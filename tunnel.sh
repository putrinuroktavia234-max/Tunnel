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

SSH_PORT="22"; DROPBEAR_PORT="222"; NGINX_PORT="80"; NGINX_DL_PORT="81"
HAPROXY_PORT="443"; XRAY_INTERNAL_TLS="8443"; XRAY_WS_NONTLS_PORT="8080"
XRAY_GRPC_PORT="8444"; BADVPN_RANGE="7100-7300"; PRICE_MONTHLY="10000"
DURATION_MONTHLY="30"

#================================================
# BOX DRAWING — W=51 inner width (53 total)
#================================================
W=51

_rep() { local s=""; for ((i=0;i<$2;i++)); do s+="$1"; done; printf "%s" "$s"; }
_box_top()  { echo -e "${CYAN}╔$(_rep '═' $W)╗${NC}"; }
_box_mid()  { echo -e "${CYAN}╠$(_rep '═' $W)╣${NC}"; }
_box_bot()  { echo -e "${CYAN}╚$(_rep '═' $W)╝${NC}"; }
_box_thin() { echo -e "${CYAN}╠$(_rep '─' $W)╣${NC}"; }
_box_empty(){ echo -e "${CYAN}║$(_rep ' ' $W)║${NC}"; }

# Center text: $1=text $2=color $3=visual_len_override(for multibyte)
_box_center() {
    local txt="$1" color="${2:-$WHITE}" vlen="${3:-${#1}}"
    local pad_l=$(( (W - vlen) / 2 )) pad_r=$(( W - vlen - (W - vlen) / 2 ))
    local lsp="" rsp=""
    for ((i=0;i<pad_l;i++)); do lsp+=" "; done
    for ((i=0;i<pad_r;i++)); do rsp+=" "; done
    echo -e "${CYAN}║${NC}${lsp}${color}${txt}${NC}${rsp}${CYAN}║${NC}"
}

# Left row: $1=pre-colored-text $2=visible-length
_box_row() {
    local txt="$1" vlen="$2"
    local pad=$(( W - 2 - vlen )); local sp=""
    for ((i=0;i<pad;i++)); do sp+=" "; done
    echo -e "${CYAN}║${NC} ${txt}${sp} ${CYAN}║${NC}"
}

# 2-column row: $1=left $2=right $3=left-vlen $4=right-vlen
_box_2col() {
    local l="$1" r="$2" ll="${3:-${#1}}" rl="${4:-${#2}}"
    local inner=$((W-2)) half=$((( W - 2 ) / 2))
    local lpad=$(( half - ll - 1 )) rpad=$(( inner - half - rl - 1 ))
    local lsp="" rsp=""
    for ((i=0;i<lpad;i++)); do lsp+=" "; done
    for ((i=0;i<rpad;i++)); do rsp+=" "; done
    echo -e "${CYAN}║${NC} ${l}${lsp} ${r}${rsp} ${CYAN}║${NC}"
}

# Service status 2-col: $1=name1 $2=ON/OFF $3=name2 $4=ON/OFF
_svc2() {
    local l1="$1" s1="$2" l2="$3" s2="$4"
    local c1 c2
    [[ "$s1" == "ON" ]] && c1="${GREEN}● ONLINE ${NC}" || c1="${RED}○ OFFLINE${NC}"
    [[ "$s2" == "ON" ]] && c2="${GREEN}● ONLINE ${NC}" || c2="${RED}○ OFFLINE${NC}"
    local inner=$((W-2)) half=$(((W-2)/2))
    local l1l=${#l1} l2l=${#l2} sv=9
    local lpad=$(( half - 1 - l1l - 2 - sv ))
    local rpad=$(( inner - half - 1 - l2l - 2 - sv ))
    local lsp="" rsp=""
    for ((i=0;i<lpad;i++)); do lsp+=" "; done
    for ((i=0;i<rpad;i++)); do rsp+=" "; done
    echo -e "${CYAN}║${NC} ${WHITE}${l1}${NC}  ${c1}${lsp} ${WHITE}${l2}${NC}  ${c2}${rsp} ${CYAN}║${NC}"
}

# Legacy aliases
_center_title() { _box_center "$1" "${2:-$WHITE}"; }
_section_line() {
    case "$1" in top) _box_top;; mid) _box_mid;; bot) _box_bot;; thin) _box_thin;; esac
}
print_menu_header() { _box_top; _box_center "$1"; _box_mid; }
print_menu_footer()  { _box_bot; }

#================================================
# SCRIPT EXPIRY SYSTEM
#================================================
setup_expiry() {
    local days="${1:-30}"
    local exp_ts=$(( $(date +%s) + days * 86400 ))
    local exp_str=$(date -d "@${exp_ts}" +"%Y-%m-%d")
    echo "${exp_ts}|${exp_str}|${days}" > "$EXPIRY_FILE"; chmod 600 "$EXPIRY_FILE"
}

check_expiry() {
    [[ ! -f "$EXPIRY_FILE" ]] && { setup_expiry 30; return 0; }
    local data exp_ts now
    data=$(cat "$EXPIRY_FILE"); exp_ts=$(echo "$data" | cut -d'|' -f1); now=$(date +%s)
    if [[ "$now" -gt "$exp_ts" ]]; then
        clear
        local exp_str=$(echo "$data" | cut -d'|' -f2)
        _box_top; _box_center "!! SCRIPT EXPIRED !!" "$RED"; _box_mid
        _box_row "${NC}  Kadaluarsa: ${YELLOW}${exp_str}${NC}" $(( 14 + ${#exp_str} ))
        _box_row "${NC}  Hubungi: ${CYAN}@ridhani16${NC}" 19; _box_bot; exit 1
    fi
    local sisa=$(( (exp_ts - now) / 86400 ))
    [[ "$sisa" -le 5 ]] && { echo -e "${YELLOW}⚠  Script expired dalam ${sisa} hari!${NC}"; sleep 2; }
    return 0
}

get_expiry_info() {
    [[ ! -f "$EXPIRY_FILE" ]] && echo "Belum diset" && return
    local data=$(cat "$EXPIRY_FILE")
    local exp_ts=$(echo "$data" | cut -d'|' -f1)
    local exp_str=$(echo "$data" | cut -d'|' -f2)
    local sisa=$(( (exp_ts - $(date +%s)) / 86400 ))
    [[ "$exp_ts" -eq 0 ]] && echo "Tidak Ada" || echo "${exp_str} (sisa ${sisa} hari)"
}

menu_expiry() {
    while true; do
        clear; _box_top; _box_center "KELOLA EXPIRY SCRIPT"; _box_mid
        local ei=$(get_expiry_info)
        _box_row "${WHITE}Status :${NC} ${ei}" $(( 8 + ${#ei} ))
        _box_mid
        _box_2col "${CYAN}[1]${NC} Set Expiry Baru"   "${CYAN}[3]${NC} Reset 30 hari" $(( 3+15 )) $(( 3+13 ))
        _box_2col "${CYAN}[2]${NC} Perpanjang Expiry" "${CYAN}[4]${NC} Nonaktifkan"   $(( 3+17 )) $(( 3+11 ))
        _box_mid; _box_2col "${CYAN}[0]${NC} Kembali" "" $(( 3+7 )) 0; _box_bot; echo ""
        read -p " Select [0-4]: " ch
        case $ch in
            1) read -p " Lama (hari): " hari; [[ "$hari" =~ ^[0-9]+$ ]] && { setup_expiry "$hari"; echo -e "${GREEN}Diset ${hari} hari!${NC}"; } || echo -e "${RED}Invalid!${NC}"; sleep 2 ;;
            2)
                read -p " Tambah berapa hari: " hari
                [[ ! "$hari" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid!${NC}"; sleep 2; continue; }
                local cur_ts=0; [[ -f "$EXPIRY_FILE" ]] && cur_ts=$(cut -d'|' -f1 < "$EXPIRY_FILE")
                local now_ts=$(date +%s); [[ "$cur_ts" -lt "$now_ts" ]] && cur_ts=$now_ts
                local new_ts=$(( cur_ts + hari * 86400 ))
                local new_str=$(date -d "@${new_ts}" +"%Y-%m-%d")
                echo "${new_ts}|${new_str}|${hari}" > "$EXPIRY_FILE"
                echo -e "${GREEN}Diperpanjang ${hari} hari! Baru: ${new_str}${NC}"; sleep 2 ;;
            3) setup_expiry 30; echo -e "${GREEN}Reset ke 30 hari!${NC}"; sleep 2 ;;
            4) echo "0|9999-99-99|0" > "$EXPIRY_FILE"; echo -e "${GREEN}Dinonaktifkan!${NC}"; sleep 2 ;;
            0) return ;;
        esac
    done
}

#================================================
# PROGRESS BAR + MESSAGES
#================================================
progress_bar() {
    local w=30 filled=$(( $1 * 30 / $2 )) pct=$(( $1 * 100 / $2 )) bar=""
    for ((i=0;i<filled;i++)); do bar+="="; done
    [[ $filled -lt $w ]] && { bar+=">"; for ((i=0;i<w-filled-1;i++)); do bar+=" "; done; }
    printf "\r ${CYAN}[${NC}${GREEN}%-${w}s${NC}${CYAN}]${NC} ${WHITE}%3d%%${NC} %s" "$bar" "$pct" "$3"
}
show_progress() { progress_bar "$1" "$2" "$3"; echo ""; }
done_msg() { printf "  ${GREEN}[✓]${NC} %-42s\n" "$1"; }
fail_msg() { printf "  ${RED}[✗]${NC} %-42s\n" "$1"; }
info_msg() { printf "  ${CYAN}[~]${NC} %s\n" "$1"; }

#================================================
# BANNER
#================================================
show_install_banner() {
    clear; echo -e "${CYAN}"
    cat << 'ASCIIEOF'
⢀⡟⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠹⣿⣿⣿⣿⣿⣿⣿⣿⡄⠄
⢸⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣿⣿⣿⣿⣿⣿⣿⡀
⣾⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⠻⣿⣿⠸⣿⣿⣿⣿⣿⡿⠻⢿⡇
ASCIIEOF
    echo -e "${NC}"
    echo -e "${WHITE}        VPN AUTO SCRIPT v${SCRIPT_VERSION}${NC}"
    echo -e "${CYAN}        By The Proffessor Squad${NC}"
    echo ""
}

#================================================
# UTILITY
#================================================
check_status() { systemctl is-active --quiet "$1" 2>/dev/null && echo "ON" || echo "OFF"; }
get_ip() {
    local ip
    for url in "https://ifconfig.me" "https://ipinfo.io/ip" "https://api.ipify.org" "https://checkip.amazonaws.com"; do
        ip=$(curl -s --max-time 3 "$url" 2>/dev/null)
        [[ -n "$ip" ]] && ! echo "$ip" | grep -q "error\|reset\|refused\|<" && { echo "$ip"; return; }
    done
    ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    echo "${ip:-N/A}"
}
send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    [[ ! -f "$CHAT_ID_FILE" ]] && return
    curl -s -X POST "https://api.telegram.org/bot$(cat $BOT_TOKEN_FILE)/sendMessage" \
        -d chat_id="$(cat $CHAT_ID_FILE)" -d text="$1" -d parse_mode="HTML" --max-time 10 >/dev/null 2>&1
}

#================================================
# DOMAIN SETUP
#================================================
generate_random_domain() {
    local ip_vps=$(get_ip) chars="abcdefghijklmnopqrstuvwxyz" rs=""
    for i in {1..6}; do rs+="${chars:RANDOM%26:1}"; done
    echo "${rs}.${ip_vps}.nip.io"
}

setup_domain() {
    clear; local prev=$(generate_random_domain)
    _box_top; _box_center "SETUP DOMAIN"; _box_mid; _box_empty
    _box_row "${CYAN}[1]${NC} Domain sendiri — SSL: Let's Encrypt" 38
    _box_empty
    _box_row "${CYAN}[2]${NC} Domain otomatis — SSL: Self-Signed" 36
    _box_row "    ${YELLOW}Contoh: ${prev}${NC}" $(( 12 + ${#prev} ))
    _box_empty; _box_bot; echo ""
    read -p " Pilih [1/2]: " dc
    case $dc in
        1)  read -p " Masukkan domain: " input_domain
            [[ -z "$input_domain" ]] && { echo -e "${RED}Domain kosong!${NC}"; sleep 2; setup_domain; return; }
            DOMAIN="$input_domain"; echo "custom" > "$DOMAIN_TYPE_FILE" ;;
        2)  DOMAIN=$(generate_random_domain); echo "random" > "$DOMAIN_TYPE_FILE"
            echo -e "${GREEN}Domain: ${CYAN}${DOMAIN}${NC}"; sleep 1 ;;
        *)  echo -e "${RED}Tidak valid!${NC}"; sleep 1; setup_domain; return ;;
    esac
    echo "$DOMAIN" > "$DOMAIN_FILE"
}

get_ssl_cert() {
    local dt="custom"; [[ -f "$DOMAIN_TYPE_FILE" ]] && dt=$(cat "$DOMAIN_TYPE_FILE")
    mkdir -p /etc/xray
    if [[ "$dt" == "custom" ]]; then
        certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos \
            --register-unsafely-without-email >/dev/null 2>&1
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key
        else _gen_self_signed; fi
    else _gen_self_signed; fi
    chmod 644 /etc/xray/xray.* 2>/dev/null
}

_gen_self_signed() {
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
}

setup_menu_command() {
    cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh || echo "Script not found!"
MENUEOF
    chmod +x /usr/local/bin/menu
    grep -q "tunnel.sh" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'BASHEOF'
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh
BASHEOF
}

setup_swap() {
    clear; _box_top; _box_center "SETUP SWAP 1GB"; _box_bot; echo ""
    local st=$(free -m | awk 'NR==3{print $2}')
    [[ "$st" -gt 0 ]] && { swapoff -a 2>/dev/null; sed -i '/swapfile/d' /etc/fstab; rm -f /swapfile; }
    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile; mkswap /swapfile >/dev/null 2>&1; swapon /swapfile
    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo -e "${GREEN}Swap 1GB OK!${NC}"; sleep 2
}

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

setup_keepalive() {
    local sc="/etc/ssh/sshd_config"
    for kv in "ClientAliveInterval 30" "ClientAliveCountMax 6" "TCPKeepAlive yes"; do
        local k=$(echo "$kv" | awk '{print $1}')
        grep -q "^${k}" "$sc" && sed -i "s/^${k}.*/${kv}/" "$sc" || echo "$kv" >> "$sc"
    done
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

change_domain() {
    clear; _box_top; _box_center "CHANGE DOMAIN"; _box_mid
    _box_row "${WHITE}Current :${NC} ${DOMAIN:-Not Set}" $(( 10 + ${#DOMAIN:-8} ))
    _box_bot; echo ""
    setup_domain; echo -e "${YELLOW}Run Fix Certificate [11]!${NC}"; sleep 3
}

fix_certificate() {
    clear; _box_top; _box_center "FIX / RENEW CERTIFICATE"; _box_mid
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    if [[ -z "$DOMAIN" ]]; then
        _box_row "${RED}Domain belum diset!${NC}" 19; _box_bot; sleep 3; return
    fi
    _box_row "${WHITE}Domain :${NC} ${DOMAIN}" $(( 9 + ${#DOMAIN} )); _box_bot; echo ""
    systemctl stop haproxy 2>/dev/null; systemctl stop nginx 2>/dev/null; sleep 1
    get_ssl_cert
    systemctl start nginx 2>/dev/null; systemctl start haproxy 2>/dev/null; systemctl restart xray 2>/dev/null
    echo -e "${GREEN}Done!${NC}"; sleep 3
}

run_speedtest() {
    clear; _box_top; _box_center "SPEEDTEST BY OOKLA"; _box_bot; echo ""
    if ! command -v speedtest >/dev/null 2>&1; then
        echo -e "${CYAN}Installing Speedtest CLI...${NC}"
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
    fi
    echo -e "${YELLOW}Testing... harap tunggu ~30 detik${NC}"; echo ""
    if command -v speedtest >/dev/null 2>&1; then
        local result=$(speedtest --accept-license --accept-gdpr 2>/dev/null)
        if [[ -n "$result" ]]; then
            local srv=$(echo "$result" | grep "Server:" | sed 's/.*Server: //')
            local lat=$(echo "$result" | grep "Latency:" | awk '{print $2,$3}')
            local dl=$(echo "$result" | grep "Download:" | awk '{print $2,$3}')
            local ul=$(echo "$result" | grep "Upload:" | awk '{print $2,$3}')
            _box_top; _box_center "Speedtest Results"; _box_mid
            _box_row "${WHITE}Server  :${NC} ${srv:0:38}" 47
            _box_row "${WHITE}Latency :${NC} ${lat}" $(( 9 + ${#lat} ))
            _box_row "${GREEN}Download:${NC} ${dl}" $(( 9 + ${#dl} ))
            _box_row "${GREEN}Upload  :${NC} ${ul}" $(( 9 + ${#ul} ))
            _box_bot
        else echo -e "${RED}Speedtest gagal!${NC}"; fi
    else echo -e "${RED}Speedtest tidak tersedia!${NC}"; fi
    echo ""; read -p "Press any key to back on menu..."
}

#================================================
# SHOW SYSTEM INFO (Dashboard)
#================================================
show_system_info() {
    local ip=$(get_ip)
    local os=$(lsb_release -d 2>/dev/null | cut -f2 | sed 's/Description:\s*//' || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)
    local uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | tr -d ' ')
    local ram_used=$(free -m | awk 'NR==2{print $3}')
    local ram_total=$(free -m | awk 'NR==2{print $2}')
    local ssl_type="Self-Signed"; [[ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]] && ssl_type="Let's Encrypt"
    local svc_total=8 svc_on=0
    local svcs=("xray" "nginx" "sshd" "dropbear" "haproxy" "udp-custom" "vpn-bot" "vpn-keepalive")
    for s in "${svcs[@]}"; do systemctl is-active --quiet "$s" 2>/dev/null && ((svc_on++)); done

    local ssh_count=0 vmess_count=0 vless_count=0 trojan_count=0
    [[ -d "$AKUN_DIR/ssh" ]] && ssh_count=$(ls "$AKUN_DIR/ssh" 2>/dev/null | wc -l)
    [[ -d "$AKUN_DIR/vmess" ]] && vmess_count=$(ls "$AKUN_DIR/vmess" 2>/dev/null | wc -l)
    [[ -d "$AKUN_DIR/vless" ]] && vless_count=$(ls "$AKUN_DIR/vless" 2>/dev/null | wc -l)
    [[ -d "$AKUN_DIR/trojan" ]] && trojan_count=$(ls "$AKUN_DIR/trojan" 2>/dev/null | wc -l)

    local vps_expiry="N/A" sisa_hari=""
    if [[ -f /root/.vps_expiry ]]; then
        vps_expiry=$(cat /root/.vps_expiry)
        local now_ts=$(date +%s) exp_ts
        exp_ts=$(date -d "$vps_expiry" +%s 2>/dev/null || echo 0)
        [[ "$exp_ts" -gt 0 ]] && sisa_hari=$(( (exp_ts - now_ts) / 86400 ))
    fi

    local st_xray=$(check_status "xray")
    local st_nginx=$(check_status "nginx")
    local st_haproxy=$(check_status "haproxy")
    local st_drop=$(check_status "dropbear")
    local st_ssh=$(check_status "sshd")
    local st_udp=$(check_status "udp-custom")
    local st_tg=$(check_status "vpn-bot")
    local st_ka=$(check_status "vpn-keepalive")

    # Header
    _box_top
    _box_center "YOUZINCRABZ PANEL" "$CYAN"
    local subtitle="Premium Edition • Proffessor Squad • @ridhani16"
    _box_center "$subtitle" "$WHITE" 47
    _box_mid

    # Server info
    _box_center "SERVER CORE STATUS" "$YELLOW"
    _box_mid
    _box_row "${WHITE}Domain  :${NC} ${CYAN}${DOMAIN:-Not Set}${NC}" $(( 10 + ${#DOMAIN:-8} ))
    _box_row "${WHITE}IP Addr :${NC} ${CYAN}${ip}${NC}" $(( 10 + ${#ip} ))
    _box_row "${WHITE}OS      :${NC} ${os:0:38}" $(( 10 + ${#os} < 49 ? 10 + ${#os} : 49 ))
    _box_row "${WHITE}Uptime  :${NC} ${uptime_str}" $(( 10 + ${#uptime_str} ))

    # CPU + RAM row
    local cpu_str="CPU Load: ${cpu_usage}%"
    local ram_str="RAM : ${ram_used} / ${ram_total} MB"
    _box_2col "${WHITE}${cpu_str}${NC}" "${WHITE}${ram_str}${NC}" ${#cpu_str} ${#ram_str}

    # SSL + Services row
    local ssl_str="SSL     : ${ssl_type}"
    local svc_str="Services : ${svc_on} / ${svc_total} Running"
    _box_2col "${WHITE}${ssl_str}${NC}" "${WHITE}${svc_str}${NC}" ${#ssl_str} ${#svc_str}

    # VPS expiry
    if [[ -n "$sisa_hari" ]]; then
        local exp_row="VPS Expiry : ${vps_expiry} (${sisa_hari} Day Remaining)"
        _box_row "${WHITE}${exp_row}${NC}" ${#exp_row}
    fi
    _box_mid

    # Active accounts
    _box_center "ACTIVE ACCOUNTS" "$YELLOW"
    _box_mid
    local acc_str="SSH: ${ssh_count}  VMess: ${vmess_count}  VLess: ${vless_count}  Trojan: ${trojan_count}"
    _box_row "${WHITE}${acc_str}${NC}" ${#acc_str}
    _box_mid

    # Network services
    _box_center "NETWORK SERVICES" "$YELLOW"
    _box_mid
    _svc2 "XRAY"     "$st_xray"   "NGINX"    "$st_nginx"
    _svc2 "HAPROXY"  "$st_haproxy" "DROPBEAR" "$st_drop"
    _svc2 "OPENSSH"  "$st_ssh"    "UDP CUST" "$st_udp"
    _svc2 "TELEGRAM" "$st_tg"     "KEEPALIV" "$st_ka"
    _box_bot
}

#================================================
# MAIN MENU
#================================================
show_menu() {
    _box_top
    _box_center "CONTROL CENTER" "$CYAN"
    _box_mid

    # Account Management
    _box_center "ACCOUNT MANAGEMENT" "$YELLOW"
    _box_thin
    _box_2col "${CYAN}[1]${NC} Create SSH / OVPN" "${CYAN}[5]${NC} Trial Xray" $(( 3+16 )) $(( 3+10 ))
    _box_2col "${CYAN}[2]${NC} Create VMess"       "${CYAN}[6]${NC} List Accounts" $(( 3+12 )) $(( 3+13 ))
    _box_2col "${CYAN}[3]${NC} Create VLess"       "${CYAN}[7]${NC} Check Expired" $(( 3+12 )) $(( 3+13 ))
    _box_2col "${CYAN}[4]${NC} Create Trojan"      "${CYAN}[8]${NC} Delete Expired" $(( 3+13 )) $(( 3+14 ))
    _box_mid

    # System Control
    _box_center "SYSTEM CONTROL" "$YELLOW"
    _box_thin
    _box_2col "${CYAN}[9]${NC}  Telegram Bot"    "${CYAN}[15]${NC} Speedtest VPS"  $(( 3+13 )) $(( 4+13 ))
    _box_2col "${CYAN}[10]${NC} Change Domain"   "${CYAN}[16]${NC} Update Panel"   $(( 4+13 )) $(( 4+12 ))
    _box_2col "${CYAN}[11]${NC} Fix SSL / Cert"  "${CYAN}[17]${NC} Backup Config"  $(( 4+14 )) $(( 4+13 ))
    _box_2col "${CYAN}[12]${NC} Optimize VPS"    "${CYAN}[18]${NC} Restore Config" $(( 4+12 )) $(( 4+14 ))
    _box_2col "${CYAN}[13]${NC} Restart Service" "${CYAN}[19]${NC} Uninstall Panel" $(( 4+15 )) $(( 4+15 ))
    _box_2col "${CYAN}[14]${NC} Port Info"       "${CYAN}[20]${NC} Expiry Manager" $(( 4+9 )) $(( 4+14 ))
    _box_mid

    # Bottom
    _box_2col "${CYAN}[0]${NC} Exit Panel" "${CYAN}[99]${NC} Advanced Mode" $(( 3+10 )) $(( 4+13 ))
    _box_mid

    # Footer info
    _box_row "${WHITE}Security :${NC} Encrypted Connection Active" $(( 10+25 ))
    _box_row "${WHITE}Tips     :${NC} Type help for command list"  $(( 10+24 ))
    _box_row "${WHITE}License  :${NC} Premium Edition"             $(( 10+15 ))
    _box_row "${WHITE}Support  :${NC} Telegram @ridhani16"         $(( 10+18 ))
    _box_bot
}

#================================================
# INFO PORT
#================================================
show_info_port() {
    clear; _box_top; _box_center "PORT INFORMATION"; _box_mid
    _box_row "${WHITE}SSH Standart :${NC} ${SSH_PORT}" $(( 14 + ${#SSH_PORT} ))
    _box_row "${WHITE}Dropbear     :${NC} ${DROPBEAR_PORT}" $(( 14 + ${#DROPBEAR_PORT} ))
    _box_row "${WHITE}Nginx        :${NC} ${NGINX_PORT}, ${NGINX_DL_PORT}" $(( 16 + ${#NGINX_PORT} + ${#NGINX_DL_PORT} ))
    _box_row "${WHITE}HAProxy TLS  :${NC} ${HAPROXY_PORT}" $(( 14 + ${#HAPROXY_PORT} ))
    _box_row "${WHITE}Xray TLS     :${NC} ${XRAY_INTERNAL_TLS}" $(( 14 + ${#XRAY_INTERNAL_TLS} ))
    _box_row "${WHITE}Xray WS      :${NC} ${XRAY_WS_NONTLS_PORT}" $(( 14 + ${#XRAY_WS_NONTLS_PORT} ))
    _box_row "${WHITE}Xray gRPC    :${NC} ${XRAY_GRPC_PORT}" $(( 14 + ${#XRAY_GRPC_PORT} ))
    _box_row "${WHITE}BadVPN UDP   :${NC} ${BADVPN_RANGE}" $(( 14 + ${#BADVPN_RANGE} ))
    _box_bot
    echo ""; read -p " Press any key..."
}

#================================================
# SHOW HELP
#================================================
_show_help() {
    clear; _box_top; _box_center "HELP - COMMAND LIST"; _box_mid
    _box_row "${CYAN}menu${NC}      - Open this panel" 22
    _box_row "${CYAN}add-ssh${NC}   - Add SSH account" 24
    _box_row "${CYAN}del-ssh${NC}   - Delete SSH account" 26
    _box_row "${CYAN}check-ssh${NC} - Check SSH accounts" 27
    _box_row "${CYAN}add-vmess${NC} - Add VMess account" 25
    _box_row "${CYAN}add-vless${NC} - Add VLess account" 25
    _box_row "${CYAN}add-trojan${NC}- Add Trojan account" 27
    _box_bot; echo ""
    read -p " Press any key..."
}

#================================================
# SSH / OPENVPN MANAGEMENT
#================================================
menu_ssh() {
    while true; do
        clear; _box_top; _box_center "SSH / OVPN MANAGEMENT"; _box_mid
        _box_2col "${CYAN}[1]${NC} Create Account"  "${CYAN}[4]${NC} Check Login"   $(( 3+14 )) $(( 3+11 ))
        _box_2col "${CYAN}[2]${NC} Delete Account"  "${CYAN}[5]${NC} Renew Account" $(( 3+14 )) $(( 3+13 ))
        _box_2col "${CYAN}[3]${NC} List Accounts"   "${CYAN}[0]${NC} Back"          $(( 3+13 )) $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-5]: " ch
        case $ch in
            1) create_ssh_account ;;
            2) delete_ssh_account ;;
            3) list_ssh_accounts ;;
            4) check_ssh_login ;;
            5) renew_ssh_account ;;
            0) return ;;
        esac
    done
}

create_ssh_account() {
    clear; _box_top; _box_center "CREATE SSH ACCOUNT"; _box_mid; _box_empty
    _box_row "${WHITE}Domain :${NC} ${CYAN}${DOMAIN}${NC}" $(( 9 + ${#DOMAIN} ))
    _box_empty; _box_bot; echo ""
    read -p " Username : " usr
    [[ -z "$usr" ]] && { echo -e "${RED}Username cannot be empty!${NC}"; sleep 2; return; }
    read -p " Password : " pass
    [[ -z "$pass" ]] && { echo -e "${RED}Password cannot be empty!${NC}"; sleep 2; return; }
    read -p " Duration (days) [default: 30]: " days
    days=${days:-30}
    read -p " Max Login [default: 2]: " maxlogin
    maxlogin=${maxlogin:-2}

    local exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    useradd -M -s /bin/false -e "$exp_date" "$usr" 2>/dev/null
    echo "${usr}:${pass}" | chpasswd 2>/dev/null

    mkdir -p "$AKUN_DIR/ssh"
    cat > "$AKUN_DIR/ssh/${usr}.json" << SSHJSON
{
  "username": "${usr}",
  "password": "${pass}",
  "created": "$(date +%Y-%m-%d)",
  "expired": "${exp_date}",
  "maxlogin": "${maxlogin}",
  "duration": "${days}"
}
SSHJSON

    clear; _box_top; _box_center "ACCOUNT CREATED!" "$GREEN"; _box_mid
    _box_row "${WHITE}Username :${NC} ${usr}" $(( 11 + ${#usr} ))
    _box_row "${WHITE}Password :${NC} ${pass}" $(( 11 + ${#pass} ))
    _box_row "${WHITE}Expired  :${NC} ${exp_date}" $(( 11 + 10 ))
    _box_row "${WHITE}Max Login:${NC} ${maxlogin}" $(( 11 + ${#maxlogin} ))
    _box_mid
    _box_row "${WHITE}Payload  :${NC} GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf][crlf]" 48
    _box_row "${WHITE}SSH      :${NC} ${DOMAIN} Port 22/222" $(( 10 + ${#DOMAIN} + 14 ))
    _box_row "${WHITE}TLS SNI  :${NC} ${DOMAIN} Port 443" $(( 10 + ${#DOMAIN} + 9 ))
    _box_bot; echo ""
    send_telegram_admin "✅ SSH Created: ${usr} | Exp: ${exp_date} | Max: ${maxlogin}"
    read -p " Press any key..."
}

delete_ssh_account() {
    clear; _box_top; _box_center "DELETE SSH ACCOUNT"; _box_bot; echo ""
    read -p " Username to delete: " usr
    [[ -z "$usr" ]] && return
    if id "$usr" &>/dev/null; then
        userdel -f "$usr" 2>/dev/null
        rm -f "$AKUN_DIR/ssh/${usr}.json"
        echo -e "${GREEN}User ${usr} deleted!${NC}"
    else echo -e "${RED}User not found!${NC}"; fi
    sleep 2
}

list_ssh_accounts() {
    clear; _box_top; _box_center "SSH ACCOUNT LIST"; _box_mid
    _box_2col "${CYAN}Username${NC}" "${CYAN}Expired / Status${NC}" 8 16
    _box_thin
    if [[ -d "$AKUN_DIR/ssh" ]] && ls "$AKUN_DIR/ssh/"*.json &>/dev/null; then
        for f in "$AKUN_DIR/ssh/"*.json; do
            local usr=$(jq -r '.username' "$f" 2>/dev/null)
            local exp=$(jq -r '.expired' "$f" 2>/dev/null)
            local today=$(date +%s) exp_ts=$(date -d "$exp" +%s 2>/dev/null || echo 0)
            local stat_col
            [[ "$today" -gt "$exp_ts" ]] && stat_col="${RED}${exp} EXPIRED${NC}" || stat_col="${GREEN}${exp}${NC}"
            _box_2col "${WHITE}${usr}${NC}" "${stat_col}" ${#usr} $(( ${#exp} + 8 ))
        done
    else _box_center "No accounts found" "$YELLOW"; fi
    _box_bot; echo ""
    read -p " Press any key..."
}

check_ssh_login() {
    clear; _box_top; _box_center "ACTIVE SSH LOGINS"; _box_mid
    local logins=$(who | awk '{print $1}' | sort | uniq -c | sort -rn)
    if [[ -n "$logins" ]]; then
        while IFS= read -r line; do
            _box_row "${WHITE}${line}${NC}" ${#line}
        done <<< "$logins"
    else _box_center "No active logins" "$YELLOW"; fi
    _box_bot; echo ""
    read -p " Press any key..."
}

renew_ssh_account() {
    clear; _box_top; _box_center "RENEW SSH ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr
    [[ -z "$usr" ]] && return
    [[ ! -f "$AKUN_DIR/ssh/${usr}.json" ]] && { echo -e "${RED}User not found!${NC}"; sleep 2; return; }
    read -p " Add days [default: 30]: " days; days=${days:-30}
    local cur_exp=$(jq -r '.expired' "$AKUN_DIR/ssh/${usr}.json" 2>/dev/null)
    local cur_ts=$(date -d "$cur_exp" +%s 2>/dev/null || date +%s)
    local now_ts=$(date +%s); [[ "$cur_ts" -lt "$now_ts" ]] && cur_ts=$now_ts
    local new_exp=$(date -d "@$(( cur_ts + days * 86400 ))" +"%Y-%m-%d")
    usermod -e "$new_exp" "$usr" 2>/dev/null
    local tmp=$(mktemp)
    jq --arg exp "$new_exp" '.expired = $exp' "$AKUN_DIR/ssh/${usr}.json" > "$tmp" && mv "$tmp" "$AKUN_DIR/ssh/${usr}.json"
    echo -e "${GREEN}${usr} renewed until ${new_exp}!${NC}"; sleep 2
}

check_expired() {
    clear; _box_top; _box_center "EXPIRED ACCOUNTS"; _box_mid
    local today=$(date +%s) found=0
    for dir in "$AKUN_DIR"/*/; do
        for f in "$dir"*.json; do
            [[ ! -f "$f" ]] && continue
            local usr=$(jq -r '.username' "$f" 2>/dev/null)
            local exp=$(jq -r '.expired' "$f" 2>/dev/null)
            local exp_ts=$(date -d "$exp" +%s 2>/dev/null || echo 0)
            if [[ "$today" -gt "$exp_ts" ]]; then
                _box_row "${RED}${usr}${NC} — Expired: ${exp}" $(( ${#usr} + 14 + ${#exp} ))
                ((found++))
            fi
        done
    done
    [[ "$found" -eq 0 ]] && _box_center "No expired accounts" "$GREEN"
    _box_bot; echo ""; read -p " Press any key..."
}

delete_expired() {
    clear; _box_top; _box_center "DELETE EXPIRED ACCOUNTS"; _box_bot; echo ""
    local today=$(date +%s) count=0
    for dir in "$AKUN_DIR"/*/; do
        for f in "$dir"*.json; do
            [[ ! -f "$f" ]] && continue
            local usr=$(jq -r '.username' "$f" 2>/dev/null)
            local exp=$(jq -r '.expired' "$f" 2>/dev/null)
            local exp_ts=$(date -d "$exp" +%s 2>/dev/null || echo 0)
            if [[ "$today" -gt "$exp_ts" ]]; then
                userdel -f "$usr" 2>/dev/null; rm -f "$f"
                echo -e " ${GREEN}Deleted:${NC} ${usr}"; ((count++))
            fi
        done
    done
    [[ "$count" -eq 0 ]] && echo -e "${YELLOW}No expired accounts found.${NC}" || echo -e "${GREEN}Deleted ${count} expired account(s)!${NC}"
    sleep 3
}

#================================================
# XRAY CONFIG HELPERS
#================================================
_xray_installed() { command -v xray >/dev/null 2>&1 || [[ -f /usr/local/bin/xray ]]; }

_gen_uuid() { cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())"; }

_add_xray_user() {
    local protocol="$1" uuid="$2" usr="$3" flow="${4:-}"
    [[ ! -f "$XRAY_CONFIG" ]] && { echo -e "${RED}xray config not found!${NC}"; return 1; }
    local tag="${protocol}-in"
    local user_obj
    if [[ "$protocol" == "trojan" ]]; then
        user_obj="{\"password\":\"${uuid}\",\"email\":\"${usr}@vpn\"}"
    elif [[ -n "$flow" ]]; then
        user_obj="{\"id\":\"${uuid}\",\"flow\":\"${flow}\",\"email\":\"${usr}@vpn\"}"
    else
        user_obj="{\"id\":\"${uuid}\",\"email\":\"${usr}@vpn\"}"
    fi
    python3 - << PYEOF
import json, sys
try:
    with open('${XRAY_CONFIG}','r') as f: c=json.load(f)
    for inb in c.get('inbounds',[]):
        if inb.get('tag')=='${tag}':
            inb.setdefault('settings',{}).setdefault('clients',[]).append(${user_obj})
    with open('${XRAY_CONFIG}','w') as f: json.dump(c,f,indent=2)
    print('ok')
except Exception as e: print('err:'+str(e),file=sys.stderr)
PYEOF
}

_del_xray_user() {
    local protocol="$1" identifier="$2"
    [[ ! -f "$XRAY_CONFIG" ]] && return 1
    local tag="${protocol}-in" field="id"
    [[ "$protocol" == "trojan" ]] && field="password"
    python3 - << PYEOF
import json
try:
    with open('${XRAY_CONFIG}','r') as f: c=json.load(f)
    for inb in c.get('inbounds',[]):
        if inb.get('tag')=='${tag}':
            clients=inb.get('settings',{}).get('clients',[])
            inb['settings']['clients']=[u for u in clients if u.get('${field}')!='${identifier}' and u.get('email','').split('@')[0]!='${identifier}']
    with open('${XRAY_CONFIG}','w') as f: json.dump(c,f,indent=2)
except: pass
PYEOF
    systemctl restart xray 2>/dev/null
}

#================================================
# VMESS MANAGEMENT
#================================================
menu_vmess() {
    while true; do
        clear; _box_top; _box_center "VMESS MANAGEMENT"; _box_mid
        _box_2col "${CYAN}[1]${NC} Create Account" "${CYAN}[3]${NC} List Accounts" $(( 3+14 )) $(( 3+13 ))
        _box_2col "${CYAN}[2]${NC} Delete Account" "${CYAN}[0]${NC} Back"          $(( 3+14 )) $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-3]: " ch
        case $ch in 1) create_vmess;; 2) delete_vmess;; 3) list_xray_accounts "vmess";; 0) return;; esac
    done
}

create_vmess() {
    clear; _box_top; _box_center "CREATE VMESS ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && { echo -e "${RED}Empty!${NC}"; sleep 2; return; }
    read -p " Duration (days) [30]: " days; days=${days:-30}
    local uuid=$(_gen_uuid) exp=$(date -d "+${days} days" +"%Y-%m-%d")
    _add_xray_user "vmess" "$uuid" "$usr" || return
    systemctl restart xray 2>/dev/null
    mkdir -p "$AKUN_DIR/vmess"
    echo "{\"username\":\"${usr}\",\"uuid\":\"${uuid}\",\"created\":\"$(date +%Y-%m-%d)\",\"expired\":\"${exp}\",\"duration\":\"${days}\"}" > "$AKUN_DIR/vmess/${usr}.json"
    local host="${DOMAIN}" port="${HAPROXY_PORT}"
    local vmess_obj="{\"v\":\"2\",\"ps\":\"${usr}\",\"add\":\"${host}\",\"port\":\"${port}\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${host}\",\"path\":\"/vmess\",\"tls\":\"tls\",\"sni\":\"${host}\"}"
    local vmess_link="vmess://$(echo -n "$vmess_obj" | base64 -w0)"
    clear; _box_top; _box_center "VMESS CREATED!" "$GREEN"; _box_mid
    _box_row "${WHITE}User   :${NC} ${usr}" $(( 9 + ${#usr} ))
    _box_row "${WHITE}UUID   :${NC} ${uuid}" $(( 9 + 36 ))
    _box_row "${WHITE}Expired:${NC} ${exp}" $(( 9 + 10 ))
    _box_row "${WHITE}Host   :${NC} ${host}" $(( 9 + ${#host} ))
    _box_row "${WHITE}Port   :${NC} ${port}" $(( 9 + ${#port} ))
    _box_row "${WHITE}Path   :${NC} /vmess" 15
    _box_row "${WHITE}TLS    :${NC} yes / WSS" 17
    _box_mid; _box_center "Import Link" "$YELLOW"
    echo -e "  ${CYAN}${vmess_link}${NC}"
    _box_bot; echo ""
    send_telegram_admin "✅ VMess Created: ${usr} | UUID: ${uuid} | Exp: ${exp}"
    read -p " Press any key..."
}

delete_vmess() {
    clear; _box_top; _box_center "DELETE VMESS ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && return
    _del_xray_user "vmess" "$usr"
    rm -f "$AKUN_DIR/vmess/${usr}.json"
    echo -e "${GREEN}${usr} deleted!${NC}"; sleep 2
}

#================================================
# VLESS MANAGEMENT
#================================================
menu_vless() {
    while true; do
        clear; _box_top; _box_center "VLESS MANAGEMENT"; _box_mid
        _box_2col "${CYAN}[1]${NC} Create Account" "${CYAN}[3]${NC} List Accounts" $(( 3+14 )) $(( 3+13 ))
        _box_2col "${CYAN}[2]${NC} Delete Account" "${CYAN}[0]${NC} Back"          $(( 3+14 )) $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-3]: " ch
        case $ch in 1) create_vless;; 2) delete_vless;; 3) list_xray_accounts "vless";; 0) return;; esac
    done
}

create_vless() {
    clear; _box_top; _box_center "CREATE VLESS ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && { echo -e "${RED}Empty!${NC}"; sleep 2; return; }
    read -p " Duration (days) [30]: " days; days=${days:-30}
    local uuid=$(_gen_uuid) exp=$(date -d "+${days} days" +"%Y-%m-%d")
    _add_xray_user "vless" "$uuid" "$usr" "xtls-rprx-vision" || return
    systemctl restart xray 2>/dev/null
    mkdir -p "$AKUN_DIR/vless"
    echo "{\"username\":\"${usr}\",\"uuid\":\"${uuid}\",\"created\":\"$(date +%Y-%m-%d)\",\"expired\":\"${exp}\",\"duration\":\"${days}\"}" > "$AKUN_DIR/vless/${usr}.json"
    local vless_link="vless://${uuid}@${DOMAIN}:${HAPROXY_PORT}?security=tls&sni=${DOMAIN}&flow=xtls-rprx-vision&type=tcp#${usr}"
    clear; _box_top; _box_center "VLESS CREATED!" "$GREEN"; _box_mid
    _box_row "${WHITE}User   :${NC} ${usr}" $(( 9 + ${#usr} ))
    _box_row "${WHITE}UUID   :${NC} ${uuid}" $(( 9 + 36 ))
    _box_row "${WHITE}Expired:${NC} ${exp}" $(( 9 + 10 ))
    _box_row "${WHITE}Host   :${NC} ${DOMAIN}" $(( 9 + ${#DOMAIN} ))
    _box_row "${WHITE}Port   :${NC} ${HAPROXY_PORT} (TLS)" $(( 9 + ${#HAPROXY_PORT} + 6 ))
    _box_row "${WHITE}Flow   :${NC} xtls-rprx-vision" 23
    _box_mid; _box_center "Import Link" "$YELLOW"
    echo -e "  ${CYAN}${vless_link}${NC}"
    _box_bot; echo ""
    send_telegram_admin "✅ VLess Created: ${usr} | UUID: ${uuid} | Exp: ${exp}"
    read -p " Press any key..."
}

delete_vless() {
    clear; _box_top; _box_center "DELETE VLESS ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && return
    _del_xray_user "vless" "$usr"
    rm -f "$AKUN_DIR/vless/${usr}.json"
    echo -e "${GREEN}${usr} deleted!${NC}"; sleep 2
}

#================================================
# TROJAN MANAGEMENT
#================================================
menu_trojan() {
    while true; do
        clear; _box_top; _box_center "TROJAN MANAGEMENT"; _box_mid
        _box_2col "${CYAN}[1]${NC} Create Account" "${CYAN}[3]${NC} List Accounts" $(( 3+14 )) $(( 3+13 ))
        _box_2col "${CYAN}[2]${NC} Delete Account" "${CYAN}[0]${NC} Back"          $(( 3+14 )) $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-3]: " ch
        case $ch in 1) create_trojan;; 2) delete_trojan;; 3) list_xray_accounts "trojan";; 0) return;; esac
    done
}

create_trojan() {
    clear; _box_top; _box_center "CREATE TROJAN ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && { echo -e "${RED}Empty!${NC}"; sleep 2; return; }
    read -p " Password [auto]: " pass; [[ -z "$pass" ]] && pass=$(tr -dc 'a-z0-9' < /dev/urandom | head -c12)
    read -p " Duration (days) [30]: " days; days=${days:-30}
    local exp=$(date -d "+${days} days" +"%Y-%m-%d")
    _add_xray_user "trojan" "$pass" "$usr" || return
    systemctl restart xray 2>/dev/null
    mkdir -p "$AKUN_DIR/trojan"
    echo "{\"username\":\"${usr}\",\"password\":\"${pass}\",\"created\":\"$(date +%Y-%m-%d)\",\"expired\":\"${exp}\",\"duration\":\"${days}\"}" > "$AKUN_DIR/trojan/${usr}.json"
    local trojan_link="trojan://${pass}@${DOMAIN}:${HAPROXY_PORT}?security=tls&sni=${DOMAIN}&type=tcp#${usr}"
    clear; _box_top; _box_center "TROJAN CREATED!" "$GREEN"; _box_mid
    _box_row "${WHITE}User    :${NC} ${usr}" $(( 10 + ${#usr} ))
    _box_row "${WHITE}Password:${NC} ${pass}" $(( 10 + ${#pass} ))
    _box_row "${WHITE}Expired :${NC} ${exp}" $(( 10 + 10 ))
    _box_row "${WHITE}Host    :${NC} ${DOMAIN}" $(( 10 + ${#DOMAIN} ))
    _box_row "${WHITE}Port    :${NC} ${HAPROXY_PORT} (TLS)" $(( 10 + ${#HAPROXY_PORT} + 6 ))
    _box_mid; _box_center "Import Link" "$YELLOW"
    echo -e "  ${CYAN}${trojan_link}${NC}"
    _box_bot; echo ""
    send_telegram_admin "✅ Trojan Created: ${usr} | Pass: ${pass} | Exp: ${exp}"
    read -p " Press any key..."
}

delete_trojan() {
    clear; _box_top; _box_center "DELETE TROJAN ACCOUNT"; _box_bot; echo ""
    read -p " Username: " usr; [[ -z "$usr" ]] && return
    _del_xray_user "trojan" "$usr"
    rm -f "$AKUN_DIR/trojan/${usr}.json"
    echo -e "${GREEN}${usr} deleted!${NC}"; sleep 2
}

list_xray_accounts() {
    local proto="$1"
    clear; _box_top; _box_center "${proto^^} ACCOUNT LIST"; _box_mid
    _box_2col "${CYAN}Username${NC}" "${CYAN}Expired${NC}" 8 7
    _box_thin
    if [[ -d "$AKUN_DIR/$proto" ]] && ls "$AKUN_DIR/$proto/"*.json &>/dev/null 2>&1; then
        for f in "$AKUN_DIR/$proto/"*.json; do
            local usr=$(jq -r '.username' "$f" 2>/dev/null)
            local exp=$(jq -r '.expired' "$f" 2>/dev/null)
            local today=$(date +%s) exp_ts=$(date -d "$exp" +%s 2>/dev/null || echo 0)
            if [[ "$today" -gt "$exp_ts" ]]; then
                _box_2col "${RED}${usr}${NC}" "${RED}${exp}${NC}" ${#usr} ${#exp}
            else
                _box_2col "${WHITE}${usr}${NC}" "${GREEN}${exp}${NC}" ${#usr} ${#exp}
            fi
        done
    else _box_center "No accounts found" "$YELLOW"; fi
    _box_bot; echo ""; read -p " Press any key..."
}

#================================================
# TRIAL XRAY
#================================================
menu_trial_xray() {
    clear; _box_top; _box_center "TRIAL XRAY ACCOUNT"; _box_mid
    _box_2col "${CYAN}[1]${NC} Trial VMess" "${CYAN}[3]${NC} Trial Trojan" $(( 3+11 )) $(( 3+12 ))
    _box_2col "${CYAN}[2]${NC} Trial VLess" "${CYAN}[0]${NC} Back"         $(( 3+11 )) $(( 3+4 ))
    _box_bot; echo ""
    read -p " Select [0-3]: " ch
    case $ch in
        1) local usr="trial_vmess_$(date +%H%M%S)" uuid=$(_gen_uuid)
           _add_xray_user "vmess" "$uuid" "$usr" >/dev/null 2>&1; systemctl restart xray 2>/dev/null
           echo -e "${GREEN}Trial VMess: ${usr}${NC}"; echo -e "${CYAN}UUID: ${uuid}${NC}"; read -p "Press any key..." ;;
        2) local usr="trial_vless_$(date +%H%M%S)" uuid=$(_gen_uuid)
           _add_xray_user "vless" "$uuid" "$usr" "xtls-rprx-vision" >/dev/null 2>&1; systemctl restart xray 2>/dev/null
           echo -e "${GREEN}Trial VLess: ${usr}${NC}"; echo -e "${CYAN}UUID: ${uuid}${NC}"; read -p "Press any key..." ;;
        3) local usr="trial_trojan_$(date +%H%M%S)" pass=$(tr -dc 'a-z0-9' < /dev/urandom | head -c12)
           _add_xray_user "trojan" "$pass" "$usr" >/dev/null 2>&1; systemctl restart xray 2>/dev/null
           echo -e "${GREEN}Trial Trojan: ${usr}${NC}"; echo -e "${CYAN}Pass: ${pass}${NC}"; read -p "Press any key..." ;;
        0) return ;;
    esac
}

#================================================
# TELEGRAM BOT
#================================================
menu_telegram_bot() {
    while true; do
        clear; _box_top; _box_center "TELEGRAM BOT"; _box_mid
        local bot_st=$(check_status "vpn-bot")
        _box_row "${WHITE}Status :${NC} $( [[ "$bot_st" == "ON" ]] && echo "${GREEN}● ONLINE${NC}" || echo "${RED}○ OFFLINE${NC}" )" 16
        [[ -f "$BOT_TOKEN_FILE" ]] && _box_row "${WHITE}Token  :${NC} $(cut -c1-15 "$BOT_TOKEN_FILE")..." 32
        _box_mid
        _box_2col "${CYAN}[1]${NC} Setup Bot Token" "${CYAN}[3]${NC} Start Bot" $(( 3+15 )) $(( 3+9 ))
        _box_2col "${CYAN}[2]${NC} Setup Chat ID"   "${CYAN}[4]${NC} Stop Bot"  $(( 3+13 )) $(( 3+8 ))
        _box_2col "                 " "${CYAN}[0]${NC} Back" 0 $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-4]: " ch
        case $ch in
            1) read -p " Bot Token: " tok; [[ -n "$tok" ]] && { echo "$tok" > "$BOT_TOKEN_FILE"; chmod 600 "$BOT_TOKEN_FILE"; echo -e "${GREEN}Token saved!${NC}"; sleep 2; } ;;
            2) read -p " Chat ID: " cid; [[ -n "$cid" ]] && { echo "$cid" > "$CHAT_ID_FILE"; chmod 600 "$CHAT_ID_FILE"; echo -e "${GREEN}Chat ID saved!${NC}"; sleep 2; } ;;
            3) install_telegram_bot; systemctl restart vpn-bot 2>/dev/null; echo -e "${GREEN}Bot started!${NC}"; sleep 2 ;;
            4) systemctl stop vpn-bot 2>/dev/null; echo -e "${YELLOW}Bot stopped!${NC}"; sleep 2 ;;
            0) return ;;
        esac
    done
}

install_telegram_bot() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    local token=$(cat "$BOT_TOKEN_FILE")
    cat > /usr/local/bin/vpn-bot.py << BOTEOF
#!/usr/bin/env python3
import requests, subprocess, time, json

BOT_TOKEN = open('${BOT_TOKEN_FILE}').read().strip()
CHAT_ID_FILE = '${CHAT_ID_FILE}'
API = f'https://api.telegram.org/bot{BOT_TOKEN}'

def send(chat_id, text):
    try:
        requests.post(f'{API}/sendMessage', json={'chat_id': chat_id, 'text': text, 'parse_mode': 'HTML'}, timeout=10)
    except: pass

def get_updates(offset=0):
    try:
        r = requests.get(f'{API}/getUpdates', params={'offset': offset, 'timeout': 30}, timeout=35)
        return r.json().get('result', [])
    except: return []

def handle(msg):
    cid = msg['message']['chat']['id']
    txt = msg['message'].get('text', '').strip()
    try:
        admin_id = int(open(CHAT_ID_FILE).read().strip()) if open.__module__ == 'builtins' else 0
    except: admin_id = 0
    if cid != admin_id and admin_id != 0:
        send(cid, '❌ Unauthorized'); return
    if txt == '/status':
        result = subprocess.getoutput("systemctl is-active xray nginx haproxy dropbear 2>/dev/null")
        send(cid, f'<b>Service Status:</b>\n<code>{result}</code>')
    elif txt.startswith('/adduser '):
        parts = txt.split()
        if len(parts) >= 3:
            usr, days = parts[1], parts[2]
            subprocess.run(['bash', '/root/tunnel.sh', 'add-user', usr, days])
            send(cid, f'✅ User {usr} added for {days} days!')
        else: send(cid, 'Usage: /adduser username days')
    elif txt == '/info':
        ip = subprocess.getoutput("curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo N/A")
        up = subprocess.getoutput("uptime -p")
        send(cid, f'<b>Server Info</b>\n🌐 IP: <code>{ip}</code>\n⏱ Uptime: {up}')
    elif txt == '/start':
        send(cid, '👋 Welcome to VPN Bot!\n\nCommands:\n/status - Service status\n/info - Server info\n/adduser user days')
    else:
        send(cid, '❓ Unknown command. Use /start for help.')

offset = 0
while True:
    updates = get_updates(offset)
    for u in updates:
        offset = u['update_id'] + 1
        if 'message' in u:
            try: handle(u)
            except Exception as e: print(f'Error: {e}')
    time.sleep(1)
BOTEOF
    chmod +x /usr/local/bin/vpn-bot.py
    cat > /etc/systemd/system/vpn-bot.service << 'BSVC'
[Unit]
Description=VPN Telegram Bot
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/vpn-bot.py
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
BSVC
    systemctl daemon-reload
    systemctl enable vpn-bot 2>/dev/null
    pip3 install requests --quiet 2>/dev/null
}

#================================================
# OPTIMIZE VPS MENU
#================================================
menu_optimize() {
    clear; _box_top; _box_center "OPTIMIZE VPS"; _box_bot; echo ""
    echo -e " ${CYAN}Applying network optimizations...${NC}"; echo ""
    optimize_vpn; done_msg "TCP BBR enabled"
    setup_swap; done_msg "Swap configured"
    setup_keepalive; done_msg "Keepalive configured"
    echo ""; echo -e " ${GREEN}Optimization complete!${NC}"; sleep 3
}

#================================================
# RESTART SERVICES
#================================================
menu_restart() {
    clear; _box_top; _box_center "RESTART SERVICES"; _box_bot; echo ""
    for svc in xray nginx haproxy dropbear sshd udp-custom vpn-keepalive vpn-bot; do
        if systemctl list-units --type=service | grep -q "${svc}"; then
            systemctl restart "$svc" 2>/dev/null && \
                printf " ${GREEN}✓${NC} %-20s ${GREEN}Restarted${NC}\n" "$svc" || \
                printf " ${RED}✗${NC} %-20s ${RED}Failed${NC}\n" "$svc"
        fi
    done
    echo ""; sleep 3
}

#================================================
# UPDATE PANEL
#================================================
update_menu() {
    clear; _box_top; _box_center "UPDATE PANEL"; _box_bot; echo ""
    echo -e " ${CYAN}Checking for updates from GitHub...${NC}"; echo ""
    local tmp=$(mktemp)
    if curl -s --max-time 15 "$SCRIPT_URL" -o "$tmp" && [[ -s "$tmp" ]]; then
        local new_ver=$(grep "^SCRIPT_VERSION=" "$tmp" | cut -d'"' -f2)
        if [[ "$new_ver" != "$SCRIPT_VERSION" ]]; then
            echo -e " ${GREEN}New version found: ${new_ver}${NC}"; echo ""
            cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null
            cp "$tmp" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"
            echo -e " ${GREEN}Updated! Restarting...${NC}"; sleep 2
            exec bash "$SCRIPT_PATH"
        else echo -e " ${YELLOW}Already up to date: v${SCRIPT_VERSION}${NC}"; fi
    else echo -e " ${RED}Update failed! Check connection.${NC}"; fi
    rm -f "$tmp"; sleep 3
}

#================================================
# BACKUP / RESTORE
#================================================
_menu_backup() {
    clear; _box_top; _box_center "BACKUP CONFIG"; _box_bot; echo ""
    local ts=$(date +%Y%m%d_%H%M%S) bdir="/root/backups/${ts}"
    mkdir -p "$bdir"
    local files=("$DOMAIN_FILE" "$DOMAIN_TYPE_FILE" "$BOT_TOKEN_FILE" "$CHAT_ID_FILE"
                 "$EXPIRY_FILE" "$XRAY_CONFIG" "/etc/haproxy/haproxy.cfg" "/etc/nginx/nginx.conf")
    for f in "${files[@]}"; do
        [[ -f "$f" ]] && { cp "$f" "$bdir/"; done_msg "Backed up: $(basename "$f")"; }
    done
    [[ -d "$AKUN_DIR" ]] && { cp -r "$AKUN_DIR" "$bdir/"; done_msg "Backed up: accounts/"; }
    local archive="/root/backup_${ts}.tar.gz"
    tar -czf "$archive" -C "/root/backups" "$ts" 2>/dev/null
    echo ""; echo -e " ${GREEN}Backup: ${archive}${NC}"; sleep 3
}

_menu_restore() {
    clear; _box_top; _box_center "RESTORE CONFIG"; _box_bot; echo ""
    local backups=($(ls -t /root/backup_*.tar.gz 2>/dev/null))
    [[ "${#backups[@]}" -eq 0 ]] && { echo -e " ${RED}No backups found!${NC}"; sleep 3; return; }
    echo -e " ${CYAN}Available backups:${NC}"; echo ""
    local i=1; for b in "${backups[@]}"; do echo " [${i}] $(basename "$b")"; ((i++)); done
    echo ""; read -p " Select: " sel; [[ -z "$sel" || "$sel" -gt "${#backups[@]}" ]] && return
    local chosen="${backups[$((sel-1))]}" tmpd=$(mktemp -d)
    tar -xzf "$chosen" -C "$tmpd" 2>/dev/null
    local bd=$(ls "$tmpd" 2>/dev/null | head -1)
    [[ -z "$bd" ]] && { rm -rf "$tmpd"; return; }
    cp "$tmpd/$bd/"*.json "$AKUN_DIR/" 2>/dev/null
    [[ -f "$tmpd/$bd/domain" ]] && cp "$tmpd/$bd/domain" "$DOMAIN_FILE"
    [[ -f "$tmpd/$bd/config.json" ]] && cp "$tmpd/$bd/config.json" "$XRAY_CONFIG"
    systemctl restart xray 2>/dev/null
    echo -e " ${GREEN}Restored from: $(basename "$chosen")${NC}"; rm -rf "$tmpd"; sleep 3
}

#================================================
# UNINSTALL
#================================================
menu_uninstall() {
    clear; _box_top; _box_center "UNINSTALL PANEL" "$RED"; _box_mid
    _box_center "This will remove ALL data!" "$RED"
    _box_center "Accounts, configs, scripts." "$YELLOW"
    _box_bot; echo ""
    read -p " Type YES to confirm: " confirm
    [[ "$confirm" != "YES" ]] && { echo -e "${YELLOW}Cancelled.${NC}"; sleep 2; return; }
    echo -e "${RED}Uninstalling...${NC}"
    systemctl stop xray nginx haproxy dropbear vpn-bot vpn-keepalive udp-custom 2>/dev/null
    systemctl disable xray nginx haproxy dropbear vpn-bot vpn-keepalive udp-custom 2>/dev/null
    apt-get remove -y haproxy nginx 2>/dev/null
    rm -rf /usr/local/etc/xray /usr/local/bin/xray "$AKUN_DIR"
    rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$EXPIRY_FILE" "$DOMAIN_FILE" "$DOMAIN_TYPE_FILE"
    rm -f /usr/local/bin/menu /usr/local/bin/vpn-bot.py /usr/local/bin/vpn-keepalive.sh
    rm -f /etc/systemd/system/vpn-bot.service /etc/systemd/system/vpn-keepalive.service
    sed -i '/tunnel.sh/d' /root/.bashrc 2>/dev/null
    systemctl daemon-reload 2>/dev/null
    echo -e "${GREEN}Uninstall complete!${NC}"; sleep 2; exit 0
}

#================================================
# ADVANCED MENU
#================================================
menu_advanced() {
    while true; do
        clear; _box_top; _box_center "ADVANCED MODE"; _box_mid
        _box_2col "${CYAN}[1]${NC} Nginx Config"   "${CYAN}[4]${NC} Edit Xray Config" $(( 3+12 )) $(( 3+16 ))
        _box_2col "${CYAN}[2]${NC} HAProxy Config" "${CYAN}[5]${NC} View Logs"        $(( 3+14 )) $(( 3+9 ))
        _box_2col "${CYAN}[3]${NC} VPS Expiry Set" "${CYAN}[0]${NC} Back"             $(( 3+14 )) $(( 3+4 ))
        _box_bot; echo ""
        read -p " Select [0-5]: " ch
        case $ch in
            1) nano /etc/nginx/nginx.conf 2>/dev/null; systemctl restart nginx 2>/dev/null ;;
            2) nano /etc/haproxy/haproxy.cfg 2>/dev/null; systemctl restart haproxy 2>/dev/null ;;
            3) read -p " VPS Expiry Date (YYYY-MM-DD): " d
               [[ -n "$d" ]] && { echo "$d" > /root/.vps_expiry; echo -e "${GREEN}Set!${NC}"; sleep 2; } ;;
            4) nano "$XRAY_CONFIG" 2>/dev/null; systemctl restart xray 2>/dev/null ;;
            5) journalctl -u xray -n 50 --no-pager | tail -30; read -p " Press any key..." ;;
            0) return ;;
        esac
    done
}

#================================================
# XRAY INBOUND CONFIG GENERATOR
#================================================
generate_xray_config() {
    mkdir -p /usr/local/etc/xray
    cat > "$XRAY_CONFIG" << XRAYCFG
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "tag": "vmess-in",
      "port": ${XRAY_WS_NONTLS_PORT},
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess", "headers": {"Host": "${DOMAIN}"}}
      }
    },
    {
      "tag": "vmess-tls-in",
      "port": 8081,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess", "headers": {"Host": "${DOMAIN}"}},
        "tlsSettings": {"certificates": [{"certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key"}]},
        "security": "tls"
      }
    },
    {
      "tag": "vless-in",
      "port": ${XRAY_INTERNAL_TLS},
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "tcpSettings": {},
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key"}]
        },
        "security": "tls"
      }
    },
    {
      "tag": "trojan-in",
      "port": 8445,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {"clients": []},
      "streamSettings": {
        "network": "tcp",
        "tlsSettings": {
          "certificates": [{"certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key"}]
        },
        "security": "tls"
      }
    },
    {
      "tag": "vless-grpc-in",
      "port": ${XRAY_GRPC_PORT},
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {"clients": [], "decryption": "none"},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "grpc"}}
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "blocked"}
  ],
  "routing": {
    "rules": [
      {"type": "field", "ip": ["geoip:private"], "outboundTag": "blocked"}
    ]
  }
}
XRAYCFG
}

configure_nginx() {
    mkdir -p "$PUBLIC_HTML"
    cat > /etc/nginx/nginx.conf << 'NGINXCFG'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
events { worker_connections 65535; use epoll; multi_accept on; }
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    server {
        listen 80 default_server;
        root /var/www/html;
        index index.html index.htm;
        server_name _;
        location /vmess { proxy_pass http://127.0.0.1:8080; proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";
            proxy_set_header Host $host; }
        location /grpc { grpc_pass grpc://127.0.0.1:8444; }
        location ~ /\.ht { deny all; }
    }
}
NGINXCFG
}

setup_udp_custom() {
    cat > /etc/systemd/system/udp-custom.service << 'UDPSVC'
[Unit]
Description=UDP Custom VPN
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
UDPSVC
    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom 2>/dev/null
}

setup_dropbear() {
    sed -i 's/^DROPBEAR_PORT=.*/DROPBEAR_PORT=222/' /etc/default/dropbear 2>/dev/null
    cat >> /etc/default/dropbear << 'DCONF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-w -s -g"
DCONF
    systemctl enable dropbear 2>/dev/null
    systemctl restart dropbear 2>/dev/null
}

install_badvpn() {
    if ! command -v badvpn-udpgw >/dev/null 2>&1; then
        local arch="x86_64"
        [[ "$(uname -m)" == "aarch64" ]] && arch="aarch64"
        curl -sL "https://github.com/ambrop72/badvpn/releases/latest/download/badvpn-${arch}-linux" \
            -o /usr/sbin/badvpn-udpgw 2>/dev/null && chmod +x /usr/sbin/badvpn-udpgw || true
    fi
}

install_xray() {
    local v="1.8.4" arch="64"
    [[ "$(uname -m)" == "aarch64" ]] && arch="arm64-v8a"
    local url="https://github.com/XTLS/Xray-core/releases/download/v${v}/Xray-linux-${arch}.zip"
    local tmp="/tmp/xray.zip"
    curl -sL "$url" -o "$tmp" 2>/dev/null
    [[ -f "$tmp" && -s "$tmp" ]] || { echo -e "${RED}Xray download failed!${NC}"; return 1; }
    mkdir -p /usr/local/bin /usr/local/etc/xray /usr/local/share/xray
    unzip -o "$tmp" -d /tmp/xray_ext >/dev/null 2>&1
    [[ -f "/tmp/xray_ext/xray" ]] && { cp /tmp/xray_ext/xray /usr/local/bin/; chmod +x /usr/local/bin/xray; }
    [[ -f "/tmp/xray_ext/geoip.dat" ]] && cp /tmp/xray_ext/geoip.dat /usr/local/share/xray/
    [[ -f "/tmp/xray_ext/geosite.dat" ]] && cp /tmp/xray_ext/geosite.dat /usr/local/share/xray/
    rm -rf "$tmp" /tmp/xray_ext
    cat > /etc/systemd/system/xray.service << 'XSVC'
[Unit]
Description=Xray Core
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardError=journal
[Install]
WantedBy=multi-user.target
XSVC
    systemctl daemon-reload
    systemctl enable xray 2>/dev/null
}

#================================================
# AUTO INSTALL
#================================================
auto_install() {
    clear; show_install_banner
    _box_top; _box_center "AUTO INSTALLATION"; _box_mid
    _box_center "VPN Server v${SCRIPT_VERSION}" "$CYAN"
    _box_bot; echo ""
    
    read -p " Install VPN Server now? [Y/n]: " yn
    [[ "$yn" =~ ^[Nn]$ ]] && exit 0

    setup_domain
    [[ -z "$DOMAIN" ]] && { echo -e "${RED}Domain required!${NC}"; exit 1; }

    echo ""; echo -e "${CYAN}Starting installation...${NC}"; echo ""

    # Update & install packages
    info_msg "Updating packages..."
    apt-get update -qq 2>/dev/null
    done_msg "Packages updated"

    local packages=(curl wget unzip jq python3 python3-pip certbot nginx haproxy dropbear openssl net-tools)
    for p in "${packages[@]}"; do
        apt-get install -y "$p" -qq 2>/dev/null && done_msg "Installed: $p" || fail_msg "Failed: $p"
    done

    info_msg "Installing Xray..."; install_xray && done_msg "Xray installed" || fail_msg "Xray install failed"
    info_msg "Installing BadVPN..."; install_badvpn && done_msg "BadVPN installed" || true

    info_msg "Generating Xray config..."
    generate_xray_config
    done_msg "Xray config generated"

    info_msg "Getting SSL certificate..."
    get_ssl_cert; done_msg "SSL configured"

    info_msg "Configuring Nginx..."; configure_nginx; systemctl enable nginx 2>/dev/null; systemctl restart nginx 2>/dev/null; done_msg "Nginx configured"
    info_msg "Configuring HAProxy..."; configure_haproxy; systemctl enable haproxy 2>/dev/null; systemctl restart haproxy 2>/dev/null; done_msg "HAProxy configured"
    info_msg "Configuring Dropbear..."; setup_dropbear; done_msg "Dropbear configured"
    info_msg "Setting up UDP Custom..."; setup_udp_custom; done_msg "UDP configured"
    info_msg "Optimizing system..."; optimize_vpn; setup_swap; setup_keepalive; done_msg "System optimized"
    info_msg "Setting up expiry..."; setup_expiry 30; done_msg "Expiry set (30 days)"
    info_msg "Starting Xray..."; systemctl restart xray 2>/dev/null && done_msg "Xray started" || fail_msg "Xray failed"

    mkdir -p "$AKUN_DIR/ssh" "$AKUN_DIR/vmess" "$AKUN_DIR/vless" "$AKUN_DIR/trojan"
    
    setup_menu_command

    echo ""; _box_top; _box_center "INSTALLATION COMPLETE!" "$GREEN"; _box_mid
    _box_row "${WHITE}Domain :${NC} ${CYAN}${DOMAIN}${NC}" $(( 9 + ${#DOMAIN} ))
    _box_row "${WHITE}SSH    :${NC} Port 22 / 222" 20
    _box_row "${WHITE}TLS    :${NC} Port 443 (HAProxy)" 25
    _box_row "${WHITE}Xray   :${NC} Port 8443 (TLS), 8080 (WS)" 34
    _box_bot; echo ""
    echo -e " Type ${CYAN}menu${NC} to open panel"; echo ""
    read -p " Press any key to open menu..."
}

#================================================
# MAIN LOOP
#================================================
main_menu() {
    while true; do
        clear
        show_system_info
        echo ""
        show_menu
        echo ""
        read -p " Select [0-20, 99]: " choice
        case $choice in
            1)  menu_ssh ;;
            2)  menu_vmess ;;
            3)  menu_vless ;;
            4)  menu_trojan ;;
            5)  menu_trial_xray ;;
            6)  list_xray_accounts "vmess"; list_xray_accounts "vless"; list_xray_accounts "trojan" ;;
            7)  check_expired ;;
            8)  delete_expired ;;
            9)  menu_telegram_bot ;;
            10) change_domain ;;
            11) fix_certificate ;;
            12) menu_optimize ;;
            13) menu_restart ;;
            14) show_info_port ;;
            15) run_speedtest ;;
            16) update_menu ;;
            17) _menu_backup ;;
            18) _menu_restore ;;
            19) menu_uninstall ;;
            20) menu_expiry ;;
            99) menu_advanced ;;
            0|00|exit|quit) clear; echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
            help|HELP) _show_help ;;
            *) ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

[[ $EUID -ne 0 ]] && { echo -e "${RED}Must be run as root!${NC}"; echo " sudo bash $0"; exit 1; }

# Load domain
[[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

# Run auto install if domain not set
if [[ ! -f "$DOMAIN_FILE" ]] || [[ -z "$DOMAIN" ]]; then
    auto_install
fi

setup_menu_command
check_expiry
main_menu
