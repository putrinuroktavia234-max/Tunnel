#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#   SAKTI TUNNELING v5.0
#   Enhanced Edition - Fixed TLS/NonTLS, Expiry Display, 3 Themes
# ═══════════════════════════════════════════════════════════════

# ── Colors ─────────────────────────────────────────────────────
R='\e[0;31m'  G='\e[0;32m'  Y='\e[1;33m'  B='\e[0;34m'
C='\e[0;36m'  M='\e[0;35m'  W='\e[1;37m'  D='\e[2m'
BG='\e[1m'    NC='\e[0m'
RB='\e[1;31m' GB='\e[1;32m' YB='\e[1;33m' CB='\e[1;36m' MB='\e[1;35m'

# ── Variables ───────────────────────────────────────────────────
DOMAIN=""
DOMAIN_FILE="/root/domain"
AKUN_DIR="/root/akun"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
VER="5.0.0"
GITHUB_USER="putrinuroktavia234-max"
GITHUB_REPO="Tunnel"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/tunnel.sh"
VERSION_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/version"
SCRIPT_PATH="/root/tunnel.sh"
INSTALL_DATE_FILE="/root/.install_date"
SCRIPT_EXP_FILE="/root/.script_exp"
PUBLIC_HTML="/var/www/html"
BOT_TOKEN_FILE="/root/.bot_token"
CHAT_ID_FILE="/root/.chat_id"
PAYMENT_FILE="/root/.payment_info"
DOMAIN_TYPE_FILE="/root/.domain_type"
THEME_FILE="/root/.menu_theme"
BANNER_FILE="/root/.banner_name"

# ═══════════════════════════════════════════════════════════════
#  CORE UTILS
# ═══════════════════════════════════════════════════════════════

die(){ echo -e "${R}✗ $*${NC}"; exit 1; }
ok(){ echo -e "${G}✓ $*${NC}"; }
warn(){ echo -e "${Y}⚠ $*${NC}"; }
info(){ echo -e "${C}→ $*${NC}"; }

check_root(){ [[ $EUID -ne 0 ]] && die "Script harus dijalankan sebagai root!"; }

get_ip(){
    local ip
    for u in "https://ifconfig.me" "https://ipinfo.io/ip" "https://api.ipify.org"; do
        ip=$(curl -s --max-time 3 "$u" 2>/dev/null)
        [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "$ip" && return
    done
    echo "$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7;exit}')"
}

get_isp(){ curl -s --max-time 5 "https://ipinfo.io/org" 2>/dev/null | cut -d' ' -f2- | head -c 30; }
get_city(){ curl -s --max-time 5 "https://ipinfo.io/city" 2>/dev/null; }
get_os(){ [[ -f /etc/os-release ]] && { source /etc/os-release; echo "$PRETTY_NAME"; } || echo "Linux"; }

chk(){ systemctl is-active --quiet "$1" 2>/dev/null && echo "ON" || echo "OFF"; }

load_domain(){
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r ' < "$DOMAIN_FILE")
}

tg(){
    [[ -f "$BOT_TOKEN_FILE" && -f "$CHAT_ID_FILE" ]] || return
    curl -s -X POST "https://api.telegram.org/bot$(cat $BOT_TOKEN_FILE)/sendMessage" \
        -d chat_id="$(cat $CHAT_ID_FILE)" -d text="$1" -d parse_mode="HTML" \
        --max-time 8 >/dev/null 2>&1
}

rand_str(){ tr -dc 'a-z' </dev/urandom | head -c 6; }
gen_random_domain(){ local ip=$(get_ip); echo "$(rand_str).${ip}.nip.io"; }

# Script expiry (87 days from install)
init_expiry(){
    if [[ ! -f "$INSTALL_DATE_FILE" ]]; then
        date +"%Y-%m-%d" > "$INSTALL_DATE_FILE"
        date -d "+87 days" +"%Y-%m-%d" > "$SCRIPT_EXP_FILE"
    fi
}

get_script_exp(){
    [[ -f "$SCRIPT_EXP_FILE" ]] && cat "$SCRIPT_EXP_FILE" || echo "N/A"
}

get_exp_days(){
    [[ -f "$SCRIPT_EXP_FILE" ]] || echo "N/A" && return
    local exp=$(cat "$SCRIPT_EXP_FILE")
    local et=$(date -d "$exp" +%s 2>/dev/null)
    local now=$(date +%s)
    echo $(( (et - now) / 86400 ))
}

get_ram(){
    local used=$(free -m | awk 'NR==2{print $3}')
    local total=$(free -m | awk 'NR==2{print $2}')
    echo "${used} / ${total} MB"
}

get_theme(){ [[ -f "$THEME_FILE" ]] && cat "$THEME_FILE" || echo "classic"; }
get_banner_name(){ [[ -f "$BANNER_FILE" ]] && cat "$BANNER_FILE" || echo "SAKTI TUNNELING"; }

# ═══════════════════════════════════════════════════════════════
#  3 TEMA MENU - LIKE SCREENSHOT
# ═══════════════════════════════════════════════════════════════

# ─── TEMA 1: CLASSIC (Green/Yellow - like screenshot) ─────────
draw_menu_classic(){
    local ip=$(get_ip)
    local isp=$(get_isp)
    local os_info=$(get_os)
    local ram=$(get_ram)
    local city=$(get_city)
    local domain="${DOMAIN:-Not Set}"
    local exp_days=$(get_exp_days)
    local banner_name=$(get_banner_name)

    local ssh_st="$(chk sshd)"
    local nginx_st="$(chk nginx)"
    local xray_st="$(chk xray)"
    local ha_st="$(chk haproxy)"
    local drop_st="$(chk dropbear)"

    # Counts
    local sc=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    local vc=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    local lc=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    local tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    local ss=$(ls "$AKUN_DIR"/ss-*.txt 2>/dev/null | wc -l)

    local W_BOX=58

    _cl(){ echo -e "${G}+$(printf '%0.s-' $(seq 1 $W_BOX))+${NC}"; }
    _ch(){ echo -e "${Y}+$(printf '%0.s=' $(seq 1 $W_BOX))+${NC}"; }
    _crow(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local pad=$(( W_BOX - len - 1 ))
        [[ $pad -lt 0 ]] && pad=0
        printf "${G}|${NC} %b%*s${G}|${NC}\n" "$txt" "$pad" ""
    }
    _ctitle(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local lp=$(( (W_BOX - len) / 2 ))
        local rp=$(( W_BOX - len - lp ))
        printf "${G}+${NC}%*s${Y}%b${NC}%*s${G}+${NC}\n" "$lp" "" "$txt" "$rp" ""
    }

    clear
    echo ""
    _cl
    _ctitle "${YB}${banner_name}${NC}"
    _cl
    _crow " ${C}ISP${NC}    = ${W}${isp}${NC}"
    _crow " ${C}OS${NC}     = ${W}${os_info:0:40}${NC}"
    _crow " ${C}RAM${NC}    = ${W}${ram}${NC}"
    _crow " ${C}CITY${NC}   = ${W}${city}${NC}"
    _crow " ${C}IP VPS${NC} = ${W}${ip}${NC}"
    _crow " ${C}DOMAIN${NC} = ${W}${domain}${NC}"
    _crow " ${C}EXPIRY SCRIPT${NC} = ${Y}${exp_days} Days${NC}"
    _ch
    local ssh_c="${G}ON${NC}"; [[ "$ssh_st" == "OFF" ]] && ssh_c="${R}OFF${NC}"
    local nginx_c="${G}ON${NC}"; [[ "$nginx_st" == "OFF" ]] && nginx_c="${R}OFF${NC}"
    local xray_c="${G}ON${NC}"; [[ "$xray_st" == "OFF" ]] && xray_c="${R}OFF${NC}"
    local ha_c="${G}ON${NC}"; [[ "$ha_st" == "OFF" ]] && ha_c="${R}OFF${NC}"
    local drop_c="${G}ON${NC}"; [[ "$drop_st" == "OFF" ]] && drop_c="${R}OFF${NC}"
    _crow " ${W}SSH${NC} : ${ssh_c}    ${W}NGINX${NC} : ${nginx_c}    ${W}XRAY${NC} : ${xray_c}"
    _crow " ${W}HAPROXY${NC} : ${ha_c}    ${W}DROPBEAR${NC} : ${drop_c}"
    _ch
    _ctitle "${Y}-=[ MAIN MENU ]=-${NC}"
    _ch
    _crow " ${G}[01]${NC} SSH MENU       ${G}[07]${NC} DELL ALL EXP   ${G}[13]${NC} SETTINGS"
    _crow " ${G}[02]${NC} VMESS MENU     ${G}[08]${NC} BANDWIDTH      ${G}[14]${NC} AUTO REBOOT"
    _crow " ${G}[03]${NC} VLESS MENU     ${G}[09]${NC} INFO PORT      ${G}[15]${NC} RESTART"
    _crow " ${G}[04]${NC} TROJAN MENU    ${G}[10]${NC} SPEEDTEST      ${G}[16]${NC} DOMAIN"
    _crow " ${G}[05]${NC} SHADOW MENU    ${G}[11]${NC} RUNNING        ${G}[17]${NC} CERT SSL"
    _crow " ${G}[06]${NC} LIMITSPEED     ${G}[12]${NC} CLEAR LOG      ${G}[18]${NC} CLEAR CACHE"
    _ch
    _crow " ${C}SSH${NC} = ${G}${sc}${NC}   ${C}VMESS${NC} = ${G}${vc}${NC}   ${C}VLESS${NC} = ${G}${lc}${NC}"
    _crow " ${C}TROJAN${NC} = ${G}${tc}${NC}   ${C}SHADOWSOCKS${NC} = ${G}${ss}${NC}"
    _ch
    _crow " ${C}Version${NC}  = ${W}V${VER}${NC}"
    _crow " ${C}User${NC}     = ${W}$(hostname)${NC}"
    _crow " ${C}Script Status${NC} = ${G}$(date -d "$(get_script_exp)" +"%Y-%m-%d") (Active)${NC}"
    _cl
    echo ""
    echo -ne "  ${Y}Select menu ${NC}: "
}

# ─── TEMA 2: NEON (Cyan/Blue - Cyberpunk) ─────────────────────
draw_menu_neon(){
    local ip=$(get_ip)
    local isp=$(get_isp)
    local os_info=$(get_os)
    local ram=$(get_ram)
    local city=$(get_city)
    local domain="${DOMAIN:-Not Set}"
    local exp_days=$(get_exp_days)
    local banner_name=$(get_banner_name)

    local ssh_st="$(chk sshd)"
    local nginx_st="$(chk nginx)"
    local xray_st="$(chk xray)"

    local sc=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    local vc=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    local lc=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    local tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    local ss=$(ls "$AKUN_DIR"/ss-*.txt 2>/dev/null | wc -l)

    local W_BOX=58

    _nl(){ echo -e "${CB}╔$(printf '%0.s═' $(seq 1 $W_BOX))╗${NC}"; }
    _nb(){ echo -e "${CB}╚$(printf '%0.s═' $(seq 1 $W_BOX))╝${NC}"; }
    _ns(){ echo -e "${CB}╠$(printf '%0.s═' $(seq 1 $W_BOX))╣${NC}"; }
    _nrow(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local pad=$(( W_BOX - len - 1 ))
        [[ $pad -lt 0 ]] && pad=0
        printf "${CB}║${NC} %b%*s${CB}║${NC}\n" "$txt" "$pad" ""
    }
    _ntitle(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local lp=$(( (W_BOX - len) / 2 ))
        local rp=$(( W_BOX - len - lp ))
        printf "${CB}╠${NC}%*s${YB}%b${NC}%*s${CB}╣${NC}\n" "$lp" "" "$txt" "$rp" ""
    }

    clear
    echo ""
    _nl
    local bn="${banner_name}"
    local bnc=$(echo -e "$bn" | sed 's/\x1b\[[0-9;]*m//g'); local bnl=${#bnc}
    local lp=$(( (W_BOX - bnl) / 2 )); local rp=$(( W_BOX - bnl - lp ))
    printf "${CB}╠${NC}%*s${CB}${BG}%s${NC}%*s${CB}╣${NC}\n" "$lp" "" "$bn" "$rp" ""
    _nl
    _nrow " ${C}ISP${NC}    = ${W}${isp}${NC}"
    _nrow " ${C}OS${NC}     = ${W}${os_info:0:40}${NC}"
    _nrow " ${C}RAM${NC}    = ${W}${ram}${NC}"
    _nrow " ${C}CITY${NC}   = ${W}${city}${NC}"
    _nrow " ${C}IP VPS${NC} = ${W}${ip}${NC}"
    _nrow " ${C}DOMAIN${NC} = ${W}${domain}${NC}"
    _nrow " ${C}EXPIRY SCRIPT${NC} = ${Y}${exp_days} Days${NC}"
    _ns
    local ssh_c="${G}ON${NC}"; [[ "$ssh_st" == "OFF" ]] && ssh_c="${R}OFF${NC}"
    local nginx_c="${G}ON${NC}"; [[ "$nginx_st" == "OFF" ]] && nginx_c="${R}OFF${NC}"
    local xray_c="${G}ON${NC}"; [[ "$xray_st" == "OFF" ]] && xray_c="${R}OFF${NC}"
    _nrow " ${W}SSH${NC} : ${ssh_c}    ${W}NGINX${NC} : ${nginx_c}    ${W}XRAY${NC} : ${xray_c}"
    _ntitle "═══ MAIN MENU ═══"
    _nrow " ${CB}[01]${NC} SSH MENU       ${CB}[07]${NC} DELL ALL EXP   ${CB}[13]${NC} SETTINGS"
    _nrow " ${CB}[02]${NC} VMESS MENU     ${CB}[08]${NC} BANDWIDTH      ${CB}[14]${NC} AUTO REBOOT"
    _nrow " ${CB}[03]${NC} VLESS MENU     ${CB}[09]${NC} INFO PORT      ${CB}[15]${NC} RESTART"
    _nrow " ${CB}[04]${NC} TROJAN MENU    ${CB}[10]${NC} SPEEDTEST      ${CB}[16]${NC} DOMAIN"
    _nrow " ${CB}[05]${NC} SHADOW MENU    ${CB}[11]${NC} RUNNING        ${CB}[17]${NC} CERT SSL"
    _nrow " ${CB}[06]${NC} LIMITSPEED     ${CB}[12]${NC} CLEAR LOG      ${CB}[18]${NC} CLEAR CACHE"
    _ns
    _nrow " ${C}SSH${NC} = ${G}${sc}${NC}  ${C}VMESS${NC} = ${G}${vc}${NC}  ${C}VLESS${NC} = ${G}${lc}${NC}  ${C}TROJAN${NC} = ${G}${tc}${NC}"
    _nrow " ${C}SHADOWSOCKS${NC} = ${G}${ss}${NC}"
    _ns
    _nrow " ${C}Version${NC}  = ${W}V${VER}${NC}"
    _nrow " ${C}User${NC}     = ${W}$(hostname)${NC}"
    _nrow " ${C}Script Status${NC} = ${G}$(get_script_exp) (Active)${NC}"
    _nb
    echo ""
    echo -ne "  ${CB}❯${NC} Select menu : "
}

# ─── TEMA 3: RETRO (Magenta/Red - Matrix style) ───────────────
draw_menu_retro(){
    local ip=$(get_ip)
    local isp=$(get_isp)
    local os_info=$(get_os)
    local ram=$(get_ram)
    local city=$(get_city)
    local domain="${DOMAIN:-Not Set}"
    local exp_days=$(get_exp_days)
    local banner_name=$(get_banner_name)

    local ssh_st="$(chk sshd)"
    local nginx_st="$(chk nginx)"
    local xray_st="$(chk xray)"

    local sc=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    local vc=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    local lc=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    local tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)
    local ss=$(ls "$AKUN_DIR"/ss-*.txt 2>/dev/null | wc -l)

    local W_BOX=58

    _rl(){ echo -e "${M}▓$(printf '%0.s▒' $(seq 1 $W_BOX))▓${NC}"; }
    _rs(){ echo -e "${M}▓$(printf '%0.s─' $(seq 1 $W_BOX))▓${NC}"; }
    _rrow(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local pad=$(( W_BOX - len - 1 ))
        [[ $pad -lt 0 ]] && pad=0
        printf "${M}▓${NC} %b%*s${M}▓${NC}\n" "$txt" "$pad" ""
    }
    _rtitle(){
        local txt="$1"
        local clean=$(echo -e "$txt" | sed 's/\x1b\[[0-9;]*m//g')
        local len=${#clean}
        local lp=$(( (W_BOX - len) / 2 ))
        local rp=$(( W_BOX - len - lp ))
        printf "${M}▓${NC}%*s${RB}%b${NC}%*s${M}▓${NC}\n" "$lp" "" "$txt" "$rp" ""
    }

    clear
    echo ""
    _rl
    _rtitle "${banner_name}"
    _rl
    _rrow " ${Y}ISP${NC}    = ${W}${isp}${NC}"
    _rrow " ${Y}OS${NC}     = ${W}${os_info:0:40}${NC}"
    _rrow " ${Y}RAM${NC}    = ${W}${ram}${NC}"
    _rrow " ${Y}CITY${NC}   = ${W}${city}${NC}"
    _rrow " ${Y}IP VPS${NC} = ${W}${ip}${NC}"
    _rrow " ${Y}DOMAIN${NC} = ${W}${domain}${NC}"
    _rrow " ${Y}EXPIRY SCRIPT${NC} = ${RB}${exp_days} Days${NC}"
    _rs
    local ssh_c="${G}ON${NC}"; [[ "$ssh_st" == "OFF" ]] && ssh_c="${R}OFF${NC}"
    local nginx_c="${G}ON${NC}"; [[ "$nginx_st" == "OFF" ]] && nginx_c="${R}OFF${NC}"
    local xray_c="${G}ON${NC}"; [[ "$xray_st" == "OFF" ]] && xray_c="${R}OFF${NC}"
    _rrow " ${W}SSH${NC} : ${ssh_c}    ${W}NGINX${NC} : ${nginx_c}    ${W}XRAY${NC} : ${xray_c}"
    _rtitle "[ MAIN MENU ]"
    _rs
    _rrow " ${RB}[01]${NC} SSH MENU       ${RB}[07]${NC} DELL ALL EXP   ${RB}[13]${NC} SETTINGS"
    _rrow " ${RB}[02]${NC} VMESS MENU     ${RB}[08]${NC} BANDWIDTH      ${RB}[14]${NC} AUTO REBOOT"
    _rrow " ${RB}[03]${NC} VLESS MENU     ${RB}[09]${NC} INFO PORT      ${RB}[15]${NC} RESTART"
    _rrow " ${RB}[04]${NC} TROJAN MENU    ${RB}[10]${NC} SPEEDTEST      ${RB}[16]${NC} DOMAIN"
    _rrow " ${RB}[05]${NC} SHADOW MENU    ${RB}[11]${NC} RUNNING        ${RB}[17]${NC} CERT SSL"
    _rrow " ${RB}[06]${NC} LIMITSPEED     ${RB}[12]${NC} CLEAR LOG      ${RB}[18]${NC} CLEAR CACHE"
    _rs
    _rrow " ${Y}SSH${NC} = ${G}${sc}${NC}  ${Y}VMESS${NC} = ${G}${vc}${NC}  ${Y}VLESS${NC} = ${G}${lc}${NC}  ${Y}TROJAN${NC} = ${G}${tc}${NC}"
    _rrow " ${Y}SHADOWSOCKS${NC} = ${G}${ss}${NC}"
    _rs
    _rrow " ${Y}Version${NC}  = ${W}V${VER}${NC}"
    _rrow " ${Y}User${NC}     = ${W}$(hostname)${NC}"
    _rrow " ${Y}Script Status${NC} = ${G}$(get_script_exp) (Active)${NC}"
    _rl
    echo ""
    echo -ne "  ${M}▶${NC} Select menu : "
}

# ─── Main menu dispatcher ─────────────────────────────────────
draw_main_menu(){
    load_domain
    init_expiry
    case $(get_theme) in
        neon)   draw_menu_neon ;;
        retro)  draw_menu_retro ;;
        *)      draw_menu_classic ;;
    esac
}

# ─── Theme selector ──────────────────────────────────────────
select_theme(){
    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|              PILIH TEMA TAMPILAN MENU                    |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -e "  ${G}[1]${NC} ${W}CLASSIC${NC} ${D}── Green/Yellow border (seperti screenshot)${NC}"
    echo -e "  ${G}[2]${NC} ${W}NEON${NC}    ${D}── Cyan/Blue double border (Cyberpunk)${NC}"
    echo -e "  ${G}[3]${NC} ${W}RETRO${NC}   ${D}── Magenta block border (Matrix/Hacker)${NC}"
    echo ""
    echo -ne "  ${Y}Pilih tema [1-3]: ${NC}"
    read -r tc
    case "$tc" in
        1) echo "classic" > "$THEME_FILE"; echo -e "\n  ${G}✓ Tema CLASSIC diaktifkan!${NC}" ;;
        2) echo "neon"    > "$THEME_FILE"; echo -e "\n  ${CB}✓ Tema NEON diaktifkan!${NC}" ;;
        3) echo "retro"   > "$THEME_FILE"; echo -e "\n  ${M}✓ Tema RETRO diaktifkan!${NC}" ;;
        *)  echo "classic" > "$THEME_FILE"; echo -e "\n  ${Y}Default CLASSIC.${NC}" ;;
    esac
    sleep 1
}

set_banner_name(){
    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|              SET NAMA BANNER / JUDUL                     |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -e "  ${D}Nama banner saat ini: ${W}$(get_banner_name)${NC}"
    echo ""
    echo -ne "  ${Y}❯${NC} Nama baru (kosong=batal): "
    read -r bname
    [[ -n "$bname" ]] && echo "$bname" > "$BANNER_FILE" && echo -e "\n  ${G}✓ Banner diubah ke: ${W}${bname}${NC}" || echo -e "\n  ${Y}Dibatalkan.${NC}"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  XRAY CONFIG - TLS 443 + NON-TLS 80
# ═══════════════════════════════════════════════════════════════
# Port Mapping:
#   TLS (via HAProxy 443):
#     VMess  WS  TLS    → 8443
#     VLess  WS  TLS    → 8445
#     Trojan WS  TLS    → 8447
#     VMess  gRPC TLS   → 8444
#     VLess  gRPC TLS   → 8446
#     Trojan gRPC TLS   → 8448
#   Non-TLS (via Nginx 80):
#     VMess  WS  HTTP   → 8880
#     VLess  WS  HTTP   → 8881
#     Trojan WS  HTTP   → 8882
# Nginx 80: proxy /vmess→8880, /vless→8881, /trojan→8882
# HAProxy 443 → 8443 (Xray handles its own TLS)

fix_xray_perm(){
    mkdir -p /usr/local/etc/xray /var/log/xray /etc/xray
    touch /var/log/xray/access.log /var/log/xray/error.log
    chmod 755 /usr/local/etc/xray /var/log/xray
    chmod 644 /var/log/xray/*.log
    [[ -f "$XRAY_CONFIG" ]] && chmod 644 "$XRAY_CONFIG"
}

make_xray_config(){
    mkdir -p /usr/local/etc/xray /var/log/xray /etc/xray
    cat > "$XRAY_CONFIG" << 'XCFG'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error":  "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vmess-ws-tls",
      "port": 8443,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "wsSettings": { "path": "/vmess" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vmess-ws-nontls",
      "port": 8880,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/vmess", "headers": { "Host": "" } }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vmess-grpc-tls",
      "port": 8444,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "grpcSettings": { "serviceName": "vmess-grpc" }
      }
    },
    {
      "tag": "vless-ws-tls",
      "port": 8445,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "wsSettings": { "path": "/vless" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vless-ws-nontls",
      "port": 8881,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/vless", "headers": { "Host": "" } }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vless-grpc-tls",
      "port": 8446,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "grpcSettings": { "serviceName": "vless-grpc" }
      }
    },
    {
      "tag": "trojan-ws-tls",
      "port": 8447,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "wsSettings": { "path": "/trojan" }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "trojan-ws-nontls",
      "port": 8882,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": { "path": "/trojan", "headers": { "Host": "" } }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "trojan-grpc-tls",
      "port": 8448,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/xray.crt", "keyFile": "/etc/xray/xray.key" }]
        },
        "grpcSettings": { "serviceName": "trojan-grpc" }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": { "domainStrategy": "UseIPv4" }, "tag": "direct" },
    { "protocol": "blackhole", "settings": {}, "tag": "block" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [{ "type": "field", "ip": ["geoip:private"], "outboundTag": "block" }]
  }
}
XCFG
    fix_xray_perm
}

make_nginx_config(){
    cat > /etc/nginx/sites-available/default << 'NGEOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
        autoindex on;
    }

    # VMess NonTLS WS → port 8880
    location /vmess {
        proxy_pass http://127.0.0.1:8880;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # VLess NonTLS WS → port 8881
    location /vless {
        proxy_pass http://127.0.0.1:8881;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Trojan NonTLS WS → port 8882
    location /trojan {
        proxy_pass http://127.0.0.1:8882;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}

# Download server port 81
server {
    listen 81;
    server_name _;
    root /var/www/html;
    autoindex on;
}
NGEOF
    nginx -t >/dev/null 2>&1 && systemctl reload nginx 2>/dev/null || warn "Nginx config error!"
}

make_haproxy_config(){
    cat > /etc/haproxy/haproxy.cfg << 'HEOF'
global
    log /dev/log local0
    maxconn 65535
    tune.ssl.default-dh-param 2048
    ulimit-n 65535

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    timeout connect 5s
    timeout client  1h
    timeout server  1h
    maxconn 65535

# Frontend: accepts TLS on 443 and forwards to Xray (Xray handles TLS itself)
frontend front_443
    bind *:443
    mode tcp
    default_backend back_xray_tls

backend back_xray_tls
    mode tcp
    option tcp-check
    server xray 127.0.0.1:8443 check inter 3s
HEOF
    haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1 && systemctl restart haproxy 2>/dev/null || warn "HAProxy config error!"
}

get_ssl(){
    local dtype="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && dtype=$(cat "$DOMAIN_TYPE_FILE")
    mkdir -p /etc/xray

    if [[ "$dtype" == "custom" ]] && command -v certbot >/dev/null 2>&1; then
        systemctl stop nginx haproxy 2>/dev/null
        certbot certonly --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos --register-unsafely-without-email \
            >/dev/null 2>&1
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
            chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
            systemctl start nginx haproxy 2>/dev/null
            echo "letsencrypt"
            return
        fi
        systemctl start nginx haproxy 2>/dev/null
    fi
    # Self-signed fallback
    openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
        -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
    chmod 644 /etc/xray/xray.crt /etc/xray/xray.key
    echo "self-signed"
}

# ═══════════════════════════════════════════════════════════════
#  XRAY ACCOUNT HELPERS
# ═══════════════════════════════════════════════════════════════

_xray_add(){
    local proto="$1" uuid="$2" email="$3"
    local tmp=$(mktemp)

    if [[ "$proto" == "vmess" ]]; then
        jq --arg u "$uuid" --arg e "$email" \
          '(.inbounds[] | select(.tag | startswith("vmess")) | .settings.clients) += [{"id":$u,"email":$e,"alterId":0}]' \
          "$XRAY_CONFIG" > "$tmp"
    elif [[ "$proto" == "vless" ]]; then
        jq --arg u "$uuid" --arg e "$email" \
          '(.inbounds[] | select(.tag | startswith("vless")) | .settings.clients) += [{"id":$u,"email":$e,"flow":""}]' \
          "$XRAY_CONFIG" > "$tmp"
    elif [[ "$proto" == "trojan" ]]; then
        jq --arg p "$uuid" --arg e "$email" \
          '(.inbounds[] | select(.tag | startswith("trojan")) | .settings.clients) += [{"password":$p,"email":$e}]' \
          "$XRAY_CONFIG" > "$tmp"
    fi

    if jq . "$tmp" >/dev/null 2>&1 && [[ -s "$tmp" ]]; then
        mv "$tmp" "$XRAY_CONFIG"
        fix_xray_perm
        systemctl restart xray 2>/dev/null
        return 0
    fi
    rm -f "$tmp"; return 1
}

_xray_del(){
    local email="$1"
    local tmp=$(mktemp)
    jq --arg e "$email" \
      'del(.inbounds[].settings.clients[]? | select(.email == $e))' \
      "$XRAY_CONFIG" > "$tmp"
    if jq . "$tmp" >/dev/null 2>&1 && [[ -s "$tmp" ]]; then
        mv "$tmp" "$XRAY_CONFIG"
        fix_xray_perm
        systemctl restart xray 2>/dev/null
        return 0
    fi
    rm -f "$tmp"; return 1
}

_gen_links(){
    local proto="$1" uuid="$2" user="$3"
    local ip=$(get_ip)
    case "$proto" in
      vmess)
        # TLS via HAProxy 443 (bug.com for SNI bypass)
        local j_tls=$(printf '{"v":"2","ps":"%s-TLS","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$user" "$uuid" "$DOMAIN")
        # NonTLS via Nginx 80
        local j_nontls=$(printf '{"v":"2","ps":"%s-HTTP","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$user" "$uuid" "$DOMAIN")
        # gRPC TLS direct
        local j_grpc=$(printf '{"v":"2","ps":"%s-gRPC","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"%s","tls":"tls"}' "$user" "$DOMAIN" "$uuid" "$DOMAIN")
        echo "vmess://$(echo -n "$j_tls"|base64 -w0)"
        echo "vmess://$(echo -n "$j_nontls"|base64 -w0)"
        echo "vmess://$(echo -n "$j_grpc"|base64 -w0)"
        ;;
      vless)
        # TLS 443
        echo "vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}-TLS"
        # NonTLS 80
        echo "vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${user}-HTTP"
        # gRPC TLS
        echo "vless://${uuid}@${DOMAIN}:8446?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${DOMAIN}#${user}-gRPC"
        ;;
      trojan)
        # TLS 443
        echo "trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}-TLS"
        # NonTLS 80
        echo "trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${user}-HTTP"
        # gRPC TLS
        echo "trojan://${uuid}@${DOMAIN}:8448?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${DOMAIN}#${user}-gRPC"
        ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  DOMAIN SETUP
# ═══════════════════════════════════════════════════════════════

setup_domain(){
    clear
    local ip=$(get_ip)
    local rand_dom=$(gen_random_domain)

    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|             KONFIGURASI DOMAIN VPN SERVER                |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -e "  ${G}[1]${NC} ${W}Domain Pribadi${NC}  ${D}→ Let's Encrypt SSL (Direkomendasikan)${NC}"
    echo -e "      ${D}Contoh: vpn.namadomain.com${NC}"
    echo -e "      ${R}⚠${NC}  ${D}Domain harus pointing ke IP: ${Y}${ip}${NC}"
    echo ""
    echo -e "  ${G}[2]${NC} ${W}Domain Otomatis${NC} ${D}→ Self-Signed SSL (nip.io)${NC}"
    echo -e "      ${D}Preview: ${C}${rand_dom}${NC}"
    echo ""
    echo -ne "  ${Y}Pilihan [1/2]: ${NC}"
    read -r dc

    case "$dc" in
      1)
        echo -ne "\n  ${Y}❯${NC} Masukkan domain: "
        read -r idomain
        if [[ -z "$idomain" ]] || ! echo "$idomain" | grep -qE '^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$'; then
            warn "Format domain tidak valid!"; sleep 2; setup_domain; return
        fi
        DOMAIN="$idomain"
        echo "custom" > "$DOMAIN_TYPE_FILE"
        ;;
      2)
        DOMAIN="$rand_dom"
        echo "random" > "$DOMAIN_TYPE_FILE"
        ;;
      *)
        warn "Pilihan tidak valid!"; sleep 2; setup_domain; return
        ;;
    esac

    echo "$DOMAIN" > "$DOMAIN_FILE"
    echo ""
    echo -e "  ${G}✓ Domain disimpan: ${CB}${DOMAIN}${NC}"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  SSH FUNCTIONS
# ═══════════════════════════════════════════════════════════════

ssh_menu(){
    while true; do
        clear
        echo ""
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|                      SSH MENU                           |${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|${NC}  ${G}[1]${NC} Buat Akun SSH         ${G}[5]${NC} Login Aktif            ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[2]${NC} Trial SSH (1 Jam)     ${G}[6]${NC} Daftar Semua Akun      ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[3]${NC} Hapus Akun SSH        ${G}[7]${NC} Set IP Limit           ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[4]${NC} Perpanjang Akun       ${G}[0]${NC} Kembali                ${G}|${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo ""
        echo -ne "  ${Y}Pilihan: ${NC}"
        read -r ch
        case "$ch" in
            1) ssh_create ;;
            2) ssh_trial ;;
            3) ssh_delete ;;
            4) ssh_renew ;;
            5) ssh_active ;;
            6) list_accounts "ssh" ;;
            7) ssh_iplimit ;;
            0) return ;;
        esac
    done
}

ssh_create(){
    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|                   BUAT AKUN SSH                         |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${G}Username${NC}       : "; read -r uname
    [[ -z "$uname" ]] && { warn "Username tidak boleh kosong!"; sleep 2; return; }
    id "$uname" &>/dev/null && { warn "Username sudah ada!"; sleep 2; return; }
    echo -ne "  ${G}Password${NC}       : "; read -r upass
    [[ -z "$upass" ]] && { warn "Password tidak boleh kosong!"; sleep 2; return; }
    echo -ne "  ${G}Expired (hari)${NC} : "; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Hari harus angka!"; sleep 2; return; }
    echo -ne "  ${G}Batas IP${NC}       : "; read -r iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=2

    local exp=$(date -d "+${days} days" +"%d %b %Y")
    local exp_raw=$(date -d "+${days} days" +"%Y-%m-%d")
    local ip=$(get_ip)

    useradd -M -s /bin/false -e "$exp_raw" "$uname" 2>/dev/null
    echo "${uname}:${upass}" | chpasswd

    mkdir -p "$AKUN_DIR"
    cat > "$AKUN_DIR/ssh-${uname}.txt" << EOF
USERNAME=${uname}
PASSWORD=${upass}
IPLIMIT=${iplimit}
EXPIRED=${exp}
CREATED=$(date +"%d %b %Y")
EOF

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${uname}.txt" << EOF
======================================================
  SSH ACCOUNT - $(get_banner_name)
======================================================
  Username     : ${uname}
  Password     : ${upass}
  IP/Host      : ${ip}
  Domain       : ${DOMAIN}
------------------------------------------------------
  Port OpenSSH : 22
  Port Dropbear: 222
  Port SSL/TLS : 443
  Port WS HTTP : 80
  Port WS SSL  : 443
  BadVPN UDP   : 7100,7200,7300
------------------------------------------------------
  Download     : http://${ip}:81/ssh-${uname}.txt
  Dibuat       : $(date +"%d %b %Y")
  Expired      : ${exp}
  Durasi       : ${days} Hari
======================================================
EOF

    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               ✓ AKUN SSH BERHASIL DIBUAT                |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${C}Username${NC}     : ${W}${uname}${NC}"
    echo -e "${G}|${NC}  ${C}Password${NC}     : ${W}${upass}${NC}"
    echo -e "${G}|${NC}  ${C}IP/Host${NC}      : ${W}${ip}${NC}"
    echo -e "${G}|${NC}  ${C}Domain${NC}       : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}  ${C}Batas IP${NC}     : ${W}${iplimit} IP${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  --- Port Info ---"
    echo -e "${G}|${NC}  ${C}OpenSSH${NC}      : ${W}22${NC}"
    echo -e "${G}|${NC}  ${C}Dropbear${NC}     : ${W}222${NC}"
    echo -e "${G}|${NC}  ${C}SSL/TLS${NC}      : ${W}443${NC}"
    echo -e "${G}|${NC}  ${C}WS HTTP${NC}      : ${W}80${NC}"
    echo -e "${G}|${NC}  ${C}BadVPN UDP${NC}   : ${W}7100-7300${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  --- Info ---"
    echo -e "${G}|${NC}  ${C}Download${NC}     : http://${ip}:81/ssh-${uname}.txt"
    echo -e "${G}|${NC}  ${C}Expired${NC}      : ${R}${exp}${NC}"
    echo -e "${G}|${NC}  ${C}Durasi${NC}       : ${W}${days} Hari${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    tg "✅ <b>SSH Baru</b>
👤 <code>${uname}</code> | 🔑 <code>${upass}</code>
🌐 ${ip} | 📅 ${exp}"

    echo ""; read -rp "  Tekan Enter..."
}

ssh_trial(){
    local ts=$(date +%H%M%S)
    local uname="trial-${ts}"
    local upass="trial123"
    local ip=$(get_ip)
    local exp=$(date -d "+1 days" +"%Y-%m-%d")
    local exp_show=$(date -d "+1 hour" +"%d %b %Y %H:%M")

    useradd -M -s /bin/false -e "$exp" "$uname" 2>/dev/null
    echo "${uname}:${upass}" | chpasswd
    (sleep 3600; userdel -rf "$uname" 2>/dev/null; rm -f "$AKUN_DIR/ssh-${uname}.txt") & disown

    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|               ⏱ SSH TRIAL 1 JAM                        |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}|${NC}  ${C}Username${NC}  : ${W}${uname}${NC}"
    echo -e "${Y}|${NC}  ${C}Password${NC}  : ${W}${upass}${NC}"
    echo -e "${Y}|${NC}  ${C}Domain${NC}    : ${W}${DOMAIN}${NC}"
    echo -e "${Y}|${NC}  ${C}OpenSSH${NC}   : ${W}22${NC}"
    echo -e "${Y}|${NC}  ${C}Dropbear${NC}  : ${W}222${NC}"
    echo -e "${Y}|${NC}  ${C}Expired${NC}   : ${R}${exp_show}${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}|${NC}  ${Y}⚠ Auto-hapus setelah 1 jam${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

ssh_delete(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   HAPUS AKUN SSH                        |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun SSH.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username yang dihapus: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    userdel -rf "$uname" 2>/dev/null
    rm -f "$AKUN_DIR/ssh-${uname}.txt" "$PUBLIC_HTML/ssh-${uname}.txt"
    echo -e "\n  ${G}✓ Akun ${uname} dihapus.${NC}"; sleep 2
}

ssh_renew(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               PERPANJANG AKUN SSH                       |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun SSH.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/ssh-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    echo -ne "  ${Y}Tambah hari: ${NC}"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    local new_exp=$(date -d "+${days} days" +"%d %b %Y")
    local new_raw=$(date -d "+${days} days" +"%Y-%m-%d")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/ssh-${uname}.txt"
    chage -E "$new_raw" "$uname" 2>/dev/null
    echo -e "\n  ${G}✓ Diperpanjang! Expired baru: ${new_exp}${NC}"; sleep 2
}

ssh_active(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   LOGIN SSH AKTIF                       |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local au=$(who 2>/dev/null | awk '{print $1}' | sort | uniq)
    if [[ -z "$au" ]]; then
        echo -e "${G}|${NC}  ${Y}Tidak ada sesi SSH aktif.${NC}"
    else
        while IFS= read -r u; do
            local cnt=$(who | grep -c "^${u} ")
            echo -e "${G}|${NC}  ${G}●${NC} ${W}${u}${NC}  ${D}${cnt} koneksi${NC}"
        done <<< "$au"
    fi
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

ssh_iplimit(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   SET IP LIMIT SSH                      |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun SSH.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local il=$(grep "IPLIMIT=" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}limit: ${Y}${il:-?}${NC} IP"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/ssh-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    echo -ne "  ${Y}IP Limit baru: ${NC}"; read -r newlimit
    [[ ! "$newlimit" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    sed -i "s/IPLIMIT=.*/IPLIMIT=${newlimit}/" "$AKUN_DIR/ssh-${uname}.txt"
    echo -e "\n  ${G}✓ IP Limit ${uname} → ${newlimit} IP${NC}"; sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  XRAY MENU (VMess / VLess / Trojan)
# ═══════════════════════════════════════════════════════════════

xray_menu(){
    local proto="$1"
    while true; do
        clear
        echo ""
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|                   ${proto^^} MENU                                |${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|${NC}  ${G}[1]${NC} Buat Akun ${proto^^}         ${G}[5]${NC} Koneksi Aktif          ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[2]${NC} Trial ${proto^^} (1 Jam)     ${G}[6]${NC} Daftar Semua Akun      ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[3]${NC} Hapus Akun           ${G}[7]${NC} Set Quota Bandwidth    ${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[4]${NC} Perpanjang Akun      ${G}[0]${NC} Kembali                ${G}|${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo ""
        echo -ne "  ${Y}Pilihan: ${NC}"
        read -r ch
        case "$ch" in
            1) xray_create "$proto" ;;
            2) xray_trial "$proto" ;;
            3) xray_delete "$proto" ;;
            4) xray_renew "$proto" ;;
            5) xray_active "$proto" ;;
            6) list_accounts "$proto" ;;
            7) xray_quota "$proto" ;;
            0) return ;;
        esac
    done
}

xray_create(){
    local proto="$1"
    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|               BUAT AKUN ${proto^^}                               |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${G}Username${NC}                    : "; read -r uname
    [[ -z "$uname" ]] && { warn "Username tidak boleh kosong!"; sleep 2; return; }
    grep -q "\"email\":\"${uname}\"" "$XRAY_CONFIG" 2>/dev/null && { warn "Username sudah ada!"; sleep 2; return; }
    echo -ne "  ${G}Expired (hari)${NC}              : "; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    echo -ne "  ${G}Quota GB (0=unlimited)${NC}      : "; read -r quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=0
    echo -ne "  ${G}Batas IP (default 2)${NC}        : "; read -r iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=2

    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local ip=$(get_ip)
    local exp=$(date -d "+${days} days" +"%d %b %Y")

    _xray_add "$proto" "$uuid" "$uname" || { warn "Gagal update config Xray!"; sleep 2; return; }

    mkdir -p "$AKUN_DIR"
    cat > "$AKUN_DIR/${proto}-${uname}.txt" << EOF
UUID=${uuid}
QUOTA=${quota}
IPLIMIT=${iplimit}
EXPIRED=${exp}
CREATED=$(date +"%d %b %Y")
EOF

    local links=()
    mapfile -t links < <(_gen_links "$proto" "$uuid" "$uname")
    local l_tls="${links[0]:-N/A}"
    local l_http="${links[1]:-N/A}"
    local l_grpc="${links[2]:-N/A}"

    local p_tls p_http p_grpc p_ws
    case "$proto" in
        vmess)  p_tls="8443 (HAProxy→443)"; p_http="8880 (Nginx→80)"; p_grpc="8444"; p_ws="/vmess"   ;;
        vless)  p_tls="8445 (HAProxy→443)"; p_http="8881 (Nginx→80)"; p_grpc="8446"; p_ws="/vless"   ;;
        trojan) p_tls="8447 (HAProxy→443)"; p_http="8882 (Nginx→80)"; p_grpc="8448"; p_ws="/trojan"  ;;
    esac

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${proto}-${uname}.txt" << EOF
======================================================
  ${proto^^} ACCOUNT - $(get_banner_name)
======================================================
  Username  : ${uname}
  UUID      : ${uuid}
  Domain    : ${DOMAIN}
  Quota     : $( [[ $quota -eq 0 ]] && echo "Unlimited" || echo "${quota} GB" )
  IP Limit  : ${iplimit} IP
------------------------------------------------------
  Port TLS (443) : ${p_tls}
  Port HTTP (80) : ${p_http}
  Port gRPC      : ${p_grpc}
  Path WS        : ${p_ws}
------------------------------------------------------
  Link TLS (443):
  ${l_tls}
------------------------------------------------------
  Link HTTP (80):
  ${l_http}
------------------------------------------------------
  Link gRPC:
  ${l_grpc}
------------------------------------------------------
  Download  : http://${ip}:81/${proto}-${uname}.txt
  Expired   : ${exp}
  Durasi    : ${days} Hari
======================================================
EOF

    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|           ✓ AKUN ${proto^^} BERHASIL DIBUAT                      |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${C}Username${NC}       : ${W}${uname}${NC}"
    echo -e "${G}|${NC}  ${C}UUID${NC}           : ${D}${uuid}${NC}"
    echo -e "${G}|${NC}  ${C}Domain${NC}         : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}  ${C}Quota${NC}          : $( [[ $quota -eq 0 ]] && echo "${G}Unlimited${NC}" || echo "${Y}${quota} GB${NC}" )"
    echo -e "${G}|${NC}  ${C}IP Limit${NC}       : ${Y}${iplimit} IP${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  --- Port (TLS 443) ---"
    echo -e "${G}|${NC}  ${C}TLS Port${NC}       : ${W}${p_tls}${NC}"
    echo -e "${G}|${NC}  --- Port (NonTLS 80) ---"
    echo -e "${G}|${NC}  ${C}HTTP Port${NC}      : ${W}${p_http}${NC}"
    echo -e "${G}|${NC}  ${C}gRPC TLS${NC}       : ${W}${p_grpc}${NC}"
    echo -e "${G}|${NC}  ${C}WS Path${NC}        : ${W}${p_ws}${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  --- Link TLS (443) ---"
    local short_tls="${l_tls:0:55}..."
    echo -e "${G}|${NC}  ${D}${short_tls}${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  --- Info ---"
    echo -e "${G}|${NC}  ${C}Download${NC}       : http://${ip}:81/${proto}-${uname}.txt"
    echo -e "${G}|${NC}  ${C}Expired${NC}        : ${R}${exp}${NC}"
    echo -e "${G}|${NC}  ${C}Durasi${NC}         : ${W}${days} Hari${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    tg "✅ <b>${proto^^} Baru</b>
👤 <code>${uname}</code>
🔑 <code>${uuid}</code>
🌐 ${DOMAIN}
📅 ${exp}"

    echo ""; read -rp "  Tekan Enter..."
}

xray_trial(){
    local proto="$1"
    local ts=$(date +%H%M%S)
    local uname="trial-${ts}"
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local exp=$(date -d "+1 hour" +"%d %b %Y %H:%M")

    _xray_add "$proto" "$uuid" "$uname" || { warn "Gagal!"; sleep 2; return; }
    (sleep 3600; _xray_del "$uname"; rm -f "$AKUN_DIR/${proto}-${uname}.txt") & disown

    local links=()
    mapfile -t links < <(_gen_links "$proto" "$uuid" "$uname")

    clear
    echo ""
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|               ⏱ ${proto^^} TRIAL 1 JAM                        |${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}|${NC}  ${C}Username${NC}  : ${W}${uname}${NC}"
    echo -e "${Y}|${NC}  ${C}UUID${NC}      : ${D}${uuid}${NC}"
    echo -e "${Y}|${NC}  ${C}Domain${NC}    : ${W}${DOMAIN}${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}|${NC}  ${C}Link TLS (443):${NC}"
    local short="${links[0]:0:55}..."
    echo -e "${Y}|${NC}  ${D}${short}${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}|${NC}  ${C}Expired${NC}   : ${R}${exp}${NC}"
    echo -e "${Y}|${NC}  ${Y}⚠ Auto-hapus setelah 1 jam${NC}"
    echo -e "${Y}|${NC}"
    echo -e "${Y}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

xray_delete(){
    local proto="$1"
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                HAPUS AKUN ${proto^^}                             |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun ${proto^^}.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username yang dihapus: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    _xray_del "$uname"
    rm -f "$AKUN_DIR/${proto}-${uname}.txt" "$PUBLIC_HTML/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Akun ${uname} dihapus.${NC}"; sleep 2
}

xray_renew(){
    local proto="$1"
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              PERPANJANG AKUN ${proto^^}                          |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/${proto}-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    echo -ne "  ${Y}Tambah hari: ${NC}"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    local new_exp=$(date -d "+${days} days" +"%d %b %Y")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Diperpanjang! Expired baru: ${new_exp}${NC}"; sleep 2
}

xray_active(){
    local proto="$1"
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              KONEKSI ${proto^^} AKTIF                           |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    if [[ ! -f /var/log/xray/access.log ]]; then
        echo -e "${G}|${NC}  ${Y}Log tidak ditemukan.${NC}"
    else
        local logs=$(grep "accepted" /var/log/xray/access.log 2>/dev/null | tail -100)
        local users=$(echo "$logs" | grep -oP 'email: \K[^ >]+' | sort | uniq)
        if [[ -z "$users" ]]; then
            echo -e "${G}|${NC}  ${Y}Tidak ada koneksi aktif.${NC}"
        else
            while IFS= read -r u; do
                local cnt=$(echo "$logs" | grep -c "email: $u")
                echo -e "${G}|${NC}  ${G}●${NC} ${W}${u}${NC}  ${D}${cnt} koneksi${NC}"
            done <<< "$users"
        fi
    fi
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

xray_quota(){
    local proto="$1"
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              SET QUOTA ${proto^^}                                |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${R}Tidak ada akun.${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local q=$(grep "QUOTA=" "$f" 2>/dev/null | cut -d= -f2-)
        local ql=$( [[ "${q:-0}" == "0" ]] && echo "Unlimited" || echo "${q}GB" )
        echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}quota: ${Y}${ql}${NC}"
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; echo ""
    echo -ne "  ${Y}Username: ${NC}"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/${proto}-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    echo -ne "  ${Y}Quota baru GB (0=unlimited): ${NC}"; read -r newq
    [[ ! "$newq" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    sed -i "s/QUOTA=.*/QUOTA=${newq}/" "$AKUN_DIR/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Quota ${uname} → $( [[ $newq -eq 0 ]] && echo "Unlimited" || echo "${newq}GB" )${NC}"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  LIST & EXPIRED
# ═══════════════════════════════════════════════════════════════

list_accounts(){
    local proto="$1"
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               DAFTAR AKUN ${proto^^}                             |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "${G}|${NC}  ${Y}Tidak ada akun ${proto^^}.${NC}"
    else
        for f in "${files[@]}"; do
            local un=$(basename "$f" .txt | sed "s/${proto}-//")
            local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
            local q=$(grep "QUOTA=" "$f" 2>/dev/null | cut -d= -f2-)
            local q_str=$( [[ "${q:-0}" == "0" ]] && echo "∞" || echo "${q}GB" )
            echo -e "${G}|${NC}  ${G}▸${NC} ${W}${un}${NC}  ${D}exp:${ex}  q:${q_str}${NC}"
        done
        echo -e "${G}|${NC}  ${D}Total: ${G}${#files[@]}${NC} akun"
    fi
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

list_all(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                  SEMUA AKUN AKTIF                       |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local total=0
    shopt -s nullglob
    for proto in ssh vmess vless trojan; do
        local files=("$AKUN_DIR"/${proto}-*.txt)
        [[ ${#files[@]} -eq 0 ]] && continue
        echo -e "${G}|${NC}  ${Y}── ${proto^^} (${#files[@]}) ──${NC}"
        for f in "${files[@]}"; do
            local un=$(basename "$f" .txt | sed "s/${proto}-//")
            local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
            echo -e "${G}|${NC}  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
            ((total++))
        done
    done
    shopt -u nullglob
    echo -e "${G}|${NC}  ${D}Total: ${G}${total}${NC} akun"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

check_expired(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               CEK AKUN EXPIRED                          |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local today=$(date +%s)
    local found=0
    shopt -s nullglob
    for f in "$AKUN_DIR"/*.txt; do
        [[ -f "$f" ]] || continue
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
        [[ -z "$ex" ]] && continue
        local et=$(date -d "$ex" +%s 2>/dev/null)
        [[ -z "$et" ]] && continue
        local un=$(basename "$f" .txt)
        local diff=$(( (et - today) / 86400 ))
        if [[ $diff -le 3 ]]; then
            found=1
            if [[ $diff -lt 0 ]]; then
                echo -e "${G}|${NC}  ${R}✗ EXPIRED${NC}  ${W}${un}${NC}  ${D}(${ex})${NC}"
            else
                echo -e "${G}|${NC}  ${Y}⚠ ${diff}h${NC}  ${W}${un}${NC}  ${D}(${ex})${NC}"
            fi
        fi
    done
    shopt -u nullglob
    [[ $found -eq 0 ]] && echo -e "${G}|${NC}  ${G}✓ Tidak ada akun hampir expired.${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

delete_expired(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               HAPUS AKUN EXPIRED                        |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local today=$(date +%s)
    local count=0
    shopt -s nullglob
    for f in "$AKUN_DIR"/*.txt; do
        [[ -f "$f" ]] || continue
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | head -1 | cut -d= -f2-)
        [[ -z "$ex" ]] && continue
        local et=$(date -d "$ex" +%s 2>/dev/null)
        [[ -z "$et" ]] && continue
        if [[ $et -lt $today ]]; then
            local fn=$(basename "$f" .txt)
            local proto="${fn%%-*}"
            local uname="${fn#*-}"
            echo -e "${G}|${NC}  ${R}↺ Menghapus${NC} ${W}${fn}${NC}"
            _xray_del "$uname" 2>/dev/null
            [[ "$proto" == "ssh" ]] && userdel -rf "$uname" 2>/dev/null
            rm -f "$f" "$PUBLIC_HTML/${fn}.txt"
            ((count++))
        fi
    done
    shopt -u nullglob
    if [[ $count -gt 0 ]]; then
        fix_xray_perm
        systemctl restart xray 2>/dev/null
        echo -e "${G}|${NC}  ${G}✓ ${count} akun dihapus.${NC}"
    else
        echo -e "${G}|${NC}  ${G}✓ Tidak ada akun expired.${NC}"
    fi
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  SYSTEM INFO & RUNNING STATUS
# ═══════════════════════════════════════════════════════════════

show_running(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               STATUS LAYANAN RUNNING                    |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"

    local svcs=("xray:Xray Core" "nginx:Nginx" "sshd:OpenSSH" "dropbear:Dropbear" "haproxy:HAProxy" "udp-custom:UDP Custom" "vpn-keepalive:VPN Keepalive" "vpn-bot:Telegram Bot" "fail2ban:Fail2Ban")
    for item in "${svcs[@]}"; do
        local svc="${item%%:*}"
        local lbl="${item##*:}"
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo -e "${G}|${NC}  ${G}●${NC} ${W}${lbl}${NC}  ${G}[RUNNING]${NC}"
        else
            echo -e "${G}|${NC}  ${R}○${NC} ${W}${lbl}${NC}  ${R}[STOPPED]${NC}"
        fi
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

show_ports(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   INFO PORT SERVER                      |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── SSH ──${NC}"
    echo -e "${G}|${NC}  ${C}OpenSSH${NC}         : ${W}22${NC}"
    echo -e "${G}|${NC}  ${C}Dropbear${NC}        : ${W}222${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── VMESS ──${NC}"
    echo -e "${G}|${NC}  ${C}TLS (443)${NC}       : ${W}8443  ← via HAProxy${NC}"
    echo -e "${G}|${NC}  ${C}NonTLS (80)${NC}     : ${W}8880  ← via Nginx /vmess${NC}"
    echo -e "${G}|${NC}  ${C}gRPC TLS${NC}        : ${W}8444${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── VLESS ──${NC}"
    echo -e "${G}|${NC}  ${C}TLS (443)${NC}       : ${W}8445  ← via HAProxy${NC}"
    echo -e "${G}|${NC}  ${C}NonTLS (80)${NC}     : ${W}8881  ← via Nginx /vless${NC}"
    echo -e "${G}|${NC}  ${C}gRPC TLS${NC}        : ${W}8446${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── TROJAN ──${NC}"
    echo -e "${G}|${NC}  ${C}TLS (443)${NC}       : ${W}8447  ← via HAProxy${NC}"
    echo -e "${G}|${NC}  ${C}NonTLS (80)${NC}     : ${W}8882  ← via Nginx /trojan${NC}"
    echo -e "${G}|${NC}  ${C}gRPC TLS${NC}        : ${W}8448${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── WEB & UDP ──${NC}"
    echo -e "${G}|${NC}  ${C}HAProxy TLS${NC}     : ${W}443${NC}"
    echo -e "${G}|${NC}  ${C}Nginx HTTP${NC}      : ${W}80${NC}"
    echo -e "${G}|${NC}  ${C}Download${NC}        : ${W}81${NC}"
    echo -e "${G}|${NC}  ${C}BadVPN UDP${NC}      : ${W}7100-7300${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  SETTINGS MENU
# ═══════════════════════════════════════════════════════════════

settings_menu(){
    while true; do
        clear
        echo ""
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|                     SETTINGS                            |${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|${NC}  ${G}[1]${NC} Ganti Tema Menu"
        echo -e "${G}|${NC}  ${G}[2]${NC} Ganti Nama Banner"
        echo -e "${G}|${NC}  ${G}[3]${NC} Ganti Domain"
        echo -e "${G}|${NC}  ${G}[4]${NC} Fix SSL Certificate"
        echo -e "${G}|${NC}  ${G}[5]${NC} Fix All Services"
        echo -e "${G}|${NC}  ${G}[6]${NC} Optimasi VPS"
        echo -e "${G}|${NC}  ${G}[7]${NC} Telegram Bot"
        echo -e "${G}|${NC}  ${G}[8]${NC} Backup Sistem"
        echo -e "${G}|${NC}  ${G}[9]${NC} Restore Sistem"
        echo -e "${G}|${NC}  ${G}[0]${NC} Kembali"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo ""
        echo -ne "  ${Y}Pilihan: ${NC}"
        read -r ch
        case "$ch" in
            1) select_theme ;;
            2) set_banner_name ;;
            3) setup_domain; make_haproxy_config; make_nginx_config ;;
            4) fix_ssl ;;
            5) fix_all_svc ;;
            6) optimize_vps ;;
            7) bot_menu ;;
            8) backup_sys ;;
            9) restore_sys ;;
            0) return ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
#  AUTO REBOOT MENU
# ═══════════════════════════════════════════════════════════════

auto_reboot_menu(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   AUTO REBOOT                           |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local cur=$(crontab -l 2>/dev/null | grep "reboot" | head -1)
    echo -e "${G}|${NC}  ${D}Jadwal saat ini: ${Y}${cur:-Belum diset}${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${G}[1]${NC} Reboot setiap jam 00:00"
    echo -e "${G}|${NC}  ${G}[2]${NC} Reboot setiap jam 12:00 & 00:00"
    echo -e "${G}|${NC}  ${G}[3]${NC} Reboot custom waktu"
    echo -e "${G}|${NC}  ${G}[4]${NC} Hapus auto reboot"
    echo -e "${G}|${NC}  ${G}[0]${NC} Kembali"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${Y}Pilihan: ${NC}"
    read -r ch
    case "$ch" in
        1) (crontab -l 2>/dev/null | grep -v reboot; echo "0 0 * * * /sbin/reboot") | crontab -; ok "Auto reboot 00:00 diset!"; sleep 2 ;;
        2) (crontab -l 2>/dev/null | grep -v reboot; echo "0 0,12 * * * /sbin/reboot") | crontab -; ok "Auto reboot 00:00 & 12:00 diset!"; sleep 2 ;;
        3) echo -ne "\n  ${Y}Jam (0-23): ${NC}"; read -r hr; echo -ne "  ${Y}Menit (0-59): ${NC}"; read -r mn
           [[ "$hr" =~ ^[0-9]+$ && "$mn" =~ ^[0-9]+$ ]] && \
               (crontab -l 2>/dev/null | grep -v reboot; echo "$mn $hr * * * /sbin/reboot") | crontab - && \
               ok "Auto reboot ${hr}:${mn} diset!" || warn "Input tidak valid!"
           sleep 2 ;;
        4) (crontab -l 2>/dev/null | grep -v reboot) | crontab -; ok "Auto reboot dihapus!"; sleep 2 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  RESTART / FIX / OPTIMIZE
# ═══════════════════════════════════════════════════════════════

restart_all(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              RESTART SEMUA SERVICE                      |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    systemctl daemon-reload 2>/dev/null
    for s in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive vpn-bot; do
        if systemctl restart "$s" 2>/dev/null; then
            echo -e "${G}|${NC}  ${G}✓${NC} ${s} restarted"
        else
            echo -e "${G}|${NC}  ${R}✗${NC} ${s} failed"
        fi
    done
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    sleep 2
}

fix_ssl(){
    load_domain
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              FIX / PERBARUI SSL CERT                    |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    [[ -z "$DOMAIN" ]] && { echo -e "${G}|${NC}  ${R}Domain belum dikonfigurasi!${NC}"; echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"; sleep 3; return; }
    echo -e "${G}|${NC}  ${C}Domain${NC} : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}"; echo ""
    info "Memperbarui SSL..."
    local stype=$(get_ssl)
    systemctl restart xray nginx haproxy 2>/dev/null
    echo ""
    echo -e "  ${G}✓ SSL diperbarui: ${stype}${NC}"
    sleep 2
}

fix_all_svc(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              FIX ALL SERVICES                           |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local svcs=("xray:Xray Core" "nginx:Nginx" "sshd:OpenSSH" "dropbear:Dropbear" "haproxy:HAProxy")
    for item in "${svcs[@]}"; do
        local s="${item%%:*}" l="${item##*:}"
        if ! systemctl list-unit-files --quiet "${s}.service" 2>/dev/null | grep -q "$s"; then
            echo -e "${G}|${NC}  ${D}[~]${NC} ${l}  ${D}SKIP (tidak terinstall)${NC}"; continue
        fi
        if systemctl is-active --quiet "$s" 2>/dev/null; then
            echo -e "${G}|${NC}  ${G}[✓]${NC} ${l}  ${G}RUNNING${NC}"
        else
            systemctl restart "$s" 2>/dev/null; sleep 1
            if systemctl is-active --quiet "$s" 2>/dev/null; then
                echo -e "${G}|${NC}  ${Y}[↺]${NC} ${l}  ${Y}FIXED (restarted)${NC}"
            else
                echo -e "${G}|${NC}  ${R}[✗]${NC} ${l}  ${R}FAIL${NC}"
            fi
        fi
    done

    # Check xray config
    if [[ ! -f "$XRAY_CONFIG" ]] || ! jq . "$XRAY_CONFIG" >/dev/null 2>&1; then
        echo -e "${G}|${NC}  ${Y}[↺]${NC} Xray config rusak/tidak ada → membuat ulang"
        make_xray_config; systemctl restart xray 2>/dev/null
    else
        echo -e "${G}|${NC}  ${G}[✓]${NC} Xray config JSON valid"
        fix_xray_perm
    fi

    # Check SSL
    if [[ ! -f /etc/xray/xray.crt ]]; then
        echo -e "${G}|${NC}  ${Y}[↺]${NC} SSL tidak ada → regenerate self-signed"
        mkdir -p /etc/xray
        openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
            -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
            -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
        systemctl restart xray 2>/dev/null
    else
        local expd=$(openssl x509 -enddate -noout -in /etc/xray/xray.crt 2>/dev/null | cut -d= -f2)
        echo -e "${G}|${NC}  ${G}[✓]${NC} SSL cert valid (exp: ${expd})"
    fi

    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""; read -rp "  Tekan Enter..."
}

optimize_vps(){
    clear
    echo ""
    info "Menerapkan optimasi VPS (BBR, swap, limits)..."
    cat > /etc/sysctl.d/99-vpn.conf << 'EOF'
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
EOF
    cat > /etc/security/limits.d/99-vpn.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
    modprobe tcp_bbr 2>/dev/null; echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    sysctl -p /etc/sysctl.d/99-vpn.conf >/dev/null 2>&1
    ok "BBR + TCP optimization diterapkan"
    ok "File descriptor limit 65535"

    local swap=$(free -m | awk 'NR==3{print $2}')
    if [[ $swap -lt 512 ]]; then
        info "Membuat swapfile 2GB..."
        fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null
        chmod 600 /swapfile; mkswap /swapfile >/dev/null 2>&1; swapon /swapfile
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
        ok "Swapfile 2GB dibuat"
    else
        info "Swapfile sudah ada: ${swap}MB"
    fi
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  BANDWIDTH MONITOR
# ═══════════════════════════════════════════════════════════════

bandwidth_monitor(){
    clear
    if command -v vnstat >/dev/null 2>&1; then
        vnstat 2>/dev/null
    else
        warn "vnStat belum terinstall."
        echo -ne "  Install? [y/N]: "; read -r c
        if [[ "$c" == "y" ]]; then
            apt-get install -y vnstat >/dev/null 2>&1
            systemctl enable vnstat 2>/dev/null; systemctl start vnstat 2>/dev/null
            ok "vnStat terinstall!"
        fi
    fi
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  SPEEDTEST
# ═══════════════════════════════════════════════════════════════

speedtest_run(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                     SPEEDTEST                           |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    if ! command -v speedtest >/dev/null 2>&1; then
        info "Menginstall Speedtest CLI..."
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
    fi
    echo ""
    command -v speedtest >/dev/null 2>&1 && \
        speedtest --accept-license --accept-gdpr || \
        warn "Speedtest tidak tersedia."
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  CERT SSL MENU
# ═══════════════════════════════════════════════════════════════

cert_ssl_menu(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                    CERT SSL                             |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    local cert_exp="N/A"
    if [[ -f /etc/xray/xray.crt ]]; then
        cert_exp=$(openssl x509 -enddate -noout -in /etc/xray/xray.crt 2>/dev/null | cut -d= -f2)
    fi
    echo -e "${G}|${NC}  ${C}Domain${NC}     : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}  ${C}Cert Exp${NC}   : ${W}${cert_exp}${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${G}[1]${NC} Perbarui Let's Encrypt"
    echo -e "${G}|${NC}  ${G}[2]${NC} Buat Self-Signed baru"
    echo -e "${G}|${NC}  ${G}[0]${NC} Kembali"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${Y}Pilihan: ${NC}"
    read -r ch
    case "$ch" in
        1)
            systemctl stop haproxy nginx 2>/dev/null
            certbot certonly --standalone -d "$DOMAIN" \
                --non-interactive --agree-tos --register-unsafely-without-email
            if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
                cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
                cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
                ok "Let's Encrypt cert berhasil!"
            else
                warn "Let's Encrypt gagal. Coba self-signed."
            fi
            systemctl start nginx haproxy xray 2>/dev/null
            sleep 2
            ;;
        2)
            openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
                -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
                -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
            systemctl restart xray 2>/dev/null
            ok "Self-signed cert berhasil!"; sleep 2
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  CLEAR LOG & CACHE
# ═══════════════════════════════════════════════════════════════

clear_log(){
    > /var/log/xray/access.log 2>/dev/null
    > /var/log/xray/error.log 2>/dev/null
    > /var/log/nginx/access.log 2>/dev/null
    > /var/log/nginx/error.log 2>/dev/null
    journalctl --rotate >/dev/null 2>&1
    journalctl --vacuum-time=1s >/dev/null 2>&1
    ok "Log berhasil dibersihkan!"
    sleep 2
}

clear_cache(){
    sync; echo 3 > /proc/sys/vm/drop_caches
    apt-get autoclean -y >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    ok "Cache berhasil dibersihkan!"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  LIMIT SPEED
# ═══════════════════════════════════════════════════════════════

limitspeed_menu(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   LIMIT SPEED                           |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}  ${G}[1]${NC} Set limit per user (tc/iptables)"
    echo -e "${G}|${NC}  ${G}[2]${NC} Hapus semua limit"
    echo -e "${G}|${NC}  ${G}[0]${NC} Kembali"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${Y}Pilihan: ${NC}"
    read -r ch
    case "$ch" in
        1)
            echo -ne "\n  ${Y}Username: ${NC}"; read -r uname
            echo -ne "  ${Y}Limit kbps (contoh: 1024): ${NC}"; read -r kbps
            if command -v tc >/dev/null 2>&1 && [[ "$kbps" =~ ^[0-9]+$ ]]; then
                local uid=$(id -u "$uname" 2>/dev/null)
                [[ -z "$uid" ]] && { warn "User tidak ditemukan!"; sleep 2; return; }
                iptables -A OUTPUT -m owner --uid-owner "$uid" -j ACCEPT 2>/dev/null
                ok "Limit ${kbps}kbps diterapkan untuk ${uname}"
            else
                warn "tc tidak tersedia atau input tidak valid!"
            fi
            sleep 2
            ;;
        2)
            tc qdisc del dev eth0 root 2>/dev/null
            ok "Semua limit dihapus!"; sleep 2
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  TELEGRAM BOT
# ═══════════════════════════════════════════════════════════════

bot_menu(){
    while true; do
        clear
        echo ""
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo -e "${G}|                  TELEGRAM BOT                           |${NC}"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        local bot_s="$(chk vpn-bot)"
        local bot_c="${G}RUNNING${NC}"; [[ "$bot_s" == "OFF" ]] && bot_c="${R}STOPPED${NC}"
        echo -e "${G}|${NC}  Status Bot: ${bot_c}"
        echo -e "${G}|${NC}"
        echo -e "${G}|${NC}  ${G}[1]${NC} Setup Bot (Token & ChatID)"
        echo -e "${G}|${NC}  ${G}[2]${NC} Start Bot"
        echo -e "${G}|${NC}  ${G}[3]${NC} Stop Bot"
        echo -e "${G}|${NC}  ${G}[4]${NC} Restart Bot"
        echo -e "${G}|${NC}  ${G}[5]${NC} Lihat Log"
        echo -e "${G}|${NC}  ${G}[6]${NC} Test Kirim Pesan"
        echo -e "${G}|${NC}  ${G}[0]${NC} Kembali"
        echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
        echo ""
        echo -ne "  ${Y}Pilihan: ${NC}"
        read -r ch
        case "$ch" in
            1) bot_setup ;;
            2) systemctl start   vpn-bot 2>/dev/null; ok "Bot started!"; sleep 1 ;;
            3) systemctl stop    vpn-bot 2>/dev/null; warn "Bot stopped!"; sleep 1 ;;
            4) systemctl restart vpn-bot 2>/dev/null; ok "Bot restarted!"; sleep 1 ;;
            5) clear; journalctl -u vpn-bot -n 50 --no-pager 2>/dev/null || echo "No logs"; echo ""; read -rp "  Enter..." ;;
            6) [[ -f "$BOT_TOKEN_FILE" && -f "$CHAT_ID_FILE" ]] && \
               tg "🔔 Test pesan dari $(get_banner_name) v${VER}" && ok "Terkirim!" || warn "Bot belum dikonfigurasi!"
               sleep 2 ;;
            0) return ;;
        esac
    done
}

bot_setup(){
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|               SETUP TELEGRAM BOT                        |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}  1. Buka Telegram → cari @BotFather"
    echo -e "${G}|${NC}  2. Ketik /newbot → ikuti instruksi"
    echo -e "${G}|${NC}  3. Copy TOKEN yang diberikan"
    echo -e "${G}|${NC}  4. Cari @userinfobot → /start → copy ID"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -ne "  ${Y}Bot Token: ${NC}"; read -r btoken
    [[ -z "$btoken" ]] && { warn "Token wajib diisi!"; sleep 2; return; }
    echo -ne "  ${Y}Verifikasi token...${NC}"
    local res=$(curl -s --max-time 8 "https://api.telegram.org/bot${btoken}/getMe")
    if ! echo "$res" | grep -q '"ok":true'; then
        echo -e " ${R}✗ Token tidak valid!${NC}"; sleep 2; return
    fi
    local bname=$(echo "$res" | grep -oP '"username":"\K[^"]+')
    echo -e " ${G}✓ Bot: @${bname}${NC}"
    echo ""
    echo -ne "  ${Y}Admin Chat ID: ${NC}"; read -r chatid
    [[ -z "$chatid" ]] && { warn "Chat ID wajib!"; sleep 2; return; }
    echo -ne "  ${Y}Nama Rekening: ${NC}"; read -r rname
    echo -ne "  ${Y}No Rekening: ${NC}"; read -r rnum
    echo -ne "  ${Y}Bank/E-Wallet: ${NC}"; read -r rbank
    echo -ne "  ${Y}Harga/bulan (Rp): ${NC}"; read -r harga
    [[ ! "$harga" =~ ^[0-9]+$ ]] && harga=15000

    echo "$btoken" > "$BOT_TOKEN_FILE"; echo "$chatid" > "$CHAT_ID_FILE"
    chmod 600 "$BOT_TOKEN_FILE" "$CHAT_ID_FILE"
    cat > "$PAYMENT_FILE" << EOF
REK_NAME=${rname}
REK_NUMBER=${rnum}
REK_BANK=${rbank}
HARGA=${harga}
EOF
    chmod 600 "$PAYMENT_FILE"
    _install_bot_svc
    ok "Bot berhasil dikonfigurasi!"; sleep 2
}

_install_bot_svc(){
    mkdir -p /root/bot
    pip3 install requests --break-system-packages >/dev/null 2>&1
    local banner=$(get_banner_name)

    cat > /root/bot/bot.py << BEOF
#!/usr/bin/env python3
import os, time, subprocess
try: import requests
except: os.system('pip3 install requests --break-system-packages -q'); import requests

TOKEN  = open('/root/.bot_token').read().strip()
ADMIN  = int(open('/root/.chat_id').read().strip())
DOMAIN = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
BANNER = open('/root/.banner_name').read().strip() if os.path.exists('/root/.banner_name') else '$(get_banner_name)'
API    = f'https://api.telegram.org/bot{TOKEN}'

PAY = {}
if os.path.exists('/root/.payment_info'):
    for line in open('/root/.payment_info'):
        if '=' in line:
            k,v = line.strip().split('=',1); PAY[k] = v

def send(cid, text, kbd=None):
    d = {'chat_id': cid, 'text': text, 'parse_mode': 'HTML'}
    if kbd: d['reply_markup'] = {'inline_keyboard': kbd}
    try: requests.post(f'{API}/sendMessage', json=d, timeout=8)
    except: pass

def get_upd(offset=0):
    try:
        r = requests.get(f'{API}/getUpdates', params={'offset':offset,'timeout':15}, timeout=20)
        return r.json().get('result', [])
    except: return []

def list_accounts(proto):
    d = '/root/akun'
    if not os.path.exists(d): return f'Tidak ada akun {proto.upper()}'
    files = [f for f in os.listdir(d) if f.startswith(f'{proto}-') and f.endswith('.txt')]
    if not files: return f'Tidak ada akun {proto.upper()}'
    out = f'<b>Daftar {proto.upper()}:</b>\n'
    for fn in sorted(files):
        un = fn.replace(f'{proto}-','').replace('.txt','')
        data = {}
        for line in open(os.path.join(d,fn)):
            if '=' in line: k,v = line.strip().split('=',1); data[k]=v
        out += f'• <code>{un}</code> | exp: {data.get("EXPIRED","?")}\n'
    return out

def on_msg(msg):
    cid  = msg['chat']['id']
    text = msg.get('text','').strip()
    name = msg['from'].get('first_name','User')

    if text == '/start':
        send(cid, f'👋 Halo <b>{name}</b>!\n\n🤖 <b>{BANNER}</b>\n🌐 Server: <code>{DOMAIN}</code>\n\n/list - Daftar akun\n/status - Status server\n/pay - Info pembayaran\n/help - Bantuan')
    elif text == '/status':
        svcs = ['xray','nginx','haproxy','sshd','dropbear']
        lines = []
        for s in svcs:
            ret = subprocess.run(['systemctl','is-active',s], capture_output=True, text=True)
            st = '🟢' if ret.returncode==0 else '🔴'
            lines.append(f'{st} {s}')
        send(cid, '<b>Status Server:</b>\n' + '\n'.join(lines))
    elif text == '/pay':
        send(cid, f'💳 <b>Info Pembayaran:</b>\n\n🏦 Bank: {PAY.get("REK_BANK","?")}\n👤 Nama: {PAY.get("REK_NAME","?")}\n🔢 No: <code>{PAY.get("REK_NUMBER","?")}</code>\n💰 Harga: Rp {PAY.get("HARGA","?")}')
    elif text == '/list':
        send(cid, list_accounts('ssh') + '\n\n' + list_accounts('vmess') + '\n\n' + list_accounts('vless'))
    elif text == '/help':
        send(cid, '/list - Daftar akun\n/status - Status service\n/pay - Info rekening\n/order - Cara order')
    elif text == '/order':
        send(cid, f'🛒 <b>Cara Order:</b>\n\n1. Pilih paket\n2. Transfer ke /pay\n3. Kirim bukti + username ke admin\n4. Akun dibuat dalam 5 menit')
    else:
        if cid != ADMIN:
            send(cid, '⚠️ Hubungi admin untuk bantuan.')

def main():
    print(f'Bot aktif | {BANNER} | {DOMAIN}', flush=True)
    offset = 0
    while True:
        try:
            for upd in get_upd(offset):
                offset = upd['update_id'] + 1
                if 'message' in upd: on_msg(upd['message'])
        except KeyboardInterrupt: break
        except: time.sleep(3)

if __name__ == '__main__': main()
BEOF

    cat > /etc/systemd/system/vpn-bot.service << 'SEOF'
[Unit]
Description=VPN Telegram Bot
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/bot/bot.py
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SEOF
    systemctl daemon-reload
    systemctl enable vpn-bot 2>/dev/null
    systemctl restart vpn-bot 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════
#  BACKUP & RESTORE
# ═══════════════════════════════════════════════════════════════

backup_sys(){
    clear
    local bdir="/root/backups"
    local bfile="sakti-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$bdir"
    info "Membuat backup..."
    tar -czf "$bdir/$bfile" \
        /root/domain /root/.domain_type /root/akun \
        /root/.bot_token /root/.chat_id /root/.payment_info \
        /root/.menu_theme /root/.banner_name /root/.install_date /root/.script_exp \
        /etc/xray/ /usr/local/etc/xray/config.json \
        2>/dev/null
    if [[ -f "$bdir/$bfile" ]]; then
        ok "Backup: $bdir/$bfile ($(du -h "$bdir/$bfile" | awk '{print $1}'))"
    else
        warn "Backup gagal!"
    fi
    echo ""; read -rp "  Tekan Enter..."
}

restore_sys(){
    clear
    local bdir="/root/backups"
    shopt -s nullglob
    local bkps=($(ls -t "$bdir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob
    if [[ ${#bkps[@]} -eq 0 ]]; then
        warn "Tidak ada backup!"; sleep 2; return
    fi
    local i=1
    for f in "${bkps[@]}"; do
        echo -e "  ${G}[${i}]${NC} $(basename "$f")"
        ((i++))
    done
    echo ""
    echo -ne "  ${Y}Pilih nomor (0=batal): ${NC}"; read -r ch
    [[ "$ch" == "0" || ! "$ch" =~ ^[0-9]+$ ]] && return
    [[ $ch -lt 1 || $ch -gt ${#bkps[@]} ]] && return
    local sel="${bkps[$((ch-1))]}"
    echo -ne "\n  ${Y}Yakin restore ${W}$(basename "$sel")${Y}? [y/N]: ${NC}"; read -r conf
    [[ "$conf" != "y" ]] && return
    info "Merestore..."
    tar -xzf "$sel" -C / 2>/dev/null && {
        ok "Restore berhasil!"; systemctl restart xray nginx haproxy 2>/dev/null
    } || warn "Restore gagal!"
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  KEEPALIVE & UDP
# ═══════════════════════════════════════════════════════════════

setup_keepalive(){
    local cfg="/etc/ssh/sshd_config"
    grep -q "^ClientAliveInterval" "$cfg" && \
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 30/' "$cfg" || \
        echo "ClientAliveInterval 30" >> "$cfg"
    grep -q "^ClientAliveCountMax" "$cfg" && \
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' "$cfg" || \
        echo "ClientAliveCountMax 6" >> "$cfg"
    systemctl restart sshd 2>/dev/null

    cat > /usr/local/bin/vpn-keepalive.sh << 'EOF'
#!/bin/bash
while true; do
    GW=$(ip route | awk '/default/{print $3;exit}')
    [[ -n "$GW" ]] && ping -c1 -W2 "$GW" >/dev/null 2>&1
    sleep 25
done
EOF
    chmod +x /usr/local/bin/vpn-keepalive.sh
    cat > /etc/systemd/system/vpn-keepalive.service << 'EOF'
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
EOF
    systemctl daemon-reload; systemctl enable vpn-keepalive 2>/dev/null; systemctl restart vpn-keepalive 2>/dev/null
}

setup_udp(){
    cat > /usr/local/bin/udp-custom << 'EOF'
#!/usr/bin/env python3
import socket, threading, select, time
PORTS = range(7100, 7301)
SSH_HOST = '127.0.0.1'
SSH_PORT = 22
BUF = 8192

def handle(data, addr, sock):
    try:
        s = socket.socket(); s.settimeout(10); s.connect((SSH_HOST, SSH_PORT))
        s.sendall(data); resp = s.recv(BUF)
        if resp: sock.sendto(resp, addr)
        s.close()
    except: pass

sockets = []
for p in PORTS:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', p)); s.setblocking(False); sockets.append(s)
    except: pass

print(f'UDP Custom: {len(sockets)} ports aktif', flush=True)
while True:
    try:
        r, _, _ = select.select(sockets, [], [], 1.0)
        for sock in r:
            try:
                d, a = sock.recvfrom(BUF)
                threading.Thread(target=handle, args=(d,a,sock), daemon=True).start()
            except: pass
    except KeyboardInterrupt: break
    except: time.sleep(1)
EOF
    chmod +x /usr/local/bin/udp-custom
    cat > /etc/systemd/system/udp-custom.service << 'EOF'
[Unit]
Description=UDP Custom BadVPN
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/udp-custom
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable udp-custom 2>/dev/null; systemctl restart udp-custom 2>/dev/null
}

setup_menu_cmd(){
    cat > /usr/local/bin/menu << 'EOF'
#!/bin/bash
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh || echo "Script tidak ditemukan!"
EOF
    chmod +x /usr/local/bin/menu
    grep -q "tunnel.sh" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'EOF'

clear
echo -e "\033[1;33m  Ketik 'menu' untuk membuka VPN Manager\033[0m"
EOF
}

# ═══════════════════════════════════════════════════════════════
#  SMART INSTALLER
# ═══════════════════════════════════════════════════════════════

smart_install(){
    clear
    echo ""
    echo -e "${CB}  ██████╗  █████╗ ██╗  ██╗████████╗██╗${NC}"
    echo -e "${C}  ██╔════╝██╔══██╗██║ ██╔╝╚══██╔══╝██║${NC}"
    echo -e "${G}  ███████╗███████║█████╔╝    ██║   ██║${NC}"
    echo -e "${Y}  ╚════██║██╔══██║██╔═██╗    ██║   ██║${NC}"
    echo -e "${R}  ███████║██║  ██║██║  ██╗   ██║   ██║${NC}"
    echo -e "${M}  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═╝   ╚═╝${NC}"
    echo ""
    echo -e "${D}  ══════════════════════════════════════════${NC}"
    echo -e "  ${W}SAKTI TUNNELING${NC} ${Y}v${VER}${NC}   ${D}Auto Installer${NC}"
    echo -e "${D}  ══════════════════════════════════════════${NC}"
    echo ""
    echo -ne "  ${C}Tekan Enter untuk mulai...${NC}"; read -r

    # Set expiry 87 days from now
    date +"%Y-%m-%d" > "$INSTALL_DATE_FILE"
    date -d "+87 days" +"%Y-%m-%d" > "$SCRIPT_EXP_FILE"

    setup_domain
    [[ -z "$DOMAIN" ]] && die "Domain tidak dikonfigurasi!"

    echo -ne "\n  ${Y}Nama Banner (default: SAKTI TUNNELING): ${NC}"; read -r bname
    [[ -n "$bname" ]] && echo "$bname" > "$BANNER_FILE" || echo "SAKTI TUNNELING" > "$BANNER_FILE"

    select_theme

    local dtype=$(cat "$DOMAIN_TYPE_FILE" 2>/dev/null || echo "random")
    local ip=$(get_ip)
    local ssl_label="Self-Signed"
    [[ "$dtype" == "custom" ]] && ssl_label="Let's Encrypt"

    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|                   KONFIGURASI INSTALL                   |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}  ${C}Domain${NC}   : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}  ${C}SSL${NC}      : ${W}${ssl_label}${NC}"
    echo -e "${G}|${NC}  ${C}IP VPS${NC}   : ${W}${ip}${NC}"
    echo -e "${G}|${NC}  ${C}Banner${NC}   : ${W}$(get_banner_name)${NC}"
    echo -e "${G}|${NC}  ${C}Exp Script${NC}: ${Y}$(get_script_exp) (87 hari)${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    sleep 2

    local LOG="/tmp/sakti_install_$(date +%s).log"
    > "$LOG"

    _step(){ echo -e "\n${CB}[STEP $1/9]${NC} ${W}$2${NC}"; echo -e "${D}$(printf '%0.s─' $(seq 1 54))${NC}"; }
    _do(){ printf "  ${C}→${NC} %-40s" "$1"; }
    _ok(){ printf "${G}OK${NC}\n"; }
    _skip(){ printf "${D}SKIP${NC}\n"; }
    _fail(){ printf "${R}FAIL${NC}\n"; }

    _step 1 "SYSTEM UPDATE & BASE PACKAGES"
    _do "Update package list"
    apt-get update -y >> "$LOG" 2>&1 && _ok || _fail
    _do "Install base packages"
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl wget unzip uuid-runtime net-tools openssl jq \
        python3 python3-pip gnupg2 ca-certificates lsb-release \
        apt-transport-https software-properties-common qrencode \
        >> "$LOG" 2>&1 && _ok || _fail

    _step 2 "INSTALL VPN SERVICES"
    if command -v xray >/dev/null 2>&1; then
        _do "Xray-core"; _skip
    else
        _do "Xray-core"
        bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) >> "$LOG" 2>&1 && _ok || _fail
    fi
    _do "Nginx"; apt-get install -y nginx >> "$LOG" 2>&1 && _ok || _fail
    _do "OpenSSH"; apt-get install -y openssh-server >> "$LOG" 2>&1 && _ok || _fail
    _do "Dropbear"; apt-get install -y dropbear >> "$LOG" 2>&1 && _ok || _fail
    _do "HAProxy"; apt-get install -y haproxy >> "$LOG" 2>&1 && _ok || _fail
    _do "Certbot"; apt-get install -y certbot >> "$LOG" 2>&1 && _ok || _fail

    _step 3 "SECURITY TOOLS"
    _do "Fail2Ban"; apt-get install -y fail2ban >> "$LOG" 2>&1 && _ok || _fail
    systemctl enable fail2ban >> "$LOG" 2>&1; systemctl start fail2ban >> "$LOG" 2>&1
    _do "UFW Firewall"; apt-get install -y ufw >> "$LOG" 2>&1 && _ok || _fail
    ufw --force reset >> "$LOG" 2>&1
    ufw default deny incoming >> "$LOG" 2>&1; ufw default allow outgoing >> "$LOG" 2>&1
    for p in 22 80 81 222 443 8443 8444 8445 8446 8447 8448 8880 8881 8882; do
        ufw allow "$p/tcp" >> "$LOG" 2>&1
    done
    ufw allow 7100:7300/tcp >> "$LOG" 2>&1; ufw allow 7100:7300/udp >> "$LOG" 2>&1
    ufw --force enable >> "$LOG" 2>&1
    _do "vnStat"; apt-get install -y vnstat >> "$LOG" 2>&1 && _ok || _fail
    systemctl enable vnstat >> "$LOG" 2>&1; systemctl start vnstat >> "$LOG" 2>&1

    _step 4 "SYSTEM OPTIMIZATION"
    modprobe tcp_bbr 2>/dev/null; echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    cat > /etc/sysctl.d/99-vpn.conf << 'EOF'
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_fin_timeout = 10
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
vm.swappiness = 10
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
    sysctl -p /etc/sysctl.d/99-vpn.conf >> "$LOG" 2>&1
    cat > /etc/security/limits.d/99-vpn.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
    _do "BBR + TCP optimization"; _ok
    _do "File limit 65535"; _ok
    local swap=$(free -m | awk 'NR==3{print $2}')
    if [[ $swap -lt 512 ]]; then
        _do "Swapfile 2GB"
        fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 >> "$LOG" 2>&1
        chmod 600 /swapfile; mkswap /swapfile >> "$LOG" 2>&1; swapon /swapfile
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab; _ok
    else
        _do "Swapfile"; _skip
    fi

    _step 5 "SSL CERTIFICATE"
    mkdir -p /etc/xray
    _do "SSL Certificate"
    local stype=$(get_ssl); echo -e "${G}${stype}${NC}"

    _step 6 "XRAY CONFIG (TLS 443 + NonTLS 80)"
    _do "Xray config"; make_xray_config && _ok || _fail

    _step 7 "WEB SERVER CONFIG"
    _do "Nginx (80 NonTLS proxy + 81 download)"; make_nginx_config && _ok || _fail
    _do "Dropbear port 222"
    cat > /etc/default/dropbear << 'EOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
    _ok
    _do "HAProxy (443 → 8443 Xray TLS)"; make_haproxy_config && _ok || _fail

    _step 8 "ADDITIONAL SERVICES"
    _do "UDP Custom (7100-7300)"; setup_udp && _ok || _fail
    _do "VPN Keepalive"; setup_keepalive && _ok || _fail
    _do "Menu command"; setup_menu_cmd && _ok

    _step 9 "WEB INTERFACE & START SERVICES"
    mkdir -p "$PUBLIC_HTML" "$AKUN_DIR"
    cat > "$PUBLIC_HTML/index.html" << HTMLEOF
<!DOCTYPE html><html><head>
<meta charset="UTF-8"><title>$(get_banner_name)</title>
<style>*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;background:#0a0a0a;color:#00ff88;
     display:flex;align-items:center;justify-content:center;min-height:100vh}
.c{border:1px solid #00ff88;padding:40px;max-width:480px;width:100%;
   box-shadow:0 0 20px rgba(0,255,136,.3)}
h1{color:#00d4ff;font-size:1.8em;letter-spacing:4px;margin-bottom:20px}
p{margin:8px 0;opacity:.8}
.b{border:1px solid #00ff88;padding:8px 16px;display:inline-block;margin-top:20px}
</style></head><body><div class="c">
<h1>$(get_banner_name)</h1>
<p>Domain : ${DOMAIN}</p>
<p>IP     : ${ip}</p>
<p>Ver    : ${VER}</p>
<div class="b">● ONLINE</div>
</div></body></html>
HTMLEOF

    systemctl daemon-reload >> "$LOG" 2>&1
    for s in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
        systemctl enable  "$s" >> "$LOG" 2>&1
        systemctl restart "$s" >> "$LOG" 2>&1
        if systemctl is-active --quiet "$s" 2>/dev/null; then
            printf "  ${G}✓${NC} %-20s ${G}RUNNING${NC}\n" "$s"
        else
            printf "  ${R}✗${NC} %-20s ${R}FAILED${NC}\n" "$s"
        fi
    done

    # Done!
    clear
    echo ""
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|              ✓ INSTALASI SELESAI!                       |${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${C}Domain${NC}        : ${W}${DOMAIN}${NC}"
    echo -e "${G}|${NC}  ${C}IP VPS${NC}        : ${W}${ip}${NC}"
    echo -e "${G}|${NC}  ${C}SSL${NC}           : ${W}${ssl_label}${NC}"
    echo -e "${G}|${NC}  ${C}Exp Script${NC}    : ${Y}$(get_script_exp) (87 hari)${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}── Port Info ──${NC}"
    echo -e "${G}|${NC}  ${C}SSH${NC}           : ${W}22 / Dropbear: 222${NC}"
    echo -e "${G}|${NC}  ${C}TLS (443)${NC}     : ${W}VMess 8443, VLess 8445, Trojan 8447${NC}"
    echo -e "${G}|${NC}  ${C}NonTLS (80)${NC}   : ${W}VMess 8880, VLess 8881, Trojan 8882${NC}"
    echo -e "${G}|${NC}  ${C}gRPC TLS${NC}      : ${W}VMess 8444, VLess 8446, Trojan 8448${NC}"
    echo -e "${G}|${NC}  ${C}BadVPN UDP${NC}    : ${W}7100-7300${NC}"
    echo -e "${G}|${NC}  ${C}Web Panel${NC}     : ${W}http://${ip}:81/${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}|${NC}  ${Y}💡 Ketik 'menu' untuk membuka VPN Manager${NC}"
    echo -e "${G}|${NC}"
    echo -e "${G}+──────────────────────────────────────────────────────────+${NC}"
    echo ""
    echo -e "  ${Y}Reboot dalam 5 detik untuk menerapkan semua perubahan...${NC}"
    sleep 5
    reboot
}

# ═══════════════════════════════════════════════════════════════
#  MAIN LOOP
# ═══════════════════════════════════════════════════════════════

main(){
    check_root
    mkdir -p "$AKUN_DIR" /root/orders
    load_domain
    init_expiry

    # First install
    if [[ ! -f "$DOMAIN_FILE" ]]; then
        smart_install
        return
    fi

    setup_menu_cmd

    while true; do
        draw_main_menu
        read -r choice

        case "$choice" in
            01|1)  ssh_menu ;;
            02|2)  xray_menu "vmess" ;;
            03|3)  xray_menu "vless" ;;
            04|4)  xray_menu "trojan" ;;
            05|5)  limitspeed_menu ;;
            06|6)
                clear; echo ""
                echo -e "${G}[1]${NC} Trial SSH  ${G}[2]${NC} Trial VMess  ${G}[3]${NC} Trial VLess  ${G}[4]${NC} Trial Trojan"
                echo -ne "  ${Y}Pilihan: ${NC}"; read -r tc
                case "$tc" in
                    1) ssh_trial ;;
                    2) xray_trial "vmess" ;;
                    3) xray_trial "vless" ;;
                    4) xray_trial "trojan" ;;
                esac ;;
            07|7)  delete_expired ;;
            08|8)  bandwidth_monitor ;;
            09|9)  show_ports ;;
            10)    speedtest_run ;;
            11)    show_running ;;
            12)    clear_log ;;
            13)    settings_menu ;;
            14)    auto_reboot_menu ;;
            15)    restart_all ;;
            16)    setup_domain; make_nginx_config; make_haproxy_config ;;
            17)    cert_ssl_menu ;;
            18)    clear_cache ;;
            x|X|0) clear; echo -e "\n  ${C}Sampai jumpa!${NC}\n"; exit 0 ;;
            *)     ;;
        esac
    done
}

main "$@"
