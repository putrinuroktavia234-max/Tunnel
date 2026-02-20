#!/bin/bash

#================================================
# VPN Auto Script v3.0 - Complete Edition
# By The Proffessor Squad
# GitHub: putrinuroktavia234-max/Tunnel
#================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Variables
DOMAIN=""
DOMAIN_FILE="/root/domain"
AKUN_DIR="/root/akun"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
SCRIPT_VERSION="3.0.0"
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
# BOX DRAWING FUNCTIONS
#================================================

draw_box_header() {
    local title="$1"
    local width=64
    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))
    
    echo -e "${CYAN}╔$(printf '═%.0s' {1..64})╗${NC}"
    printf "${CYAN}║${NC}%*s${BOLD}${WHITE}%s${NC}%*s${CYAN}║${NC}\n" \
        $padding "" "$title" $((width - title_len - padding)) ""
    echo -e "${CYAN}╠$(printf '═%.0s' {1..64})╣${NC}"
}

draw_box_separator() {
    echo -e "${CYAN}╠$(printf '═%.0s' {1..64})╣${NC}"
}

draw_box_footer() {
    echo -e "${CYAN}╚$(printf '═%.0s' {1..64})╝${NC}"
}

draw_simple_box_top() {
    echo -e "${CYAN}┌$(printf '─%.0s' {1..64})┐${NC}"
}

draw_simple_box_bottom() {
    echo -e "${CYAN}└$(printf '─%.0s' {1..64})┘${NC}"
}

print_menu_item() {
    local num="$1"
    local text="$2"
    printf "${CYAN}║${NC}  ${YELLOW}[%2s]${NC} %-54s ${CYAN}║${NC}\n" "$num" "$text"
}

print_menu_item_double() {
    local num1="$1" text1="$2" num2="$3" text2="$4"
    printf "${CYAN}║${NC}  ${YELLOW}[%2s]${NC} %-22s ${YELLOW}[%2s]${NC} %-22s ${CYAN}║${NC}\n" \
        "$num1" "$text1" "$num2" "$text2"
}

print_info_line() {
    local label="$1"
    local value="$2"
    local color="${3:-$GREEN}"
    printf "${CYAN}║${NC} ${WHITE}%-20s${NC} : ${color}%-38s${NC} ${CYAN}║${NC}\n" "$label" "$value"
}

print_status_line() {
    local label="$1"
    local status="$2"
    if [[ "$status" == "RUNNING" ]] || [[ "$status" == "ON" ]]; then
        printf "${CYAN}║${NC} ${GREEN}●${NC} %-20s ${GREEN}%-37s${NC} ${CYAN}║${NC}\n" "$label" "$status"
    else
        printf "${CYAN}║${NC} ${RED}○${NC} %-20s ${RED}%-37s${NC} ${CYAN}║${NC}\n" "$label" "$status"
    fi
}

print_text_line() {
    local text="$1"
    printf "${CYAN}║${NC} %-62s ${CYAN}║${NC}\n" "$text"
}

print_empty_line() {
    echo -e "${CYAN}║${NC}                                                                ${CYAN}║${NC}"
}

#================================================
# UTILITY FUNCTIONS
#================================================

check_status() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo "RUNNING" || echo "STOPPED"
}

get_ip() {
    local ip
    for url in "https://ifconfig.me" "https://ipinfo.io/ip" "https://api.ipify.org"; do
        ip=$(curl -s --max-time 3 "$url" 2>/dev/null)
        if [[ -n "$ip" ]] && ! echo "$ip" | grep -q "error\|<"; then
            echo "$ip"
            return
        fi
    done
    ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    echo "${ip:-N/A}"
}

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

send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    [[ ! -f "$CHAT_ID_FILE" ]] && return
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

#================================================
# CHECK IF INSTALLED
#================================================

is_installed() {
    local package="$1"
    case "$package" in
        "xray")
            command -v xray >/dev/null 2>&1
            ;;
        "nginx")
            command -v nginx >/dev/null 2>&1
            ;;
        "stunnel4")
            command -v stunnel4 >/dev/null 2>&1 || [[ -f /etc/stunnel/stunnel.conf ]]
            ;;
        "dropbear")
            command -v dropbear >/dev/null 2>&1
            ;;
        "haproxy")
            command -v haproxy >/dev/null 2>&1
            ;;
        "fail2ban")
            command -v fail2ban-client >/dev/null 2>&1
            ;;
        "certbot")
            command -v certbot >/dev/null 2>&1
            ;;
        "unbound")
            command -v unbound >/dev/null 2>&1
            ;;
        "vnstat")
            command -v vnstat >/dev/null 2>&1
            ;;
        "netdata")
            systemctl is-active --quiet netdata 2>/dev/null
            ;;
        "bbr")
            sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr
            ;;
        "swap")
            [[ $(free -m | awk 'NR==3{print $2}') -gt 0 ]]
            ;;
        "ufw")
            command -v ufw >/dev/null 2>&1
            ;;
        *)
            command -v "$package" >/dev/null 2>&1
            ;;
    esac
}

#================================================
# BANNER INSTALL
#================================================

show_install_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'ASCIIEOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██╗   ██╗██████╗ ███╗   ██╗    ███████╗ ██████╗██████╗   ║
║   ██║   ██║██╔══██╗████╗  ██║    ██╔════╝██╔════╝██╔══██╗  ║
║   ██║   ██║██████╔╝██╔██╗ ██║    ███████╗██║     ██████╔╝  ║
║   ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║    ╚════██║██║     ██╔══██╗  ║
║    ╚████╔╝ ██║     ██║ ╚████║    ███████║╚██████╗██║  ██║  ║
║     ╚═══╝  ╚═╝     ╚═╝  ╚═══╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
ASCIIEOF
    echo -e "${NC}"
    echo -e "${WHITE}               VPN AUTO SCRIPT v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}               By The Proffessor Squad${NC}"
    echo ""
}

#================================================
# SETUP DOMAIN
#================================================

setup_domain() {
    clear
    draw_box_header "SETUP DOMAIN"
    print_empty_line
    print_text_line " ${WHITE}[1]${NC} Pakai domain sendiri"
    print_text_line "     ${YELLOW}Contoh: vpn.example.com${NC}"
    print_text_line "     SSL: Let's Encrypt"
    print_empty_line
    print_text_line " ${WHITE}[2]${NC} Generate domain otomatis"
    local preview=$(generate_random_domain)
    print_text_line "     ${YELLOW}Contoh: ${preview}${NC}"
    print_text_line "     SSL: Self-signed"
    print_empty_line
    draw_box_footer
    echo ""
    read -p " Pilih [1/2]: " domain_choice
    
    case $domain_choice in
        1)
            echo ""
            read -p " Masukkan domain: " input_domain
            [[ -z "$input_domain" ]] && {
                echo -e "${RED}Domain kosong!${NC}"
                sleep 2
                setup_domain
                return
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
            sleep 1
            setup_domain
            return
            ;;
    esac
    echo "$DOMAIN" > "$DOMAIN_FILE"
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
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Ketik 'menu' untuk membuka VPN Manager             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
BASHEOF
    fi
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
# SETUP SWAP
#================================================

setup_swap() {
    local swap_total
    swap_total=$(free -m | awk 'NR==3{print $2}')
    
    if [[ "$swap_total" -gt 512 ]]; then
        return 0
    fi
    
    swapoff -a 2>/dev/null
    sed -i '/swapfile/d' /etc/fstab
    rm -f /swapfile
    
    fallocate -l 2G /swapfile 2>/dev/null || \
        dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null
    
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    swapon /swapfile
    
    grep -q "/swapfile" /etc/fstab || \
        echo "/swapfile none swap sw 0 0" >> /etc/fstab
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
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-keepalive.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
KASEOF
    
    systemctl daemon-reload
    systemctl enable vpn-keepalive 2>/dev/null
    systemctl restart vpn-keepalive 2>/dev/null
}

#================================================
# GET SSL CERT
#================================================

get_ssl_cert() {
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")
    
    mkdir -p /etc/xray
    
    if [[ "$domain_type" == "custom" ]]; then
        certbot certonly --standalone \
            -d "$DOMAIN" \
            --non-interactive \
            --agree-tos \
            --register-unsafely-without-email \
            >/dev/null 2>&1
        
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key
        else
            _gen_self_signed
        fi
    else
        _gen_self_signed
    fi
    
    chmod 644 /etc/xray/xray.* 2>/dev/null
}

_gen_self_signed() {
    openssl req -new -newkey rsa:2048 \
        -days 3650 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt 2>/dev/null
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
    timeout connect 5s
    timeout client 1h
    timeout server 1h
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
# THEME SELECTOR - PILIH TEMA MENU
#================================================

THEME_FILE="/root/.menu_theme"

select_menu_theme() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}          ${BOLD}${WHITE}🎨  PILIH TEMA TAMPILAN MENU  🎨${NC}                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Theme 1 - Modern Box
    echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${GREEN}┃${NC}  ${BOLD}${WHITE}TEMA 1${NC} ${CYAN}│${NC} ${WHITE}MODERN BOX (Default)${NC}                           ${GREEN}┃${NC}"
    echo -e "${GREEN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} Double border tebal (╔═╗)                               ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} Color-coded sections                                     ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} Professional & clean look                               ${GREEN}┃${NC}"
    echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""
    
    # Theme 2 - Minimalist
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC}  ${BOLD}${WHITE}TEMA 2${NC} ${CYAN}│${NC} ${WHITE}MINIMALIST (Simple)${NC}                            ${BLUE}│${NC}"
    echo -e "${BLUE}├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}✓${NC} Single line border (┌─┐)                                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}✓${NC} Minimalist & space-efficient                            ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}  ${YELLOW}✓${NC} Easy to read                                             ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    # Theme 3 - Colorful
    echo -e "${CYAN}╭──────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}  ${BOLD}${WHITE}TEMA 3${NC} ${YELLOW}│${NC} ${WHITE}COLORFUL (Rainbow)${NC}                            ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${GREEN}✓${NC} Rounded corners (╭─╮)                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${GREEN}✓${NC} Multiple colors per section                             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC}  ${GREEN}✓${NC} Eye-catching & modern                                    ${CYAN}│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    
    # Theme 4 - Classic
    echo -e "${WHITE}+--------------------------------------------------------------+${NC}"
    echo -e "${WHITE}|${NC}  ${BOLD}TEMA 4${NC} ${CYAN}|${NC} ${WHITE}CLASSIC (Retro)${NC}                                   ${WHITE}|${NC}"
    echo -e "${WHITE}+--------------------------------------------------------------+${NC}"
    echo -e "${WHITE}|${NC}  ${YELLOW}✓${NC} ASCII art style (+---+)                                  ${WHITE}|${NC}"
    echo -e "${WHITE}|${NC}  ${YELLOW}✓${NC} Compatible with old terminals                            ${WHITE}|${NC}"
    echo -e "${WHITE}|${NC}  ${YELLOW}✓${NC} Nostalgic look                                           ${WHITE}|${NC}"
    echo -e "${WHITE}+--------------------------------------------------------------+${NC}"
    echo ""
    
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BOLD}${YELLOW}Pilih tema yang Anda sukai:${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "  ${CYAN}➤${NC} Masukkan pilihan ${WHITE}[1/2/3/4]${NC}: "
    read theme_choice
    
    case $theme_choice in
        1) echo "modern" > "$THEME_FILE" ;;
        2) echo "minimal" > "$THEME_FILE" ;;
        3) echo "colorful" > "$THEME_FILE" ;;
        4) echo "classic" > "$THEME_FILE" ;;
        *) echo "modern" > "$THEME_FILE" ;;
    esac
    
    echo ""
    echo -e "  ${GREEN}✓ Tema berhasil disimpan!${NC}"
    sleep 1
}

get_current_theme() {
    if [[ -f "$THEME_FILE" ]]; then
        cat "$THEME_FILE"
    else
        echo "modern"
    fi
}

#================================================
# DYNAMIC BOX FUNCTIONS - THEME AWARE
#================================================

draw_header() {
    local title="$1"
    local theme=$(get_current_theme)
    local width=64
    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))
    
    case "$theme" in
        "modern")
            echo -e "${CYAN}╔$(printf '═%.0s' {1..64})╗${NC}"
            printf "${CYAN}║${NC}%*s${BOLD}${WHITE}%s${NC}%*s${CYAN}║${NC}\n" \
                $padding "" "$title" $((width - title_len - padding)) ""
            echo -e "${CYAN}╠$(printf '═%.0s' {1..64})╣${NC}"
            ;;
        "minimal")
            echo -e "${BLUE}┌$(printf '─%.0s' {1..64})┐${NC}"
            printf "${BLUE}│${NC}%*s${BOLD}${WHITE}%s${NC}%*s${BLUE}│${NC}\n" \
                $padding "" "$title" $((width - title_len - padding)) ""
            echo -e "${BLUE}├$(printf '─%.0s' {1..64})┤${NC}"
            ;;
        "colorful")
            echo -e "${CYAN}╭$(printf '─%.0s' {1..64})╮${NC}"
            printf "${CYAN}│${NC}%*s${BOLD}${YELLOW}%s${NC}%*s${CYAN}│${NC}\n" \
                $padding "" "$title" $((width - title_len - padding)) ""
            echo -e "${CYAN}├$(printf '─%.0s' {1..64})┤${NC}"
            ;;
        "classic")
            echo -e "${WHITE}+$(printf -- '-%.0s' {1..64})+${NC}"
            printf "${WHITE}|${NC}%*s${BOLD}%s${NC}%*s${WHITE}|${NC}\n" \
                $padding "" "$title" $((width - title_len - padding)) ""
            echo -e "${WHITE}+$(printf -- '-%.0s' {1..64})+${NC}"
            ;;
    esac
}

draw_footer() {
    local theme=$(get_current_theme)
    
    case "$theme" in
        "modern")
            echo -e "${CYAN}╚$(printf '═%.0s' {1..64})╝${NC}"
            ;;
        "minimal")
            echo -e "${BLUE}└$(printf '─%.0s' {1..64})┘${NC}"
            ;;
        "colorful")
            echo -e "${CYAN}╰$(printf '─%.0s' {1..64})╯${NC}"
            ;;
        "classic")
            echo -e "${WHITE}+$(printf -- '-%.0s' {1..64})+${NC}"
            ;;
    esac
}

draw_separator() {
    local theme=$(get_current_theme)
    
    case "$theme" in
        "modern")
            echo -e "${CYAN}╠$(printf '═%.0s' {1..64})╣${NC}"
            ;;
        "minimal")
            echo -e "${BLUE}├$(printf '─%.0s' {1..64})┤${NC}"
            ;;
        "colorful")
            echo -e "${CYAN}├$(printf '─%.0s' {1..64})┤${NC}"
            ;;
        "classic")
            echo -e "${WHITE}+$(printf -- '-%.0s' {1..64})+${NC}"
            ;;
    esac
}

print_line() {
    local text="$1"
    local theme=$(get_current_theme)
    local border_color
    
    case "$theme" in
        "modern") border_color="${CYAN}" ;;
        "minimal") border_color="${BLUE}" ;;
        "colorful") border_color="${CYAN}" ;;
        "classic") border_color="${WHITE}" ;;
    esac
    
    printf "${border_color}║${NC} %-62s ${border_color}║${NC}\n" "$text"
}

print_menu_option() {
    local num="$1"
    local text="$2"
    local theme=$(get_current_theme)
    local border_color num_color
    
    case "$theme" in
        "modern") 
            border_color="${CYAN}"
            num_color="${YELLOW}"
            ;;
        "minimal") 
            border_color="${BLUE}"
            num_color="${CYAN}"
            ;;
        "colorful") 
            border_color="${CYAN}"
            num_color="${GREEN}"
            ;;
        "classic") 
            border_color="${WHITE}"
            num_color="${YELLOW}"
            ;;
    esac
    
    printf "${border_color}║${NC}  ${num_color}[%2s]${NC} %-54s ${border_color}║${NC}\n" "$num" "$text"
}

print_menu_double() {
    local num1="$1" text1="$2" num2="$3" text2="$4"
    local theme=$(get_current_theme)
    local border_color num_color
    
    case "$theme" in
        "modern") 
            border_color="${CYAN}"
            num_color="${YELLOW}"
            ;;
        "minimal") 
            border_color="${BLUE}"
            num_color="${CYAN}"
            ;;
        "colorful") 
            border_color="${CYAN}"
            num_color="${GREEN}"
            ;;
        "classic") 
            border_color="${WHITE}"
            num_color="${YELLOW}"
            ;;
    esac
    
    printf "${border_color}║${NC}  ${num_color}[%2s]${NC} %-22s ${num_color}[%2s]${NC} %-22s ${border_color}║${NC}\n" \
        "$num1" "$text1" "$num2" "$text2"
}

print_info() {
    local label="$1"
    local value="$2"
    local theme=$(get_current_theme)
    local border_color
    
    case "$theme" in
        "modern") border_color="${CYAN}" ;;
        "minimal") border_color="${BLUE}" ;;
        "colorful") border_color="${CYAN}" ;;
        "classic") border_color="${WHITE}" ;;
    esac
    
    printf "${border_color}║${NC} ${WHITE}%-20s${NC} : ${GREEN}%-38s${NC} ${border_color}║${NC}\n" "$label" "$value"
}

print_status() {
    local label="$1"
    local status="$2"
    local theme=$(get_current_theme)
    local border_color
    
    case "$theme" in
        "modern") border_color="${CYAN}" ;;
        "minimal") border_color="${BLUE}" ;;
        "colorful") border_color="${CYAN}" ;;
        "classic") border_color="${WHITE}" ;;
    esac
    
    if [[ "$status" == "RUNNING" ]] || [[ "$status" == "ON" ]]; then
        printf "${border_color}║${NC} ${GREEN}●${NC} %-20s ${GREEN}%-37s${NC} ${border_color}║${NC}\n" "$label" "$status"
    else
        printf "${border_color}║${NC} ${RED}○${NC} %-20s ${RED}%-37s${NC} ${border_color}║${NC}\n" "$label" "$status"
    fi
}

#================================================
# XRAY CONFIG
#================================================

fix_xray_permissions() {
    mkdir -p /usr/local/etc/xray /var/log/xray
    chmod 755 /usr/local/etc/xray /var/log/xray
    touch /var/log/xray/access.log /var/log/xray/error.log
    chmod 644 /var/log/xray/*.log
    chmod 644 /usr/local/etc/xray/config.json 2>/dev/null
    chown -R nobody:nogroup /var/log/xray 2>/dev/null
}

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
        "wsSettings": {"path": "/vmess"}
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
        "wsSettings": {"path": "/vmess"}
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
        "wsSettings": {"path": "/vless"}
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
        "wsSettings": {"path": "/vless"}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
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
        "wsSettings": {"path": "/trojan"}
      },
      "sniffing": {"enabled": true, "destOverride": ["http","tls"]},
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
    {"protocol": "freedom", "settings": {"domainStrategy": "UseIPv4"}, "tag": "direct"},
    {"protocol": "blackhole", "settings": {}, "tag": "block"}
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [{"type": "field", "ip": ["geoip:private"], "outboundTag": "block"}]
  }
}
XRAYEOF
    fix_xray_permissions
}

#================================================
# CHECK USER LOGIN - FIXED
#================================================

check_user_login() {
    local protocol="$1"
    clear
    draw_header "ACTIVE ${protocol^^} LOGINS"
    echo ""
    
    if [[ "$protocol" == "ssh" ]]; then
        print_line "${WHITE}Active SSH Sessions:${NC}"
        echo ""
        
        local active_users=$(who 2>/dev/null | awk '{print $1}' | sort | uniq)
        if [[ -z "$active_users" ]]; then
            print_line "${YELLOW}No active SSH sessions${NC}"
        else
            while IFS= read -r user; do
                local login_count=$(who | grep -c "^$user ")
                local login_time=$(who | grep "^$user " | head -1 | awk '{print $3, $4}')
                local login_from=$(who | grep "^$user " | head -1 | awk '{print $5}' | tr -d '()')
                
                print_line "${GREEN}●${NC} User: ${WHITE}$user${NC}"
                print_line "  Connections: ${CYAN}$login_count${NC}"
                print_line "  Login Time: ${CYAN}$login_time${NC}"
                print_line "  From: ${CYAN}${login_from:-localhost}${NC}"
                echo ""
            done <<< "$active_users"
        fi
    else
        print_line "${WHITE}Active ${protocol^^} Connections:${NC}"
        echo ""
        
        if [[ ! -f /var/log/xray/access.log ]]; then
            print_line "${YELLOW}Log file not found${NC}"
        else
            # Parse Xray log untuk email (username)
            local recent_logs=$(grep "accepted" /var/log/xray/access.log 2>/dev/null | \
                grep -i "$protocol" | tail -50)
            
            if [[ -z "$recent_logs" ]]; then
                print_line "${YELLOW}No recent ${protocol^^} connections${NC}"
            else
                # Extract unique users dari log
                local active_users=$(echo "$recent_logs" | \
                    grep -oP 'email: \K[^,]+' | sort | uniq)
                
                if [[ -z "$active_users" ]]; then
                    print_line "${YELLOW}No active users detected${NC}"
                else
                    while IFS= read -r username; do
                        local conn_count=$(echo "$recent_logs" | grep -c "email: $username")
                        local last_seen=$(echo "$recent_logs" | grep "email: $username" | \
                            tail -1 | awk '{print $1, $2}')
                        
                        print_line "${GREEN}●${NC} User: ${WHITE}$username${NC}"
                        print_line "  Connections: ${CYAN}$conn_count${NC}"
                        print_line "  Last Seen: ${CYAN}$last_seen${NC}"
                        echo ""
                    done <<< "$active_users"
                fi
            fi
        fi
    fi
    
    draw_footer
    echo ""
    read -p "Press any key to back..."
}
#================================================
# DASHBOARD v3.0 - THEME AWARE
#================================================

show_system_info() {
    clear
    
    # Load domain
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    
    # Get system info
    local os_name="Unknown"
    [[ -f /etc/os-release ]] && {
        source /etc/os-release
        os_name="${PRETTY_NAME}"
    }
    
    local ip_vps ram_used ram_total ram_pct cpu uptime_str
    local ssl_type ssl_status svc_running svc_total
    
    ip_vps=$(get_ip)
    ram_used=$(free -m | awk 'NR==2{print $3}')
    ram_total=$(free -m | awk 'NR==2{print $2}')
    ram_pct=$(awk "BEGIN {printf \"%.1f\", ($ram_used/$ram_total)*100}")
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    uptime_str=$(uptime -p | sed 's/up //')
    
    # SSL info
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")
    
    if [[ "$domain_type" == "custom" ]]; then
        ssl_type="Let's Encrypt"
        [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]] && \
            ssl_status="${GREEN}✓${NC}" || ssl_status="${YELLOW}⚠${NC}"
    else
        ssl_type="Self-Signed"
        ssl_status="${CYAN}~${NC}"
    fi
    
    # Count services
    local services=(xray nginx sshd haproxy dropbear udp-custom vpn-keepalive vpn-bot)
    svc_total=${#services[@]}
    svc_running=0
    for svc in "${services[@]}"; do
        systemctl is-active --quiet "$svc" 2>/dev/null && ((svc_running++))
    done
    
    # Count accounts
    local ssh_count vmess_count vless_count trojan_count
    ssh_count=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    vmess_count=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    vless_count=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    trojan_count=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    
    # Header with theme
    echo ""
    draw_header "VPN SERVER DASHBOARD v3.0"
    print_line "${GREEN}Proffessor Squad${NC} • ${YELLOW}@ridhani16${NC}"
    draw_separator
    
    # Server Info
    print_line "${BOLD}${WHITE}SERVER INFORMATION${NC}"
    echo ""
    print_info "Domain" "${DOMAIN:-Not Set}"
    print_info "IP Address" "$ip_vps"
    print_info "Operating System" "$os_name"
    print_info "Uptime" "$uptime_str"
    print_info "CPU Load" "${cpu}%"
    print_info "RAM Usage" "${ram_used}MB / ${ram_total}MB (${ram_pct}%)"
    print_info "SSL Certificate" "$ssl_type $ssl_status"
    print_info "Active Services" "${GREEN}$svc_running${NC}/$svc_total Running"
    
    draw_separator
    
    # Accounts Summary
    print_line "${BOLD}${WHITE}ACCOUNTS SUMMARY${NC}"
    echo ""
    printf "$(get_border_char)║${NC} ${WHITE}SSH:${NC} ${GREEN}%-2d${NC} users  │  ${WHITE}VMess:${NC} ${GREEN}%-2d${NC} users  │  ${WHITE}VLess:${NC} ${GREEN}%-2d${NC} users  │  ${WHITE}Trojan:${NC} ${GREEN}%-2d${NC} $(get_border_char)║${NC}\n" \
        "$ssh_count" "$vmess_count" "$vless_count" "$trojan_count"
    
    draw_separator
    
    # Service Status
    print_line "${BOLD}${WHITE}SERVICE STATUS${NC}"
    echo ""
    print_status "Xray Core" "$(check_status xray)"
    print_status "Nginx" "$(check_status nginx)"
    print_status "SSH Server" "$(check_status sshd)"
    print_status "HAProxy" "$(check_status haproxy)"
    print_status "Dropbear" "$(check_status dropbear)"
    print_status "UDP Custom" "$(check_status udp-custom)"
    print_status "Keepalive Service" "$(check_status vpn-keepalive)"
    print_status "Telegram Bot" "$(check_status vpn-bot)"
    
    draw_footer
    echo ""
}

get_border_char() {
    local theme=$(get_current_theme)
    case "$theme" in
        "modern") echo "${CYAN}" ;;
        "minimal") echo "${BLUE}" ;;
        "colorful") echo "${CYAN}" ;;
        "classic") echo "${WHITE}" ;;
    esac
}

#================================================
# MAIN MENU v3.0 - THEME AWARE
#================================================

show_menu() {
    draw_header "MAIN MENU"
    print_line ""
    
    # Account Management
    print_line "${BOLD}${WHITE}ACCOUNT MANAGEMENT${NC}"
    echo ""
    print_menu_double "1" "SSH Menu" "5" "Trial Generator"
    print_menu_double "2" "VMess Menu" "6" "List All Accounts"
    print_menu_double "3" "VLess Menu" "7" "Check Expired"
    print_menu_double "4" "Trojan Menu" "8" "Delete Expired"
    
    draw_separator
    
    # System Tools
    print_line "${BOLD}${WHITE}SYSTEM TOOLS${NC}"
    echo ""
    print_menu_double "9" "Telegram Bot" "14" "Service Info"
    print_menu_double "10" "Change Domain" "15" "Speedtest"
    print_menu_double "11" "Fix SSL/Cert" "16" "Update Script"
    print_menu_double "12" "Optimize VPS" "17" "Backup System"
    print_menu_double "13" "Restart All" "18" "Restore System"
    
    draw_separator
    
    # Advanced
    print_line "${BOLD}${WHITE}ADVANCED${NC}"
    echo ""
    print_menu_double "19" "Uninstall Menu" "99" "Advanced Settings"
    print_menu_option "20" "Change Menu Theme"
    
    draw_separator
    print_menu_option "0" "Exit Program"
    print_line ""
    draw_footer
    
    echo ""
    echo -e "${YELLOW}💡 TIP:${NC} Type ${WHITE}help${NC} for command guide  │  ${YELLOW}📞${NC} Support: ${WHITE}@ridhani16${NC}"
    echo ""
}

#================================================
# CHANGE DOMAIN
#================================================

change_domain() {
    clear
    draw_header "CHANGE DOMAIN"
    print_line ""
    print_info "Current Domain" "${GREEN}${DOMAIN:-Not Set}${NC}"
    print_line ""
    draw_footer
    echo ""
    echo -e "${YELLOW}Starting domain reconfiguration...${NC}"
    sleep 1
    setup_domain
    echo ""
    echo -e "${YELLOW}⚠  Please run 'Fix SSL/Cert' menu to update certificate!${NC}"
    sleep 3
}

#================================================
# FIX CERTIFICATE
#================================================

fix_certificate() {
    clear
    draw_header "FIX / RENEW SSL CERTIFICATE"
    print_line ""
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && {
        print_line "${RED}Domain not configured!${NC}"
        draw_footer
        sleep 3
        return
    }
    print_info "Domain" "$DOMAIN"
    print_line ""
    draw_footer
    echo ""
    echo -e "${CYAN}Stopping services...${NC}"
    systemctl stop haproxy nginx 2>/dev/null
    sleep 1
    
    echo -e "${CYAN}Getting SSL certificate...${NC}"
    get_ssl_cert
    
    echo -e "${CYAN}Starting services...${NC}"
    systemctl start nginx haproxy 2>/dev/null
    systemctl restart xray 2>/dev/null
    
    echo -e "${GREEN}✓ Certificate updated!${NC}"
    sleep 2
}

#================================================
# SPEEDTEST
#================================================

run_speedtest() {
    clear
    draw_header "SPEEDTEST BY OOKLA"
    print_line ""
    
    if ! command -v speedtest >/dev/null 2>&1 && \
       ! command -v speedtest-cli >/dev/null 2>&1; then
        print_line "${YELLOW}Installing Speedtest CLI...${NC}"
        draw_footer
        echo ""
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
        if ! command -v speedtest >/dev/null 2>&1; then
            pip3 install speedtest-cli --break-system-packages >/dev/null 2>&1
        fi
    fi
    
    print_line "${YELLOW}Testing... Please wait ~30 seconds${NC}"
    draw_footer
    echo ""
    
    if command -v speedtest >/dev/null 2>&1; then
        local result=$(speedtest --accept-license --accept-gdpr 2>/dev/null)
        if [[ -n "$result" ]]; then
            clear
            draw_header "SPEEDTEST RESULTS"
            print_line ""
            
            local server=$(echo "$result" | grep "Server:" | sed 's/.*Server: //')
            local latency=$(echo "$result" | grep "Latency:" | awk '{print $2,$3}')
            local dl=$(echo "$result" | grep "Download:" | awk '{print $2,$3}')
            local ul=$(echo "$result" | grep "Upload:" | awk '{print $2,$3}')
            local url=$(echo "$result" | grep "Result URL:" | awk '{print $NF}')
            
            print_info "Server" "$server"
            print_info "Latency" "$latency"
            print_info "Download" "${GREEN}$dl${NC}"
            print_info "Upload" "${GREEN}$ul${NC}"
            [[ -n "$url" ]] && print_info "Result URL" "$url"
            print_line ""
            print_line "${CYAN}Source: https://www.speedtest.net${NC}"
            draw_footer
        else
            print_line "${RED}Speedtest failed!${NC}"
            draw_footer
        fi
    elif command -v speedtest-cli >/dev/null 2>&1; then
        local result=$(speedtest-cli --simple 2>/dev/null)
        if [[ -n "$result" ]]; then
            clear
            draw_header "SPEEDTEST RESULTS"
            print_line ""
            while IFS= read -r line; do
                print_line "$line"
            done <<< "$result"
            print_line ""
            draw_footer
        fi
    fi
    
    echo ""
    read -p "Press any key to back..."
}

#================================================
# CEK EXPIRED
#================================================

cek_expired() {
    clear
    draw_header "CHECK EXPIRED ACCOUNTS"
    print_line ""
    
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
                print_line "${RED}EXPIRED${NC}: $uname ($exp_str)"
            else
                print_line "${YELLOW}$diff days${NC}: $uname ($exp_str)"
            fi
        fi
    done
    shopt -u nullglob
    
    [[ $found -eq 0 ]] && print_line "${GREEN}No expired accounts!${NC}"
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# DELETE EXPIRED
#================================================

delete_expired() {
    clear
    draw_header "DELETE EXPIRED ACCOUNTS"
    print_line ""
    
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
            
            print_line "${RED}Deleting${NC}: $fname"
            
            local tmp=$(mktemp)
            jq --arg email "$uname" \
               'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
               "$XRAY_CONFIG" > "$tmp" 2>/dev/null && \
               mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
            
            [[ "$protocol" == "ssh" ]] && userdel -f "$uname" 2>/dev/null
            
            rm -f "$f" "$PUBLIC_HTML/${fname}.txt"
            ((count++))
        fi
    done
    shopt -u nullglob
    
    if [[ $count -gt 0 ]]; then
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        print_line ""
        print_line "${GREEN}Deleted $count accounts!${NC}"
    else
        print_line "${GREEN}No expired accounts found!${NC}"
    fi
    
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# SHOW INFO PORT
#================================================

show_info_port() {
    clear
    draw_header "SERVER PORT INFORMATION"
    print_line ""
    
    print_info "SSH OpenSSH" "22"
    print_info "SSH Dropbear" "222"
    print_info "Nginx HTTP (NonTLS)" "80"
    print_info "Nginx Download" "81"
    print_info "HAProxy TLS" "443 → Xray 8443"
    print_info "Xray WebSocket TLS" "443 (via HAProxy)"
    print_info "Xray WebSocket NonTLS" "80 (via Nginx)"
    print_info "Xray gRPC TLS" "8444"
    print_info "BadVPN UDP Range" "7100-7300"
    
    print_line ""
    print_line "${BOLD}${WHITE}PATH CONFIGURATION${NC}"
    print_line ""
    print_info "VMess WS Path" "/vmess"
    print_info "VLess WS Path" "/vless"
    print_info "Trojan WS Path" "/trojan"
    print_info "VMess gRPC" "vmess-grpc"
    print_info "VLess gRPC" "vless-grpc"
    print_info "Trojan gRPC" "trojan-grpc"
    
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# LIST ALL ACCOUNTS
#================================================

list_all_accounts() {
    clear
    draw_header "ALL ACTIVE ACCOUNTS"
    print_line ""
    
    local total=0
    
    # SSH
    shopt -s nullglob
    local ssh_files=("$AKUN_DIR"/ssh-*.txt)
    if [[ -f "${ssh_files[0]}" ]]; then
        print_line "${BOLD}${GREEN}SSH ACCOUNTS${NC}"
        echo ""
        for f in "${ssh_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/ssh-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_line "  ${CYAN}•${NC} $uname ${YELLOW}($exp)${NC}"
            ((total++))
        done
        echo ""
    fi
    
    # VMess
    local vmess_files=("$AKUN_DIR"/vmess-*.txt)
    if [[ -f "${vmess_files[0]}" ]]; then
        print_line "${BOLD}${GREEN}VMESS ACCOUNTS${NC}"
        echo ""
        for f in "${vmess_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vmess-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_line "  ${CYAN}•${NC} $uname ${YELLOW}($exp)${NC}"
            ((total++))
        done
        echo ""
    fi
    
    # VLess
    local vless_files=("$AKUN_DIR"/vless-*.txt)
    if [[ -f "${vless_files[0]}" ]]; then
        print_line "${BOLD}${GREEN}VLESS ACCOUNTS${NC}"
        echo ""
        for f in "${vless_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vless-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_line "  ${CYAN}•${NC} $uname ${YELLOW}($exp)${NC}"
            ((total++))
        done
        echo ""
    fi
    
    # Trojan
    local trojan_files=("$AKUN_DIR"/trojan-*.txt)
    if [[ -f "${trojan_files[0]}" ]]; then
        print_line "${BOLD}${GREEN}TROJAN ACCOUNTS${NC}"
        echo ""
        for f in "${trojan_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/trojan-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_line "  ${CYAN}•${NC} $uname ${YELLOW}($exp)${NC}"
            ((total++))
        done
        echo ""
    fi
    shopt -u nullglob
    
    print_line ""
    print_info "Total Accounts" "${GREEN}$total${NC}"
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# HELP SCREEN
#================================================

show_help() {
    clear
    draw_header "COMMAND GUIDE"
    print_line ""
    
    print_line "${BOLD}${WHITE}Account Management:${NC}"
    print_line "  ${CYAN}1-4${NC}   → Protocol account menus"
    print_line "  ${CYAN}5${NC}     → Generate trial accounts (1 hour)"
    print_line "  ${CYAN}6${NC}     → List all active accounts"
    print_line "  ${CYAN}7-8${NC}   → Check/delete expired accounts"
    print_line ""
    
    print_line "${BOLD}${WHITE}System Tools:${NC}"
    print_line "  ${CYAN}9${NC}     → Telegram bot management"
    print_line "  ${CYAN}10-11${NC} → Domain & SSL management"
    print_line "  ${CYAN}12-13${NC} → VPS optimization & restart"
    print_line "  ${CYAN}14-15${NC} → Service info & speedtest"
    print_line "  ${CYAN}16${NC}    → Update script from GitHub"
    print_line "  ${CYAN}17-18${NC} → Backup & restore system"
    print_line ""
    
    print_line "${BOLD}${WHITE}Advanced:${NC}"
    print_line "  ${CYAN}19${NC}    → Uninstall components"
    print_line "  ${CYAN}20${NC}    → Change menu theme"
    print_line "  ${CYAN}99${NC}    → Advanced settings (12 menus)"
    print_line "  ${CYAN}0${NC}     → Exit program"
    print_line "  ${CYAN}help${NC}  → Show this guide"
    
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
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

    local uuid ip_vps exp created
    uuid=$(cat /proc/sys/kernel/random/uuid)
    ip_vps=$(get_ip)
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    created=$(date +"%d %b, %Y")

    local temp=$(mktemp)

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
        echo -e "${RED}Failed to update Xray config!${NC}"
        sleep 2
        return 1
    fi

    mkdir -p "$AKUN_DIR"
    printf "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    # Generate links
    local link_tls link_nontls link_grpc

    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"

        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"

        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
            "$username" "$DOMAIN" "$uuid")
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

    # Save download file
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" << DLEOF
═══════════════════════════════════════════════════════════
  ${protocol^^} ACCOUNT
═══════════════════════════════════════════════════════════
 Username         : ${username}
 IP/Host          : ${ip_vps}
 Domain           : ${DOMAIN}
 UUID             : ${uuid}
 Quota            : ${quota} GB
 IP Limit         : ${iplimit} IP
═══════════════════════════════════════════════════════════
 Port TLS         : 443
 Port NonTLS      : 80
 Port gRPC        : 8444
 Network          : WebSocket / gRPC
 Path WS          : /${protocol}
 ServiceName gRPC : ${protocol}-grpc
 TLS              : enabled
═══════════════════════════════════════════════════════════
 Link TLS:
 ${link_tls}
═══════════════════════════════════════════════════════════
 Link NonTLS:
 ${link_nontls}
═══════════════════════════════════════════════════════════
 Link gRPC:
 ${link_grpc}
═══════════════════════════════════════════════════════════
 Download: http://${ip_vps}:81/${protocol}-${username}.txt
═══════════════════════════════════════════════════════════
 Active Duration  : ${days} Days
 Created          : ${created}
 Expired          : ${exp}
═══════════════════════════════════════════════════════════
DLEOF

    _display_xray_result "$protocol" "$username" "$ip_vps" "$uuid" \
        "$quota" "$iplimit" "$link_tls" "$link_nontls" "$link_grpc" \
        "$days" "$created" "$exp"

    send_telegram_admin "✅ <b>New ${protocol^^} Account</b>
👤 User: <code>${username}</code>
🔑 UUID: <code>${uuid}</code>
🌐 Domain: ${DOMAIN}
📅 Exp: ${exp}"

    read -p "Press any key to back..."
}

_display_xray_result() {
    local protocol="$1" username="$2" ip_vps="$3" uuid="$4"
    local quota="$5" iplimit="$6" link_tls="$7" link_nontls="$8"
    local link_grpc="$9" days="${10}" created="${11}" exp="${12}"

    clear
    draw_header "${protocol^^} ACCOUNT CREATED"
    print_line ""
    
    print_info "Username" "$username"
    print_info "IP/Host" "$ip_vps"
    print_info "Domain" "$DOMAIN"
    print_info "UUID" "$uuid"
    print_info "Quota" "${quota} GB"
    print_info "IP Limit" "${iplimit} IP"
    
    draw_separator
    print_line "${BOLD}${WHITE}PORT CONFIGURATION${NC}"
    print_line ""
    print_info "Port TLS" "443"
    print_info "Port NonTLS" "80"
    print_info "Port gRPC" "8444"
    print_info "Network" "WebSocket / gRPC"
    print_info "Path WS" "/${protocol}"
    print_info "ServiceName" "${protocol}-grpc"
    
    draw_separator
    print_line "${BOLD}${WHITE}CONNECTION LINKS${NC}"
    print_line ""
    print_line "${CYAN}TLS Link:${NC}"
    print_line "${WHITE}${link_tls}${NC}"
    print_line ""
    print_line "${CYAN}NonTLS Link:${NC}"
    print_line "${WHITE}${link_nontls}${NC}"
    print_line ""
    print_line "${CYAN}gRPC Link:${NC}"
    print_line "${WHITE}${link_grpc}${NC}"
    
    draw_separator
    print_info "Download" "http://${ip_vps}:81/${protocol}-${username}.txt"
    print_info "Active Duration" "${days} Days"
    print_info "Created" "$created"
    print_info "Expired" "$exp"
    print_line ""
    draw_footer
    echo ""
}

#================================================
# CREATE SSH ACCOUNT
#================================================

create_ssh() {
    clear
    draw_header "CREATE SSH ACCOUNT"
    print_line ""
    draw_footer
    echo ""
    
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Username required!${NC}"
        sleep 2
        return
    }
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"
        sleep 2
        return
    fi
    
    read -p " Password      : " password
    [[ -z "$password" ]] && {
        echo -e "${RED}Password required!${NC}"
        sleep 2
        return
    }
    
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid number!${NC}"
        sleep 2
        return
    }
    
    read -p " IP Limit      : " iplimit
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

    # Save download file
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" << SSHEOF
═══════════════════════════════════════════════════════════
  SSH ACCOUNT
═══════════════════════════════════════════════════════════
 Username         : ${username}
 Password         : ${password}
 IP/Host          : ${ip_vps}
 Domain SSH       : ${DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 SSH WS Non SSL   : 80
 SSH WS SSL       : 443
 BadVPN UDPGW     : 7100,7200,7300
═══════════════════════════════════════════════════════════
 Format HC        : ${DOMAIN}:80@${username}:${password}
═══════════════════════════════════════════════════════════
 Payload:
 GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: ws[crlf][crlf]
═══════════════════════════════════════════════════════════
 Download: http://${ip_vps}:81/ssh-${username}.txt
═══════════════════════════════════════════════════════════
 Active Duration  : ${days} Days
 Created          : ${created}
 Expired          : ${exp}
═══════════════════════════════════════════════════════════
SSHEOF

    clear
    draw_header "SSH ACCOUNT CREATED"
    print_line ""
    
    print_info "Username" "$username"
    print_info "Password" "$password"
    print_info "IP/Host" "$ip_vps"
    print_info "Domain" "$DOMAIN"
    
    draw_separator
    print_line "${BOLD}${WHITE}PORT CONFIGURATION${NC}"
    print_line ""
    print_info "OpenSSH" "22"
    print_info "Dropbear" "222"
    print_info "SSL/TLS" "443"
    print_info "SSH WS Non SSL" "80"
    print_info "SSH WS SSL" "443"
    print_info "BadVPN UDP" "7100-7300"
    
    draw_separator
    print_info "Format HC" "${DOMAIN}:80@${username}:${password}"
    print_info "Download" "http://${ip_vps}:81/ssh-${username}.txt"
    print_info "Active Duration" "${days} Days"
    print_info "Created" "$created"
    print_info "Expired" "$exp"
    print_line ""
    draw_footer
    
    send_telegram_admin "✅ <b>New SSH Account</b>
👤 User: <code>${username}</code>
🔑 Pass: <code>${password}</code>
🌐 IP: ${ip_vps}
📅 Exp: ${exp}"

    echo ""
    read -p "Press any key to back..."
}

#================================================
# CREATE TRIAL ACCOUNT
#================================================

create_trial_account() {
    local protocol="$1"
    local ts=$(date +%H%M%S)
    local username="trial-${ts}"
    local ip_vps=$(get_ip)
    local exp=$(date -d "+1 hour" +"%d %b %Y %H:%M")
    
    if [[ "$protocol" == "ssh" ]]; then
        local password="1"
        local exp_date=$(date -d "+1 days" +"%Y-%m-%d")
        
        useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null
        echo "${username}:${password}" | chpasswd
        
        # Auto delete after 1 hour
        (
            sleep 3600
            userdel -f "$username" 2>/dev/null
            rm -f "$AKUN_DIR/ssh-${username}.txt"
            rm -f "$PUBLIC_HTML/ssh-${username}.txt"
        ) & disown
        
        clear
        draw_header "SSH TRIAL ACCOUNT"
        print_line ""
        print_info "Username" "$username"
        print_info "Password" "$password"
        print_info "Domain" "$DOMAIN"
        print_info "OpenSSH" "22"
        print_info "Dropbear" "222"
        print_info "Duration" "1 Hour (Auto Delete)"
        print_info "Expired" "$exp"
        print_line ""
        print_line "${YELLOW}⚠ Account will be auto-deleted after 1 hour${NC}"
        print_line ""
        draw_footer
    else
        local uuid=$(cat /proc/sys/kernel/random/uuid)
        local temp=$(mktemp)
        
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
        else
            rm -f "$temp"
            echo -e "${RED}Failed!${NC}"
            sleep 2
            return
        fi
        
        # Generate links (simplified for trial)
        local link_tls link_nontls
        if [[ "$protocol" == "vmess" ]]; then
            local j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
                "$username" "$uuid" "$DOMAIN")
            link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
        elif [[ "$protocol" == "vless" ]]; then
            link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        elif [[ "$protocol" == "trojan" ]]; then
            link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        fi
        
        # Auto delete after 1 hour
        (
            sleep 3600
            local tmp2=$(mktemp)
            jq --arg email "$username" \
               'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
               "$XRAY_CONFIG" > "$tmp2" 2>/dev/null && \
               mv "$tmp2" "$XRAY_CONFIG" || rm -f "$tmp2"
            fix_xray_permissions
            systemctl restart xray 2>/dev/null
            rm -f "$AKUN_DIR/${protocol}-${username}.txt"
        ) & disown
        
        clear
        draw_header "${protocol^^} TRIAL ACCOUNT"
        print_line ""
        print_info "Username" "$username"
        print_info "UUID" "$uuid"
        print_info "Domain" "$DOMAIN"
        print_info "Port TLS" "443"
        print_info "Port NonTLS" "80"
        print_info "Path" "/${protocol}"
        print_line ""
        print_line "${CYAN}TLS Link:${NC}"
        print_line "${WHITE}${link_tls}${NC}"
        print_line ""
        print_info "Duration" "1 Hour (Auto Delete)"
        print_info "Expired" "$exp"
        print_line ""
        print_line "${YELLOW}⚠ Account will be auto-deleted after 1 hour${NC}"
        print_line ""
        draw_footer
    fi
    
    echo ""
    read -p "Press any key to back..."
}

#================================================
# DELETE / RENEW ACCOUNT
#================================================

delete_account() {
    local protocol="$1"
    clear
    draw_header "DELETE ${protocol^^} ACCOUNT"
    print_line ""
    
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_line "${RED}No accounts found!${NC}"
        draw_footer
        sleep 2
        return
    fi
    
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        print_line "  ${CYAN}•${NC} $n ${YELLOW}($e)${NC}"
    done
    
    print_line ""
    draw_footer
    echo ""
    read -p " Username to delete: " username
    [[ -z "$username" ]] && return
    
    local tmp=$(mktemp)
    jq --arg email "$username" \
       'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
       "$XRAY_CONFIG" > "$tmp" 2>/dev/null && \
       mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"
    
    fix_xray_permissions
    systemctl restart xray 2>/dev/null
    
    rm -f "$AKUN_DIR/${protocol}-${username}.txt"
    rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"
    
    [[ "$protocol" == "ssh" ]] && userdel -f "$username" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ Account deleted: ${username}${NC}"
    sleep 2
}

renew_account() {
    local protocol="$1"
    clear
    draw_header "RENEW ${protocol^^} ACCOUNT"
    print_line ""
    
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_line "${RED}No accounts found!${NC}"
        draw_footer
        sleep 2
        return
    fi
    
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        print_line "  ${CYAN}•${NC} $n ${YELLOW}($e)${NC}"
    done
    
    print_line ""
    draw_footer
    echo ""
    read -p " Username to renew: " username
    [[ -z "$username" ]] && return
    
    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && {
        echo -e "${RED}Account not found!${NC}"
        sleep 2
        return
    }
    
    read -p " Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid number!${NC}"
        sleep 2
        return
    }
    
    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" \
        "$AKUN_DIR/${protocol}-${username}.txt"
    
    [[ "$protocol" == "ssh" ]] && \
        chage -E "$new_exp_date" "$username" 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ Account renewed! New expiry: ${new_exp}${NC}"
    sleep 2
}

#================================================
# PROTOCOL MENUS
#================================================

menu_ssh() {
    while true; do
        clear
        draw_header "SSH MENU"
        print_menu_option "1" "Create SSH Account"
        print_menu_option "2" "Trial SSH (1 Hour)"
        print_menu_option "3" "Delete SSH Account"
        print_menu_option "4" "Renew SSH Account"
        print_menu_option "5" "Check Active Logins"
        print_menu_option "6" "List All SSH Users"
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) create_ssh ;;
            2) create_trial_account "ssh" ;;
            3) delete_account "ssh" ;;
            4) renew_account "ssh" ;;
            5) check_user_login "ssh" ;;
            6) _list_protocol_accounts "ssh" ;;
            0) return ;;
        esac
    done
}

menu_vmess() {
    while true; do
        clear
        draw_header "VMESS MENU"
        print_menu_option "1" "Create VMess Account"
        print_menu_option "2" "Trial VMess (1 Hour)"
        print_menu_option "3" "Delete VMess Account"
        print_menu_option "4" "Renew VMess Account"
        print_menu_option "5" "Check Active Logins"
        print_menu_option "6" "List All VMess Users"
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) _create_xray_account "vmess" ;;
            2) create_trial_account "vmess" ;;
            3) delete_account "vmess" ;;
            4) renew_account "vmess" ;;
            5) check_user_login "vmess" ;;
            6) _list_protocol_accounts "vmess" ;;
            0) return ;;
        esac
    done
}

menu_vless() {
    while true; do
        clear
        draw_header "VLESS MENU"
        print_menu_option "1" "Create VLess Account"
        print_menu_option "2" "Trial VLess (1 Hour)"
        print_menu_option "3" "Delete VLess Account"
        print_menu_option "4" "Renew VLess Account"
        print_menu_option "5" "Check Active Logins"
        print_menu_option "6" "List All VLess Users"
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) _create_xray_account "vless" ;;
            2) create_trial_account "vless" ;;
            3) delete_account "vless" ;;
            4) renew_account "vless" ;;
            5) check_user_login "vless" ;;
            6) _list_protocol_accounts "vless" ;;
            0) return ;;
        esac
    done
}

menu_trojan() {
    while true; do
        clear
        draw_header "TROJAN MENU"
        print_menu_option "1" "Create Trojan Account"
        print_menu_option "2" "Trial Trojan (1 Hour)"
        print_menu_option "3" "Delete Trojan Account"
        print_menu_option "4" "Renew Trojan Account"
        print_menu_option "5" "Check Active Logins"
        print_menu_option "6" "List All Trojan Users"
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) _create_xray_account "trojan" ;;
            2) create_trial_account "trojan" ;;
            3) delete_account "trojan" ;;
            4) renew_account "trojan" ;;
            5) check_user_login "trojan" ;;
            6) _list_protocol_accounts "trojan" ;;
            0) return ;;
        esac
    done
}

_create_xray_account() {
    local protocol="$1"
    clear
    draw_header "CREATE ${protocol^^} ACCOUNT"
    print_line ""
    draw_footer
    echo ""
    
    read -p " Username      : " username
    [[ -z "$username" ]] && {
        echo -e "${RED}Username required!${NC}"
        sleep 2
        return
    }
    
    if grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "${RED}Username already exists!${NC}"
        sleep 2
        return
    fi
    
    read -p " Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "${RED}Invalid number!${NC}"
        sleep 2
        return
    }
    
    read -p " Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    
    read -p " IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    
    create_account_template "$protocol" "$username" "$days" "$quota" "$iplimit"
}

_list_protocol_accounts() {
    local protocol="$1"
    clear
    draw_header "${protocol^^} ACCOUNT LIST"
    print_line ""
    
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    
    if [[ ${#files[@]} -eq 0 ]]; then
        print_line "${RED}No accounts found!${NC}"
    else
        for f in "${files[@]}"; do
            local uname exp quota trial
            uname=$(basename "$f" .txt | sed "s/${protocol}-//")
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2)
            quota=$(grep "QUOTA" "$f" 2>/dev/null | cut -d= -f2)
            trial=$(grep "TRIAL" "$f" 2>/dev/null | cut -d= -f2)
            
            if [[ "$trial" == "1" ]]; then
                print_line "${YELLOW}[TRIAL]${NC} $uname - Exp: $exp"
            else
                print_line "${GREEN}[MEMBER]${NC} $uname - Quota: ${quota}GB - Exp: $exp"
            fi
        done
        print_line ""
        print_info "Total" "${GREEN}${#files[@]}${NC} accounts"
    fi
    
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# TRIAL GENERATOR MENU
#================================================

menu_trial_generator() {
    clear
    draw_header "TRIAL ACCOUNT GENERATOR"
    print_menu_option "1" "SSH Trial (1 Hour)"
    print_menu_option "2" "VMess Trial (1 Hour)"
    print_menu_option "3" "VLess Trial (1 Hour)"
    print_menu_option "4" "Trojan Trial (1 Hour)"
    print_menu_option "0" "Back to Main Menu"
    draw_footer
    echo ""
    read -p " Select: " choice
    
    case $choice in
        1) create_trial_account "ssh" ;;
        2) create_trial_account "vmess" ;;
        3) create_trial_account "vless" ;;
        4) create_trial_account "trojan" ;;
        0) return ;;
    esac
}
#================================================
# TELEGRAM BOT - SETUP & SERVICE
#================================================

setup_telegram_bot() {
    clear
    draw_header "TELEGRAM BOT SETUP"
    print_line ""
    print_line "${WHITE}How to get Bot Token:${NC}"
    print_line "  1. Open Telegram, search ${CYAN}@BotFather${NC}"
    print_line "  2. Type /newbot and follow instructions"
    print_line "  3. Copy the TOKEN provided"
    print_line ""
    print_line "${WHITE}How to get Chat ID:${NC}"
    print_line "  1. Search ${CYAN}@userinfobot${NC} in Telegram"
    print_line "  2. Type /start to see your ID"
    print_line ""
    draw_footer
    echo ""
    
    read -p " Bot Token     : " bot_token
    [[ -z "$bot_token" ]] && {
        echo -e "${RED}Token required!${NC}"
        sleep 2
        return
    }
    
    read -p " Admin Chat ID : " admin_id
    [[ -z "$admin_id" ]] && {
        echo -e "${RED}Chat ID required!${NC}"
        sleep 2
        return
    }
    
    echo ""
    echo -e "${CYAN}Testing token...${NC}"
    local test_result=$(curl -s --max-time 10 \
        "https://api.telegram.org/bot${bot_token}/getMe")
    
    if ! echo "$test_result" | grep -q '"ok":true'; then
        echo -e "${RED}✗ Invalid token!${NC}"
        sleep 2
        return
    fi
    
    local bot_name=$(echo "$test_result" | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result']['username'])" 2>/dev/null)
    
    echo -e "${GREEN}✓ Valid bot! @${bot_name}${NC}"
    echo ""
    
    read -p " Account Name  : " rek_name
    read -p " Account Number: " rek_number
    read -p " Bank/E-Wallet : " rek_bank
    read -p " Price/Month   : " harga
    [[ ! "$harga" =~ ^[0-9]+$ ]] && harga=10000
    
    echo "$bot_token" > "$BOT_TOKEN_FILE"
    echo "$admin_id" > "$CHAT_ID_FILE"
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
        echo ""
        echo -e "${GREEN}✓ Bot is active! @${bot_name}${NC}"
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
            -d chat_id="$admin_id" \
            -d text="✅ Bot VPN Active! Domain: ${DOMAIN}" \
            -d parse_mode="HTML" --max-time 10 >/dev/null 2>&1
    else
        echo -e "${RED}✗ Bot failed to start!${NC}"
        journalctl -u vpn-bot -n 10 --no-pager
    fi
    
    echo ""
    read -p "Press any key to back..."
}

_install_bot_service() {
    mkdir -p /root/bot "$ORDER_DIR"
    
    pip3 install requests --break-system-packages >/dev/null 2>&1 || \
        pip3 install requests >/dev/null 2>&1
    
    # Bot script (simplified version - same as before)
    cat > /root/bot/bot.py << 'BOTEOF'
#!/usr/bin/env python3
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

TOKEN = open('/root/.bot_token').read().strip()
ADMIN_ID = int(open('/root/.chat_id').read().strip())
DOMAIN = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
ORDER_DIR = '/root/orders'
AKUN_DIR = '/root/akun'
API = f'https://api.telegram.org/bot{TOKEN}'

os.makedirs(ORDER_DIR, exist_ok=True)
os.makedirs(AKUN_DIR, exist_ok=True)

user_state = {}
state_lock = threading.Lock()

def make_session():
    s = requests.Session()
    retry = Retry(total=2, backoff_factor=0.3, status_forcelist=[500,502,503,504])
    adapter = HTTPAdapter(max_retries=retry, pool_connections=20, pool_maxsize=50)
    s.mount('https://', adapter)
    return s

SESSION = make_session()

def api_post(method, data, timeout=6):
    try:
        r = SESSION.post(f'{API}/{method}', data=data, timeout=timeout)
        return r.json()
    except: return {}

def send(chat_id, text, markup=None):
    data = {'chat_id': chat_id, 'text': text, 'parse_mode': 'HTML'}
    if markup: data['reply_markup'] = json.dumps(markup)
    return api_post('sendMessage', data)

def get_updates(offset=0):
    try:
        r = SESSION.get(f'{API}/getUpdates', 
            params={'offset': offset, 'timeout': 15, 'limit': 100}, timeout=20)
        return r.json().get('result', [])
    except: return []

def kb_main():
    return {'keyboard': [
        ['🆓 Trial Gratis', '🛒 Order VPN'],
        ['📋 Cek Akun', 'ℹ️ Info Server'],
        ['❓ Bantuan', '📞 Admin']
    ], 'resize_keyboard': True}

def on_start(msg):
    chat_id = msg['chat']['id']
    fname = msg['from'].get('first_name', 'User')
    send(chat_id, f'''👋 Halo <b>{fname}</b>!

🤖 <b>Bot VPN Proffessor Squad</b>
🌐 Server: <code>{DOMAIN}</code>

<b>Menu:</b>
🆓 Trial Gratis → Akun 1 jam
🛒 Order VPN → 30 hari
📋 Cek Akun → Lihat akun aktif
ℹ️ Info Server → Port & domain

Pilih menu di bawah 👇''', markup=kb_main())

def on_msg(msg):
    if 'text' not in msg: return
    text = msg['text'].strip()
    if text in ['/start', '🏠 Menu']: on_start(msg)

def main():
    print(f'Bot VPN - Admin: {ADMIN_ID}', flush=True)
    offset = 0
    while True:
        try:
            updates = get_updates(offset)
            for upd in updates:
                offset = upd['update_id'] + 1
                if 'message' in upd:
                    threading.Thread(target=on_msg, args=(upd['message'],), daemon=True).start()
        except KeyboardInterrupt: break
        except Exception as e: 
            print(f'Loop: {e}', flush=True)
            time.sleep(2)

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
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF
    
    systemctl daemon-reload
    systemctl enable vpn-bot 2>/dev/null
    systemctl restart vpn-bot 2>/dev/null
}

menu_telegram_bot() {
    while true; do
        clear
        local bs=$(check_status vpn-bot)
        draw_header "TELEGRAM BOT"
        print_status "Bot Service" "$bs"
        print_line ""
        print_menu_option "1" "Setup Bot"
        print_menu_option "2" "Start Bot"
        print_menu_option "3" "Stop Bot"
        print_menu_option "4" "Restart Bot"
        print_menu_option "5" "View Logs"
        print_menu_option "6" "Bot Info"
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) setup_telegram_bot ;;
            2) systemctl start vpn-bot; echo -e "${GREEN}Started!${NC}"; sleep 1 ;;
            3) systemctl stop vpn-bot; echo -e "${YELLOW}Stopped!${NC}"; sleep 1 ;;
            4) systemctl restart vpn-bot; echo -e "${GREEN}Restarted!${NC}"; sleep 1 ;;
            5) clear; journalctl -u vpn-bot -n 50 --no-pager; echo ""; read -p "Press any key..." ;;
            6) _show_bot_info ;;
            0) return ;;
        esac
    done
}

_show_bot_info() {
    clear
    draw_header "BOT INFORMATION"
    print_line ""
    
    if [[ -f "$BOT_TOKEN_FILE" ]]; then
        local aid=$(cat "$CHAT_ID_FILE" 2>/dev/null)
        print_info "Status" "$(check_status vpn-bot)"
        print_info "Admin Chat ID" "$aid"
        
        if [[ -f "$PAYMENT_FILE" ]]; then
            source "$PAYMENT_FILE"
            print_line ""
            print_info "Bank/E-Wallet" "$REK_BANK"
            print_info "Account Number" "$REK_NUMBER"
            print_info "Account Name" "$REK_NAME"
            print_info "Price/Month" "Rp ${HARGA}"
        fi
    else
        print_line "${RED}Bot not configured yet!${NC}"
    fi
    
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

#================================================
# UDP CUSTOM INSTALLATION
#================================================

install_udp_custom() {
    if is_installed "udp-custom"; then
        echo -e "${YELLOW}UDP Custom already installed, skipping...${NC}"
        return 0
    fi
    
    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select, time

PORTS = range(7100, 7301)
SSH_HOST = '127.0.0.1'
SSH_PORT = 22
BUF = 8192
TIMEOUT = 10

def handle(data, addr, sock):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(TIMEOUT)
        s.connect((SSH_HOST, SSH_PORT))
        s.sendall(data)
        resp = s.recv(BUF)
        if resp: sock.sendto(resp, addr)
        s.close()
    except: pass

sockets = []
for port in PORTS:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', port))
        s.setblocking(False)
        sockets.append(s)
    except: pass

print(f'UDP Custom: {len(sockets)} ports active', flush=True)

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

[Install]
WantedBy=multi-user.target
UDPSVC
    
    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom 2>/dev/null
}

#================================================
# ADVANCED MENU - COMPLETE
#================================================

menu_advanced() {
    while true; do
        clear
        draw_header "⚙️  ADVANCED SETTINGS"
        print_menu_double "1" "Port Management" "7" "Firewall Rules"
        print_menu_double "2" "Protocol Settings" "8" "Bandwidth Monitor"
        print_menu_double "3" "Auto Backup" "9" "User Limits"
        print_menu_double "4" "SSH Protection" "10" "Custom Scripts"
        print_menu_double "5" "Fail2Ban Setup" "11" "Cron Jobs"
        print_menu_double "6" "DDoS Protection" "12" "System Logs"
        print_line ""
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select [0-12]: " choice
        
        case $choice in
            1) _adv_port_management ;;
            2) _adv_protocol_settings ;;
            3) _adv_auto_backup ;;
            4) _adv_ssh_protection ;;
            5) _adv_fail2ban ;;
            6) _adv_ddos_protection ;;
            7) _adv_firewall ;;
            8) _adv_bandwidth ;;
            9) _adv_user_limits ;;
            10) _adv_custom_scripts ;;
            11) _adv_cron_jobs ;;
            12) _adv_system_logs ;;
            0) return ;;
        esac
    done
}

_adv_port_management() {
    clear
    draw_header "PORT MANAGEMENT"
    print_line ""
    print_line "${BOLD}${WHITE}Current Port Configuration:${NC}"
    print_line ""
    print_info "SSH OpenSSH" "22"
    print_info "SSH Dropbear" "222"
    print_info "Nginx HTTP" "80"
    print_info "Nginx Download" "81"
    print_info "HAProxy TLS" "443"
    print_info "Xray Internal TLS" "8443"
    print_info "Xray Internal NonTLS" "8080"
    print_info "Xray gRPC" "8444"
    print_info "BadVPN UDP" "7100-7300"
    print_line ""
    print_line "${BOLD}${WHITE}Active Listening Ports:${NC}"
    print_line ""
    draw_footer
    echo ""
    ss -tulpn 2>/dev/null | grep -E 'LISTEN|udp' | awk '{printf " • %-10s %-20s\n", $1, $5}' | head -15
    echo ""
    read -p "Press any key to back..."
}

_adv_protocol_settings() {
    clear
    draw_header "PROTOCOL SETTINGS"
    print_line ""
    local inbound_count=$(jq '.inbounds | length' "$XRAY_CONFIG" 2>/dev/null)
    print_info "Total Xray Inbounds" "${inbound_count:-0}"
    print_info "VMess Encryption" "Auto (0)"
    print_info "VLess Encryption" "None"
    print_info "WebSocket Path" "/vmess /vless /trojan"
    print_info "gRPC ServiceName" "vmess-grpc vless-grpc trojan-grpc"
    print_info "SNI" "bug.com"
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

_adv_auto_backup() {
    clear
    draw_header "AUTO BACKUP CONFIGURATION"
    print_menu_option "1" "Enable Daily Backup (02:00)"
    print_menu_option "2" "Enable Weekly Backup (Sunday 02:00)"
    print_menu_option "3" "Disable Auto Backup"
    print_menu_option "4" "Manual Backup Now"
    print_menu_option "5" "View Backup History"
    print_menu_option "0" "Back"
    draw_footer
    echo ""
    read -p " Select: " backup_choice
    
    case $backup_choice in
        1)
            (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/menu backup_auto") | crontab -
            echo -e "${GREEN}✓ Daily backup enabled${NC}"
            sleep 2
            ;;
        2)
            (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/menu backup_auto") | crontab -
            echo -e "${GREEN}✓ Weekly backup enabled${NC}"
            sleep 2
            ;;
        3)
            crontab -l 2>/dev/null | grep -v "backup_auto" | crontab -
            echo -e "${GREEN}✓ Auto backup disabled${NC}"
            sleep 2
            ;;
        4) _menu_backup ;;
        5)
            clear
            draw_header "BACKUP HISTORY"
            print_line ""
            if [[ -d /root/backups ]]; then
                ls -lh /root/backups/*.tar.gz 2>/dev/null | awk '{printf " %s %s %s  %s\n", $6, $7, $8, $9}'
            else
                print_line "${YELLOW}No backups found${NC}"
            fi
            print_line ""
            draw_footer
            echo ""
            read -p "Press any key..."
            ;;
    esac
}

_adv_ssh_protection() {
    clear
    draw_header "SSH BRUTE FORCE PROTECTION"
    print_menu_option "1" "Set Max Auth Tries (3-6)"
    print_menu_option "2" "Disable Root Login"
    print_menu_option "3" "Enable Root Login"
    print_menu_option "4" "Disable Password Auth"
    print_menu_option "5" "View Failed Logins"
    print_menu_option "0" "Back"
    draw_footer
    echo ""
    read -p " Select: " ssh_choice
    
    case $ssh_choice in
        1)
            read -p " Max tries [3-6]: " max_tries
            [[ ! "$max_tries" =~ ^[3-6]$ ]] && max_tries=3
            sed -i "s/^#*MaxAuthTries.*/MaxAuthTries $max_tries/" /etc/ssh/sshd_config
            systemctl restart sshd
            echo -e "${GREEN}✓ Set to $max_tries${NC}"
            sleep 2
            ;;
        2)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            systemctl restart sshd
            echo -e "${GREEN}✓ Root login disabled${NC}"
            sleep 2
            ;;
        3)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
            systemctl restart sshd
            echo -e "${YELLOW}✓ Root login enabled${NC}"
            sleep 2
            ;;
        4)
            echo -e "${RED}⚠ Ensure SSH key is configured!${NC}"
            read -p " Continue? [y/N]: " confirm
            if [[ "$confirm" == "y" ]]; then
                sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
                systemctl restart sshd
                echo -e "${GREEN}✓ Password auth disabled${NC}"
            fi
            sleep 2
            ;;
        5)
            clear
            draw_header "FAILED SSH LOGINS"
            print_line ""
            draw_footer
            echo ""
            grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20
            echo ""
            read -p "Press any key..."
            ;;
    esac
}

_adv_fail2ban() {
    clear
    draw_header "FAIL2BAN SETUP"
    print_line ""
    
    if ! command -v fail2ban-client >/dev/null 2>&1; then
        print_line "${YELLOW}Fail2Ban not installed${NC}"
        draw_footer
        echo ""
        read -p " Install Fail2Ban? [y/N]: " install_f2b
        if [[ "$install_f2b" == "y" ]]; then
            apt-get update >/dev/null 2>&1
            apt-get install -y fail2ban >/dev/null 2>&1
            systemctl enable fail2ban
            systemctl start fail2ban
            echo -e "${GREEN}✓ Installed${NC}"
        fi
    else
        systemctl status fail2ban --no-pager | head -5
        echo ""
        fail2ban-client status 2>/dev/null
    fi
    
    echo ""
    read -p "Press any key to back..."
}

_adv_ddos_protection() {
    clear
    draw_header "DDoS PROTECTION"
    print_menu_option "1" "Enable SYN Cookies"
    print_menu_option "2" "Configure Connection Limits"
    print_menu_option "3" "Enable ICMP Rate Limiting"
    print_menu_option "4" "View Current Settings"
    print_menu_option "0" "Back"
    draw_footer
    echo ""
    read -p " Select: " ddos_choice
    
    case $ddos_choice in
        1)
            sysctl -w net.ipv4.tcp_syncookies=1
            echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
            echo -e "${GREEN}✓ Enabled${NC}"
            sleep 2
            ;;
        2)
            cat >> /etc/sysctl.conf << 'DDOSEOF'
net.ipv4.tcp_max_syn_backlog = 4096
net.core.somaxconn = 1024
DDOSEOF
            sysctl -p
            echo -e "${GREEN}✓ Configured${NC}"
            sleep 2
            ;;
        3)
            sysctl -w net.ipv4.icmp_ratelimit=1000
            echo "net.ipv4.icmp_ratelimit=1000" >> /etc/sysctl.conf
            echo -e "${GREEN}✓ Enabled${NC}"
            sleep 2
            ;;
        4)
            clear
            sysctl net.ipv4.tcp_syncookies
            sysctl net.ipv4.tcp_max_syn_backlog
            sysctl net.core.somaxconn
            echo ""
            read -p "Press any key..."
            ;;
    esac
}

_adv_firewall() {
    clear
    draw_header "FIREWALL RULES"
    print_line ""
    
    if command -v ufw >/dev/null 2>&1; then
        ufw status numbered
    else
        print_line "${YELLOW}UFW not installed${NC}"
        draw_footer
        echo ""
        read -p " Install UFW? [y/N]: " install_ufw
        if [[ "$install_ufw" == "y" ]]; then
            apt-get install -y ufw >/dev/null 2>&1
            ufw --force enable
            ufw allow 22,80,81,222,443,8444/tcp
            ufw allow 7100:7300/tcp
            ufw allow 7100:7300/udp
            echo -e "${GREEN}✓ Installed${NC}"
        fi
    fi
    
    echo ""
    read -p "Press any key to back..."
}

_adv_bandwidth() {
    clear
    draw_header "BANDWIDTH MONITOR"
    print_line ""
    
    if command -v vnstat >/dev/null 2>&1; then
        vnstat
    else
        print_line "${YELLOW}vnStat not installed${NC}"
        draw_footer
        echo ""
        read -p " Install vnStat? [y/N]: " install_vn
        if [[ "$install_vn" == "y" ]]; then
            apt-get install -y vnstat >/dev/null 2>&1
            systemctl enable vnstat
            systemctl start vnstat
            echo -e "${GREEN}✓ Installed (wait 5 min for data)${NC}"
        fi
    fi
    
    echo ""
    read -p "Press any key to back..."
}

_adv_user_limits() {
    clear
    draw_header "USER LIMITS"
    print_line ""
    cat /etc/security/limits.d/99-vpn.conf 2>/dev/null || echo "No custom limits"
    echo ""
    ulimit -a | head -10
    echo ""
    read -p "Press any key to back..."
}

_adv_custom_scripts() {
    clear
    draw_header "CUSTOM SCRIPTS"
    print_line ""
    if [[ -d /root/scripts ]]; then
        ls -lh /root/scripts/*.sh 2>/dev/null | awk '{printf " • %s  %s\n", $9, $5}'
    else
        print_line "${YELLOW}No scripts found${NC}"
        print_line "  Create: ${CYAN}mkdir -p /root/scripts${NC}"
    fi
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

_adv_cron_jobs() {
    clear
    draw_header "CRON JOBS"
    print_line ""
    crontab -l 2>/dev/null || print_line "${YELLOW}No cron jobs${NC}"
    print_line ""
    draw_footer
    echo ""
    read -p "Press any key to back..."
}

_adv_system_logs() {
    while true; do
        clear
        draw_header "SYSTEM LOGS"
        print_menu_option "1" "Xray Access Logs"
        print_menu_option "2" "Xray Error Logs"
        print_menu_option "3" "Nginx Error Logs"
        print_menu_option "4" "SSH Auth Logs"
        print_menu_option "5" "System Journal"
        print_menu_option "6" "HAProxy Logs"
        print_menu_option "0" "Back"
        draw_footer
        echo ""
        read -p " Select: " log_choice
        
        case $log_choice in
            1) clear; tail -50 /var/log/xray/access.log 2>/dev/null || echo "No logs"; echo ""; read -p "Press any key..." ;;
            2) clear; tail -50 /var/log/xray/error.log 2>/dev/null || echo "No logs"; echo ""; read -p "Press any key..." ;;
            3) clear; tail -50 /var/log/nginx/error.log 2>/dev/null || echo "No logs"; echo ""; read -p "Press any key..." ;;
            4) clear; tail -50 /var/log/auth.log 2>/dev/null || echo "No logs"; echo ""; read -p "Press any key..." ;;
            5) clear; journalctl -n 50 --no-pager; echo ""; read -p "Press any key..." ;;
            6) clear; journalctl -u haproxy -n 50 --no-pager; echo ""; read -p "Press any key..." ;;
            0) return ;;
        esac
    done
}
#================================================
# UPDATE MENU - GITHUB AUTO UPDATE
#================================================

update_menu() {
    clear
    draw_header "UPDATE SCRIPT"
    print_line ""
    print_info "Current Version" "${GREEN}${SCRIPT_VERSION}${NC}"
    print_line ""
    draw_footer
    echo ""
    echo -e "${CYAN}Checking GitHub for updates...${NC}"
    
    local latest
    latest=$(curl -s --max-time 10 "$VERSION_URL" 2>/dev/null | tr -d '\n\r ' | xargs)
    
    if [[ -z "$latest" ]]; then
        echo -e "${RED}✗ Cannot connect to GitHub!${NC}"
        echo ""
        echo -e "${YELLOW}Possible reasons:${NC}"
        echo -e " • No internet connection"
        echo -e " • GitHub is down"
        echo -e " • Repository URL incorrect"
        echo ""
        read -p "Press Enter to back..."
        return
    fi
    
    echo -e " Latest Version  : ${GREEN}${latest}${NC}"
    echo ""
    
    if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
        echo -e "${GREEN}✓ You are using the latest version!${NC}"
        echo ""
        read -p "Press Enter to back..."
        return
    fi
    
    local current_num latest_num
    current_num=$(echo "$SCRIPT_VERSION" | tr -d '.')
    latest_num=$(echo "$latest" | tr -d '.')
    
    if [[ "$latest_num" -lt "$current_num" ]]; then
        echo -e "${YELLOW}⚠ Your version is newer than GitHub!${NC}"
        echo ""
        read -p "Downgrade to stable? [y/N]: " confirm
        [[ "$confirm" != "y" ]] && return
    else
        echo -e "${YELLOW}⬆ Update available!${NC}"
        echo ""
        read -p "Update now? [y/N]: " confirm
        [[ "$confirm" != "y" ]] && return
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Step 1: Backup
    echo -e "${CYAN}[1/4]${NC} Creating backup..."
    cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo -e "      ${GREEN}✓ Backup created${NC}"
    else
        echo -e "      ${RED}✗ Backup failed!${NC}"
        read -p "Press Enter to back..."
        return
    fi
    
    # Step 2: Download
    echo -e "${CYAN}[2/4]${NC} Downloading v${latest}..."
    local tmp="/tmp/tunnel_new.sh"
    curl -L --progress-bar --max-time 60 "$SCRIPT_URL" -o "$tmp" 2>&1 | \
        grep -o '[0-9]*\.[0-9]' | tail -1
    
    if [[ ! -s "$tmp" ]]; then
        echo -e "      ${RED}✗ Download failed!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        read -p "Press Enter to back..."
        return
    fi
    echo -e "      ${GREEN}✓ Downloaded${NC}"
    
    # Step 3: Validate
    echo -e "${CYAN}[3/4]${NC} Validating script..."
    bash -n "$tmp" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "      ${RED}✗ Syntax error!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        rm -f "$tmp"
        read -p "Press Enter to back..."
        return
    fi
    echo -e "      ${GREEN}✓ Syntax OK${NC}"
    
    # Step 4: Apply
    echo -e "${CYAN}[4/4]${NC} Applying update..."
    mv "$tmp" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "      ${GREEN}✓ Update applied${NC}"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ UPDATE SUCCESSFUL!                         ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════╣${NC}"
    printf "${GREEN}║  Old: v${SCRIPT_VERSION}  →  New: v${latest}%*s║${NC}\n" \
        $((37 - ${#SCRIPT_VERSION} - ${#latest})) ""
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Restarting script in 3 seconds...${NC}"
    sleep 3
    exec bash "$SCRIPT_PATH"
}

rollback_script() {
    clear
    draw_header "ROLLBACK SCRIPT"
    print_line ""
    
    if [[ ! -f "$BACKUP_PATH" ]]; then
        print_line "${RED}No backup file found!${NC}"
        draw_footer
        sleep 2
        return
    fi
    
    local backup_ver
    backup_ver=$(grep "SCRIPT_VERSION=" "$BACKUP_PATH" 2>/dev/null | \
        head -1 | cut -d'"' -f2)
    
    print_info "Current Version" "${GREEN}${SCRIPT_VERSION}${NC}"
    print_info "Backup Version" "${YELLOW}${backup_ver:-Unknown}${NC}"
    print_line ""
    draw_footer
    echo ""
    echo -e "${YELLOW}⚠ Restore previous version?${NC}"
    read -p "Continue? [y/N]: " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    cp "$BACKUP_PATH" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    echo -e "${GREEN}✓ Rollback successful!${NC}"
    echo -e "${YELLOW}Restarting...${NC}"
    sleep 2
    exec bash "$SCRIPT_PATH"
}

#================================================
# BACKUP & RESTORE SYSTEM
#================================================

_menu_backup() {
    clear
    draw_header "BACKUP SYSTEM"
    print_line ""
    print_line "${YELLOW}Creating backup...${NC}"
    draw_footer
    echo ""
    
    local backup_dir="/root/backups"
    local backup_file="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$backup_dir"
    
    tar -czf "$backup_dir/$backup_file" \
        /root/domain \
        /root/.domain_type \
        /root/akun \
        /root/.bot_token \
        /root/.chat_id \
        /root/.payment_info \
        /root/.menu_theme \
        /etc/xray/xray.crt \
        /etc/xray/xray.key \
        /usr/local/etc/xray/config.json \
        2>/dev/null
    
    if [[ -f "$backup_dir/$backup_file" ]]; then
        clear
        draw_header "BACKUP COMPLETED"
        print_line ""
        print_info "Filename" "$backup_file"
        print_info "Size" "$(du -h "$backup_dir/$backup_file" | awk '{print $1}')"
        print_info "Location" "$backup_dir/"
        print_line ""
        draw_footer
    else
        echo -e "${RED}✗ Backup failed!${NC}"
    fi
    
    echo ""
    read -p "Press any key to back..."
}

_menu_restore() {
    clear
    draw_header "RESTORE SYSTEM"
    print_line ""
    
    local backup_dir="/root/backups"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_line "${RED}No backup directory!${NC}"
        draw_footer
        sleep 2
        return
    fi
    
    print_line "${WHITE}Available Backups:${NC}"
    print_line ""
    draw_footer
    echo ""
    
    shopt -s nullglob
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "${RED}No backups found!${NC}"
        sleep 2
        return
    fi
    
    local i=1
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | awk '{print $1}')
        printf " ${CYAN}[%d]${NC} %-40s ${YELLOW}%s${NC}\n" "$i" "$filename" "$size"
        ((i++))
    done
    
    echo ""
    read -p " Select [1-${#backups[@]}] or 0 to cancel: " choice
    
    if [[ "$choice" == "0" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]] || \
       [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#backups[@]}" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    local selected_backup="${backups[$((choice-1))]}"
    
    echo ""
    echo -e "${YELLOW}⚠️  This will overwrite current config!${NC}"
    read -p "Continue? [y/N]: " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    echo ""
    echo -e "${CYAN}Restoring...${NC}"
    tar -xzf "$selected_backup" -C / 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Restore successful!${NC}"
        echo -e "${YELLOW}Restarting services...${NC}"
        systemctl restart xray nginx haproxy 2>/dev/null
        echo -e "${GREEN}✓ Done!${NC}"
    else
        echo -e "${RED}✗ Restore failed!${NC}"
    fi
    
    echo ""
    read -p "Press any key to back..."
}

#================================================
# UNINSTALL MENU
#================================================

menu_uninstall() {
    while true; do
        clear
        draw_header "UNINSTALL MENU"
        print_menu_option "1" "Uninstall Xray"
        print_menu_option "2" "Uninstall Nginx"
        print_menu_option "3" "Uninstall HAProxy"
        print_menu_option "4" "Uninstall Dropbear"
        print_menu_option "5" "Uninstall UDP Custom"
        print_menu_option "6" "Uninstall Bot"
        print_menu_option "7" "Uninstall Keepalive"
        print_menu_option "8" "Uninstall Stunnel4"
        print_line ""
        print_line "${RED}[99] REMOVE ALL COMPONENTS${NC}"
        print_line ""
        print_menu_option "0" "Back to Main Menu"
        draw_footer
        echo ""
        read -p " Select: " choice
        
        case $choice in
            1) _uninstall_xray ;;
            2) _uninstall_nginx ;;
            3) _uninstall_haproxy ;;
            4) _uninstall_dropbear ;;
            5) _uninstall_udp ;;
            6) _uninstall_bot ;;
            7) _uninstall_keepalive ;;
            8) _uninstall_stunnel ;;
            99) _uninstall_all ;;
            0) return ;;
        esac
    done
}

_uninstall_xray() {
    clear
    draw_header "UNINSTALL XRAY"
    print_line ""
    print_line "${YELLOW}This will remove Xray and all accounts${NC}"
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop xray 2>/dev/null
    systemctl disable xray 2>/dev/null
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray
    rm -f "$AKUN_DIR"/vmess-*.txt "$AKUN_DIR"/vless-*.txt "$AKUN_DIR"/trojan-*.txt
    echo ""
    echo -e "${GREEN}✓ Xray uninstalled${NC}"
    sleep 2
}

_uninstall_nginx() {
    clear
    draw_header "UNINSTALL NGINX"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    apt-get purge -y nginx nginx-common >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}✓ Nginx uninstalled${NC}"
    sleep 2
}

_uninstall_haproxy() {
    clear
    draw_header "UNINSTALL HAPROXY"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop haproxy 2>/dev/null
    systemctl disable haproxy 2>/dev/null
    apt-get purge -y haproxy >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}✓ HAProxy uninstalled${NC}"
    sleep 2
}

_uninstall_dropbear() {
    clear
    draw_header "UNINSTALL DROPBEAR"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop dropbear 2>/dev/null
    systemctl disable dropbear 2>/dev/null
    apt-get purge -y dropbear >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}✓ Dropbear uninstalled${NC}"
    sleep 2
}

_uninstall_udp() {
    clear
    draw_header "UNINSTALL UDP CUSTOM"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop udp-custom 2>/dev/null
    systemctl disable udp-custom 2>/dev/null
    rm -f /etc/systemd/system/udp-custom.service
    rm -f /usr/local/bin/udp-custom
    systemctl daemon-reload
    echo -e "${GREEN}✓ UDP Custom uninstalled${NC}"
    sleep 2
}

_uninstall_bot() {
    clear
    draw_header "UNINSTALL TELEGRAM BOT"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop vpn-bot 2>/dev/null
    systemctl disable vpn-bot 2>/dev/null
    rm -f /etc/systemd/system/vpn-bot.service
    rm -rf /root/bot
    rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"
    systemctl daemon-reload
    echo -e "${GREEN}✓ Bot uninstalled${NC}"
    sleep 2
}

_uninstall_keepalive() {
    clear
    draw_header "UNINSTALL KEEPALIVE"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop vpn-keepalive 2>/dev/null
    systemctl disable vpn-keepalive 2>/dev/null
    rm -f /etc/systemd/system/vpn-keepalive.service
    rm -f /usr/local/bin/vpn-keepalive.sh
    systemctl daemon-reload
    echo -e "${GREEN}✓ Keepalive uninstalled${NC}"
    sleep 2
}

_uninstall_stunnel() {
    clear
    draw_header "UNINSTALL STUNNEL4"
    print_line ""
    draw_footer
    echo ""
    read -p " Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    
    systemctl stop stunnel4 2>/dev/null
    systemctl disable stunnel4 2>/dev/null
    apt-get purge -y stunnel4 >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "${GREEN}✓ Stunnel4 uninstalled${NC}"
    sleep 2
}

_uninstall_all() {
    clear
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}║              ⚠️  REMOVE ALL VPN COMPONENTS  ⚠️                ║${NC}"
    echo -e "${RED}║                                                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}This will remove ALL VPN components and data!${NC}"
    echo ""
    echo -e "${WHITE}Components to be removed:${NC}"
    echo -e " • Xray, Nginx, HAProxy, Dropbear, Stunnel4"
    echo -e " • UDP Custom, Keepalive, Telegram Bot"
    echo -e " • All accounts and configurations"
    echo -e " • SSL certificates"
    echo -e " • Backup files"
    echo ""
    read -p " Type 'DELETE' to confirm: " confirm
    
    if [[ "$confirm" != "DELETE" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 2
        return
    fi
    
    echo ""
    echo -e "${RED}Removing all components...${NC}"
    echo ""
    
    # Stop all services
    for svc in xray nginx haproxy dropbear stunnel4 \
               udp-custom vpn-keepalive vpn-bot; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        echo -e " ${RED}✗${NC} Stopped: $svc"
    done
    
    echo ""
    
    # Uninstall packages
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1
    apt-get purge -y nginx haproxy dropbear stunnel4 >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    
    # Remove files
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray \
           /root/akun /root/bot /root/orders /root/domain \
           /root/.domain_type /root/.bot_token /root/.chat_id \
           /root/.payment_info /root/.menu_theme /root/backups \
           /root/tunnel.sh.bak
    
    rm -f /etc/systemd/system/udp-custom.service \
          /etc/systemd/system/vpn-keepalive.service \
          /etc/systemd/system/vpn-bot.service \
          /usr/local/bin/udp-custom \
          /usr/local/bin/vpn-keepalive.sh \
          /usr/local/bin/menu \
          /root/tunnel.sh
    
    sed -i '/tunnel.sh/d' /root/.bashrc 2>/dev/null
    systemctl daemon-reload
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║            ✓ ALL COMPONENTS REMOVED SUCCESSFULLY              ║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    sleep 3
    exit 0
}

#================================================
# CHANGE MENU THEME
#================================================

change_menu_theme() {
    select_menu_theme
}

#================================================
# RESTART ALL SERVICES
#================================================

restart_all_services() {
    clear
    draw_header "RESTART ALL SERVICES"
    print_line ""
    
    for svc in xray nginx sshd dropbear haproxy \
               udp-custom vpn-keepalive vpn-bot stunnel4; do
        if systemctl restart "$svc" 2>/dev/null; then
            print_status "$svc" "RESTARTED"
        else
            print_status "$svc" "FAILED"
        fi
    done
    
    print_line ""
    draw_footer
    echo ""
    sleep 2
}

#================================================
# OPTIMIZE VPS
#================================================

optimize_vps() {
    clear
    draw_header "OPTIMIZE VPS"
    print_line ""
    print_line "${CYAN}Optimizing system...${NC}"
    draw_footer
    echo ""
    
    optimize_vpn
    
    echo -e "${GREEN}✓ BBR enabled${NC}"
    echo -e "${GREEN}✓ TCP tuning applied${NC}"
    echo -e "${GREEN}✓ File limits increased${NC}"
    echo -e "${GREEN}✓ Network optimized${NC}"
    echo ""
    read -p "Press any key to back..."
}
#================================================
# SMART INSTALLER - CHECK & SKIP IF INSTALLED
#================================================

smart_install() {
    show_install_banner
    
    # Setup domain first
    setup_domain
    [[ -z "$DOMAIN" ]] && {
        echo -e "${RED}Domain not configured!${NC}"
        exit 1
    }
    
    # Theme selection
    select_menu_theme
    
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")
    
    clear
    show_install_banner
    echo -e " Domain   : ${GREEN}${DOMAIN}${NC}"
    echo -e " SSL Type : ${GREEN}$(
        [[ "$domain_type" == "custom" ]] && \
        echo "Let's Encrypt" || echo "Self-Signed"
    )${NC}"
    echo -e " Theme    : ${GREEN}$(get_current_theme)${NC}"
    echo ""
    sleep 2
    
    local LOG="/tmp/install_$(date +%s).log"
    > "$LOG"
    
    # Helper functions
    _install_header() {
        local title="$1"
        echo ""
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        printf "${CYAN}║${NC}%*s${WHITE}%s${NC}%*s${CYAN}║${NC}\n" \
            $(( (62 - ${#title}) / 2 )) "" "$title" \
            $(( 62 - ${#title} - (62 - ${#title}) / 2 )) ""
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    }
    
    _ok() { echo -e "  ${GREEN}[✓]${NC} $1"; }
    _skip() { echo -e "  ${YELLOW}[⊘]${NC} $1 ${YELLOW}(already installed)${NC}"; }
    _fail() { echo -e "  ${RED}[✗]${NC} $1"; }
    
    _pkg() {
        local pkg="$1"
        if dpkg -l | grep -q "^ii.*$pkg"; then
            _skip "$pkg"
            return 0
        fi
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >> "$LOG" 2>&1
        [[ $? -eq 0 ]] && _ok "$pkg" || _fail "$pkg"
    }
    
    # Step 1: System Update
    _install_header "STEP 1 - SYSTEM UPDATE"
    echo -e "${CYAN}Updating package lists...${NC}"
    apt-get update -y >> "$LOG" 2>&1
    _ok "Package lists updated"
    echo -e "${CYAN}Upgrading system...${NC}"
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG" 2>&1
    _ok "System upgraded"
    
    # Step 2: Base Packages
    _install_header "STEP 2 - BASE PACKAGES"
    local base_pkgs=(
        curl wget unzip uuid-runtime net-tools
        openssl jq qrencode python3 python3-pip
        software-properties-common gnupg2 ca-certificates
        lsb-release apt-transport-https
    )
    for pkg in "${base_pkgs[@]}"; do
        _pkg "$pkg"
    done
    
    # Step 3: VPN Services
    _install_header "STEP 3 - VPN SERVICES"
    
    # Xray
    if is_installed "xray"; then
        _skip "Xray-core"
    else
        echo -e "${CYAN}Installing Xray-core...${NC}"
        bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
            >> "$LOG" 2>&1
        [[ $? -eq 0 ]] && _ok "Xray-core" || _fail "Xray-core"
    fi
    
    # Nginx
    if is_installed "nginx"; then
        _skip "Nginx"
    else
        _pkg "nginx"
    fi
    
    # OpenSSH
    if is_installed "sshd"; then
        _skip "OpenSSH Server"
    else
        _pkg "openssh-server"
    fi
    
    # Dropbear
    if is_installed "dropbear"; then
        _skip "Dropbear"
    else
        _pkg "dropbear"
    fi
    
    # HAProxy
    if is_installed "haproxy"; then
        _skip "HAProxy"
    else
        _pkg "haproxy"
    fi
    
    # Stunnel4
    if is_installed "stunnel4"; then
        _skip "Stunnel4"
    else
        _pkg "stunnel4"
    fi
    
    # Certbot
    if is_installed "certbot"; then
        _skip "Certbot"
    else
        _pkg "certbot"
    fi
    
    # Netcat
    _pkg "netcat-openbsd"
    
    # Step 4: Additional Tools
    _install_header "STEP 4 - ADDITIONAL TOOLS"
    
    # Fail2Ban
    if is_installed "fail2ban"; then
        _skip "Fail2Ban"
    else
        _pkg "fail2ban"
        systemctl enable fail2ban 2>/dev/null
        systemctl start fail2ban 2>/dev/null
    fi
    
    # UFW
    if is_installed "ufw"; then
        _skip "UFW Firewall"
    else
        _pkg "ufw"
        ufw --force enable >> "$LOG" 2>&1
        ufw allow 22,80,81,222,443,8444/tcp >> "$LOG" 2>&1
        ufw allow 7100:7300/tcp >> "$LOG" 2>&1
        ufw allow 7100:7300/udp >> "$LOG" 2>&1
        _ok "UFW configured"
    fi
    
    # Unbound DNS
    if is_installed "unbound"; then
        _skip "Unbound DNS"
    else
        _pkg "unbound"
        systemctl enable unbound 2>/dev/null
        systemctl start unbound 2>/dev/null
    fi
    
    # vnStat
    if is_installed "vnstat"; then
        _skip "vnStat"
    else
        _pkg "vnstat"
        systemctl enable vnstat 2>/dev/null
        systemctl start vnstat 2>/dev/null
    fi
    
    # Netdata (optional monitoring)
    if is_installed "netdata"; then
        _skip "Netdata"
    else
        echo -e "${CYAN}Installing Netdata...${NC}"
        bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait >> "$LOG" 2>&1
        [[ $? -eq 0 ]] && _ok "Netdata" || _skip "Netdata (optional)"
    fi
    
    # Step 5: System Optimization
    _install_header "STEP 5 - SYSTEM OPTIMIZATION"
    
    # BBR
    if is_installed "bbr"; then
        _skip "BBR TCP Congestion"
    else
        echo -e "${CYAN}Enabling BBR...${NC}"
        modprobe tcp_bbr 2>/dev/null
        echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
        _ok "BBR enabled"
    fi
    
    # Swap
    if is_installed "swap"; then
        _skip "Swapfile"
    else
        echo -e "${CYAN}Creating 2GB swapfile...${NC}"
        setup_swap
        _ok "Swapfile 2GB"
    fi
    
    # Sysctl tuning
    echo -e "${CYAN}Applying network tuning...${NC}"
    optimize_vpn
    _ok "Network optimized"
    
    # Logrotate
    if command -v logrotate >/dev/null 2>&1; then
        _skip "Logrotate"
    else
        _pkg "logrotate"
    fi
    
    # Cron
    if systemctl is-active --quiet cron 2>/dev/null; then
        _skip "Cron"
    else
        _pkg "cron"
        systemctl enable cron 2>/dev/null
        systemctl start cron 2>/dev/null
    fi
    
    # Step 6: SSL Certificate
    _install_header "STEP 6 - SSL CERTIFICATE"
    echo -e "${CYAN}Getting SSL certificate...${NC}"
    mkdir -p /etc/xray
    
    if [[ "$domain_type" == "custom" ]]; then
        echo -e "${CYAN}Trying Let's Encrypt...${NC}"
        certbot certonly --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos \
            --register-unsafely-without-email >> "$LOG" 2>&1
        
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key
            _ok "Let's Encrypt certificate"
        else
            echo -e "${YELLOW}Let's Encrypt failed, using self-signed...${NC}"
            _gen_self_signed
            _ok "Self-signed certificate"
        fi
    else
        _gen_self_signed
        _ok "Self-signed certificate for $DOMAIN"
    fi
    chmod 644 /etc/xray/xray.* 2>/dev/null
    
    # Step 7: Configure Services
    _install_header "STEP 7 - SERVICE CONFIGURATION"
    
    echo -e "${CYAN}Creating Xray config...${NC}"
    create_xray_config
    _ok "Xray config (8 inbounds)"
    
    echo -e "${CYAN}Configuring Nginx...${NC}"
    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    
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
        proxy_read_timeout 86400s;
    }
    
    location /vless {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400s;
    }
    
    location /trojan {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400s;
    }
}

server {
    listen 81;
    server_name _;
    root /var/www/html;
    autoindex on;
}
NGXEOF
    _ok "Nginx configured"
    
    echo -e "${CYAN}Configuring Dropbear...${NC}"
    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    _ok "Dropbear port 222"
    
    echo -e "${CYAN}Configuring HAProxy...${NC}"
    configure_haproxy
    _ok "HAProxy 443 → 8443"
    
    # Step 8: Additional Services
    _install_header "STEP 8 - ADDITIONAL SERVICES"
    
    echo -e "${CYAN}Installing UDP Custom...${NC}"
    install_udp_custom
    _ok "UDP Custom 7100-7300"
    
    echo -e "${CYAN}Setting up Keepalive...${NC}"
    setup_keepalive
    _ok "Keepalive service"
    
    echo -e "${CYAN}Setting up menu command...${NC}"
    setup_menu_command
    _ok "Menu command (type: menu)"
    
    # Step 9: Create Web Index
    _install_header "STEP 9 - WEB INTERFACE"
    
    local ip_vps=$(get_ip)
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>VPN Server - ${DOMAIN}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;
     background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);
     min-height:100vh;display:flex;align-items:center;
     justify-content:center;color:#fff}
.container{max-width:500px;padding:40px;background:rgba(255,255,255,0.1);
           backdrop-filter:blur(10px);border-radius:20px;
           box-shadow:0 8px 32px rgba(0,0,0,0.3);text-align:center}
h1{font-size:2.5em;margin-bottom:10px;text-shadow:2px 2px 4px rgba(0,0,0,0.3)}
.domain{font-size:1.2em;color:#e0e0e0;margin-bottom:20px}
.ip{color:#ffd700;font-weight:bold}
.badge{display:inline-block;background:rgba(255,255,255,0.2);
       padding:8px 20px;border-radius:25px;margin-top:20px;
       font-size:0.9em;text-transform:uppercase;letter-spacing:2px}
.stats{display:grid;grid-template-columns:1fr 1fr;gap:15px;margin-top:30px}
.stat-box{background:rgba(255,255,255,0.15);padding:15px;border-radius:10px}
.stat-label{font-size:0.8em;opacity:0.8}
.stat-value{font-size:1.5em;font-weight:bold;margin-top:5px}
</style>
</head>
<body>
<div class="container">
<h1>🚀 VPN Server</h1>
<div class="domain">${DOMAIN}</div>
<div class="ip">${ip_vps}</div>
<div class="badge">Online & Ready</div>
<div class="stats">
<div class="stat-box">
<div class="stat-label">SSL</div>
<div class="stat-value">✓</div>
</div>
<div class="stat-box">
<div class="stat-label">Status</div>
<div class="stat-value">Active</div>
</div>
</div>
</div>
</body>
</html>
IDXEOF
    _ok "Web index page"
    
    # Step 10: Start Services
    _install_header "STEP 10 - START SERVICES"
    
    systemctl daemon-reload >> "$LOG" 2>&1
    
    local services=(xray nginx sshd dropbear haproxy udp-custom vpn-keepalive)
    for svc in "${services[@]}"; do
        systemctl enable "$svc" >> "$LOG" 2>&1
        systemctl restart "$svc" >> "$LOG" 2>&1
        if systemctl is-active --quiet "$svc"; then
            _ok "$svc"
        else
            _fail "$svc"
        fi
    done
    
    # Summary
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║         ✓  INSTALLATION COMPLETED SUCCESSFULLY!             ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "Domain" "$DOMAIN"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "IP Address" "$ip_vps"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "SSL Type" \
        "$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "Menu Theme" "$(get_current_theme)"
    echo ""
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "SSH" "22"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Dropbear" "222"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray TLS" "443"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray NonTLS" "80"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray gRPC" "8444"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "BadVPN UDP" "7100-7300"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Web Panel" "http://${ip_vps}:81/"
    echo ""
    printf "  ${WHITE}%-20s${NC}: ${YELLOW}%s${NC}\n" "Install Log" "$LOG"
    printf "  ${WHITE}%-20s${NC}: ${YELLOW}%s${NC}\n" "Support" "@ridhani16"
    echo ""
    echo -e "  ${GREEN}💡 Type '${WHITE}menu${GREEN}' to open VPN Manager!${NC}"
    echo ""
    echo -e "  ${YELLOW}Rebooting in 5 seconds...${NC}"
    sleep 5
    reboot
}

#================================================
# MAIN MENU LOOP
#================================================

main_menu() {
    while true; do
        show_system_info
        show_menu
        read -p " Enter choice: " choice

        case $choice in
            1) menu_ssh ;;
            2) menu_vmess ;;
            3) menu_vless ;;
            4) menu_trojan ;;
            5) menu_trial_generator ;;
            6) list_all_accounts ;;
            7) cek_expired ;;
            8) delete_expired ;;
            9) menu_telegram_bot ;;
            10) change_domain ;;
            11) fix_certificate ;;
            12) optimize_vps ;;
            13) restart_all_services ;;
            14) show_info_port ;;
            15) run_speedtest ;;
            16) update_menu ;;
            17) _menu_backup ;;
            18) _menu_restore ;;
            19) menu_uninstall ;;
            20) change_menu_theme ;;
            99) menu_advanced ;;
            0)
                clear
                echo -e "${CYAN}Goodbye!${NC}"
                exit 0
                ;;
            help|HELP)
                show_help ;;
            rollback)
                rollback_script ;;
            *)
                ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

# Must run as root
[[ $EUID -ne 0 ]] && {
    echo -e "${RED}This script must be run as root!${NC}"
    echo "Usage: sudo bash $0"
    exit 1
}

# Load domain
[[ -f "$DOMAIN_FILE" ]] && \
    DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

# First time installation
if [[ ! -f "$DOMAIN_FILE" ]]; then
    smart_install
fi

# Ensure menu command exists
setup_menu_command

# Run main menu
main_menu
