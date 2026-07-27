#!/bin/bash
# ============================================================
# VPN-API Bridge — Master VPS (OrderVPN)
# Dipanggil oleh web panel untuk membuat/menghapus akun VPN lokal
# ============================================================
XRAY_CONFIG="/usr/local/etc/xray/config.json"
AKUN_DIR="/root/akun"
LOG_FILE="/var/log/vpn-api.log"
RL_DIR="/tmp/vpn-api-rl"
CONFIG_LOCK="/tmp/vpn-api-config.lock"

# Init
mkdir -p "$AKUN_DIR" "$RL_DIR" "$(dirname "$LOG_FILE")" 2>/dev/null

log_event() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ── VALIDATION ────────────────────────────────────────────────
validate_username() {
    local u="$1" len=${#1}
    [ "$len" -gt 32 ] && { echo '{"success":false,"message":"Username too long (max 32)"}'; exit 1; }
    [[ "$u" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo '{"success":false,"message":"Username hanya boleh huruf, angka, dash, underscore"}'; exit 1; }
    for b in root admin www-data systemd nginx xray nobody; do
        [ "$u" = "$b" ] && { echo '{"success":false,"message":"Username blacklisted"}'; exit 1; }
    done
}
validate_days() { [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 365 ] 2>/dev/null || { echo '{"success":false,"message":"Days must be 1-365"}'; exit 1; }; }
validate_quota() { [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 1000 ] 2>/dev/null || { echo '{"success":false,"message":"Quota must be 1-1000 GB"}'; exit 1; }; }
validate_iplimit() { [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le 10 ] 2>/dev/null || { echo '{"success":false,"message":"IP limit must be 1-10"}'; exit 1; }; }

acquire_lock() {
    exec 200>"$CONFIG_LOCK"
    flock -w 10 200 || { echo '{"success":false,"message":"Config lock timeout"}'; exit 1; }
}
release_lock() { flock -u 200 2>/dev/null; }

uuidgen() {
    cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$$-$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')"
}

# ── GET CURRENT IP & DOMAIN ──────────────────────────────────
get_my_ip() {
    local ip
    ip=$(cat /root/.ip_vps 2>/dev/null | tr -d '\n\r ' | head -1)
    if [ -n "$ip" ] && echo "$ip" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "$ip"; return
    fi
    ip=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')
    [ -n "$ip" ] && echo "$ip" || echo "127.0.0.1"
}
get_my_domain() {
    cat /root/domain 2>/dev/null | tr -d '\n\r ' | head -1 || get_my_ip
}

# ── SERVICE STATUS CHECKERS ───────────────────────────────────
_xray_status() { systemctl is-active xray 2>/dev/null || echo "inactive"; }
_nginx_status() { systemctl is-active nginx 2>/dev/null || echo "inactive"; }
_ssh_status() { systemctl is-active "$(systemctl list-units --type=service 2>/dev/null | grep -oP 'ssh[d]?\.service' | head -1 || echo ssh)" 2>/dev/null || echo "inactive"; }

# ═══════════════════════════════════════════════════════════════
#  MAIN COMMAND DISPATCHER
# ═══════════════════════════════════════════════════════════════
case "${1:-}" in
    create)
        proto="$2"; user="$3"; days="$4"; quota="$5"; iplimit="$6"
        validate_username "$user"; validate_days "$days"; validate_quota "$quota"; validate_iplimit "$iplimit"

        expired=$(date -d "+$days days" +%Y-%m-%d)
        uuid=$(uuidgen)
        domain=$(get_my_domain)
        ip=$(get_my_ip)

        # ── SSH ──
        if [ "$proto" = "ssh" ] || [ "$proto" = "trial" ]; then
            pass=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 10 | head -1)
            useradd -e "$expired" -s /bin/false -M "$user" 2>/dev/null || true
            echo "$user:$pass" | chpasswd 2>/dev/null
            echo "UUID=$uuid|PASS=$pass|QUOTA=$quota|IPLIMIT=$iplimit|EXPIRED=$expired|CREATED=$(date +%Y-%m-%d)" > "${AKUN_DIR}/ssh-${user}.txt"
            echo "{\"success\":true,\"protocol\":\"ssh\",\"username\":\"$user\",\"password\":\"$pass\",\"ip\":\"$ip\",\"domain\":\"$domain\",\"expired\":\"$expired\",\"link_config\":\"ssh://${user}:${pass}@${ip}:22\",\"link_tls\":\"ssh://${user}:${pass}@${ip}:22\",\"link_nontls\":\"ssh://${user}:${pass}@${ip}:22\",\"link_grpc\":\"ssh://${user}:${pass}@${ip}:22\"}"
            log_event "CREATE ssh $user $days $quota $iplimit"
            exit 0
        fi

        # ── VMess / VLess / Trojan ──
        if [ ! -f "$XRAY_CONFIG" ]; then
            echo '{"success":false,"message":"Xray config tidak ditemukan"}'
            exit 1
        fi

        if ! command -v jq &>/dev/null; then
            echo '{"success":false,"message":"jq tidak terinstall"}'
            exit 1
        fi

        # Map protocol to WS tag and gRPC tag
        case "$proto" in
            vmess)  ws_tag="vmess-ws";  grpc_tag="vmess-grpc";  ws_port="8080"; grpc_port="8444" ;;
            vless)  ws_tag="vless-ws";  grpc_tag="vless-grpc";  ws_port="8081"; grpc_port="8445" ;;
            trojan) ws_tag="trojan-ws"; grpc_tag="trojan-grpc"; ws_port="8082"; grpc_port="8446" ;;
            *)
                echo "{\"success\":false,\"message\":\"Unknown protocol: $proto\"}"
                exit 1
                ;;
        esac

        acquire_lock
        tmp=$(mktemp)
        # Check if jq operations work
        if ! jq --arg u "$user" --arg uuid "$uuid" --arg email "$user" \
            --arg wstag "$ws_tag" --arg grpctag "$grpc_tag" \
            '(.inbounds[] | select(.tag==$wstag) | .settings.clients) += [{"id":$uuid,"email":$email,"alterId":0}] |
             (.inbounds[] | select(.tag==$grpctag) | .settings.clients) += [{"id":$uuid,"email":$email,"alterId":0}]' \
            "$XRAY_CONFIG" > "$tmp" 2>/dev/null; then
            rm -f "$tmp"
            release_lock
            echo '{"success":false,"message":"Gagal update Xray config (jq error)"}'
            exit 1
        fi
        mv "$tmp" "$XRAY_CONFIG"
        release_lock

        # Restart xray
        systemctl restart xray 2>/dev/null || true
        sleep 0.5

        # Build config links
        link_ws="${proto}://${uuid}@${domain}:${ws_port}?path=%2F${proto}&security=none&type=ws#${user}-ws"
        link_grpc="${proto}://${uuid}@${domain}:${grpc_port}?serviceName=${proto}-grpc&security=none&type=grpc#${user}-grpc"

        # VMess uses special format
        if [ "$proto" = "vmess" ]; then
            # VMess uses a JSON config format
            vmess_config="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"${ws_port}\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${domain}\",\"path\":\"/${proto}\",\"tls\":\"\"}"
            link_ws="vmess://$(echo -n "$vmess_config" | base64 -w0 2>/dev/null || echo -n "$vmess_config" | base64 | tr -d '\n')"
        fi

        # Save account info
        echo "UUID=$uuid|QUOTA=$quota|IPLIMIT=$iplimit|EXPIRED=$expired|CREATED=$(date +%Y-%m-%d)" > "${AKUN_DIR}/${proto}-${user}.txt"

        echo "{\"success\":true,\"protocol\":\"$proto\",\"username\":\"$user\",\"uuid\":\"$uuid\",\"ip\":\"$ip\",\"domain\":\"$domain\",\"expired\":\"$expired\",\"link_ws\":\"$link_ws\",\"link_grpc\":\"$link_grpc\",\"link_nontls\":\"$link_ws\",\"link_tls\":\"$link_ws\",\"link_config\":\"$link_ws\",\"link_trojan\":\"trojan://${uuid}@${domain}:${ws_port}?path=%2F${proto}&security=none&type=ws#${user}-trojan\"}"
        log_event "CREATE $proto $user $days $quota $iplimit (uuid=$uuid)"
        ;;

    delete)
        proto="$2"; user="$3"
        if [ -z "$user" ]; then
            echo '{"success":false,"message":"Username required"}'
            exit 1
        fi

        if [ "$proto" = "ssh" ] || [ "$proto" = "trial" ]; then
            userdel -f "$user" 2>/dev/null || true
            rm -f "${AKUN_DIR}/ssh-${user}.txt"
            echo '{"success":true,"message":"Deleted"}'
            log_event "DELETE ssh $user"
            exit 0
        fi

        if [ ! -f "$XRAY_CONFIG" ]; then
            echo '{"success":false,"message":"Xray config not found"}'
            exit 1
        fi

        acquire_lock
        tmp=$(mktemp)
        # Remove client from ALL inbounds (both ws and grpc)
        jq --arg email "$user" '
            (.inbounds[].settings.clients) |= map(select(.email != $email))
        ' "$XRAY_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$XRAY_CONFIG"
        release_lock

        systemctl restart xray 2>/dev/null || true
        rm -f "${AKUN_DIR}/${proto}-${user}.txt"
        echo '{"success":true,"message":"Deleted"}'
        log_event "DELETE $proto $user"
        ;;

    renew)
        proto="$2"; user="$3"; additional_days="${4:-30}"
        [ -z "$user" ] && { echo '{"success":false,"message":"Username required"}'; exit 1; }
        acct_file="${AKUN_DIR}/${proto}-${user}.txt"
        if [ ! -f "$acct_file" ]; then
            echo "{\"success\":false,\"message\":\"Account $user not found\"}"
            exit 1
        fi
        # Read current expiry
        current_exp=$(grep -oP 'EXPIRED=\K[0-9-]+' "$acct_file" 2>/dev/null)
        if [ -z "$current_exp" ]; then current_exp=$(date +%Y-%m-%d); fi
        new_exp=$(date -d "$current_exp +$additional_days days" +%Y-%m-%d 2>/dev/null)
        # Update expiry
        sed -i "s/EXPIRED=[0-9-]*/EXPIRED=$new_exp/" "$acct_file"
        if [ "$proto" = "ssh" ] || [ "$proto" = "trial" ]; then
            # Extend user account expiry
            usermod -e "$new_exp" "$user" 2>/dev/null || true
        fi
        echo "{\"success\":true,\"message\":\"Renewed until $new_exp\",\"new_expired\":\"$new_exp\"}"
        log_event "RENEW $proto $user +$additional_days days -> $new_exp"
        ;;

    status)
        xr=$(_xray_status)
        ng=$(_nginx_status)
        domain=$(get_my_domain)
        ip=$(get_my_ip)
        echo "{\"success\":true,\"xray\":\"$xr\",\"nginx\":\"$ng\",\"domain\":\"$domain\",\"ip\":\"$ip\"}"
        ;;

    list)
        proto="$2"
        if [ -n "$proto" ]; then
            accounts=()
            for f in "${AKUN_DIR}/${proto}-"*.txt; do
                [ -f "$f" ] || continue
                name=$(basename "$f" | sed "s/${proto}-//; s/\.txt//")
                exp=$(grep -oP 'EXPIRED=\K[0-9-]+' "$f" 2>/dev/null || echo "N/A")
                accounts+=("{\"username\":\"$name\",\"expired\":\"$exp\"}")
            done
            echo "{\"success\":true,\"accounts\":[$(IFS=,; echo "${accounts[*]}")]}"
        else
            accounts=()
            for f in "${AKUN_DIR}/"*.txt; do
                [ -f "$f" ] || continue
                name=$(basename "$f" .txt)
                exp=$(grep -oP 'EXPIRED=\K[0-9-]+' "$f" 2>/dev/null || echo "N/A")
                accounts+=("{\"username\":\"$name\",\"expired\":\"$exp\"}")
            done
            echo "{\"success\":true,\"accounts\":[$(IFS=,; echo "${accounts[*]}")]}"
        fi
        ;;

    monitor|health)
        cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2+$4}')
        [ -z "$cpu" ] && cpu=$(top -bn1 2>/dev/null | awk '/^%Cpu/{print $2}')
        [ -z "$cpu" ] && cpu=0
        ram_total=$(free -m | awk 'NR==2{print $2}')
        ram_used=$(free -m | awk 'NR==2{print $3}')
        ram_pct=$(awk "BEGIN{printf \"%.0f\",($ram_used/$ram_total)*100}" 2>/dev/null || echo 0)
        disk=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
        uptime=$(uptime -p 2>/dev/null | sed 's/up //')
        xr=$(_xray_status)
        ng=$(_nginx_status)
        sshc=$(ps aux 2>/dev/null | grep -c '[s]shd' || echo 0)
        vmc=$(find "${AKUN_DIR}" -name 'vmess-*.txt' 2>/dev/null | wc -l)
        vlc=$(find "${AKUN_DIR}" -name 'vless-*.txt' 2>/dev/null | wc -l)
        trc=$(find "${AKUN_DIR}" -name 'trojan-*.txt' 2>/dev/null | wc -l)
        ip=$(get_my_ip)
        domain=$(get_my_domain)
        echo "{\"success\":true,\"ping_ms\":\"1\",\"uptime\":\"$uptime\",\"cpu\":\"$cpu\",\"ram\":\"$ram_pct\",\"ram_used\":\"$ram_used\",\"ram_total\":\"$ram_total\",\"disk\":\"$disk\",\"ssh_count\":$sshc,\"vmess_count\":$vmc,\"vless_count\":$vlc,\"trojan_count\":$trc,\"xray\":\"$xr\",\"nginx\":\"$ng\",\"ssh\":\"active\",\"ip\":\"$ip\",\"domain\":\"$domain\"}"
        ;;

    probe|discover)
        host="${2:-}"; user="${3:-root}"; pass="${4:-}"; port="${5:-22}"
        if [ -z "$host" ] || [ -z "$pass" ]; then
            echo '{"success":false,"message":"host and password required"}'
            exit 1
        fi
        # Probe remote server via SSH
        if command -v sshpass &>/dev/null; then
            if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo ok" >/dev/null 2>&1; then
                # Try to get region info
                region=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$port" "$user@$host" "curl -s --max-time 3 http://ip-api.com/json/ 2>/dev/null | grep -oP '\"country\":\"\K[^\"]+'" 2>/dev/null || echo "Unknown")
                remote_domain=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$port" "$user@$host" "cat /root/domain 2>/dev/null || hostname -I | awk '{print \$1}'" 2>/dev/null || echo "$host")
                echo "{\"success\":true,\"message\":\"Connection OK\",\"region\":\"$region\",\"domain\":\"$remote_domain\"}"
            else
                echo '{"success":false,"message":"SSH connection or authentication failed"}'
            fi
        else
            echo '{"success\":false,"message":"sshpass not installed on master"}'
        fi
        ;;

    *)
        echo "{\"success\":false,\"message\":\"Unknown command: ${1:-none}\",\"usage\":\"create|delete|renew|status|list|monitor|probe\"}"
        ;;
esac
