#!/bin/bash

#================================================
# Auto Script VPN Server - FIXED EDITION
# By The Proffessor Squad
#================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

DOMAIN=""
DOMAIN_FILE="/root/domain"
AKUN_DIR="/root/akun"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
SCRIPT_VERSION="By The Proffessor Squad"
PUBLIC_HTML="/var/www/html"
USERNAME="YouzinCrabz"
BOT_TOKEN_FILE="/root/.bot_token"
CHAT_ID_FILE="/root/.chat_id"

# ================================================
# PORT VARIABLES - UPDATED
# ================================================
SSH_PORT="22"
DROPBEAR_PORT="222"
NGINX_PORT="80"
HAPROXY_PORT="443"
VMESS_TLS_PORT="8443"
VLESS_TLS_PORT="8443"
TROJAN_TLS_PORT="2083"
XRAY_GRPC_PORT="8444"
XRAY_WS_NONTLS_PORT="8080"
VMESS_NONTLS_PORT="8080"
VLESS_NONTLS_PORT="8080"
TROJAN_NONTLS_PORT="8080"
BADVPN_PORT1="7100"
BADVPN_PORT2="7200"
BADVPN_PORT3="7300"
BADVPN_RANGE="7100-7300"

# Display strings
SSH_PORTS="22"
DROPBEAR_PORTS="222"
NGINX_PORTS="80"
HAPROXY_PORTS="443"
VMESS_TLS_PORTS="8443"
VLESS_TLS_PORTS="8443"
TROJAN_TLS_PORTS="2083"
GRPC_PORT="8444"
WS_NONTLS_PORT="8080"
BADVPN_PORTS="7100-7300"

# ================================================
# UTILITY FUNCTIONS
# ================================================

check_status() {
    if systemctl is-active --quiet "$1" 2>/dev/null; then
        echo "ON"
    else
        echo "OFF"
    fi
}

send_telegram() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    local token
    token=$(cat "$BOT_TOKEN_FILE")
    local chatid
    chatid=$(cat "$CHAT_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" \
        -d text="$1" >/dev/null 2>&1
}

print_menu_header() {
    local title="$1"
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
    printf "${CYAN}|${NC}  %-44s ${CYAN}|${NC}\n" "$title"
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
}

print_menu_footer() {
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
}

# ================================================
# CHANGE DOMAIN - FIXED
# ================================================

change_domain() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CHANGE DOMAIN${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " Current domain: ${GREEN}${DOMAIN:-Not Set}${NC}"
    echo ""
    read -p " New Domain: " new_domain
    [[ -z "$new_domain" ]] && {
        echo -e "${RED}Domain cannot be empty!${NC}"
        sleep 2; return
    }

    echo "$new_domain" > "$DOMAIN_FILE"
    DOMAIN="$new_domain"

    # Update nginx config with new domain
    if [[ -f /etc/nginx/sites-available/default ]]; then
        sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/xray\/xray.key;/" \
            /etc/nginx/sites-available/default
        sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/xray\/xray.crt;/" \
            /etc/nginx/sites-available/default
        systemctl reload nginx 2>/dev/null
    fi

    echo ""
    echo -e "${GREEN}Domain changed to: ${CYAN}${DOMAIN}${NC}"
    echo -e "${YELLOW}Run Fix Certificate (menu 17) to renew SSL!${NC}"
    sleep 3
}

# ================================================
# FIX CERTIFICATE - FIXED
# ================================================

fix_certificate() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}FIX / RENEW CERTIFICATE${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    # Load domain
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}Domain not set! Please set domain first (menu 16).${NC}"
        sleep 3; return
    fi

    echo -e " Domain: ${GREEN}${DOMAIN}${NC}"
    echo ""
    echo -e "${CYAN}Stopping nginx for certificate renewal...${NC}"
    systemctl stop nginx 2>/dev/null

    echo -e "${CYAN}Requesting SSL certificate from Let's Encrypt...${NC}"
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --force-renewal 2>&1 | tail -5

    mkdir -p /etc/xray

    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
        chmod 644 /etc/xray/xray.*
        echo ""
        echo -e "${GREEN}Certificate successfully obtained!${NC}"
        echo -e " Cert : ${CYAN}/etc/xray/xray.crt${NC}"
        echo -e " Key  : ${CYAN}/etc/xray/xray.key${NC}"
    else
        echo ""
        echo -e "${YELLOW}Let's Encrypt failed. Creating self-signed cert...${NC}"
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
            -subj "/CN=$DOMAIN" \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt 2>/dev/null
        chmod 644 /etc/xray/xray.*
        echo -e "${GREEN}Self-signed certificate created.${NC}"
    fi

    # Restart services
    systemctl start nginx 2>/dev/null
    systemctl restart xray 2>/dev/null
    echo ""
    echo -e "${GREEN}Services restarted!${NC}"
    sleep 3
}

# ================================================
# SPEEDTEST - FIXED
# ================================================

run_speedtest() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SPEEDTEST${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    # Check if speedtest is installed
    if command -v speedtest >/dev/null 2>&1; then
        echo -e "${CYAN}Running speedtest...${NC}"
        speedtest
    elif command -v speedtest-cli >/dev/null 2>&1; then
        echo -e "${CYAN}Running speedtest-cli...${NC}"
        speedtest-cli
    else
        echo -e "${YELLOW}Speedtest not found. Installing...${NC}"
        # Try installing speedtest-cli via pip
        if command -v pip3 >/dev/null 2>&1; then
            pip3 install speedtest-cli --break-system-packages 2>/dev/null || \
            pip3 install speedtest-cli 2>/dev/null
        fi
        # Try apt
        if ! command -v speedtest-cli >/dev/null 2>&1; then
            apt-get install -y speedtest-cli >/dev/null 2>&1
        fi
        # Try official speedtest
        if ! command -v speedtest-cli >/dev/null 2>&1; then
            curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh \
                | bash >/dev/null 2>&1
            apt-get install -y speedtest >/dev/null 2>&1
        fi

        if command -v speedtest >/dev/null 2>&1; then
            echo -e "${CYAN}Running speedtest...${NC}"
            echo ""
            speedtest
        elif command -v speedtest-cli >/dev/null 2>&1; then
            echo -e "${CYAN}Running speedtest-cli...${NC}"
            echo ""
            speedtest-cli
        else
            echo -e "${RED}Failed to install speedtest.${NC}"
            echo -e "${YELLOW}Manual install: pip3 install speedtest-cli${NC}"
        fi
    fi

    echo ""
    read -p "Press Enter..."
}
#================================================
# FIX XRAY PERMISSIONS
#================================================

fix_xray_permissions() {
    mkdir -p /usr/local/etc/xray /var/log/xray
    chmod 755 /usr/local/etc/xray
    chmod 755 /var/log/xray
    touch /var/log/xray/access.log /var/log/xray/error.log
    chmod 644 /var/log/xray/access.log /var/log/xray/error.log
    chmod 644 /usr/local/etc/xray/config.json 2>/dev/null
    chown -R nobody:nogroup /var/log/xray 2>/dev/null
}

#================================================
# CREATE XRAY CONFIG - PORT UPDATED
#================================================

create_xray_config() {
    mkdir -p /var/log/xray /usr/local/etc/xray
    cat > "$XRAY_CONFIG" << 'XRAYEOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 8443,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "wsSettings": {"path": "/vmess","headers": {}}
      },
      "tag": "vmess-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess","headers": {}}
      },
      "tag": "vmess-nontls-8080"
    },
    {
      "port": 8443,
      "protocol": "vless",
      "settings": {"clients": [],"decryption": "none"},
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "wsSettings": {"path": "/vless","headers": {}}
      },
      "tag": "vless-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {"clients": [],"decryption": "none"},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vless","headers": {}}
      },
      "tag": "vless-nontls-8080"
    },
    {
      "port": 2083,
      "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "wsSettings": {"path": "/trojan","headers": {}}
      },
      "tag": "trojan-tls-2083"
    },
    {
      "port": 8444,
      "protocol": "vless",
      "settings": {"clients": [],"decryption": "none"},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "grpcSettings": {"serviceName": "vless-grpc"}
      },
      "tag": "vless-grpc-8444"
    },
    {
      "port": 8444,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "grpcSettings": {"serviceName": "vmess-grpc"}
      },
      "tag": "vmess-grpc-8444"
    },
    {
      "port": 8444,
      "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "grpcSettings": {"serviceName": "trojan-grpc"}
      },
      "tag": "trojan-grpc-8444"
    }
  ],
  "outbounds": [
    {"protocol": "freedom","settings": {},"tag": "direct"},
    {"protocol": "blackhole","settings": {},"tag": "block"}
  ]
}
XRAYEOF
    fix_xray_permissions
}

#================================================
# SETUP KEEPALIVE & STABILITY
#================================================

setup_keepalive() {
    if grep -q "^ClientAliveInterval" /etc/ssh/sshd_config 2>/dev/null; then
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 60/' /etc/ssh/sshd_config
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config
        sed -i 's/^TCPKeepAlive.*/TCPKeepAlive yes/' /etc/ssh/sshd_config
    else
        echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
        echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config
        echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null

    mkdir -p /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service.d/keepalive.conf << 'XKEOF'
[Service]
Restart=always
RestartSec=5
XKEOF

    cat > /usr/local/bin/vpn-keepalive.sh << 'VPNEOF'
#!/bin/bash
GW=$(ip route | awk '/default/{print $3; exit}')
while true; do
    [[ -n "$GW" ]] && ping -c 1 -W 3 "$GW" >/dev/null 2>&1
    echo -n "ka" | nc -u -w1 127.0.0.1 7100 >/dev/null 2>&1
    sleep 30
done
VPNEOF
    chmod +x /usr/local/bin/vpn-keepalive.sh

    cat > /etc/systemd/system/vpn-keepalive.service << 'KASEOF'
[Unit]
Description=VPN Keepalive Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-keepalive.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
KASEOF

    cat > /etc/sysctl.d/99-vpn-stable.conf << 'SYSCTLEOF'
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_fin_timeout = 15
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 8192
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
SYSCTLEOF

    sysctl -p /etc/sysctl.d/99-vpn-stable.conf >/dev/null 2>&1
    systemctl daemon-reload
    systemctl enable vpn-keepalive 2>/dev/null
    systemctl restart vpn-keepalive 2>/dev/null
    echo -e "${GREEN}Keepalive configured!${NC}"
}

#================================================
# SHOW SYSTEM INFO - STATUS TABLE FIXED
#================================================

show_system_info() {
    clear
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && source /etc/os-release && os_name="${PRETTY_NAME}"

    local ip_vps ram cpu uptime_str
    ip_vps=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "N/A")
    ram=$(free -m | awk 'NR==2{printf "%s / %s MB", $3, $2}')
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    uptime_str=$(uptime -p | sed 's/up //')

    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}        ${GREEN}Welcome Mr. ${USERNAME}${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SYSTEM OS"   "$os_name"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SYSTEM CORE" "$(nproc)"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SERVER RAM"  "$ram"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "LOAD CPU"    "${cpu}%"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "DATE"        "$(date +"%d-%m-%Y")"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "TIME"        "$(date +"%H:%M:%S")"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "UPTIME"      "$uptime_str"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "IP VPS"      "$ip_vps"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "DOMAIN"      "${DOMAIN:-Not Set}"
    echo -e "${CYAN}+========================================================+${NC}"

    local vc lc tc sc
    vc=$(ls "$AKUN_DIR"/vmess-*.txt  2>/dev/null | wc -l)
    lc=$(ls "$AKUN_DIR"/vless-*.txt  2>/dev/null | wc -l)
    tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    sc=$(ls "$AKUN_DIR"/ssh-*.txt    2>/dev/null | wc -l)

    echo -e "              ${CYAN}>>> INFORMATION ACCOUNT <<<${NC}"
    echo -e "     ${CYAN}===============================================${NC}"
    printf "           %-20s = ${GREEN}%s${NC}\n" "SSH/OPENVPN/UDP" "$sc"
    printf "           %-20s = ${GREEN}%s${NC}\n" "VMESS/WS/GRPC"   "$vc"
    printf "           %-20s = ${GREEN}%s${NC}\n" "VLESS/WS/GRPC"   "$lc"
    printf "           %-20s = ${GREEN}%s${NC}\n" "TROJAN/WS/GRPC"  "$tc"
    printf "           %-20s = ${GREEN}%s${NC}\n" "SHADOW/WS/GRPC"  "0"
    echo -e "     ${CYAN}===============================================${NC}"
    echo -e "                ${CYAN}>>> ${USERNAME} <<<${NC}"
    echo ""

    local s1 s2 s3 s4 s5 s6 s7
    s1=$(check_status sshd)
    s2=$(check_status nginx)
    s3=$(check_status xray)
    s4=$(check_status udp-custom)
    s5=$(check_status haproxy)
    s6=$(check_status dropbear)
    s7=$(check_status vpn-keepalive)

    local cs1 cs2 cs3 cs4 cs5 cs6 cs7 csN csW
    [[ "$s1" == "ON" ]] && cs1="${GREEN}ON ${NC}" || cs1="${RED}OFF${NC}"
    [[ "$s2" == "ON" ]] && cs2="${GREEN}ON ${NC}" || cs2="${RED}OFF${NC}"
    [[ "$s3" == "ON" ]] && cs3="${GREEN}ON ${NC}" || cs3="${RED}OFF${NC}"
    [[ "$s4" == "ON" ]] && cs4="${GREEN}ON ${NC}" || cs4="${RED}OFF${NC}"
    [[ "$s5" == "ON" ]] && cs5="${GREEN}ON ${NC}" || cs5="${RED}OFF${NC}"
    [[ "$s6" == "ON" ]] && cs6="${GREEN}ON ${NC}" || cs6="${RED}OFF${NC}"
    [[ "$s7" == "ON" ]] && cs7="${GREEN}ON ${NC}" || cs7="${RED}OFF${NC}"
    csN="${YELLOW}OFF${NC}"
    csW="${YELLOW}OFF${NC}"

    echo -e "${CYAN}+==================+==================+==================+${NC}"
    echo -e "${CYAN}|${NC} SSH     ${cs1}   ${CYAN}|${NC} NOOBZVPN ${csN} ${CYAN}|${NC} NGINX   ${cs2}   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} WS-ePro ${csW}  ${CYAN}|${NC} UDP      ${cs4}   ${CYAN}|${NC} XRAY    ${cs3}    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} HAPROXY ${cs5}  ${CYAN}|${NC} DROPBEAR ${cs6}   ${CYAN}|${NC} PINGKA  ${cs7}    ${CYAN}|${NC}"
    echo -e "${CYAN}+==================+==================+==================+${NC}"
}

#================================================
# SHOW MAIN MENU
#================================================

show_menu() {
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[01]${NC} SSH MENU     ${CYAN}|${NC} ${WHITE}[08]${NC} BCKP/RSTR    ${CYAN}|${NC} ${WHITE}[15]${NC} MENU BOT    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[02]${NC} VMESS MENU   ${CYAN}|${NC} ${WHITE}[09]${NC} GOTOP X RAM  ${CYAN}|${NC} ${WHITE}[16]${NC} CHG DOMAIN  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[03]${NC} VLESS MENU   ${CYAN}|${NC} ${WHITE}[10]${NC} RESTART ALL  ${CYAN}|${NC} ${WHITE}[17]${NC} FIX CRT     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[04]${NC} TROJAN MENU  ${CYAN}|${NC} ${WHITE}[11]${NC} TELE BOT     ${CYAN}|${NC} ${WHITE}[18]${NC} CHG BANNER  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[05]${NC} NOOBZVPN     ${CYAN}|${NC} ${WHITE}[12]${NC} UPDATE MENU  ${CYAN}|${NC} ${WHITE}[19]${NC} RST BANNER  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[06]${NC} SS - LIBEV   ${CYAN}|${NC} ${WHITE}[13]${NC} RUNNING      ${CYAN}|${NC} ${WHITE}[20]${NC} SPEEDTEST   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[07]${NC} INSTALL UDP  ${CYAN}|${NC} ${WHITE}[14]${NC} INFO PORT    ${CYAN}|${NC} ${WHITE}[21]${NC} EKSTRAK     ${CYAN}|${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC} Script Version = ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
}

#================================================
# SHOW INFO PORT
#================================================

show_info_port() {
    clear
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}            ${WHITE}SERVER PORT INFORMATION${NC}               ${CYAN}|${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "SSH"                    "$SSH_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Dropbear"               "$DROPBEAR_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Nginx"                  "$NGINX_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "HAProxy"                "$HAPROXY_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "XRAY TLS VLESS/VMess"   "$VMESS_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Trojan TLS"             "$TROJAN_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Xray gRPC"              "$XRAY_GRPC_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Xray WS NonTLS"         "$XRAY_WS_NONTLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "BadVPN"                 "$BADVPN_RANGE"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
    read -p "Press Enter..."
}
#================================================
# CREATE ACCOUNT TEMPLATE
#================================================

create_account_template() {
    local protocol="$1"
    local username="$2"
    local days="$3"
    local quota="$4"
    local iplimit="$5"

    local uuid
    uuid=$(cat /proc/sys/kernel/random/uuid)
    local exp
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    local created
    created=$(date +"%d %b, %Y")

    local temp
    temp=$(mktemp)

    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vmess")).settings.clients) += [{"id": $uuid, "email": $email, "alterId": 0}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "vless" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vless")).settings.clients) += [{"id": $uuid, "email": $email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "trojan" ]]; then
        jq --arg password "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("trojan")).settings.clients) += [{"password": $password, "email": $email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    fi

    if [[ $? -eq 0 ]]; then
        mv "$temp" "$XRAY_CONFIG"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        sleep 1
    else
        rm -f "$temp"
        echo -e "${RED}Failed to update Xray config!${NC}"
        sleep 2
        return 1
    fi

    mkdir -p "$AKUN_DIR"
    printf "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    local link_tls link_nontls link_grpc
    local j_tls j_nontls j_grpc

    if [[ "$protocol" == "vmess" ]]; then
        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"%s","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$VMESS_TLS_PORT" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"

        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"%s","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$VMESS_NONTLS_PORT" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"

        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"%s","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
            "$username" "$DOMAIN" "$XRAY_GRPC_PORT" "$uuid")
        link_grpc="vmess://$(printf '%s' "$j_grpc" | base64 -w 0)"

    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:${VLESS_TLS_PORT}?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        link_nontls="vless://${uuid}@bug.com:${VLESS_NONTLS_PORT}?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}"
        link_grpc="vless://${uuid}@${DOMAIN}:${XRAY_GRPC_PORT}?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}"

    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:${TROJAN_TLS_PORT}?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        link_nontls="trojan://${uuid}@bug.com:${XRAY_WS_NONTLS_PORT}?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}"
        link_grpc="trojan://${uuid}@${DOMAIN}:${XRAY_GRPC_PORT}?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}"
    fi

    mkdir -p "$PUBLIC_HTML"
    printf "proxies:\n  - name: \"%s\"\n    type: %s\n    server: %s\n    port: %s\n    uuid: %s\n    alterId: 0\n    cipher: auto\n    tls: true\n    network: ws\n    ws-opts:\n      path: /%s\n      headers:\n        Host: %s\n" \
        "$username" "$protocol" "$DOMAIN" "$VMESS_TLS_PORT" "$uuid" "$protocol" "$DOMAIN" \
        > "$PUBLIC_HTML/${protocol}-${username}.txt"

    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}Xray/${protocol^^} Account${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n"    "Remarks"    "$username"
    printf " %-16s : %s\n"    "Domain"     "$DOMAIN"
    printf " %-16s : %s GB\n" "User Quota" "$quota"
    printf " %-16s : %s IP\n" "User Ip"    "$iplimit"

    case $protocol in
        vmess)
            printf " %-16s : %s\n" "Port TLS"      "$VMESS_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS"   "$VMESS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"     "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "id"            "$uuid"
            printf " %-16s : %s\n" "alterId"       "0"
            printf " %-16s : %s\n" "Security"      "auto"
            printf " %-16s : %s\n" "Network"       "ws"
            printf " %-16s : %s\n" "Path"          "/vmess"
            printf " %-16s : %s\n" "ServiceName"   "vmess-grpc"
            ;;
        vless)
            printf " %-16s : %s\n" "Port TLS"      "$VLESS_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS"   "$VLESS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"     "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "id"            "$uuid"
            printf " %-16s : %s\n" "Encryption"    "none"
            printf " %-16s : %s\n" "Network"       "ws"
            printf " %-16s : %s\n" "Path"          "/vless"
            printf " %-16s : %s\n" "ServiceName"   "vless-grpc"
            ;;
        trojan)
            printf " %-16s : %s\n" "Port TLS"      "$TROJAN_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS"   "$XRAY_WS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"     "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "Password"      "$uuid"
            printf " %-16s : %s\n" "Network"       "ws"
            printf " %-16s : %s\n" "Path"          "/trojan"
            printf " %-16s : %s\n" "ServiceName"   "trojan-grpc"
            ;;
    esac

    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link TLS"      "$link_tls"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link NonTLS"   "$link_nontls"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link GRPC"     "$link_grpc"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : https://%s:%s/%s-%s.txt\n" "OpenClash" "$DOMAIN" "$NGINX_PORT" "$protocol" "$username"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s Hari\n" "Aktif Selama"  "$days"
    printf " %-16s : %s\n"      "Dibuat Pada"   "$created"
    printf " %-16s : %s\n"      "Berakhir Pada" "$exp"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    send_telegram "- ${protocol^^}: $username | Exp: $exp | UUID: $uuid"
    read -p "Press Enter to continue..."
    return 0
}

#================================================
# TRIAL ACCOUNT
#================================================

create_trial() {
    local protocol="$1"
    local username="trial-$(date +%H%M%S)"
    echo -e "${YELLOW}Auto username: ${GREEN}${username}${NC} (1 hari, 1 GB, 1 IP)"
    sleep 1
    create_account_template "$protocol" "$username" 1 1 1
}

#================================================
# SSH ACCOUNT
#================================================

create_ssh() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE SSH ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User     : " username
    [[ -z "$username" ]] && { echo -e "${RED}Username required!${NC}"; sleep 2; return; }
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"; sleep 2; return
    fi
    read -p " Password : " password
    [[ -z "$password" ]] && { echo -e "${RED}Password required!${NC}"; sleep 2; return; }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid days!${NC}"; sleep 2; return; }
    read -p " Limit IP : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1

    local exp exp_date created
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y")

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SSH / OpenVPN Account${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n"    "Remarks"     "$username"
    printf " %-16s : %s\n"    "Domain"      "$DOMAIN"
    printf " %-16s : %s\n"    "Username"    "$username"
    printf " %-16s : %s\n"    "Password"    "$password"
    printf " %-16s : %s IP\n" "User Ip"     "$iplimit"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "SSH Port"    "$SSH_PORT"
    printf " %-16s : %s\n" "Dropbear"    "$DROPBEAR_PORT"
    printf " %-16s : %s\n" "Nginx"       "$NGINX_PORT"
    printf " %-16s : %s\n" "HAProxy"     "$HAPROXY_PORT"
    printf " %-16s : %s\n" "BadVPN"      "$BADVPN_RANGE"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: websocket[crlf][crlf]\n" \
        "Payload WS" "$DOMAIN"
    printf " %-16s : GET wss://%s/ HTTP/1.1[crlf][crlf]\n" \
        "Payload SSL" "$DOMAIN"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : https://%s:%s/ssh-%s.txt\n" "OpenClash" "$DOMAIN" "$NGINX_PORT" "$username"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s Hari\n" "Aktif Selama"  "$days"
    printf " %-16s : %s\n"      "Dibuat Pada"   "$created"
    printf " %-16s : %s\n"      "Berakhir Pada" "$exp"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    send_telegram "- SSH: $username | Pass: $password | Exp: $exp"
    read -p "Press Enter to continue..."
}

create_ssh_trial() {
    local username="trial-$(date +%H%M%S)"
    local password="trial123"
    local exp exp_date created
    exp=$(date -d "+1 days" +"%d %b, %Y")
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y")

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SSH Trial Account${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Domain"    "$DOMAIN"
    printf " %-16s : %s\n" "Username"  "$username"
    printf " %-16s : %s\n" "Password"  "$password"
    printf " %-16s : %s\n" "User Ip"   "1 IP"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "SSH Port"  "$SSH_PORT"
    printf " %-16s : %s\n" "Dropbear"  "$DROPBEAR_PORT"
    printf " %-16s : %s\n" "Nginx"     "$NGINX_PORT"
    printf " %-16s : %s\n" "HAProxy"   "$HAPROXY_PORT"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : 1 Hari\n" "Aktif Selama"
    printf " %-16s : %s\n"     "Dibuat Pada"   "$created"
    printf " %-16s : %s\n"     "Berakhir Pada" "$exp"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    send_telegram "- SSH Trial: $username | Pass: $password | Exp: $exp"
    read -p "Press Enter to continue..."
}

#================================================
# DELETE / RENEW / LIST / CHECK LOGIN
#================================================

delete_account() {
    local protocol="$1"
    clear
    print_menu_header "DELETE ${protocol^^} ACCOUNT"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt 2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" | cut -d= -f2)
        echo -e "  ${CYAN}-${NC} $n  ${YELLOW}(Exp: $e)${NC}"
    done
    echo ""

    read -p "Username to delete: " username
    [[ -z "$username" ]] && return

    local temp
    temp=$(mktemp)
    jq --arg email "$username" \
       'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
       "$XRAY_CONFIG" > "$temp" 2>/dev/null && \
       mv "$temp" "$XRAY_CONFIG" || rm -f "$temp"

    fix_xray_permissions
    systemctl restart xray 2>/dev/null
    rm -f "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && userdel -f "$username" 2>/dev/null

    echo -e "${GREEN}Account ${username} deleted!${NC}"
    sleep 2
}

renew_account() {
    local protocol="$1"
    clear
    print_menu_header "RENEW ${protocol^^} ACCOUNT"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt 2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" | cut -d= -f2)
        echo -e "  ${CYAN}-${NC} $n  ${YELLOW}(Exp: $e)${NC}"
    done
    echo ""

    read -p "Username to renew: " username
    [[ -z "$username" ]] && return
    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && {
        echo -e "${RED}Account not found!${NC}"; sleep 2; return
    }

    read -p "Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"; sleep 2; return
    }

    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")

    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" \
        "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && \
        chage -E "$new_exp_date" "$username" 2>/dev/null

    echo -e "${GREEN}Renewed! New expiry: ${CYAN}${new_exp}${NC}"
    sleep 3
}

list_accounts() {
    local protocol="$1"
    clear
    print_menu_header "${protocol^^} ACCOUNT LIST"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt 2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"; sleep 2; return
    fi

    echo -e "${CYAN}+------------------------------------------------+${NC}"
    printf " %-20s %-15s %-10s\n" "USERNAME" "EXPIRED" "QUOTA"
    echo -e "${CYAN}+------------------------------------------------+${NC}"
    for f in "${files[@]}"; do
        local uname exp quota
        uname=$(basename "$f" .txt | sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f"   | cut -d= -f2)
        quota=$(grep "QUOTA"   "$f" | cut -d= -f2)
        printf " %-20s %-15s %-10s\n" "$uname" "$exp" "${quota:-N/A} GB"
    done
    echo -e "${CYAN}+------------------------------------------------+${NC}"
    echo -e " Total: ${GREEN}${#files[@]}${NC} accounts"
    echo ""
    read -p "Press Enter..."
}

check_user_login() {
    local protocol="$1"
    clear
    print_menu_header "ACTIVE ${protocol^^} LOGINS"
    echo ""
    if [[ "$protocol" == "ssh" ]]; then
        echo -e "${WHITE}Active SSH sessions:${NC}"
        who 2>/dev/null || echo "None"
    else
        echo -e "${WHITE}Active Xray ${protocol^^} connections:${NC}"
        if [[ -f /var/log/xray/access.log ]]; then
            grep -i "$protocol" /var/log/xray/access.log 2>/dev/null | \
                awk '{print $NF}' | sort | uniq -c | sort -rn | head -20 \
                || echo "No data"
        else
            echo "No log data"
        fi
    fi
    echo ""
    read -p "Press Enter..."
}
#================================================
# CREATE VMESS / VLESS / TROJAN
#================================================

create_vmess() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE VMESS ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User: " username
    [[ -z "$username" ]] && { echo -e "${RED}Required${NC}"; sleep 2; return; }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid${NC}"; sleep 2; return; }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=1000
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "vmess" "$username" "$days" "$quota" "$iplimit"
}

create_vless() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE VLESS ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User: " username
    [[ -z "$username" ]] && { echo -e "${RED}Required${NC}"; sleep 2; return; }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid${NC}"; sleep 2; return; }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=1000
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "vless" "$username" "$days" "$quota" "$iplimit"
}

create_trojan() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE TROJAN ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User: " username
    [[ -z "$username" ]] && { echo -e "${RED}Required${NC}"; sleep 2; return; }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid${NC}"; sleep 2; return; }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=1000
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "trojan" "$username" "$days" "$quota" "$iplimit"
}

#================================================
# MENU SSH
#================================================

menu_ssh() {
    while true; do
        clear
        print_menu_header "SSH MENU"
        echo -e "     ${WHITE}[1]${NC} Create SSH Account"
        echo -e "     ${WHITE}[2]${NC} Trial SSH Account"
        echo -e "     ${WHITE}[3]${NC} Delete SSH Account"
        echo -e "     ${WHITE}[4]${NC} Renew SSH Account"
        echo -e "     ${WHITE}[5]${NC} Cek User Login SSH"
        echo -e "     ${WHITE}[6]${NC} Cek User SSH"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_ssh ;;
            2) create_ssh_trial ;;
            3) delete_account "ssh" ;;
            4) renew_account "ssh" ;;
            5) check_user_login "ssh" ;;
            6) list_accounts "ssh" ;;
            0) return ;;
        esac
    done
}

#================================================
# MENU VMESS
#================================================

menu_vmess() {
    while true; do
        clear
        print_menu_header "VMESS MENU"
        echo -e "     ${WHITE}[1]${NC} Create Vmess Account"
        echo -e "     ${WHITE}[2]${NC} Trial Vmess Account"
        echo -e "     ${WHITE}[3]${NC} Delete Account Vmess"
        echo -e "     ${WHITE}[4]${NC} Renew Account Vmess"
        echo -e "     ${WHITE}[5]${NC} Cek User Login Vmess"
        echo -e "     ${WHITE}[6]${NC} Cek User Vmess"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_vmess ;;
            2) create_trial "vmess" ;;
            3) delete_account "vmess" ;;
            4) renew_account "vmess" ;;
            5) check_user_login "vmess" ;;
            6) list_accounts "vmess" ;;
            0) return ;;
        esac
    done
}

#================================================
# MENU VLESS
#================================================

menu_vless() {
    while true; do
        clear
        print_menu_header "VLESS MENU"
        echo -e "     ${WHITE}[1]${NC} Create Vless Account"
        echo -e "     ${WHITE}[2]${NC} Trial Vless Account"
        echo -e "     ${WHITE}[3]${NC} Delete Account Vless"
        echo -e "     ${WHITE}[4]${NC} Renew Account Vless"
        echo -e "     ${WHITE}[5]${NC} Cek User Login Vless"
        echo -e "     ${WHITE}[6]${NC} Cek User Vless"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_vless ;;
            2) create_trial "vless" ;;
            3) delete_account "vless" ;;
            4) renew_account "vless" ;;
            5) check_user_login "vless" ;;
            6) list_accounts "vless" ;;
            0) return ;;
        esac
    done
}

#================================================
# MENU TROJAN
#================================================

menu_trojan() {
    while true; do
        clear
        print_menu_header "TROJAN MENU"
        echo -e "     ${WHITE}[1]${NC} Create Trojan Account"
        echo -e "     ${WHITE}[2]${NC} Trial Trojan Account"
        echo -e "     ${WHITE}[3]${NC} Delete Account Trojan"
        echo -e "     ${WHITE}[4]${NC} Renew Account Trojan"
        echo -e "     ${WHITE}[5]${NC} Cek User Login Trojan"
        echo -e "     ${WHITE}[6]${NC} Cek User Trojan"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) create_trojan ;;
            2) create_trial "trojan" ;;
            3) delete_account "trojan" ;;
            4) renew_account "trojan" ;;
            5) check_user_login "trojan" ;;
            6) list_accounts "trojan" ;;
            0) return ;;
        esac
    done
}

#================================================
# INSTALL UDP CUSTOM
#================================================

install_udp_custom() {
    clear
    echo -e "${CYAN}Installing UDP Custom (BadVPN 7100-7300)...${NC}"

    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select

def handle(data, addr, sock):
    try:
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.settimeout(10)
        ssh.connect(('127.0.0.1', 22))
        ssh.sendall(data)
        resp = ssh.recv(8192)
        sock.sendto(resp, addr)
        ssh.close()
    except:
        pass

sockets = []
for port in range(7100, 7301):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', port))
        sockets.append(s)
    except:
        pass

while True:
    try:
        readable, _, _ = select.select(sockets, [], [], 1)
        for sock in readable:
            try:
                data, addr = sock.recvfrom(8192)
                threading.Thread(
                    target=handle,
                    args=(data, addr, sock),
                    daemon=True
                ).start()
            except:
                pass
    except:
        pass
UDPEOF

    chmod +x /usr/local/bin/udp-custom

    cat > /etc/systemd/system/udp-custom.service << 'UDPSVCEOF'
[Unit]
Description=UDP Custom BadVPN 7100-7300
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/udp-custom
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UDPSVCEOF

    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom
    echo -e "${GREEN}UDP Custom installed! Ports: 7100-7300${NC}"
    sleep 2
}
#================================================
# AUTO INSTALL
#================================================

auto_install() {
    clear
    echo -e "${GREEN}AUTO INSTALLATION - By The Proffessor Squad${NC}"
    echo ""
    read -p "Domain: " DOMAIN
    [[ -z "$DOMAIN" ]] && { echo "Domain required!"; exit 1; }
    echo "$DOMAIN" > "$DOMAIN_FILE"

    echo -e "${CYAN}[1/8]${NC} Installing packages..."
    apt-get update -y >/dev/null 2>&1
    apt-get install -y curl wget jq qrencode unzip uuid-runtime nginx \
        openssh-server dropbear certbot python3 net-tools haproxy \
        netcat-openbsd openssl >/dev/null 2>&1

    echo -e "${CYAN}[2/8]${NC} Installing Xray..."
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        >/dev/null 2>&1

    mkdir -p "$AKUN_DIR" /var/log/xray /usr/local/etc/xray "$PUBLIC_HTML"

    echo -e "${CYAN}[3/8]${NC} Getting SSL certificate..."
    systemctl stop nginx 2>/dev/null
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email >/dev/null 2>&1

    mkdir -p /etc/xray
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
        echo -e "${GREEN}SSL certificate obtained!${NC}"
    else
        echo -e "${YELLOW}Using self-signed certificate...${NC}"
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
            -subj "/CN=$DOMAIN" \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt 2>/dev/null
    fi
    chmod 644 /etc/xray/xray.*

    echo -e "${CYAN}[4/8]${NC} Creating Xray config..."
    create_xray_config

    echo -e "${CYAN}[5/8]${NC} Configuring Nginx (port 80)..."
    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80;
    root /var/www/html;
    index index.html;
    keepalive_timeout 300;
    keepalive_requests 1000;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGXEOF
    systemctl enable nginx 2>/dev/null
    systemctl restart nginx 2>/dev/null

    echo -e "${CYAN}[6/8]${NC} Configuring Dropbear (port 222)..."
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    systemctl enable dropbear 2>/dev/null
    systemctl restart dropbear 2>/dev/null

    echo -e "${CYAN}[7/8]${NC} Configuring HAProxy (port 443)..."
    cat > /etc/haproxy/haproxy.cfg << 'HAEOF'
global
    log /dev/log local0
    maxconn 4096
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    timeout connect 5s
    timeout client  1h
    timeout server  1h
    timeout tunnel  1h

frontend main_443
    bind *:443
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    use_backend xray_tls if { req.ssl_hello_type 1 }
    default_backend xray_tls

backend xray_tls
    server xray 127.0.0.1:8443 check

frontend main_80
    bind *:80
    mode http
    default_backend nginx_80

backend nginx_80
    mode http
    server nginx 127.0.0.1:80 check
HAEOF
    systemctl enable haproxy 2>/dev/null
    systemctl restart haproxy 2>/dev/null

    echo -e "${CYAN}[8/8]${NC} Installing UDP Custom & Keepalive..."
    install_udp_custom >/dev/null 2>&1
    setup_keepalive

    # Configure SSH port 22
    if ! grep -q "^Port 22" /etc/ssh/sshd_config; then
        sed -i 's/^#Port.*/Port 22/' /etc/ssh/sshd_config
        sed -i 's/^Port.*/Port 22/'  /etc/ssh/sshd_config
    fi
    systemctl enable sshd 2>/dev/null
    systemctl restart sshd 2>/dev/null

    # Install speedtest
    echo -e "${CYAN}Installing speedtest...${NC}"
    pip3 install speedtest-cli --break-system-packages 2>/dev/null || \
    pip3 install speedtest-cli 2>/dev/null || \
    apt-get install -y speedtest-cli >/dev/null 2>&1

    systemctl daemon-reload
    for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
        systemctl enable "$svc" 2>/dev/null
        systemctl restart "$svc" 2>/dev/null
    done

    if ! grep -q "tunnel.sh" /root/.bashrc; then
        echo "" >> /root/.bashrc
        echo "[[ -f /root/tunnel.sh ]] && /root/tunnel.sh" >> /root/.bashrc
    fi

    clear
    echo -e "${GREEN}+=========================================+${NC}"
    echo -e "${GREEN}|     Installation Complete!              |${NC}"
    echo -e "${GREEN}+=========================================+${NC}"
    echo ""
    printf " %-24s : %s\n" "Domain"              "$DOMAIN"
    printf " %-24s : %s\n" "SSH"                 "22"
    printf " %-24s : %s\n" "Dropbear"            "222"
    printf " %-24s : %s\n" "Nginx"               "80"
    printf " %-24s : %s\n" "HAProxy"             "443"
    printf " %-24s : %s\n" "Xray TLS VMess/VLess" "8443"
    printf " %-24s : %s\n" "Trojan TLS"          "2083"
    printf " %-24s : %s\n" "Xray gRPC"           "8444"
    printf " %-24s : %s\n" "Xray WS NonTLS"      "8080"
    printf " %-24s : %s\n" "BadVPN"              "7100-7300"
    printf " %-24s : %s\n" "Keepalive"           "Active"
    echo ""
    echo -e "${YELLOW}Rebooting in 5 seconds...${NC}"
    sleep 5
    reboot
}

#================================================
# MAIN MENU
#================================================

main_menu() {
    while true; do
        show_system_info
        show_menu
        read -p "Options [ 1 - 21 ] >>> " choice
        case $choice in
            1)  menu_ssh ;;
            2)  menu_vmess ;;
            3)  menu_vless ;;
            4)  menu_trojan ;;
            7)  install_udp_custom ;;
            10)
                clear
                echo -e "${CYAN}Restarting all services...${NC}"
                echo ""
                for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
                    if systemctl restart "$svc" 2>/dev/null; then
                        echo -e " ${GREEN}+${NC} $svc restarted"
                    else
                        echo -e " ${RED}x${NC} $svc failed"
                    fi
                done
                echo ""
                sleep 2
                ;;
            13)
                clear
                echo -e "${CYAN}+=========================================+${NC}"
                echo -e "${CYAN}|${NC}  ${WHITE}SERVICE STATUS${NC}"
                echo -e "${CYAN}+=========================================+${NC}"
                for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
                    if systemctl is-active --quiet "$svc"; then
                        echo -e " ${GREEN}+${NC} $svc"
                    else
                        echo -e " ${RED}x${NC} $svc"
                    fi
                done
                echo -e "${CYAN}+=========================================+${NC}"
                echo ""
                read -p "Press Enter..."
                ;;
            14) show_info_port ;;
            16) change_domain ;;
            17) fix_certificate ;;
            20) run_speedtest ;;
            0|x)
                clear
                exit 0
                ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

[[ $EUID -ne 0 ]] && { echo "Run as root!"; exit 1; }
[[ ! -f "$DOMAIN_FILE" ]] && auto_install
[[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
main_menu
