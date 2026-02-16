#!/bin/bash

#================================================
# Auto Script VPN Server - PROFFESSOR SQUAD
# By The Proffessor Squad
# Version: 1.0.0
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
SCRIPT_VERSION="1.0.0"
SCRIPT_AUTHOR="By The Proffessor Squad"
GITHUB_USER="putrinuroktavia234-max"
GITHUB_REPO="Tunnel"
GITHUB_BRANCH="main"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/tunnel.sh"
VERSION_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/version"
SCRIPT_PATH="/root/tunnel.sh"
BACKUP_PATH="/root/tunnel.sh.bak"
PUBLIC_HTML="/var/www/html"
USERNAME="YouzinCrabz"
BOT_TOKEN_FILE="/root/.bot_token"
CHAT_ID_FILE="/root/.chat_id"
BOT_PID_FILE="/root/.bot_pid"
ORDER_DIR="/root/orders"

# ================================================
# PORT VARIABLES
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

# Harga & durasi
PRICE_MONTHLY="10000"
DURATION_MONTHLY="30"
TRIAL_DURATION="1h"
TRIAL_QUOTA="1"

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

send_telegram() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    local token
    token=$(cat "$BOT_TOKEN_FILE")
    local chatid="$1"
    local msg="$2"
    curl -s -X POST \
        "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" \
        -d text="$msg" \
        -d parse_mode="HTML" >/dev/null 2>&1
}

send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] || [[ ! -f "$CHAT_ID_FILE" ]] && return
    local token
    token=$(cat "$BOT_TOKEN_FILE")
    local chatid
    chatid=$(cat "$CHAT_ID_FILE")
    curl -s -X POST \
        "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" \
        -d text="$1" \
        -d parse_mode="HTML" >/dev/null 2>&1
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
# COMMAND MENU - ketik 'menu' kapanpun
# ================================================

setup_menu_command() {
    # Buat script /usr/local/bin/menu
    cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
if [[ -f /root/tunnel.sh ]]; then
    bash /root/tunnel.sh
else
    echo "Script not found: /root/tunnel.sh"
fi
MENUEOF
    chmod +x /usr/local/bin/menu

    # Tambah ke .bashrc kalau belum ada
    if ! grep -q "tunnel.sh" /root/.bashrc; then
        cat >> /root/.bashrc << 'BASHEOF'

# Auto run VPN menu
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh
BASHEOF
    fi

    # Tambah alias
    if ! grep -q "alias menu" /root/.bashrc; then
        echo "alias menu='bash /root/tunnel.sh'" >> /root/.bashrc
    fi
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
    echo -e "${GREEN}Swap 1GB created!${NC}"
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
# SHADOWSOCKS LIBEV - FIXED
# ================================================

install_ss_libev() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}INSTALL SHADOWSOCKS-LIBEV${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    echo -e "${CYAN}Installing shadowsocks-libev...${NC}"

    # Fix untuk Ubuntu 22.04
    apt-get install -y shadowsocks-libev >/dev/null 2>&1

    # Cek apakah berhasil
    if ! command -v ss-server >/dev/null 2>&1; then
        echo -e "${YELLOW}Trying alternative install...${NC}"
        apt-get install -y software-properties-common >/dev/null 2>&1
        add-apt-repository -y ppa:max-c-lv/shadowsocks-libev \
            >/dev/null 2>&1
        apt-get update -y >/dev/null 2>&1
        apt-get install -y shadowsocks-libev >/dev/null 2>&1
    fi

    if ! command -v ss-server >/dev/null 2>&1; then
        echo -e "${RED}SS-Libev install failed!${NC}"
        echo -e "${YELLOW}Try manual: apt install shadowsocks-libev${NC}"
        sleep 3; return
    fi

    local ss_pass
    ss_pass=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 16)
    local ip_vps
    ip_vps=$(get_ip)

    mkdir -p /etc/shadowsocks-libev
    cat > /etc/shadowsocks-libev/config.json << SSEOF
{
    "server": "0.0.0.0",
    "server_port": $SS_PORT,
    "password": "$ss_pass",
    "timeout": 300,
    "method": "aes-256-gcm",
    "fast_open": true,
    "mode": "tcp_and_udp"
}
SSEOF

    # Fix service name Ubuntu 22.04
    local ss_service="shadowsocks-libev"
    if ! systemctl list-unit-files | grep -q "shadowsocks-libev.service"; then
        ss_service="shadowsocks"
    fi

    systemctl enable "$ss_service" 2>/dev/null
    systemctl restart "$ss_service" 2>/dev/null
    sleep 1

    local ss_b64
    ss_b64=$(echo -n "aes-256-gcm:${ss_pass}" | base64 -w 0)
    local ss_link="ss://${ss_b64}@${ip_vps}:${SS_PORT}#SS-${DOMAIN}"

    mkdir -p "$AKUN_DIR"
    printf "SS_PORT=%s\nSS_PASS=%s\nSS_METHOD=aes-256-gcm\nSS_LINK=%s\n" \
        "$SS_PORT" "$ss_pass" "$ss_link" > "$AKUN_DIR/shadowsocks.txt"

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}Shadowsocks-Libev Account${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "IP/Host"   "$ip_vps"
    printf " %-16s : %s\n" "Domain"    "$DOMAIN"
    printf " %-16s : %s\n" "Port"      "$SS_PORT"
    printf " %-16s : %s\n" "Password"  "$ss_pass"
    printf " %-16s : %s\n" "Method"    "aes-256-gcm"
    printf " %-16s : %s\n" "Plugin"    "none"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "SS Link"   "$ss_link"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    read -p "Press any key to back on menu..."
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
                    local ip_vps
                    ip_vps=$(get_ip)
                    echo -e "${CYAN}___________________________________________${NC}"
                    echo -e "  ${WHITE}Shadowsocks-Libev Account${NC}"
                    echo -e "${CYAN}___________________________________________${NC}"
                    printf " %-16s : %s\n" "IP/Host"  "$ip_vps"
                    printf " %-16s : %s\n" "Domain"   "$DOMAIN"
                    printf " %-16s : %s\n" "Port"     "$SS_PORT"
                    printf " %-16s : %s\n" "Password" "$SS_PASS"
                    printf " %-16s : %s\n" "Method"   "$SS_METHOD"
                    echo -e "${CYAN}___________________________________________${NC}"
                    printf " %-16s : %s\n" "SS Link"  "$SS_LINK"
                    echo -e "${CYAN}___________________________________________${NC}"
                else
                    echo -e "${RED}SS not installed yet!${NC}"
                fi
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            3)
                systemctl restart shadowsocks-libev 2>/dev/null || \
                systemctl restart shadowsocks 2>/dev/null
                echo -e "${GREEN}SS-Libev restarted!${NC}"; sleep 2
                ;;
            4)
                clear
                systemctl status shadowsocks-libev --no-pager 2>/dev/null || \
                systemctl status shadowsocks --no-pager 2>/dev/null
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            0) return ;;
        esac
    done
}

# ================================================
# NOOBZVPN - FIXED & DETAIL
# ================================================

install_noobzvpn() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}INSTALL NOOBZVPN (OpenVPN)${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    echo -e "${CYAN}Installing OpenVPN...${NC}"
    apt-get install -y openvpn easy-rsa >/dev/null 2>&1

    local ip_vps
    ip_vps=$(get_ip)

    # Setup easy-rsa
    local easyrsa_dir="/etc/openvpn/easy-rsa"
    if [[ ! -d "$easyrsa_dir" ]]; then
        make-cadir "$easyrsa_dir" 2>/dev/null || \
            cp -r /usr/share/easy-rsa "$easyrsa_dir"
    fi

    # Generate certs
    if [[ ! -f /etc/openvpn/ca.crt ]]; then
        echo -e "${CYAN}Generating certificates...${NC}"
        cd "$easyrsa_dir" || return
        ./easyrsa init-pki >/dev/null 2>&1
        echo "noobzvpn" | ./easyrsa build-ca nopass >/dev/null 2>&1
        echo "server" | \
            ./easyrsa build-server-full server nopass >/dev/null 2>&1
        ./easyrsa gen-dh >/dev/null 2>&1
        openvpn --genkey secret ta.key 2>/dev/null

        cp pki/ca.crt /etc/openvpn/
        cp pki/issued/server.crt /etc/openvpn/
        cp pki/private/server.key /etc/openvpn/
        cp pki/dh.pem /etc/openvpn/
        [[ -f ta.key ]] && cp ta.key /etc/openvpn/
    fi

    # Server config
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
auth SHA256
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
explicit-exit-notify 1
OVPNEOF

    # IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' \
        /etc/sysctl.conf 2>/dev/null
    grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf || \
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1

    # NAT rules
    local iface
    iface=$(ip route | awk '/default/{print $5; exit}')
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 \
        -o "$iface" -j MASQUERADE 2>/dev/null

    # Generate client config
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/client.ovpn" << CLIENTEOF
client
dev tun
proto tcp
remote $ip_vps 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
verb 3
<ca>
$(cat /etc/openvpn/ca.crt)
</ca>
CLIENTEOF

    systemctl enable openvpn@server 2>/dev/null
    systemctl restart openvpn@server 2>/dev/null
    sleep 2

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}NoobzVPN (OpenVPN) Account${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "IP/Host"       "$ip_vps"
    printf " %-16s : %s\n" "Domain"        "$DOMAIN"
    printf " %-16s : %s\n" "Protocol"      "TCP"
    printf " %-16s : %s\n" "Port"          "1194"
    printf " %-16s : %s\n" "Cipher"        "AES-256-CBC"
    printf " %-16s : %s\n" "Auth"          "SHA256"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/client.ovpn\n" \
        "Config Download" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    if systemctl is-active --quiet openvpn@server; then
        echo -e " Status          : ${GREEN}RUNNING${NC}"
    else
        echo -e " Status          : ${RED}FAILED${NC}"
        echo -e " ${YELLOW}Check: journalctl -u openvpn@server${NC}"
    fi
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

menu_noobzvpn() {
    while true; do
        clear
        print_menu_header "NOOBZVPN MENU"
        echo -e "     ${WHITE}[1]${NC} Install NoobzVPN"
        echo -e "     ${WHITE}[2]${NC} Show Config Info"
        echo -e "     ${WHITE}[3]${NC} Restart NoobzVPN"
        echo -e "     ${WHITE}[4]${NC} Status NoobzVPN"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) install_noobzvpn ;;
            2)
                clear
                local ip_vps
                ip_vps=$(get_ip)
                echo -e "${CYAN}___________________________________________${NC}"
                echo -e "  ${WHITE}NoobzVPN (OpenVPN) Info${NC}"
                echo -e "${CYAN}___________________________________________${NC}"
                printf " %-16s : %s\n" "IP/Host"       "$ip_vps"
                printf " %-16s : %s\n" "Domain"        "$DOMAIN"
                printf " %-16s : %s\n" "Protocol"      "TCP"
                printf " %-16s : %s\n" "Port"          "1194"
                printf " %-16s : %s\n" "Cipher"        "AES-256-CBC"
                echo -e "${CYAN}___________________________________________${NC}"
                printf " %-16s : https://%s:81/client.ovpn\n" \
                    "Config Download" "$DOMAIN"
                echo -e "${CYAN}___________________________________________${NC}"
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            3)
                systemctl restart openvpn@server
                echo -e "${GREEN}NoobzVPN restarted!${NC}"; sleep 2
                ;;
            4)
                clear
                systemctl status openvpn@server --no-pager
                echo ""
                read -p "Press any key to back on menu..."
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

    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
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
        pip3 install speedtest-cli \
            --break-system-packages >/dev/null 2>&1 || \
        pip3 install speedtest-cli >/dev/null 2>&1 || \
        apt-get install -y speedtest-cli >/dev/null 2>&1
        command -v speedtest-cli >/dev/null 2>&1 && \
            speedtest-cli || \
            echo -e "${RED}Install failed.${NC}"
    fi
    echo ""
    read -p "Press any key to back on menu..."
}

# ================================================
# UPDATE MENU
# ================================================

update_menu() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}UPDATE SCRIPT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " Current Version : ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e " GitHub          : ${GREEN}${GITHUB_USER}/${GITHUB_REPO}${NC}"
    echo ""

    echo -e "${CYAN}Checking GitHub connection...${NC}"
    if ! curl -s --max-time 10 \
        "https://github.com/${GITHUB_USER}/${GITHUB_REPO}" \
        >/dev/null 2>&1; then
        echo -e "${RED}Cannot reach GitHub!${NC}"
        read -p "Press Enter..."; return
    fi
    echo -e "${GREEN}Connected!${NC}"

    echo -e "${CYAN}Checking latest version...${NC}"
    local latest_version
    latest_version=$(curl -s --max-time 10 \
        "$VERSION_URL" 2>/dev/null | tr -d '\n\r' | xargs)

    if [[ -z "$latest_version" ]]; then
        echo -e "${RED}Cannot get version from GitHub!${NC}"
        echo -e "${YELLOW}Make sure 'version' file exists in repo.${NC}"
        read -p "Press Enter..."; return
    fi

    echo -e " Latest Version  : ${GREEN}${latest_version}${NC}"
    echo ""

    if [[ "$latest_version" == "$SCRIPT_VERSION" ]]; then
        echo -e "${GREEN}Already up to date! (v${SCRIPT_VERSION})${NC}"
        read -p "Press Enter..."; return
    fi

    # Tampil changelog
    local changelog
    changelog=$(curl -s --max-time 10 \
        "https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/changelog.md" \
        2>/dev/null | head -15)
    if [[ -n "$changelog" ]]; then
        echo -e "${WHITE}=== CHANGELOG v${latest_version} ===${NC}"
        echo "$changelog"
        echo -e "${WHITE}================================${NC}"
        echo ""
    fi

    echo -e "${YELLOW}Update v${SCRIPT_VERSION} -> v${latest_version}?${NC}"
    read -p "Continue? [y/n]: " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
        echo -e "${YELLOW}Cancelled.${NC}"; sleep 2; return
    }

    echo ""
    echo -e "${CYAN}[1/4]${NC} Backing up..."
    cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null && \
        echo -e "${GREEN}Backup saved!${NC}" || {
        echo -e "${RED}Backup failed!${NC}"; sleep 2; return
    }

    echo -e "${CYAN}[2/4]${NC} Downloading..."
    local tmp_file="/tmp/tunnel_new.sh"
    local chars="/-\|"
    local i=0
    curl -s --max-time 60 "$SCRIPT_URL" -o "$tmp_file" &
    local curl_pid=$!
    while kill -0 $curl_pid 2>/dev/null; do
        printf "\r Downloading [%c]" "${chars:$((i % 4)):1}"
        sleep 0.2
        ((i++))
    done
    wait $curl_pid
    local curl_exit=$?
    printf "\r Downloading [${GREEN}DONE${NC}]     \n"

    if [[ $curl_exit -ne 0 ]] || [[ ! -s "$tmp_file" ]]; then
        echo -e "${RED}Download failed! Rolling back...${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        rm -f "$tmp_file"; sleep 2; return
    fi

    echo -e "${CYAN}[3/4]${NC} Validating..."
    if ! bash -n "$tmp_file" 2>/dev/null; then
        echo -e "${RED}Validation failed! Rolling back...${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        rm -f "$tmp_file"; sleep 2; return
    fi
    echo -e "${GREEN}Valid!${NC}"

    echo -e "${CYAN}[4/4]${NC} Applying update..."
    mv "$tmp_file" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"

    echo ""
    echo -e "${GREEN}Update successful! v${SCRIPT_VERSION} -> v${latest_version}${NC}"
    echo -e "${YELLOW}Restarting in 3 seconds...${NC}"
    sleep 3
    exec bash "$SCRIPT_PATH"
}

rollback_script() {
    clear
    print_menu_header "ROLLBACK SCRIPT"
    echo ""

    if [[ ! -f "$BACKUP_PATH" ]]; then
        echo -e "${RED}No backup found!${NC}"
        read -p "Press Enter..."; return
    fi

    local backup_version
    backup_version=$(grep "SCRIPT_VERSION=" "$BACKUP_PATH" | \
        head -1 | cut -d'"' -f2)

    echo -e " Current : ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e " Backup  : ${YELLOW}${backup_version:-Unknown}${NC}"
    echo ""
    read -p "Rollback? [y/n]: " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
        sleep 2; return
    }

    cp "$BACKUP_PATH" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}Rollback done!${NC}"
    sleep 3
    exec bash "$SCRIPT_PATH"
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
    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && \
        source /etc/os-release && os_name="${PRETTY_NAME}"

    local ip_vps ram swap_info cpu uptime_str
    ip_vps=$(get_ip)
    ram=$(free -m | awk 'NR==2{printf "%s / %s MB", $3, $2}')
    swap_info=$(free -m | awk 'NR==3{printf "%s / %s MB", $3, $2}')
    cpu=$(top -bn1 | grep "Cpu(s)" | \
        awk '{print $2}' | cut -d'%' -f1)
    uptime_str=$(uptime -p | sed 's/up //')

    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}        ${GREEN}Welcome Mr. ${USERNAME}${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "SYSTEM OS"   "$os_name"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "SYSTEM CORE" "$(nproc) Core"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "SERVER RAM"  "$ram"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "SWAP"        "$swap_info"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "LOAD CPU"    "${cpu}%"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "DATE"        "$(date +"%d-%m-%Y")"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "TIME"        "$(date +"%H:%M:%S")"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "UPTIME"      "$uptime_str"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "IP VPS"      "$ip_vps"
    printf "${CYAN}|${NC} ${WHITE}*${NC} %-15s = ${GREEN}%-30s${NC} ${CYAN}|${NC}\n" \
        "DOMAIN"      "${DOMAIN:-Not Set}"
    echo -e "${CYAN}+========================================================+${NC}"

    local vc lc tc sc
    vc=$(ls "$AKUN_DIR"/vmess-*.txt  2>/dev/null | wc -l)
    lc=$(ls "$AKUN_DIR"/vless-*.txt  2>/dev/null | wc -l)
    tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    sc=$(ls "$AKUN_DIR"/ssh-*.txt    2>/dev/null | wc -l)

    echo -e "              ${CYAN}>>> INFORMATION ACCOUNT <<<${NC}"
    echo -e "     ${CYAN}===============================================${NC}"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "SSH/OPENVPN/UDP" "$sc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "VMESS/WS/GRPC"   "$vc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "VLESS/WS/GRPC"   "$lc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "TROJAN/WS/GRPC"  "$tc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "SHADOW/WS/GRPC"  "0"
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
    [[ "$s9" == "OFF" ]] && s9=$(check_status shadowsocks)

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
    echo -e "${CYAN}|${NC} SSH    ${cs1}    ${CYAN}|${NC} NOOBZVPN ${cs8} ${CYAN}|${NC} NGINX  ${cs2}    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} SS-LBV ${cs9}    ${CYAN}|${NC} UDP      ${cs4}   ${CYAN}|${NC} XRAY   ${cs3}     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} HAPRXY ${cs5}    ${CYAN}|${NC} DROPBEAR ${cs6}   ${CYAN}|${NC} PINGKA ${cs7}     ${CYAN}|${NC}"
    echo -e "${CYAN}+==================+==================+==================+${NC}"
}

#================================================
# SHOW MAIN MENU
#================================================

show_menu() {
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[01]${NC} SSH MENU     ${CYAN}|${NC} ${WHITE}[08]${NC} SWAP SETUP   ${CYAN}|${NC} ${WHITE}[15]${NC} TELE BOT    ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[02]${NC} VMESS MENU   ${CYAN}|${NC} ${WHITE}[09]${NC} OPTIMIZE VPN ${CYAN}|${NC} ${WHITE}[16]${NC} CHG DOMAIN  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[03]${NC} VLESS MENU   ${CYAN}|${NC} ${WHITE}[10]${NC} RESTART ALL  ${CYAN}|${NC} ${WHITE}[17]${NC} FIX CRT     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[04]${NC} TROJAN MENU  ${CYAN}|${NC} ${WHITE}[11]${NC} RUNNING      ${CYAN}|${NC} ${WHITE}[18]${NC} UPDATE MENU ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[05]${NC} NOOBZVPN     ${CYAN}|${NC} ${WHITE}[12]${NC} INFO PORT    ${CYAN}|${NC} ${WHITE}[19]${NC} SPEEDTEST   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[06]${NC} SS - LIBEV   ${CYAN}|${NC} ${WHITE}[13]${NC} CEK EXPIRED  ${CYAN}|${NC} ${WHITE}[20]${NC} EKSTRAK     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[07]${NC} INSTALL UDP  ${CYAN}|${NC} ${WHITE}[14]${NC} DEL EXPIRED  ${CYAN}|${NC} ${WHITE}[00]${NC} EXIT        ${CYAN}|${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} Version: ${GREEN}%-10s${NC} Author: ${GREEN}%-25s${NC} ${CYAN}|${NC}\n" \
        "$SCRIPT_VERSION" "$SCRIPT_AUTHOR"
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
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "SSH"                  "$SSH_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Dropbear"             "$DROPBEAR_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Nginx Webserver"      "$NGINX_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "HAProxy SSL"          "$HAPROXY_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray TLS VMess/VLess" "$VMESS_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Trojan TLS"           "$TROJAN_TLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray gRPC"            "$XRAY_GRPC_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray WS NonTLS"       "$XRAY_WS_NONTLS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Shadowsocks"          "$SS_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "NoobzVPN OpenVPN"     "$NOOBZ_PORT"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "BadVPN UDP"           "$BADVPN_RANGE"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# CEK EXPIRED ACCOUNTS
#================================================

cek_expired() {
    clear
    print_menu_header "CEK EXPIRED ACCOUNTS"
    echo ""
    local today
    today=$(date +%s)
    local found=0

    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str exp_ts protocol uname
        exp_str=$(grep "EXPIRED=" "$f" | cut -d= -f2)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue

        uname=$(basename "$f" .txt)
        local diff=$(( (exp_ts - today) / 86400 ))

        if [[ $diff -le 3 ]]; then
            found=1
            if [[ $diff -lt 0 ]]; then
                echo -e " ${RED}EXPIRED${NC} : $uname (${exp_str})"
            else
                echo -e " ${YELLOW}${diff} days${NC} : $uname (${exp_str})"
            fi
        fi
    done

    [[ $found -eq 0 ]] && \
        echo -e "${GREEN}No accounts expiring soon!${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# DELETE EXPIRED ACCOUNTS
#================================================

delete_expired() {
    clear
    print_menu_header "DELETE EXPIRED ACCOUNTS"
    echo ""
    local today
    today=$(date +%s)
    local count=0

    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str exp_ts
        exp_str=$(grep "EXPIRED=" "$f" | cut -d= -f2)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue

        if [[ $exp_ts -lt $today ]]; then
            local fname
            fname=$(basename "$f" .txt)
            local uname=${fname#*-}
            local protocol=${fname%%-*}

            echo -e " ${RED}Deleting${NC}: $fname"

            # Hapus dari xray config
            local temp
            temp=$(mktemp)
            jq --arg email "$uname" \
               'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
               "$XRAY_CONFIG" > "$temp" 2>/dev/null && \
               mv "$temp" "$XRAY_CONFIG" || rm -f "$temp"

            # Hapus user SSH
            [[ "$protocol" == "ssh" ]] && \
                userdel -f "$uname" 2>/dev/null

            rm -f "$f"
            rm -f "$PUBLIC_HTML/${fname}.txt"
            ((count++))
        fi
    done

    if [[ $count -gt 0 ]]; then
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        echo ""
        echo -e "${GREEN}Deleted ${count} expired accounts!${NC}"
    else
        echo -e "${GREEN}No expired accounts found!${NC}"
    fi
    echo ""
    read -p "Press any key to back on menu..."
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
    local ip_vps
    ip_vps=$(get_ip)

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

    # Simpan file untuk download
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" << XRAYFILE
___________________________________________
  ${protocol^^} Account
___________________________________________
 Username         : ${username}
 IP/Host          : ${ip_vps}
 Domain           : ${DOMAIN}
 UUID             : ${uuid}
 Quota            : ${quota} GB
 IP Limit         : ${iplimit} IP
___________________________________________
 Port TLS         : ${VMESS_TLS_PORT}
 Port NonTLS      : ${XRAY_WS_NONTLS_PORT}
 Port gRPC        : ${XRAY_GRPC_PORT}
 Path WS          : /${protocol}
 ServiceName gRPC : ${protocol}-grpc
___________________________________________
 Link TLS         : ${link_tls}
___________________________________________
 Link NonTLS      : ${link_nontls}
___________________________________________
 Link gRPC        : ${link_grpc}
___________________________________________
 Save Link        : https://${DOMAIN}:81/${protocol}-${username}.txt
___________________________________________
 Aktif Selama     : ${days} Hari
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
XRAYFILE

    # Simpan OpenClash format
    printf "proxies:\n  - name: \"%s\"\n    type: %s\n    server: %s\n    port: %s\n    uuid: %s\n    alterId: 0\n    cipher: auto\n    tls: true\n    network: ws\n    ws-opts:\n      path: /%s\n      headers:\n        Host: %s\n" \
        "$username" "$protocol" "$DOMAIN" \
        "$VMESS_TLS_PORT" "$uuid" "$protocol" "$DOMAIN" \
        > "$PUBLIC_HTML/${protocol}-${username}-clash.yaml"

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}${protocol^^} Account${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Username"    "$username"
    printf " %-16s : %s\n" "IP/Host"     "$ip_vps"
    printf " %-16s : %s\n" "Domain"      "$DOMAIN"
    printf " %-16s : %s\n" "UUID"        "$uuid"
    printf " %-16s : %s GB\n" "Quota"    "$quota"
    printf " %-16s : %s IP\n" "IP Limit" "$iplimit"
    echo -e "${CYAN}___________________________________________${NC}"

    case $protocol in
        vmess|vless)
            printf " %-16s : %s\n" "Port TLS"    "$VMESS_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS" "$XRAY_WS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"   "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "Network"     "WebSocket"
            printf " %-16s : %s\n" "Path"        "/${protocol}"
            printf " %-16s : %s\n" "ServiceName" "${protocol}-grpc"
            printf " %-16s : %s\n" "TLS"         "enabled"
            ;;
        trojan)
            printf " %-16s : %s\n" "Port TLS"    "$TROJAN_TLS_PORT"
            printf " %-16s : %s\n" "Port NonTLS" "$XRAY_WS_NONTLS_PORT"
            printf " %-16s : %s\n" "Port gRPC"   "$XRAY_GRPC_PORT"
            printf " %-16s : %s\n" "Network"     "WebSocket"
            printf " %-16s : %s\n" "Path"        "/trojan"
            printf " %-16s : %s\n" "ServiceName" "trojan-grpc"
            printf " %-16s : %s\n" "TLS"         "enabled"
            ;;
    esac

    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Link TLS"    "$link_tls"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Link NonTLS" "$link_nontls"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Link gRPC"   "$link_grpc"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : https://%s:81/%s-%s.txt\n" \
        "Save Link" "$DOMAIN" "$protocol" "$username"
    printf " %-16s : https://%s:81/%s-%s-clash.yaml\n" \
        "OpenClash" "$DOMAIN" "$protocol" "$username"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s Hari\n" "Aktif Selama"  "$days"
    printf " %-16s : %s\n"      "Dibuat Pada"   "$created"
    printf " %-16s : %s\n"      "Berakhir Pada" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    send_telegram_admin \
        "✅ <b>New ${protocol^^}</b>
👤 User: <code>${username}</code>
🔑 UUID: <code>${uuid}</code>
📅 Exp: ${exp}
🌐 Domain: ${DOMAIN}"
    read -p "Press any key to back on menu..."
    return 0
}

#================================================
# TRIAL XRAY - 1 JAM
#################################################

create_trial_xray() {
    local protocol="$1"
    local username="trial-$(date +%H%M%S)"
    local uuid
    uuid=$(cat /proc/sys/kernel/random/uuid)
    local exp
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
    local created
    created=$(date +"%d %b, %Y %H:%M")
    local ip_vps
    ip_vps=$(get_ip)

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

    [[ $? -eq 0 ]] && mv "$temp" "$XRAY_CONFIG" || rm -f "$temp"
    fix_xray_permissions
    systemctl restart xray 2>/dev/null
    sleep 1

    mkdir -p "$AKUN_DIR"
    printf "UUID=%s\nQUOTA=1\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$uuid" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    # Auto delete setelah 1 jam
    (
        sleep 3600
        # Hapus dari xray
        local tmp
        tmp=$(mktemp)
        jq --arg email "$username" \
           'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp" 2>/dev/null && \
           mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        rm -f "$AKUN_DIR/${protocol}-${username}.txt"
        rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"
    ) &
    disown $!

    local link_tls
    if [[ "$protocol" == "vmess" ]]; then
        local j_tls
        j_tls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"%s","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$VMESS_TLS_PORT" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:${VLESS_TLS_PORT}?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:${TROJAN_TLS_PORT}?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
    fi

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}Trial ${protocol^^} Account (1 Jam)${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Username"    "$username"
    printf " %-16s : %s\n" "IP/Host"     "$ip_vps"
    printf " %-16s : %s\n" "Domain"      "$DOMAIN"
    printf " %-16s : %s\n" "UUID"        "$uuid"
    printf " %-16s : %s\n" "Quota"       "1 GB"
    printf " %-16s : %s\n" "IP Limit"    "1 IP"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Port TLS"    "$VMESS_TLS_PORT"
    printf " %-16s : %s\n" "Port NonTLS" "$XRAY_WS_NONTLS_PORT"
    printf " %-16s : %s\n" "Path"        "/${protocol}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Link TLS"    "$link_tls"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : 1 Jam (Auto Delete)\n" "Aktif Selama"
    printf " %-16s : %s\n" "Dibuat"      "$created"
    printf " %-16s : %s\n" "Berakhir"    "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# CREATE SSH - FORMAT LENGKAP
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

    _print_ssh_result \
        "SSH & OpenVPN Account" \
        "$username" "$password" "$ip_vps" \
        "$days" "$created" "$exp"

    send_telegram_admin \
        "✅ <b>New SSH</b>
👤 User: <code>${username}</code>
🔑 Pass: <code>${password}</code>
🌐 IP: ${ip_vps}
📅 Exp: ${exp}"
    read -p "Press any key to back on menu..."
}

# Helper print SSH result
_print_ssh_result() {
    local title="$1" username="$2" password="$3"
    local ip_vps="$4" days="$5" created="$6" exp="$7"
    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}${title}${NC}"
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
    printf " %-16s : %s:80@%s:%s\n" \
        "Format Hc" "$DOMAIN" "$username" "$password"
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
}

#================================================
# SSH TRIAL - 1 JAM
#================================================

create_ssh_trial() {
    local suffix
    suffix=$(cat /proc/sys/kernel/random/uuid | \
        tr -d '-' | head -c 4 | tr '[:lower:]' '[:upper:]')
    local username="Trial-${suffix}"
    local password="1"
    local ip_vps
    ip_vps=$(get_ip)

    local exp exp_date created
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y %H:%M")

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$username" "$password" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    # Auto delete setelah 1 jam
    (
        sleep 3600
        userdel -f "$username" 2>/dev/null
        rm -f "$AKUN_DIR/ssh-${username}.txt"
        rm -f "$PUBLIC_HTML/ssh-${username}.txt"
    ) &
    disown $!

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" << TRIALFILE
___________________________________________
  Trial SSH & OpenVPN (1 Jam)
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
 Aktif Selama     : 1 Jam (Auto Delete)
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
TRIALFILE

    _print_ssh_result \
        "Trial SSH & OpenVPN (1 Jam)" \
        "$username" "$password" "$ip_vps" \
        "1 Jam" "$created" "$exp"

    send_telegram_admin \
        "🆓 <b>New SSH Trial</b>
👤 User: <code>${username}</code>
🔑 Pass: <code>${password}</code>
🌐 IP: ${ip_vps}
⏰ Exp: ${exp} (1 Jam)"
    read -p "Press any key to back on menu..."
}

#================================================
# DELETE / RENEW / LIST / CHECK
#================================================

delete_account() {
    local protocol="$1"
    clear
    print_menu_header "DELETE ${protocol^^} ACCOUNT"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt \
        2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No ${protocol^^} accounts!${NC}"
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
    rm -f "$PUBLIC_HTML/${protocol}-${username}-clash.yaml"
    [[ "$protocol" == "ssh" ]] && \
        userdel -f "$username" 2>/dev/null

    echo -e "${GREEN}Account ${username} deleted!${NC}"
    sleep 2
}

renew_account() {
    local protocol="$1"
    clear
    print_menu_header "RENEW ${protocol^^} ACCOUNT"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt \
        2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No ${protocol^^} accounts!${NC}"
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
        echo -e "${RED}Not found!${NC}"; sleep 2; return
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

    echo -e "${GREEN}Renewed! Expiry: ${CYAN}${new_exp}${NC}"
    sleep 3
}

list_accounts() {
    local protocol="$1"
    clear
    print_menu_header "${protocol^^} ACCOUNT LIST"
    echo ""

    local files
    mapfile -t files < <(ls "$AKUN_DIR"/${protocol}-*.txt \
        2>/dev/null)
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No accounts!${NC}"
        sleep 2; return
    fi

    echo -e "${CYAN}+----------------------------------------------------+${NC}"
    printf " %-20s %-15s %-8s %-6s\n" \
        "USERNAME" "EXPIRED" "QUOTA" "TYPE"
    echo -e "${CYAN}+----------------------------------------------------+${NC}"
    for f in "${files[@]}"; do
        local uname exp quota trial
        uname=$(basename "$f" .txt | sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f"   | cut -d= -f2)
        quota=$(grep "QUOTA"   "$f" | cut -d= -f2)
        trial=$(grep "TRIAL"   "$f" | cut -d= -f2)
        local ttype="Member"
        [[ "$trial" == "1" ]] && ttype="Trial"
        printf " %-20s %-15s %-8s %-6s\n" \
            "$uname" "$exp" "${quota:-N/A}GB" "$ttype"
    done
    echo -e "${CYAN}+----------------------------------------------------+${NC}"
    echo -e " Total: ${GREEN}${#files[@]}${NC} accounts"
    echo ""
    read -p "Press any key to back on menu..."
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
        echo -e "${WHITE}Login count per user:${NC}"
        who | awk '{print $1}' | sort | uniq -c | sort -rn
    else
        echo -e "${WHITE}Active Xray ${protocol^^}:${NC}"
        if [[ -f /var/log/xray/access.log ]]; then
            grep -i "$protocol" /var/log/xray/access.log \
                2>/dev/null | \
                awk '{print $NF}' | sort | uniq -c | \
                sort -rn | head -20 || echo "No data"
        else
            echo "No log"
        fi
    fi
    echo ""
    read -p "Press any key to back on menu..."
}
#================================================
# TELEGRAM BOT - SETUP
#================================================

setup_telegram_bot() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SETUP TELEGRAM BOT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " ${YELLOW}Langkah setup:${NC}"
    echo -e " 1. Buka Telegram, cari @BotFather"
    echo -e " 2. Ketik /newbot"
    echo -e " 3. Ikuti instruksi, dapatkan TOKEN"
    echo -e " 4. Cari @userinfobot untuk dapat CHAT_ID"
    echo ""

    read -p " Bot Token   : " bot_token
    [[ -z "$bot_token" ]] && {
        echo -e "${RED}Token required!${NC}"; sleep 2; return
    }

    read -p " Admin Chat ID: " admin_id
    [[ -z "$admin_id" ]] && {
        echo -e "${RED}Chat ID required!${NC}"; sleep 2; return
    }

    # Test token
    echo -e "${CYAN}Testing bot token...${NC}"
    local test_result
    test_result=$(curl -s --max-time 10 \
        "https://api.telegram.org/bot${bot_token}/getMe")
    if echo "$test_result" | grep -q '"ok":true'; then
        local bot_name
        bot_name=$(echo "$test_result" | \
            python3 -c "import sys,json; \
            d=json.load(sys.stdin); \
            print(d['result']['username'])" 2>/dev/null)
        echo -e "${GREEN}Bot valid! Username: @${bot_name}${NC}"
    else
        echo -e "${RED}Invalid token!${NC}"
        sleep 2; return
    fi

    echo "$bot_token" > "$BOT_TOKEN_FILE"
    echo "$admin_id"  > "$CHAT_ID_FILE"
    chmod 600 "$BOT_TOKEN_FILE" "$CHAT_ID_FILE"

    echo ""
    read -p " Nama Rekening (untuk pembayaran): " rek_name
    read -p " No Rekening/Dana/OVO/GoPay      : " rek_number
    read -p " Bank/E-wallet                   : " rek_bank

    cat > /root/.payment_info << PAYEOF
REK_NAME=${rek_name}
REK_NUMBER=${rek_number}
REK_BANK=${rek_bank}
PAYEOF
    chmod 600 /root/.payment_info

    # Install bot service
    _install_bot_service "$bot_token" "$admin_id"

    echo ""
    echo -e "${GREEN}Bot setup complete!${NC}"
    echo -e " Token saved : ${CYAN}${BOT_TOKEN_FILE}${NC}"
    echo -e " Admin ID    : ${CYAN}${admin_id}${NC}"
    echo -e " Bot running : ${GREEN}Active${NC}"
    echo ""

    # Kirim test message ke admin
    send_telegram "$admin_id" \
        "✅ <b>Bot VPN Aktif!</b>
🤖 Bot berhasil dikonfigurasi
🌐 Domain: <code>${DOMAIN}</code>
👤 Admin ID: <code>${admin_id}</code>

Ketik /help untuk lihat perintah."

    sleep 3
}

_install_bot_service() {
    local token="$1"
    local admin_id="$2"

    mkdir -p /root/bot
    mkdir -p "$ORDER_DIR"

    # Buat script bot utama
    cat > /root/bot/bot.py << BOTEOF
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Telegram Bot VPN - Proffessor Squad

import os, json, time, subprocess, requests
from datetime import datetime, timedelta

TOKEN     = open('/root/.bot_token').read().strip()
ADMIN_ID  = int(open('/root/.chat_id').read().strip())
DOMAIN    = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
ORDER_DIR = '/root/orders'
AKUN_DIR  = '/root/akun'
HTML_DIR  = '/var/www/html'

os.makedirs(ORDER_DIR, exist_ok=True)
os.makedirs(AKUN_DIR,  exist_ok=True)

API = f'https://api.telegram.org/bot{TOKEN}'

# =====================
# PAYMENT INFO
# =====================
def get_payment_info():
    info = {}
    try:
        with open('/root/.payment_info') as f:
            for line in f:
                line = line.strip()
                if '=' in line:
                    k, v = line.split('=', 1)
                    info[k] = v
    except:
        pass
    return info

# =====================
# TELEGRAM FUNCTIONS
# =====================
def send_msg(chat_id, text, reply_markup=None, parse_mode='HTML'):
    data = {
        'chat_id': chat_id,
        'text': text,
        'parse_mode': parse_mode
    }
    if reply_markup:
        data['reply_markup'] = json.dumps(reply_markup)
    try:
        requests.post(f'{API}/sendMessage', data=data, timeout=10)
    except:
        pass

def send_photo(chat_id, photo_url, caption=''):
    try:
        requests.post(f'{API}/sendPhoto', data={
            'chat_id': chat_id,
            'photo': photo_url,
            'caption': caption,
            'parse_mode': 'HTML'
        }, timeout=10)
    except:
        pass

def get_updates(offset=0):
    try:
        r = requests.get(f'{API}/getUpdates',
            params={'offset': offset, 'timeout': 30},
            timeout=35)
        return r.json().get('result', [])
    except:
        return []

def answer_callback(callback_id, text=''):
    try:
        requests.post(f'{API}/answerCallbackQuery', data={
            'callback_query_id': callback_id,
            'text': text
        }, timeout=5)
    except:
        pass

# =====================
# UTILITY
# =====================
def get_ip():
    for url in ['https://ifconfig.me','https://ipinfo.io/ip',
                'https://api.ipify.org']:
        try:
            r = requests.get(url, timeout=5)
            if r.status_code == 200:
                return r.text.strip()
        except:
            pass
    return 'N/A'

def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True,
            capture_output=True, text=True, timeout=60)
        return result.stdout.strip()
    except:
        return ''

def save_order(order_id, data):
    path = f'{ORDER_DIR}/{order_id}.json'
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

def load_order(order_id):
    path = f'{ORDER_DIR}/{order_id}.json'
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)

def delete_order(order_id):
    path = f'{ORDER_DIR}/{order_id}.json'
    if os.path.exists(path):
        os.remove(path)

def list_pending_orders():
    orders = []
    if not os.path.exists(ORDER_DIR):
        return orders
    for f in os.listdir(ORDER_DIR):
        if f.endswith('.json'):
            try:
                with open(f'{ORDER_DIR}/{f}') as fp:
                    data = json.load(fp)
                    if data.get('status') == 'pending':
                        orders.append(data)
            except:
                pass
    return orders

# =====================
# KEYBOARD HELPERS
# =====================
def kb_main():
    return {
        'keyboard': [
            ['🆓 Trial Gratis', '🛒 Order VPN'],
            ['📋 Status Akun', '❓ Bantuan'],
            ['ℹ️ Info Server']
        ],
        'resize_keyboard': True,
        'one_time_keyboard': False
    }

def kb_protocol():
    return {
        'inline_keyboard': [
            [
                {'text': '🔵 SSH', 'callback_data': 'trial_ssh'},
                {'text': '🟢 VMess', 'callback_data': 'trial_vmess'}
            ],
            [
                {'text': '🟡 VLess', 'callback_data': 'trial_vless'},
                {'text': '🔴 Trojan', 'callback_data': 'trial_trojan'}
            ]
        ]
    }

def kb_order_protocol():
    return {
        'inline_keyboard': [
            [
                {'text': '🔵 SSH 30hr', 'callback_data': 'order_ssh'},
                {'text': '🟢 VMess 30hr', 'callback_data': 'order_vmess'}
            ],
            [
                {'text': '🟡 VLess 30hr', 'callback_data': 'order_vless'},
                {'text': '🔴 Trojan 30hr', 'callback_data': 'order_trojan'}
            ]
        ]
    }

def kb_admin_confirm(order_id):
    return {
        'inline_keyboard': [[
            {'text': '✅ Konfirmasi Bayar',
             'callback_data': f'confirm_{order_id}'},
            {'text': '❌ Tolak Order',
             'callback_data': f'reject_{order_id}'}
        ]]
    }

# =====================
# CREATE ACCOUNT
# =====================
def create_ssh_account(username, password, days=30):
    exp_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
    run_cmd(f'useradd -M -s /bin/false -e {exp_date} {username} 2>/dev/null')
    run_cmd(f'echo "{username}:{password}" | chpasswd')
    exp_str = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')
    created = datetime.now().strftime('%d %b, %Y')
    content = (
        f'USERNAME={username}\n'
        f'PASSWORD={password}\n'
        f'IPLIMIT=1\n'
        f'EXPIRED={exp_str}\n'
        f'CREATED={created}\n'
    )
    with open(f'{AKUN_DIR}/ssh-{username}.txt', 'w') as f:
        f.write(content)
    return exp_str

def create_xray_account(protocol, username, days=30, quota=100):
    import uuid as uuidlib
    uid = str(uuidlib.uuid4())
    exp_str = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')
    created = datetime.now().strftime('%d %b, %Y')

    # Update xray config via jq
    cfg = '/usr/local/etc/xray/config.json'
    if protocol == 'vmess':
        cmd = (
            f'jq --arg uuid "{uid}" --arg email "{username}" '
            f"'(.inbounds[] | select(.tag | startswith(\"vmess\"))"
            f'.settings.clients) += '
            f'[{{\"id\": $uuid, \"email\": $email, \"alterId\": 0}}]\' '
            f'{cfg} > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json {cfg}'
        )
    elif protocol == 'vless':
        cmd = (
            f'jq --arg uuid "{uid}" --arg email "{username}" '
            f"'(.inbounds[] | select(.tag | startswith(\"vless\"))"
            f'.settings.clients) += '
            f'[{{\"id\": $uuid, \"email\": $email}}]\' '
            f'{cfg} > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json {cfg}'
        )
    elif protocol == 'trojan':
        cmd = (
            f'jq --arg password "{uid}" --arg email "{username}" '
            f"'(.inbounds[] | select(.tag | startswith(\"trojan\"))"
            f'.settings.clients) += '
            f'[{{\"password\": $password, \"email\": $email}}]\' '
            f'{cfg} > /tmp/xray_tmp.json && mv /tmp/xray_tmp.json {cfg}'
        )
    run_cmd(cmd)
    run_cmd('chmod 644 /usr/local/etc/xray/config.json')
    run_cmd('systemctl restart xray')

    content = (
        f'UUID={uid}\nQUOTA={quota}\n'
        f'IPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n'
    )
    with open(f'{AKUN_DIR}/{protocol}-{username}.txt', 'w') as f:
        f.write(content)
    return uid, exp_str

def create_trial_account(protocol, chat_id):
    ts  = datetime.now().strftime('%H%M%S')
    username = f'trial-{ts}'
    ip_vps = get_ip()
    exp_1h = (datetime.now() + timedelta(hours=1)).strftime('%d %b %Y %H:%M')

    if protocol == 'ssh':
        password = '1'
        exp_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
        run_cmd(f'useradd -M -s /bin/false -e {exp_date} {username} 2>/dev/null')
        run_cmd(f'echo "{username}:{password}" | chpasswd')

        # Auto delete 1 jam
        run_cmd(
            f'(sleep 3600; userdel -f {username} 2>/dev/null; '
            f'rm -f {AKUN_DIR}/ssh-{username}.txt) &'
        )

        msg = (
            f'🆓 <b>Trial SSH (1 Jam)</b>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'👤 Username : <code>{username}</code>\n'
            f'🔑 Password : <code>{password}</code>\n'
            f'🌐 IP/Host  : <code>{ip_vps}</code>\n'
            f'🔗 Domain   : <code>{DOMAIN}</code>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'🔌 OpenSSH  : 22\n'
            f'🔌 Dropbear : 222\n'
            f'🔌 SSL/TLS  : 443\n'
            f'🔌 WS NonSSL: 80, 8080\n'
            f'🔌 WS SSL   : 443, 8443\n'
            f'🔌 BadVPN   : 7100-7300\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'📋 Payload  : GET / HTTP/1.1[crlf]'
            f'Host: {DOMAIN}[crlf]'
            f'Upgrade: ws[crlf][crlf]\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'⏰ Aktif    : 1 Jam (Auto Hapus)\n'
            f'📅 Expired  : {exp_1h}\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'⚠️ <i>Akun trial otomatis dihapus setelah 1 jam</i>'
        )
        send_msg(chat_id, msg)

    else:
        # Xray trial 1 jam
        try:
            uid, _ = create_xray_account(protocol, username, days=1, quota=1)
        except Exception as e:
            send_msg(chat_id, f'❌ Gagal buat akun: {e}')
            return

        # Auto delete 1 jam
        run_cmd(
            f'(sleep 3600; '
            f'jq --arg email "{username}" '
            f"'del(.inbounds[].settings.clients[]? | "
            f'select(.email == $email))\' '
            f'/usr/local/etc/xray/config.json > /tmp/xdel.json && '
            f'mv /tmp/xdel.json /usr/local/etc/xray/config.json; '
            f'systemctl restart xray; '
            f'rm -f {AKUN_DIR}/{protocol}-{username}.txt) &'
        )

        port_tls  = '8443'
        port_ntls = '8080'
        if protocol == 'trojan':
            port_tls = '2083'

        msg = (
            f'🆓 <b>Trial {protocol.upper()} (1 Jam)</b>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'👤 Username  : <code>{username}</code>\n'
            f'🔑 UUID      : <code>{uid}</code>\n'
            f'🌐 IP/Host   : <code>{ip_vps}</code>\n'
            f'🔗 Domain    : <code>{DOMAIN}</code>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'🔌 Port TLS  : {port_tls}\n'
            f'🔌 Port WS   : {port_ntls}\n'
            f'🔌 Port gRPC : 8444\n'
            f'📂 Path      : /{protocol}\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'⏰ Aktif     : 1 Jam (Auto Hapus)\n'
            f'📅 Expired   : {exp_1h}\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'⚠️ <i>Akun trial otomatis dihapus setelah 1 jam</i>'
        )
        send_msg(chat_id, msg)

def format_order_msg(order):
    pay = get_payment_info()
    return (
        f'🛒 <b>Detail Order</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━\n'
        f'🆔 Order ID : <code>{order["order_id"]}</code>\n'
        f'📦 Paket    : {order["protocol"].upper()} 30 Hari\n'
        f'💰 Harga    : Rp 10.000\n'
        f'👤 Username : <code>{order["username"]}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━\n'
        f'💳 Pembayaran ke:\n'
        f'🏦 {pay.get("REK_BANK","N/A")}\n'
        f'📱 {pay.get("REK_NUMBER","N/A")}\n'
        f'👤 a/n {pay.get("REK_NAME","N/A")}\n'
        f'━━━━━━━━━━━━━━━━━━━━\n'
        f'📸 Kirim bukti bayar ke admin\n'
        f'⏳ Order expired dalam 24 jam\n'
        f'━━━━━━━━━━━━━━━━━━━━\n'
        f'✅ Setelah konfirmasi admin,\n'
        f'akun akan langsung dikirim ke sini.'
    )

# =====================
# HANDLE MESSAGES
# =====================
user_state = {}

def handle_msg(msg):
    chat_id  = msg['chat']['id']
    text     = msg.get('text', '').strip()
    username = msg['from'].get('username', f'user{chat_id}')
    fname    = msg['from'].get('first_name', 'User')

    # State machine untuk order
    state = user_state.get(chat_id, {})

    if state.get('step') == 'wait_username':
        # User input username untuk order
        new_username = text.strip().replace(' ', '_')
        if len(new_username) < 3:
            send_msg(chat_id,
                '❌ Username minimal 3 karakter!')
            return
        protocol = state['protocol']
        order_id = f'{chat_id}_{int(time.time())}'
        order = {
            'order_id'  : order_id,
            'chat_id'   : chat_id,
            'username'  : new_username,
            'protocol'  : protocol,
            'status'    : 'pending',
            'created_at': datetime.now().isoformat(),
            'tg_user'   : username
        }
        save_order(order_id, order)
        user_state.pop(chat_id, None)

        # Kirim detail pembayaran ke user
        send_msg(chat_id, format_order_msg(order))

        # Notif admin
        send_msg(ADMIN_ID,
            f'🔔 <b>ORDER BARU!</b>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'🆔 Order ID : <code>{order_id}</code>\n'
            f'📦 Paket    : {protocol.upper()} 30 Hari\n'
            f'👤 Username : <code>{new_username}</code>\n'
            f'📱 TG User  : @{username}\n'
            f'🆔 Chat ID  : <code>{chat_id}</code>\n'
            f'💰 Harga    : Rp 10.000\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'Tunggu bukti pembayaran dari user.',
            reply_markup=kb_admin_confirm(order_id)
        )
        return

    # Command handler
    if text == '/start' or text == '🏠 Menu':
        send_msg(chat_id,
            f'👋 Halo <b>{fname}</b>!\n\n'
            f'🤖 Bot VPN <b>Proffessor Squad</b>\n'
            f'🌐 Server: <code>{DOMAIN}</code>\n\n'
            f'Pilih menu di bawah:',
            reply_markup=kb_main()
        )

    elif text in ['/help', '❓ Bantuan']:
        send_msg(chat_id,
            '📋 <b>Panduan Bot VPN</b>\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            '🆓 <b>Trial Gratis</b>\n'
            '   Akun trial 1 jam gratis\n'
            '   Tersedia: SSH, VMess, VLess, Trojan\n\n'
            '🛒 <b>Order VPN</b>\n'
            '   Paket 30 hari - Rp 10.000\n'
            '   Tersedia: SSH, VMess, VLess, Trojan\n\n'
            '📋 <b>Status Akun</b>\n'
            '   Cek expired akun kamu\n\n'
            'ℹ️ <b>Info Server</b>\n'
            '   Lihat info & port server\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            '💬 Hubungi admin jika ada masalah'
        )

    elif text in ['🆓 Trial Gratis']:
        send_msg(chat_id,
            '🆓 <b>Pilih Protocol Trial</b>\n'
            'Akun aktif selama <b>1 jam</b>, gratis!',
            reply_markup=kb_protocol()
        )

    elif text in ['🛒 Order VPN']:
        send_msg(chat_id,
            '🛒 <b>Order VPN 30 Hari</b>\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            '💰 Harga: <b>Rp 10.000</b>\n'
            '📅 Durasi: <b>30 Hari</b>\n'
            '━━━━━━━━━━━━━━━━━━━━\n'
            'Pilih protocol:',
            reply_markup=kb_order_protocol()
        )

    elif text in ['📋 Status Akun']:
        # Cari akun berdasarkan username telegram
        found = False
        for f in os.listdir(AKUN_DIR):
            if not f.endswith('.txt'):
                continue
            filepath = f'{AKUN_DIR}/{f}'
            content = open(filepath).read()
            # Cek apakah file akun ini milik user ini
            # (berdasarkan order history)
            for order_file in os.listdir(ORDER_DIR):
                if not order_file.endswith('.json'):
                    continue
                order = load_order(order_file.replace('.json',''))
                if order and \
                   str(order.get('chat_id')) == str(chat_id) and \
                   order.get('status') == 'confirmed':
                    uname = order.get('username','')
                    proto = order.get('protocol','')
                    akun_file = f'{AKUN_DIR}/{proto}-{uname}.txt'
                    if os.path.exists(akun_file):
                        lines = open(akun_file).read()
                        exp = ''
                        for line in lines.split('\n'):
                            if 'EXPIRED=' in line:
                                exp = line.split('=',1)[1]
                        send_msg(chat_id,
                            f'📋 <b>Status Akun</b>\n'
                            f'━━━━━━━━━━━━━━━━━━━━\n'
                            f'📦 Paket   : {proto.upper()}\n'
                            f'👤 Username: <code>{uname}</code>\n'
                            f'📅 Expired : {exp}\n'
                            f'━━━━━━━━━━━━━━━━━━━━'
                        )
                        found = True
                        break
            if found:
                break
        if not found:
            send_msg(chat_id,
                '📋 Tidak ada akun aktif.\n'
                'Gunakan /order untuk beli VPN.'
            )

    elif text in ['ℹ️ Info Server']:
        ip_vps = get_ip()
        send_msg(chat_id,
            f'ℹ️ <b>Info Server</b>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'🌐 Domain : <code>{DOMAIN}</code>\n'
            f'🖥️ IP     : <code>{ip_vps}</code>\n'
            f'━━━━━━━━━━━━━━━━━━━━\n'
            f'🔌 <b>Port Info:</b>\n'
            f'   SSH      : 22\n'
            f'   Dropbear : 222\n'
            f'   Nginx    : 80\n'
            f'   HAProxy  : 443\n'
            f'   VMess TLS: 8443\n'
            f'   Trojan   : 2083\n'
            f'   gRPC     : 8444\n'
            f'   WS NonTLS: 8080\n'
            f'   BadVPN   : 7100-7300\n'
            f'━━━━━━━━━━━━━━━━━━━━'
        )

    # Admin commands
    elif text == '/orders' and chat_id == ADMIN_ID:
        orders = list_pending_orders()
        if not orders:
            send_msg(ADMIN_ID, '📭 Tidak ada order pending.')
            return
        for o in orders[:10]:
            send_msg(ADMIN_ID,
                f'🔔 <b>Order Pending</b>\n'
                f'🆔 ID      : <code>{o["order_id"]}</code>\n'
                f'📦 Paket   : {o["protocol"].upper()}\n'
                f'👤 Username: <code>{o["username"]}</code>\n'
                f'📱 TG      : @{o.get("tg_user","N/A")}\n'
                f'🕐 Waktu   : {o["created_at"][:16]}',
                reply_markup=kb_admin_confirm(o['order_id'])
            )

    elif text.startswith('/cek ') and chat_id == ADMIN_ID:
        order_id = text.split(' ', 1)[1].strip()
        order = load_order(order_id)
        if order:
            send_msg(ADMIN_ID,
                f'📋 <b>Detail Order</b>\n'
                f'🆔 ID    : <code>{order_id}</code>\n'
                f'📦 Paket : {order["protocol"].upper()}\n'
                f'👤 User  : <code>{order["username"]}</code>\n'
                f'📱 TG    : @{order.get("tg_user","N/A")}\n'
                f'✅ Status: {order["status"]}',
                reply_markup=kb_admin_confirm(order_id)
            )
        else:
            send_msg(ADMIN_ID, '❌ Order tidak ditemukan.')

    elif text == '/broadcast' and chat_id == ADMIN_ID:
        send_msg(ADMIN_ID,
            '📢 Fitur broadcast belum diimplementasi.\n'
            'Gunakan /send [chat_id] [pesan]'
        )

def handle_callback(cb):
    chat_id     = cb['message']['chat']['id']
    cb_id       = cb['id']
    data        = cb['data']
    msg_id      = cb['message']['message_id']

    # Trial callbacks
    if data.startswith('trial_'):
        protocol = data.replace('trial_', '')
        answer_callback(cb_id, f'Membuat akun trial {protocol}...')
        send_msg(chat_id,
            f'⏳ Membuat akun trial {protocol.upper()}...'
        )
        create_trial_account(protocol, chat_id)

    # Order callbacks
    elif data.startswith('order_'):
        protocol = data.replace('order_', '')
        answer_callback(cb_id)
        user_state[chat_id] = {
            'step': 'wait_username',
            'protocol': protocol
        }
        send_msg(chat_id,
            f'🛒 <b>Order {protocol.upper()} 30 Hari</b>\n\n'
            f'Ketik username yang diinginkan:\n'
            f'<i>(huruf, angka, strip saja. Min 3 karakter)</i>'
        )

    # Admin: konfirmasi bayar
    elif data.startswith('confirm_') and chat_id == ADMIN_ID:
        order_id = data.replace('confirm_', '')
        order = load_order(order_id)
        if not order:
            answer_callback(cb_id, '❌ Order tidak ditemukan!')
            return
        if order['status'] != 'pending':
            answer_callback(cb_id, '⚠️ Order sudah diproses!')
            return

        answer_callback(cb_id, '⏳ Memproses...')
        protocol = order['protocol']
        username = order['username']
        user_chat_id = order['chat_id']
        ip_vps = get_ip()

        try:
            if protocol == 'ssh':
                import random, string
                password = ''.join(
                    random.choices(string.ascii_letters + string.digits, k=8)
                )
                exp_str = create_ssh_account(username, password, days=30)

                msg = (
                    f'✅ <b>Akun SSH Berhasil Dibuat!</b>\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'👤 Username : <code>{username}</code>\n'
                    f'🔑 Password : <code>{password}</code>\n'
                    f'🌐 IP/Host  : <code>{ip_vps}</code>\n'
                    f'🔗 Domain   : <code>{DOMAIN}</code>\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'🔌 OpenSSH  : 22\n'
                    f'🔌 Dropbear : 222\n'
                    f'🔌 SSL/TLS  : 443\n'
                    f'🔌 WS NonSSL: 80, 8080\n'
                    f'🔌 WS SSL   : 443, 8443\n'
                    f'🔌 BadVPN   : 7100-7300\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'📅 Expired  : {exp_str}\n'
                    f'📋 Save Link: '
                    f'https://{DOMAIN}:81/ssh-{username}.txt\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'💰 Terima kasih sudah berlangganan!'
                )

            else:
                uid, exp_str = create_xray_account(
                    protocol, username, days=30, quota=100
                )
                port_tls  = '8443'
                port_ntls = '8080'
                if protocol == 'trojan':
                    port_tls = '2083'

                msg = (
                    f'✅ <b>Akun {protocol.upper()} Berhasil!</b>\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'👤 Username  : <code>{username}</code>\n'
                    f'🔑 UUID      : <code>{uid}</code>\n'
                    f'🌐 IP/Host   : <code>{ip_vps}</code>\n'
                    f'🔗 Domain    : <code>{DOMAIN}</code>\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'🔌 Port TLS  : {port_tls}\n'
                    f'🔌 Port WS   : {port_ntls}\n'
                    f'🔌 Port gRPC : 8444\n'
                    f'📂 Path      : /{protocol}\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'📅 Expired   : {exp_str}\n'
                    f'📋 Save Link : '
                    f'https://{DOMAIN}:81/{protocol}-{username}.txt\n'
                    f'━━━━━━━━━━━━━━━━━━━━\n'
                    f'💰 Terima kasih sudah berlangganan!'
                )

            send_msg(user_chat_id, msg)
            order['status'] = 'confirmed'
            save_order(order_id, order)
            send_msg(ADMIN_ID,
                f'✅ Order <code>{order_id}</code> dikonfirmasi!\n'
                f'Akun {protocol.upper()} untuk @{order.get("tg_user","N/A")} sudah dikirim.'
            )

        except Exception as e:
            send_msg(ADMIN_ID, f'❌ Error buat akun: {e}')

    # Admin: tolak order
    elif data.startswith('reject_') and chat_id == ADMIN_ID:
        order_id = data.replace('reject_', '')
        order = load_order(order_id)
        if not order:
            answer_callback(cb_id, '❌ Order tidak ditemukan!')
            return
        answer_callback(cb_id, 'Order ditolak')
        order['status'] = 'rejected'
        save_order(order_id, order)
        send_msg(order['chat_id'],
            f'❌ <b>Order Ditolak</b>\n'
            f'Order ID: <code>{order_id}</code>\n'
            f'Hubungi admin jika ada pertanyaan.'
        )
        send_msg(ADMIN_ID,
            f'❌ Order <code>{order_id}</code> ditolak.'
        )

# =====================
# MAIN LOOP
# =====================
def main():
    print('Bot VPN Proffessor Squad - Starting...')
    offset = 0
    while True:
        try:
            updates = get_updates(offset)
            for update in updates:
                offset = update['update_id'] + 1
                if 'message' in update:
                    handle_msg(update['message'])
                elif 'callback_query' in update:
                    handle_callback(update['callback_query'])
        except KeyboardInterrupt:
            print('Bot stopped.')
            break
        except Exception as e:
            print(f'Error: {e}')
            time.sleep(5)

if __name__ == '__main__':
    main()
BOTEOF

    chmod +x /root/bot/bot.py

    # Install dependencies
    pip3 install requests --break-system-packages \
        >/dev/null 2>&1 || pip3 install requests >/dev/null 2>&1

    # Buat systemd service
    cat > /etc/systemd/system/vpn-bot.service << 'SVCEOF'
[Unit]
Description=VPN Telegram Bot - Proffessor Squad
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/bot/bot.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable vpn-bot 2>/dev/null
    systemctl restart vpn-bot 2>/dev/null
}

#================================================
# MENU TELEGRAM BOT
#================================================

menu_telegram_bot() {
    while true; do
        clear
        print_menu_header "TELEGRAM BOT MENU"
        local bot_status
        bot_status=$(check_status vpn-bot)
        local cs
        [[ "$bot_status" == "ON" ]] && \
            cs="${GREEN}RUNNING${NC}" || cs="${RED}STOPPED${NC}"
        echo -e "  Status Bot : ${cs}"
        echo ""
        echo -e "     ${WHITE}[1]${NC} Setup Bot (Token & Admin)"
        echo -e "     ${WHITE}[2]${NC} Start Bot"
        echo -e "     ${WHITE}[3]${NC} Stop Bot"
        echo -e "     ${WHITE}[4]${NC} Restart Bot"
        echo -e "     ${WHITE}[5]${NC} Lihat Log Bot"
        echo -e "     ${WHITE}[6]${NC} Lihat Order Pending"
        echo -e "     ${WHITE}[7]${NC} Info Bot"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) setup_telegram_bot ;;
            2)
                systemctl start vpn-bot
                echo -e "${GREEN}Bot started!${NC}"; sleep 2
                ;;
            3)
                systemctl stop vpn-bot
                echo -e "${YELLOW}Bot stopped!${NC}"; sleep 2
                ;;
            4)
                systemctl restart vpn-bot
                echo -e "${GREEN}Bot restarted!${NC}"; sleep 2
                ;;
            5)
                clear
                echo -e "${WHITE}Bot Log (last 30 lines):${NC}"
                echo -e "${CYAN}================================${NC}"
                journalctl -u vpn-bot -n 30 --no-pager
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            6)
                clear
                print_menu_header "ORDER PENDING"
                echo ""
                local found=0
                for f in "$ORDER_DIR"/*.json 2>/dev/null; do
                    [[ ! -f "$f" ]] && continue
                    local status
                    status=$(python3 -c \
                        "import json; \
                        d=json.load(open('$f')); \
                        print(d.get('status',''))" 2>/dev/null)
                    if [[ "$status" == "pending" ]]; then
                        found=1
                        python3 -c "
import json
d=json.load(open('$f'))
print(f'Order ID : {d[\"order_id\"]}')
print(f'Protocol : {d[\"protocol\"].upper()}')
print(f'Username : {d[\"username\"]}')
print(f'TG User  : @{d.get(\"tg_user\",\"N/A\")}')
print(f'Created  : {d[\"created_at\"][:16]}')
print('---')
" 2>/dev/null
                    fi
                done
                [[ $found -eq 0 ]] && \
                    echo -e "${GREEN}Tidak ada order pending!${NC}"
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            7)
                clear
                print_menu_header "BOT INFO"
                echo ""
                if [[ -f "$BOT_TOKEN_FILE" ]]; then
                    local token
                    token=$(cat "$BOT_TOKEN_FILE")
                    local admin_id
                    admin_id=$(cat "$CHAT_ID_FILE" 2>/dev/null)
                    local bot_info
                    bot_info=$(curl -s --max-time 5 \
                        "https://api.telegram.org/bot${token}/getMe")
                    local bot_name
                    bot_name=$(echo "$bot_info" | \
                        python3 -c "import sys,json; \
                        d=json.load(sys.stdin); \
                        print(d.get('result',{}).get('username','N/A'))" \
                        2>/dev/null)
                    printf " %-16s : @%s\n" "Bot Username" "$bot_name"
                    printf " %-16s : %s\n"  "Admin ID"    "$admin_id"
                    printf " %-16s : %s\n"  "Status"      "$bot_status"
                    if [[ -f /root/.payment_info ]]; then
                        source /root/.payment_info
                        echo ""
                        echo -e " ${WHITE}Payment Info:${NC}"
                        printf " %-16s : %s\n" "Bank/E-Wallet" "$REK_BANK"
                        printf " %-16s : %s\n" "No Rekening"   "$REK_NUMBER"
                        printf " %-16s : %s\n" "Atas Nama"     "$REK_NAME"
                    fi
                else
                    echo -e "${RED}Bot belum dikonfigurasi!${NC}"
                    echo -e "${YELLOW}Pilih [1] untuk setup bot.${NC}"
                fi
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            0) return ;;
        esac
    done
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
    [[ -z "$username" ]] && {
        echo -e "${RED}Required${NC}"; sleep 2; return
    }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid${NC}"; sleep 2; return
    }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vmess" "$username" "$days" "$quota" "$iplimit"
}

create_vless() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE VLESS ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User: " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required${NC}"; sleep 2; return
    }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid${NC}"; sleep 2; return
    }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vless" "$username" "$days" "$quota" "$iplimit"
}

create_trojan() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE TROJAN ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " User: " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required${NC}"; sleep 2; return
    }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid${NC}"; sleep 2; return
    }
    read -p " Limit User (GB): " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " Limit User (IP): " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "trojan" "$username" "$days" "$quota" "$iplimit"
}

#================================================
# MENU SSH
#================================================

menu_ssh() {
    while true; do
        clear
        print_menu_header "SSH MENU"
        echo -e "     ${WHITE}[1]${NC} Create SSH Account"
        echo -e "     ${WHITE}[2]${NC} Trial SSH (1 Jam)"
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
        echo -e "     ${WHITE}[2]${NC} Trial Vmess (1 Jam)"
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
            2) create_trial_xray "vmess" ;;
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
        echo -e "     ${WHITE}[2]${NC} Trial Vless (1 Jam)"
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
            2) create_trial_xray "vless" ;;
            3) delete_account "vless" ;;
            4) renew_account "vless" ;;
            5) check_user_login "vless" ;;
            6) list_accounts "vless" ;;
            0) return ;;
        esac
    done
}

#################################################
# MENU TROJAN
#################################################

menu_trojan() {
    while true; do
        clear
        print_menu_header "TROJAN MENU"
        echo -e "     ${WHITE}[1]${NC} Create Trojan Account"
        echo -e "     ${WHITE}[2]${NC} Trial Trojan (1 Jam)"
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
            2) create_trial_xray "trojan" ;;
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

print(f'UDP Custom: {len(sockets)} ports (7100-7300)')

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
# UPDATE MENU
#================================================

menu_update() {
    while true; do
        clear
        print_menu_header "UPDATE / ROLLBACK MENU"
        echo -e "     ${WHITE}[1]${NC} Check & Update Script"
        echo -e "     ${WHITE}[2]${NC} Rollback Previous Version"
        echo -e "     ${WHITE}[3]${NC} Script Info"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) update_menu ;;
            2) rollback_script ;;
            3)
                clear
                print_menu_header "SCRIPT INFO"
                echo ""
                printf " %-16s : %s\n" "Version"  "$SCRIPT_VERSION"
                printf " %-16s : %s\n" "Author"   "$SCRIPT_AUTHOR"
                printf " %-16s : %s\n" "GitHub"   \
                    "${GITHUB_USER}/${GITHUB_REPO}"
                printf " %-16s : %s\n" "Branch"   "$GITHUB_BRANCH"
                printf " %-16s : %s\n" "Backup"   "$BACKUP_PATH"
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            0) return ;;
        esac
    done
}
#================================================
# AUTO INSTALL
#================================================

auto_install() {
    clear
    echo -e "${GREEN}+=========================================+${NC}"
    echo -e "${GREEN}|   AUTO INSTALLATION                     |${NC}"
    echo -e "${GREEN}|   By The Proffessor Squad               |${NC}"
    echo -e "${GREEN}+=========================================+${NC}"
    echo ""
    read -p "Domain: " DOMAIN
    [[ -z "$DOMAIN" ]] && {
        echo "Domain required!"; exit 1
    }
    echo "$DOMAIN" > "$DOMAIN_FILE"

    echo -e "${CYAN}[1/10]${NC} Installing packages..."
    apt-get update -y >/dev/null 2>&1
    apt-get install -y \
        curl wget jq qrencode unzip uuid-runtime \
        nginx openssh-server dropbear certbot \
        python3 python3-pip net-tools haproxy \
        netcat-openbsd openssl \
        >/dev/null 2>&1
    echo -e "${GREEN}Packages installed!${NC}"

    echo -e "${CYAN}[2/10]${NC} Installing Xray..."
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        >/dev/null 2>&1
    echo -e "${GREEN}Xray installed!${NC}"

    mkdir -p "$AKUN_DIR" /var/log/xray \
        /usr/local/etc/xray "$PUBLIC_HTML" "$ORDER_DIR"

    echo -e "${CYAN}[3/10]${NC} Setting up Swap 1GB..."
    if [[ $(free -m | awk 'NR==3{print $2}') -lt 512 ]]; then
        fallocate -l 1G /swapfile 2>/dev/null || \
            dd if=/dev/zero of=/swapfile bs=1M count=1024 \
            2>/dev/null
        chmod 600 /swapfile
        mkswap /swapfile >/dev/null 2>&1
        swapon /swapfile
        grep -q "/swapfile" /etc/fstab || \
            echo "/swapfile none swap sw 0 0" >> /etc/fstab
        echo -e "${GREEN}Swap 1GB created!${NC}"
    else
        echo -e "${YELLOW}Swap exists, skipping...${NC}"
    fi

    echo -e "${CYAN}[4/10]${NC} Getting SSL certificate..."
    systemctl stop nginx   2>/dev/null
    systemctl stop haproxy 2>/dev/null
    sleep 1

    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --register-unsafely-without-email \
        >/dev/null 2>&1

    mkdir -p /etc/xray
    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
            /etc/xray/xray.crt
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
            /etc/xray/xray.key
        echo -e "${GREEN}SSL certificate obtained!${NC}"
    else
        echo -e "${YELLOW}Using self-signed certificate...${NC}"
        openssl req -new -newkey rsa:2048 -days 365 \
            -nodes -x509 \
            -subj "/CN=$DOMAIN" \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt 2>/dev/null
        echo -e "${GREEN}Self-signed cert created!${NC}"
    fi
    chmod 644 /etc/xray/xray.*

    echo -e "${CYAN}[5/10]${NC} Creating Xray config..."
    create_xray_config
    echo -e "${GREEN}Xray config created!${NC}"

    echo -e "${CYAN}[6/10]${NC} Configuring Nginx (port 80 & 81)..."
    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html index.htm;
    keepalive_timeout 300;
    keepalive_requests 10000;

    location / {
        try_files $uri $uri/ =404;
        autoindex on;
    }

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

server {
    listen 81;
    server_name _;
    root /var/www/html;
    index index.html;
    autoindex on;
    keepalive_timeout 300;
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

    echo -e "${CYAN}[7/10]${NC} Configuring Dropbear (port 222)..."
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    echo -e "${GREEN}Dropbear configured!${NC}"

    echo -e "${CYAN}[8/10]${NC} Configuring HAProxy (443 -> 8443)..."
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

    echo -e "${CYAN}[9/10]${NC} Installing UDP, Keepalive & Optimize..."
    install_udp_custom >/dev/null 2>&1
    setup_keepalive
    optimize_vpn

    # SSH port 22
    sed -i 's/^#\?Port.*/Port 22/' /etc/ssh/sshd_config

    # Install dependencies python
    pip3 install requests \
        --break-system-packages >/dev/null 2>&1 || \
        pip3 install requests >/dev/null 2>&1

    # Install speedtest
    pip3 install speedtest-cli \
        --break-system-packages >/dev/null 2>&1 || \
        apt-get install -y speedtest-cli >/dev/null 2>&1

    echo -e "${CYAN}[10/10]${NC} Starting all services..."
    systemctl daemon-reload
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

    # Setup menu command
    setup_menu_command

    # Buat index.html
    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html>
<html>
<head>
<title>${DOMAIN} - VPN Server</title>
<style>
body{font-family:Arial;background:#1a1a2e;color:#eee;
     text-align:center;padding:50px}
h1{color:#00d4ff}
p{color:#aaa}
</style>
</head>
<body>
<h1>VPN Server</h1>
<p>${DOMAIN}</p>
<p>Powered by Proffessor Squad</p>
</body>
</html>
IDXEOF

    local ip_vps
    ip_vps=$(get_ip)

    clear
    echo -e "${GREEN}+=========================================+${NC}"
    echo -e "${GREEN}|       Installation Complete!            |${NC}"
    echo -e "${GREEN}+=========================================+${NC}"
    echo ""
    printf " %-26s : %s\n" "Domain"               "$DOMAIN"
    printf " %-26s : %s\n" "IP VPS"               "$ip_vps"
    printf " %-26s : %s\n" "SSH"                  "22"
    printf " %-26s : %s\n" "Dropbear"             "222"
    printf " %-26s : %s\n" "Nginx"                "80, 81"
    printf " %-26s : %s\n" "HAProxy"              "443 -> 8443"
    printf " %-26s : %s\n" "Xray TLS VMess/VLess" "8443"
    printf " %-26s : %s\n" "Trojan TLS"           "2083"
    printf " %-26s : %s\n" "Xray gRPC"            "8444"
    printf " %-26s : %s\n" "Xray WS NonTLS"       "8080"
    printf " %-26s : %s\n" "BadVPN UDP"           "7100-7300"
    printf " %-26s : %s\n" "Swap"                 "1GB"
    printf " %-26s : %s\n" "BBR"                  "Enabled"
    printf " %-26s : %s\n" "Keepalive"            "Active"
    echo ""
    echo -e "${YELLOW}Tip: Ketik 'menu' kapanpun untuk buka menu!${NC}"
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
        read -p "Options [ 00 - 19 ] >>> " choice
        case $choice in
            1|01) menu_ssh ;;
            2|02) menu_vmess ;;
            3|03) menu_vless ;;
            4|04) menu_trojan ;;
            5|05) menu_noobzvpn ;;
            6|06) menu_ss_libev ;;
            7|07) install_udp_custom ;;
            8|08) setup_swap ;;
            9|09)
                optimize_vpn
                echo -e "${GREEN}Done!${NC}"
                sleep 2
                ;;
            10)
                clear
                echo -e "${CYAN}Restarting services...${NC}"
                echo ""
                for svc in xray nginx sshd dropbear \
                           haproxy udp-custom \
                           vpn-keepalive openvpn@server \
                           shadowsocks-libev vpn-bot; do
                    if systemctl restart "$svc" 2>/dev/null; then
                        echo -e " ${GREEN}+${NC} $svc"
                    else
                        echo -e " ${RED}x${NC} $svc"
                    fi
                done
                sleep 2
                ;;
            11)
                clear
                echo -e "${CYAN}+=========================================+${NC}"
                echo -e "${CYAN}|${NC}  ${WHITE}SERVICE STATUS${NC}"
                echo -e "${CYAN}+=========================================+${NC}"
                for svc in xray nginx sshd dropbear \
                           haproxy udp-custom \
                           vpn-keepalive openvpn@server \
                           shadowsocks-libev vpn-bot; do
                    if systemctl is-active --quiet "$svc"; then
                        echo -e " ${GREEN}+${NC} $svc ${GREEN}[RUNNING]${NC}"
                    else
                        echo -e " ${RED}x${NC} $svc ${RED}[STOPPED]${NC}"
                    fi
                done
                echo -e "${CYAN}+=========================================+${NC}"
                echo ""
                echo -e "${WHITE}Port Status:${NC}"
                ss -tulpn 2>/dev/null | \
                    grep -E ':22 |:80 |:81 |:222 |:443 |:1194 |:2083 |:8080 |:8388 |:8443 |:8444 ' | \
                    awk '{printf " + %s %s\n", $1, $5}'
                echo ""
                read -p "Press any key to back on menu..."
                ;;
            12) show_info_port ;;
            13) cek_expired ;;
            14) delete_expired ;;
            15) menu_telegram_bot ;;
            16) change_domain ;;
            17) fix_certificate ;;
            18) menu_update ;;
            19) run_speedtest ;;
            0|00)
                clear
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

[[ $EUID -ne 0 ]] && {
    echo "Run as root!"
    exit 1
}

# Load domain
[[ -f "$DOMAIN_FILE" ]] && \
    DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

# First time install
[[ ! -f "$DOMAIN_FILE" ]] && auto_install

# Setup menu command setiap run
setup_menu_command

# Jalankan main menu
main_menu
