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
ORDER_DIR="/root/orders"
PAYMENT_FILE="/root/.payment_info"
DOMAIN_TYPE_FILE="/root/.domain_type"

#================================================
# PORT VARIABLES
#================================================
SSH_PORT="22"
DROPBEAR_PORT="222"
NGINX_PORT="80"
NGINX_DL_PORT="81"
HAPROXY_PORT="443"
VMESS_TLS_PORT="443"
VLESS_TLS_PORT="443"
TROJAN_TLS_PORT="443"
XRAY_INTERNAL_TLS="8443"
XRAY_WS_NONTLS_PORT="80"
XRAY_GRPC_PORT="8444"
BADVPN_RANGE="7100-7300"
PRICE_MONTHLY="10000"
DURATION_MONTHLY="30"

#================================================
# PROGRESS BAR
#================================================

progress_bar() {
    local current="$1"
    local total="$2"
    local label="$3"
    local width=30
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    local pct=$(( current * 100 / total ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="="; done
    if [[ $filled -lt $width ]]; then
        bar+=">"
        for ((i=0; i<empty-1; i++)); do
            bar+=" "
        done
    fi
    printf "\r ${CYAN}[${NC}${GREEN}%-${width}s${NC}${CYAN}]${NC} ${WHITE}%3d%%${NC} %s" \
        "$bar" "$pct" "$label"
}

show_progress() {
    progress_bar "$1" "$2" "$3"
    echo ""
}

done_msg() {
    printf " ${GREEN}[✓]${NC} %-40s ${GREEN}Done!${NC}\n" "$1"
}

fail_msg() {
    printf " ${RED}[✗]${NC} %-40s ${RED}Failed!${NC}\n" "$1"
}

info_msg() {
    printf " ${CYAN}[i]${NC} %s\n" "$1"
}

#================================================
# BANNER INSTALL
#================================================

show_install_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'ASCIIEOF'
⢀⡟⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠹⣿⣿⣿⣿⣿⣿⣿⣿⡄⠄
⢸⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣿⣿⣿⣿⣿⣿⣿⡀
⣾⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⠸⣿⣿⣿⣿⣿⡿⠻⢿⡇
⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⡀⠄⢸⣿⡇⣿⣿⣿⣿⣿⠁⠄⠈⣿
⢹⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠁⢀⣼⣿⡇⣿⣿⣿⣿⣿⡈⠃⢠⡇
⢸⡼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⡇
⠈⣷⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢱⣿⣿⣿⣿⣿⣿⣿⣿⠁
⠄⢸⣧⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢡⣿⣿⣿⣿⣿⣿⣿⣿⠇⠄
⠄⠄⢿⣷⣝⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⣡⣾⣿⣿⣿⣿⣿⣿⡿⠋⠄⠄
ASCIIEOF
    echo -e "${NC}"
    echo -e "${WHITE}  ____  ____   ___  _____ _____ ____  ____  ___  ____${NC}"
    echo -e "${CYAN}  Auto VPN Installer v${SCRIPT_VERSION}${NC}"
    echo -e "${GREEN}  By The Proffessor Squad${NC}"
    echo ""
    echo -e "${CYAN}+=========================================+${NC}"
}

#================================================
# UTILITY FUNCTIONS
#================================================

check_status() {
    systemctl is-active --quiet "$1" \
        2>/dev/null && \
        echo "ON" || echo "OFF"
}

get_ip() {
    local ip
    for url in \
        "https://ifconfig.me" \
        "https://ipinfo.io/ip" \
        "https://api.ipify.org" \
        "https://checkip.amazonaws.com"; do
        ip=$(curl -s --max-time 3 \
            "$url" 2>/dev/null)
        if [[ -n "$ip" ]] && \
           ! echo "$ip" | \
           grep -q "error\|reset\|refused\|<"
        then
            echo "$ip"; return
        fi
    done
    ip=$(ip route get 8.8.8.8 2>/dev/null | \
        awk '{print $7; exit}')
    echo "${ip:-N/A}"
}

send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    [[ ! -f "$CHAT_ID_FILE" ]]   && return
    local token chatid
    token=$(cat "$BOT_TOKEN_FILE")
    chatid=$(cat "$CHAT_ID_FILE")
    curl -s -X POST \
        "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" \
        -d text="$1" \
        -d parse_mode="HTML" \
        --max-time 10 >/dev/null 2>&1
}

print_menu_header() {
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
    printf "${CYAN}|${NC}  %-44s ${CYAN}|${NC}\n" "$1"
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
}

print_menu_footer() {
    echo -e "${CYAN}+-----------------------------------------------+${NC}"
}

#================================================
# DOMAIN SETUP
#================================================

generate_random_domain() {
    local ip_vps chars random_str
    ip_vps=$(get_ip)
    chars="abcdefghijklmnopqrstuvwxyz"
    random_str=""
    for i in {1..6}; do
        random_str+="${chars:RANDOM%26:1}"
    done
    echo "${random_str}.${ip_vps}.nip.io"
}

setup_domain() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SETUP DOMAIN${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " ${WHITE}[1]${NC} Pakai domain sendiri"
    echo -e "     ${YELLOW}Contoh: vpn.example.com${NC}"
    echo -e "     SSL: Let's Encrypt"
    echo ""
    echo -e " ${WHITE}[2]${NC} Generate domain otomatis"
    local preview
    preview=$(generate_random_domain)
    echo -e "     ${YELLOW}Contoh: ${preview}${NC}"
    echo -e "     SSL: Self-signed"
    echo ""
    read -p " Pilih [1/2]: " domain_choice
    case $domain_choice in
        1)
            echo ""
            read -p " Masukkan domain: " input_domain
            [[ -z "$input_domain" ]] && {
                echo -e "${RED}Domain kosong!${NC}"
                sleep 2; setup_domain; return
            }
            DOMAIN="$input_domain"
            echo "custom" > "$DOMAIN_TYPE_FILE"
            ;;
        2)
            DOMAIN=$(generate_random_domain)
            echo "random" > "$DOMAIN_TYPE_FILE"
            echo -e "${GREEN}Domain: ${CYAN}${DOMAIN}${NC}"
            sleep 1
            ;;
        *)
            echo -e "${RED}Tidak valid!${NC}"
            sleep 1; setup_domain; return
            ;;
    esac
    echo "$DOMAIN" > "$DOMAIN_FILE"
}

get_ssl_cert() {
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && \
        domain_type=$(cat "$DOMAIN_TYPE_FILE")
    mkdir -p /etc/xray
    if [[ "$domain_type" == "custom" ]]; then
        certbot certonly --standalone \
            -d "$DOMAIN" \
            --non-interactive \
            --agree-tos \
            --register-unsafely-without-email \
            >/dev/null 2>&1
        if [[ -f \
            "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]];
        then
            cp \
            "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" \
                /etc/xray/xray.crt
            cp \
            "/etc/letsencrypt/live/$DOMAIN/privkey.pem" \
                /etc/xray/xray.key
        else
            _gen_self_signed
        fi
    else
        _gen_self_signed
    fi
    chmod 644 /etc/xray/xray.*
}

_gen_self_signed() {
    openssl req -new -newkey rsa:2048 \
        -days 3650 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt 2>/dev/null
}

#================================================
# SETUP MENU COMMAND
#================================================

setup_menu_command() {
    cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
[[ -f /root/tunnel.sh ]] && \
    bash /root/tunnel.sh || \
    echo "Script not found!"
MENUEOF
    chmod +x /usr/local/bin/menu
    if ! grep -q "tunnel.sh" \
        /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc << 'BASHEOF'

# VPN Menu Auto Run
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh
BASHEOF
    fi
}

#================================================
# SETUP SWAP
#================================================

setup_swap() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SETUP SWAP 1GB${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    local swap_total
    swap_total=$(free -m | awk 'NR==3{print $2}')
    if [[ "$swap_total" -gt 0 ]]; then
        echo -e "${YELLOW}Swap ada: ${swap_total}MB${NC}"
        swapoff -a 2>/dev/null
        sed -i '/swapfile/d' /etc/fstab
        rm -f /swapfile
    fi
    echo -e "${CYAN}Creating 1GB swap...${NC}"
    fallocate -l 1G /swapfile 2>/dev/null || \
        dd if=/dev/zero of=/swapfile \
           bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    swapon /swapfile
    grep -q "/swapfile" /etc/fstab || \
        echo "/swapfile none swap sw 0 0" \
        >> /etc/fstab
    echo -e "${GREEN}Swap 1GB OK!${NC}"
    sleep 2
}

#================================================
# OPTIMIZE VPN
#================================================

optimize_vpn() {
    cat > /etc/sysctl.d/99-vpn.conf << 'SYSCTLEOF'
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 6
net.ipv4.tcp_fin_timeout = 10
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
vm.swappiness = 10
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
SYSCTLEOF
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    sysctl -p /etc/sysctl.d/99-vpn.conf \
        >/dev/null 2>&1
    cat > /etc/security/limits.d/99-vpn.conf \
        << 'LIMEOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
LIMEOF
}

#================================================
# SETUP KEEPALIVE
#================================================

setup_keepalive() {
    local sshcfg="/etc/ssh/sshd_config"
    grep -q "^ClientAliveInterval" \
        "$sshcfg" && \
        sed -i \
        's/^ClientAliveInterval.*/ClientAliveInterval 30/' \
        "$sshcfg" || \
        echo "ClientAliveInterval 30" >> "$sshcfg"
    grep -q "^ClientAliveCountMax" \
        "$sshcfg" && \
        sed -i \
        's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' \
        "$sshcfg" || \
        echo "ClientAliveCountMax 6" >> "$sshcfg"
    grep -q "^TCPKeepAlive" "$sshcfg" && \
        sed -i \
        's/^TCPKeepAlive.*/TCPKeepAlive yes/' \
        "$sshcfg" || \
        echo "TCPKeepAlive yes" >> "$sshcfg"
    systemctl restart sshd 2>/dev/null

    mkdir -p \
        /etc/systemd/system/xray.service.d
    cat > \
        /etc/systemd/system/xray.service.d/override.conf \
        << 'XKEOF'
[Service]
Restart=always
RestartSec=3
LimitNOFILE=65535
XKEOF

    cat > /usr/local/bin/vpn-keepalive.sh \
        << 'VPNEOF'
#!/bin/bash
while true; do
    GW=$(ip route | \
        awk '/default/{print $3; exit}')
    [[ -n "$GW" ]] && \
        ping -c1 -W2 "$GW" >/dev/null 2>&1
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1
    sleep 25
done
VPNEOF
    chmod +x /usr/local/bin/vpn-keepalive.sh

    cat > \
        /etc/systemd/system/vpn-keepalive.service \
        << 'KASEOF'
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
}

#================================================
# HAPROXY - FIXED (NO BACKSLASH)
#================================================

configure_haproxy() {
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
}

#================================================
# CHANGE DOMAIN
#================================================

change_domain() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CHANGE DOMAIN${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e " Current: ${GREEN}${DOMAIN:-Not Set}${NC}"
    echo ""
    setup_domain
    echo -e "${YELLOW}Run Fix Certificate [15]!${NC}"
    sleep 3
}

#================================================
# FIX CERTIFICATE
#================================================

fix_certificate() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}FIX / RENEW CERTIFICATE${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' \
            < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && {
        echo -e "${RED}Domain belum diset!${NC}"
        sleep 3; return
    }
    echo -e " Domain: ${GREEN}${DOMAIN}${NC}"
    echo ""
    systemctl stop haproxy 2>/dev/null
    systemctl stop nginx   2>/dev/null
    sleep 1
    get_ssl_cert
    systemctl start nginx   2>/dev/null
    systemctl start haproxy 2>/dev/null
    systemctl restart xray  2>/dev/null
    echo -e "${GREEN}Done!${NC}"
    sleep 3
}

#================================================
# SPEEDTEST
#================================================

run_speedtest() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}SPEEDTEST${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    echo -e "${CYAN}Testing download speed...${NC}"
    echo ""
    local servers=(
        "https://speed.cloudflare.com/__down?bytes=104857600"
        "https://proof.ovh.net/files/100Mb.dat"
        "https://speedtest.tele2.net/100MB.zip"
    )
    for server in "${servers[@]}"; do
        local speed speed_mbps host
        host=$(echo "$server" | \
            cut -d'/' -f3)
        speed=$(curl -o /dev/null -s \
            --max-time 15 \
            -w "%{speed_download}" \
            "$server" 2>/dev/null)
        if [[ -n "$speed" ]]; then
            speed_mbps=$(echo "$speed" | \
                awk '{printf "%.2f",$1/125000}')
            echo -e \
            " ${WHITE}Server${NC}: ${CYAN}${host}${NC}"
            echo -e \
            " ${WHITE}Speed ${NC}: ${GREEN}${speed_mbps} Mbps${NC}"
            echo ""
        fi
    done
    echo -e "${CYAN}Ping test:${NC}"
    ping -c 4 8.8.8.8 2>/dev/null | \
        tail -2 | while read line; do
        echo -e " ${WHITE}${line}${NC}"
    done
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# UPDATE MENU
#================================================

update_menu() {
    clear
    print_menu_header "UPDATE SCRIPT"
    echo ""
    echo -e " Current: ${GREEN}${SCRIPT_VERSION}${NC}"
    echo ""
    echo -e "${CYAN}Checking GitHub...${NC}"
    local latest
    latest=$(curl -s --max-time 10 \
        "$VERSION_URL" 2>/dev/null | \
        tr -d '\n\r ' | xargs)
    [[ -z "$latest" ]] && {
        echo -e "${RED}Cannot get version!${NC}"
        read -p "Press Enter..."; return
    }
    echo -e " Latest : ${GREEN}${latest}${NC}"
    echo ""
    [[ "$latest" == "$SCRIPT_VERSION" ]] && {
        echo -e "${GREEN}Up to date!${NC}"
        read -p "Press Enter..."; return
    }
    read -p "Update? [y/n]: " confirm
    [[ "$confirm" != "y" ]] && return
    cp "$SCRIPT_PATH" "$BACKUP_PATH" \
        2>/dev/null || {
        echo -e "${RED}Backup failed!${NC}"
        sleep 2; return
    }
    local tmp="/tmp/tunnel_new.sh"
    local i=0 chars="/-\|"
    curl -s --max-time 60 \
        "$SCRIPT_URL" -o "$tmp" &
    local cpid=$!
    while kill -0 $cpid 2>/dev/null; do
        printf "\r ${CYAN}[${chars:$((i%4)):1}]${NC} Downloading..."
        sleep 0.2; ((i++))
    done
    wait $cpid
    printf "\r ${GREEN}[✓]${NC} Download complete!     \n"
    [[ ! -s "$tmp" ]] && {
        echo -e "${RED}Download failed!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        sleep 2; return
    }
    bash -n "$tmp" 2>/dev/null || {
        echo -e "${RED}Validation failed!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        rm -f "$tmp"; sleep 2; return
    }
    mv "$tmp" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}Updated!${NC}"
    sleep 2
    exec bash "$SCRIPT_PATH"
}

rollback_script() {
    clear
    print_menu_header "ROLLBACK SCRIPT"
    echo ""
    [[ ! -f "$BACKUP_PATH" ]] && {
        echo -e "${RED}No backup!${NC}"
        read -p "Press Enter..."; return
    }
    local bv
    bv=$(grep "SCRIPT_VERSION=" \
        "$BACKUP_PATH" | \
        head -1 | cut -d'"' -f2)
    echo -e " Current: ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e " Backup : ${YELLOW}${bv:-Unknown}${NC}"
    echo ""
    read -p "Rollback? [y/n]: " c
    [[ "$c" != "y" ]] && return
    cp "$BACKUP_PATH" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}Done!${NC}"; sleep 2
    exec bash "$SCRIPT_PATH"
}

#================================================
# UNINSTALL
#================================================

menu_uninstall() {
    while true; do
        clear
        print_menu_header "UNINSTALL MENU"
        echo -e "     ${WHITE}[1]${NC} Uninstall Xray"
        echo -e "     ${WHITE}[2]${NC} Uninstall Nginx"
        echo -e "     ${WHITE}[3]${NC} Uninstall HAProxy"
        echo -e "     ${WHITE}[4]${NC} Uninstall Dropbear"
        echo -e "     ${WHITE}[5]${NC} Uninstall UDP Custom"
        echo -e "     ${WHITE}[6]${NC} Uninstall Bot Telegram"
        echo -e "     ${WHITE}[7]${NC} Uninstall Keepalive"
        echo -e "     ${RED}[8]${NC} ${RED}HAPUS SEMUA SCRIPT${NC}"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) _uninstall_xray ;;
            2) _uninstall_nginx ;;
            3) _uninstall_haproxy ;;
            4) _uninstall_dropbear ;;
            5) _uninstall_udp ;;
            6) _uninstall_bot ;;
            7) _uninstall_keepalive ;;
            8) _uninstall_all ;;
            0) return ;;
        esac
    done
}

_uninstall_xray() {
    clear
    print_menu_header "UNINSTALL XRAY"
    echo ""
    read -p " Yakin uninstall Xray? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop xray 2>/dev/null
    systemctl disable xray 2>/dev/null
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1
    rm -rf /usr/local/etc/xray \
           /var/log/xray \
           /etc/xray
    rm -f "$AKUN_DIR"/vmess-*.txt \
          "$AKUN_DIR"/vless-*.txt \
          "$AKUN_DIR"/trojan-*.txt
    echo -e "${GREEN}Xray uninstalled!${NC}"
    sleep 2
}

_uninstall_nginx() {
    clear
    print_menu_header "UNINSTALL NGINX"
    echo ""
    read -p " Yakin uninstall Nginx? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    apt-get purge -y nginx nginx-common \
        >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}Nginx uninstalled!${NC}"
    sleep 2
}

_uninstall_haproxy() {
    clear
    print_menu_header "UNINSTALL HAPROXY"
    echo ""
    read -p " Yakin uninstall HAProxy? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop haproxy 2>/dev/null
    systemctl disable haproxy 2>/dev/null
    apt-get purge -y haproxy >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}HAProxy uninstalled!${NC}"
    sleep 2
}

_uninstall_dropbear() {
    clear
    print_menu_header "UNINSTALL DROPBEAR"
    echo ""
    read -p " Yakin uninstall Dropbear? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop dropbear 2>/dev/null
    systemctl disable dropbear 2>/dev/null
    apt-get purge -y dropbear >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}Dropbear uninstalled!${NC}"
    sleep 2
}

_uninstall_udp() {
    clear
    print_menu_header "UNINSTALL UDP CUSTOM"
    echo ""
    read -p " Yakin uninstall UDP? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop udp-custom 2>/dev/null
    systemctl disable udp-custom 2>/dev/null
    rm -f /etc/systemd/system/udp-custom.service
    rm -f /usr/local/bin/udp-custom
    systemctl daemon-reload
    echo -e "${GREEN}UDP Custom uninstalled!${NC}"
    sleep 2
}

_uninstall_bot() {
    clear
    print_menu_header "UNINSTALL BOT TELEGRAM"
    echo ""
    read -p " Yakin uninstall Bot? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop vpn-bot 2>/dev/null
    systemctl disable vpn-bot 2>/dev/null
    rm -f /etc/systemd/system/vpn-bot.service
    rm -rf /root/bot
    rm -f "$BOT_TOKEN_FILE" \
          "$CHAT_ID_FILE" \
          "$PAYMENT_FILE"
    systemctl daemon-reload
    echo -e "${GREEN}Bot Telegram uninstalled!${NC}"
    sleep 2
}

_uninstall_keepalive() {
    clear
    print_menu_header "UNINSTALL KEEPALIVE"
    echo ""
    read -p " Yakin uninstall Keepalive? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop vpn-keepalive 2>/dev/null
    systemctl disable vpn-keepalive 2>/dev/null
    rm -f \
        /etc/systemd/system/vpn-keepalive.service
    rm -f /usr/local/bin/vpn-keepalive.sh
    systemctl daemon-reload
    echo -e "${GREEN}Keepalive uninstalled!${NC}"
    sleep 2
}

_uninstall_all() {
    clear
    echo -e "${RED}+=========================================+${NC}"
    echo -e "${RED}|      !! HAPUS SEMUA SCRIPT !!           |${NC}"
    echo -e "${RED}+=========================================+${NC}"
    echo ""
    echo -e "${YELLOW}Ini akan menghapus SEMUA:${NC}"
    echo -e " - Xray + semua akun"
    echo -e " - Nginx, HAProxy, Dropbear"
    echo -e " - UDP Custom, Keepalive"
    echo -e " - Bot Telegram + orders"
    echo -e " - Script tunnel.sh"
    echo -e " - Domain & config files"
    echo ""
    read -p " Ketik 'HAPUS' untuk konfirmasi: " \
        confirm
    [[ "$confirm" != "HAPUS" ]] && {
        echo -e "${YELLOW}Dibatalkan.${NC}"
        sleep 2; return
    }

    echo ""
    echo -e "${RED}Menghapus semua...${NC}"
    echo ""

    # Stop semua service
    for svc in xray nginx haproxy dropbear \
               udp-custom vpn-keepalive \
               vpn-bot; do
        systemctl stop    "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        echo -e " ${RED}-${NC} Stopped: $svc"
    done

    # Uninstall Xray
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1

    # Uninstall packages
    apt-get purge -y \
        nginx haproxy dropbear \
        >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1

    # Hapus semua files
    rm -rf /usr/local/etc/xray \
           /var/log/xray \
           /etc/xray \
           /root/akun \
           /root/bot \
           /root/orders \
           /root/domain \
           /root/.domain_type \
           /root/.bot_token \
           /root/.chat_id \
           /root/.payment_info \
           /root/tunnel.sh.bak

    rm -f /etc/systemd/system/udp-custom.service
    rm -f /etc/systemd/system/vpn-keepalive.service
    rm -f /etc/systemd/system/vpn-bot.service
    rm -f /usr/local/bin/udp-custom
    rm -f /usr/local/bin/vpn-keepalive.sh
    rm -f /usr/local/bin/menu
    rm -f /root/tunnel.sh

    # Hapus dari bashrc
    sed -i '/tunnel.sh/d' \
        /root/.bashrc 2>/dev/null
    sed -i '/VPN Menu Auto Run/d' \
        /root/.bashrc 2>/dev/null

    systemctl daemon-reload

    echo ""
    echo -e "${GREEN}Semua script berhasil dihapus!${NC}"
    echo -e "${YELLOW}Server akan kembali bersih.${NC}"
    echo ""
    sleep 3
    exit 0
}
#================================================
# FIX XRAY PERMISSIONS
#================================================

fix_xray_permissions() {
    mkdir -p /usr/local/etc/xray /var/log/xray
    chmod 755 /usr/local/etc/xray
    chmod 755 /var/log/xray
    touch /var/log/xray/access.log \
          /var/log/xray/error.log
    chmod 644 /var/log/xray/access.log \
              /var/log/xray/error.log
    chmod 644 /usr/local/etc/xray/config.json \
        2>/dev/null
    chown -R nobody:nogroup \
        /var/log/xray 2>/dev/null
}

#================================================
# CREATE XRAY CONFIG
# Port Internal: 8443 (TLS), 8080 (NonTLS), 8444 (gRPC)
# Port User: 443 (via HAProxy), 80 (via Nginx)
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
        "wsSettings": {
          "path": "/vmess",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "tag": "vmess-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "tag": "vmess-nontls-8080"
    },
    {
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "wsSettings": {
          "path": "/vless",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "tag": "vless-tls-8443"
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "tag": "vless-nontls-8080"
    },
    {
      "port": 8443,
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
        "wsSettings": {
          "path": "/trojan",
          "headers": {}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      },
      "tag": "trojan-tls-8443"
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
        "grpcSettings": {
          "serviceName": "vmess-grpc"
        }
      },
      "tag": "vmess-grpc-8444"
    },
    {
      "port": 8444,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{
            "certificateFile": "/etc/xray/xray.crt",
            "keyFile": "/etc/xray/xray.key"
          }]
        },
        "grpcSettings": {
          "serviceName": "vless-grpc"
        }
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
        "grpcSettings": {
          "serviceName": "trojan-grpc"
        }
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
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "block"
    }]
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
        DOMAIN=$(tr -d '\n\r' \
            < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && {
        source /etc/os-release
        os_name="${PRETTY_NAME}"
    }

    local ip_vps ram swap_info cpu uptime_str
    ip_vps=$(get_ip)
    ram=$(free -m | \
        awk 'NR==2{printf "%s/%sMB",$3,$2}')
    swap_info=$(free -m | \
        awk 'NR==3{printf "%s/%sMB",$3,$2}')
    cpu=$(top -bn1 | grep "Cpu(s)" | \
        awk '{print $2}' | \
        cut -d'%' -f1 2>/dev/null || \
        echo "N/A")
    uptime_str=$(uptime -p | sed 's/up //')

    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}          ${GREEN}Welcome Mr. ${USERNAME}${NC}"
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
    vc=$(ls "$AKUN_DIR"/vmess-*.txt \
        2>/dev/null | wc -l)
    lc=$(ls "$AKUN_DIR"/vless-*.txt \
        2>/dev/null | wc -l)
    tc=$(ls "$AKUN_DIR"/trojan-*.txt \
        2>/dev/null | wc -l)
    sc=$(ls "$AKUN_DIR"/ssh-*.txt \
        2>/dev/null | wc -l)

    echo -e "              ${CYAN}>>> INFORMATION ACCOUNT <<<${NC}"
    echo -e "     ${CYAN}===============================================${NC}"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "SSH/UDP"       "$sc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "VMESS/WS/GRPC" "$vc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "VLESS/WS/GRPC" "$lc"
    printf "           %-20s = ${GREEN}%s${NC}\n" \
        "TROJAN/WS/GRPC" "$tc"
    echo -e "     ${CYAN}===============================================${NC}"
    echo -e "                ${CYAN}>>> ${USERNAME} <<<${NC}"
    echo ""

    # Service status
    local s1 s2 s3 s4 s5 s6 s7 s8
    s1=$(check_status sshd)
    s2=$(check_status nginx)
    s3=$(check_status xray)
    s4=$(check_status udp-custom)
    s5=$(check_status haproxy)
    s6=$(check_status dropbear)
    s7=$(check_status vpn-keepalive)
    s8=$(check_status vpn-bot)

    _col() {
        [[ "$1" == "ON" ]] && \
            printf "${GREEN}ON ${NC}" || \
            printf "${RED}OFF${NC}"
    }

    local c1 c2 c3 c4 c5 c6 c7 c8
    c1=$(_col "$s1")
    c2=$(_col "$s2")
    c3=$(_col "$s3")
    c4=$(_col "$s4")
    c5=$(_col "$s5")
    c6=$(_col "$s6")
    c7=$(_col "$s7")
    c8=$(_col "$s8")

    echo -e "${CYAN}+================+================+================+${NC}"
    printf "${CYAN}|${NC} SSH    %-14b${CYAN}|${NC} NGINX   %-14b${CYAN}|${NC} XRAY    %-14b${CYAN}|${NC}\n" \
        "$c1" "$c2" "$c3"
    printf "${CYAN}|${NC} HAPRXY %-14b${CYAN}|${NC} DROPBR  %-14b${CYAN}|${NC} UDP     %-14b${CYAN}|${NC}\n" \
        "$c5" "$c6" "$c4"
    printf "${CYAN}|${NC} PINGKA %-14b${CYAN}|${NC} BOT     %-14b${CYAN}|${NC}                 ${CYAN}|${NC}\n" \
        "$c7" "$c8"
    echo -e "${CYAN}+================+================+================+${NC}"
}

#================================================
# SHOW MAIN MENU
# Menu 5 & 6 sekarang = CEK EXPIRED & DEL EXPIRED
# OpenVPN & SS-Libev dihapus
#================================================

show_menu() {
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[01]${NC} SSH MENU    ${CYAN}|${NC} ${WHITE}[07]${NC} SWAP SETUP  ${CYAN}|${NC} ${WHITE}[13]${NC} TELE BOT   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[02]${NC} VMESS MENU  ${CYAN}|${NC} ${WHITE}[08]${NC} OPTIMIZE    ${CYAN}|${NC} ${WHITE}[14]${NC} CHG DOMAIN ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[03]${NC} VLESS MENU  ${CYAN}|${NC} ${WHITE}[09]${NC} RESTART ALL ${CYAN}|${NC} ${WHITE}[15]${NC} FIX CERT   ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[04]${NC} TROJAN MENU ${CYAN}|${NC} ${WHITE}[10]${NC} RUNNING     ${CYAN}|${NC} ${WHITE}[16]${NC} UPDATE     ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[05]${NC} CEK EXPIRED ${CYAN}|${NC} ${WHITE}[11]${NC} INFO PORT   ${CYAN}|${NC} ${WHITE}[17]${NC} SPEEDTEST  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC} ${WHITE}[06]${NC} DEL EXPIRED ${CYAN}|${NC} ${WHITE}[12]${NC} INSTALL UDP ${CYAN}|${NC} ${WHITE}[18]${NC} UNINSTALL  ${CYAN}|${NC}"
    echo -e "${CYAN}|${NC}                 ${CYAN}|${NC}                 ${CYAN}|${NC} ${WHITE}[00]${NC} EXIT       ${CYAN}|${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} Ver: ${GREEN}%-8s${NC} | Author: ${GREEN}%-29s${NC} ${CYAN}|${NC}\n" \
        "$SCRIPT_VERSION" "$SCRIPT_AUTHOR"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
}

#================================================
# INFO PORT
#================================================

show_info_port() {
    clear
    echo -e "${CYAN}+========================================================+${NC}"
    echo -e "${CYAN}|${NC}           ${WHITE}SERVER PORT INFORMATION${NC}              ${CYAN}|${NC}"
    echo -e "${CYAN}+========================================================+${NC}"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "SSH"                 "22"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Dropbear"            "222"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Nginx (NonTLS)"      "80"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Nginx Download"      "81"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "HAProxy (TLS)"       "443 -> Xray 8443"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray WS TLS"         "443 (via HAProxy)"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray WS NonTLS"      "80 (via Nginx)"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "Xray gRPC TLS"       "8444"
    printf "${CYAN}|${NC} %-28s : ${GREEN}%-20s${NC} ${CYAN}|${NC}\n" \
        "BadVPN UDP"          "7100-7300"
    echo -e "${CYAN}+========================================================+${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# CEK EXPIRED
#================================================

cek_expired() {
    clear
    print_menu_header "CEK EXPIRED ACCOUNTS"
    echo ""
    local today found=0
    today=$(date +%s)
    shopt -s nullglob
    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str exp_ts uname diff
        exp_str=$(grep "EXPIRED=" "$f" \
            2>/dev/null | \
            head -1 | cut -d= -f2-)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" \
            +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue
        uname=$(basename "$f" .txt)
        diff=$(( (exp_ts - today) / 86400 ))
        if [[ $diff -le 3 ]]; then
            found=1
            if [[ $diff -lt 0 ]]; then
                echo -e \
                " ${RED}EXPIRED${NC}: $uname"
                echo -e \
                "          ${YELLOW}($exp_str)${NC}"
            else
                echo -e \
                " ${YELLOW}${diff} hari${NC}: $uname"
                echo -e \
                "          ${CYAN}($exp_str)${NC}"
            fi
        fi
    done
    shopt -u nullglob
    [[ $found -eq 0 ]] && \
        echo -e "${GREEN}Tidak ada akun expired!${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# DELETE EXPIRED
#================================================

delete_expired() {
    clear
    print_menu_header "DELETE EXPIRED ACCOUNTS"
    echo ""
    local today count=0
    today=$(date +%s)
    shopt -s nullglob
    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str exp_ts fname \
              uname protocol
        exp_str=$(grep "EXPIRED=" "$f" \
            2>/dev/null | \
            head -1 | cut -d= -f2-)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" \
            +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue
        if [[ $exp_ts -lt $today ]]; then
            fname=$(basename "$f" .txt)
            protocol=${fname%%-*}
            uname=${fname#*-}
            echo -e \
            " ${RED}Deleting${NC}: $fname"
            local tmp
            tmp=$(mktemp)
            jq --arg email "$uname" \
               'del(.inbounds[].settings.clients[]?
                | select(.email == $email))' \
               "$XRAY_CONFIG" > "$tmp" \
               2>/dev/null && \
               mv "$tmp" "$XRAY_CONFIG" || \
               rm -f "$tmp"
            [[ "$protocol" == "ssh" ]] && \
                userdel -f "$uname" 2>/dev/null
            rm -f "$f"
            rm -f \
                "$PUBLIC_HTML/${fname}.txt"
            rm -f \
                "$PUBLIC_HTML/${fname}-clash.yaml"
            ((count++))
        fi
    done
    shopt -u nullglob
    if [[ $count -gt 0 ]]; then
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        echo ""
        echo -e \
        "${GREEN}Deleted ${count} accounts!${NC}"
    else
        echo -e \
        "${GREEN}Tidak ada akun expired!${NC}"
    fi
    echo ""
    read -p "Press any key to back on menu..."
}
#================================================
# CREATE ACCOUNT TEMPLATE - XRAY
# Output: TLS port 443, NonTLS port 80
#================================================

create_account_template() {
    local protocol="$1"
    local username="$2"
    local days="$3"
    local quota="$4"
    local iplimit="$5"

    local uuid ip_vps exp created
    uuid=$(cat /proc/sys/kernel/random/uuid)
    ip_vps=$(get_ip)
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    created=$(date +"%d %b, %Y")

    local temp
    temp=$(mktemp)

    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("vmess"))
             .settings.clients) +=
            [{"id":$uuid,"email":$email,
              "alterId":0}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "vless" ]]; then
        jq --arg uuid "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("vless"))
             .settings.clients) +=
            [{"id":$uuid,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "trojan" ]]; then
        jq --arg password "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("trojan"))
             .settings.clients) +=
            [{"password":$password,
              "email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    fi

    if [[ $? -eq 0 ]] && [[ -s "$temp" ]]; then
        mv "$temp" "$XRAY_CONFIG"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        sleep 1
    else
        rm -f "$temp"
        echo -e "${RED}Failed update Xray!${NC}"
        sleep 2; return 1
    fi

    mkdir -p "$AKUN_DIR"
    printf \
        "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" \
        "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    # Generate links
    # TLS  -> port 443 (via HAProxy -> 8443)
    # NonTLS -> port 80 (via Nginx -> 8080)
    local link_tls link_nontls link_grpc

    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' \
            "$j_tls" | base64 -w 0)"

        j_nontls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' \
            "$j_nontls" | base64 -w 0)"

        j_grpc=$(printf \
            '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
            "$username" "$DOMAIN" "$uuid")
        link_grpc="vmess://$(printf '%s' \
            "$j_grpc" | base64 -w 0)"

    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="vless://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"

    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="trojan://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"
    fi

    # Simpan file download
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" \
        << DLEOF
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
 Port TLS         : 443
 Port NonTLS      : 80
 Port gRPC        : 8444
 Network          : WebSocket / gRPC
 Path WS          : /${protocol}
 ServiceName gRPC : ${protocol}-grpc
 TLS              : enabled
___________________________________________
 Link TLS         : ${link_tls}
___________________________________________
 Link NonTLS      : ${link_nontls}
___________________________________________
 Link gRPC        : ${link_grpc}
___________________________________________
 Download         : http://${ip_vps}:81/${protocol}-${username}.txt
___________________________________________
 Aktif Selama     : ${days} Hari
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
DLEOF

    _print_xray_result \
        "$protocol" "$username" "$ip_vps" \
        "$uuid" "$quota" "$iplimit" \
        "$link_tls" "$link_nontls" "$link_grpc" \
        "$days" "$created" "$exp"

    send_telegram_admin \
"✅ <b>New ${protocol^^} Account</b>
👤 User  : <code>${username}</code>
🔑 UUID  : <code>${uuid}</code>
🌐 Domain: ${DOMAIN}
📅 Exp   : ${exp}"

    read -p "Press any key to back on menu..."
}

#================================================
# PRINT XRAY RESULT
# Hanya tampilkan TLS 443 dan NonTLS 80
#================================================

_print_xray_result() {
    local protocol="$1"   username="$2"
    local ip_vps="$3"     uuid="$4"
    local quota="$5"      iplimit="$6"
    local link_tls="$7"   link_nontls="$8"
    local link_grpc="$9"  days="${10}"
    local created="${11}" exp="${12}"

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
    printf " %-16s : %s\n" "Port TLS"    "443"
    printf " %-16s : %s\n" "Port NonTLS" "80"
    printf " %-16s : %s\n" "Port gRPC"   "8444"
    printf " %-16s : %s\n" "Network"     "WebSocket / gRPC"
    printf " %-16s : %s\n" "Path WS"     "/${protocol}"
    printf " %-16s : %s\n" "ServiceName" "${protocol}-grpc"
    printf " %-16s : %s\n" "TLS"         "enabled"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link TLS"
    echo "   ${link_tls}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link NonTLS"
    echo "   ${link_nontls}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link gRPC"
    echo "   ${link_grpc}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : http://%s:81/%s-%s.txt\n" \
        "Download" "$ip_vps" \
        "$protocol" "$username"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s Hari\n" \
        "Aktif Selama" "$days"
    printf " %-16s : %s\n" \
        "Dibuat"   "$created"
    printf " %-16s : %s\n" \
        "Berakhir" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
}

#================================================
# TRIAL XRAY - 1 JAM AUTO DELETE
#================================================

create_trial_xray() {
    local protocol="$1"
    local username="trial-$(date +%H%M%S)"
    local uuid ip_vps exp created
    uuid=$(cat /proc/sys/kernel/random/uuid)
    ip_vps=$(get_ip)
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
    created=$(date +"%d %b, %Y %H:%M")

    local temp
    temp=$(mktemp)

    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("vmess"))
             .settings.clients) +=
            [{"id":$uuid,"email":$email,
              "alterId":0}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "vless" ]]; then
        jq --arg uuid "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("vless"))
             .settings.clients) +=
            [{"id":$uuid,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null

    elif [[ "$protocol" == "trojan" ]]; then
        jq --arg password "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("trojan"))
             .settings.clients) +=
            [{"password":$password,
              "email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    fi

    if [[ $? -eq 0 ]] && [[ -s "$temp" ]]; then
        mv "$temp" "$XRAY_CONFIG"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        sleep 1
    else
        rm -f "$temp"
        echo -e "${RED}Failed!${NC}"
        sleep 2; return
    fi

    mkdir -p "$AKUN_DIR"
    printf \
        "UUID=%s\nQUOTA=1\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$uuid" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    # Auto delete 1 jam
    (
        sleep 3600
        local tmp
        tmp=$(mktemp)
        jq --arg email "$username" \
           'del(.inbounds[].settings.clients[]?
             | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp" \
           2>/dev/null && \
           mv "$tmp" "$XRAY_CONFIG" || \
           rm -f "$tmp"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        rm -f \
            "$AKUN_DIR/${protocol}-${username}.txt"
        rm -f \
            "$PUBLIC_HTML/${protocol}-${username}.txt"
    ) &
    disown $!

    # Generate links TLS 443 & NonTLS 80
    local link_tls link_nontls link_grpc

    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' \
            "$j_tls" | base64 -w 0)"

        j_nontls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' \
            "$j_nontls" | base64 -w 0)"

        j_grpc=$(printf \
            '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
            "$username" "$DOMAIN" "$uuid")
        link_grpc="vmess://$(printf '%s' \
            "$j_grpc" | base64 -w 0)"

    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="vless://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"

    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="trojan://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"
    fi

    clear
    echo -e "${CYAN}___________________________________________${NC}"
    echo -e "  ${WHITE}Trial ${protocol^^} (1 Jam)${NC}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Username"    "$username"
    printf " %-16s : %s\n" "IP/Host"     "$ip_vps"
    printf " %-16s : %s\n" "Domain"      "$DOMAIN"
    printf " %-16s : %s\n" "UUID"        "$uuid"
    printf " %-16s : %s\n" "Quota"       "1 GB"
    printf " %-16s : %s\n" "IP Limit"    "1 IP"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Port TLS"    "443"
    printf " %-16s : %s\n" "Port NonTLS" "80"
    printf " %-16s : %s\n" "Port gRPC"   "8444"
    printf " %-16s : %s\n" "Path WS"     "/${protocol}"
    printf " %-16s : %s\n" "ServiceName" "${protocol}-grpc"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link TLS"
    echo "   ${link_tls}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link NonTLS"
    echo "   ${link_nontls}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : \n" "Link gRPC"
    echo "   ${link_grpc}"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : 1 Jam (Auto Delete)\n" \
        "Aktif Selama"
    printf " %-16s : %s\n" "Dibuat"   "$created"
    printf " %-16s : %s\n" "Berakhir" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# CREATE SSH ACCOUNT
#================================================

create_ssh() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE SSH ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required!${NC}"
        sleep 2; return
    }
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"
        sleep 2; return
    fi
    read -p " Password      : " password
    [[ -z "$password" ]] && {
        echo -e "${RED}Required!${NC}"
        sleep 2; return
    }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"
        sleep 2; return
    }
    read -p " Limit IP      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && \
        iplimit=1

    local exp exp_date created ip_vps
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    exp_date=$(date -d "+${days} days" \
        +"%Y-%m-%d")
    created=$(date +"%d %b, %Y")
    ip_vps=$(get_ip)

    useradd -M -s /bin/false \
        -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf \
        "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" \
        "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    _save_ssh_file \
        "SSH Account" \
        "$username" "$password" \
        "$ip_vps" "$days" "$created" "$exp"

    _print_ssh_result \
        "SSH Account" \
        "$username" "$password" \
        "$ip_vps" "$days" "$created" "$exp"

    send_telegram_admin \
"✅ <b>New SSH Account</b>
👤 User : <code>${username}</code>
🔑 Pass : <code>${password}</code>
🌐 IP   : ${ip_vps}
📅 Exp  : ${exp}"

    read -p "Press any key to back on menu..."
}

#================================================
# SSH TRIAL - 1 JAM
#================================================

create_ssh_trial() {
    local suffix
    suffix=$(cat /proc/sys/kernel/random/uuid | \
        tr -d '-' | head -c 4 | \
        tr '[:lower:]' '[:upper:]')
    local username="Trial-${suffix}"
    local password="1"
    local ip_vps exp exp_date created

    ip_vps=$(get_ip)
    exp=$(date -d "+1 hour" \
        +"%d %b, %Y %H:%M")
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y %H:%M")

    useradd -M -s /bin/false \
        -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf \
        "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$username" "$password" \
        "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"

    # Auto delete 1 jam
    (
        sleep 3600
        userdel -f "$username" 2>/dev/null
        rm -f \
            "$AKUN_DIR/ssh-${username}.txt"
        rm -f \
            "$PUBLIC_HTML/ssh-${username}.txt"
    ) &
    disown $!

    _save_ssh_file \
        "Trial SSH (1 Jam)" \
        "$username" "$password" \
        "$ip_vps" "1 Jam (Auto Delete)" \
        "$created" "$exp"

    _print_ssh_result \
        "Trial SSH (1 Jam)" \
        "$username" "$password" \
        "$ip_vps" "1 Jam" "$created" "$exp"

    send_telegram_admin \
"🆓 <b>SSH Trial</b>
👤 User : <code>${username}</code>
🔑 Pass : <code>${password}</code>
⏰ Exp  : ${exp}"

    read -p "Press any key to back on menu..."
}

_save_ssh_file() {
    local title="$1"    username="$2"
    local password="$3" ip_vps="$4"
    local days="$5"     created="$6"
    local exp="$7"

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" \
        << SSHFILE
___________________________________________
  ${title}
___________________________________________
 Username         : ${username}
 Password         : ${password}
 IP/Host          : ${ip_vps}
 Domain SSH       : ${DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 SSH Ws Non SSL   : 80
 SSH Ws SSL       : 443
 BadVPN UDPGW     : 7100,7200,7300
 Format Hc        : ${DOMAIN}:80@${username}:${password}
___________________________________________
 Save Link        : http://${ip_vps}:81/ssh-${username}.txt
___________________________________________
 Payload          : GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: ws[crlf][crlf]
___________________________________________
 Aktif Selama     : ${days}
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
SSHFILE
}

_print_ssh_result() {
    local title="$1"    username="$2"
    local password="$3" ip_vps="$4"
    local days="$5"     created="$6"
    local exp="$7"

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
    printf " %-16s : %s\n" "SSH Ws Non SSL" "80"
    printf " %-16s : %s\n" "SSH Ws SSL"     "443"
    printf " %-16s : %s\n" "BadVPN UDPGW"   "7100,7200,7300"
    printf " %-16s : %s:80@%s:%s\n" \
        "Format Hc" "$DOMAIN" \
        "$username" "$password"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : http://%s:81/ssh-%s.txt\n" \
        "Save Link" "$ip_vps" "$username"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: ws[crlf][crlf]\n" \
        "Payload" "$DOMAIN"
    echo -e "${CYAN}___________________________________________${NC}"
    printf " %-16s : %s\n" "Aktif Selama"  "$days"
    printf " %-16s : %s\n" "Dibuat Pada"   "$created"
    printf " %-16s : %s\n" "Berakhir Pada" "$exp"
    echo -e "${CYAN}___________________________________________${NC}"
    echo ""
}

#================================================
# DELETE / RENEW / LIST / CHECK LOGIN
#================================================

delete_account() {
    local protocol="$1"
    clear
    print_menu_header "DELETE ${protocol^^}"
    echo ""
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No accounts!${NC}"
        sleep 2; return
    fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | \
            sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" \
            2>/dev/null | cut -d= -f2-)
        echo -e "  ${CYAN}-${NC} $n ${YELLOW}($e)${NC}"
    done
    echo ""
    read -p "Username to delete: " username
    [[ -z "$username" ]] && return
    local tmp
    tmp=$(mktemp)
    jq --arg email "$username" \
       'del(.inbounds[].settings.clients[]?
         | select(.email == $email))' \
       "$XRAY_CONFIG" > "$tmp" \
       2>/dev/null && \
       mv "$tmp" "$XRAY_CONFIG" || \
       rm -f "$tmp"
    fix_xray_permissions
    systemctl restart xray 2>/dev/null
    rm -f \
        "$AKUN_DIR/${protocol}-${username}.txt"
    rm -f \
        "$PUBLIC_HTML/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && \
        userdel -f "$username" 2>/dev/null
    echo -e "${GREEN}Deleted: ${username}${NC}"
    sleep 2
}

renew_account() {
    local protocol="$1"
    clear
    print_menu_header "RENEW ${protocol^^}"
    echo ""
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No accounts!${NC}"
        sleep 2; return
    fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | \
            sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" \
            2>/dev/null | cut -d= -f2-)
        echo -e "  ${CYAN}-${NC} $n ${YELLOW}($e)${NC}"
    done
    echo ""
    read -p "Username to renew: " username
    [[ -z "$username" ]] && return
    [[ ! -f \
        "$AKUN_DIR/${protocol}-${username}.txt" \
    ]] && {
        echo -e "${RED}Not found!${NC}"
        sleep 2; return
    }
    read -p "Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"
        sleep 2; return
    }
    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" \
        +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" \
        +"%Y-%m-%d")
    sed -i \
        "s/EXPIRED=.*/EXPIRED=${new_exp}/" \
        "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && \
        chage -E "$new_exp_date" \
            "$username" 2>/dev/null
    echo -e \
        "${GREEN}Renewed! Exp: ${new_exp}${NC}"
    sleep 3
}

list_accounts() {
    local protocol="$1"
    clear
    print_menu_header "${protocol^^} LIST"
    echo ""
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${RED}No accounts!${NC}"
        sleep 2; return
    fi
    echo -e "${CYAN}+------------------------------------------------------+${NC}"
    printf " %-20s %-18s %-8s %-6s\n" \
        "USERNAME" "EXPIRED" "QUOTA" "TYPE"
    echo -e "${CYAN}+------------------------------------------------------+${NC}"
    for f in "${files[@]}"; do
        local uname exp quota trial ttype
        uname=$(basename "$f" .txt | \
            sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f" \
            2>/dev/null | cut -d= -f2-)
        quota=$(grep "QUOTA" "$f" \
            2>/dev/null | cut -d= -f2)
        trial=$(grep "TRIAL" "$f" \
            2>/dev/null | cut -d= -f2)
        ttype="Member"
        [[ "$trial" == "1" ]] && ttype="Trial"
        printf " %-20s %-18s %-8s %-6s\n" \
            "$uname" "$exp" \
            "${quota:-N/A}GB" "$ttype"
    done
    echo -e "${CYAN}+------------------------------------------------------+${NC}"
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
        echo -e "${WHITE}Login count:${NC}"
        who 2>/dev/null | \
            awk '{print $1}' | \
            sort | uniq -c | sort -rn
    else
        echo -e "${WHITE}Xray ${protocol^^} log:${NC}"
        if [[ -f /var/log/xray/access.log ]];
        then
            grep -i "$protocol" \
                /var/log/xray/access.log \
                2>/dev/null | tail -20 || \
                echo "No data"
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
    echo -e " ${YELLOW}Cara mendapatkan Bot Token:${NC}"
    echo -e " 1. Buka Telegram cari ${WHITE}@BotFather${NC}"
    echo -e " 2. Ketik /newbot ikuti instruksi"
    echo -e " 3. Copy TOKEN yang diberikan"
    echo ""
    echo -e " ${YELLOW}Cara mendapatkan Chat ID:${NC}"
    echo -e " 1. Cari ${WHITE}@userinfobot${NC} di Telegram"
    echo -e " 2. Ketik /start lihat ID kamu"
    echo ""

    read -p " Bot Token     : " bot_token
    [[ -z "$bot_token" ]] && {
        echo -e "${RED}Token required!${NC}"
        sleep 2; return
    }
    read -p " Admin Chat ID : " admin_id
    [[ -z "$admin_id" ]] && {
        echo -e "${RED}Chat ID required!${NC}"
        sleep 2; return
    }

    echo -e "${CYAN}Testing token...${NC}"
    local test_result bot_name
    test_result=$(curl -s --max-time 10 \
        "https://api.telegram.org/bot${bot_token}/getMe")
    if ! echo "$test_result" | \
        grep -q '"ok":true'; then
        echo -e "${RED}Token tidak valid!${NC}"
        sleep 2; return
    fi
    bot_name=$(echo "$test_result" | \
        python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d['result']['username'])
" 2>/dev/null)
    echo -e "${GREEN}Bot valid! @${bot_name}${NC}"
    echo ""

    read -p " Nama Pemilik Rekening : " rek_name
    read -p " Nomor Rek/Dana/GoPay  : " rek_number
    read -p " Bank / E-Wallet       : " rek_bank
    read -p " Harga per Bulan (Rp)  : " harga
    [[ ! "$harga" =~ ^[0-9]+$ ]] && harga=10000

    echo "$bot_token" > "$BOT_TOKEN_FILE"
    echo "$admin_id"  > "$CHAT_ID_FILE"
    chmod 600 "$BOT_TOKEN_FILE" "$CHAT_ID_FILE"

    cat > "$PAYMENT_FILE" << PAYEOF
REK_NAME=${rek_name}
REK_NUMBER=${rek_number}
REK_BANK=${rek_bank}
HARGA=${harga}
PAYEOF
    chmod 600 "$PAYMENT_FILE"

    _install_bot_service

    sleep 2
    if systemctl is-active --quiet vpn-bot; then
        echo -e "${GREEN}Bot aktif! @${bot_name}${NC}"
        curl -s -X POST \
            "https://api.telegram.org/bot${bot_token}/sendMessage" \
            -d chat_id="$admin_id" \
            -d text="✅ Bot VPN Aktif! Domain: ${DOMAIN}" \
            -d parse_mode="HTML" \
            --max-time 10 >/dev/null 2>&1
    else
        echo -e "${RED}Bot gagal start!${NC}"
        journalctl -u vpn-bot -n 10 --no-pager
    fi
    echo ""
    read -p "Press any key to back on menu..."
}

_install_bot_service() {
    mkdir -p /root/bot "$ORDER_DIR"

    pip3 install requests \
        --break-system-packages \
        >/dev/null 2>&1 || \
        pip3 install requests >/dev/null 2>&1

    cat > /root/bot/bot.py << 'BOTEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Bot VPN Proffessor Squad
# Optimized: Fast response, no delay

import os, json, time, subprocess
import threading
from datetime import datetime, timedelta

try:
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
except ImportError:
    os.system(
        'pip3 install requests '
        '--break-system-packages -q'
    )
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry

# =====================
# CONFIG
# =====================
TOKEN    = open('/root/.bot_token').read().strip()
ADMIN_ID = int(open('/root/.chat_id').read().strip())
DOMAIN   = open('/root/domain').read().strip() \
           if os.path.exists('/root/domain') \
           else 'N/A'
ORDER_DIR = '/root/orders'
AKUN_DIR  = '/root/akun'
HTML_DIR  = '/var/www/html'
API       = f'https://api.telegram.org/bot{TOKEN}'

os.makedirs(ORDER_DIR, exist_ok=True)
os.makedirs(AKUN_DIR,  exist_ok=True)
os.makedirs(HTML_DIR,  exist_ok=True)

user_state = {}
state_lock = threading.Lock()

# =====================
# SESSION - Fast HTTP
# =====================
def make_session():
    s = requests.Session()
    retry = Retry(
        total=2,
        backoff_factor=0.3,
        status_forcelist=[500,502,503,504]
    )
    adapter = HTTPAdapter(
        max_retries=retry,
        pool_connections=20,
        pool_maxsize=50
    )
    s.mount('https://', adapter)
    s.mount('http://', adapter)
    return s

SESSION = make_session()

# =====================
# PAYMENT INFO
# =====================
def get_payment():
    info = {
        'REK_NAME'  : 'N/A',
        'REK_NUMBER': 'N/A',
        'REK_BANK'  : 'N/A',
        'HARGA'     : '10000'
    }
    try:
        with open('/root/.payment_info') as f:
            for line in f:
                line = line.strip()
                if '=' in line:
                    k, v = line.split('=', 1)
                    info[k.strip()] = v.strip()
    except:
        pass
    return info

# =====================
# TELEGRAM API - Fast
# =====================
def api_post(method, data, timeout=6):
    try:
        r = SESSION.post(
            f'{API}/{method}',
            data=data,
            timeout=timeout
        )
        return r.json()
    except Exception as e:
        print(f'API error {method}: {e}',
              flush=True)
        return {}

def send(chat_id, text,
         markup=None, parse_mode='HTML'):
    data = {
        'chat_id'   : chat_id,
        'text'      : text,
        'parse_mode': parse_mode
    }
    if markup:
        data['reply_markup'] = json.dumps(markup)
    return api_post('sendMessage', data)

def edit_msg(chat_id, msg_id, text,
             markup=None):
    data = {
        'chat_id'   : chat_id,
        'message_id': msg_id,
        'text'      : text,
        'parse_mode': 'HTML'
    }
    if markup:
        data['reply_markup'] = json.dumps(markup)
    return api_post('editMessageText', data)

def answer_cb(cb_id, text='', alert=False):
    api_post('answerCallbackQuery', {
        'callback_query_id': cb_id,
        'text'             : text,
        'show_alert'       : alert
    })

def get_updates(offset=0):
    try:
        r = SESSION.get(
            f'{API}/getUpdates',
            params={
                'offset' : offset,
                'timeout': 15,
                'limit'  : 100
            },
            timeout=20
        )
        return r.json().get('result', [])
    except:
        return []

# =====================
# KEYBOARDS
# =====================
def kb_main():
    return {
        'keyboard': [
            ['🆓 Trial Gratis', '🛒 Order VPN'],
            ['📋 Cek Akun Saya', 'ℹ️ Info Server'],
            ['❓ Bantuan', '📞 Hubungi Admin']
        ],
        'resize_keyboard'  : True,
        'one_time_keyboard': False
    }

def kb_trial():
    return {'inline_keyboard': [
        [
            {'text': '🔵 SSH',
             'callback_data': 'trial_ssh'},
            {'text': '🟢 VMess',
             'callback_data': 'trial_vmess'}
        ],
        [
            {'text': '🟡 VLess',
             'callback_data': 'trial_vless'},
            {'text': '🔴 Trojan',
             'callback_data': 'trial_trojan'}
        ],
        [
            {'text': '◀️ Kembali',
             'callback_data': 'back_main'}
        ]
    ]}

def kb_order():
    return {'inline_keyboard': [
        [
            {'text': '🔵 SSH',
             'callback_data': 'order_ssh'},
            {'text': '🟢 VMess',
             'callback_data': 'order_vmess'}
        ],
        [
            {'text': '🟡 VLess',
             'callback_data': 'order_vless'},
            {'text': '🔴 Trojan',
             'callback_data': 'order_trojan'}
        ],
        [
            {'text': '◀️ Kembali',
             'callback_data': 'back_main'}
        ]
    ]}

def kb_confirm(order_id):
    return {'inline_keyboard': [[
        {'text': '✅ Konfirmasi',
         'callback_data': f'confirm_{order_id}'},
        {'text': '❌ Tolak',
         'callback_data': f'reject_{order_id}'}
    ]]}

def kb_cancel():
    return {'inline_keyboard': [[
        {'text': '❌ Batalkan',
         'callback_data': 'cancel_order'}
    ]]}

# =====================
# UTILITIES
# =====================
def get_ip():
    for url in [
        'https://ifconfig.me',
        'https://ipinfo.io/ip',
        'https://api.ipify.org'
    ]:
        try:
            r = SESSION.get(url, timeout=3)
            if r.status_code == 200 \
               and r.text.strip():
                return r.text.strip()
        except:
            pass
    return 'N/A'

def run_cmd(cmd):
    try:
        r = subprocess.run(
            cmd, shell=True,
            capture_output=True,
            text=True, timeout=90
        )
        return r.stdout.strip()
    except Exception as e:
        print(f'CMD error: {e}', flush=True)
        return ''

def save_order(oid, data):
    with open(
        f'{ORDER_DIR}/{oid}.json', 'w'
    ) as f:
        json.dump(data, f, indent=2)

def load_order(oid):
    p = f'{ORDER_DIR}/{oid}.json'
    if not os.path.exists(p):
        return None
    with open(p) as f:
        return json.load(f)

def get_pending():
    orders = []
    if not os.path.exists(ORDER_DIR):
        return orders
    for fn in os.listdir(ORDER_DIR):
        if not fn.endswith('.json'):
            continue
        try:
            with open(
                f'{ORDER_DIR}/{fn}'
            ) as f:
                d = json.load(f)
            if d.get('status') == 'pending':
                orders.append(d)
        except:
            pass
    return orders

# =====================
# CREATE SSH - Fast
# =====================
def make_ssh(username, password, days=30):
    exp_date = (
        datetime.now() + timedelta(days=days)
    ).strftime('%Y-%m-%d')
    exp_str = (
        datetime.now() + timedelta(days=days)
    ).strftime('%d %b, %Y')
    created = datetime.now().strftime(
        '%d %b, %Y'
    )

    run_cmd(
        f'useradd -M -s /bin/false '
        f'-e {exp_date} {username} 2>/dev/null'
    )
    run_cmd(
        f'echo "{username}:{password}" | chpasswd'
    )

    content = (
        f'USERNAME={username}\n'
        f'PASSWORD={password}\n'
        f'IPLIMIT=1\n'
        f'EXPIRED={exp_str}\n'
        f'CREATED={created}\n'
    )
    with open(
        f'{AKUN_DIR}/ssh-{username}.txt', 'w'
    ) as f:
        f.write(content)

    ip = get_ip()
    with open(
        f'{HTML_DIR}/ssh-{username}.txt', 'w'
    ) as f:
        f.write(
f'''___________________________________________
  SSH Account
___________________________________________
 Username         : {username}
 Password         : {password}
 IP/Host          : {ip}
 Domain SSH       : {DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 SSH Ws Non SSL   : 80
 SSH Ws SSL       : 443
 BadVPN UDPGW     : 7100,7200,7300
 Format Hc        : {DOMAIN}:80@{username}:{password}
___________________________________________
 Save Link        : http://{ip}:81/ssh-{username}.txt
___________________________________________
 Payload          : GET / HTTP/1.1[crlf]Host: {DOMAIN}[crlf]Upgrade: ws[crlf][crlf]
___________________________________________
 Aktif Selama     : {days} Hari
 Dibuat Pada      : {created}
 Berakhir Pada    : {exp_str}
___________________________________________
''')
    return exp_str, ip

# =====================
# CREATE XRAY - Fast
# Port: TLS 443, NonTLS 80
# =====================
def make_xray(protocol, username,
              days=30, quota=100):
    import uuid as uuidlib, base64
    uid     = str(uuidlib.uuid4())
    exp_str = (
        datetime.now() + timedelta(days=days)
    ).strftime('%d %b, %Y')
    created = datetime.now().strftime(
        '%d %b, %Y'
    )
    cfg = '/usr/local/etc/xray/config.json'

    # Xray internal ports
    # 8443=TLS, 8080=NonTLS
    # User-facing: 443 (HAProxy), 80 (Nginx)

    if protocol == 'vmess':
        cmd = (
            f'jq --arg uuid "{uid}" '
            f'--arg email "{username}" '
            f"'(.inbounds[] | "
            f'select(.tag | startswith(\\"vmess\\"))'
            f'.settings.clients) += '
            f'[{{"id":$uuid,"email":$email,'
            f'"alterId":0}}]\' '
            f'{cfg} > /tmp/xr.json && '
            f'mv /tmp/xr.json {cfg}'
        )
    elif protocol == 'vless':
        cmd = (
            f'jq --arg uuid "{uid}" '
            f'--arg email "{username}" '
            f"'(.inbounds[] | "
            f'select(.tag | startswith(\\"vless\\"))'
            f'.settings.clients) += '
            f'[{{"id":$uuid,"email":$email}}]\' '
            f'{cfg} > /tmp/xr.json && '
            f'mv /tmp/xr.json {cfg}'
        )
    elif protocol == 'trojan':
        cmd = (
            f'jq --arg password "{uid}" '
            f'--arg email "{username}" '
            f"'(.inbounds[] | "
            f'select(.tag | startswith(\\"trojan\\"))'
            f'.settings.clients) += '
            f'[{{"password":$password,'
            f'"email":$email}}]\' '
            f'{cfg} > /tmp/xr.json && '
            f'mv /tmp/xr.json {cfg}'
        )

    run_cmd(cmd)
    run_cmd('chmod 644 '
            '/usr/local/etc/xray/config.json')
    run_cmd('systemctl restart xray')

    content = (
        f'UUID={uid}\n'
        f'QUOTA={quota}\n'
        f'IPLIMIT=1\n'
        f'EXPIRED={exp_str}\n'
        f'CREATED={created}\n'
    )
    with open(
        f'{AKUN_DIR}/{protocol}-{username}.txt',
        'w'
    ) as f:
        f.write(content)

    ip = get_ip()

    # Links - TLS 443, NonTLS 80
    if protocol == 'vmess':
        j_tls = (
            f'{{"v":"2","ps":"{username}",'
            f'"add":"bug.com","port":"443",'
            f'"id":"{uid}","aid":"0",'
            f'"net":"ws","path":"/{protocol}",'
            f'"type":"none","host":"{DOMAIN}",'
            f'"tls":"tls"}}'
        )
        link_tls = "vmess://" + \
            base64.b64encode(
                j_tls.encode()
            ).decode()

        j_ntls = (
            f'{{"v":"2","ps":"{username}",'
            f'"add":"bug.com","port":"80",'
            f'"id":"{uid}","aid":"0",'
            f'"net":"ws","path":"/{protocol}",'
            f'"type":"none","host":"{DOMAIN}",'
            f'"tls":"none"}}'
        )
        link_ntls = "vmess://" + \
            base64.b64encode(
                j_ntls.encode()
            ).decode()

        j_grpc = (
            f'{{"v":"2","ps":"{username}",'
            f'"add":"{DOMAIN}","port":"8444",'
            f'"id":"{uid}","aid":"0",'
            f'"net":"grpc",'
            f'"path":"{protocol}-grpc",'
            f'"type":"none","host":"bug.com",'
            f'"tls":"tls"}}'
        )
        link_grpc = "vmess://" + \
            base64.b64encode(
                j_grpc.encode()
            ).decode()

    elif protocol == 'vless':
        link_tls = (
            f"vless://{uid}@bug.com:443"
            f"?path=%2F{protocol}"
            f"&security=tls&encryption=none"
            f"&host={DOMAIN}&type=ws"
            f"&sni={DOMAIN}#{username}-TLS"
        )
        link_ntls = (
            f"vless://{uid}@bug.com:80"
            f"?path=%2F{protocol}"
            f"&security=none&encryption=none"
            f"&host={DOMAIN}&type=ws"
            f"#{username}-NonTLS"
        )
        link_grpc = (
            f"vless://{uid}@{DOMAIN}:8444"
            f"?mode=gun&security=tls"
            f"&encryption=none&type=grpc"
            f"&serviceName={protocol}-grpc"
            f"&sni=bug.com#{username}-gRPC"
        )

    elif protocol == 'trojan':
        link_tls = (
            f"trojan://{uid}@bug.com:443"
            f"?path=%2F{protocol}"
            f"&security=tls&host={DOMAIN}"
            f"&type=ws&sni={DOMAIN}"
            f"#{username}-TLS"
        )
        link_ntls = (
            f"trojan://{uid}@bug.com:80"
            f"?path=%2F{protocol}"
            f"&security=none&host={DOMAIN}"
            f"&type=ws#{username}-NonTLS"
        )
        link_grpc = (
            f"trojan://{uid}@{DOMAIN}:8444"
            f"?mode=gun&security=tls"
            f"&type=grpc"
            f"&serviceName={protocol}-grpc"
            f"&sni=bug.com#{username}-gRPC"
        )

    # Simpan file download
    with open(
        f'{HTML_DIR}/{protocol}-{username}.txt',
        'w'
    ) as f:
        f.write(
f'''___________________________________________
  {protocol.upper()} Account
___________________________________________
 Username         : {username}
 IP/Host          : {ip}
 Domain           : {DOMAIN}
 UUID             : {uid}
 Quota            : {quota} GB
 IP Limit         : 1 IP
___________________________________________
 Port TLS         : 443
 Port NonTLS      : 80
 Port gRPC        : 8444
 Network          : WebSocket / gRPC
 Path WS          : /{protocol}
 ServiceName gRPC : {protocol}-grpc
 TLS              : enabled
___________________________________________
 Link TLS         : {link_tls}
___________________________________________
 Link NonTLS      : {link_ntls}
___________________________________________
 Link gRPC        : {link_grpc}
___________________________________________
 Download         : http://{ip}:81/{protocol}-{username}.txt
___________________________________________
 Aktif Selama     : {days} Hari
 Dibuat Pada      : {created}
 Berakhir Pada    : {exp_str}
___________________________________________
''')

    return (uid, exp_str, ip,
            link_tls, link_ntls, link_grpc)

# =====================
# FORMAT OUTPUT MSG
# =====================
def fmt_ssh_msg(username, password,
                ip, exp_str, title,
                durasi="30 Hari"):
    return (
        f'✅ <b>{title}</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'👤 Username       : '
        f'<code>{username}</code>\n'
        f'🔑 Password       : '
        f'<code>{password}</code>\n'
        f'🖥️ IP/Host        : '
        f'<code>{ip}</code>\n'
        f'🌐 Domain SSH     : '
        f'<code>{DOMAIN}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔌 OpenSSH        : 22\n'
        f'🔌 Dropbear       : 222\n'
        f'🔌 Port SSH UDP   : 1-65535\n'
        f'🔌 SSL/TLS        : 443\n'
        f'🔌 SSH Ws Non SSL : 80\n'
        f'🔌 SSH Ws SSL     : 443\n'
        f'🔌 BadVPN UDPGW   : 7100,7200,7300\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'📋 Format Hc      : '
        f'{DOMAIN}:80@{username}:{password}\n'
        f'📦 Payload        : '
        f'GET / HTTP/1.1[crlf]'
        f'Host: {DOMAIN}[crlf]'
        f'Upgrade: ws[crlf][crlf]\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔗 Download       : '
        f'http://{ip}:81/ssh-{username}.txt\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'⏰ Aktif Selama   : {durasi}\n'
        f'📅 Berakhir Pada  : {exp_str}\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━'
    )

def fmt_xray_msg(protocol, username,
                 uid, ip, exp_str,
                 link_tls, link_ntls,
                 link_grpc, title,
                 durasi="30 Hari"):
    return (
        f'✅ <b>{title}</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'👤 Username        : '
        f'<code>{username}</code>\n'
        f'🔑 UUID            : '
        f'<code>{uid}</code>\n'
        f'🖥️ IP/Host         : '
        f'<code>{ip}</code>\n'
        f'🌐 Domain          : '
        f'<code>{DOMAIN}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔌 Port TLS        : 443\n'
        f'🔌 Port NonTLS     : 80\n'
        f'🔌 Port gRPC       : 8444\n'
        f'📂 Network         : WebSocket / gRPC\n'
        f'📂 Path WS         : /{protocol}\n'
        f'📂 ServiceName gRPC: {protocol}-grpc\n'
        f'🔒 TLS             : enabled\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔗 Link TLS:\n'
        f'<code>{link_tls}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔗 Link NonTLS:\n'
        f'<code>{link_ntls}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔗 Link gRPC:\n'
        f'<code>{link_grpc}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔗 Download        : '
        f'http://{ip}:81/{protocol}-{username}.txt\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'⏰ Aktif Selama    : {durasi}\n'
        f'📅 Berakhir Pada   : {exp_str}\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━'
    )

# =====================
# TRIAL - Fast
# =====================
def do_trial(protocol, chat_id):
    ts       = datetime.now().strftime('%H%M%S')
    username = f'trial-{ts}'
    ip       = get_ip()
    exp_1h   = (
        datetime.now() + timedelta(hours=1)
    ).strftime('%d %b %Y %H:%M')

    if protocol == 'ssh':
        password = '1'
        exp_date = (
            datetime.now() + timedelta(days=1)
        ).strftime('%Y-%m-%d')
        run_cmd(
            f'useradd -M -s /bin/false '
            f'-e {exp_date} {username} 2>/dev/null'
        )
        run_cmd(
            f'echo "{username}:{password}" | chpasswd'
        )
        # Auto delete background
        run_cmd(
            f'(sleep 3600; '
            f'userdel -f {username} 2>/dev/null; '
            f'rm -f {AKUN_DIR}/ssh-{username}.txt '
            f'{HTML_DIR}/ssh-{username}.txt) & disown'
        )
        msg = fmt_ssh_msg(
            username, password, ip, exp_1h,
            'Trial SSH Berhasil! 🆓',
            '1 Jam (Auto Hapus)'
        )
        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'
        send(chat_id, msg, markup=kb_main())

    else:
        try:
            uid, _, ip, \
            link_tls, link_ntls, \
            link_grpc = make_xray(
                protocol, username,
                days=1, quota=1
            )
        except Exception as e:
            send(chat_id,
                f'❌ Gagal buat akun: {e}')
            return

        # Auto delete background
        del_cmd = (
            f'(sleep 3600; '
            f'jq --arg email "{username}" '
            f"'del(.inbounds[].settings"
            f'.clients[]? | '
            f'select(.email == $email))\' '
            f'/usr/local/etc/xray/config.json'
            f' > /tmp/xd.json && '
            f'mv /tmp/xd.json '
            f'/usr/local/etc/xray/config.json; '
            f'chmod 644 '
            f'/usr/local/etc/xray/config.json; '
            f'systemctl restart xray; '
            f'rm -f '
            f'{AKUN_DIR}/{protocol}-{username}.txt '
            f'{HTML_DIR}/{protocol}-{username}.txt'
            f') & disown'
        )
        run_cmd(del_cmd)

        msg = fmt_xray_msg(
            protocol, username, uid, ip,
            exp_1h, link_tls, link_ntls,
            link_grpc,
            f'Trial {protocol.upper()} Berhasil! 🆓',
            '1 Jam (Auto Hapus)'
        )
        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'
        send(chat_id, msg, markup=kb_main())

# =====================
# FORMAT PAYMENT MSG
# =====================
def fmt_payment(order):
    pay   = get_payment()
    harga = int(pay.get('HARGA', 10000))
    return (
        f'🛒 <b>Detail Order</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🆔 Order ID   : '
        f'<code>{order["order_id"]}</code>\n'
        f'📦 Paket      : '
        f'{order["protocol"].upper()} 30 Hari\n'
        f'👤 Username   : '
        f'<code>{order["username"]}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'💰 <b>PEMBAYARAN</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🏦 {pay.get("REK_BANK", "N/A")}\n'
        f'📱 No: '
        f'<code>{pay.get("REK_NUMBER", "N/A")}</code>\n'
        f'👤 a/n: {pay.get("REK_NAME", "N/A")}\n'
        f'💵 Nominal: <b>Rp {harga:,}</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'📸 Langkah:\n'
        f'1. Transfer Rp {harga:,}\n'
        f'2. Screenshot bukti transfer\n'
        f'3. Kirim ke admin\n'
        f'4. Tunggu konfirmasi\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'⏳ Order berlaku 24 jam'
    )

# =====================
# DELIVER ACCOUNT
# =====================
def deliver_account(chat_id, protocol,
                    username):
    import random, string
    ip = get_ip()
    try:
        if protocol == 'ssh':
            password = ''.join(
                random.choices(
                    string.ascii_letters +
                    string.digits, k=8
                )
            )
            exp_str, ip = make_ssh(
                username, password, days=30
            )
            msg = fmt_ssh_msg(
                username, password, ip,
                exp_str,
                'Akun SSH Berhasil Dibuat! ✅'
            )
            msg += '\n💰 Terima kasih! 🙏'

        else:
            uid, exp_str, ip, \
            link_tls, link_ntls, \
            link_grpc = make_xray(
                protocol, username,
                days=30, quota=100
            )
            msg = fmt_xray_msg(
                protocol, username, uid, ip,
                exp_str, link_tls, link_ntls,
                link_grpc,
                f'Akun {protocol.upper()} '
                f'Berhasil! ✅'
            )
            msg += '\n💰 Terima kasih! 🙏'

        send(chat_id, msg, markup=kb_main())
        return True, msg

    except Exception as e:
        return False, str(e)

# =====================
# MESSAGE HANDLERS
# =====================
def on_start(msg):
    chat_id = msg['chat']['id']
    fname   = msg['from'].get(
        'first_name', 'User')
    pay   = get_payment()
    harga = int(pay.get('HARGA', 10000))
    send(chat_id,
        f'👋 Halo <b>{fname}</b>!\n\n'
        f'🤖 <b>Bot VPN Proffessor Squad</b>\n'
        f'🌐 Server: <code>{DOMAIN}</code>\n\n'
        f'<b>Menu:</b>\n'
        f'🆓 Trial Gratis → Akun 1 jam\n'
        f'🛒 Order VPN → 30 hari '
        f'Rp {harga:,}\n'
        f'📋 Cek Akun → Lihat akun aktif\n'
        f'ℹ️ Info Server → Port & domain\n'
        f'❓ Bantuan → Panduan lengkap\n\n'
        f'Pilih menu di bawah 👇',
        markup=kb_main()
    )

def on_help(msg):
    chat_id = msg['chat']['id']
    pay     = get_payment()
    harga   = int(pay.get('HARGA', 10000))
    send(chat_id,
        f'❓ <b>PANDUAN BOT VPN</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        f'🆓 <b>TRIAL (1 Jam)</b>\n'
        f'• Ketik 🆓 Trial Gratis\n'
        f'• Pilih SSH/VMess/VLess/Trojan\n'
        f'• Akun langsung dikirim\n'
        f'• Auto hapus setelah 1 jam\n\n'
        f'🛒 <b>ORDER (30 Hari)</b>\n'
        f'• Ketik 🛒 Order VPN\n'
        f'• Pilih protocol\n'
        f'• Masukkan username\n'
        f'• Transfer Rp {harga:,}\n'
        f'• Kirim bukti ke admin\n'
        f'• Akun dikirim setelah konfirmasi\n\n'
        f'💳 <b>PEMBAYARAN</b>\n'
        f'• Bank: {pay.get("REK_BANK","N/A")}\n'
        f'• No: {pay.get("REK_NUMBER","N/A")}\n'
        f'• a/n: {pay.get("REK_NAME","N/A")}\n'
        f'• Harga: Rp {harga:,}/bulan\n\n'
        f'📞 Masalah? Ketik 📞 Hubungi Admin\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━',
        markup=kb_main()
    )

def on_info(msg):
    chat_id = msg['chat']['id']
    ip      = get_ip()
    send(chat_id,
        f'ℹ️ <b>INFO SERVER</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🌐 Domain : <code>{DOMAIN}</code>\n'
        f'🖥️ IP VPS : <code>{ip}</code>\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔌 <b>Port SSH:</b>\n'
        f'   OpenSSH   : 22\n'
        f'   Dropbear  : 222\n'
        f'   SSL/TLS   : 443\n'
        f'   UDP       : 1-65535\n'
        f'   BadVPN    : 7100,7200,7300\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'🔌 <b>Port Xray:</b>\n'
        f'   TLS (WS)  : 443\n'
        f'   NonTLS    : 80\n'
        f'   gRPC TLS  : 8444\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'📂 <b>Path WS:</b>\n'
        f'   VMess     : /vmess\n'
        f'   VLess     : /vless\n'
        f'   Trojan    : /trojan\n'
        f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        f'📦 Download: http://{ip}:81/',
        markup=kb_main()
    )

def on_cek_akun(msg):
    chat_id = msg['chat']['id']
    found   = []
    if not os.path.exists(ORDER_DIR):
        send(chat_id,
            '📋 Tidak ada akun aktif.',
            markup=kb_main()
        )
        return
    for fn in os.listdir(ORDER_DIR):
        if not fn.endswith('.json'):
            continue
        try:
            with open(
                f'{ORDER_DIR}/{fn}'
            ) as f:
                order = json.load(f)
            if str(order.get('chat_id')) == \
               str(chat_id) and \
               order.get('status') == \
               'confirmed':
                proto = order.get('protocol','')
                uname = order.get('username','')
                af = (
                    f'{AKUN_DIR}/'
                    f'{proto}-{uname}.txt'
                )
                if os.path.exists(af):
                    exp = ''
                    with open(af) as a:
                        for line in a:
                            if 'EXPIRED=' \
                               in line:
                                exp = line\
                                    .split('=',1)\
                                    [1].strip()
                    found.append({
                        'protocol': proto,
                        'username': uname,
                        'expired' : exp
                    })
        except:
            pass
    if not found:
        send(chat_id,
            f'📋 <b>Akun Kamu</b>\n\n'
            f'❌ Tidak ada akun aktif.\n\n'
            f'Gunakan 🛒 Order VPN '
            f'untuk membeli.',
            markup=kb_main()
        )
        return
    text = '📋 <b>Akun Aktif Kamu</b>\n'
    text += '━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    for a in found:
        text += (
            f'📦 {a["protocol"].upper()}\n'
            f'   👤 {a["username"]}\n'
            f'   📅 {a["expired"]}\n\n'
        )
    send(chat_id, text, markup=kb_main())

def on_contact(msg):
    chat_id = msg['chat']['id']
    fname   = msg['from'].get(
        'first_name', 'User')
    uname   = msg['from'].get('username', '')
    send(chat_id,
        f'📞 Pesan diteruskan ke admin.\n'
        f'Tunggu balasan ya! ⏰ < 30 menit',
        markup=kb_main()
    )
    send(ADMIN_ID,
        f'📞 <b>User butuh bantuan!</b>\n'
        f'👤 Nama   : {fname}\n'
        f'📱 TG     : @{uname}\n'
        f'🆔 Chat ID: <code>{chat_id}</code>'
    )

# =====================
# CALLBACK HANDLER
# =====================
def on_callback(cb):
    chat_id = cb['message']['chat']['id']
    msg_id  = cb['message']['message_id']
    cb_id   = cb['id']
    data    = cb['data']
    uname   = cb['from'].get('username', '')
    fname   = cb['from'].get(
        'first_name', 'User')

    # Answer callback immediately
    answer_cb(cb_id)

    if data.startswith('trial_'):
        protocol = data.replace('trial_', '')
        send(chat_id,
            f'⏳ Membuat trial '
            f'{protocol.upper()}...'
        )
        threading.Thread(
            target=do_trial,
            args=(protocol, chat_id),
            daemon=True
        ).start()

    elif data.startswith('order_'):
        protocol = data.replace('order_', '')
        pay   = get_payment()
        harga = int(pay.get('HARGA', 10000))
        with state_lock:
            user_state[chat_id] = {
                'step'    : 'wait_username',
                'protocol': protocol
            }
        send(chat_id,
            f'🛒 <b>Order '
            f'{protocol.upper()} 30 Hari</b>\n'
            f'💰 Harga: <b>Rp {harga:,}</b>\n\n'
            f'✏️ Ketik username:\n'
            f'<i>(3-20 karakter, '
            f'huruf & angka)\n'
            f'Contoh: budi123</i>',
            markup=kb_cancel()
        )

    elif data == 'cancel_order':
        with state_lock:
            user_state.pop(chat_id, None)
        send(chat_id,
            '❌ Order dibatalkan.',
            markup=kb_main()
        )

    elif data == 'back_main':
        send(chat_id,
            '🏠 Menu Utama',
            markup=kb_main()
        )

    elif data.startswith('confirm_') and \
         chat_id == ADMIN_ID:
        oid   = data.replace('confirm_', '')
        order = load_order(oid)
        if not order:
            send(ADMIN_ID, '❌ Order tidak ada!')
            return
        if order.get('status') != 'pending':
            send(ADMIN_ID, '⚠️ Sudah diproses!')
            return
        send(ADMIN_ID, '⏳ Membuat akun...')

        def do_confirm():
            ok, result = deliver_account(
                order['chat_id'],
                order['protocol'],
                order['username']
            )
            if ok:
                order['status'] = 'confirmed'
                save_order(oid, order)
                send(ADMIN_ID,
                    f'✅ Akun '
                    f'{order["protocol"].upper()}'
                    f' <code>'
                    f'{order["username"]}'
                    f'</code> dikirim ke '
                    f'@{order.get("tg_user","?")}'
                )
            else:
                send(ADMIN_ID,
                    f'❌ Gagal: {result}'
                )

        threading.Thread(
            target=do_confirm,
            daemon=True
        ).start()

    elif data.startswith('reject_') and \
         chat_id == ADMIN_ID:
        oid   = data.replace('reject_', '')
        order = load_order(oid)
        if not order:
            send(ADMIN_ID, '❌ Tidak ada!')
            return
        order['status'] = 'rejected'
        save_order(oid, order)
        send(order['chat_id'],
            f'❌ <b>Order Ditolak</b>\n'
            f'ID: <code>{oid}</code>\n\n'
            f'Hubungi admin untuk info.',
            markup=kb_main()
        )
        send(ADMIN_ID,
            f'❌ Order <code>{oid}</code> '
            f'ditolak.'
        )

# =====================
# MESSAGE ROUTER
# =====================
def on_msg(msg):
    if 'text' not in msg:
        return
    chat_id = msg['chat']['id']
    text    = msg['text'].strip()
    uname   = msg['from'].get('username', '')
    fname   = msg['from'].get(
        'first_name', 'User')

    with state_lock:
        state = user_state.get(chat_id, {})

    if state.get('step') == 'wait_username':
        new_u = text.strip().replace(' ', '_')
        if len(new_u) < 3 or len(new_u) > 20:
            send(chat_id,
                '❌ Username 3-20 karakter!\n'
                'Coba lagi:',
                markup=kb_cancel()
            )
            return

        protocol = state['protocol']
        oid      = (
            f'{chat_id}_{int(time.time())}'
        )
        order = {
            'order_id'  : oid,
            'chat_id'   : chat_id,
            'username'  : new_u,
            'protocol'  : protocol,
            'status'    : 'pending',
            'created_at': datetime.now()
                .isoformat(),
            'tg_user'   : uname,
            'tg_name'   : fname
        }
        save_order(oid, order)

        with state_lock:
            user_state.pop(chat_id, None)

        send(chat_id, fmt_payment(order))

        pay   = get_payment()
        harga = int(pay.get('HARGA', 10000))
        send(ADMIN_ID,
            f'🔔 <b>ORDER BARU!</b>\n'
            f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
            f'🆔 ID       : '
            f'<code>{oid}</code>\n'
            f'📦 Paket    : '
            f'{protocol.upper()} 30 Hari\n'
            f'👤 Username : '
            f'<code>{new_u}</code>\n'
            f'📱 TG User  : @{uname}\n'
            f'💰 Harga    : Rp {harga:,}\n'
            f'━━━━━━━━━━━━━━━━━━━━━━━━━\n'
            f'⏳ Tunggu bukti bayar.',
            markup=kb_confirm(oid)
        )
        return

    # Menu routing
    if text in ['/start', '🏠 Menu']:
        on_start(msg)
    elif text in ['/help', '❓ Bantuan']:
        on_help(msg)
    elif text == '🆓 Trial Gratis':
        send(chat_id,
            f'🆓 <b>Trial Gratis 1 Jam</b>\n\n'
            f'Pilih protocol:\n'
            f'<i>Auto hapus setelah 1 jam</i>',
            markup=kb_trial()
        )
    elif text == '🛒 Order VPN':
        pay   = get_payment()
        harga = int(pay.get('HARGA', 10000))
        send(chat_id,
            f'🛒 <b>Order VPN 30 Hari</b>\n'
            f'💰 Harga: <b>Rp {harga:,}</b>\n\n'
            f'Pilih protocol:',
            markup=kb_order()
        )
    elif text == '📋 Cek Akun Saya':
        on_cek_akun(msg)
    elif text == 'ℹ️ Info Server':
        on_info(msg)
    elif text == '📞 Hubungi Admin':
        on_contact(msg)
    elif text == '/orders' and \
         chat_id == ADMIN_ID:
        orders = get_pending()
        if not orders:
            send(ADMIN_ID,
                '📭 Tidak ada pending.')
            return
        pay   = get_payment()
        harga = int(pay.get('HARGA', 10000))
        for o in orders[:5]:
            send(ADMIN_ID,
                f'🔔 <b>PENDING</b>\n'
                f'ID: <code>{o["order_id"]}</code>\n'
                f'Paket: {o["protocol"].upper()}\n'
                f'User: <code>{o["username"]}</code>\n'
                f'TG: @{o.get("tg_user","N/A")}\n'
                f'Harga: Rp {harga:,}',
                markup=kb_confirm(o['order_id'])
            )
    elif text.startswith('/konfirm ') and \
         chat_id == ADMIN_ID:
        oid   = text.split(' ', 1)[1].strip()
        order = load_order(oid)
        if order:
            send(ADMIN_ID,
                f'Order: <code>{oid}</code>',
                markup=kb_confirm(oid)
            )
        else:
            send(ADMIN_ID, '❌ Tidak ditemukan.')

# =====================
# MAIN LOOP - Fast
# =====================
def main():
    print(f'Bot VPN v1.0 - Admin: {ADMIN_ID}',
          flush=True)
    offset    = 0
    max_workers = 20
    pool = []

    while True:
        try:
            updates = get_updates(offset)
            for upd in updates:
                offset = upd['update_id'] + 1
                t = None
                if 'message' in upd:
                    t = threading.Thread(
                        target=on_msg,
                        args=(upd['message'],),
                        daemon=True
                    )
                elif 'callback_query' in upd:
                    t = threading.Thread(
                        target=on_callback,
                        args=(
                            upd['callback_query'],
                        ),
                        daemon=True
                    )
                if t:
                    t.start()
                    pool.append(t)

            # Cleanup dead threads
            pool = [
                x for x in pool if x.is_alive()
            ]

        except KeyboardInterrupt:
            print('Bot stopped.', flush=True)
            break
        except Exception as e:
            print(f'Loop error: {e}', flush=True)
            time.sleep(2)

if __name__ == '__main__':
    main()
BOTEOF

    chmod +x /root/bot/bot.py

    cat > /etc/systemd/system/vpn-bot.service \
        << 'SVCEOF'
[Unit]
Description=VPN Bot Proffessor Squad
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -u /root/bot/bot.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable vpn-bot 2>/dev/null
    systemctl restart vpn-bot 2>/dev/null
    sleep 2
}

#================================================
# MENU TELEGRAM BOT
#================================================

menu_telegram_bot() {
    while true; do
        clear
        print_menu_header "TELEGRAM BOT"
        local bs
        bs=$(check_status vpn-bot)
        local cs
        [[ "$bs" == "ON" ]] && \
            cs="${GREEN}RUNNING${NC}" || \
            cs="${RED}STOPPED${NC}"
        echo -e "  Status: ${cs}"
        echo ""
        echo -e "     ${WHITE}[1]${NC} Setup Bot"
        echo -e "     ${WHITE}[2]${NC} Start Bot"
        echo -e "     ${WHITE}[3]${NC} Stop Bot"
        echo -e "     ${WHITE}[4]${NC} Restart Bot"
        echo -e "     ${WHITE}[5]${NC} Lihat Log"
        echo -e "     ${WHITE}[6]${NC} Order Pending"
        echo -e "     ${WHITE}[7]${NC} Info Bot"
        echo -e "     ${WHITE}[0]${NC} Back To Menu"
        print_menu_footer
        echo ""
        read -p "Select: " choice
        case $choice in
            1) setup_telegram_bot ;;
            2)
                systemctl start vpn-bot
                echo -e "${GREEN}Started!${NC}"
                sleep 2
                ;;
            3)
                systemctl stop vpn-bot
                echo -e "${YELLOW}Stopped!${NC}"
                sleep 2
                ;;
            4)
                systemctl restart vpn-bot
                echo -e "${GREEN}Restarted!${NC}"
                sleep 2
                ;;
            5)
                clear
                journalctl -u vpn-bot \
                    -n 50 --no-pager
                echo ""
                read -p "Press any key..."
                ;;
            6)
                clear
                print_menu_header "ORDER PENDING"
                echo ""
                local found=0
                shopt -s nullglob
                for f in "$ORDER_DIR"/*.json; do
                    [[ ! -f "$f" ]] && continue
                    local st
                    st=$(python3 -c "
import json
try:
    d=json.load(open('$f'))
    print(d.get('status',''))
except:
    print('')
" 2>/dev/null)
                    if [[ "$st" == "pending" ]];
                    then
                        found=1
                        python3 -c "
import json
d=json.load(open('$f'))
print(f'Order ID : {d[\"order_id\"]}')
print(f'Protocol : {d[\"protocol\"].upper()}')
print(f'Username : {d[\"username\"]}')
print(f'TG User  : @{d.get(\"tg_user\",\"N/A\")}')
print(f'Status   : {d[\"status\"]}')
print('---')
" 2>/dev/null
                    fi
                done
                shopt -u nullglob
                [[ $found -eq 0 ]] && \
                    echo -e \
                    "${GREEN}Tidak ada pending!${NC}"
                echo ""
                read -p "Press any key..."
                ;;
            7)
                clear
                print_menu_header "BOT INFO"
                echo ""
                if [[ -f "$BOT_TOKEN_FILE" ]];
                then
                    local aid
                    aid=$(cat "$CHAT_ID_FILE" \
                        2>/dev/null)
                    printf " %-16s : %s\n" \
                        "Status"   "$bs"
                    printf " %-16s : %s\n" \
                        "Admin ID" "$aid"
                    if [[ -f "$PAYMENT_FILE" ]];
                    then
                        source "$PAYMENT_FILE"
                        echo ""
                        printf " %-16s : %s\n" \
                            "Bank"     "$REK_BANK"
                        printf " %-16s : %s\n" \
                            "No Rek"   "$REK_NUMBER"
                        printf " %-16s : %s\n" \
                            "Atas Nama" "$REK_NAME"
                        printf " %-16s : Rp %s\n" \
                            "Harga"    "$HARGA"
                    fi
                else
                    echo -e \
                    "${RED}Bot belum setup!${NC}"
                fi
                echo ""
                read -p "Press any key..."
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
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "${RED}Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"
        sleep 2; return
    }
    read -p " Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vmess" "$username" \
        "$days" "$quota" "$iplimit"
}

create_vless() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE VLESS ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "${RED}Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"
        sleep 2; return
    }
    read -p " Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vless" "$username" \
        "$days" "$quota" "$iplimit"
}

create_trojan() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}CREATE TROJAN ACCOUNT${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "${RED}Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid!${NC}"
        sleep 2; return
    }
    read -p " Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "trojan" "$username" \
        "$days" "$quota" "$iplimit"
}

#================================================
# MENU SSH
#================================================

menu_ssh() {
    while true; do
        clear
        print_menu_header "SSH MENU"
        echo -e "     ${WHITE}[1]${NC} Create SSH"
        echo -e "     ${WHITE}[2]${NC} Trial SSH (1 Jam)"
        echo -e "     ${WHITE}[3]${NC} Delete SSH"
        echo -e "     ${WHITE}[4]${NC} Renew SSH"
        echo -e "     ${WHITE}[5]${NC} Cek Login SSH"
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
        echo -e "     ${WHITE}[1]${NC} Create VMess"
        echo -e "     ${WHITE}[2]${NC} Trial VMess (1 Jam)"
        echo -e "     ${WHITE}[3]${NC} Delete VMess"
        echo -e "     ${WHITE}[4]${NC} Renew VMess"
        echo -e "     ${WHITE}[5]${NC} Cek Login VMess"
        echo -e "     ${WHITE}[6]${NC} List User VMess"
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
        echo -e "     ${WHITE}[1]${NC} Create VLess"
        echo -e "     ${WHITE}[2]${NC} Trial VLess (1 Jam)"
        echo -e "     ${WHITE}[3]${NC} Delete VLess"
        echo -e "     ${WHITE}[4]${NC} Renew VLess"
        echo -e "     ${WHITE}[5]${NC} Cek Login VLess"
        echo -e "     ${WHITE}[6]${NC} List User VLess"
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

#================================================
# MENU TROJAN
#================================================

menu_trojan() {
    while true; do
        clear
        print_menu_header "TROJAN MENU"
        echo -e "     ${WHITE}[1]${NC} Create Trojan"
        echo -e "     ${WHITE}[2]${NC} Trial Trojan (1 Jam)"
        echo -e "     ${WHITE}[3]${NC} Delete Trojan"
        echo -e "     ${WHITE}[4]${NC} Renew Trojan"
        echo -e "     ${WHITE}[5]${NC} Cek Login Trojan"
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
# MENU UPDATE
#================================================

menu_update() {
    while true; do
        clear
        print_menu_header "UPDATE / ROLLBACK"
        echo -e "     ${WHITE}[1]${NC} Check & Update"
        echo -e "     ${WHITE}[2]${NC} Rollback"
        echo -e "     ${WHITE}[3]${NC} Info Versi"
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
                printf " %-16s : %s\n" \
                    "Version" "$SCRIPT_VERSION"
                printf " %-16s : %s\n" \
                    "Author"  "$SCRIPT_AUTHOR"
                printf " %-16s : %s\n" \
                    "GitHub" \
                    "${GITHUB_USER}/${GITHUB_REPO}"
                printf " %-16s : %s\n" \
                    "Branch"  "$GITHUB_BRANCH"
                echo ""
                read -p "Press any key..."
                ;;
            0) return ;;
        esac
    done
}

#================================================
# INSTALL UDP CUSTOM
#================================================

install_udp_custom() {
    clear
    echo -e "${CYAN}+=========================================+${NC}"
    echo -e "${CYAN}|${NC}  ${WHITE}INSTALL UDP CUSTOM (7100-7300)${NC}"
    echo -e "${CYAN}+=========================================+${NC}"
    echo ""

    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select, time

PORTS      = range(7100, 7301)
SSH_HOST   = '127.0.0.1'
SSH_PORT   = 22
BUF        = 8192
TIMEOUT    = 10

def handle(data, addr, sock):
    try:
        s = socket.socket(
            socket.AF_INET,
            socket.SOCK_STREAM
        )
        s.settimeout(TIMEOUT)
        s.connect((SSH_HOST, SSH_PORT))
        s.sendall(data)
        resp = s.recv(BUF)
        if resp:
            sock.sendto(resp, addr)
        s.close()
    except:
        pass

sockets = []
for port in PORTS:
    try:
        s = socket.socket(
            socket.AF_INET,
            socket.SOCK_DGRAM
        )
        s.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_REUSEADDR, 1
        )
        s.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_RCVBUF, 1048576
        )
        s.setsockopt(
            socket.SOL_SOCKET,
            socket.SO_SNDBUF, 1048576
        )
        s.bind(('0.0.0.0', port))
        s.setblocking(False)
        sockets.append(s)
    except:
        pass

print(
    f'UDP Custom: {len(sockets)} ports '
    f'(7100-7300)',
    flush=True
)

while True:
    try:
        readable, _, _ = select.select(
            sockets, [], [], 1.0
        )
        for sock in readable:
            try:
                data, addr = \
                    sock.recvfrom(BUF)
                threading.Thread(
                    target=handle,
                    args=(data, addr, sock),
                    daemon=True
                ).start()
            except:
                pass
    except KeyboardInterrupt:
        break
    except:
        time.sleep(1)
UDPEOF

    chmod +x /usr/local/bin/udp-custom

    cat > \
        /etc/systemd/system/udp-custom.service \
        << 'UDPSVC'
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
UDPSVC

    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom
    sleep 1

    if systemctl is-active \
        --quiet udp-custom; then
        echo -e \
        "${GREEN}UDP OK! (7100-7300)${NC}"
    else
        echo -e "${RED}UDP Failed!${NC}"
        journalctl -u udp-custom \
            -n 5 --no-pager
    fi
    sleep 2
}
#================================================
# AUTO INSTALL
#================================================

auto_install() {
    show_install_banner

    setup_domain
    [[ -z "$DOMAIN" ]] && {
        echo -e "${RED}Domain kosong!${NC}"
        exit 1
    }

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && \
        domain_type=$(cat "$DOMAIN_TYPE_FILE")

    echo ""
    echo -e " Domain   : ${GREEN}${DOMAIN}${NC}"
    echo -e " SSL Type : ${GREEN}$(
        [[ "$domain_type" == "custom" ]] && \
        echo "Let's Encrypt" || \
        echo "Self-Signed"
    )${NC}"
    echo ""
    sleep 2

    local total=10
    local step=0

    # ─── Step 1 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Installing packages..."
    DEBIAN_FRONTEND=noninteractive \
    apt-get update -y >/dev/null 2>&1
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        curl wget jq qrencode unzip \
        uuid-runtime nginx openssh-server \
        dropbear certbot python3 python3-pip \
        net-tools haproxy netcat-openbsd \
        openssl iptables-persistent \
        >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        done_msg "Packages installed"
    else
        fail_msg "Some packages failed"
    fi

    # ─── Step 2 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Installing Xray..."
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        >/dev/null 2>&1
    mkdir -p "$AKUN_DIR" /var/log/xray \
             /usr/local/etc/xray \
             "$PUBLIC_HTML" \
             "$ORDER_DIR" /root/bot
    if command -v xray >/dev/null 2>&1; then
        done_msg "Xray installed"
    else
        fail_msg "Xray install failed"
    fi

    # ─── Step 3 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Setting up Swap 1GB..."
    if [[ $(free -m | \
        awk 'NR==3{print $2}') -lt 512 ]]; then
        fallocate -l 1G /swapfile \
            2>/dev/null || \
            dd if=/dev/zero of=/swapfile \
               bs=1M count=1024 \
               2>/dev/null
        chmod 600 /swapfile
        mkswap /swapfile >/dev/null 2>&1
        swapon /swapfile
        grep -q "/swapfile" /etc/fstab || \
            echo \
            "/swapfile none swap sw 0 0" \
            >> /etc/fstab
        done_msg "Swap 1GB created"
    else
        info_msg "Swap already exists, skip"
    fi

    # ─── Step 4 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Getting SSL certificate..."
    get_ssl_cert
    if [[ -f /etc/xray/xray.crt ]]; then
        done_msg "SSL certificate ready"
    else
        fail_msg "SSL cert failed"
    fi

    # ─── Step 5 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Creating Xray config..."
    create_xray_config
    if [[ -f "$XRAY_CONFIG" ]]; then
        done_msg "Xray config created"
    else
        fail_msg "Xray config failed"
    fi

    # ─── Step 6 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Configuring Nginx..."
    cat > /etc/nginx/sites-available/default \
        << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
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
        add_header Content-Type text/plain;
    }
}
NGXEOF
    rm -f /etc/nginx/sites-enabled/default
    ln -sf \
        /etc/nginx/sites-available/default \
        /etc/nginx/sites-enabled/default
    if nginx -t >/dev/null 2>&1; then
        done_msg "Nginx configured"
    else
        fail_msg "Nginx config error"
    fi

    # ─── Step 7 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Configuring Dropbear..."
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    done_msg "Dropbear configured"

    # ─── Step 8 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Configuring HAProxy..."
    configure_haproxy
    if haproxy -c -f \
        /etc/haproxy/haproxy.cfg \
        >/dev/null 2>&1; then
        done_msg "HAProxy configured"
    else
        fail_msg "HAProxy config error"
    fi

    # ─── Step 9 ───────────────────────────────
    ((step++))
    show_progress $step $total \
        "Setup UDP, Keepalive & Optimize..."
    install_udp_custom >/dev/null 2>&1
    setup_keepalive    >/dev/null 2>&1
    optimize_vpn       >/dev/null 2>&1
    sed -i 's/^#\?Port.*/Port 22/' \
        /etc/ssh/sshd_config 2>/dev/null
    pip3 install requests \
        --break-system-packages \
        >/dev/null 2>&1 || \
        pip3 install requests \
        >/dev/null 2>&1
    done_msg "Optimization done"

    # ─── Step 10 ──────────────────────────────
    ((step++))
    show_progress $step $total \
        "Starting all services..."
    echo ""
    systemctl daemon-reload
    for svc in xray nginx sshd dropbear \
               haproxy udp-custom \
               vpn-keepalive; do
        systemctl enable  "$svc" 2>/dev/null
        systemctl restart "$svc" 2>/dev/null
        if systemctl is-active \
            --quiet "$svc"; then
            done_msg "$svc"
        else
            fail_msg "$svc"
        fi
    done

    setup_menu_command

    local ip_vps
    ip_vps=$(get_ip)

    # Index HTML
    cat > "$PUBLIC_HTML/index.html" \
        << IDXEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>${DOMAIN}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;
     background:#0a0a1a;color:#eee;
     display:flex;align-items:center;
     justify-content:center;
     min-height:100vh;text-align:center}
.box{padding:40px;background:#111;
     border:1px solid #00d4ff33;
     border-radius:12px;max-width:500px}
h1{color:#00d4ff;margin-bottom:10px}
p{color:#888;margin:5px 0}
.badge{display:inline-block;
       background:#00d4ff22;color:#00d4ff;
       padding:4px 12px;border-radius:20px;
       margin-top:15px;font-size:13px}
</style>
</head>
<body>
<div class="box">
<h1>VPN Server</h1>
<p>${DOMAIN}</p>
<p>${ip_vps}</p>
<div class="badge">Proffessor Squad</div>
</div>
</body>
</html>
IDXEOF

    # ─── Done ─────────────────────────────────
    echo ""
    echo -e "${GREEN}+=========================================+${NC}"
    echo -e "${GREEN}|     ✓  Installation Complete!           |${NC}"
    echo -e "${GREEN}+=========================================+${NC}"
    echo ""
    printf " %-20s : %s\n" \
        "Domain"    "$DOMAIN"
    printf " %-20s : %s\n" \
        "IP VPS"    "$ip_vps"
    printf " %-20s : %s\n" \
        "SSL"       "$([[ "$domain_type" \
        == "custom" ]] && \
        echo "Let's Encrypt" || \
        echo "Self-Signed")"
    echo ""
    printf " %-20s : %s\n" \
        "SSH"       "22"
    printf " %-20s : %s\n" \
        "Dropbear"  "222"
    printf " %-20s : %s\n" \
        "Xray TLS"  "443 (HAProxy → 8443)"
    printf " %-20s : %s\n" \
        "Xray NonTLS" "80 (Nginx → 8080)"
    printf " %-20s : %s\n" \
        "Xray gRPC" "8444"
    printf " %-20s : %s\n" \
        "BadVPN UDP" "7100-7300"
    printf " %-20s : %s\n" \
        "Download"  "http://${ip_vps}:81/"
    echo ""
    echo -e "${YELLOW}💡 Ketik 'menu' untuk membuka menu!${NC}"
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
        read -p \
            "Options [ 00 - 18 ] >>> " choice

        case $choice in
            1|01) menu_ssh ;;
            2|02) menu_vmess ;;
            3|03) menu_vless ;;
            4|04) menu_trojan ;;
            5|05) cek_expired ;;
            6|06) delete_expired ;;
            7|07) setup_swap ;;
            8|08)
                clear
                optimize_vpn
                echo -e "${GREEN}Optimization done!${NC}"
                sleep 2
                ;;
            9|09)
                clear
                echo -e "${CYAN}Restarting all services...${NC}"
                echo ""
                for svc in xray nginx sshd \
                           dropbear haproxy \
                           udp-custom \
                           vpn-keepalive \
                           vpn-bot; do
                    if systemctl restart \
                        "$svc" 2>/dev/null; then
                        printf \
                        " ${GREEN}+${NC} %-20s ${GREEN}[OK]${NC}\n"\
                        "$svc"
                    else
                        printf \
                        " ${RED}x${NC} %-20s ${RED}[SKIP]${NC}\n"\
                        "$svc"
                    fi
                done
                echo ""
                sleep 2
                ;;
            10)
                clear
                echo -e "${CYAN}+=========================================+${NC}"
                echo -e "${CYAN}|${NC}  ${WHITE}SERVICE & PORT STATUS${NC}"
                echo -e "${CYAN}+=========================================+${NC}"
                echo ""
                for svc in xray nginx sshd \
                           dropbear haproxy \
                           udp-custom \
                           vpn-keepalive \
                           vpn-bot; do
                    if systemctl is-active \
                        --quiet "$svc"; then
                        printf \
                        " ${GREEN}+${NC} %-20s ${GREEN}[RUNNING]${NC}\n"\
                        "$svc"
                    else
                        printf \
                        " ${RED}x${NC} %-20s ${RED}[STOPPED]${NC}\n"\
                        "$svc"
                    fi
                done
                echo ""
                echo -e "${CYAN}+=========================================+${NC}"
                echo -e " ${WHITE}Active Ports:${NC}"
                echo -e "${CYAN}+=========================================+${NC}"
                ss -tulpn 2>/dev/null | \
                    grep -E \
                    ':22 |:80 |:81 |:222 |:443 |:8080 |:8443 |:8444 ' | \
                    awk '{printf " + %-6s %s\n",
                        $1,$5}'
                echo ""
                read -p "Press any key..."
                ;;
            11) show_info_port ;;
            12) install_udp_custom ;;
            13) menu_telegram_bot ;;
            14) change_domain ;;
            15) fix_certificate ;;
            16) menu_update ;;
            17) run_speedtest ;;
            18) menu_uninstall ;;
            0|00)
                clear
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

# Harus root
[[ $EUID -ne 0 ]] && {
    echo -e "${RED}Run as root!${NC}"
    echo "sudo bash $0"
    exit 1
}

# Load domain
[[ -f "$DOMAIN_FILE" ]] && \
    DOMAIN=$(tr -d '\n\r' \
        < "$DOMAIN_FILE" | xargs)

# First time install
if [[ ! -f "$DOMAIN_FILE" ]]; then
    auto_install
fi

# Setup menu command
setup_menu_command

# Run main menu
main_menu
