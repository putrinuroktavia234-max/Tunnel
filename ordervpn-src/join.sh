#!/bin/bash
# ======================================================
# VPN-JOIN — Hubungkan VPS Baru ke Master Panel OrderVPN
# Usage: bash <(curl -s http://MASTER_IP:8888/ordervpn/join.sh) --master=IP --secret=KEY
# ======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; NC='\033[0m'

log_info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }
log_ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; }
log_err()  { echo -e "  ${RED}[ERR]${NC}  $1"; }

# Parse args
for arg in "$@"; do
    case "$arg" in
        --master=*) MASTER_IP="${arg#*=}" ;;
        --secret=*) JOIN_SECRET="${arg#*=}" ;;
        --code=*)   SERVER_CODE="${arg#*=}" ;;
        --name=*)   SERVER_NAME="${arg#*=}" ;;
    esac
done

[ -z "$MASTER_IP" ] && read -rp "Masukkan IP Master Panel: " MASTER_IP
[ -z "$JOIN_SECRET" ] && read -rp "Masukkan Join Secret (dari admin panel): " JOIN_SECRET

MASTER_URL="http://${MASTER_IP}:8888/ordervpn"

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}VPN JOIN — Hubungkan ke Master Panel${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Validate connection to master
log_info "Menghubungi master panel..."
if ! curl -s --max-time 5 "$MASTER_URL" >/dev/null 2>&1; then
    log_err "Tidak bisa terhubung ke $MASTER_IP:8888"
    exit 1
fi
log_ok "Terhubung ke master panel"

# Detect info
log_info "Mendeteksi informasi server..."
MY_IP=$(curl -4 -s ifconfig.me 2>/dev/null || ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
[ -z "$MY_IP" ] && MY_IP=$(hostname -I | awk '{print $1}')

if [ -z "$SERVER_CODE" ]; then
    SERVER_CODE="sv$(date +%s | tail -c 6)"
fi
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="VPS-$(echo $MY_IP | tr '.' '-')"
fi

log_info "IP: $MY_IP"
log_info "Code: $SERVER_CODE"
log_info "Nama: $SERVER_NAME"

# Install vpn-api bridge
log_info "Menginstall vpn-api bridge..."

# Create minimal vpn-api
cat > /usr/local/bin/vpn-api << 'BRIDGE'
#!/bin/bash
case "${1:-}" in
    create)
        echo '{"success":true,"message":"create on remote"}'
        ;;
    delete)
        echo '{"success":true,"message":"deleted"}'
        ;;
    monitor|health)
        cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}')
        ram=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2}')
        disk=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
        uptime=$(uptime -p | sed 's/up //')
        echo "{\"success\":true,\"ping_ms\":\"1\",\"uptime\":\"$uptime\",\"cpu\":\"$cpu\",\"ram\":\"$ram\",\"disk\":\"$disk\",\"ssh_count\":0,\"vmess_count\":0,\"vless_count\":0,\"trojan_count\":0,\"xray\":\"OFF\",\"nginx\":\"OFF\",\"ssh\":\"OFF\",\"ip\":\"$(hostname -I | awk '{print $1}')\"}"
        ;;
    probe|discover)
        echo '{"success":true,"region":"Auto Joined","domain":"","ip":"'$(hostname -I | awk '{print $1}')'"}'
        ;;
    *)
        echo '{"success":false,"message":"unknown command"}'
        ;;
esac
BRIDGE
chmod +x /usr/local/bin/vpn-api
log_ok "vpn-api bridge terinstall"

# Generate SSH key if missing
if [ ! -f /root/.ssh/id_rsa ]; then
    log_info "Membuat SSH key..."
    mkdir -p /root/.ssh
    ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N "" -q
    log_ok "SSH key dibuat"
fi

log_info "Mendaftarkan ke master panel..."
PUBKEY=$(cat /root/.ssh/id_rsa.pub)

# Detect region
REGION=$(curl -4 -s --max-time 5 "http://ip-api.com/json/" 2>/dev/null | grep -oP '"country":"\K[^"]+' || echo "Unknown")

REG_DATA=$(cat <<EOF
{
    "action": "register",
    "secret": "$JOIN_SECRET",
    "host": "$MY_IP",
    "code_server": "$SERVER_CODE",
    "nama_server": "$SERVER_NAME",
    "lokasi": "$REGION",
    "domain": "$MY_IP",
    "pubkey": "$PUBKEY"
}
EOF
)

RESULT=$(curl -s --max-time 10 -X POST "${MASTER_URL}/api/register_vps.php" \
    -H "Content-Type: application/json" \
    -d "$REG_DATA" 2>/dev/null)

if echo "$RESULT" | grep -q '"success":true'; then
    log_ok "Terdaftar di master panel!"

    # Save master info
    echo "$MASTER_IP" > /root/.master_ip
    echo "$JOIN_SECRET" > /root/.join_secret
    chmod 600 /root/.join_secret /root/.master_ip 2>/dev/null

    # Add master public key for passwordless SSH
    MASTER_PUBKEY=$(echo "$RESULT" | grep -oP '"master_pubkey":"\K[^"]+')
    if [ -n "$MASTER_PUBKEY" ]; then
        echo "$MASTER_PUBKEY" >> /root/.ssh/authorized_keys
        log_ok "SSH key master ditambahkan"
    fi

    # Setup cron for heartbeat
    (crontab -l 2>/dev/null | grep -v "vpn-heartbeat"; echo "*/5 * * * * curl -s --max-time 5 -X POST ${MASTER_URL}/api/register_vps.php -H 'Content-Type: application/json' -d '{\"action\":\"heartbeat\",\"secret\":\"$JOIN_SECRET\",\"code_server\":\"$SERVER_CODE\"}' >/dev/null 2>&1") | crontab -
    log_ok "Cron heartbeat dipasang (setiap 5 menit)"

    # === AUTO DEPLOYMENT ===
    echo ""
    log_info "Menginstall Xray + full bridge..."
    DEPLOY_SCRIPT=$(mktemp)
    if curl -s --max-time 30 "${MASTER_URL}/deploy-node.sh" -o "$DEPLOY_SCRIPT" 2>/dev/null && [ -s "$DEPLOY_SCRIPT" ] && grep -q "Xray" "$DEPLOY_SCRIPT"; then
        chmod +x "$DEPLOY_SCRIPT"
        bash "$DEPLOY_SCRIPT" "$MASTER_URL" "$JOIN_SECRET" "$SERVER_CODE"
        rm -f "$DEPLOY_SCRIPT"
    else
        log_err "Gagal download deploy script dari master"
        rm -f "$DEPLOY_SCRIPT"
    fi
else
    ERR_MSG=$(echo "$RESULT" | grep -oP '"message":"\K[^"]+')
    log_err "Gagal daftar: ${ERR_MSG:-Unknown error}"
    exit 1
fi
