#!/bin/bash

#================================================
# Auto Script VPN Server v2.0
# By The Proffessor Squad
# GitHub: putrinuroktavia234-max/Tunnel
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
SCRIPT_VERSION="2.0.0"
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
EXPIRY_FILE="/root/.script_expiry"

#================================================
# PORT VARIABLES
#================================================
SSH_PORT="22"
DROPBEAR_PORT="222"
NGINX_PORT="80"
NGINX_DL_PORT="81"
HAPROXY_PORT="443"
XRAY_INTERNAL_TLS="8443"
XRAY_WS_NONTLS_PORT="8080"
XRAY_GRPC_PORT="8444"
BADVPN_RANGE="7100-7300"
PRICE_MONTHLY="10000"
DURATION_MONTHLY="30"

# Lebar kotak tetap 66 karakter (isi dalam)
W=66

#================================================
# SCRIPT EXPIRY SYSTEM
#================================================

setup_expiry() {
    local days="${1:-30}"
    local exp_ts=$(( $(date +%s) + days * 86400 ))
    local exp_str=$(date -d "@${exp_ts}" +"%Y-%m-%d")
    echo "${exp_ts}|${exp_str}|${days}" > "$EXPIRY_FILE"
    chmod 600 "$EXPIRY_FILE"
}

check_expiry() {
    [[ ! -f "$EXPIRY_FILE" ]] && {
        # Jika file expiry belum ada, buat dengan 30 hari
        setup_expiry 30
        return 0
    }
    local data exp_ts now
    data=$(cat "$EXPIRY_FILE")
    exp_ts=$(echo "$data" | cut -d'|' -f1)
    now=$(date +%s)
    if [[ "$now" -gt "$exp_ts" ]]; then
        clear
        local exp_str=$(echo "$data" | cut -d'|' -f2)
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    !! SCRIPT EXPIRED !!                         ║${NC}"
        echo -e "${RED}╠══════════════════════════════════════════════════════════════════╣${NC}"
        printf "${RED}║${NC}  %-64s${RED}║${NC}\n" "Script ini sudah kadaluarsa pada: ${exp_str}"
        printf "${RED}║${NC}  %-64s${RED}║${NC}\n" "Silahkan hubungi admin untuk perpanjangan."
        printf "${RED}║${NC}  %-64s${RED}║${NC}\n" "Kontak: @ridhani16"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
    local sisa=$(( (exp_ts - now) / 86400 ))
    if [[ "$sisa" -le 5 ]]; then
        echo -e "${YELLOW}⚠  Script akan expired dalam ${sisa} hari! Hubungi @ridhani16${NC}"
        sleep 2
    fi
    return 0
}

get_expiry_info() {
    [[ ! -f "$EXPIRY_FILE" ]] && echo "Belum diset" && return
    local data exp_str days now exp_ts sisa
    data=$(cat "$EXPIRY_FILE")
    exp_ts=$(echo "$data" | cut -d'|' -f1)
    exp_str=$(echo "$data" | cut -d'|' -f2)
    days=$(echo "$data" | cut -d'|' -f3)
    now=$(date +%s)
    sisa=$(( (exp_ts - now) / 86400 ))
    echo "Expired: ${exp_str} (sisa ${sisa} hari)"
}

menu_expiry() {
    while true; do
        clear
        local EL=$(printf '═%.0s' $(seq 1 $W))
        local IL=$(printf '─%.0s' $(seq 1 $W))
        echo -e "${CYAN}╔${EL}╗${NC}"
        _center_title "KELOLA EXPIRY SCRIPT"
        echo -e "${CYAN}╠${EL}╣${NC}"
        echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
        local exp_info=$(get_expiry_info)
        printf "${CYAN}║${NC}  ${WHITE}Status  :${NC} %-54s${CYAN}║${NC}\n" "$exp_info"
        echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
        echo -e "${CYAN}╠${EL}╣${NC}"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Set Expiry Baru (hari)"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Perpanjang Expiry"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Reset Expiry (30 hari)"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Nonaktifkan Expiry"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Kembali"
        echo -e "${CYAN}╚${EL}╝${NC}"
        echo ""
        read -p " Select [0-4]: " ch
        case $ch in
            1)
                echo ""
                read -p " Masukkan lama (hari): " hari
                [[ ! "$hari" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; continue; }
                setup_expiry "$hari"
                echo -e "${GREEN}Expiry diset ${hari} hari!${NC}"
                sleep 2
                ;;
            2)
                echo ""
                read -p " Tambah berapa hari: " hari
                [[ ! "$hari" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; continue; }
                local cur_ts=0
                [[ -f "$EXPIRY_FILE" ]] && cur_ts=$(cat "$EXPIRY_FILE" | cut -d'|' -f1)
                local now_ts=$(date +%s)
                [[ "$cur_ts" -lt "$now_ts" ]] && cur_ts=$now_ts
                local new_ts=$(( cur_ts + hari * 86400 ))
                local new_str=$(date -d "@${new_ts}" +"%Y-%m-%d")
                echo "${new_ts}|${new_str}|${hari}" > "$EXPIRY_FILE"
                echo -e "${GREEN}Expiry diperpanjang ${hari} hari! Baru: ${new_str}${NC}"
                sleep 2
                ;;
            3)
                setup_expiry 30
                echo -e "${GREEN}Expiry direset ke 30 hari!${NC}"
                sleep 2
                ;;
            4)
                echo "0|9999-99-99|0" > "$EXPIRY_FILE"
                echo -e "${GREEN}Expiry dinonaktifkan!${NC}"
                sleep 2
                ;;
            0) return ;;
        esac
    done
}

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
        for ((i=0; i<empty-1; i++)); do bar+=" "; done
    fi
    printf "\r ${CYAN}[${NC}${GREEN}%-${width}s${NC}${CYAN}]${NC} ${WHITE}%3d%%${NC} %s" "$bar" "$pct" "$label"
}

show_progress() {
    progress_bar "$1" "$2" "$3"
    echo ""
}

done_msg() { printf "  ${GREEN}[✓]${NC} %-42s\n" "$1"; }
fail_msg() { printf "  ${RED}[✗]${NC} %-42s\n" "$1"; }
info_msg() { printf "  ${CYAN}[~]${NC} %s\n" "$1"; }

#================================================
# HELPER: CENTER TITLE DALAM KOTAK W=66
#================================================

_center_title() {
    local txt="$1"
    local color="${2:-$WHITE}"
    local len=${#txt}
    local total=$W
    local pad_l=$(( (total - len) / 2 ))
    local pad_r=$(( total - len - pad_l ))
    printf "${CYAN}║${NC}%*s${color}%s${NC}%*s${CYAN}║${NC}\n" $pad_l "" "$txt" $pad_r ""
}

_section_line() {
    local EL=$(printf '═%.0s' $(seq 1 $W))
    local IL=$(printf '─%.0s' $(seq 1 $W))
    case "$1" in
        top)    echo -e "${CYAN}╔${EL}╗${NC}" ;;
        mid)    echo -e "${CYAN}╠${EL}╣${NC}" ;;
        bot)    echo -e "${CYAN}╚${EL}╝${NC}" ;;
        thin)   echo -e "${CYAN}├${IL}┤${NC}" ;;
    esac
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
    echo -e "${WHITE}        VPN AUTO SCRIPT v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}        By The Proffessor Squad${NC}"
    echo ""
    echo -e "${CYAN}+=============================================+${NC}"
}

#================================================
# UTILITY FUNCTIONS
#================================================

check_status() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo "ON" || echo "OFF"
}

get_ip() {
    local ip
    for url in "https://ifconfig.me" "https://ipinfo.io/ip" "https://api.ipify.org" "https://checkip.amazonaws.com"; do
        ip=$(curl -s --max-time 3 "$url" 2>/dev/null)
        if [[ -n "$ip" ]] && ! echo "$ip" | grep -q "error\|reset\|refused\|<"; then
            echo "$ip"; return
        fi
    done
    ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    echo "${ip:-N/A}"
}

send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    [[ ! -f "$CHAT_ID_FILE" ]]   && return
    local token chatid
    token=$(cat "$BOT_TOKEN_FILE")
    chatid=$(cat "$CHAT_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" -d text="$1" -d parse_mode="HTML" --max-time 10 >/dev/null 2>&1
}

print_menu_header() {
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "$1"
    echo -e "${CYAN}╠${EL}╣${NC}"
}

print_menu_footer() {
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╚${EL}╝${NC}"
}

#================================================
# DOMAIN SETUP
#================================================

generate_random_domain() {
    local ip_vps chars random_str
    ip_vps=$(get_ip)
    chars="abcdefghijklmnopqrstuvwxyz"
    random_str=""
    for i in {1..6}; do random_str+="${chars:RANDOM%26:1}"; done
    echo "${random_str}.${ip_vps}.nip.io"
}

setup_domain() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "SETUP DOMAIN"
    echo -e "${CYAN}╠${EL}╣${NC}"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    printf "${CYAN}║${NC}  ${WHITE}[1]${NC} %-60s${CYAN}║${NC}\n" "Pakai domain sendiri"
    printf "${CYAN}║${NC}      ${YELLOW}%-58s${NC}${CYAN}║${NC}\n" "Contoh: vpn.example.com  |  SSL: Let's Encrypt"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    local preview; preview=$(generate_random_domain)
    printf "${CYAN}║${NC}  ${WHITE}[2]${NC} %-60s${CYAN}║${NC}\n" "Generate domain otomatis"
    printf "${CYAN}║${NC}      ${YELLOW}%-58s${NC}${CYAN}║${NC}\n" "Contoh: ${preview}"
    printf "${CYAN}║${NC}      ${YELLOW}%-58s${NC}${CYAN}║${NC}\n" "SSL: Self-signed"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    read -p " Pilih [1/2]: " domain_choice
    case $domain_choice in
        1)
            echo ""
            read -p " Masukkan domain: " input_domain
            [[ -z "$input_domain" ]] && { echo -e "${RED}Domain kosong!${NC}"; sleep 2; setup_domain; return; }
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
            echo -e "${RED}Tidak valid!${NC}"; sleep 1; setup_domain; return ;;
    esac
    echo "$DOMAIN" > "$DOMAIN_FILE"
}

get_ssl_cert() {
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")
    mkdir -p /etc/xray
    if [[ "$domain_type" == "custom" ]]; then
        certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos \
            --register-unsafely-without-email >/dev/null 2>&1
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
        else
            _gen_self_signed
        fi
    else
        _gen_self_signed
    fi
    chmod 644 /etc/xray/xray.* 2>/dev/null
}

_gen_self_signed() {
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
}

#================================================
# SETUP MENU COMMAND
#================================================

setup_menu_command() {
    cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh || echo "Script not found!"
MENUEOF
    chmod +x /usr/local/bin/menu
    if ! grep -q "tunnel.sh" /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc << 'BASHEOF'

# VPN Menu
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh
BASHEOF
    fi
}

#================================================
# SETUP SWAP
#================================================

setup_swap() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "SETUP SWAP 1GB"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    local swap_total; swap_total=$(free -m | awk 'NR==3{print $2}')
    if [[ "$swap_total" -gt 0 ]]; then
        echo -e "${YELLOW}Swap ada: ${swap_total}MB${NC}"
        swapoff -a 2>/dev/null; sed -i '/swapfile/d' /etc/fstab; rm -f /swapfile
    fi
    echo -e "${CYAN}Creating 1GB swap...${NC}"
    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile; mkswap /swapfile >/dev/null 2>&1; swapon /swapfile
    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo -e "${GREEN}Swap 1GB OK!${NC}"
    sleep 2
}

#================================================
# OPTIMIZE VPN
#================================================

optimize_vpn() {
    cat > /etc/sysctl.d/99-vpn.conf << 'SYSEOF'
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
SYSEOF
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    sysctl -p /etc/sysctl.d/99-vpn.conf >/dev/null 2>&1
    cat > /etc/security/limits.d/99-vpn.conf << 'LIMEOF'
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
    grep -q "^ClientAliveInterval" "$sshcfg" && \
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 30/' "$sshcfg" || \
        echo "ClientAliveInterval 30" >> "$sshcfg"
    grep -q "^ClientAliveCountMax" "$sshcfg" && \
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' "$sshcfg" || \
        echo "ClientAliveCountMax 6" >> "$sshcfg"
    grep -q "^TCPKeepAlive" "$sshcfg" && \
        sed -i 's/^TCPKeepAlive.*/TCPKeepAlive yes/' "$sshcfg" || \
        echo "TCPKeepAlive yes" >> "$sshcfg"
    systemctl restart sshd 2>/dev/null
    mkdir -p /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service.d/override.conf << 'XEOF'
[Service]
Restart=always
RestartSec=3
LimitNOFILE=65535
XEOF
    cat > /usr/local/bin/vpn-keepalive.sh << 'KAEOF'
#!/bin/bash
while true; do
    GW=$(ip route | awk '/default/{print $3; exit}')
    [[ -n "$GW" ]] && ping -c1 -W2 "$GW" >/dev/null 2>&1
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1
    sleep 25
done
KAEOF
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
}

#================================================
# HAPROXY CONFIG
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
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "CHANGE DOMAIN"
    echo -e "${CYAN}╠${EL}╣${NC}"
    printf "${CYAN}║${NC}  ${WHITE}Current :${NC} %-54s${CYAN}║${NC}\n" "${DOMAIN:-Not Set}"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    setup_domain
    echo -e "${YELLOW}Run Fix Certificate [11]!${NC}"
    sleep 3
}

#================================================
# FIX CERTIFICATE
#================================================

fix_certificate() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "FIX / RENEW CERTIFICATE"
    echo -e "${CYAN}╠${EL}╣${NC}"
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && { printf "${CYAN}║${NC}  ${RED}%-62s${NC}${CYAN}║${NC}\n" "Domain belum diset!"; echo -e "${CYAN}╚${EL}╝${NC}"; sleep 3; return; }
    printf "${CYAN}║${NC}  ${WHITE}Domain :${NC} %-54s${CYAN}║${NC}\n" "$DOMAIN"
    echo -e "${CYAN}╚${EL}╝${NC}"
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
# SPEEDTEST - OOKLA
#================================================

run_speedtest() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "SPEEDTEST BY OOKLA"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    if ! command -v speedtest >/dev/null 2>&1 && ! command -v speedtest-cli >/dev/null 2>&1; then
        echo -e "${CYAN}Installing Speedtest CLI...${NC}"
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
        if ! command -v speedtest >/dev/null 2>&1; then
            pip3 install speedtest-cli --break-system-packages >/dev/null 2>&1
        fi
    fi
    echo -e "${YELLOW}Testing... harap tunggu ~30 detik${NC}"
    echo ""
    local result
    if command -v speedtest >/dev/null 2>&1; then
        result=$(speedtest --accept-license --accept-gdpr 2>/dev/null)
        if [[ -n "$result" ]]; then
            local server latency dl ul url
            server=$(echo "$result" | grep "Server:" | sed 's/.*Server: //')
            latency=$(echo "$result" | grep "Latency:" | awk '{print $2,$3}')
            dl=$(echo "$result" | grep "Download:" | awk '{print $2,$3}')
            ul=$(echo "$result" | grep "Upload:" | awk '{print $2,$3}')
            url=$(echo "$result" | grep "Result URL:" | awk '{print $NF}')
            local IL=$(printf '─%.0s' $(seq 1 $W))
            echo -e "${CYAN}┌${IL}┐${NC}"
            _center_title "Speedtest Results"
            echo -e "${CYAN}├${IL}┤${NC}"
            printf "${CYAN}│${NC} ${WHITE}%-16s${NC} : %-44s${CYAN}│${NC}\n" "Server"   "$server"
            printf "${CYAN}│${NC} ${WHITE}%-16s${NC} : %-44s${CYAN}│${NC}\n" "Latency"  "$latency"
            printf "${CYAN}│${NC} ${WHITE}%-16s${NC} : ${GREEN}%-44s${NC}${CYAN}│${NC}\n" "Download" "$dl"
            printf "${CYAN}│${NC} ${WHITE}%-16s${NC} : ${GREEN}%-44s${NC}${CYAN}│${NC}\n" "Upload"   "$ul"
            [[ -n "$url" ]] && printf "${CYAN}│${NC} ${WHITE}%-16s${NC} : %-44s${CYAN}│${NC}\n" "Result URL" "$url"
            echo -e "${CYAN}└${IL}┘${NC}"
        else
            echo -e "${RED}Speedtest gagal!${NC}"
        fi
    elif command -v speedtest-cli >/dev/null 2>&1; then
        result=$(speedtest-cli --simple 2>/dev/null)
        [[ -n "$result" ]] && echo "$result" || echo -e "${RED}Speedtest gagal!${NC}"
    else
        echo -e "${RED}Speedtest tidak tersedia!${NC}"
    fi
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# FIX XRAY PERMISSIONS
#================================================

fix_xray_permissions() {
    mkdir -p /usr/local/etc/xray /var/log/xray
    chmod 755 /usr/local/etc/xray; chmod 755 /var/log/xray
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
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "wsSettings": {"path": "/vmess","headers": {}}
      },
      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},
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
      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},
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
      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},
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
      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},
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
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "wsSettings": {"path": "/trojan","headers": {}}
      },
      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},
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
          "certificates": [{"certificateFile": "/etc/xray/xray.crt","keyFile": "/etc/xray/xray.key"}]
        },
        "grpcSettings": {"serviceName": "vmess-grpc"}
      },
      "tag": "vmess-grpc-8444"
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
    {"protocol": "freedom","settings": {"domainStrategy": "UseIPv4"},"tag": "direct"},
    {"protocol": "blackhole","settings": {},"tag": "block"}
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [{"type": "field","ip": ["geoip:private"],"outboundTag": "block"}]
  }
}
XRAYEOF
    fix_xray_permissions
}

#================================================
# SHOW SYSTEM INFO - DASHBOARD v2.0
#================================================

show_system_info() {
    clear
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && { source /etc/os-release; os_name="${PRETTY_NAME}"; }

    local ip_vps ram_used ram_total ram_pct cpu uptime_str ssl_type ssl_status svc_running svc_total
    ip_vps=$(get_ip)
    ram_used=$(free -m | awk 'NR==2{print $3}')
    ram_total=$(free -m | awk 'NR==2{print $2}')
    ram_pct=$(awk "BEGIN {printf \"%.1f\", ($ram_used/$ram_total)*100}")
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    uptime_str=$(uptime -p | sed 's/up //')

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")
    if [[ "$domain_type" == "custom" ]]; then
        ssl_type="Let's Encrypt"
        [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]] && ssl_status="${GREEN}✓${NC}" || ssl_status="${YELLOW}⚠${NC}"
    else
        ssl_type="Self-Signed"
        ssl_status="${CYAN}~${NC}"
    fi

    local services=(xray nginx sshd haproxy dropbear udp-custom vpn-keepalive vpn-bot)
    svc_total=${#services[@]}
    svc_running=0
    for svc in "${services[@]}"; do systemctl is-active --quiet "$svc" 2>/dev/null && ((svc_running++)); done

    local ssh_count vmess_count vless_count trojan_count
    ssh_count=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    vmess_count=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    vless_count=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    trojan_count=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)

    # Expiry info
    local exp_info="N/A"
    [[ -f "$EXPIRY_FILE" ]] && {
        local exp_ts now sisa exp_str
        exp_ts=$(cat "$EXPIRY_FILE" | cut -d'|' -f1)
        exp_str=$(cat "$EXPIRY_FILE" | cut -d'|' -f2)
        now=$(date +%s)
        sisa=$(( (exp_ts - now) / 86400 ))
        [[ "$exp_ts" -eq 0 ]] && exp_info="Tidak Ada" || exp_info="${exp_str} (${sisa}h)"
    }

    local EL=$(printf '═%.0s' $(seq 1 $W))
    local IL=$(printf '─%.0s' $(seq 1 $W))

    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "VPN SERVER DASHBOARD v2.0"
    _center_title "Proffessor Squad  ·  @ridhani16" "$YELLOW"
    echo -e "${CYAN}╠${EL}╣${NC}"

    # Server Info
    echo -e "${CYAN}║${NC}  ${WHITE}▌ SERVER INFO${NC}$(printf '%*s' 51 '')${CYAN}║${NC}"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}Domain   :${NC} %-20s  ${WHITE}IP VPS  :${NC} %-17s${CYAN}│${NC}\n" "${DOMAIN:-Not Set}" "$ip_vps"
    printf "${CYAN}│${NC} ${WHITE}OS       :${NC} %-20s  ${WHITE}Uptime  :${NC} %-17s${CYAN}│${NC}\n" "${os_name:0:20}" "${uptime_str:0:17}"
    printf "${CYAN}│${NC} ${WHITE}CPU Load :${NC} %-20s  ${WHITE}RAM     :${NC} %-17s${CYAN}│${NC}\n" "${cpu}%" "${ram_used}/${ram_total}MB"
    printf "${CYAN}│${NC} ${WHITE}SSL      :${NC} %-20s  ${WHITE}Services:${NC} ${GREEN}%-17s${NC}${CYAN}│${NC}\n" "$ssl_type" "$svc_running/$svc_total Running"
    printf "${CYAN}│${NC} ${WHITE}Expiry   :${NC} %-53s${CYAN}│${NC}\n" "$exp_info"
    echo -e "${CYAN}╠${EL}╣${NC}"

    # Accounts
    echo -e "${CYAN}║${NC}  ${WHITE}▌ ACCOUNTS${NC}$(printf '%*s' 54 '')${CYAN}║${NC}"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC}  ${WHITE}SSH:${NC} ${GREEN}%-3d${NC}  ${WHITE}VMess:${NC} ${GREEN}%-3d${NC}  ${WHITE}VLess:${NC} ${GREEN}%-3d${NC}  ${WHITE}Trojan:${NC} ${GREEN}%-3d${NC}$(printf '%*s' 25 '')${CYAN}│${NC}\n" \
        "$ssh_count" "$vmess_count" "$vless_count" "$trojan_count"
    echo -e "${CYAN}╠${EL}╣${NC}"

    # Service Status
    echo -e "${CYAN}║${NC}  ${WHITE}▌ SERVICE STATUS${NC}$(printf '%*s' 48 '')${CYAN}║${NC}"
    echo -e "${CYAN}├${IL}┤${NC}"

    _svc_row() {
        local s1="$1" l1="$2" s2="$3" l2="$4"
        local c1 c2
        systemctl is-active --quiet "$s1" 2>/dev/null && c1="${GREEN}● RUNNING${NC}" || c1="${RED}○ STOPPED${NC}"
        systemctl is-active --quiet "$s2" 2>/dev/null && c2="${GREEN}● RUNNING${NC}" || c2="${RED}○ STOPPED${NC}"
        printf "${CYAN}│${NC}  %-14s " "$l1"
        printf "${c1}    %-14s " "$l2"
        printf "${c2}  ${CYAN}│${NC}\n"
    }

    _svc_row "xray"          "Xray"         "haproxy"       "HAProxy"
    _svc_row "nginx"         "Nginx"         "dropbear"      "Dropbear"
    _svc_row "sshd"          "SSH"           "udp-custom"    "UDP Custom"
    _svc_row "vpn-bot"       "Bot Telegram"  "vpn-keepalive" "Keepalive"

    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
}

#================================================
# SHOW MAIN MENU
#================================================

show_menu() {
    local EL=$(printf '═%.0s' $(seq 1 $W))
    local IL=$(printf '─%.0s' $(seq 1 $W))

    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "MAIN MENU"
    echo -e "${CYAN}╠${EL}╣${NC}"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"

    # Account Management
    printf "${CYAN}║${NC}  ${WHITE}┌─ ACCOUNT MANAGEMENT ─────────────────────────────────────┐${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[1]${NC} SSH / OVPN     ${CYAN}[4]${NC} Trojan       ${CYAN}[7]${NC} Check Expired   ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[2]${NC} VMess          ${CYAN}[5]${NC} Trial Xray   ${CYAN}[8]${NC} Delete Expired  ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[3]${NC} VLess          ${CYAN}[6]${NC} List All                      ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}└──────────────────────────────────────────────────────────┘${NC}  ${CYAN}║${NC}\n"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"

    # System & Tools
    printf "${CYAN}║${NC}  ${WHITE}┌─ SYSTEM & TOOLS ─────────────────────────────────────────┐${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[9]${NC}  Telegram Bot   ${CYAN}[13]${NC} Restart All  ${CYAN}[17]${NC} Backup         ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[10]${NC} Change Domain  ${CYAN}[14]${NC} Port Info    ${CYAN}[18]${NC} Restore        ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[11]${NC} Fix SSL/Cert   ${CYAN}[15]${NC} Speedtest    ${CYAN}[19]${NC} Uninstall      ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}│${NC}  ${CYAN}[12]${NC} Optimize VPS   ${CYAN}[16]${NC} Update       ${CYAN}[20]${NC} Expiry Script  ${WHITE}│${NC}  ${CYAN}║${NC}\n"
    printf "${CYAN}║${NC}  ${WHITE}└──────────────────────────────────────────────────────────┘${NC}  ${CYAN}║${NC}\n"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"

    printf "${CYAN}║${NC}  ${CYAN}[0]${NC} Exit$(printf '%*s' 25 '')${CYAN}[99]${NC} Advanced Menu              ${CYAN}║${NC}\n"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    echo -e "${CYAN}╠${EL}╣${NC}"
    printf "${CYAN}║${NC}  ${YELLOW}💡 TIP: ketik 'help'${NC}$(printf '%*s' 18 '')${YELLOW}📞 Support: ${WHITE}@ridhani16${NC}$(printf '%*s' 10 '')${CYAN}║${NC}\n"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
}

#================================================
# INFO PORT
#================================================

show_info_port() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    local IL=$(printf '─%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "SERVER PORT INFORMATION"
    echo -e "${CYAN}╠${EL}╣${NC}"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "SSH"                  "22"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Dropbear"             "222"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Nginx NonTLS"         "80"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Nginx Download"       "81"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "HAProxy TLS"          "443 → Xray 8443"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Xray WS TLS"          "443 (via HAProxy)"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Xray WS NonTLS"       "80 (via Nginx)"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "Xray gRPC TLS"        "8444"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-30s${NC}${CYAN}║${NC}\n" "BadVPN UDP"           "7100-7300"
    echo -e "${CYAN}╚${EL}╝${NC}"
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
        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue
        uname=$(basename "$f" .txt)
        diff=$(( (exp_ts - today) / 86400 ))
        if [[ $diff -le 3 ]]; then
            found=1
            if [[ $diff -lt 0 ]]; then
                printf "  ${RED}EXPIRED${NC}: %-30s ${YELLOW}(%s)${NC}\n" "$uname" "$exp_str"
            else
                printf "  ${YELLOW}%d hari ${NC}: %-30s ${CYAN}(%s)${NC}\n" "$diff" "$uname" "$exp_str"
            fi
        fi
    done
    shopt -u nullglob
    [[ $found -eq 0 ]] && echo -e "${GREEN}Tidak ada akun expired!${NC}"
    echo ""
    print_menu_footer
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
        local exp_str exp_ts fname uname protocol
        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
        [[ -z "$exp_str" ]] && continue
        exp_ts=$(date -d "$exp_str" +%s 2>/dev/null)
        [[ -z "$exp_ts" ]] && continue
        if [[ $exp_ts -lt $today ]]; then
            fname=$(basename "$f" .txt)
            protocol=${fname%%-*}
            uname=${fname#*-}
            printf "  ${RED}Deleting${NC}: %s\n" "$fname"
            local tmp; tmp=$(mktemp)
            jq --arg email "$uname" 'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
               "$XRAY_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
            [[ "$protocol" == "ssh" ]] && userdel -f "$uname" 2>/dev/null
            rm -f "$f"
            rm -f "$PUBLIC_HTML/${fname}.txt"
            rm -f "$PUBLIC_HTML/${fname}-clash.yaml"
            ((count++))
        fi
    done
    shopt -u nullglob
    if [[ $count -gt 0 ]]; then
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        echo ""
        echo -e "${GREEN}Deleted ${count} accounts!${NC}"
    else
        echo -e "${GREEN}Tidak ada akun expired!${NC}"
    fi
    echo ""
    print_menu_footer
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# CREATE ACCOUNT TEMPLATE - XRAY
#================================================

create_account_template() {
    local protocol="$1" username="$2" days="$3" quota="$4" iplimit="$5"
    local uuid ip_vps exp created
    uuid=$(cat /proc/sys/kernel/random/uuid)
    ip_vps=$(get_ip)
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    created=$(date +"%d %b, %Y")

    local temp; temp=$(mktemp)
    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vmess")).settings.clients) += [{"id":$uuid,"email":$email,"alterId":0}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    elif [[ "$protocol" == "vless" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vless")).settings.clients) += [{"id":$uuid,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    elif [[ "$protocol" == "trojan" ]]; then
        jq --arg password "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("trojan")).settings.clients) += [{"password":$password,"email":$email}]' \
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
    printf "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    local link_tls link_nontls link_grpc
    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"
        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' "$username" "$DOMAIN" "$uuid")
        link_grpc="vmess://$(printf '%s' "$j_grpc" | base64 -w 0)"
    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="vless://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"
    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="trojan://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"
    fi

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" << DLEOF
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
 Link TLS         :
 ${link_tls}
___________________________________________
 Link NonTLS      :
 ${link_nontls}
___________________________________________
 Link gRPC        :
 ${link_grpc}
___________________________________________
 Download         : http://${ip_vps}:81/${protocol}-${username}.txt
___________________________________________
 Aktif Selama     : ${days} Hari
 Dibuat Pada      : ${created}
 Berakhir Pada    : ${exp}
___________________________________________
DLEOF

    _print_xray_result "$protocol" "$username" "$ip_vps" "$uuid" "$quota" "$iplimit" \
        "$link_tls" "$link_nontls" "$link_grpc" "$days" "$created" "$exp"

    send_telegram_admin "✅ <b>New ${protocol^^} Account</b>
👤 User  : <code>${username}</code>
🔑 UUID  : <code>${uuid}</code>
🌐 Domain: ${DOMAIN}
📅 Exp   : ${exp}"

    read -p "Press any key to back on menu..."
}

#================================================
# PRINT XRAY RESULT
#================================================

_print_xray_result() {
    local protocol="$1" username="$2" ip_vps="$3" uuid="$4"
    local quota="$5"    iplimit="$6"  link_tls="$7" link_nontls="$8"
    local link_grpc="$9" days="${10}"  created="${11}" exp="${12}"
    local IL=$(printf '─%.0s' $(seq 1 44))
    clear
    echo -e "${CYAN}┌${IL}┐${NC}"
    printf "${CYAN}│${NC}  %-40s${CYAN}│${NC}\n" "${protocol^^} Account"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Username"    "$username"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "IP/Host"     "$ip_vps"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Domain"      "$DOMAIN"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "UUID"        "$uuid"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Quota"       "${quota} GB"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "IP Limit"    "${iplimit} IP"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Port TLS"    "443"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Port NonTLS" "80"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Port gRPC"   "8444"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Network"     "WebSocket / gRPC"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Path WS"     "/${protocol}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "ServiceName" "${protocol}-grpc"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "TLS"         "enabled"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}Link TLS    :${NC}$(printf ' %-30s' "")${CYAN}│${NC}\n"
    echo "   ${link_tls}" | fold -w 42 | while IFS= read -r l; do printf "${CYAN}│${NC} %-42s${CYAN}│${NC}\n" "$l"; done
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}Link NonTLS :${NC}$(printf ' %-30s' "")${CYAN}│${NC}\n"
    echo "   ${link_nontls}" | fold -w 42 | while IFS= read -r l; do printf "${CYAN}│${NC} %-42s${CYAN}│${NC}\n" "$l"; done
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}Link gRPC   :${NC}$(printf ' %-30s' "")${CYAN}│${NC}\n"
    echo "   ${link_grpc}" | fold -w 42 | while IFS= read -r l; do printf "${CYAN}│${NC} %-42s${CYAN}│${NC}\n" "$l"; done
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Aktif"    "${days} Hari"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Dibuat"   "$created"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Berakhir" "$exp"
    echo -e "${CYAN}└${IL}┘${NC}"
    echo ""
}

#================================================
# TRIAL XRAY - 1 JAM
#================================================

create_trial_xray() {
    local protocol="$1"
    local username="trial-$(date +%H%M%S)"
    local uuid ip_vps exp created
    uuid=$(cat /proc/sys/kernel/random/uuid)
    ip_vps=$(get_ip)
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
    created=$(date +"%d %b, %Y %H:%M")

    local temp; temp=$(mktemp)
    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vmess")).settings.clients) += [{"id":$uuid,"email":$email,"alterId":0}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    elif [[ "$protocol" == "vless" ]]; then
        jq --arg uuid "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("vless")).settings.clients) += [{"id":$uuid,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    elif [[ "$protocol" == "trojan" ]]; then
        jq --arg password "$uuid" --arg email "$username" \
           '(.inbounds[] | select(.tag | startswith("trojan")).settings.clients) += [{"password":$password,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    fi

    if [[ $? -eq 0 ]] && [[ -s "$temp" ]]; then
        mv "$temp" "$XRAY_CONFIG"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        sleep 1
    else
        rm -f "$temp"; echo -e "${RED}Failed!${NC}"; sleep 2; return
    fi

    mkdir -p "$AKUN_DIR"
    printf "UUID=%s\nQUOTA=1\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$uuid" "$exp" "$created" > "$AKUN_DIR/${protocol}-${username}.txt"

    (
        sleep 3600
        local tmp2; tmp2=$(mktemp)
        jq --arg email "$username" 'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp2" 2>/dev/null && mv "$tmp2" "$XRAY_CONFIG" || rm -f "$tmp2"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        rm -f "$AKUN_DIR/${protocol}-${username}.txt" "$PUBLIC_HTML/${protocol}-${username}.txt"
    ) &
    disown $!

    local link_tls link_nontls link_grpc
    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"
        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' "$username" "$DOMAIN" "$uuid")
        link_grpc="vmess://$(printf '%s' "$j_grpc" | base64 -w 0)"
    elif [[ "$protocol" == "vless" ]]; then
        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="vless://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"
    elif [[ "$protocol" == "trojan" ]]; then
        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"
        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"
        link_grpc="trojan://${uuid}@${DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"
    fi

    _print_xray_result "$protocol" "$username" "$ip_vps" "$uuid" "1" "1" \
        "$link_tls" "$link_nontls" "$link_grpc" "1 Jam (Auto Delete)" "$created" "$exp"
    read -p "Press any key to back on menu..."
}

#================================================
# CREATE SSH
#================================================

create_ssh() {
    clear
    print_menu_header "CREATE SSH ACCOUNT"
    echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Required!${NC}"; sleep 2; return; }
    if id "$username" &>/dev/null; then echo -e "${RED}User sudah ada!${NC}"; sleep 2; return; fi
    read -p " Password      : " password
    [[ -z "$password" ]] && { echo -e "${RED}Required!${NC}"; sleep 2; return; }
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; return; }
    read -p " Limit IP      : " iplimit
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

    _save_ssh_file "SSH Account" "$username" "$password" "$ip_vps" "$days" "$created" "$exp"
    _print_ssh_result "SSH Account" "$username" "$password" "$ip_vps" "$days" "$created" "$exp"

    send_telegram_admin "✅ <b>New SSH Account</b>
👤 User : <code>${username}</code>
🔑 Pass : <code>${password}</code>
🌐 IP   : ${ip_vps}
📅 Exp  : ${exp}"
    read -p "Press any key to back on menu..."
}

#================================================
# SSH TRIAL
#================================================

create_ssh_trial() {
    local suffix; suffix=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 4 | tr '[:lower:]' '[:upper:]')
    local username="Trial-${suffix}" password="1" ip_vps exp exp_date created
    ip_vps=$(get_ip)
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
    exp_date=$(date -d "+1 days" +"%Y-%m-%d")
    created=$(date +"%d %b, %Y %H:%M")

    useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
    echo "${username}:${password}" | chpasswd

    mkdir -p "$AKUN_DIR"
    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$username" "$password" "$exp" "$created" > "$AKUN_DIR/ssh-${username}.txt"

    (
        sleep 3600
        userdel -f "$username" 2>/dev/null
        rm -f "$AKUN_DIR/ssh-${username}.txt" "$PUBLIC_HTML/ssh-${username}.txt"
    ) &
    disown $!

    _save_ssh_file "Trial SSH (1 Jam)" "$username" "$password" "$ip_vps" "1 Jam (Auto Delete)" "$created" "$exp"
    _print_ssh_result "Trial SSH (1 Jam)" "$username" "$password" "$ip_vps" "1 Jam" "$created" "$exp"

    send_telegram_admin "🆓 <b>SSH Trial</b>
👤 User : <code>${username}</code>
🔑 Pass : <code>${password}</code>
⏰ Exp  : ${exp}"
    read -p "Press any key to back on menu..."
}

#================================================
# SSH HELPERS
#================================================

_save_ssh_file() {
    local title="$1" username="$2" password="$3" ip_vps="$4" days="$5" created="$6" exp="$7"
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" << SSHFILE
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
    local title="$1" username="$2" password="$3" ip_vps="$4" days="$5" created="$6" exp="$7"
    local IL=$(printf '─%.0s' $(seq 1 44))
    clear
    echo -e "${CYAN}┌${IL}┐${NC}"
    printf "${CYAN}│${NC}  %-40s${CYAN}│${NC}\n" "$title"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Username"       "$username"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Password"       "$password"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "IP/Host"        "$ip_vps"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Domain SSH"     "$DOMAIN"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "OpenSSH"        "22"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Dropbear"       "222"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "SSL/TLS"        "443"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "BadVPN UDPGW"   "7100,7200,7300"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Format Hc"      "${DOMAIN}:80@${username}:${password}"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : http://%s:81/ssh-%s.txt${CYAN}│${NC}\n" "Save Link" "$ip_vps" "$username"
    echo -e "${CYAN}├${IL}┤${NC}"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Aktif Selama"  "$days"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Dibuat Pada"   "$created"
    printf "${CYAN}│${NC} ${WHITE}%-14s${NC} : %-23s${CYAN}│${NC}\n" "Berakhir Pada" "$exp"
    echo -e "${CYAN}└${IL}┘${NC}"
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
    if [[ ${#files[@]} -eq 0 ]]; then echo -e "${RED}No accounts!${NC}"; sleep 2; return; fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        printf "  ${CYAN}•${NC} %-20s ${YELLOW}%s${NC}\n" "$n" "$e"
    done
    echo ""
    read -p "Username to delete: " username
    [[ -z "$username" ]] && return
    local tmp; tmp=$(mktemp)
    jq --arg email "$username" 'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
       "$XRAY_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
    fix_xray_permissions
    systemctl restart xray 2>/dev/null
    rm -f "$AKUN_DIR/${protocol}-${username}.txt" "$PUBLIC_HTML/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && userdel -f "$username" 2>/dev/null
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
    if [[ ${#files[@]} -eq 0 ]]; then echo -e "${RED}No accounts!${NC}"; sleep 2; return; fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        printf "  ${CYAN}•${NC} %-20s ${YELLOW}%s${NC}\n" "$n" "$e"
    done
    echo ""
    read -p "Username to renew: " username
    [[ -z "$username" ]] && return
    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && { echo -e "${RED}Not found!${NC}"; sleep 2; return; }
    read -p "Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; return; }
    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && chage -E "$new_exp_date" "$username" 2>/dev/null
    echo -e "${GREEN}Renewed! Exp: ${new_exp}${NC}"
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
    if [[ ${#files[@]} -eq 0 ]]; then echo -e "${RED}No accounts!${NC}"; sleep 2; return; fi
    local IL=$(printf '─%.0s' $(seq 1 52))
    printf "${CYAN}┌${IL}┐${NC}\n"
    printf "${CYAN}│${NC} ${WHITE}%-20s %-18s %-6s %-4s${NC}${CYAN}│${NC}\n" "USERNAME" "EXPIRED" "QUOTA" "TYPE"
    printf "${CYAN}├${IL}┤${NC}\n"
    for f in "${files[@]}"; do
        local uname exp quota trial ttype
        uname=$(basename "$f" .txt | sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        quota=$(grep "QUOTA" "$f" 2>/dev/null | cut -d= -f2)
        trial=$(grep "TRIAL" "$f" 2>/dev/null | cut -d= -f2)
        ttype="Member"; [[ "$trial" == "1" ]] && ttype="Trial"
        printf "${CYAN}│${NC} %-20s %-18s %-6s %-4s${CYAN}│${NC}\n" "$uname" "$exp" "${quota:-N/A}GB" "$ttype"
    done
    printf "${CYAN}└${IL}┘${NC}\n"
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
        who 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn
    else
        echo -e "${WHITE}Xray ${protocol^^} log (last 20):${NC}"
        if [[ -f /var/log/xray/access.log ]]; then
            grep -i "$protocol" /var/log/xray/access.log 2>/dev/null | tail -20 || echo "No data"
        else
            echo "No log"
        fi
    fi
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# SETUP TELEGRAM BOT
#================================================

setup_telegram_bot() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "SETUP TELEGRAM BOT"
    echo -e "${CYAN}╠${EL}╣${NC}"
    printf "${CYAN}║${NC}  ${YELLOW}%-62s${NC}${CYAN}║${NC}\n" "Cara mendapatkan Bot Token:"
    printf "${CYAN}║${NC}  %-64s${CYAN}║${NC}\n" "1. Buka Telegram cari @BotFather"
    printf "${CYAN}║${NC}  %-64s${CYAN}║${NC}\n" "2. Ketik /newbot ikuti instruksi"
    printf "${CYAN}║${NC}  %-64s${CYAN}║${NC}\n" "3. Copy TOKEN yang diberikan"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    read -p " Bot Token     : " bot_token
    [[ -z "$bot_token" ]] && { echo -e "${RED}Token required!${NC}"; sleep 2; return; }
    read -p " Admin Chat ID : " admin_id
    [[ -z "$admin_id" ]] && { echo -e "${RED}Chat ID required!${NC}"; sleep 2; return; }
    echo -e "${CYAN}Testing token...${NC}"
    local test_result bot_name
    test_result=$(curl -s --max-time 10 "https://api.telegram.org/bot${bot_token}/getMe")
    if ! echo "$test_result" | grep -q '"ok":true'; then
        echo -e "${RED}Token tidak valid!${NC}"; sleep 2; return
    fi
    bot_name=$(echo "$test_result" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['username'])" 2>/dev/null)
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
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
            -d chat_id="$admin_id" -d text="✅ Bot VPN Aktif! Domain: ${DOMAIN}" \
            -d parse_mode="HTML" --max-time 10 >/dev/null 2>&1
    else
        echo -e "${RED}Bot gagal start!${NC}"
        journalctl -u vpn-bot -n 10 --no-pager
    fi
    echo ""
    read -p "Press any key to back on menu..."
}

#================================================
# INSTALL BOT SERVICE
#================================================

_install_bot_service() {
    mkdir -p /root/bot "$ORDER_DIR"
    pip3 install requests --break-system-packages >/dev/null 2>&1 || pip3 install requests >/dev/null 2>&1
    cat > /root/bot/bot.py << 'BOTEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, json, time, subprocess, threading
from datetime import datetime, timedelta
try:
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
except ImportError:
    os.system('pip3 install requests --break-system-packages -q')
    import requests
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry

TOKEN     = open('/root/.bot_token').read().strip()
ADMIN_ID  = int(open('/root/.chat_id').read().strip())
DOMAIN    = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
ORDER_DIR = '/root/orders'
AKUN_DIR  = '/root/akun'
HTML_DIR  = '/var/www/html'
API       = f'https://api.telegram.org/bot{TOKEN}'

os.makedirs(ORDER_DIR, exist_ok=True)
os.makedirs(AKUN_DIR,  exist_ok=True)
os.makedirs(HTML_DIR,  exist_ok=True)

user_state = {}
state_lock = threading.Lock()

def make_session():
    s = requests.Session()
    retry = Retry(total=2, backoff_factor=0.3, status_forcelist=[500,502,503,504])
    adapter = HTTPAdapter(max_retries=retry, pool_connections=20, pool_maxsize=50)
    s.mount('https://', adapter); s.mount('http://', adapter)
    return s

SESSION = make_session()

def get_payment():
    info = {'REK_NAME':'N/A','REK_NUMBER':'N/A','REK_BANK':'N/A','HARGA':'10000'}
    try:
        with open('/root/.payment_info') as f:
            for line in f:
                line = line.strip()
                if '=' in line:
                    k,v = line.split('=',1); info[k.strip()] = v.strip()
    except: pass
    return info

def api_post(method, data, timeout=6):
    try:
        r = SESSION.post(f'{API}/{method}', data=data, timeout=timeout); return r.json()
    except Exception as e:
        print(f'API {method}: {e}', flush=True); return {}

def send(chat_id, text, markup=None, parse_mode='HTML'):
    data = {'chat_id':chat_id,'text':text,'parse_mode':parse_mode}
    if markup: data['reply_markup'] = json.dumps(markup)
    return api_post('sendMessage', data)

def answer_cb(cb_id, text='', alert=False):
    api_post('answerCallbackQuery', {'callback_query_id':cb_id,'text':text,'show_alert':alert})

def get_updates(offset=0):
    try:
        r = SESSION.get(f'{API}/getUpdates', params={'offset':offset,'timeout':15,'limit':100}, timeout=20)
        return r.json().get('result', [])
    except: return []

def kb_main():
    return {'keyboard':[['🆓 Trial Gratis','🛒 Order VPN'],['📋 Cek Akun Saya','ℹ️ Info Server'],['❓ Bantuan','📞 Hubungi Admin']],'resize_keyboard':True,'one_time_keyboard':False}

def kb_trial():
    return {'inline_keyboard':[[{'text':'🔵 SSH','callback_data':'trial_ssh'},{'text':'🟢 VMess','callback_data':'trial_vmess'}],[{'text':'🟡 VLess','callback_data':'trial_vless'},{'text':'🔴 Trojan','callback_data':'trial_trojan'}],[{'text':'◀️ Kembali','callback_data':'back_main'}]]}

def kb_order():
    return {'inline_keyboard':[[{'text':'🔵 SSH','callback_data':'order_ssh'},{'text':'🟢 VMess','callback_data':'order_vmess'}],[{'text':'🟡 VLess','callback_data':'order_vless'},{'text':'🔴 Trojan','callback_data':'order_trojan'}],[{'text':'◀️ Kembali','callback_data':'back_main'}]]}

def kb_confirm(order_id):
    return {'inline_keyboard':[[{'text':'✅ Konfirmasi','callback_data':f'confirm_{order_id}'},{'text':'❌ Tolak','callback_data':f'reject_{order_id}'}]]}

def kb_cancel():
    return {'inline_keyboard':[[{'text':'❌ Batalkan','callback_data':'cancel_order'}]]}

def get_ip():
    for url in ['https://ifconfig.me','https://ipinfo.io/ip','https://api.ipify.org']:
        try:
            r = SESSION.get(url, timeout=3)
            if r.status_code == 200: return r.text.strip()
        except: pass
    return 'N/A'

def run_cmd(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=90)
        return r.stdout.strip()
    except Exception as e:
        print(f'CMD: {e}', flush=True); return ''

def save_order(oid, data):
    with open(f'{ORDER_DIR}/{oid}.json','w') as f: json.dump(data, f, indent=2)

def load_order(oid):
    p = f'{ORDER_DIR}/{oid}.json'
    if not os.path.exists(p): return None
    with open(p) as f: return json.load(f)

def get_pending():
    orders = []
    if not os.path.exists(ORDER_DIR): return orders
    for fn in os.listdir(ORDER_DIR):
        if not fn.endswith('.json'): continue
        try:
            with open(f'{ORDER_DIR}/{fn}') as f: d = json.load(f)
            if d.get('status') == 'pending': orders.append(d)
        except: pass
    return orders

def make_ssh(username, password, days=30):
    exp_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
    exp_str  = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')
    created  = datetime.now().strftime('%d %b, %Y')
    run_cmd(f'useradd -M -s /bin/false -e {exp_date} {username} 2>/dev/null')
    run_cmd(f'echo "{username}:{password}" | chpasswd')
    with open(f'{AKUN_DIR}/ssh-{username}.txt','w') as f:
        f.write(f'USERNAME={username}\nPASSWORD={password}\nIPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n')
    ip = get_ip()
    return exp_str, ip

def make_xray(protocol, username, days=30, quota=100):
    import uuid as uuidlib, base64
    uid = str(uuidlib.uuid4())
    exp_str = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')
    created = datetime.now().strftime('%d %b, %Y')
    cfg = '/usr/local/etc/xray/config.json'
    if protocol == 'vmess':
        cmd = f'jq --arg uuid "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("vmess")).settings.clients) += [{{"id":$uuid,"email":$email,"alterId":0}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'
    elif protocol == 'vless':
        cmd = f'jq --arg uuid "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("vless")).settings.clients) += [{{"id":$uuid,"email":$email}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'
    elif protocol == 'trojan':
        cmd = f'jq --arg password "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("trojan")).settings.clients) += [{{"password":$password,"email":$email}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'
    run_cmd(cmd); run_cmd(f'chmod 644 {cfg}'); run_cmd('systemctl restart xray')
    with open(f'{AKUN_DIR}/{protocol}-{username}.txt','w') as f:
        f.write(f'UUID={uid}\nQUOTA={quota}\nIPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n')
    ip = get_ip()
    if protocol == 'vmess':
        import base64
        j_tls  = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"443","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"tls"}}'
        link_tls  = "vmess://" + base64.b64encode(j_tls.encode()).decode()
        j_ntls = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"80","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"none"}}'
        link_ntls = "vmess://" + base64.b64encode(j_ntls.encode()).decode()
        j_grpc = f'{{"v":"2","ps":"{username}","add":"{DOMAIN}","port":"8444","id":"{uid}","aid":"0","net":"grpc","path":"{protocol}-grpc","type":"none","host":"bug.com","tls":"tls"}}'
        link_grpc = "vmess://" + base64.b64encode(j_grpc.encode()).decode()
    elif protocol == 'vless':
        link_tls  = f"vless://{uid}@bug.com:443?path=%2F{protocol}&security=tls&encryption=none&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"
        link_ntls = f"vless://{uid}@bug.com:80?path=%2F{protocol}&security=none&encryption=none&host={DOMAIN}&type=ws#{username}-NonTLS"
        link_grpc = f"vless://{uid}@{DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"
    elif protocol == 'trojan':
        link_tls  = f"trojan://{uid}@bug.com:443?path=%2F{protocol}&security=tls&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"
        link_ntls = f"trojan://{uid}@bug.com:80?path=%2F{protocol}&security=none&host={DOMAIN}&type=ws#{username}-NonTLS"
        link_grpc = f"trojan://{uid}@{DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"
    return (uid, exp_str, ip, link_tls, link_ntls, link_grpc)

def fmt_ssh_msg(username, password, ip, exp_str, title, durasi="30 Hari"):
    return f'''✅ <b>{title}</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n👤 Username : <code>{username}</code>\n🔑 Password : <code>{password}</code>\n🌐 Domain   : <code>{DOMAIN}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🔌 OpenSSH  : 22\n🔌 Dropbear : 222\n🔌 SSL/TLS  : 443\n🔌 BadVPN   : 7100,7200,7300\n━━━━━━━━━━━━━━━━━━━━━━━━━\n⏰ Aktif    : {durasi}\n📅 Expired  : {exp_str}\n━━━━━━━━━━━━━━━━━━━━━━━━━'''

def fmt_xray_msg(protocol, username, uid, ip, exp_str, link_tls, link_ntls, link_grpc, title, durasi="30 Hari"):
    return f'''✅ <b>{title}</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n👤 Username : <code>{username}</code>\n🔑 UUID     : <code>{uid}</code>\n🌐 Domain   : <code>{DOMAIN}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🔌 Port TLS    : 443\n🔌 Port NonTLS : 80\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🔗 Link TLS:\n<code>{link_tls}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🔗 Link NonTLS:\n<code>{link_ntls}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n⏰ Aktif  : {durasi}\n📅 Expired: {exp_str}\n━━━━━━━━━━━━━━━━━━━━━━━━━'''

def do_trial(protocol, chat_id):
    ts = datetime.now().strftime('%H%M%S')
    username = f'trial-{ts}'
    ip = get_ip()
    exp_1h = (datetime.now() + timedelta(hours=1)).strftime('%d %b %Y %H:%M')
    if protocol == 'ssh':
        password = '1'
        exp_date = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
        run_cmd(f'useradd -M -s /bin/false -e {exp_date} {username} 2>/dev/null')
        run_cmd(f'echo "{username}:{password}" | chpasswd')
        run_cmd(f'(sleep 3600; userdel -f {username} 2>/dev/null; rm -f {AKUN_DIR}/ssh-{username}.txt {HTML_DIR}/ssh-{username}.txt) & disown')
        msg = fmt_ssh_msg(username, password, ip, exp_1h, 'Trial SSH Berhasil! 🆓', '1 Jam (Auto Hapus)')
        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'
        send(chat_id, msg, markup=kb_main())
    else:
        try:
            uid, _, ip, link_tls, link_ntls, link_grpc = make_xray(protocol, username, days=1, quota=1)
        except Exception as e:
            send(chat_id, f'❌ Gagal buat akun: {e}'); return
        del_cmd = f'(sleep 3600; jq --arg email "{username}" \'del(.inbounds[].settings.clients[]? | select(.email == $email))\' /usr/local/etc/xray/config.json > /tmp/xd.json && mv /tmp/xd.json /usr/local/etc/xray/config.json; chmod 644 /usr/local/etc/xray/config.json; systemctl restart xray; rm -f {AKUN_DIR}/{protocol}-{username}.txt {HTML_DIR}/{protocol}-{username}.txt) & disown'
        run_cmd(del_cmd)
        msg = fmt_xray_msg(protocol, username, uid, ip, exp_1h, link_tls, link_ntls, link_grpc, f'Trial {protocol.upper()} Berhasil! 🆓', '1 Jam (Auto Hapus)')
        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'
        send(chat_id, msg, markup=kb_main())

def fmt_payment(order):
    pay = get_payment()
    harga = int(pay.get('HARGA', 10000))
    return f'''🛒 <b>Detail Order</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🆔 Order ID : <code>{order["order_id"]}</code>\n📦 Paket    : {order["protocol"].upper()} 30 Hari\n👤 Username : <code>{order["username"]}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n💰 <b>PEMBAYARAN</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🏦 {pay.get("REK_BANK","N/A")}\n📱 No : <code>{pay.get("REK_NUMBER","N/A")}</code>\n👤 a/n: {pay.get("REK_NAME","N/A")}\n💵 Nominal: <b>Rp {harga:,}</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n📸 Langkah:\n1. Transfer Rp {harga:,}\n2. Screenshot bukti\n3. Kirim ke admin\n4. Tunggu konfirmasi\n━━━━━━━━━━━━━━━━━━━━━━━━━'''

def deliver_account(chat_id, protocol, username):
    import random, string
    try:
        if protocol == 'ssh':
            password = ''.join(random.choices(string.ascii_letters + string.digits, k=8))
            exp_str, ip = make_ssh(username, password, days=30)
            msg = fmt_ssh_msg(username, password, ip, exp_str, 'Akun SSH Berhasil! ✅')
        else:
            uid, exp_str, ip, link_tls, link_ntls, link_grpc = make_xray(protocol, username, days=30, quota=100)
            msg = fmt_xray_msg(protocol, username, uid, ip, exp_str, link_tls, link_ntls, link_grpc, f'Akun {protocol.upper()} Berhasil! ✅')
        msg += '\n💰 Terima kasih! 🙏'
        send(chat_id, msg, markup=kb_main())
        return True, msg
    except Exception as e:
        return False, str(e)

def on_start(msg):
    chat_id = msg['chat']['id']
    fname = msg['from'].get('first_name','User')
    pay = get_payment()
    harga = int(pay.get('HARGA',10000))
    send(chat_id, f'''👋 Halo <b>{fname}</b>!\n\n🤖 <b>Bot VPN Proffessor Squad</b>\n🌐 Server: <code>{DOMAIN}</code>\n\nPilih menu di bawah 👇''', markup=kb_main())

def on_help(msg):
    chat_id = msg['chat']['id']
    pay = get_payment()
    harga = int(pay.get('HARGA',10000))
    send(chat_id, f'❓ <b>PANDUAN BOT VPN</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🆓 Trial 1 jam → ketik Trial Gratis\n🛒 Order 30 hari → Rp {harga:,}\n📞 Masalah? ketik Hubungi Admin\n━━━━━━━━━━━━━━━━━━━━━━━━━', markup=kb_main())

def on_info(msg):
    chat_id = msg['chat']['id']
    ip = get_ip()
    send(chat_id, f'ℹ️ <b>INFO SERVER</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🌐 Domain : <code>{DOMAIN}</code>\n🖥️ IP VPS : <code>{ip}</code>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🔌 SSH: 22 | Dropbear: 222 | SSL: 443\n🔌 Xray TLS: 443 | NonTLS: 80 | gRPC: 8444\n━━━━━━━━━━━━━━━━━━━━━━━━━', markup=kb_main())

def on_cek_akun(msg):
    chat_id = msg['chat']['id']
    found = []
    if os.path.exists(ORDER_DIR):
        for fn in os.listdir(ORDER_DIR):
            if not fn.endswith('.json'): continue
            try:
                with open(f'{ORDER_DIR}/{fn}') as f: order = json.load(f)
                if str(order.get('chat_id')) == str(chat_id) and order.get('status') == 'confirmed':
                    proto = order.get('protocol',''); uname = order.get('username','')
                    af = f'{AKUN_DIR}/{proto}-{uname}.txt'; exp = ''
                    if os.path.exists(af):
                        with open(af) as a:
                            for line in a:
                                if 'EXPIRED=' in line: exp = line.split('=',1)[1].strip()
                    found.append({'protocol':proto,'username':uname,'expired':exp})
            except: pass
    if not found:
        send(chat_id, '📋 Tidak ada akun aktif.', markup=kb_main()); return
    text = '📋 <b>Akun Aktif Kamu</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    for a in found: text += f'📦 {a["protocol"].upper()} | 👤 {a["username"]} | 📅 {a["expired"]}\n'
    send(chat_id, text, markup=kb_main())

def on_contact(msg):
    chat_id = msg['chat']['id']
    fname = msg['from'].get('first_name','User')
    uname = msg['from'].get('username','')
    send(chat_id, '📞 Pesan diteruskan ke admin.', markup=kb_main())
    send(ADMIN_ID, f'📞 <b>User butuh bantuan!</b>\n👤 {fname} | @{uname} | <code>{chat_id}</code>')

def on_callback(cb):
    chat_id = cb['message']['chat']['id']
    cb_id = cb['id']; data = cb['data']
    uname = cb['from'].get('username',''); fname = cb['from'].get('first_name','User')
    answer_cb(cb_id)
    if data.startswith('trial_'):
        protocol = data.replace('trial_','')
        send(chat_id, f'⏳ Membuat trial {protocol.upper()}...')
        threading.Thread(target=do_trial, args=(protocol, chat_id), daemon=True).start()
    elif data.startswith('order_'):
        protocol = data.replace('order_','')
        pay = get_payment(); harga = int(pay.get('HARGA',10000))
        with state_lock: user_state[chat_id] = {'step':'wait_username','protocol':protocol}
        send(chat_id, f'🛒 <b>Order {protocol.upper()} 30 Hari</b>\n💰 Rp {harga:,}\n\n✏️ Ketik username (3-20 karakter):', markup=kb_cancel())
    elif data == 'cancel_order':
        with state_lock: user_state.pop(chat_id, None)
        send(chat_id, '❌ Order dibatalkan.', markup=kb_main())
    elif data == 'back_main':
        send(chat_id, '🏠 Menu Utama', markup=kb_main())
    elif data.startswith('confirm_') and chat_id == ADMIN_ID:
        oid = data.replace('confirm_',''); order = load_order(oid)
        if not order: send(ADMIN_ID,'❌ Order tidak ada!'); return
        if order.get('status') != 'pending': send(ADMIN_ID,'⚠️ Sudah diproses!'); return
        send(ADMIN_ID,'⏳ Membuat akun...')
        def do_confirm():
            ok, result = deliver_account(order['chat_id'], order['protocol'], order['username'])
            if ok:
                order['status'] = 'confirmed'; save_order(oid, order)
                send(ADMIN_ID, f'✅ Akun {order["protocol"].upper()} <code>{order["username"]}</code> dikirim!')
            else: send(ADMIN_ID, f'❌ Gagal: {result}')
        threading.Thread(target=do_confirm, daemon=True).start()
    elif data.startswith('reject_') and chat_id == ADMIN_ID:
        oid = data.replace('reject_',''); order = load_order(oid)
        if not order: send(ADMIN_ID,'❌ Tidak ada!'); return
        order['status'] = 'rejected'; save_order(oid, order)
        send(order['chat_id'], f'❌ <b>Order Ditolak</b>\nID: <code>{oid}</code>', markup=kb_main())
        send(ADMIN_ID, f'❌ Order <code>{oid}</code> ditolak.')

def on_msg(msg):
    if 'text' not in msg: return
    chat_id = msg['chat']['id']; text = msg['text'].strip()
    uname = msg['from'].get('username',''); fname = msg['from'].get('first_name','User')
    with state_lock: state = user_state.get(chat_id, {})
    if state.get('step') == 'wait_username':
        new_u = text.strip().replace(' ','_')
        if len(new_u) < 3 or len(new_u) > 20:
            send(chat_id, '❌ Username 3-20 karakter!', markup=kb_cancel()); return
        protocol = state['protocol']; oid = f'{chat_id}_{int(time.time())}'
        order = {'order_id':oid,'chat_id':chat_id,'username':new_u,'protocol':protocol,'status':'pending','created_at':datetime.now().isoformat(),'tg_user':uname,'tg_name':fname}
        save_order(oid, order)
        with state_lock: user_state.pop(chat_id, None)
        send(chat_id, fmt_payment(order))
        pay = get_payment(); harga = int(pay.get('HARGA',10000))
        send(ADMIN_ID, f'🔔 <b>ORDER BARU!</b>\n🆔 {oid}\n📦 {protocol.upper()}\n👤 <code>{new_u}</code>\n📱 @{uname}\n💰 Rp {harga:,}', markup=kb_confirm(oid))
        return
    if text in ['/start','🏠 Menu']: on_start(msg)
    elif text in ['/help','❓ Bantuan']: on_help(msg)
    elif text == '🆓 Trial Gratis': send(chat_id, '🆓 Pilih protocol:', markup=kb_trial())
    elif text == '🛒 Order VPN':
        pay = get_payment(); harga = int(pay.get('HARGA',10000))
        send(chat_id, f'🛒 Order VPN 30 Hari - Rp {harga:,}\nPilih protocol:', markup=kb_order())
    elif text == '📋 Cek Akun Saya': on_cek_akun(msg)
    elif text == 'ℹ️ Info Server': on_info(msg)
    elif text == '📞 Hubungi Admin': on_contact(msg)

def main():
    print(f'Bot VPN - Admin: {ADMIN_ID}', flush=True)
    offset = 0; pool = []
    while True:
        try:
            updates = get_updates(offset)
            for upd in updates:
                offset = upd['update_id'] + 1; t = None
                if 'message' in upd: t = threading.Thread(target=on_msg, args=(upd['message'],), daemon=True)
                elif 'callback_query' in upd: t = threading.Thread(target=on_callback, args=(upd['callback_query'],), daemon=True)
                if t: t.start(); pool.append(t)
            pool = [x for x in pool if x.is_alive()]
        except KeyboardInterrupt: print('Bot stopped.', flush=True); break
        except Exception as e: print(f'Loop: {e}', flush=True); time.sleep(2)

if __name__ == '__main__': main()
BOTEOF
    chmod +x /root/bot/bot.py
    cat > /etc/systemd/system/vpn-bot.service << 'SVCEOF'
[Unit]
Description=VPN Bot Proffessor Squad
After=network.target

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
        local bs; bs=$(check_status vpn-bot)
        local cs; [[ "$bs" == "ON" ]] && cs="${GREEN}RUNNING${NC}" || cs="${RED}STOPPED${NC}"
        printf "${CYAN}║${NC}  Status  : %-56b${CYAN}║${NC}\n" "$cs"
        echo -e "${CYAN}╠$(printf '═%.0s' $(seq 1 $W))╣${NC}"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Setup Bot"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Start Bot"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Stop Bot"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Restart Bot"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Lihat Log"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "Order Pending"
        printf "${CYAN}║${NC}  ${CYAN}[7]${NC} %-60s${CYAN}║${NC}\n" "Info Bot"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer
        echo ""
        read -p " Select: " choice
        case $choice in
            1) setup_telegram_bot ;;
            2) systemctl start vpn-bot; echo -e "${GREEN}Started!${NC}"; sleep 2 ;;
            3) systemctl stop vpn-bot; echo -e "${YELLOW}Stopped!${NC}"; sleep 2 ;;
            4) systemctl restart vpn-bot; echo -e "${GREEN}Restarted!${NC}"; sleep 2 ;;
            5) clear; journalctl -u vpn-bot -n 50 --no-pager; echo ""; read -p "Press any key..." ;;
            6)
                clear; print_menu_header "ORDER PENDING"; echo ""
                local found=0
                shopt -s nullglob
                for f in "$ORDER_DIR"/*.json; do
                    [[ ! -f "$f" ]] && continue
                    local st; st=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('status',''))" 2>/dev/null)
                    if [[ "$st" == "pending" ]]; then
                        found=1
                        python3 -c "import json; d=json.load(open('$f')); print(f'ID:{d[\"order_id\"]} | {d[\"protocol\"].upper()} | {d[\"username\"]} | @{d.get(\"tg_user\",\"N/A\")}')" 2>/dev/null
                    fi
                done
                shopt -u nullglob
                [[ $found -eq 0 ]] && echo -e "${GREEN}Tidak ada pending!${NC}"
                echo ""; read -p "Press any key..."
                ;;
            7)
                clear; print_menu_header "BOT INFO"; echo ""
                if [[ -f "$BOT_TOKEN_FILE" ]]; then
                    local aid; aid=$(cat "$CHAT_ID_FILE" 2>/dev/null)
                    printf " %-16s : %s\n" "Status"   "$bs"
                    printf " %-16s : %s\n" "Admin ID" "$aid"
                    if [[ -f "$PAYMENT_FILE" ]]; then
                        source "$PAYMENT_FILE"
                        printf " %-16s : %s\n" "Bank"      "$REK_BANK"
                        printf " %-16s : %s\n" "No Rek"    "$REK_NUMBER"
                        printf " %-16s : %s\n" "Atas Nama" "$REK_NAME"
                        printf " %-16s : Rp %s\n" "Harga"  "$HARGA"
                    fi
                else
                    echo -e "${RED}Bot belum setup!${NC}"
                fi
                echo ""; read -p "Press any key..."
                ;;
            0) return ;;
        esac
    done
}

#================================================
# CREATE VMESS / VLESS / TROJAN
#================================================

create_vmess() {
    clear; print_menu_header "CREATE VMESS ACCOUNT"; echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Required!${NC}"; sleep 2; return; }
    grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null && { echo -e "${RED}Username sudah ada!${NC}"; sleep 2; return; }
    read -p " Expired (days): " days; [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; return; }
    read -p " Quota (GB)    : " quota; [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit; [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "vmess" "$username" "$days" "$quota" "$iplimit"
}

create_vless() {
    clear; print_menu_header "CREATE VLESS ACCOUNT"; echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Required!${NC}"; sleep 2; return; }
    grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null && { echo -e "${RED}Username sudah ada!${NC}"; sleep 2; return; }
    read -p " Expired (days): " days; [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; return; }
    read -p " Quota (GB)    : " quota; [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit; [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "vless" "$username" "$days" "$quota" "$iplimit"
}

create_trojan() {
    clear; print_menu_header "CREATE TROJAN ACCOUNT"; echo ""
    read -p " Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Required!${NC}"; sleep 2; return; }
    grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null && { echo -e "${RED}Username sudah ada!${NC}"; sleep 2; return; }
    read -p " Expired (days): " days; [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; return; }
    read -p " Quota (GB)    : " quota; [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p " IP Limit      : " iplimit; [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template "trojan" "$username" "$days" "$quota" "$iplimit"
}

#================================================
# MENU SSH / VMESS / VLESS / TROJAN
#================================================

menu_ssh() {
    while true; do
        clear; print_menu_header "SSH MENU"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Create SSH"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Trial SSH (1 Jam)"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Delete SSH"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Renew SSH"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Cek Login SSH"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "List User SSH"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer; echo ""
        read -p " Select: " choice
        case $choice in
            1) create_ssh ;; 2) create_ssh_trial ;; 3) delete_account "ssh" ;;
            4) renew_account "ssh" ;; 5) check_user_login "ssh" ;; 6) list_accounts "ssh" ;; 0) return ;;
        esac
    done
}

menu_vmess() {
    while true; do
        clear; print_menu_header "VMESS MENU"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Create VMess"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Trial VMess (1 Jam)"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Delete VMess"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Renew VMess"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Cek Login VMess"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "List User VMess"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer; echo ""
        read -p " Select: " choice
        case $choice in
            1) create_vmess ;; 2) create_trial_xray "vmess" ;; 3) delete_account "vmess" ;;
            4) renew_account "vmess" ;; 5) check_user_login "vmess" ;; 6) list_accounts "vmess" ;; 0) return ;;
        esac
    done
}

menu_vless() {
    while true; do
        clear; print_menu_header "VLESS MENU"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Create VLess"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Trial VLess (1 Jam)"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Delete VLess"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Renew VLess"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Cek Login VLess"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "List User VLess"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer; echo ""
        read -p " Select: " choice
        case $choice in
            1) create_vless ;; 2) create_trial_xray "vless" ;; 3) delete_account "vless" ;;
            4) renew_account "vless" ;; 5) check_user_login "vless" ;; 6) list_accounts "vless" ;; 0) return ;;
        esac
    done
}

menu_trojan() {
    while true; do
        clear; print_menu_header "TROJAN MENU"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Create Trojan"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Trial Trojan (1 Jam)"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Delete Trojan"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Renew Trojan"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Cek Login Trojan"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "List User Trojan"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer; echo ""
        read -p " Select: " choice
        case $choice in
            1) create_trojan ;; 2) create_trial_xray "trojan" ;; 3) delete_account "trojan" ;;
            4) renew_account "trojan" ;; 5) check_user_login "trojan" ;; 6) list_accounts "trojan" ;; 0) return ;;
        esac
    done
}

#================================================
# INSTALL UDP CUSTOM
#================================================

install_udp_custom() {
    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select, time

PORTS    = range(7100, 7301)
SSH_HOST = '127.0.0.1'
SSH_PORT = 22
BUF      = 8192
TIMEOUT  = 10

def handle(data, addr, sock):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(TIMEOUT); s.connect((SSH_HOST, SSH_PORT))
        s.sendall(data); resp = s.recv(BUF)
        if resp: sock.sendto(resp, addr)
        s.close()
    except: pass

sockets = []
for port in PORTS:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
        s.bind(('0.0.0.0', port)); s.setblocking(False); sockets.append(s)
    except: pass

print(f'UDP Custom: {len(sockets)} ports (7100-7300)', flush=True)

while True:
    try:
        readable, _, _ = select.select(sockets, [], [], 1.0)
        for sock in readable:
            try:
                data, addr = sock.recvfrom(BUF)
                threading.Thread(target=handle, args=(data, addr, sock), daemon=True).start()
            except: pass
    except KeyboardInterrupt: break
    except: time.sleep(1)
UDPEOF
    chmod +x /usr/local/bin/udp-custom
    cat > /etc/systemd/system/udp-custom.service << 'UDPSVC'
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
}

#================================================
# UPDATE MENU
#================================================

update_menu() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"
    _center_title "UPDATE SCRIPT"
    echo -e "${CYAN}╠${EL}╣${NC}"
    printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : ${GREEN}%-41s${NC}${CYAN}║${NC}\n" "Current Version" "$SCRIPT_VERSION"
    echo -e "${CYAN}╚${EL}╝${NC}"
    echo ""
    echo -e "${CYAN}Checking GitHub for updates...${NC}"
    local latest; latest=$(curl -s --max-time 10 "$VERSION_URL" 2>/dev/null | tr -d '\n\r ' | xargs)
    if [[ -z "$latest" ]]; then
        echo -e "${RED}✗ Cannot connect to GitHub!${NC}"; echo ""; read -p "Press Enter..."; return
    fi
    printf " Latest Version  : ${GREEN}%s${NC}\n" "$latest"
    echo ""
    if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
        echo -e "${GREEN}✓ Sudah versi terbaru!${NC}"; echo ""; read -p "Press Enter..."; return
    fi
    echo -e "${YELLOW}⬆ Update tersedia!${NC}"
    echo ""
    read -p "Update sekarang? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return
    echo ""
    echo -e "${CYAN}[1/4]${NC} Creating backup..."
    cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null && done_msg "Backup created" || { fail_msg "Backup failed!"; read -p "Press Enter..."; return; }
    echo -e "${CYAN}[2/4]${NC} Downloading v${latest}..."
    local tmp="/tmp/tunnel_new.sh"
    curl -L --max-time 60 "$SCRIPT_URL" -o "$tmp" >/dev/null 2>&1
    if [[ ! -s "$tmp" ]]; then
        fail_msg "Download failed!"; cp "$BACKUP_PATH" "$SCRIPT_PATH"; read -p "Press Enter..."; return
    fi
    done_msg "Downloaded"
    echo -e "${CYAN}[3/4]${NC} Validating..."
    bash -n "$tmp" 2>/dev/null && done_msg "Syntax OK" || { fail_msg "Syntax error!"; cp "$BACKUP_PATH" "$SCRIPT_PATH"; rm -f "$tmp"; read -p "Press Enter..."; return; }
    echo -e "${CYAN}[4/4]${NC} Applying..."
    mv "$tmp" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"
    done_msg "Update applied"
    echo ""
    echo -e "${GREEN}✓ UPDATE SUKSES! Restarting in 3 detik...${NC}"
    sleep 3; exec bash "$SCRIPT_PATH"
}

rollback_script() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${CYAN}╔${EL}╗${NC}"; _center_title "ROLLBACK SCRIPT"; echo -e "${CYAN}╚${EL}╝${NC}"; echo ""
    if [[ ! -f "$BACKUP_PATH" ]]; then echo -e "${RED}✗ Tidak ada backup!${NC}"; sleep 2; return; fi
    local backup_ver; backup_ver=$(grep "SCRIPT_VERSION=" "$BACKUP_PATH" 2>/dev/null | head -1 | cut -d'"' -f2)
    printf " Current : ${GREEN}%s${NC}\n" "$SCRIPT_VERSION"
    printf " Backup  : ${YELLOW}%s${NC}\n" "${backup_ver:-Unknown}"
    echo ""
    read -p "Rollback? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return
    cp "$BACKUP_PATH" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}✓ Rollback sukses!${NC}"; sleep 2; exec bash "$SCRIPT_PATH"
}

#================================================
# ADVANCED MENU - LENGKAP
#================================================

menu_advanced() {
    while true; do
        clear
        local EL=$(printf '═%.0s' $(seq 1 $W))
        echo -e "${CYAN}╔${EL}╗${NC}"
        _center_title "⚙️  ADVANCED SETTINGS"
        echo -e "${CYAN}╠${EL}╣${NC}"
        echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC}  %-28s  ${CYAN}[7]${NC}  %-25s${CYAN}║${NC}\n" "Port Management"      "Firewall / UFW"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC}  %-28s  ${CYAN}[8]${NC}  %-25s${CYAN}║${NC}\n" "Protocol Settings"    "Bandwidth Monitor"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC}  %-28s  ${CYAN}[9]${NC}  %-25s${CYAN}║${NC}\n" "Auto Backup Config"   "User Limits"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC}  %-28s  ${CYAN}[10]${NC} %-25s${CYAN}║${NC}\n" "SSH Brute Protection" "Custom Cron Jobs"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC}  %-28s  ${CYAN}[11]${NC} %-25s${CYAN}║${NC}\n" "Fail2Ban Setup"       "System Logs"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC}  %-28s  ${CYAN}[12]${NC} %-25s${CYAN}║${NC}\n" "DDoS Protection"      "Process Monitor"
        echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC}  %-62s${CYAN}║${NC}\n" "Back to Main Menu"
        echo -e "${CYAN}╚${EL}╝${NC}"
        echo ""
        read -p " Select [0-12]: " choice
        case $choice in
            1)  _adv_port_management ;;
            2)  _adv_protocol_settings ;;
            3)  _adv_auto_backup ;;
            4)  _adv_ssh_brute_protection ;;
            5)  _adv_fail2ban ;;
            6)  _adv_ddos_protection ;;
            7)  _adv_firewall ;;
            8)  _adv_bandwidth_monitor ;;
            9)  _adv_user_limits ;;
            10) _adv_cron_jobs ;;
            11) _adv_system_logs ;;
            12) _adv_process_monitor ;;
            0)  return ;;
        esac
    done
}

# [1] Port Management
_adv_port_management() {
    clear
    print_menu_header "PORT MANAGEMENT"
    echo ""
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "SSH"                  "22"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Dropbear"             "222"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Nginx NonTLS"         "80"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Nginx Download"       "81"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "HAProxy TLS"          "443"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Xray Internal TLS"   "8443"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Xray Internal NonTLS" "8080"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "Xray gRPC"            "8444"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : ${GREEN}%-28s${NC}${CYAN}║${NC}\n" "BadVPN UDP"           "7100-7300"
    print_menu_footer
    echo ""
    echo -e "${YELLOW}Ganti Port Dropbear:${NC}"
    read -p " Port baru Dropbear (enter=skip): " dp
    if [[ "$dp" =~ ^[0-9]+$ ]] && [[ "$dp" -gt 1 ]] && [[ "$dp" -lt 65535 ]]; then
        sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=${dp}/" /etc/default/dropbear 2>/dev/null
        systemctl restart dropbear 2>/dev/null
        echo -e "${GREEN}Dropbear port diubah ke ${dp}${NC}"
    fi
    echo ""
    read -p "Press any key to back..."
}

# [2] Protocol Settings
_adv_protocol_settings() {
    clear
    print_menu_header "PROTOCOL SETTINGS"
    echo ""
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "VMess WS Path"        "/vmess"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "VLess WS Path"        "/vless"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "Trojan WS Path"       "/trojan"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "VMess gRPC Service"   "vmess-grpc"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "VLess gRPC Service"   "vless-grpc"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "Trojan gRPC Service"  "trojan-grpc"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "TLS Cert"             "/etc/xray/xray.crt"
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "TLS Key"              "/etc/xray/xray.key"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Ganti WS Path Semua Protocol"
    echo -e "${CYAN}[2]${NC} Lihat Xray Config (raw)"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            read -p " Path baru (tanpa /): " newpath
            [[ -z "$newpath" ]] && return
            local tmp; tmp=$(mktemp)
            jq --arg p "/${newpath}" '(.inbounds[] | select(.streamSettings.network=="ws") | .streamSettings.wsSettings.path) = $p' \
               "$XRAY_CONFIG" > "$tmp" 2>/dev/null && mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
            systemctl restart xray 2>/dev/null
            echo -e "${GREEN}Path diubah ke /${newpath}${NC}"
            sleep 2
            ;;
        2)
            clear; cat "$XRAY_CONFIG" 2>/dev/null | head -80
            echo ""; read -p "Press any key..."
            ;;
    esac
}

# [3] Auto Backup Config
_adv_auto_backup() {
    clear
    print_menu_header "AUTO BACKUP CONFIG"
    echo ""
    local backup_dir="/root/backups"
    local cron_job="0 3 * * * tar -czf ${backup_dir}/vpn-backup-\$(date +\%Y\%m\%d).tar.gz /root/akun /root/domain /usr/local/etc/xray/config.json /etc/xray/ 2>/dev/null && find ${backup_dir} -name '*.tar.gz' -mtime +7 -delete"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Backup otomatis setiap hari jam 03:00"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Simpan di: /root/backups/"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "File > 7 hari otomatis dihapus"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Aktifkan Auto Backup (Cron)"
    echo -e "${CYAN}[2]${NC} Nonaktifkan Auto Backup"
    echo -e "${CYAN}[3]${NC} Backup Manual Sekarang"
    echo -e "${CYAN}[4]${NC} Lihat Riwayat Backup"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            mkdir -p "$backup_dir"
            (crontab -l 2>/dev/null | grep -v "vpn-backup"; echo "$cron_job") | crontab -
            echo -e "${GREEN}Auto backup aktif! Setiap hari jam 03:00${NC}"
            sleep 2
            ;;
        2)
            crontab -l 2>/dev/null | grep -v "vpn-backup" | crontab -
            echo -e "${YELLOW}Auto backup dinonaktifkan!${NC}"
            sleep 2
            ;;
        3)
            mkdir -p "$backup_dir"
            local fname="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
            tar -czf "${backup_dir}/${fname}" /root/akun /root/domain \
                /usr/local/etc/xray/config.json /etc/xray/ 2>/dev/null
            echo -e "${GREEN}Backup selesai: ${fname}${NC}"
            sleep 2
            ;;
        4)
            clear; print_menu_header "RIWAYAT BACKUP"; echo ""
            ls -lh "$backup_dir"/*.tar.gz 2>/dev/null || echo -e "${YELLOW}Belum ada backup${NC}"
            echo ""; read -p "Press any key..."
            ;;
    esac
}

# [4] SSH Brute Force Protection
_adv_ssh_brute_protection() {
    clear
    print_menu_header "SSH BRUTE FORCE PROTECTION"
    echo ""
    local status; status=$(iptables -L INPUT -n 2>/dev/null | grep -c "ssh\|22" || echo 0)
    printf "${CYAN}║${NC}  ${WHITE}%-30s${NC} : %-29s${CYAN}║${NC}\n" "Status Rule SSH" "${status} rules aktif"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Limit: max 4 koneksi SSH per menit per IP"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Aktifkan Brute Protection (iptables)"
    echo -e "${CYAN}[2]${NC} Nonaktifkan Brute Protection"
    echo -e "${CYAN}[3]${NC} Lihat IP yang Terblokir"
    echo -e "${CYAN}[4]${NC} Unban IP Tertentu"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            iptables -I INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent --set 2>/dev/null
            iptables -I INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP 2>/dev/null
            iptables -I INPUT -p tcp --dport 222 -i eth0 -m state --state NEW -m recent --set 2>/dev/null
            iptables -I INPUT -p tcp --dport 222 -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP 2>/dev/null
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
            echo -e "${GREEN}Brute force protection aktif!${NC}"
            sleep 2
            ;;
        2)
            iptables -D INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent --set 2>/dev/null
            iptables -D INPUT -p tcp --dport 22 -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP 2>/dev/null
            echo -e "${YELLOW}Brute force protection dinonaktifkan!${NC}"
            sleep 2
            ;;
        3)
            clear; echo -e "${WHITE}IP Terblokir:${NC}"; echo ""
            cat /proc/net/xt_recent/DEFAULT 2>/dev/null | awk '{print $1}' | grep -v "^#" || echo "Tidak ada"
            echo ""; read -p "Press any key..."
            ;;
        4)
            read -p " IP yang akan di-unban: " ip
            [[ -z "$ip" ]] && return
            echo "/$ip/" > /proc/net/xt_recent/DEFAULT 2>/dev/null
            iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            echo -e "${GREEN}IP ${ip} di-unban!${NC}"; sleep 2
            ;;
    esac
}

# [5] Fail2Ban Setup
_adv_fail2ban() {
    clear
    print_menu_header "FAIL2BAN SETUP"
    echo ""
    local f2b_status; command -v fail2ban-client >/dev/null 2>&1 && f2b_status="${GREEN}Terinstall${NC}" || f2b_status="${RED}Belum Terinstall${NC}"
    printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41b${CYAN}║${NC}\n" "Status Fail2Ban" "$f2b_status"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Blokir otomatis IP yang gagal login berkali-kali"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Install & Setup Fail2Ban"
    echo -e "${CYAN}[2]${NC} Lihat Status Fail2Ban"
    echo -e "${CYAN}[3]${NC} Lihat IP yang Diblokir"
    echo -e "${CYAN}[4]${NC} Unban IP Tertentu"
    echo -e "${CYAN}[5]${NC} Restart Fail2Ban"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            echo -e "${CYAN}Installing fail2ban...${NC}"
            apt-get install -y fail2ban >/dev/null 2>&1
            cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled  = true
port     = 22,222
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 7200

[dropbear]
enabled  = true
port     = 22,222
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
F2BEOF
            systemctl enable fail2ban 2>/dev/null
            systemctl restart fail2ban 2>/dev/null
            echo -e "${GREEN}Fail2Ban terinstall dan aktif!${NC}"
            sleep 2
            ;;
        2)
            clear; fail2ban-client status 2>/dev/null || echo "Fail2Ban tidak berjalan"
            echo ""; read -p "Press any key..."
            ;;
        3)
            clear; fail2ban-client status sshd 2>/dev/null || echo "Tidak ada data"
            echo ""; read -p "Press any key..."
            ;;
        4)
            read -p " IP yang akan di-unban: " ip
            [[ -z "$ip" ]] && return
            fail2ban-client set sshd unbanip "$ip" 2>/dev/null
            echo -e "${GREEN}IP ${ip} di-unban!${NC}"; sleep 2
            ;;
        5)
            systemctl restart fail2ban 2>/dev/null
            echo -e "${GREEN}Fail2Ban di-restart!${NC}"; sleep 2
            ;;
    esac
}

# [6] DDoS Protection
_adv_ddos_protection() {
    clear
    print_menu_header "DDOS PROTECTION"
    echo ""
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Rate limiting via iptables untuk proteksi DDoS dasar"
    printf "${CYAN}║${NC}  %-62s${CYAN}║${NC}\n" "Limit: 100 koneksi baru per IP per menit"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Aktifkan DDoS Protection"
    echo -e "${CYAN}[2]${NC} Nonaktifkan DDoS Protection"
    echo -e "${CYAN}[3]${NC} Lihat Status Rules"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            # SYN flood protection
            iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 4 -j ACCEPT 2>/dev/null
            iptables -A INPUT -p tcp --syn -j DROP 2>/dev/null
            # ICMP flood
            iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 4 -j ACCEPT 2>/dev/null
            iptables -A INPUT -p icmp --icmp-type echo-request -j DROP 2>/dev/null
            # Connection limit per IP
            iptables -A INPUT -p tcp -m connlimit --connlimit-above 100 -j REJECT --reject-with tcp-reset 2>/dev/null
            # New connection rate limit
            iptables -A INPUT -p tcp -m state --state NEW -m limit --limit 100/minute --limit-burst 200 -j ACCEPT 2>/dev/null
            iptables -A INPUT -p tcp -m state --state NEW -j DROP 2>/dev/null
            # Enable SYN cookies
            echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
            echo -e "${GREEN}DDoS protection aktif!${NC}"; sleep 2
            ;;
        2)
            iptables -F INPUT 2>/dev/null
            iptables -P INPUT ACCEPT 2>/dev/null
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
            echo -e "${YELLOW}DDoS protection dinonaktifkan! Semua rule INPUT dihapus.${NC}"; sleep 3
            ;;
        3)
            clear; iptables -L INPUT -n --line-numbers 2>/dev/null
            echo ""; read -p "Press any key..."
            ;;
    esac
}

# [7] Firewall / UFW
_adv_firewall() {
    clear
    print_menu_header "FIREWALL / UFW"
    echo ""
    if command -v ufw >/dev/null 2>&1; then
        local ufw_status; ufw_status=$(ufw status | head -1)
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41s${CYAN}║${NC}\n" "UFW Status" "$ufw_status"
        print_menu_footer
        echo ""
        echo -e "${CYAN}[1]${NC} Aktifkan UFW dengan rule VPN"
        echo -e "${CYAN}[2]${NC} Nonaktifkan UFW"
        echo -e "${CYAN}[3]${NC} Lihat Rules UFW"
        echo -e "${CYAN}[4]${NC} Tambah Rule Custom"
        echo -e "${CYAN}[5]${NC} Hapus Rule"
        echo -e "${CYAN}[0]${NC} Kembali"
        echo ""
        read -p " Select: " c
        case $c in
            1)
                ufw --force reset >/dev/null 2>&1
                ufw default deny incoming >/dev/null 2>&1
                ufw default allow outgoing >/dev/null 2>&1
                ufw allow 22/tcp >/dev/null 2>&1
                ufw allow 80/tcp >/dev/null 2>&1
                ufw allow 81/tcp >/dev/null 2>&1
                ufw allow 222/tcp >/dev/null 2>&1
                ufw allow 443/tcp >/dev/null 2>&1
                ufw allow 8443/tcp >/dev/null 2>&1
                ufw allow 8080/tcp >/dev/null 2>&1
                ufw allow 8444/tcp >/dev/null 2>&1
                ufw allow 7100:7300/udp >/dev/null 2>&1
                ufw --force enable >/dev/null 2>&1
                echo -e "${GREEN}UFW aktif dengan rule VPN!${NC}"; sleep 2
                ;;
            2) ufw disable; sleep 2 ;;
            3) clear; ufw status numbered; echo ""; read -p "Press any key..." ;;
            4)
                read -p " Port: " port; read -p " Protokol (tcp/udp): " proto
                ufw allow "${port}/${proto}" 2>/dev/null
                echo -e "${GREEN}Rule ditambahkan!${NC}"; sleep 2
                ;;
            5)
                ufw status numbered; echo ""
                read -p " Nomor rule yang dihapus: " num
                [[ "$num" =~ ^[0-9]+$ ]] && ufw --force delete "$num" 2>/dev/null
                echo -e "${GREEN}Rule dihapus!${NC}"; sleep 2
                ;;
        esac
    else
        print_menu_footer
        echo ""
        read -p " Install UFW? [y/N]: " c
        [[ "$c" == "y" ]] && { apt-get install -y ufw >/dev/null 2>&1; echo -e "${GREEN}UFW terinstall!${NC}"; sleep 2; }
    fi
}

# [8] Bandwidth Monitor
_adv_bandwidth_monitor() {
    while true; do
        clear
        print_menu_header "BANDWIDTH MONITOR"
        echo ""
        local iface; iface=$(ip route | awk '/default/{print $5; exit}')
        local rx_bytes tx_bytes
        rx_bytes=$(cat /sys/class/net/${iface}/statistics/rx_bytes 2>/dev/null || echo 0)
        tx_bytes=$(cat /sys/class/net/${iface}/statistics/tx_bytes 2>/dev/null || echo 0)
        local rx_mb=$(( rx_bytes / 1048576 ))
        local tx_mb=$(( tx_bytes / 1048576 ))
        local rx_gb=$(awk "BEGIN {printf \"%.2f\", $rx_bytes/1073741824}")
        local tx_gb=$(awk "BEGIN {printf \"%.2f\", $tx_bytes/1073741824}")
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41s${CYAN}║${NC}\n" "Interface" "$iface"
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : ${GREEN}%-41s${NC}${CYAN}║${NC}\n" "Total Download" "${rx_mb} MB (${rx_gb} GB)"
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : ${YELLOW}%-41s${NC}${CYAN}║${NC}\n" "Total Upload"   "${tx_mb} MB (${tx_gb} GB)"
        echo ""
        # Live speed sample
        local rx1 tx1 rx2 tx2
        rx1=$(cat /sys/class/net/${iface}/statistics/rx_bytes 2>/dev/null || echo 0)
        tx1=$(cat /sys/class/net/${iface}/statistics/tx_bytes 2>/dev/null || echo 0)
        sleep 1
        rx2=$(cat /sys/class/net/${iface}/statistics/rx_bytes 2>/dev/null || echo 0)
        tx2=$(cat /sys/class/net/${iface}/statistics/tx_bytes 2>/dev/null || echo 0)
        local dl_speed=$(( (rx2 - rx1) / 1024 ))
        local ul_speed=$(( (tx2 - tx1) / 1024 ))
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : ${GREEN}%-41s${NC}${CYAN}║${NC}\n" "Download Speed" "${dl_speed} KB/s"
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : ${YELLOW}%-41s${NC}${CYAN}║${NC}\n" "Upload Speed"   "${ul_speed} KB/s"
        print_menu_footer
        echo ""
        echo -e "${YELLOW}Auto refresh 5 detik. Tekan CTRL+C atau ketik 'q' untuk keluar.${NC}"
        read -t 5 -p " " input
        [[ "$input" == "q" ]] && break
    done
}

# [9] User Limits
_adv_user_limits() {
    clear
    print_menu_header "USER LIMITS"
    echo ""
    local cur_limit; cur_limit=$(ulimit -n)
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : %-33s${CYAN}║${NC}\n" "Current nofile limit" "$cur_limit"
    printf "${CYAN}║${NC}  ${WHITE}%-28s${NC} : %-33s${CYAN}║${NC}\n" "Config file" "/etc/security/limits.d/99-vpn.conf"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Set nofile limit custom"
    echo -e "${CYAN}[2]${NC} Apply limit 65535 (recommended)"
    echo -e "${CYAN}[3]${NC} Lihat user yang login"
    echo -e "${CYAN}[4]${NC} Lihat proses per user"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            read -p " Masukkan limit baru: " lim
            [[ ! "$lim" =~ ^[0-9]+$ ]] && return
            cat > /etc/security/limits.d/99-vpn.conf << LIMEOF
* soft nofile ${lim}
* hard nofile ${lim}
root soft nofile ${lim}
root hard nofile ${lim}
LIMEOF
            echo -e "${GREEN}Limit diubah ke ${lim}. Re-login untuk efektif.${NC}"; sleep 2
            ;;
        2)
            optimize_vpn
            echo -e "${GREEN}Limit 65535 diterapkan!${NC}"; sleep 2
            ;;
        3)
            clear; who; echo ""; w; echo ""; read -p "Press any key..."
            ;;
        4)
            clear; ps aux --sort=-%cpu | head -20; echo ""; read -p "Press any key..."
            ;;
    esac
}

# [10] Cron Jobs
_adv_cron_jobs() {
    clear
    print_menu_header "CRON JOBS"
    echo ""
    crontab -l 2>/dev/null || echo -e "${YELLOW}  Belum ada cron job${NC}"
    print_menu_footer
    echo ""
    echo -e "${CYAN}[1]${NC} Tambah cron job"
    echo -e "${CYAN}[2]${NC} Hapus semua cron job"
    echo -e "${CYAN}[3]${NC} Tambah auto delete expired (jam 01:00)"
    echo -e "${CYAN}[0]${NC} Kembali"
    echo ""
    read -p " Select: " c
    case $c in
        1)
            read -p " Cron expression (mis: 0 3 * * *): " expr
            read -p " Command: " cmd
            [[ -z "$expr" || -z "$cmd" ]] && return
            (crontab -l 2>/dev/null; echo "$expr $cmd") | crontab -
            echo -e "${GREEN}Cron job ditambahkan!${NC}"; sleep 2
            ;;
        2)
            read -p " Yakin hapus semua? [y/N]: " con
            [[ "$con" == "y" ]] && { crontab -r 2>/dev/null; echo -e "${GREEN}Semua cron dihapus!${NC}"; sleep 2; }
            ;;
        3)
            local auto_del="0 1 * * * bash /root/tunnel.sh delete_expired_cron 2>/dev/null"
            (crontab -l 2>/dev/null | grep -v "delete_expired_cron"; echo "$auto_del") | crontab -
            echo -e "${GREEN}Auto delete expired aktif (jam 01:00 tiap hari)!${NC}"; sleep 2
            ;;
    esac
}

# [11] System Logs
_adv_system_logs() {
    while true; do
        clear
        print_menu_header "SYSTEM LOGS"
        echo ""
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Xray Access Log"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Xray Error Log"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Nginx Error Log"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "SSH Auth Log"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "System Journal (journalctl)"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "HAProxy Log"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Kembali"
        print_menu_footer
        echo ""
        read -p " Select: " c
        case $c in
            1) clear; echo -e "${WHITE}=== Xray Access Log (Last 50) ===${NC}"; tail -50 /var/log/xray/access.log 2>/dev/null || echo "No log"; echo ""; read -p "Press any key..." ;;
            2) clear; echo -e "${WHITE}=== Xray Error Log (Last 50) ===${NC}"; tail -50 /var/log/xray/error.log 2>/dev/null || echo "No log"; echo ""; read -p "Press any key..." ;;
            3) clear; echo -e "${WHITE}=== Nginx Error Log ===${NC}"; tail -50 /var/log/nginx/error.log 2>/dev/null || echo "No log"; echo ""; read -p "Press any key..." ;;
            4) clear; echo -e "${WHITE}=== SSH Auth Log ===${NC}"; tail -50 /var/log/auth.log 2>/dev/null || echo "No log"; echo ""; read -p "Press any key..." ;;
            5) clear; journalctl -n 80 --no-pager; echo ""; read -p "Press any key..." ;;
            6) clear; echo -e "${WHITE}=== HAProxy Log ===${NC}"; journalctl -u haproxy -n 50 --no-pager; echo ""; read -p "Press any key..." ;;
            0) return ;;
        esac
    done
}

# [12] Process Monitor
_adv_process_monitor() {
    while true; do
        clear
        print_menu_header "PROCESS MONITOR"
        echo ""
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41s${CYAN}║${NC}\n" "Memory" "$(free -h | awk 'NR==2{print $3"/"$2}')"
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41s${CYAN}║${NC}\n" "CPU Core" "$(nproc)"
        printf "${CYAN}║${NC}  ${WHITE}%-20s${NC} : %-41s${CYAN}║${NC}\n" "Load Avg" "$(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        echo -e "${CYAN}== Top 10 Proses (CPU) ==${NC}"
        ps aux --sort=-%cpu | head -11 | tail -10 | awk '{printf " %-10s %5s%% %5s%% %s\n", $1, $3, $4, $11}'
        print_menu_footer
        echo ""
        echo -e "${YELLOW}Auto refresh 5 detik. Ketik 'q' untuk keluar.${NC}"
        read -t 5 -p " " input
        [[ "$input" == "q" ]] && break
    done
}

#================================================
# UNINSTALL MENU
#================================================

menu_uninstall() {
    while true; do
        clear
        print_menu_header "UNINSTALL MENU"
        printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "Uninstall Xray"
        printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "Uninstall Nginx"
        printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Uninstall HAProxy"
        printf "${CYAN}║${NC}  ${CYAN}[4]${NC} %-60s${CYAN}║${NC}\n" "Uninstall Dropbear"
        printf "${CYAN}║${NC}  ${CYAN}[5]${NC} %-60s${CYAN}║${NC}\n" "Uninstall UDP Custom"
        printf "${CYAN}║${NC}  ${CYAN}[6]${NC} %-60s${CYAN}║${NC}\n" "Uninstall Bot Telegram"
        printf "${CYAN}║${NC}  ${CYAN}[7]${NC} %-60s${CYAN}║${NC}\n" "Uninstall Keepalive"
        printf "${CYAN}║${NC}  ${RED}[8]${NC} ${RED}%-60s${NC}${CYAN}║${NC}\n" "HAPUS SEMUA SCRIPT"
        printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back To Menu"
        print_menu_footer
        echo ""
        read -p " Select: " choice
        case $choice in
            1) _uninstall_xray ;;     2) _uninstall_nginx ;;
            3) _uninstall_haproxy ;;  4) _uninstall_dropbear ;;
            5) _uninstall_udp ;;      6) _uninstall_bot ;;
            7) _uninstall_keepalive ;; 8) _uninstall_all ;;
            0) return ;;
        esac
    done
}

_uninstall_xray() {
    clear; print_menu_header "UNINSTALL XRAY"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop xray 2>/dev/null; systemctl disable xray 2>/dev/null
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray
    rm -f "$AKUN_DIR"/vmess-*.txt "$AKUN_DIR"/vless-*.txt "$AKUN_DIR"/trojan-*.txt
    echo -e "${GREEN}Xray uninstalled!${NC}"; sleep 2
}

_uninstall_nginx() {
    clear; print_menu_header "UNINSTALL NGINX"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop nginx 2>/dev/null; systemctl disable nginx 2>/dev/null
    apt-get purge -y nginx nginx-common >/dev/null 2>&1; apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}Nginx uninstalled!${NC}"; sleep 2
}

_uninstall_haproxy() {
    clear; print_menu_header "UNINSTALL HAPROXY"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop haproxy 2>/dev/null; systemctl disable haproxy 2>/dev/null
    apt-get purge -y haproxy >/dev/null 2>&1; apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}HAProxy uninstalled!${NC}"; sleep 2
}

_uninstall_dropbear() {
    clear; print_menu_header "UNINSTALL DROPBEAR"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop dropbear 2>/dev/null; systemctl disable dropbear 2>/dev/null
    apt-get purge -y dropbear >/dev/null 2>&1; apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}Dropbear uninstalled!${NC}"; sleep 2
}

_uninstall_udp() {
    clear; print_menu_header "UNINSTALL UDP"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop udp-custom 2>/dev/null; systemctl disable udp-custom 2>/dev/null
    rm -f /etc/systemd/system/udp-custom.service /usr/local/bin/udp-custom
    systemctl daemon-reload; echo -e "${GREEN}UDP uninstalled!${NC}"; sleep 2
}

_uninstall_bot() {
    clear; print_menu_header "UNINSTALL BOT"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop vpn-bot 2>/dev/null; systemctl disable vpn-bot 2>/dev/null
    rm -f /etc/systemd/system/vpn-bot.service; rm -rf /root/bot
    rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"
    systemctl daemon-reload; echo -e "${GREEN}Bot uninstalled!${NC}"; sleep 2
}

_uninstall_keepalive() {
    clear; print_menu_header "UNINSTALL KEEPALIVE"; echo ""
    read -p " Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return
    systemctl stop vpn-keepalive 2>/dev/null; systemctl disable vpn-keepalive 2>/dev/null
    rm -f /etc/systemd/system/vpn-keepalive.service /usr/local/bin/vpn-keepalive.sh
    systemctl daemon-reload; echo -e "${GREEN}Keepalive uninstalled!${NC}"; sleep 2
}

_uninstall_all() {
    clear
    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo -e "${RED}╔${EL}╗${NC}"
    _center_title "!! HAPUS SEMUA SCRIPT !!" "$RED"
    echo -e "${RED}╠${EL}╣${NC}"
    printf "${RED}║${NC}  ${YELLOW}%-62s${RED}║${NC}\n" "Akan menghapus SEMUA komponen VPN!"
    echo -e "${RED}╚${EL}╝${NC}"
    echo ""
    read -p " Ketik 'HAPUS' untuk konfirmasi: " confirm
    [[ "$confirm" != "HAPUS" ]] && { echo -e "${YELLOW}Dibatalkan.${NC}"; sleep 2; return; }
    echo ""
    for svc in xray nginx haproxy dropbear udp-custom vpn-keepalive vpn-bot; do
        systemctl stop "$svc" 2>/dev/null; systemctl disable "$svc" 2>/dev/null
        printf "  ${RED}-${NC} Stopped: %s\n" "$svc"
    done
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
    apt-get purge -y nginx haproxy dropbear >/dev/null 2>&1; apt-get autoremove -y >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray /root/akun /root/bot /root/orders \
           /root/domain /root/.domain_type /root/.bot_token /root/.chat_id /root/.payment_info \
           /root/.script_expiry /root/tunnel.sh.bak
    rm -f /etc/systemd/system/udp-custom.service /etc/systemd/system/vpn-keepalive.service \
          /etc/systemd/system/vpn-bot.service /usr/local/bin/udp-custom \
          /usr/local/bin/vpn-keepalive.sh /usr/local/bin/menu /root/tunnel.sh
    sed -i '/tunnel.sh/d' /root/.bashrc 2>/dev/null
    systemctl daemon-reload
    echo ""; echo -e "${GREEN}Semua script dihapus!${NC}"; sleep 3; exit 0
}

#================================================
# HELPER: LIST ALL, BACKUP, RESTORE, HELP
#================================================

_menu_list_all() {
    clear
    print_menu_header "ALL ACCOUNTS"
    echo ""
    local total=0
    shopt -s nullglob
    for proto in ssh vmess vless trojan; do
        local files=("$AKUN_DIR"/${proto}-*.txt)
        [[ ${#files[@]} -eq 0 ]] && continue
        printf "${CYAN}║${NC}  ${GREEN}▌ ${proto^^} ACCOUNTS${NC}$(printf '%*s' $((49-${#proto})) '')${CYAN}║${NC}\n"
        for f in "${files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed "s/${proto}-//")
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            printf "${CYAN}║${NC}   ${CYAN}•${NC} %-24s ${YELLOW}%-34s${NC}${CYAN}║${NC}\n" "$uname" "$exp"
            ((total++))
        done
        echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    done
    shopt -u nullglob
    print_menu_footer
    echo ""
    echo -e " ${WHITE}Total Accounts: ${GREEN}${total}${NC}"
    echo ""
    read -p "Press any key to back..."
}

_menu_backup() {
    clear
    print_menu_header "BACKUP SYSTEM"
    echo ""
    local backup_dir="/root/backups"
    local backup_file="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$backup_dir"
    tar -czf "$backup_dir/$backup_file" \
        /root/domain /root/.domain_type /root/akun \
        /root/.bot_token /root/.chat_id /root/.payment_info \
        /root/.script_expiry \
        /etc/xray/xray.crt /etc/xray/xray.key \
        /usr/local/etc/xray/config.json 2>/dev/null
    if [[ -f "$backup_dir/$backup_file" ]]; then
        echo -e "${GREEN}✓ Backup created!${NC}"
        printf " File : ${WHITE}%s${NC}\n" "$backup_file"
        printf " Size : ${CYAN}%s${NC}\n" "$(du -h "$backup_dir/$backup_file" | awk '{print $1}')"
        printf " Path : ${YELLOW}%s${NC}\n" "$backup_dir/$backup_file"
    else
        echo -e "${RED}✗ Backup failed!${NC}"
    fi
    echo ""; read -p "Press any key to back..."
}

_menu_restore() {
    clear
    print_menu_header "RESTORE SYSTEM"
    echo ""
    local backup_dir="/root/backups"
    [[ ! -d "$backup_dir" ]] && { echo -e "${RED}No backup directory!${NC}"; sleep 2; return; }
    shopt -s nullglob
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob
    if [[ ${#backups[@]} -eq 0 ]]; then echo -e "${RED}No backups found!${NC}"; sleep 2; return; fi
    local i=1
    for backup in "${backups[@]}"; do
        printf " ${CYAN}[%d]${NC} %-40s ${YELLOW}%s${NC}\n" "$i" "$(basename "$backup")" "$(du -h "$backup" | awk '{print $1}')"
        ((i++))
    done
    echo ""
    read -p " Select [1-${#backups[@]}] atau 0 cancel: " choice
    [[ "$choice" == "0" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#backups[@]}" ]] && return
    local selected="${backups[$((choice-1))]}"
    echo ""
    read -p " Overwrite config sekarang? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return
    tar -xzf "$selected" -C / 2>/dev/null && {
        echo -e "${GREEN}✓ Restore berhasil!${NC}"
        systemctl restart xray nginx haproxy 2>/dev/null
    } || echo -e "${RED}✗ Restore gagal!${NC}"
    echo ""; read -p "Press any key to back..."
}

_show_help() {
    clear
    print_menu_header "COMMAND GUIDE"
    echo ""
    printf "${CYAN}║${NC}  ${WHITE}%-62s${NC}${CYAN}║${NC}\n" "Account Management:"
    printf "${CYAN}║${NC}  ${CYAN}1-4${NC}   %-58s${CYAN}║${NC}\n" "Create/manage protocol accounts"
    printf "${CYAN}║${NC}  ${CYAN}5${NC}     %-58s${CYAN}║${NC}\n" "Generate trial accounts (1 hour)"
    printf "${CYAN}║${NC}  ${CYAN}6${NC}     %-58s${CYAN}║${NC}\n" "List all accounts"
    printf "${CYAN}║${NC}  ${CYAN}7-8${NC}   %-58s${CYAN}║${NC}\n" "Check/delete expired accounts"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    printf "${CYAN}║${NC}  ${WHITE}%-62s${NC}${CYAN}║${NC}\n" "System Tools:"
    printf "${CYAN}║${NC}  ${CYAN}9${NC}     %-58s${CYAN}║${NC}\n" "Telegram bot management"
    printf "${CYAN}║${NC}  ${CYAN}10${NC}    %-58s${CYAN}║${NC}\n" "Change domain name"
    printf "${CYAN}║${NC}  ${CYAN}11${NC}    %-58s${CYAN}║${NC}\n" "Fix/renew SSL certificate"
    printf "${CYAN}║${NC}  ${CYAN}12${NC}    %-58s${CYAN}║${NC}\n" "Optimize VPS settings"
    printf "${CYAN}║${NC}  ${CYAN}13${NC}    %-58s${CYAN}║${NC}\n" "Restart all services"
    printf "${CYAN}║${NC}  ${CYAN}14${NC}    %-58s${CYAN}║${NC}\n" "View port information"
    printf "${CYAN}║${NC}  ${CYAN}15${NC}    %-58s${CYAN}║${NC}\n" "Run speedtest (Ookla)"
    printf "${CYAN}║${NC}  ${CYAN}16${NC}    %-58s${CYAN}║${NC}\n" "Update script from GitHub"
    printf "${CYAN}║${NC}  ${CYAN}17-18${NC} %-58s${CYAN}║${NC}\n" "Backup & restore system"
    printf "${CYAN}║${NC}  ${CYAN}19${NC}    %-58s${CYAN}║${NC}\n" "Uninstall menu"
    printf "${CYAN}║${NC}  ${CYAN}20${NC}    %-58s${CYAN}║${NC}\n" "Kelola expiry script"
    echo -e "${CYAN}║${NC}$(printf ' %-64s ' "")${CYAN}║${NC}"
    printf "${CYAN}║${NC}  ${CYAN}99${NC}    %-58s${CYAN}║${NC}\n" "Advanced settings menu"
    printf "${CYAN}║${NC}  ${CYAN}0${NC}     %-58s${CYAN}║${NC}\n" "Exit program"
    printf "${CYAN}║${NC}  ${CYAN}help${NC}  %-58s${CYAN}║${NC}\n" "Show this help screen"
    print_menu_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# AUTO INSTALL
#================================================

auto_install() {
    show_install_banner
    setup_domain
    [[ -z "$DOMAIN" ]] && { echo -e "${RED}Domain kosong!${NC}"; exit 1; }

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")

    clear; show_install_banner
    printf " Domain   : ${GREEN}%s${NC}\n" "$DOMAIN"
    printf " SSL Type : ${GREEN}%s${NC}\n" "$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")"
    echo ""; sleep 1

    local total=10 step=0 LOG="/tmp/install.log"
    > "$LOG"

    _ok()   { printf "  ${GREEN}[✓]${NC} %-42s\n" "$1"; }
    _fail() { printf "  ${RED}[✗]${NC} %-42s\n" "$1"; }
    _head() {
        local txt="$1"; local len=${#txt}
        local line; line=$(printf '─%.0s' $(seq 1 50))
        echo ""; echo -e "  ${CYAN}┌${line}┐${NC}"
        printf "  ${CYAN}│${NC}%*s${WHITE}%s${NC}%*s${CYAN}│${NC}\n" $(( (50-len)/2 )) "" "$txt" $(( 50-len-(50-len)/2 )) ""
        echo -e "  ${CYAN}└${line}┘${NC}"; echo ""
    }
    _pkg() {
        local pkg="$1"; local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'); local i=0
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >> "$LOG" 2>&1 &
        local pid=$!
        while kill -0 $pid 2>/dev/null; do
            printf "\r  ${CYAN}[%s]${NC} Installing %-30s" "${spin[$((i % 10))]}" "${pkg}..."
            sleep 0.1; ((i++))
        done
        wait $pid
        [[ $? -eq 0 ]] && printf "\r  ${GREEN}[✓]${NC} %-42s\n" "$pkg" || printf "\r  ${RED}[✗]${NC} %-42s\n" "$pkg failed"
    }
    _run() {
        local label="$1" cmd="$2"; local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏'); local i=0
        eval "$cmd" >> "$LOG" 2>&1 &
        local pid=$!
        while kill -0 $pid 2>/dev/null; do
            printf "\r  ${CYAN}[%s]${NC} %-42s" "${spin[$((i % 10))]}" "${label}..."
            sleep 0.1; ((i++))
        done
        wait $pid; local ret=$?
        [[ $ret -eq 0 ]] && printf "\r  ${GREEN}[✓]${NC} %-42s\n" "$label" || printf "\r  ${RED}[✗]${NC} %-42s\n" "$label failed"
        return $ret
    }

    ((step++)); show_progress $step $total "System update..."
    _head "STEP 1 / 10 — System Update"
    _run "apt-get update" "apt-get update -y"
    _run "apt-get upgrade" "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"

    ((step++)); show_progress $step $total "Installing base packages..."
    _head "STEP 2 / 10 — Base Packages"
    for pkg in curl wget unzip uuid-runtime net-tools openssl jq qrencode iptables-persistent python3 python3-pip; do _pkg "$pkg"; done

    ((step++)); show_progress $step $total "Installing VPN services..."
    _head "STEP 3 / 10 — VPN Services"
    for pkg in nginx openssh-server dropbear haproxy certbot netcat-openbsd; do _pkg "$pkg"; done

    ((step++)); show_progress $step $total "Installing Xray-core..."
    _head "STEP 4 / 10 — Xray Core"
    _run "Downloading Xray" "bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
    mkdir -p "$AKUN_DIR" /var/log/xray /usr/local/etc/xray "$PUBLIC_HTML" "$ORDER_DIR" /root/bot
    command -v xray >/dev/null 2>&1 && { xver=$(xray version 2>/dev/null | head -1 | awk '{print $2}'); _ok "Xray $xver installed"; } || _fail "Xray install failed"

    ((step++)); show_progress $step $total "Setting up Swap 1GB..."
    _head "STEP 5 / 10 — Swap Memory"
    local cur_swap; cur_swap=$(free -m | awk 'NR==3{print $2}')
    if [[ "$cur_swap" -lt 512 ]]; then
        _run "Creating swapfile 1GB" "fallocate -l 1G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=1024"
        chmod 600 /swapfile; _run "Formatting swap" "mkswap /swapfile"; _run "Enabling swap" "swapon /swapfile"
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
        _ok "Swap 1GB active"
    else
        _ok "Swap exists (${cur_swap}MB), skip"
    fi

    ((step++)); show_progress $step $total "Getting SSL certificate..."
    _head "STEP 6 / 10 — SSL Certificate"
    mkdir -p /etc/xray
    if [[ "$domain_type" == "custom" ]]; then
        _run "Certbot for $DOMAIN" "certbot certonly --standalone -d '$DOMAIN' --non-interactive --agree-tos --register-unsafely-without-email"
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key
            chmod 644 /etc/xray/xray.*; _ok "Let's Encrypt cert installed"
        else
            _fail "Certbot failed"
            _run "Self-signed cert" "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"
        fi
    else
        _run "Self-signed cert" "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"
        _ok "Self-signed cert for $DOMAIN"
    fi
    chmod 644 /etc/xray/xray.* 2>/dev/null

    ((step++)); show_progress $step $total "Creating configs..."
    _head "STEP 7 / 10 — Xray & Nginx Config"
    _run "Creating Xray config" "create_xray_config"
    _ok "8 inbounds: VMess/VLess/Trojan"
    _ok "TLS→443, NonTLS→80, gRPC→8444"

    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    keepalive_timeout 300;
    keepalive_requests 10000;

    location / { try_files $uri $uri/ =404; autoindex on; }

    location /vmess {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
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
    }
}
server {
    listen 81;
    server_name _;
    root /var/www/html;
    index index.html;
    autoindex on;
    location / { try_files $uri $uri/ =404; add_header Content-Type text/plain; }
}
NGXEOF

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    nginx -t >> "$LOG" 2>&1 && _ok "Nginx config valid" || _fail "Nginx config error"

    ((step++)); show_progress $step $total "Configuring Dropbear & HAProxy..."
    _head "STEP 8 / 10 — Dropbear & HAProxy"
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    _ok "Dropbear port 222"
    configure_haproxy
    haproxy -c -f /etc/haproxy/haproxy.cfg >> "$LOG" 2>&1 && _ok "HAProxy port 443 → Xray 8443" || _fail "HAProxy config error"

    ((step++)); show_progress $step $total "UDP, Keepalive & Optimize..."
    _head "STEP 9 / 10 — System Optimize"
    _run "Installing UDP Custom" "install_udp_custom"
    _ok "BadVPN UDP 7100-7300 ready"
    _run "Configuring SSH keepalive" "setup_keepalive"
    _ok "SSH keepalive interval 30s"
    _run "Enabling BBR & TCP optimize" "optimize_vpn"
    _ok "BBR + TCP buffer optimized"
    sed -i 's/^#\?Port.*/Port 22/' /etc/ssh/sshd_config 2>/dev/null
    _ok "SSH port locked to 22"
    _run "Installing Python requests" "pip3 install requests --break-system-packages"
    _ok "Python deps ready"

    # Setup expiry 30 hari pertama kali
    setup_expiry 30
    _ok "Script expiry diset 30 hari"

    ((step++)); show_progress $step $total "Starting services..."
    _head "STEP 10 / 10 — Start Services"
    systemctl daemon-reload >> "$LOG" 2>&1
    for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
        systemctl enable "$svc" >> "$LOG" 2>&1
        systemctl restart "$svc" >> "$LOG" 2>&1
        systemctl is-active --quiet "$svc" && \
            printf "  ${GREEN}[✓]${NC} %-20s ${GREEN}RUNNING${NC}\n" "$svc" || \
            printf "  ${RED}[✗]${NC} %-20s ${RED}FAILED${NC}\n" "$svc"
    done

    setup_menu_command
    _ok "Menu command → ketik 'menu'"

    local ip_vps; ip_vps=$(get_ip)
    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>${DOMAIN}</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:Arial,sans-serif;background:#0a0a1a;color:#eee;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center}.box{padding:40px;background:#111;border:1px solid #00d4ff33;border-radius:12px;max-width:500px}h1{color:#00d4ff;margin-bottom:10px}p{color:#888;margin:5px 0}.badge{display:inline-block;background:#00d4ff22;color:#00d4ff;padding:4px 12px;border-radius:20px;margin-top:15px;font-size:13px}</style></head>
<body><div class="box"><h1>VPN Server</h1><p>${DOMAIN}</p><p>${ip_vps}</p><div class="badge">Proffessor Squad</div></div></body></html>
IDXEOF
    _ok "Web index created"

    local EL=$(printf '═%.0s' $(seq 1 $W))
    echo ""
    echo -e "${GREEN}╔${EL}╗${NC}"
    _center_title "✓  INSTALLATION COMPLETE!" "$GREEN"
    echo -e "${GREEN}╚${EL}╝${NC}"
    echo ""
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "Domain"       "$DOMAIN"
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "IP VPS"       "$ip_vps"
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "SSL"          "$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")"
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "Expiry Script" "30 hari dari sekarang"
    echo ""
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "SSH"           "22"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Dropbear"      "222"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray TLS"      "443 (HAProxy→8443)"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray NonTLS"   "80 (Nginx→8080)"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray gRPC"     "8444"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "BadVPN UDP"    "7100-7300"
    echo ""
    echo -e "  ${YELLOW}💡 Ketik 'menu' untuk membuka menu!${NC}"
    echo -e "  ${YELLOW}Rebooting in 5 seconds...${NC}"
    sleep 5; reboot
}

#================================================
# MAIN MENU
#================================================

main_menu() {
    while true; do
        check_expiry
        show_system_info
        show_menu
        read -p " Enter choice [0-20,99]: " choice

        case $choice in
            1|01) menu_ssh ;;
            2|02) menu_vmess ;;
            3|03) menu_vless ;;
            4|04) menu_trojan ;;
            5|05)
                clear
                print_menu_header "TRIAL XRAY GENERATOR"
                printf "${CYAN}║${NC}  ${CYAN}[1]${NC} %-60s${CYAN}║${NC}\n" "VMess Trial"
                printf "${CYAN}║${NC}  ${CYAN}[2]${NC} %-60s${CYAN}║${NC}\n" "VLess Trial"
                printf "${CYAN}║${NC}  ${CYAN}[3]${NC} %-60s${CYAN}║${NC}\n" "Trojan Trial"
                printf "${CYAN}║${NC}  ${CYAN}[0]${NC} %-60s${CYAN}║${NC}\n" "Back"
                print_menu_footer; echo ""
                read -p " Select: " tc
                case $tc in
                    1) create_trial_xray "vmess" ;;
                    2) create_trial_xray "vless" ;;
                    3) create_trial_xray "trojan" ;;
                esac
                ;;
            6|06)  _menu_list_all ;;
            7|07)  cek_expired ;;
            8|08)  delete_expired ;;
            9|09)  menu_telegram_bot ;;
            10)    change_domain ;;
            11)    fix_certificate ;;
            12)    clear; optimize_vpn; echo -e "${GREEN}Optimization done!${NC}"; sleep 2 ;;
            13)
                clear
                echo -e "${CYAN}Restarting all services...${NC}"; echo ""
                for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive vpn-bot; do
                    systemctl restart "$svc" 2>/dev/null && \
                        printf " ${GREEN}✓${NC} %-20s ${GREEN}Restarted${NC}\n" "$svc" || \
                        printf " ${RED}✗${NC} %-20s ${RED}Failed${NC}\n" "$svc"
                done; echo ""; sleep 2
                ;;
            14)    show_info_port ;;
            15)    run_speedtest ;;
            16)    update_menu ;;
            17)    _menu_backup ;;
            18)    _menu_restore ;;
            19)    menu_uninstall ;;
            20)    menu_expiry ;;
            99)    menu_advanced ;;
            0|00)  clear; echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
            help|HELP) _show_help ;;
            *) ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

[[ $EUID -ne 0 ]] && { echo -e "${RED}Run as root!${NC}"; echo "sudo bash $0"; exit 1; }

[[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

if [[ ! -f "$DOMAIN_FILE" ]]; then
    auto_install
fi

setup_menu_command
check_expiry
main_menu
