#!/bin/bash
# deploy-node.sh — Full VPN node deployment for OrderVPN
# Called by join.sh after successful registration with master
# Usage: sourced from join.sh, not standalone

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; NC='\033[0m'

log_info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }
log_ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; }
log_err()  { echo -e "  ${RED}[ERR]${NC}  $1"; }

MASTER_URL="${1:-}"
JOIN_SECRET="${2:-}"
SERVER_CODE="${3:-}"
[ -z "$MASTER_URL" ] && { log_err "MASTER_URL required"; return 1; }

# ============================================================
# 1. Install dependencies
# ============================================================
log_info "Menginstall dependencies..."
apt-get update -qq
apt-get install -y -qq jq nginx curl openssh-server sshpass cron systemd 2>&1 | tail -1
log_ok "Dependencies terinstall"

# ============================================================
# 2. Install Xray
# ============================================================
if ! command -v xray &>/dev/null; then
    log_info "Menginstall Xray..."
    bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.23 2>&1 | tail -1
    log_ok "Xray terinstall"
else
    log_ok "Xray sudah terinstall ($(xray --version | head -1))"
fi

# ============================================================
# 3. Generate Xray config (6 inbounds)
# ============================================================
log_info "Membuat konfigurasi Xray..."

XRAY_CONFIG="/usr/local/etc/xray/config.json"
mkdir -p /usr/local/etc/xray /var/log/xray /root/akun /tmp/vpn-api-rl

MY_IP=$(curl -4 -s ifconfig.me 2>/dev/null || ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}' || hostname -I | awk '{print $1}')

cat > "$XRAY_CONFIG" << CONFIGEOF
{
  "log": {"loglevel": "warning", "access": "/var/log/xray/access.log", "error": "/var/log/xray/error.log"},
  "inbounds": [
    {
      "port": 8080, "protocol": "vmess", "tag": "vmess-ws",
      "settings": {"clients": []},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    },
    {
      "port": 8081, "protocol": "vless", "tag": "vless-ws",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    },
    {
      "port": 8082, "protocol": "trojan", "tag": "trojan-ws",
      "settings": {"clients": []},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    },
    {
      "port": 8444, "protocol": "vmess", "tag": "vmess-grpc",
      "settings": {"clients": []},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vmess-grpc"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    },
    {
      "port": 8445, "protocol": "vless", "tag": "vless-grpc",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vless-grpc"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    },
    {
      "port": 8446, "protocol": "trojan", "tag": "trojan-grpc",
      "settings": {"clients": []},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "trojan-grpc"}},
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]}
    }
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}],
  "routing": {"domainStrategy": "AsIs"}
}
CONFIGEOF

# Store IP as domain fallback
echo "$MY_IP" > /root/domain

log_ok "Konfigurasi Xray siap (6 inbounds: WS + gRPC)"

# ============================================================
# 4. Install full vpn-api bridge
# ============================================================
log_info "Mendownload vpn-api bridge dari master..."
BRIDGE_URL="${MASTER_URL}/api/get_bridge.php?secret=${JOIN_SECRET}"
BRIDGE_FILE="/usr/local/bin/vpn-api"

# Remove old stub if exists
rm -f "$BRIDGE_FILE"

# Download full bridge
if curl -s --max-time 30 "$BRIDGE_URL" -o "$BRIDGE_FILE" && [ -s "$BRIDGE_FILE" ] && grep -q "XRAY_CONFIG" "$BRIDGE_FILE" 2>/dev/null; then
    chmod +x "$BRIDGE_FILE"
    log_ok "vpn-api bridge terinstall (full version)"
else
    log_info "Download gagal, membuat bridge standar..."
    cat > "$BRIDGE_FILE" << 'BRIDGEEOF'
#!/bin/bash
# VPN-API Bridge — Deployed by join.sh
XRAY_CONFIG="/usr/local/etc/xray/config.json"
AKUN_DIR="/root/akun"
LOG_FILE="/var/log/vpn-api.log"
RL_DIR="/tmp/vpn-api-rl"
CONFIG_LOCK="/tmp/vpn-api-config.lock"

log_event() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
validate_username() {
    local u="$1" len=${#1}
    [ "$len" -gt 32 ] && { echo '{"success":false,"message":"Username too long"}'; exit 1; }
    [[ "$u" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo '{"success":false,"message":"Invalid chars"}'; exit 1; }
    for b in root admin www-data systemd; do [ "$u" = "$b" ] && { echo '{"success":false,"message":"Blacklisted"}'; exit 1; }; done
}
validate_days() { [ "$1" -ge 1 -a "$1" -le 365 ] 2>/dev/null || { echo '{"success":false,"message":"Days 1-365"}'; exit 1; }; }
validate_quota() { [ "$1" -ge 1 -a "$1" -le 100 ] 2>/dev/null || { echo '{"success":false,"message":"Quota 1-100"}'; exit 1; }; }
validate_iplimit() { [ "$1" -ge 1 -a "$1" -le 5 ] 2>/dev/null || { echo '{"success":false,"message":"IP limit 1-5"}'; exit 1; }; }
acquire_lock() { exec 200>"$CONFIG_LOCK"; flock -w 10 200 || { echo '{"success":false,"message":"Lock timeout"}'; exit 1; }; }
release_lock() { flock -u 200; }

uuidgen() { cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$$-$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"; }

case "${1:-}" in
    create)
        proto="$2"; user="$3"; days="$4"; quota="$5"; iplimit="$6"
        validate_username "$user"; validate_days "$days"; validate_quota "$quota"; validate_iplimit "$iplimit"
        expired=$(date -d "+$days days" +%Y-%m-%d)
        uuid=$(uuidgen)
        domain=$(cat /root/domain 2>/dev/null || echo "$(hostname -I | awk '{print $1}')")
        ip=$(hostname -I | awk '{print $1}')
        
        if [ "$proto" = "ssh" ]; then
            pass=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 8 | head -1)
            useradd -e "$expired" -s /bin/false -M "$user" 2>/dev/null || true
            echo "$user:$pass" | chpasswd
            echo "UUID=$uuid|PASS=$pass|QUOTA=$quota|IPLIMIT=$iplimit|EXPIRED=$expired|CREATED=$(date +%Y-%m-%d)" > "${AKUN_DIR}/ssh-${user}.txt"
            echo "{\"success\":true,\"protocol\":\"ssh\",\"username\":\"$user\",\"password\":\"$pass\",\"expired\":\"$expired\"}"
        else
            acquire_lock
            tmp=$(mktemp) && jq --arg u "$user" --arg uuid "$uuid" --arg email "$user" '
                (.inbounds[] | select(.tag=="'"${proto}"'-ws") .settings.clients) += [{"id":$uuid,"email":$email}]
              | (.inbounds[] | select(.tag=="'"${proto}"'-grpc") .settings.clients) += [{"id":$uuid,"email":$email}]
            ' "$XRAY_CONFIG" > "$tmp" && mv "$tmp" "$XRAY_CONFIG"
            release_lock
            systemctl restart xray 2>/dev/null || true
            
            link_ws="${proto}://${uuid}@${ip}:8080?path=%2F${proto}&security=none&type=ws#${user}-ws"
            link_grpc="${proto}://${uuid}@${ip}:8444?serviceName=${proto}-grpc&security=none&type=grpc#${user}-grpc"
            echo "UUID=$uuid|QUOTA=$quota|IPLIMIT=$iplimit|EXPIRED=$expired|CREATED=$(date +%Y-%m-%d)" > "${AKUN_DIR}/${proto}-${user}.txt"
            echo "{\"success\":true,\"protocol\":\"$proto\",\"username\":\"$user\",\"uuid\":\"$uuid\",\"ip\":\"$ip\",\"domain\":\"$domain\",\"expired\":\"$expired\",\"link_ws\":\"$link_ws\",\"link_grpc\":\"$link_grpc\",\"link_nontls\":\"$link_ws\",\"link_tls\":\"$link_ws\",\"link_trojan\":\"trojan://${uuid}@${ip}:8082?path=%2Ftrojan&security=none&type=ws#${user}-trojan\"}"
        fi
        log_event "CREATE $proto $user $days $quota $iplimit"
        ;;
    delete)
        proto="$2"; user="$3"
        if [ "$proto" = "ssh" ]; then
            userdel -f "$user" 2>/dev/null || true
            rm -f "${AKUN_DIR}/ssh-${user}.txt"
        else
            acquire_lock
            tmp=$(mktemp) && jq --arg email "$user" '
                (.inbounds[] | select(.tag=="'"${proto}"'-ws") .settings.clients) |= map(select(.email!=$email))
              | (.inbounds[] | select(.tag=="'"${proto}"'-grpc") .settings.clients) |= map(select(.email!=$email))
            ' "$XRAY_CONFIG" > "$tmp" && mv "$tmp" "$XRAY_CONFIG"
            release_lock
            systemctl restart xray 2>/dev/null || true
            rm -f "${AKUN_DIR}/${proto}-${user}.txt"
        fi
        echo '{"success":true,"message":"Deleted"}'
        log_event "DELETE $proto $user"
        ;;
    status)
        xr=$(systemctl is-active xray 2>/dev/null || echo "inactive")
        ng=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
        domain=$(cat /root/domain 2>/dev/null || echo "$(hostname -I | awk '{print $1}')")
        echo "{\"success\":true,\"xray\":\"$xr\",\"nginx\":\"$ng\",\"domain\":\"$domain\",\"ip\":\"$(hostname -I | awk '{print $1}')\"}"
        ;;
    list)
        proto="$2"
        if [ -n "$proto" ]; then
            for f in "${AKUN_DIR}/${proto}-"*.txt; do
                [ -f "$f" ] || continue
                name=$(basename "$f" | sed "s/${proto}-//; s/\.txt//")
                echo "$name"
            done
        else
            for f in "${AKUN_DIR}/"*.txt; do
                [ -f "$f" ] || continue
                basename "$f" .txt
            done
        fi
        ;;
    monitor|health)
        cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2+$4}')
        [ -z "$cpu" ] && cpu=$(top -bn1 2>/dev/null | awk '/^%Cpu/{print $2}')
        [ -z "$cpu" ] && cpu=0
        ram=$(free -m | awk 'NR==2{printf "%.0f", $3*100/$2}')
        disk=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
        uptime=$(uptime -p 2>/dev/null | sed 's/up //')
        xr=$(systemctl is-active xray 2>/dev/null || echo "inactive")
        ng=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
        sshc=$(ps aux | grep sshd | grep -v grep | wc -l)
        vmc=$(find "${AKUN_DIR}" -name 'vmess-*.txt' 2>/dev/null | wc -l)
        vlc=$(find "${AKUN_DIR}" -name 'vless-*.txt' 2>/dev/null | wc -l)
        trc=$(find "${AKUN_DIR}" -name 'trojan-*.txt' 2>/dev/null | wc -l)
        echo "{\"success\":true,\"ping_ms\":\"1\",\"uptime\":\"$uptime\",\"cpu\":\"$cpu\",\"ram\":\"$ram\",\"disk\":\"$disk\",\"ssh_count\":$sshc,\"vmess_count\":$vmc,\"vless_count\":$vlc,\"trojan_count\":$trc,\"xray\":\"$xr\",\"nginx\":\"$ng\",\"ssh\":\"active\",\"ip\":\"$(hostname -I | awk '{print $1}')\",\"domain\":\"$(cat /root/domain 2>/dev/null || echo '')\"}"
        ;;
    *)
        echo '{"success":false,"message":"unknown command"}'
        ;;
esac
BRIDGEEOF
    chmod +x /usr/local/bin/vpn-api
    log_ok "vpn-api bridge terinstall (standard)"
fi

# ============================================================
# 5. Setup sudoers for www-data
# ============================================================
if [ ! -f /etc/sudoers.d/ordervpn-api ]; then
    cat > /etc/sudoers.d/ordervpn-api << 'SUDOEOF'
www-data ALL=(root) NOPASSWD: /usr/local/bin/vpn-api
SUDOEOF
    chmod 440 /etc/sudoers.d/ordervpn-api
    log_ok "Sudoers dikonfigurasi"
fi

# ============================================================
# 6. Start Xray
# ============================================================
log_info "Menjalankan Xray..."
systemctl enable xray 2>/dev/null || true
systemctl restart xray 2>/dev/null || true
sleep 1
if systemctl is-active xray &>/dev/null; then
    log_ok "Xray berjalan"
else
    log_warn "Xray gagal jalan, cek: xray run -config $XRAY_CONFIG"
fi

# ============================================================
# 7. Setup cron untuk cleanup expired accounts
# ============================================================
(crontab -l 2>/dev/null | grep -v "vpn-cleanup"; cat << 'CRONEOF'
0 3 * * * for f in /root/akun/*.txt; do [ -f "$f" ] || continue; exp=$(grep -oP 'EXPIRED=\K[0-9-]+' "$f" 2>/dev/null); [ -n "$exp" -a "$(date +%s)" -gt "$(date -d "$exp" +%s 2>/dev/null)" ] && rm -f "$f"; done
CRONEOF
) | crontab -
log_ok "Cron cleanup dipasang"

# ============================================================
# 8. Summary
# ============================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}✔ DEPLOYMENT SELESAI — Node VPN Siap${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Xray:    ${CYAN}$(xray --version 2>/dev/null | head -1)${NC}"
echo -e "  IP:      ${CYAN}$MY_IP${NC}"
echo -e "  Ports:   ${CYAN}8080-8082 (WS) / 8444-8446 (gRPC)${NC}"
echo -e "  Bridge:  ${CYAN}/usr/local/bin/vpn-api${NC}"
echo -e "  Master:  ${CYAN}${MASTER_URL}${NC}"
echo ""
