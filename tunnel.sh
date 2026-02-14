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
# PORT VARIABLES
# 80   -> Nginx webserver
# 443  -> HAProxy -> Xray 8443
# 8443 -> Xray TLS VMess/VLess
# 2083 -> Xray Trojan TLS
# 8444 -> Xray gRPC
# 8080 -> Xray WS NonTLS
# 22   -> SSH
# 222  -> Dropbear
# 7100-7300 -> BadVPN UDP
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
SS_PORT="8388"
NOOBZ_PORT="1194"

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

get_ip() {
    local ip
    ip=$(curl -s --max-time 3 ifconfig.me 2>/dev/null)
    if [[ -z "$ip" ]] || echo "$ip" | grep -q "error\|reset\|refused"; then
        ip=$(curl -s --max-time 3 ipinfo.io/ip 2>/dev/null)
    fi
    if [[ -z "$ip" ]] || echo "$ip" | grep -q "error\|reset\|refused"; then
        ip=$(curl -s --max-time 3 api.ipify.org 2>/dev/null)
    fi
    if [[ -z "$ip" ]] || echo "$ip" | grep -q "error\|reset\|refused"; then
        ip=$(curl -s --max-time 3 checkip.amazonaws.com 2>/dev/null)
    fi
    if [[ -z "$ip" ]] || echo "$ip" | grep -q "error\|reset\|refused"; then
        ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    fi
    [[ -z "$ip" ]] && ip="N/A"
    echo "$ip"
}

# ================================================
# SETUP SWAP 1GB
# ================================================

setup_swap() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SETUP SWAP 1GB${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    local swap_total
    swap_total=$(free -m | awk 'NR==3{print $2}')
    if [[ "$swap_total" -gt 0 ]]; then
        echo -e "${YELLOW}Swap exists: ${swap_total}MB - Recreating...${NC}"
        swapoff -a
        sed -i '/swapfile/d' /etc/fstab
        rm -f /swapfile
    fi

    echo -e "${CYAN}Creating 1GB swap...${NC}"
    fallocate -l 1G /swapfile 2>/dev/null || \
        dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    swapon /swapfile

    grep -q "/swapfile" /etc/fstab || \
        echo "/swapfile none swap sw 0 0" >> /etc/fstab

    grep -q "vm.swappiness" /etc/sysctl.conf && \
        sed -i 's/vm.swappiness.*/vm.swappiness=10/' /etc/sysctl.conf || \
        echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1

    echo -e "${GREEN}Swap 1GB created! Total: $(free -h | awk 'NR==3{print $2}')${NC}"
    sleep 2
}

# ================================================
# OPTIMIZE VPN
# ================================================

optimize_vpn() {
    echo -e "${CYAN}Optimizing VPN...${NC}"
    cat > /etc/sysctl.d/99-vpn-optimize.conf << 'SYSCTLEOF'
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_fin_timeout = 10
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_forward = 1
net.ipv4.tcp_no_metrics_save = 1
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
SYSCTLEOF

    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf 2>/dev/null
    sysctl -p /etc/sysctl.d/99-vpn-optimize.conf >/dev/null 2>&1

    cat > /etc/security/limits.d/99-vpn.conf << 'LIMEOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
LIMEOF

    mkdir -p /etc/systemd/system.conf.d
    cat > /etc/systemd/system.conf.d/limits.conf << 'SDEOF'
[Manager]
DefaultLimitNOFILE=65535
DefaultLimitNPROC=65535
SDEOF
    echo -e "${GREEN}VPN optimized!${NC}"
}

# ================================================
# SETUP KEEPALIVE
# ================================================

setup_keepalive() {
    local sshcfg="/etc/ssh/sshd_config"
    grep -q "^ClientAliveInterval" "$sshcfg" 2>/dev/null && \
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 30/' "$sshcfg" || \
        echo "ClientAliveInterval 30" >> "$sshcfg"
    grep -q "^ClientAliveCountMax" "$sshcfg" 2>/dev/null && \
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' "$sshcfg" || \
        echo "ClientAliveCountMax 6" >> "$sshcfg"
    grep -q "^TCPKeepAlive" "$sshcfg" 2>/dev/null && \
        sed -i 's/^TCPKeepAlive.*/TCPKeepAlive yes/' "$sshcfg" || \
        echo "TCPKeepAlive yes" >> "$sshcfg"
    systemctl restart sshd 2>/dev/null

    mkdir -p /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service.d/override.conf << 'XKEOF'
[Service]
Restart=always
RestartSec=3
LimitNOFILE=65535
XKEOF

    cat > /usr/local/bin/vpn-keepalive.sh << 'VPNEOF'
#!/bin/bash
while true; do
    GW=$(ip route | awk '/default/{print $3; exit}')
    [[ -n "$GW" ]] && ping -c 1 -W 2 "$GW" >/dev/null 2>&1
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
    for port in 7100 7200 7300; do
        echo -n "ping" | nc -u -w1 127.0.0.1 $port >/dev/null 2>&1
    done
    sleep 25
done
VPNEOF
    chmod +x /usr/local/bin/vpn-keepalive.sh

    cat > /etc/systemd/system/vpn-keepalive.service << 'KASEOF'
[Unit]
Description=VPN Keepalive
After=network.target xray.service

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-keepalive.sh
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
KASEOF

    systemctl daemon-reload
    systemctl enable vpn-keepalive 2>/dev/null
    systemctl restart vpn-keepalive 2>/dev/null
    echo -e "${GREEN}Keepalive configured!${NC}"
}

# ================================================
# NOOBZVPN
# ================================================

install_noobzvpn() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}INSTALL NOOBZVPN${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e "${CYAN}Installing NoobzVPN (OpenVPN-based)...${NC}"

    apt-get install -y openvpn easy-rsa >/dev/null 2>&1

    if [[ ! -d /etc/openvpn/easy-rsa ]]; then
        make-cadir /etc/openvpn/easy-rsa 2>/dev/null || \
            cp -r /usr/share/easy-rsa /etc/openvpn/easy-rsa
    fi

    cd /etc/openvpn/easy-rsa || return

    cat > /etc/openvpn/server.conf << 'OVPNEOF'
port 1194
proto tcp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
OVPNEOF

    # Generate certs jika belum ada
    if [[ ! -f /etc/openvpn/ca.crt ]]; then
        echo -e "${YELLOW}Generating certificates (may take a moment)...${NC}"
        cd /etc/openvpn/easy-rsa
        ./easyrsa init-pki >/dev/null 2>&1
        echo "noobzvpn" | ./easyrsa build-ca nopass >/dev/null 2>&1
        echo "server" | ./easyrsa build-server-full server nopass >/dev/null 2>&1
        ./easyrsa gen-dh >/dev/null 2>&1

        cp pki/ca.crt /etc/openvpn/
        cp pki/issued/server.crt /etc/openvpn/
        cp pki/private/server.key /etc/openvpn/
        cp pki/dh.pem /etc/openvpn/
    fi

    # Generate client config
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/client.ovpn" << CLIENTEOF
client
dev tun
proto tcp
remote $DOMAIN 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
CLIENTEOF

    systemctl enable openvpn@server 2>/dev/null
    systemctl restart openvpn@server 2>/dev/null

    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 2>/dev/null
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ens3 -j MASQUERADE 2>/dev/null

    if systemctl is-active --quiet openvpn@server; then
        echo -e "${GREEN}NoobzVPN (OpenVPN) installed! Port: 1194${NC}"
        echo -e "${GREEN}Client config: https://${DOMAIN}:81/client.ovpn${NC}"
    else
        echo -e "${RED}OpenVPN failed. Check: journalctl -u openvpn@server${NC}"
    fi
    sleep 3
}

menu_noobzvpn() {
    while true; do
        clear
        print_menu_header "NOOBZVPN MENU"
        echo -e "     ${WHITE}[1]${NC} Install NoobzVPN"
        echo -e "     ${WHITE}[2]${NC} Status NoobzVPN"
        echo -e "     ${WHITE}[3]${NC} Restart NoobzVPN"
        echo -e "     ${WHITE}[4]${NC} Stop NoobzVPN"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) install_noobzvpn ;;
            2)
                clear
                echo -e "${WHITE}NoobzVPN Status:${NC}"
                systemctl status openvpn@server --no-pager
                echo ""
                read -p "Press Enter..."
                ;;
            3) systemctl restart openvpn@server
               echo -e "${GREEN}NoobzVPN restarted!${NC}"; sleep 2 ;;
            4) systemctl stop openvpn@server
               echo -e "${YELLOW}NoobzVPN stopped!${NC}"; sleep 2 ;;
            0) return ;;
        esac
    done
}

# ================================================
# SHADOWSOCKS LIBEV
# ================================================

install_ss_libev() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}INSTALL SHADOWSOCKS-LIBEV${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    apt-get install -y shadowsocks-libev >/dev/null 2>&1
    if ! command -v ss-server >/dev/null 2>&1; then
        echo -e "${YELLOW}Adding repo...${NC}"
        apt-get install -y software-properties-common >/dev/null 2>&1
        add-apt-repository -y ppa:max-c-lv/shadowsocks-libev >/dev/null 2>&1
        apt-get update -y >/dev/null 2>&1
        apt-get install -y shadowsocks-libev >/dev/null 2>&1
    fi

    local ss_pass
    ss_pass=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 16)

    mkdir -p /etc/shadowsocks-libev
    cat > /etc/shadowsocks-libev/config.json << SSEOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$ss_pass",
    "timeout": 300,
    "method": "aes-256-gcm",
    "fast_open": true,
    "mode": "tcp_and_udp",
    "plugin": "obfs-local",
    "plugin_opts": "obfs=http;obfs-host=$DOMAIN"
}
SSEOF

    # Install obfs plugin
    apt-get install -y simple-obfs >/dev/null 2>&1

    systemctl enable shadowsocks-libev 2>/dev/null
    systemctl restart shadowsocks-libev 2>/dev/null

    # Simpan info
    mkdir -p "$AKUN_DIR"
    printf "SS_PORT=%s\nSS_PASS=%s\nSS_METHOD=aes-256-gcm\n" \
        "$SS_PORT" "$ss_pass" > "$AKUN_DIR/shadowsocks.txt"

    # Generate SS link
    local ss_b64
    ss_b64=$(echo -n "aes-256-gcm:${ss_pass}" | base64 -w 0)
    local ss_link="ss://${ss_b64}@${DOMAIN}:${SS_PORT}#SS-${DOMAIN}"

    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}Shadowsocks Account${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Host"     "$DOMAIN"
    printf " %-16s : %s\n" "Port"     "$SS_PORT"
    printf " %-16s : %s\n" "Password" "$ss_pass"
    printf " %-16s : %s\n" "Method"   "aes-256-gcm"
    printf " %-16s : %s\n" "Plugin"   "obfs-http"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "SS Link" "$ss_link"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p "Press Enter..."
}

menu_ss_libev() {
    while true; do
        clear
        print_menu_header "SHADOWSOCKS LIBEV"
        echo -e "     ${WHITE}[1]${NC} Install SS-Libev"
        echo -e "     ${WHITE}[2]${NC} Show SS Account"
        echo -e "     ${WHITE}[3]${NC} Restart SS-Libev"
        echo -e "     ${WHITE}[4]${NC} Status SS-Libev"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) install_ss_libev ;;
            2)
                clear
                if [[ -f "$AKUN_DIR/shadowsocks.txt" ]]; then
                    source "$AKUN_DIR/shadowsocks.txt"
                    echo -e "${CYAN}+=========================================+${NC}"
                    echo -e "${CYAN}|${NC}  ${WHITE}Shadowsocks Account${NC}"
                    echo -e "${CYAN}+=========================================+${NC}"
                    printf " %-16s : %s\n" "Host"     "$DOMAIN"
                    printf " %-16s : %s\n" "Port"     "$SS_PORT"
                    printf " %-16s : %s\n" "Password" "$SS_PASS"
                    printf " %-16s : %s\n" "Method"   "$SS_METHOD"
                    echo -e "${CYAN}+=========================================+${NC}"
                else
                    echo -e "${RED}SS not installed yet!${NC}"
                fi
                echo ""
                read -p "Press Enter..."
                ;;
            3) systemctl restart shadowsocks-libev
               echo -e "${GREEN}SS-Libev restarted!${NC}"; sleep 2 ;;
            4)
                clear
                systemctl status shadowsocks-libev --no-pager
                echo ""
                read -p "Press Enter..."
                ;;
            0) return ;;
        esac
    done
}

# ================================================
# CHANGE DOMAIN
# ================================================

change_domain() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CHANGE DOMAIN${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " Current: ${GREEN}${DOMAIN:-Not Set}${NC}"
    echo ""
    read -p " New Domain: " new_domain
    [[ -z "$new_domain" ]] && {
        echo -e "${RED}Domain cannot be empty!${NC}"
        sleep 2; return
    }
    echo "$new_domain" > "$DOMAIN_FILE"
    DOMAIN="$new_domain"
    echo -e "${GREEN}Domain changed to: ${CYAN}${DOMAIN}${NC}"
    echo -e "${YELLOW}Run Fix Certificate [17] to renew SSL!${NC}"
    sleep 3
}

# ================================================
# FIX CERTIFICATE
# ================================================

fix_certificate() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}FIX / RENEW CERTIFICATE${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}Domain not set! Use menu [16] first.${NC}"
        sleep 3; return
    fi

    echo -e " Domain: ${GREEN}${DOMAIN}${NC}"
    echo ""
    echo -e "${CYAN}Stopping services...${NC}"
    systemctl stop haproxy 2>/dev/null
    systemctl stop nginx 2>/dev/null
    sleep 1

    echo -e "${CYAN}Requesting SSL from Let's Encrypt...${NC}"
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        --force-renewal 2>&1 | tail -8

    mkdir -p /etc/xray
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
        chmod 644 /etc/xray/xray.*
        echo -e "${GREEN}Certificate obtained!${NC}"
    else
        echo -e "${YELLOW}Using self-signed cert...${NC}"
        openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
            -subj "/CN=$DOMAIN" \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt 2>/dev/null
        chmod 644 /etc/xray/xray.*
        echo -e "${GREEN}Self-signed cert created.${NC}"
    fi

    systemctl start nginx 2>/dev/null
    systemctl start haproxy 2>/dev/null
    systemctl restart xray 2>/dev/null
    echo -e "${GREEN}Done! Services restarted.${NC}"
    sleep 3
}

# ================================================
# SPEEDTEST
# ================================================

run_speedtest() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SPEEDTEST${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    if command -v speedtest >/dev/null 2>&1; then
        speedtest
    elif command -v speedtest-cli >/dev/null 2>&1; then
        speedtest-cli
    else
        echo -e "${YELLOW}Installing speedtest-cli...${NC}"
        pip3 install speedtest-cli --break-system-packages >/dev/null 2>&1 || \
        pip3 install speedtest-cli >/dev/null 2>&1 || \
        apt-get install -y speedtest-cli >/dev/null 2>&1
        command -v speedtest-cli >/dev/null 2>&1 && speedtest-cli || \
            echo -e "${RED}Install failed. Try: pip3 install speedtest-cli${NC}"
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
# CREATE XRAY CONFIG
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
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "wsSettings": {"path": "/vmess", "headers": {}}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
      "tag": "vmess-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess", "headers": {}}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
      "tag": "vmess-nontls-8080"
    },
    {
      "port": 8443,
      "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "wsSettings": {"path": "/vless", "headers": {}}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
      "tag": "vless-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vless", "headers": {}}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
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
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "wsSettings": {"path": "/trojan", "headers": {}}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
      "tag": "trojan-tls-2083"
    },
    {
      "port": 8444,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "grpcSettings": {"serviceName": "vmess-grpc"}
      },
      "tag": "vmess-grpc-8444"
    },
    {
      "port": 8444,
      "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "grpcSettings": {"serviceName": "vless-grpc"}
      },
      "tag": "vless-grpc-8444"
    },
    {
      "port": 8444,
      "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "grpcSettings": {"serviceName": "trojan-grpc"}
      },
      "tag": "trojan-grpc-8444"
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {"domainStrategy": "UseIPv4"},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "block"
      }
    ]
  }
}
XRAYEOF
    fix_xray_permissions
}

#================================================
# SHOW SYSTEM INFO
#================================================

show_system_info() {
    clear
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && source /etc/os-release && os_name="${PRETTY_NAME}"

    local ip_vps ram swap_info cpu uptime_str
    ip_vps=$(get_ip)
    ram=$(free -m | awk 'NR==2{printf "%s / %s MB", $3, $2}')
    swap_info=$(free -m | awk 'NR==3{printf "%s / %s MB", $3, $2}')
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    uptime_str=$(uptime -p | sed 's/up //')

    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}        ${GREEN}Welcome Mr. ${USERNAME}${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SYSTEM OS"   "$os_name"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SYSTEM CORE" "$(nproc) Core"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SERVER RAM"  "$ram"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" "SWAP"        "$swap_info"
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

    local s1 s2 s3 s4 s5 s6 s7 s8 s9
    s1=$(check_status sshd)
    s2=$(check_status nginx)
    s3=$(check_status xray)
    s4=$(check_status udp-custom)
    s5=$(check_status haproxy)
    s6=$(check_status dropbear)
    s7=$(check_status vpn-keepalive)
    s8=$(check_status openvpn@server)
    s9=$(check_status shadowsocks-libev)

    local cs1 cs2 cs3 cs4 cs5 cs6 cs7 cs8 cs9
    [[ "$s1" == "ON" ]] && cs1="${GREEN}ON ${NC}" || cs1="${RED}OFF${NC}"
    [[ "$s2" == "ON" ]] && cs2="${GREEN}ON ${NC}" || cs2="${RED}OFF${NC}"
    [[ "$s3" == "ON" ]] && cs3="${GREEN}ON ${NC}" || cs3="${RED}OFF${NC}"
    [[ "$s4" == "ON" ]] && cs4="${GREEN}ON ${NC}" || cs4="${RED}OFF${NC}"
    [[ "$s5" == "ON" ]] && cs5="${GREEN}ON ${NC}" || cs5="${RED}OFF${NC}"
    [[ "$s6" == "ON" ]] && cs6="${GREEN}ON ${NC}" || cs6="${RED}OFF${NC}"
    [[ "$s7" == "ON" ]] && cs7="${GREEN}ON ${NC}" || cs7="${RED}OFF${NC}"
    [[ "$s8" == "ON" ]] && cs8="${GREEN}ON ${NC}" || cs8="${RED}OFF${NC}"
    [[ "$s9" == "ON" ]] && cs9="${GREEN}ON ${NC}" || cs9="${RED}OFF${NC}"

    echo -e "${CYAN}+==================+==================+==================+${NC}"
    echo -e "${CYAN}|${NC} SSH     ${cs1}   ${CYAN}|${NC} NOOBZVPN ${cs8} ${CYAN}|${NC} NGINX   ${cs2}   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} SS-LIBEV ${cs9}  ${CYAN}|${NC} UDP      ${cs4}   ${CYAN}|${NC} XRAY    ${cs3}    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} HAPROXY ${cs5}  ${CYAN}|${NC} DROPBEAR ${cs6}   ${CYAN}|${NC} PINGKA  ${cs7}    ${CYAN}|${NC}"
    echo -e "${CYAN}+==================+==================+==================+${NC}"
}

#================================================
# SHOW MAIN MENU
#================================================

show_menu() {
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[01]${NC} SSH MENU     ${CYAN}|${NC} ${WHITE}[08]${NC} SWAP SETUP   ${CYAN}|${NC} ${WHITE}[15]${NC} MENU BOT    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[02]${NC} VMESS MENU   ${CYAN}|${NC} ${WHITE}[09]${NC} OPTIMIZE VPN ${CYAN}|${NC} ${WHITE}[16]${NC} CHG DOMAIN  ${CYAN}|${NC}"
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
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "SSH"                  "$SSH_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Dropbear"             "$DROPBEAR_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Nginx Webserver"      "$NGINX_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "HAProxy SSL"          "$HAPROXY_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Xray TLS VMess/VLess" "$VMESS_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Trojan TLS"           "$TROJAN_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Xray gRPC"            "$XRAY_GRPC_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Xray WS NonTLS"       "$XRAY_WS_NONTLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "Shadowsocks"          "$SS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "NoobzVPN OpenVPN"     "$NOOBZ_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" "BadVPN UDP"           "$BADVPN_RANGE"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
    read -p "Press Enter..."
}
#================================================
# CREATE ACCOUNT TEMPLATE - XRAY
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
        j_tls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"%s","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$VMESS_TLS_PORT" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"

        j_nontls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"%s","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$VMESS_NONTLS_PORT" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"

        j_grpc=$(printf \
            '{"v":"2","ps":"%s","add":"%s","port":"%s","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
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
        "$username" "$protocol" "$DOMAIN" "$VMESS_TLS_PORT" \
        "$uuid" "$protocol" "$DOMAIN" \
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
            printf " %-16s : %s\n" "Port TLS"    "$VMESS_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS" "$VMESS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"   "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "id"          "$uuid"
            printf " %-16s : %s\n" "alterId"     "0"
            printf " %-16s : %s\n" "Security"    "auto"
            printf " %-16s : %s\n" "Network"     "ws"
            printf " %-16s : %s\n" "Path"        "/vmess"
            printf " %-16s : %s\n" "ServiceName" "vmess-grpc"
            ;;
        vless)
            printf " %-16s : %s\n" "Port TLS"    "$VLESS_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS" "$VLESS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"   "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "id"          "$uuid"
            printf " %-16s : %s\n" "Encryption"  "none"
            printf " %-16s : %s\n" "Network"     "ws"
            printf " %-16s : %s\n" "Path"        "/vless"
            printf " %-16s : %s\n" "ServiceName" "vless-grpc"
            ;;
        trojan)
            printf " %-16s : %s\n" "Port TLS"    "$TROJAN_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS" "$XRAY_WS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"   "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "Password"    "$uuid"
            printf " %-16s : %s\n" "Network"     "ws"
            printf " %-16s : %s\n" "Path"        "/trojan"
            printf " %-16s : %s\n" "ServiceName" "trojan-grpc"
            ;;
    esac

    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link TLS"    "$link_tls"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link NonTLS" "$link_nontls"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : %s\n" "Link GRPC"   "$link_grpc"
    echo -e "${CYAN}+=========================================+${NC}"
    printf " %-16s : https://%s:%s/%s-%s.txt\n" \
        "OpenClash" "$DOMAIN" "$NGINX_PORT" "$protocol" "$username"
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
# TRIAL XRAY
#================================================

create_trial() {
    local protocol="$1"
    local username="trial-$(date +%H%M%S)"
    echo -e "${YELLOW}Auto username: ${GREEN}${username}${NC} (1 hari, 1 GB, 1 IP)"
    sleep 1
    create_account_template "$protocol" "$username" 1 1 1
}

#================================================
# CREATE SSH - FORMAT BARU
#================================================

create_ssh() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE SSH ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " Username    : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Username required!${NC}"; sleep 2; return
    }
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"; sleep 2; return
    fi
    read -p " Password    : " password
    [[ -z "$password" ]] && {
        echo -e "${RED}Password required!${NC}"; sleep 2; return
    }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid days!${NC}"; sleep 2; return
    }
    read -p " Limit IP    : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1

    local exp exp_date created ip_vps
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y")
    ip_vps=$(get_ip)

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    # Simpan file info untuk download
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" << SSHFILE
___________________________________________
  SSH & OpenVPN Account
___________________________________________
 Username         : ${username}
 Password         : ${password}
 IP/Host          : ${ip_vps}
 Domain SSH       : ${DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 SSH Ws Non SSL   : 80, 8080
 SSH Ws SSL       : 443, 8443
 OVPN Ws Non SSL  : 80
 OVPN Ws SSL      : 443
 BadVPN UDPGW     : 7100,7200,7300
 Format Hc        : ${DOMAIN}:80@${username}:${password}
___________________________________________
 OVPN Download    : https://${DOMAIN}:81/
___________________________________________
 Save Link        : https://${DOMAIN}:81/ssh-${username}.txt
___________________________________________
 Payload          : GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: ws[crlf][crlf]
___________________________________________
 Aktif Selama     : ${days} Hari
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
SSHFILE

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}SSH & OpenVPN Account${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Username"       "$username"
    printf " %-16s : %s\n" "Password"       "$password"
    printf " %-16s : %s\n" "IP/Host"        "$ip_vps"
    printf " %-16s : %s\n" "Domain SSH"     "$DOMAIN"
    printf " %-16s : %s\n" "OpenSSH"        "22"
    printf " %-16s : %s\n" "Dropbear"       "222"
    printf " %-16s : %s\n" "Port SSH UDP"   "1-65535"
    printf " %-16s : %s\n" "SSL/TLS"        "443"
    printf " %-16s : %s\n" "SSH Ws Non SSL" "80, 8080"
    printf " %-16s : %s\n" "SSH Ws SSL"     "443, 8443"
    printf " %-16s : %s\n" "OVPN Ws NonSSL" "80"
    printf " %-16s : %s\n" "OVPN Ws SSL"    "443"
    printf " %-16s : %s\n" "BadVPN UDPGW"   "7100,7200,7300"
    printf " %-16s : %s:%s@%s:%s\n" \
        "Format Hc" "$DOMAIN" "$NGINX_PORT" "$username" "$password"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/\n" "OVPN Download" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/ssh-%s.txt\n" \
        "Save Link" "$DOMAIN" "$username"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: ws[crlf][crlf]\n" \
        "Payload" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s Hari\n" "Aktif Selama"  "$days"
    printf " %-16s : %s\n"      "Dibuat Pada"   "$created"
    printf " %-16s : %s\n"      "Berakhir Pada" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    send_telegram "- SSH: $username | Pass: $password | IP: $ip_vps | Exp: $exp"
    read -p "Press any key to back on menu..."
}

#================================================
# SSH TRIAL - FORMAT BARU
#================================================

create_ssh_trial() {
    local username="Trial-$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 4 | tr '[:lower:]' '[:upper:]')"
    local password="1"
    local days="1"
    local exp exp_date created ip_vps
    exp=$(date -d "+1 days" +"%d %b, %Y")
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y")
    ip_vps=$(get_ip)

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" << SSHTRIAL
___________________________________________
  Trial SSH & OpenVPN
___________________________________________
 Username         : ${username}
 Password         : ${password}
 IP/Host          : ${ip_vps}
 Domain SSH       : ${DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 SSH Ws Non SSL   : 80, 8080
 SSH Ws SSL       : 443, 8443
 OVPN Ws Non SSL  : 80
 OVPN Ws SSL      : 443
 BadVPN UDPGW     : 7100,7200,7300
 Format Hc        : ${DOMAIN}:80@${username}:${password}
___________________________________________
 OVPN Download    : https://${DOMAIN}:81/
___________________________________________
 Save Link        : https://${DOMAIN}:81/ssh-${username}.txt
___________________________________________
 Payload          : GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: ws[crlf][crlf]
___________________________________________
 Aktif Selama     : 1 Hari (Trial)
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
SSHTRIAL

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}Trial SSH & OpenVPN${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Username"       "$username"
    printf " %-16s : %s\n" "Password"       "$password"
    printf " %-16s : %s\n" "IP/Host"        "$ip_vps"
    printf " %-16s : %s\n" "Domain SSH"     "$DOMAIN"
    printf " %-16s : %s\n" "OpenSSH"        "22"
    printf " %-16s : %s\n" "Dropbear"       "222"
    printf " %-16s : %s\n" "Port SSH UDP"   "1-65535"
    printf " %-16s : %s\n" "SSL/TLS"        "443"
    printf " %-16s : %s\n" "SSH Ws Non SSL" "80, 8080"
    printf " %-16s : %s\n" "SSH Ws SSL"     "443, 8443"
    printf " %-16s : %s\n" "OVPN Ws NonSSL" "80"
    printf " %-16s : %s\n" "OVPN Ws SSL"    "443"
    printf " %-16s : %s\n" "BadVPN UDPGW"   "7100,7200,7300"
    printf " %-16s : %s:%s@%s:%s\n" \
        "Format Hc" "$DOMAIN" "$NGINX_PORT" "$username" "$password"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/\n" "OVPN Download" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/ssh-%s.txt\n" \
        "Save Link" "$DOMAIN" "$username"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: ws[crlf][crlf]\n" \
        "Payload" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : 1 Hari (Trial)\n" "Aktif Selama"
    printf " %-16s : %s\n" "Dibuat Pada"   "$created"
    printf " %-16s : %s\n" "Berakhir Pada" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    send_telegram "- SSH Trial: $username | Pass: $password | IP: $ip_vps | Exp: $exp"
    read -p "Press any key to back on menu..."
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
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"
        sleep 2; return
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
    rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"
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
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"
        sleep 2; return
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
        echo -e "${RED}No ${protocol^^} accounts found!${NC}"
        sleep 2; return
    fi

    echo -e "${CYAN}+------------------------------------------------+${NC}"
    printf " %-20s %-15s %-10s\n" "USERNAME" "EXPIRED" "QUOTA"
    echo -e "${CYAN}+------------------------------------------------+${NC}"
    for f in "${files[@]}"; do
        local uname exp quota
        uname=$(basename "$f" .txt | sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f"   | cut -d= -f2)
        quota=$(grep "QUOTA"   "$f" | cut -d= -f2)
        printf " %-20s %-15s %-10s\n" \
            "$uname" "$exp" "${quota:-N/A} GB"
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
        echo ""
        echo -e "${WHITE}SSH login count per user:${NC}"
        who | awk '{print $1}' | sort | uniq -c | sort -rn
    else
        echo -e "${WHITE}Active Xray ${protocol^^} connections:${NC}"
        if [[ -f /var/log/xray/access.log ]]; then
            grep -i "$protocol" /var/log/xray/access.log 2>/dev/null | \
                awk '{print $NF}' | sort | uniq -c | \
                sort -rn | head -20 || echo "No data"
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
        echo -e "     ${WHITE}[6]${NC} List User SSH"
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
        echo -e "     ${WHITE}[6]${NC} List User Vmess"
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
        echo -e "     ${WHITE}[6]${NC} List User Vless"
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
        echo -e "     ${WHITE}[6]${NC} List User Trojan"
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
# INSTALL UDP CUSTOM 7100-7300
#================================================

install_udp_custom() {
    clear
    echo -e "${CYAN}Installing UDP Custom (BadVPN 7100-7300)...${NC}"

    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select, time

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
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
        s.bind(('0.0.0.0', port))
        s.setblocking(False)
        sockets.append(s)
    except:
        pass

print(f"UDP Custom listening on {len(sockets)} ports (7100-7300)")

while True:
    try:
        readable, _, _ = select.select(sockets, [], [], 1)
        for sock in readable:
            try:
                data, addr = sock.recvfrom(8192)
                t = threading.Thread(
                    target=handle,
                    args=(data, addr, sock),
                    daemon=True
                )
                t.start()
            except:
                pass
    except:
        time.sleep(1)
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
RestartSec=3
LimitNOFILE=65535
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
UDPSVCEOF

    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom
    sleep 1

    if systemctl is-active --quiet udp-custom; then
        echo -e "${GREEN}UDP Custom running! Ports: 7100-7300${NC}"
    else
        echo -e "${RED}UDP Custom failed!${NC}"
        journalctl -u udp-custom -n 5 --no-pager
    fi
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

    echo -e "${CYAN}[1/9]${NC} Installing packages..."
    apt-get update -y >/dev/null 2>&1
    apt-get install -y curl wget jq qrencode unzip uuid-runtime nginx \
        openssh-server dropbear certbot python3 python3-pip net-tools \
        haproxy netcat-openbsd openssl >/dev/null 2>&1

    echo -e "${CYAN}[2/9]${NC} Installing Xray..."
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        >/dev/null 2>&1

    mkdir -p "$AKUN_DIR" /var/log/xray /usr/local/etc/xray "$PUBLIC_HTML"

    echo -e "${CYAN}[3/9]${NC} Setting up Swap 1GB..."
    if [[ $(free -m | awk 'NR==3{print $2}') -lt 512 ]]; then
        fallocate -l 1G /swapfile 2>/dev/null || \
            dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
        chmod 600 /swapfile
        mkswap /swapfile >/dev/null 2>&1
        swapon /swapfile
        grep -q "/swapfile" /etc/fstab || \
            echo "/swapfile none swap sw 0 0" >> /etc/fstab
        echo -e "${GREEN}Swap 1GB created!${NC}"
    else
        echo -e "${YELLOW}Swap exists, skipping...${NC}"
    fi

    echo -e "${CYAN}[4/9]${NC} Getting SSL certificate..."
    systemctl stop nginx 2>/dev/null
    systemctl stop haproxy 2>/dev/null
    sleep 1

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

    echo -e "${CYAN}[5/9]${NC} Creating Xray config..."
    create_xray_config

    echo -e "${CYAN}[6/9]${NC} Configuring Nginx (port 80)..."
    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html index.htm;

    keepalive_timeout 300;
    keepalive_requests 10000;

    # Serve account files
    location / {
        try_files $uri $uri/ =404;
        autoindex on;
    }

    # VMess NonTLS WebSocket
    location /vmess {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
    }

    # VLess NonTLS WebSocket
    location /vless {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
    }

    # Trojan NonTLS WebSocket
    location /trojan {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
    }
}

# Port 81 untuk download file
server {
    listen 81;
    server_name _;
    root /var/www/html;
    index index.html;
    autoindex on;
    location / {
        try_files $uri $uri/ =404;
    }
}
NGXEOF

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/default \
        /etc/nginx/sites-enabled/default

    nginx -t >/dev/null 2>&1 && \
        echo -e "${GREEN}Nginx config OK!${NC}" || \
        echo -e "${RED}Nginx config error!${NC}"

    echo -e "${CYAN}[7/9]${NC} Configuring Dropbear (port 222)..."
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF

    echo -e "${CYAN}[8/9]${NC} Configuring HAProxy (443 -> Xray 8443)..."
    cat > /etc/haproxy/haproxy.cfg << 'HAEOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 65535
    tune.ssl.default-dh-param 2048

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    option tcp-smart-accept
    option tcp-smart-connect
    timeout connect 5s
    timeout client  1h
    timeout server  1h
    timeout tunnel  1h
    maxconn 65535

# Port 443 -> Xray TLS 8443
frontend front_443
    bind *:443
    mode tcp
    default_backend back_xray_tls

backend back_xray_tls
    mode tcp
    server xray_tls 127.0.0.1:8443 check inter 3s rise 2 fall 3
HAEOF

    haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1 && \
        echo -e "${GREEN}HAProxy config OK!${NC}" || \
        echo -e "${RED}HAProxy config error!${NC}"

    echo -e "${CYAN}[9/9]${NC} Installing UDP, Keepalive & Optimizing..."
    install_udp_custom >/dev/null 2>&1
    setup_keepalive
    optimize_vpn

    # SSH port 22
    sed -i 's/^#\?Port.*/Port 22/' /etc/ssh/sshd_config

    # Install speedtest
    pip3 install speedtest-cli --break-system-packages >/dev/null 2>&1 || \
        pip3 install speedtest-cli >/dev/null 2>&1 || \
        apt-get install -y speedtest-cli >/dev/null 2>&1

    # Enable & start semua service
    systemctl daemon-reload
    echo ""
    echo -e "${CYAN}Starting services...${NC}"
    for svc in xray nginx sshd dropbear haproxy \
               udp-custom vpn-keepalive; do
        systemctl enable "$svc" 2>/dev/null
        systemctl restart "$svc" 2>/dev/null
        if systemctl is-active --quiet "$svc"; then
            echo -e " ${GREEN}+${NC} $svc"
        else
            echo -e " ${RED}x${NC} $svc"
        fi
    done

    # Auto run on login
    if ! grep -q "tunnel.sh" /root/.bashrc; then
        echo "" >> /root/.bashrc
        echo "[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh" \
            >> /root/.bashrc
    fi

    # Buat halaman index untuk download
    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html>
<html>
<head><title>${DOMAIN} VPN Server</title></head>
<body>
<h2>VPN Server - ${DOMAIN}</h2>
<p>Server is running.</p>
</body>
</html>
IDXEOF

    clear
    echo -e "${GREEN}+=========================================+${NC}"
    echo -e "${GREEN}|       Installation Complete!            |${NC}"
    echo -e "${GREEN}+=========================================+${NC}"
    echo ""
    printf " %-26s : %s\n" "Domain"                "$DOMAIN"
    printf " %-26s : %s\n" "IP VPS"                "$(get_ip)"
    printf " %-26s : %s\n" "SSH"                   "22"
    printf " %-26s : %s\n" "Dropbear"              "222"
    printf " %-26s : %s\n" "Nginx"                 "80, 81"
    printf " %-26s : %s\n" "HAProxy"               "443 -> Xray 8443"
    printf " %-26s : %s\n" "Xray TLS VMess/VLess"  "8443"
    printf " %-26s : %s\n" "Trojan TLS"            "2083"
    printf " %-26s : %s\n" "Xray gRPC"             "8444"
    printf " %-26s : %s\n" "Xray WS NonTLS"        "8080"
    printf " %-26s : %s\n" "BadVPN UDP"            "7100-7300"
    printf " %-26s : %s\n" "Swap"                  "1GB"
    printf " %-26s : %s\n" "BBR"                   "Enabled"
    printf " %-26s : %s\n" "Keepalive"             "Active"
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
            5)  menu_noobzvpn ;;
            6)  menu_ss_libev ;;
            7)  install_udp_custom ;;
            8)  setup_swap ;;
            9)
                optimize_vpn
                echo -e "${GREEN}Optimization applied!${NC}"
                sleep 2
                ;;
            10)
                clear
                echo -e "${CYAN}Restarting all services...${NC}"
                echo ""
                for svc in xray nginx sshd dropbear haproxy \
                           udp-custom vpn-keepalive \
                           openvpn@server shadowsocks-libev; do
                    if systemctl restart "$svc" 2>/dev/null; then
                        echo -e " ${GREEN}+${NC} $svc"
                    else
                        echo -e " ${RED}x${NC} $svc"
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
                for svc in xray nginx sshd dropbear haproxy \
                           udp-custom vpn-keepalive \
                           openvpn@server shadowsocks-libev; do
                    if systemctl is-active --quiet "$svc"; then
                        echo -e " ${GREEN}+${NC} $svc ${GREEN}[RUNNING]${NC}"
                    else
                        echo -e " ${RED}x${NC} $svc ${RED}[STOPPED]${NC}"
                    fi
                done
                echo -e "${CYAN}+=========================================+${NC}"
                echo ""
                echo -e "${WHITE}Port Status:${NC}"
                ss -tulpn | grep -E \
                    ':22 |:80 |:81 |:222 |:443 |:1194 |:2083 |:8080 |:8388 |:8443 |:8444 ' \
                    2>/dev/null | \
                    awk '{print $1, $5}' | \
                    while read p a; do
                        echo -e " ${GREEN}+${NC} $p $a"
                    done
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
