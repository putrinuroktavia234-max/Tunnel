#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#   VPN AUTO SCRIPT v4.0 - FULL REWRITE
#   By The Proffessor Squad | @ridhani16
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
VER="4.0.0"
GITHUB_USER="putrinuroktavia234-max"
GITHUB_REPO="Tunnel"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/tunnel.sh"
VERSION_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/version"
SCRIPT_PATH="/root/tunnel.sh"
PUBLIC_HTML="/var/www/html"
BOT_TOKEN_FILE="/root/.bot_token"
CHAT_ID_FILE="/root/.chat_id"
PAYMENT_FILE="/root/.payment_info"
DOMAIN_TYPE_FILE="/root/.domain_type"
THEME_FILE="/root/.menu_theme"
W=68  # box width

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

gen_random_domain(){
    local ip=$(get_ip)
    echo "$(rand_str).${ip}.nip.io"
}

# ═══════════════════════════════════════════════════════════════
#  THEME ENGINE - 3 COMPLETELY DIFFERENT THEMES
# ═══════════════════════════════════════════════════════════════

get_theme(){ [[ -f "$THEME_FILE" ]] && cat "$THEME_FILE" || echo "neon"; }

# ─── THEME: NEON (Cyberpunk style) ────────────────────────────
# ─── THEME: ELITE (Luxury minimal) ───────────────────────────
# ─── THEME: RETRO (Terminal old-school) ──────────────────────

_box_chars(){
    case $(get_theme) in
        neon)  echo "╔╗╚╝║═╠╣╬"; ;; # double heavy
        elite) echo "┏┓┗┛┃━┣┫╋"; ;; # heavy single
        retro) echo "++++|=++++"; ;; # ASCII pure
    esac
}

# Split: TL TR BL BR V H ML MR C
_bc(){ local s=$(_box_chars); echo "${s:$1:1}"; }

BOX_TL(){ _bc 0; }
BOX_TR(){ _bc 1; }
BOX_BL(){ _bc 2; }
BOX_BR(){ _bc 3; }
BOX_V(){  _bc 4; }
BOX_H(){  _bc 5; }
BOX_ML(){ _bc 6; }
BOX_MR(){ _bc 7; }

_theme_colors(){
    case $(get_theme) in
        neon)
            TC="${CB}"      # title color
            BC="${C}"       # border color
            AC="${YB}"      # accent color
            MC="${G}"       # menu number color
            SC="${M}"       # section color
            IC="${W}"       # info label color
            ;;
        elite)
            TC="${W}"
            BC="${W}"
            AC="${CB}"
            MC="${CB}"
            SC="${C}"
            IC="${C}"
            ;;
        retro)
            TC="${YB}"
            BC="${G}"
            AC="${Y}"
            MC="${G}"
            SC="${Y}"
            IC="${Y}"
            ;;
    esac
}

# Draw horizontal line of W chars
_hline(){ local c="$1" n="${2:-$W}"; printf "%${n}s" | tr ' ' "$c"; }

box_top(){
    _theme_colors
    local title="$1"
    local tl=$(BOX_TL) tr=$(BOX_TR) h=$(BOX_H)
    if [[ -z "$title" ]]; then
        echo -e "${BC}${tl}$(_hline "$h")${tr}${NC}"
    else
        local ct=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        local tl_len=${#ct}
        local lpad=$(( (W - tl_len - 2) / 2 ))
        local rpad=$(( W - tl_len - 2 - lpad ))
        local lh=$(_hline "$h" $lpad)
        local rh=$(_hline "$h" $rpad)
        echo -e "${BC}${tl}${lh} ${TC}${BG}${title}${NC}${BC} ${rh}${tr}${NC}"
    fi
}

box_bot(){
    _theme_colors
    echo -e "${BC}$(BOX_BL)$(_hline "$(BOX_H)")$(BOX_BR)${NC}"
}

box_sep(){
    _theme_colors
    echo -e "${BC}$(BOX_ML)$(_hline "$(BOX_H)")$(BOX_MR)${NC}"
}

box_sep_label(){
    _theme_colors
    local label="$1"
    local cl=$(echo -e "$label" | sed 's/\x1b\[[0-9;]*m//g')
    local ll=${#cl}
    local lp=$(( (W - ll - 2) / 2 ))
    local rp=$(( W - ll - 2 - lp ))
    local h=$(BOX_H)
    local lh=$(_hline "$h" $lp)
    local rh=$(_hline "$h" $rp)
    echo -e "${BC}$(BOX_ML)${D}${lh}${NC}${BC} ${SC}${label}${NC}${BC} ${D}${rh}${NC}${BC}$(BOX_MR)${NC}"
}

box_row(){
    # box_row "content string (may have color codes)"
    _theme_colors
    local content="$1"
    local v=$(BOX_V)
    local clean=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local cl=${#clean}
    local pad=$(( W - cl - 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "${BC}%s${NC} %b%*s${BC}%s${NC}\n" "$v" "$content" "$pad" "" "$v"
}

box_empty(){
    _theme_colors
    local v=$(BOX_V)
    printf "${BC}%s%*s%s${NC}\n" "$v" "$W" "" "$v"
}

box_kv(){
    # box_kv "Label" "Value"
    _theme_colors
    local label="$1" val="$2"
    local v=$(BOX_V)
    local cv=$(echo -e "$val" | sed 's/\x1b\[[0-9;]*m//g')
    local sep=" : "
    local total=$(( ${#label} + ${#sep} + ${#cv} ))
    local pad=$(( W - total - 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "${BC}%s${NC} ${IC}%s${NC}${sep}%b%*s${BC}%s${NC}\n" \
        "$v" "$label" "$val" "$pad" "" "$v"
}

box_menu(){
    # box_menu "num" "text" [icon]
    _theme_colors
    local num="$1" text="$2" icon="${3:- }"
    local v=$(BOX_V)
    local display="${icon} ${text}"
    local total=$(( 2 + ${#num} + 3 + ${#icon} + 1 + ${#text} ))
    local pad=$(( W - total - 2 ))
    [[ $pad -lt 0 ]] && pad=0

    case $(get_theme) in
        neon)
            printf "${BC}%s${NC}  ${BC}[${MC}%s${BC}]${NC} %s%s%*s${BC}%s${NC}\n" \
                "$v" "$num" "$icon " "$text" "$pad" "" "$v"
            ;;
        elite)
            printf "${BC}%s${NC}  ${BC}${MC}%s${NC}${D}›${NC} %s%s%*s${BC}%s${NC}\n" \
                "$v" "$num" "$icon " "$text" "$pad" "" "$v"
            ;;
        retro)
            printf "${BC}%s${NC}  [${MC}%s${NC}] %s%s%*s${BC}%s${NC}\n" \
                "$v" "$num" "$icon " "$text" "$pad" "" "$v"
            ;;
    esac
}

box_menu2(){
    # 2-column menu
    _theme_colors
    local n1="$1" t1="$2" n2="$3" t2="$4" i1="${5:- }" i2="${6:- }"
    local v=$(BOX_V)
    local half=$(( W / 2 ))
    local col1_text="${i1} ${t1}"
    local col2_text="${i2} ${t2}"
    local item1_len=$(( 2 + ${#n1} + 3 + ${#col1_text} ))
    local item2_len=$(( 2 + ${#n2} + 3 + ${#col2_text} ))
    local p1=$(( half - item1_len ))
    local p2=$(( W - half - item2_len - 2 ))
    [[ $p1 -lt 0 ]] && p1=0
    [[ $p2 -lt 0 ]] && p2=0

    case $(get_theme) in
        neon)
            printf "${BC}%s${NC}  ${BC}[${MC}%s${BC}]${NC} %s%s%*s${BC}[${MC}%s${BC}]${NC} %s%s%*s${BC}%s${NC}\n" \
                "$v" "$n1" "$i1 " "$t1" "$p1" "" "$n2" "$i2 " "$t2" "$p2" "" "$v"
            ;;
        elite)
            printf "${BC}%s${NC}  ${MC}%s${NC}${D}›${NC} %s%s%*s${MC}%s${NC}${D}›${NC} %s%s%*s${BC}%s${NC}\n" \
                "$v" "$n1" "$i1 " "$t1" "$p1" "" "$n2" "$i2 " "$t2" "$p2" "" "$v"
            ;;
        retro)
            printf "${BC}%s${NC}  [${MC}%s${NC}] %s%s%*s[${MC}%s${NC}] %s%s%*s${BC}%s${NC}\n" \
                "$v" "$n1" "$i1 " "$t1" "$p1" "" "$n2" "$i2 " "$t2" "$p2" "" "$v"
            ;;
    esac
}

box_status(){
    _theme_colors
    local label="$1" status="$2"
    local v=$(BOX_V)
    local pad=$(( W - ${#label} - ${#status} - 7 ))
    [[ $pad -lt 0 ]] && pad=0
    if [[ "$status" == "ON" ]] || [[ "$status" == "RUNNING" ]]; then
        printf "${BC}%s${NC}  ${GB}●${NC} %-24s ${GB}%s${NC}%*s${BC}%s${NC}\n" \
            "$v" "$label" "● AKTIF" "$pad" "" "$v"
    else
        printf "${BC}%s${NC}  ${R}○${NC} %-24s ${R}%s${NC}%*s${BC}%s${NC}\n" \
            "$v" "$label" "○ MATI " "$pad" "" "$v"
    fi
}

prompt_input(){
    _theme_colors
    local label="$1"
    echo -ne "  ${AC}❯${NC} ${IC}${label}${NC}: "
}

prompt_choice(){
    _theme_colors
    echo -ne "\n  ${BC}$(BOX_V)${NC} ${AC}❯${NC} Pilihan: "
}

# ═══════════════════════════════════════════════════════════════
#  THEME SELECTOR
# ═══════════════════════════════════════════════════════════════

select_theme(){
    clear; echo ""

    # Preview NEON
    echo -e "${CB}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CB}║${NC}  ${YB}[1]${NC} ${W}NEON${NC} ${D}── Cyberpunk Style${NC}                                     ${CB}║${NC}"
    echo -e "${CB}╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CB}║${NC}  ${CB}╔══════════════════════╗${NC}                                          ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${CB}║${NC} ${YB}NEON DASHBOARD${NC}       ${CB}║${NC}  • Double border cyan/yellow              ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${CB}╠══════════════════════╣${NC}  • Cyberpunk color scheme               ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${CB}║${NC}  ${CB}[${G}1${CB}]${NC} Menu Item  ██   ${CB}║${NC}  • Neon glow effect on numbers          ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${CB}║${NC}  ${CB}[${G}2${CB}]${NC} Menu Item  ██   ${CB}║${NC}  • Best for dark terminals               ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${CB}╚══════════════════════╝${NC}                                          ${CB}║${NC}"
    echo -e "${CB}╠════════════════════════════════════════════════════════════════════╣${NC}"

    # Preview ELITE
    echo -e "${CB}║${NC}  ${YB}[2]${NC} ${W}ELITE${NC} ${D}── Luxury Minimal${NC}                                    ${CB}║${NC}"
    echo -e "${CB}╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CB}║${NC}  ${W}┏━━━━━━━━━━━━━━━━━━━━━━┓${NC}                                          ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${W}┃${NC}  ${CB}ELITE DASHBOARD${NC}      ${W}┃${NC}  • Heavy single border white/cyan         ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${W}┣━━━━━━━━━━━━━━━━━━━━━━┫${NC}  • Luxury minimal aesthetic              ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${W}┃${NC}  ${CB}1${NC}${D}›${NC} Menu Item       ${W}┃${NC}  • Arrow indicator style                 ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${W}┃${NC}  ${CB}2${NC}${D}›${NC} Menu Item       ${W}┃${NC}  • Clean & professional                  ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${W}┗━━━━━━━━━━━━━━━━━━━━━━┛${NC}                                          ${CB}║${NC}"
    echo -e "${CB}╠════════════════════════════════════════════════════════════════════╣${NC}"

    # Preview RETRO
    echo -e "${CB}║${NC}  ${YB}[3]${NC} ${W}RETRO${NC} ${D}── Terminal Classic${NC}                                  ${CB}║${NC}"
    echo -e "${CB}╠════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CB}║${NC}  ${G}+----------------------+${NC}                                          ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${G}|${NC}  ${Y}RETRO DASHBOARD${NC}      ${G}|${NC}  • Pure ASCII +--+ borders green/yellow     ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${G}|======================|${NC}  • Old-school terminal vibes              ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${G}|${NC}  [${G}1${NC}] Menu Item       ${G}|${NC}  • Max compatibility all terminals          ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${G}|${NC}  [${G}2${NC}] Menu Item       ${G}|${NC}  • Hacker aesthetic                         ${CB}║${NC}"
    echo -e "${CB}║${NC}  ${G}+----------------------+${NC}                                          ${CB}║${NC}"
    echo -e "${CB}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "  ${YB}❯${NC} Pilih tema [1-3]: "
    read -r tc
    case "$tc" in
        1) echo "neon"  > "$THEME_FILE"; echo -e "\n  ${CB}✦ Tema NEON diaktifkan!${NC}" ;;
        2) echo "elite" > "$THEME_FILE"; echo -e "\n  ${W}✦ Tema ELITE diaktifkan!${NC}" ;;
        3) echo "retro" > "$THEME_FILE"; echo -e "\n  ${G}✦ Tema RETRO diaktifkan!${NC}" ;;
        *)  echo "neon" > "$THEME_FILE"; echo -e "\n  ${Y}Default NEON.${NC}" ;;
    esac
    sleep 1
}

# ═══════════════════════════════════════════════════════════════
#  ANIMATED INSTALLER
# ═══════════════════════════════════════════════════════════════

_spinner(){
    local pid=$1 msg="$2"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${C}${frames[$i]}${NC} ${D}%s${NC}" "$msg"
        i=$(( (i+1) % ${#frames[@]} ))
        sleep 0.1
    done
    printf "\r"
}

_pkg_install(){
    local pkg="$1" label="${2:-$1}"
    if dpkg -l 2>/dev/null | grep -q "^ii.*${pkg}[[:space:]]"; then
        printf "  ${D}[≡]${NC} %-32s ${D}already installed${NC}\n" "$label"
        return 0
    fi
    printf "  ${C}[↓]${NC} %-32s" "$label"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" \
        >> /tmp/vpn_install.log 2>&1
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        printf " ${G}done${NC}\n"
    else
        printf " ${R}failed${NC}\n"
    fi
    return $rc
}

_step_banner(){
    local step="$1" total="$2" title="$3"
    local pct=$(( step * 100 / total ))
    local filled=$(( step * 30 / total ))
    local bar=$(printf '#%.0s' $(seq 1 $filled))
    local empty=$(printf '.%.0s' $(seq 1 $((30-filled))))

    echo ""
    echo -e "${CB}┌──────────────────────────────────────────────────────────────────┐${NC}"
    printf "${CB}│${NC}  ${W}STEP %d/%d${NC}  ${D}%-40s${NC}  ${Y}%3d%%${NC}  ${CB}│${NC}\n" \
        "$step" "$total" "$title" "$pct"
    printf "${CB}│${NC}  [${G}%s${D}%s${NC}]                                             ${CB}│${NC}\n" \
        "$bar" "$empty"
    echo -e "${CB}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

_ok_step(){   printf "  ${G}[✓]${NC} %-38s ${G}OK${NC}\n" "$1"; }
_skip_step(){ printf "  ${D}[⊘]${NC} %-38s ${D}SKIP${NC}\n" "$1"; }
_fail_step(){ printf "  ${R}[✗]${NC} %-38s ${R}FAIL${NC}\n" "$1"; }
_run_step(){  printf "  ${C}[→]${NC} %-38s" "$1"; }

show_install_banner(){
    clear
    # Animated reveal
    local frames=(
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}"
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}
${C}    ██║   ██║██╔══██╗████╗  ██║${NC}"
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}
${C}    ██║   ██║██╔══██╗████╗  ██║${NC}
${G}    ██║   ██║██████╔╝██╔██╗ ██║${NC}"
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}
${C}    ██║   ██║██╔══██╗████╗  ██║${NC}
${G}    ██║   ██║██████╔╝██╔██╗ ██║${NC}
${Y}    ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║${NC}"
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}
${C}    ██║   ██║██╔══██╗████╗  ██║${NC}
${G}    ██║   ██║██████╔╝██╔██╗ ██║${NC}
${Y}    ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║${NC}
${R}     ╚████╔╝ ██║     ██║ ╚████║${NC}"
"
${CB}    ██╗   ██╗██████╗ ███╗   ██╗${NC}
${C}    ██║   ██║██╔══██╗████╗  ██║${NC}
${G}    ██║   ██║██████╔╝██╔██╗ ██║${NC}
${Y}    ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║${NC}
${R}     ╚████╔╝ ██║     ██║ ╚████║${NC}
${M}      ╚═══╝  ╚═╝     ╚═╝  ╚═══╝${NC}")

    for frame in "${frames[@]}"; do
        clear
        echo -e "$frame"
        sleep 0.08
    done

    clear
    echo ""
    echo -e "${CB}  ██╗   ██╗██████╗ ███╗   ██╗${NC}"
    echo -e "${C}  ██║   ██║██╔══██╗████╗  ██║${NC}"
    echo -e "${G}  ██║   ██║██████╔╝██╔██╗ ██║${NC}"
    echo -e "${Y}  ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║${NC}"
    echo -e "${R}   ╚████╔╝ ██║     ██║ ╚████║${NC}"
    echo -e "${M}    ╚═══╝  ╚═╝     ╚═╝  ╚═══╝${NC}"
    echo ""
    echo -e "${D}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${W}VPN AUTO SCRIPT ${Y}v${VER}${NC}         ${D}By The Proffessor Squad${NC}"
    echo -e "  ${D}Support: ${C}@ridhani16${NC}              ${D}github.com/${GITHUB_USER}${NC}"
    echo -e "${D}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
#  XRAY CONFIG - FIXED PORT ALLOCATION
# ═══════════════════════════════════════════════════════════════
# Port mapping (no conflicts):
#   VMess  WS  TLS    : 8443
#   VMess  WS  NonTLS : 8880
#   VMess  gRPC TLS   : 8444
#   VLess  WS  TLS    : 8445
#   VLess  WS  NonTLS : 8881
#   VLess  gRPC TLS   : 8446
#   Trojan WS  TLS    : 8447
#   Trojan gRPC TLS   : 8448
# HAProxy 443 → VMess 8443 (TLS termination via xray itself)
# Nginx 80 → forwards /vmess /vless /trojan to respective NonTLS ports

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
        "wsSettings": { "path": "/vmess" }
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
        "wsSettings": { "path": "/vless" }
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

get_ssl(){
    local dtype="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && dtype=$(cat "$DOMAIN_TYPE_FILE")
    mkdir -p /etc/xray

    if [[ "$dtype" == "custom" ]] && command -v certbot >/dev/null 2>&1; then
        certbot certonly --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos --register-unsafely-without-email \
            >/dev/null 2>&1
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
            echo "letsencrypt"
            return
        fi
    fi
    # Self-signed fallback
    openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
        -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
        -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null
    echo "self-signed"
}

# ── Xray account helpers ──────────────────────────────────────

_xray_add(){
    local proto="$1" uuid="$2" email="$3"
    local tmp=$(mktemp)
    local tag_prefix
    case "$proto" in
        vmess)  tag_prefix="vmess"  ;;
        vless)  tag_prefix="vless"  ;;
        trojan) tag_prefix="trojan" ;;
    esac

    if [[ "$proto" == "vmess" ]]; then
        jq --arg u "$uuid" --arg e "$email" \
          '(.inbounds[] | select(.tag | startswith("vmess")) | .settings.clients) += [{"id":$u,"email":$e,"alterId":0}]' \
          "$XRAY_CONFIG" > "$tmp"
    elif [[ "$proto" == "vless" ]]; then
        jq --arg u "$uuid" --arg e "$email" \
          '(.inbounds[] | select(.tag | startswith("vless")) | .settings.clients) += [{"id":$u,"email":$e}]' \
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
        local j_tls=$(printf '{"v":"2","ps":"%s-TLS","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' "$user" "$uuid" "$DOMAIN")
        local j_nontls=$(printf '{"v":"2","ps":"%s-HTTP","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' "$user" "$uuid" "$DOMAIN")
        local j_grpc=$(printf '{"v":"2","ps":"%s-gRPC","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"%s","tls":"tls"}' "$user" "$DOMAIN" "$uuid" "$DOMAIN")
        echo "vmess://$(echo -n "$j_tls"|base64 -w0)"
        echo "vmess://$(echo -n "$j_nontls"|base64 -w0)"
        echo "vmess://$(echo -n "$j_grpc"|base64 -w0)"
        ;;
      vless)
        echo "vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}-TLS"
        echo "vless://${uuid}@bug.com:80?path=%2Fvless&security=none&encryption=none&host=${DOMAIN}&type=ws#${user}-HTTP"
        echo "vless://${uuid}@${DOMAIN}:8446?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${DOMAIN}#${user}-gRPC"
        ;;
      trojan)
        echo "trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${user}-TLS"
        echo "trojan://${uuid}@bug.com:80?path=%2Ftrojan&security=none&host=${DOMAIN}&type=ws#${user}-HTTP"
        echo "trojan://${uuid}@${DOMAIN}:8448?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${DOMAIN}#${user}-gRPC"
        ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#  DOMAIN SETUP
# ═══════════════════════════════════════════════════════════════

setup_domain(){
    clear; echo ""
    local ip=$(get_ip)
    local rand_dom=$(gen_random_domain)

    echo -e "${CB}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CB}│${NC}           ${W}KONFIGURASI DOMAIN VPN SERVER${NC}                        ${CB}│${NC}"
    echo -e "${CB}└──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${G}[1]${NC} ${W}Domain Pribadi${NC}  ${D}─ Let's Encrypt SSL (Recommended)${NC}"
    echo -e "      ${D}Contoh: vpn.namadomain.com${NC}"
    echo -e "      ${R}⚠${NC} ${D}Domain harus sudah pointing ke IP: ${Y}${ip}${NC}"
    echo ""
    echo -e "  ${G}[2]${NC} ${W}Domain Otomatis${NC} ${D}─ Self-Signed SSL (nip.io)${NC}"
    echo -e "      ${D}Preview: ${C}${rand_dom}${NC}"
    echo -e "      ${D}Tidak perlu konfigurasi DNS${NC}"
    echo ""
    echo -ne "  ${YB}❯${NC} Pilihan [1/2]: "
    read -r dc

    case "$dc" in
      1)
        echo -ne "\n  ${YB}❯${NC} Masukkan domain: "
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
    echo -e "  ${G}✓${NC} Domain disimpan: ${CB}${DOMAIN}${NC}"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  DASHBOARD
# ═══════════════════════════════════════════════════════════════

show_dashboard(){
    clear
    load_domain

    local ip=$(get_ip)
    local os_name="Linux"
    [[ -f /etc/os-release ]] && { source /etc/os-release; os_name="${PRETTY_NAME}"; }
    local ram_u=$(free -m | awk 'NR==2{print $3}')
    local ram_t=$(free -m | awk 'NR==2{print $2}')
    local ram_p=0
    [[ $ram_t -gt 0 ]] && ram_p=$(( ram_u * 100 / ram_t ))
    local cpu=$(top -bn1 2>/dev/null | awk '/Cpu/{print $2}' | cut -d. -f1)
    local up=$(uptime -p 2>/dev/null | sed 's/up //')

    local dtype="random"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && dtype=$(cat "$DOMAIN_TYPE_FILE")
    local ssl_t="Self-Signed"
    [[ "$dtype" == "custom" ]] && ssl_t="Let's Encrypt"

    local svcs_on=0 svcs_tot=0
    for s in xray nginx sshd haproxy dropbear udp-custom vpn-keepalive vpn-bot; do
        ((svcs_tot++))
        systemctl is-active --quiet "$s" 2>/dev/null && ((svcs_on++))
    done

    local sc=$(ls "$AKUN_DIR"/ssh-*.txt   2>/dev/null | wc -l)
    local vc=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    local lc=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    local tc=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)

    _theme_colors
    echo ""
    box_top " VPN MANAGER v${VER} "
    box_sep_label "SERVER"
    box_kv "Domain"   "${CB}${DOMAIN:-Not Set}${NC}"
    box_kv "IP VPS"   "${W}${ip}${NC}"
    box_kv "OS"       "${D}${os_name}${NC}"
    box_kv "Uptime"   "${C}${up}${NC}"
    box_kv "CPU"      "${Y}${cpu:-0}%${NC}"
    box_kv "RAM"      "${Y}${ram_u}/${ram_t} MB (${ram_p}%)${NC}"
    box_kv "SSL"      "${G}${ssl_t}${NC}"
    box_kv "Services" "${G}${svcs_on}${NC}${D}/${svcs_tot} aktif${NC}"
    box_sep_label "AKUN"
    box_row " SSH:${G}${sc}${NC}  VMess:${G}${vc}${NC}  VLess:${G}${lc}${NC}  Trojan:${G}${tc}${NC}"
    box_sep_label "STATUS"
    box_status "Xray Core"       "$(chk xray)"
    box_status "Nginx"           "$(chk nginx)"
    box_status "HAProxy"         "$(chk haproxy)"
    box_status "Dropbear"        "$(chk dropbear)"
    box_status "UDP Custom"      "$(chk udp-custom)"
    box_status "Keepalive"       "$(chk vpn-keepalive)"
    box_status "Telegram Bot"    "$(chk vpn-bot)"
    box_bot
    echo ""
}

# ═══════════════════════════════════════════════════════════════
#  MAIN MENU
# ═══════════════════════════════════════════════════════════════

show_main_menu(){
    _theme_colors
    box_top " MAIN MENU "
    box_sep_label "AKUN"
    box_menu2 "1" "SSH"          "2" "VMess"        "🖥" "📡"
    box_menu2 "3" "VLess"        "4" "Trojan"        "📡" "🛡"
    box_menu2 "5" "Trial Akun"   "6" "List Semua"    "⏱" "📋"
    box_menu2 "7" "Cek Expired"  "8" "Hapus Expired" "📅" "🗑"
    box_sep_label "SISTEM"
    box_menu2 "9"  "Telegram Bot"  "10" "Ganti Domain"   "🤖" "🌐"
    box_menu2 "11" "Fix SSL"       "12" "Optimalkan VPS"  "🔐" "⚡"
    box_menu2 "13" "Restart All"   "14" "Fix All Service" "🔄" "🔧"
    box_menu2 "15" "Speedtest"     "16" "Update Script"   "🚀" "🔄"
    box_menu2 "17" "Backup"        "18" "Restore"         "💾" "📥"
    box_menu  "19" "Info Port"                            "ℹ"
    box_sep_label "LAINNYA"
    box_menu2 "20" "Hapus Komponen" "21" "Ganti Tema"    "🗑" "🎨"
    box_menu  "99" "Advanced Settings"                    "⚙"
    box_sep_label "─"
    box_menu  "0"  "Keluar"                               "✕"
    box_bot
    echo ""
    echo -e "  ${D}Tema: $(get_theme | tr a-z A-Z)${NC}  ${D}│${NC}  ${D}ketik ${C}help${NC}${D} untuk panduan${NC}"
}

# ═══════════════════════════════════════════════════════════════
#  SSH MENU & FUNCTIONS
# ═══════════════════════════════════════════════════════════════

ssh_menu(){
    while true; do
        clear
        _theme_colors
        box_top " SSH MENU "
        box_sep_label "KELOLA"
        box_menu "1" "Buat Akun SSH"          "➕"
        box_menu "2" "Trial SSH (1 Jam)"       "⏱"
        box_menu "3" "Hapus Akun SSH"          "🗑"
        box_menu "4" "Perpanjang Akun SSH"     "🔄"
        box_menu "5" "Login Aktif"             "👁"
        box_menu "6" "Daftar Semua Akun"       "📋"
        box_menu "7" "Set IP Limit per User"   "🔒"
        box_sep_label "─"
        box_menu "0" "Kembali"                 "◀"
        box_bot
        prompt_choice; read -r ch
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
    box_top " BUAT AKUN SSH "
    box_empty
    box_bot
    echo ""
    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && { warn "Username tidak boleh kosong!"; sleep 2; return; }
    id "$uname" &>/dev/null && { warn "Username sudah ada!"; sleep 2; return; }
    prompt_input "Password"; read -r upass
    [[ -z "$upass" ]] && { warn "Password tidak boleh kosong!"; sleep 2; return; }
    prompt_input "Expired (hari)"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Hari harus angka!"; sleep 2; return; }
    prompt_input "Batas IP (default 2)"; read -r iplimit
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
==========================================================
  SSH ACCOUNT - Proffessor Squad
==========================================================
 Username     : ${uname}
 Password     : ${upass}
 IP/Host      : ${ip}
 Domain       : ${DOMAIN}
----------------------------------------------------------
 Port OpenSSH : 22
 Port Dropbear: 222
 Port SSL/TLS : 443
 Port WS HTTP : 80
 Port WS SSL  : 443
 BadVPN UDP   : 7100,7200,7300
----------------------------------------------------------
 Format HC    : ${DOMAIN}:80@${uname}:${upass}
----------------------------------------------------------
 Download     : http://${ip}:81/ssh-${uname}.txt
 Dibuat       : $(date +"%d %b %Y")
 Expired      : ${exp}
 Durasi       : ${days} Hari
==========================================================
EOF

    clear
    box_top " ✓ AKUN SSH DIBUAT "
    box_empty
    box_kv "Username"   "${G}${uname}${NC}"
    box_kv "Password"   "${W}${upass}${NC}"
    box_kv "IP/Host"    "${C}${ip}${NC}"
    box_kv "Domain"     "${C}${DOMAIN}${NC}"
    box_kv "Batas IP"   "${Y}${iplimit} IP${NC}"
    box_sep_label "PORT"
    box_kv "OpenSSH"    "22"
    box_kv "Dropbear"   "222"
    box_kv "SSL/TLS"    "443"
    box_kv "WS HTTP"    "80"
    box_kv "BadVPN UDP" "7100-7300"
    box_sep_label "INFO"
    box_kv "Download"   "http://${ip}:81/ssh-${uname}.txt"
    box_kv "Expired"    "${R}${exp}${NC}"
    box_kv "Durasi"     "${days} Hari"
    box_empty
    box_bot

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

    (sleep 3600; userdel -rf "$uname" 2>/dev/null
     rm -f "$AKUN_DIR/ssh-${uname}.txt") & disown

    clear
    box_top " ⏱ SSH TRIAL 1 JAM "
    box_empty
    box_kv "Username"  "${G}${uname}${NC}"
    box_kv "Password"  "${W}${upass}${NC}"
    box_kv "Domain"    "${C}${DOMAIN}${NC}"
    box_kv "OpenSSH"   "22"
    box_kv "Dropbear"  "222"
    box_kv "Expired"   "${R}${exp_show}${NC}"
    box_empty
    box_row "  ${Y}⚠ Auto-hapus setelah 1 jam${NC}"
    box_empty
    box_bot
    echo ""; read -rp "  Tekan Enter..."
}

ssh_delete(){
    clear
    box_top " HAPUS AKUN SSH "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun SSH.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username yang dihapus"; read -r uname
    [[ -z "$uname" ]] && return

    userdel -rf "$uname" 2>/dev/null
    rm -f "$AKUN_DIR/ssh-${uname}.txt" "$PUBLIC_HTML/ssh-${uname}.txt"
    echo -e "\n  ${G}✓ Akun ${uname} dihapus.${NC}"; sleep 2
}

ssh_renew(){
    clear
    box_top " PERPANJANG AKUN SSH "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun SSH.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/ssh-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    prompt_input "Tambah hari"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }

    local new_exp=$(date -d "+${days} days" +"%d %b %Y")
    local new_raw=$(date -d "+${days} days" +"%Y-%m-%d")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/ssh-${uname}.txt"
    chage -E "$new_raw" "$uname" 2>/dev/null

    echo -e "\n  ${G}✓ Diperpanjang! Expired baru: ${new_exp}${NC}"; sleep 2
}

ssh_active(){
    clear
    box_top " LOGIN SSH AKTIF "
    box_empty
    local au=$(who 2>/dev/null | awk '{print $1}' | sort | uniq)
    if [[ -z "$au" ]]; then
        box_row "  ${Y}Tidak ada sesi SSH aktif.${NC}"
    else
        while IFS= read -r u; do
            local cnt=$(who | grep -c "^${u} ")
            local t=$(who | grep "^${u} " | head -1 | awk '{print $3,$4}')
            box_row "  ${G}●${NC} ${W}${u}${NC}  ${D}${cnt} koneksi  login: ${t}${NC}"
        done <<< "$au"
    fi
    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

ssh_iplimit(){
    clear
    box_top " SET IP LIMIT SSH "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/ssh-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun SSH.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed 's/ssh-//')
        local il=$(grep "IPLIMIT=" "$f" 2>/dev/null | cut -d= -f2-)
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}limit: ${Y}${il:-?}${NC} IP${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/ssh-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    prompt_input "IP Limit baru"; read -r newlimit
    [[ ! "$newlimit" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }

    sed -i "s/IPLIMIT=.*/IPLIMIT=${newlimit}/" "$AKUN_DIR/ssh-${uname}.txt"
    echo -e "\n  ${G}✓ IP Limit ${uname} diset ke ${newlimit}.${NC}"; sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  XRAY MENU (VMess / VLess / Trojan)
# ═══════════════════════════════════════════════════════════════

xray_menu(){
    local proto="$1"
    local icon="📡"
    [[ "$proto" == "trojan" ]] && icon="🛡"

    while true; do
        clear
        _theme_colors
        box_top " ${proto^^} MENU "
        box_sep_label "KELOLA"
        box_menu "1" "Buat Akun ${proto^^}"        "➕"
        box_menu "2" "Trial ${proto^^} (1 Jam)"    "⏱"
        box_menu "3" "Hapus Akun"                  "🗑"
        box_menu "4" "Perpanjang Akun"             "🔄"
        box_menu "5" "Koneksi Aktif"               "👁"
        box_menu "6" "Daftar Semua Akun"           "📋"
        box_menu "7" "Set Quota Bandwidth"         "📊"
        box_sep_label "─"
        box_menu "0" "Kembali"                     "◀"
        box_bot
        prompt_choice; read -r ch
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
    box_top " BUAT AKUN ${proto^^} "
    box_empty; box_bot; echo ""

    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && { warn "Username tidak boleh kosong!"; sleep 2; return; }
    grep -q "\"email\":\"${uname}\"" "$XRAY_CONFIG" 2>/dev/null && { warn "Username sudah ada!"; sleep 2; return; }
    prompt_input "Expired (hari)"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }
    prompt_input "Quota GB (default 0=unlimited)"; read -r quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=0
    prompt_input "Batas IP (default 2)"; read -r iplimit
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

    # Generate links
    local links=()
    mapfile -t links < <(_gen_links "$proto" "$uuid" "$uname")
    local l_tls="${links[0]}"
    local l_http="${links[1]}"
    local l_grpc="${links[2]}"

    # Port info per protocol
    local p_tls p_http p_grpc p_ws
    case "$proto" in
        vmess)  p_tls=8443; p_http=8880; p_grpc=8444; p_ws="/vmess"  ;;
        vless)  p_tls=8445; p_http=8881; p_grpc=8446; p_ws="/vless"  ;;
        trojan) p_tls=8447; p_http="N/A"; p_grpc=8448; p_ws="/trojan" ;;
    esac

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${proto}-${uname}.txt" << EOF
==========================================================
  ${proto^^} ACCOUNT - Proffessor Squad
==========================================================
 Username  : ${uname}
 UUID      : ${uuid}
 Domain    : ${DOMAIN}
 Quota     : $( [[ $quota -eq 0 ]] && echo "Unlimited" || echo "${quota} GB" )
 IP Limit  : ${iplimit} IP
----------------------------------------------------------
 Port TLS  : ${p_tls}   (direct / via HAProxy 443)
 Port HTTP : ${p_http}  (via Nginx 80)
 Port gRPC : ${p_grpc}
 Path WS   : ${p_ws}
----------------------------------------------------------
 Link TLS:
 ${l_tls}
----------------------------------------------------------
 Link HTTP:
 ${l_http}
----------------------------------------------------------
 Link gRPC:
 ${l_grpc}
----------------------------------------------------------
 Download  : http://${ip}:81/${proto}-${uname}.txt
 Expired   : ${exp}
 Durasi    : ${days} Hari
==========================================================
EOF

    clear
    box_top " ✓ AKUN ${proto^^} DIBUAT "
    box_empty
    box_kv "Username"   "${G}${uname}${NC}"
    box_kv "UUID"       "${D}${uuid}${NC}"
    box_kv "Domain"     "${C}${DOMAIN}${NC}"
    box_kv "Quota"      "$( [[ $quota -eq 0 ]] && echo "${G}Unlimited${NC}" || echo "${Y}${quota} GB${NC}" )"
    box_kv "IP Limit"   "${Y}${iplimit} IP${NC}"
    box_sep_label "PORT"
    box_kv "TLS"        "${p_tls}  (HAProxy→443)"
    box_kv "HTTP"       "${p_http} (Nginx→80)"
    box_kv "gRPC"       "${p_grpc}"
    box_kv "Path WS"    "${p_ws}"
    box_sep_label "LINKS"
    box_row "  ${C}TLS:${NC}"
    # Truncate long link for display
    local short="${l_tls:0:60}..."
    box_row "  ${D}${short}${NC}"
    box_empty
    box_sep_label "INFO"
    box_kv "Download"   "http://${ip}:81/${proto}-${uname}.txt"
    box_kv "Expired"    "${R}${exp}${NC}"
    box_kv "Durasi"     "${days} Hari"
    box_empty
    box_bot

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

    (sleep 3600
     _xray_del "$uname"
     rm -f "$AKUN_DIR/${proto}-${uname}.txt") & disown

    local links=()
    mapfile -t links < <(_gen_links "$proto" "$uuid" "$uname")

    clear
    box_top " ⏱ ${proto^^} TRIAL 1 JAM "
    box_empty
    box_kv "Username"  "${G}${uname}${NC}"
    box_kv "UUID"      "${D}${uuid}${NC}"
    box_kv "Domain"    "${C}${DOMAIN}${NC}"
    box_sep_label "LINK TLS"
    local short="${links[0]:0:62}..."
    box_row "  ${D}${short}${NC}"
    box_empty
    box_kv "Expired"   "${R}${exp}${NC}"
    box_row "  ${Y}⚠ Auto-hapus setelah 1 jam${NC}"
    box_empty
    box_bot
    echo ""; read -rp "  Tekan Enter..."
}

xray_delete(){
    local proto="$1"
    clear
    box_top " HAPUS AKUN ${proto^^} "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun ${proto^^}.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username yang dihapus"; read -r uname
    [[ -z "$uname" ]] && return

    _xray_del "$uname"
    rm -f "$AKUN_DIR/${proto}-${uname}.txt" "$PUBLIC_HTML/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Akun ${uname} dihapus.${NC}"; sleep 2
}

xray_renew(){
    local proto="$1"
    clear
    box_top " PERPANJANG AKUN ${proto^^} "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/${proto}-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    prompt_input "Tambah hari"; read -r days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }

    local new_exp=$(date -d "+${days} days" +"%d %b %Y")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Diperpanjang! Expired baru: ${new_exp}${NC}"; sleep 2
}

xray_active(){
    local proto="$1"
    clear
    box_top " KONEKSI ${proto^^} AKTIF "
    box_empty

    if [[ ! -f /var/log/xray/access.log ]]; then
        box_row "  ${Y}Log tidak ditemukan.${NC}"
        box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."; return
    fi

    local logs=$(grep "accepted" /var/log/xray/access.log 2>/dev/null | grep -i "$proto" | tail -100)
    if [[ -z "$logs" ]]; then
        box_row "  ${Y}Tidak ada koneksi ${proto^^} aktif.${NC}"
    else
        local users=$(echo "$logs" | grep -oP 'email: \K[^ >]+' | sort | uniq)
        if [[ -z "$users" ]]; then
            box_row "  ${Y}Tidak ada user terdeteksi.${NC}"
        else
            while IFS= read -r u; do
                local cnt=$(echo "$logs" | grep -c "email: $u")
                box_row "  ${G}●${NC} ${W}${u}${NC}  ${D}${cnt} koneksi${NC}"
            done <<< "$users"
        fi
    fi

    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

xray_quota(){
    local proto="$1"
    clear
    box_top " SET QUOTA ${proto^^} "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada akun.${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local un=$(basename "$f" .txt | sed "s/${proto}-//")
        local q=$(grep "QUOTA=" "$f" 2>/dev/null | cut -d= -f2-)
        local ql=$( [[ "${q:-0}" == "0" ]] && echo "Unlimited" || echo "${q}GB" )
        box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}quota: ${Y}${ql}${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Username"; read -r uname
    [[ -z "$uname" ]] && return
    [[ ! -f "$AKUN_DIR/${proto}-${uname}.txt" ]] && { warn "Akun tidak ditemukan!"; sleep 2; return; }
    prompt_input "Quota baru GB (0=unlimited)"; read -r newq
    [[ ! "$newq" =~ ^[0-9]+$ ]] && { warn "Harus angka!"; sleep 2; return; }

    sed -i "s/QUOTA=.*/QUOTA=${newq}/" "$AKUN_DIR/${proto}-${uname}.txt"
    echo -e "\n  ${G}✓ Quota ${uname} diset ke $( [[ $newq -eq 0 ]] && echo "Unlimited" || echo "${newq}GB" ).${NC}"
    sleep 2
}

# ═══════════════════════════════════════════════════════════════
#  LIST & EXPIRED
# ═══════════════════════════════════════════════════════════════

list_accounts(){
    local proto="$1"
    clear
    box_top " DAFTAR AKUN ${proto^^} "
    box_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${proto}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        box_row "  ${Y}Tidak ada akun ${proto^^}.${NC}"
    else
        for f in "${files[@]}"; do
            local un=$(basename "$f" .txt | sed "s/${proto}-//")
            local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
            local q=$(grep "QUOTA=" "$f" 2>/dev/null | cut -d= -f2-)
            local il=$(grep "IPLIMIT=" "$f" 2>/dev/null | cut -d= -f2-)
            local q_str=$( [[ "${q:-0}" == "0" ]] && echo "∞" || echo "${q}GB" )
            box_row "  ${G}▸${NC} ${W}${un}${NC}  ${D}exp:${ex}  q:${q_str}  ip:${il:-?}${NC}"
        done
        box_empty
        box_kv "Total" "${G}${#files[@]}${NC} akun"
    fi

    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

trial_menu(){
    clear
    box_top " TRIAL GENERATOR "
    box_empty
    box_menu "1" "SSH Trial (1 Jam)"     "🖥"
    box_menu "2" "VMess Trial (1 Jam)"   "📡"
    box_menu "3" "VLess Trial (1 Jam)"   "📡"
    box_menu "4" "Trojan Trial (1 Jam)"  "🛡"
    box_sep_label "─"
    box_menu "0" "Kembali"               "◀"
    box_bot
    prompt_choice; read -r ch
    case "$ch" in
        1) ssh_trial ;;
        2) xray_trial "vmess" ;;
        3) xray_trial "vless" ;;
        4) xray_trial "trojan" ;;
    esac
}

list_all(){
    clear
    box_top " SEMUA AKUN AKTIF "
    box_empty
    local total=0
    shopt -s nullglob

    for proto in ssh vmess vless trojan; do
        local files=("$AKUN_DIR"/${proto}-*.txt)
        [[ ${#files[@]} -eq 0 ]] && continue
        box_sep_label "${proto^^} (${#files[@]})"
        for f in "${files[@]}"; do
            local un=$(basename "$f" .txt | sed "s/${proto}-//")
            local ex=$(grep "EXPIRED=" "$f" 2>/dev/null | cut -d= -f2-)
            box_row "  ${C}•${NC} ${W}${un}${NC}  ${D}exp: ${ex}${NC}"
            ((total++))
        done
    done

    shopt -u nullglob
    box_empty
    box_kv "Total Akun" "${G}${total}${NC}"
    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

check_expired(){
    clear
    box_top " CEK AKUN EXPIRED "
    box_empty
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
                box_row "  ${R}✗ EXPIRED${NC}  ${W}${un}${NC}  ${D}(${ex})${NC}"
            else
                box_row "  ${Y}⚠ ${diff}h${NC}  ${W}${un}${NC}  ${D}(${ex})${NC}"
            fi
        fi
    done

    shopt -u nullglob
    [[ $found -eq 0 ]] && box_row "  ${G}✓ Tidak ada akun hampir expired.${NC}"
    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

delete_expired(){
    clear
    box_top " HAPUS AKUN EXPIRED "
    box_empty
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
            box_row "  ${R}↺ Menghapus${NC} ${W}${fn}${NC}"
            _xray_del "$uname" 2>/dev/null
            [[ "$proto" == "ssh" ]] && userdel -rf "$uname" 2>/dev/null
            rm -f "$f" "$PUBLIC_HTML/${fn}.txt"
            ((count++))
        fi
    done

    shopt -u nullglob
    box_empty
    if [[ $count -gt 0 ]]; then
        fix_xray_perm
        systemctl restart xray 2>/dev/null
        box_row "  ${G}✓ ${count} akun dihapus.${NC}"
    else
        box_row "  ${G}✓ Tidak ada akun expired.${NC}"
    fi
    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  TELEGRAM BOT
# ═══════════════════════════════════════════════════════════════

bot_menu(){
    while true; do
        clear
        _theme_colors
        box_top " TELEGRAM BOT "
        box_empty
        box_status "Bot Service" "$(chk vpn-bot)"
        box_empty
        box_sep_label "KELOLA"
        box_menu "1" "Setup Bot (Token & ChatID)" "⚙"
        box_menu "2" "Start Bot"                  "▶"
        box_menu "3" "Stop Bot"                   "⏹"
        box_menu "4" "Restart Bot"                "🔄"
        box_menu "5" "Lihat Log"                  "📋"
        box_menu "6" "Test Kirim Pesan"           "📨"
        box_sep_label "─"
        box_menu "0" "Kembali"                    "◀"
        box_bot
        prompt_choice; read -r ch
        case "$ch" in
            1) bot_setup ;;
            2) systemctl start   vpn-bot 2>/dev/null; echo -e "\n  ${G}▶ Started${NC}"; sleep 1 ;;
            3) systemctl stop    vpn-bot 2>/dev/null; echo -e "\n  ${Y}⏹ Stopped${NC}"; sleep 1 ;;
            4) systemctl restart vpn-bot 2>/dev/null; echo -e "\n  ${G}🔄 Restarted${NC}"; sleep 1 ;;
            5) clear; journalctl -u vpn-bot -n 50 --no-pager 2>/dev/null || echo "  No logs"; echo ""; read -rp "  Enter..." ;;
            6) [[ -f "$BOT_TOKEN_FILE" && -f "$CHAT_ID_FILE" ]] && \
               tg "🔔 Test pesan dari VPN Manager v${VER}" && echo -e "\n  ${G}✓ Terkirim!${NC}" || \
               echo -e "\n  ${R}Bot belum dikonfigurasi!${NC}"; sleep 2 ;;
            0) return ;;
        esac
    done
}

bot_setup(){
    clear
    box_top " SETUP TELEGRAM BOT "
    box_empty
    box_row "  ${D}1. Buka Telegram → cari ${C}@BotFather${NC}"
    box_row "  ${D}2. Ketik /newbot → ikuti instruksi${NC}"
    box_row "  ${D}3. Copy TOKEN yang diberikan${NC}"
    box_row "  ${D}4. Cari ${C}@userinfobot${NC}${D} → /start → copy ID${NC}"
    box_empty; box_bot; echo ""

    prompt_input "Bot Token"; read -r btoken
    [[ -z "$btoken" ]] && { warn "Token wajib diisi!"; sleep 2; return; }

    echo -ne "\n  ${C}→${NC} Memverifikasi token..."
    local res=$(curl -s --max-time 8 "https://api.telegram.org/bot${btoken}/getMe")
    if ! echo "$res" | grep -q '"ok":true'; then
        echo -e " ${R}✗ Token tidak valid!${NC}"; sleep 2; return
    fi
    local bname=$(echo "$res" | grep -oP '"username":"\K[^"]+')
    echo -e " ${G}✓ Bot: @${bname}${NC}"

    echo ""
    prompt_input "Admin Chat ID"; read -r chatid
    [[ -z "$chatid" ]] && { warn "Chat ID wajib diisi!"; sleep 2; return; }
    prompt_input "Nama Rekening"; read -r rname
    prompt_input "No Rekening/Dompet"; read -r rnum
    prompt_input "Bank/E-Wallet"; read -r rbank
    prompt_input "Harga/bulan (Rp)"; read -r harga
    [[ ! "$harga" =~ ^[0-9]+$ ]] && harga=15000

    echo "$btoken" > "$BOT_TOKEN_FILE"
    echo "$chatid"  > "$CHAT_ID_FILE"
    chmod 600 "$BOT_TOKEN_FILE" "$CHAT_ID_FILE"
    cat > "$PAYMENT_FILE" << EOF
REK_NAME=${rname}
REK_NUMBER=${rnum}
REK_BANK=${rbank}
HARGA=${harga}
EOF
    chmod 600 "$PAYMENT_FILE"
    _install_bot_svc
    echo -e "\n  ${G}✓ Bot berhasil dikonfigurasi & dijalankan!${NC}"; sleep 2
}

_install_bot_svc(){
    mkdir -p /root/bot
    pip3 install requests --break-system-packages >/dev/null 2>&1

    cat > /root/bot/bot.py << 'BEOF'
#!/usr/bin/env python3
import os, time, subprocess
try: import requests
except: os.system('pip3 install requests --break-system-packages -q'); import requests

TOKEN  = open('/root/.bot_token').read().strip()
ADMIN  = int(open('/root/.chat_id').read().strip())
DOMAIN = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
API    = f'https://api.telegram.org/bot{TOKEN}'

PAY = {}
if os.path.exists('/root/.payment_info'):
    for line in open('/root/.payment_info'):
        if '=' in line:
            k,v = line.strip().split('=',1)
            PAY[k] = v

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
        send(cid, f'''👋 Halo <b>{name}</b>!

🤖 <b>VPN Manager Bot</b>
🌐 Server: <code>{DOMAIN}</code>

Gunakan perintah:
/list - Daftar semua akun
/status - Status server
/pay - Info pembayaran
/help - Bantuan''')

    elif text == '/help':
        send(cid, '''📖 <b>Daftar Perintah:</b>

/list - Daftar akun (SSH/VMess/VLess/Trojan)
/status - Status service server
/pay - Info rekening & harga
/order - Cara order VPN''')

    elif text == '/status':
        services = ['xray','nginx','haproxy','sshd','dropbear']
        lines = []
        for s in services:
            ret = subprocess.run(['systemctl','is-active',s], capture_output=True, text=True)
            st = '🟢' if ret.returncode==0 else '🔴'
            lines.append(f'{st} {s}')
        send(cid, '<b>Status Server:</b>\n' + '\n'.join(lines))

    elif text == '/pay':
        msg_pay = f'''💳 <b>Info Pembayaran:</b>

🏦 Bank/E-Wallet : {PAY.get("REK_BANK","?")}
👤 Nama         : {PAY.get("REK_NAME","?")}
🔢 No Rekening  : <code>{PAY.get("REK_NUMBER","?")}</code>
💰 Harga/bulan  : Rp {PAY.get("HARGA","?")}

Setelah transfer, kirim bukti ke admin.'''
        send(cid, msg_pay)

    elif text == '/order':
        send(cid, f'''🛒 <b>Cara Order VPN:</b>

1. Pilih paket (SSH/VMess/VLess/Trojan)
2. Transfer ke rekening di /pay
3. Kirim bukti transfer + username ke admin
4. Admin akan buat akun dalam 5 menit

📞 Admin: @ridhani16''')

    elif text == '/list':
        send(cid, list_accounts('ssh') + '\n\n' + list_accounts('vmess'))

    elif cid != ADMIN:
        send(cid, '⚠️ Hubungi admin untuk bantuan lebih lanjut.')

def main():
    print(f'Bot aktif | Domain: {DOMAIN}', flush=True)
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
#  SYSTEM TOOLS
# ═══════════════════════════════════════════════════════════════

fix_all_svc(){
    clear
    box_top " 🔧 FIX ALL SERVICES "
    box_empty
    box_sep_label "SERVICE"
    box_empty

    local fixed=0 failed=0 ok=0

    _fline(){
        local label="$1" result="$2" note="$3"
        case "$result" in
            OK)    printf "  ${G}[✓]${NC} %-28s ${G}OK${NC}    ${D}%s${NC}\n" "$label" "$note" ;;
            FIXED) printf "  ${Y}[↺]${NC} %-28s ${Y}FIXED${NC} ${D}%s${NC}\n" "$label" "$note" ;;
            FAIL)  printf "  ${R}[✗]${NC} %-28s ${R}FAIL${NC}  ${D}%s${NC}\n" "$label" "$note" ;;
            SKIP)  printf "  ${D}[~]${NC} %-28s ${D}SKIP${NC}  ${D}%s${NC}\n" "$label" "$note" ;;
        esac
    }

    local svcs=("xray" "nginx" "haproxy" "sshd" "dropbear" "udp-custom" "vpn-keepalive" "vpn-bot")
    local lbls=("Xray Core" "Nginx" "HAProxy" "SSH/OpenSSH" "Dropbear" "UDP Custom" "VPN Keepalive" "Telegram Bot")

    for i in "${!svcs[@]}"; do
        local s="${svcs[$i]}" l="${lbls[$i]}"
        if ! systemctl list-unit-files --quiet "${s}.service" 2>/dev/null | grep -q "$s"; then
            _fline "$l" "SKIP" "tidak terinstall"; continue
        fi
        if systemctl is-active --quiet "$s" 2>/dev/null; then
            _fline "$l" "OK" "berjalan"; ((ok++))
        else
            systemctl restart "$s" 2>/dev/null; sleep 1
            if systemctl is-active --quiet "$s" 2>/dev/null; then
                _fline "$l" "FIXED" "di-restart"; ((fixed++))
            else
                _fline "$l" "FAIL" "cek: journalctl -u $s"; ((failed++))
            fi
        fi
    done

    echo ""
    box_sep_label "SSL"
    echo ""
    if [[ -f /etc/xray/xray.crt ]]; then
        local expd=$(openssl x509 -enddate -noout -in /etc/xray/xray.crt 2>/dev/null | cut -d= -f2)
        local et=$(date -d "$expd" +%s 2>/dev/null)
        local dl=$(( (${et:-0} - $(date +%s)) / 86400 ))
        if [[ $dl -lt 0 ]]; then
            _fline "SSL Certificate" "FAIL" "expired ${dl}d lalu"
            openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
                -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
                -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null && \
                _fline "SSL Regenerate" "FIXED" "self-signed baru" && ((fixed++)) || ((failed++))
            systemctl restart xray 2>/dev/null
        elif [[ $dl -lt 7 ]]; then
            _fline "SSL Certificate" "FIXED" "${dl}d sisa, memperbarui"
            get_ssl >/dev/null; ((fixed++))
        else
            _fline "SSL Certificate" "OK" "${dl}d sisa"; ((ok++))
        fi
    else
        _fline "SSL Certificate" "FAIL" "tidak ditemukan"
        mkdir -p /etc/xray
        openssl req -x509 -newkey rsa:2048 -days 3650 -nodes \
            -subj "/C=ID/O=VPN/CN=${DOMAIN}" \
            -keyout /etc/xray/xray.key -out /etc/xray/xray.crt 2>/dev/null && \
            _fline "SSL Dibuat" "FIXED" "self-signed" && ((fixed++)) || ((failed++))
        systemctl restart xray 2>/dev/null
    fi

    echo ""
    box_sep_label "XRAY CONFIG"
    echo ""
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        _fline "Xray Config" "FAIL" "tidak ada"
        make_xray_config; _fline "Xray Config" "FIXED" "dibuat ulang"; ((fixed++))
        systemctl restart xray 2>/dev/null
    elif ! jq . "$XRAY_CONFIG" >/dev/null 2>&1; then
        _fline "Xray JSON" "FAIL" "JSON rusak!"
        make_xray_config; _fline "Xray Config" "FIXED" "dibuat ulang"; ((fixed++))
        systemctl restart xray 2>/dev/null
    else
        _fline "Xray Config JSON" "OK" "valid"; ((ok++))
        fix_xray_perm; _fline "Xray Permission" "OK" "fixed"
    fi

    echo ""
    box_sep_label "PORT"
    echo ""
    for port in 22 80 443; do
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            _fline "Port ${port}" "OK" "listening"; ((ok++))
        else
            _fline "Port ${port}" "FAIL" "tidak terbuka"; ((failed++))
        fi
    done

    echo ""
    box_sep_label "HASIL"
    printf "  ${G}✓ OK   : ${ok}${NC}   ${Y}↺ Fixed: ${fixed}${NC}   ${R}✗ Fail : ${failed}${NC}\n"
    echo ""
    if [[ $failed -eq 0 ]]; then
        echo -e "  ${G}✦ Semua service normal!${NC}"
    else
        echo -e "  ${R}✦ Ada ${failed} masalah yang perlu penanganan manual.${NC}"
    fi
    echo ""; read -rp "  Tekan Enter..."
}

change_domain(){
    load_domain
    clear
    box_top " GANTI DOMAIN "
    box_empty
    box_kv "Domain Saat Ini" "${C}${DOMAIN:-Belum set}${NC}"
    box_empty; box_bot; echo ""
    info "Memulai konfigurasi domain baru..."
    sleep 1
    setup_domain
    echo -e "\n  ${Y}⚠ Jalankan 'Fix SSL' setelah mengganti domain!${NC}"
    sleep 3
}

fix_ssl(){
    load_domain
    clear
    box_top " FIX / PERBARUI SSL "
    box_empty
    [[ -z "$DOMAIN" ]] && { box_row "  ${R}Domain belum dikonfigurasi!${NC}"; box_bot; sleep 3; return; }
    box_kv "Domain" "${C}${DOMAIN}${NC}"
    box_empty; box_bot; echo ""

    info "Menghentikan service..."
    systemctl stop haproxy nginx 2>/dev/null; sleep 1

    info "Memperbarui sertifikat SSL..."
    local stype=$(get_ssl)

    info "Memulai service..."
    systemctl start nginx haproxy 2>/dev/null
    systemctl restart xray 2>/dev/null

    echo -e "\n  ${G}✓ SSL diperbarui: ${stype}${NC}"; sleep 2
}

optimize_vps(){
    clear
    box_top " OPTIMASI VPS "
    box_empty
    info "Menerapkan optimasi kernel..."
    echo ""

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
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    sysctl -p /etc/sysctl.d/99-vpn.conf >/dev/null 2>&1

    _ok_step "BBR TCP Congestion Control"
    _ok_step "Socket buffer tuning"
    _ok_step "File descriptor limit 65535"
    _ok_step "IPv6 disabled"
    _ok_step "IP forwarding enabled"

    # Swap
    local swap=$(free -m | awk 'NR==3{print $2}')
    if [[ $swap -lt 512 ]]; then
        info "Membuat 2GB swapfile..."
        swapoff -a 2>/dev/null; rm -f /swapfile
        fallocate -l 2G /swapfile 2>/dev/null || \
            dd if=/dev/zero of=/swapfile bs=1M count=2048 2>/dev/null
        chmod 600 /swapfile; mkswap /swapfile >/dev/null 2>&1; swapon /swapfile
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
        _ok_step "Swapfile 2GB dibuat"
    else
        _skip_step "Swapfile (sudah ada: ${swap}MB)"
    fi

    echo ""; read -rp "  Tekan Enter..."
}

restart_all(){
    clear
    box_top " RESTART SEMUA SERVICE "
    box_empty

    systemctl daemon-reload 2>/dev/null
    for s in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive vpn-bot; do
        if systemctl restart "$s" 2>/dev/null; then
            box_status "$s" "ON"
        else
            box_status "$s" "OFF"
        fi
    done

    box_empty; box_bot; echo ""; sleep 2
}

speedtest_run(){
    clear
    box_top " SPEEDTEST "
    box_empty

    if ! command -v speedtest >/dev/null 2>&1; then
        box_row "  ${Y}Menginstall Speedtest CLI...${NC}"
        box_bot; echo ""
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
    else
        box_row "  ${Y}Testing... tunggu ~30 detik${NC}"
        box_bot; echo ""
    fi

    command -v speedtest >/dev/null 2>&1 && \
        speedtest --accept-license --accept-gdpr || \
        echo -e "  ${R}Speedtest tidak tersedia.${NC}"

    echo ""; read -rp "  Tekan Enter..."
}

update_script(){
    clear
    box_top " UPDATE SCRIPT "
    box_empty
    box_kv "Versi saat ini" "${G}${VER}${NC}"
    box_empty; box_bot; echo ""
    info "Memeriksa GitHub..."

    local latest
    latest=$(curl -s --max-time 10 "$VERSION_URL" 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$latest" ]]; then
        warn "Tidak dapat terhubung ke GitHub!"; sleep 2; return
    fi

    echo -e "  Latest: ${G}${latest}${NC}"; echo ""
    if [[ "$latest" == "$VER" ]]; then
        ok "Sudah versi terbaru!"; sleep 2; return
    fi

    echo -ne "  Update sekarang? [y/N]: "; read -r c
    [[ "$c" != "y" ]] && return

    cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak" 2>/dev/null
    local tmp="/tmp/tunnel_new.sh"
    curl -sL "$SCRIPT_URL" -o "$tmp"
    if bash -n "$tmp" 2>/dev/null; then
        mv "$tmp" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"
        ok "Update berhasil! Restart..."; sleep 2
        exec bash "$SCRIPT_PATH"
    else
        warn "File update tidak valid!"; rm -f "$tmp"; sleep 2
    fi
}

backup_sys(){
    clear
    box_top " BACKUP SISTEM "
    box_empty
    local bdir="/root/backups"
    local bfile="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$bdir"
    info "Membuat backup..."

    tar -czf "$bdir/$bfile" \
        /root/domain /root/.domain_type /root/akun \
        /root/.bot_token /root/.chat_id /root/.payment_info \
        /root/.menu_theme /etc/xray/ /usr/local/etc/xray/config.json \
        2>/dev/null

    if [[ -f "$bdir/$bfile" ]]; then
        clear
        box_top " ✓ BACKUP SELESAI "
        box_empty
        box_kv "File"   "${G}${bfile}${NC}"
        box_kv "Ukuran" "$(du -h "$bdir/$bfile" | awk '{print $1}')"
        box_kv "Lokasi" "${bdir}/"
        box_empty; box_bot
    else
        warn "Backup gagal!"
    fi
    echo ""; read -rp "  Tekan Enter..."
}

restore_sys(){
    clear
    box_top " RESTORE SISTEM "
    box_empty

    local bdir="/root/backups"
    if [[ ! -d "$bdir" ]]; then
        box_row "  ${R}Direktori backup tidak ditemukan!${NC}"
        box_bot; sleep 2; return
    fi

    shopt -s nullglob
    local bkps=($(ls -t "$bdir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob

    if [[ ${#bkps[@]} -eq 0 ]]; then
        box_row "  ${R}Tidak ada backup!${NC}"
        box_bot; sleep 2; return
    fi

    for f in "${bkps[@]}"; do
        local sz=$(du -h "$f" | awk '{print $1}')
        box_row "  ${C}•${NC} $(basename "$f")  ${D}(${sz})${NC}"
    done

    box_empty; box_bot; echo ""
    prompt_input "Nomor backup [1-${#bkps[@]}] (0=batal)"; read -r ch
    [[ "$ch" == "0" || ! "$ch" =~ ^[0-9]+$ ]] && return
    [[ $ch -lt 1 || $ch -gt ${#bkps[@]} ]] && return

    local sel="${bkps[$((ch-1))]}"
    echo -ne "\n  ${Y}⚠ Ini akan menimpa konfigurasi saat ini! Lanjutkan? [y/N]: ${NC}"
    read -r conf
    [[ "$conf" != "y" ]] && return

    info "Merestore..."
    tar -xzf "$sel" -C / 2>/dev/null && {
        ok "Restore berhasil!"
        systemctl restart xray nginx haproxy 2>/dev/null
    } || warn "Restore gagal!"

    echo ""; read -rp "  Tekan Enter..."
}

show_ports(){
    clear
    box_top " INFO PORT SERVER "
    box_empty
    box_sep_label "SSH"
    box_kv "OpenSSH"           "22"
    box_kv "Dropbear"          "222"
    box_sep_label "VMESS"
    box_kv "VMess WS TLS"      "8443  (via HAProxy 443)"
    box_kv "VMess WS HTTP"     "8880  (via Nginx 80)"
    box_kv "VMess gRPC"        "8444"
    box_sep_label "VLESS"
    box_kv "VLess WS TLS"      "8445  (via HAProxy)"
    box_kv "VLess WS HTTP"     "8881  (via Nginx 80)"
    box_kv "VLess gRPC"        "8446"
    box_sep_label "TROJAN"
    box_kv "Trojan WS TLS"     "8447  (via HAProxy)"
    box_kv "Trojan gRPC"       "8448"
    box_sep_label "WEB & UDP"
    box_kv "Nginx HTTP"        "80"
    box_kv "Nginx Download"    "81"
    box_kv "HAProxy TLS"       "443"
    box_kv "BadVPN UDP"        "7100-7300"
    box_sep_label "WS PATH"
    box_kv "VMess"   "/vmess"
    box_kv "VLess"   "/vless"
    box_kv "Trojan"  "/trojan"
    box_empty; box_bot
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  ADVANCED SETTINGS - FULLY FUNCTIONAL
# ═══════════════════════════════════════════════════════════════

adv_menu(){
    while true; do
        clear
        _theme_colors
        box_top " ⚙ ADVANCED SETTINGS "
        box_sep_label "JARINGAN"
        box_menu2 "1" "Manajemen Port SSH"    "2" "Ganti Port Nginx"   "🔌" "🔌"
        box_menu2 "3" "Restart Service"       "4" "Cek Port Aktif"     "🔄" "👁"
        box_sep_label "KEAMANAN"
        box_menu2 "5" "Fail2Ban"             "6" "UFW Firewall"        "🚧" "🔥"
        box_menu2 "7" "SSH Hardening"        "8" "Block IP"            "🔒" "🚫"
        box_sep_label "LOG & MONITOR"
        box_menu2 "9"  "Log Xray"            "10" "Log Nginx"          "📋" "📋"
        box_menu2 "11" "Log SSH"             "12" "Monitor Bandwidth"  "📋" "📊"
        box_sep_label "LAINNYA"
        box_menu "13" "Cron Jobs"                                      "⏰"
        box_menu "14" "User Limit System"                              "🔢"
        box_sep_label "─"
        box_menu "0"  "Kembali"                                        "◀"
        box_bot
        prompt_choice; read -r ch
        case "$ch" in
            1)  adv_ssh_port ;;
            2)  adv_nginx_port ;;
            3)  restart_all ;;
            4)  adv_check_ports ;;
            5)  adv_fail2ban ;;
            6)  adv_ufw ;;
            7)  adv_ssh_hardening ;;
            8)  adv_block_ip ;;
            9)  clear; tail -50 /var/log/xray/access.log 2>/dev/null || echo "No logs"; echo ""; read -rp "  Enter..." ;;
            10) clear; tail -50 /var/log/nginx/error.log 2>/dev/null || echo "No logs"; echo ""; read -rp "  Enter..." ;;
            11) clear; tail -50 /var/log/auth.log 2>/dev/null || echo "No logs"; echo ""; read -rp "  Enter..." ;;
            12) adv_bandwidth ;;
            13) adv_cron ;;
            14) adv_ulimit ;;
            0)  return ;;
        esac
    done
}

adv_ssh_port(){
    clear
    box_top " MANAJEMEN PORT SSH "
    box_empty
    local cur_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    local db_port=$(grep "^DROPBEAR_PORT=" /etc/default/dropbear 2>/dev/null | cut -d= -f2)
    box_kv "OpenSSH Port saat ini"  "${C}${cur_port:-22}${NC}"
    box_kv "Dropbear Port saat ini" "${C}${db_port:-222}${NC}"
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Ganti port OpenSSH"
    echo -e "  ${G}[2]${NC} Ganti port Dropbear"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
      1)
        prompt_input "Port baru OpenSSH (1024-65535)"; read -r np
        if [[ "$np" =~ ^[0-9]+$ ]] && [[ $np -ge 1024 ]] && [[ $np -le 65535 ]]; then
            sed -i "s/^#*Port .*/Port ${np}/" /etc/ssh/sshd_config
            grep -q "^Port " /etc/ssh/sshd_config || echo "Port ${np}" >> /etc/ssh/sshd_config
            systemctl restart sshd 2>/dev/null
            echo -e "\n  ${G}✓ OpenSSH port diganti ke ${np}${NC}"
            warn "Pastikan port ${np} terbuka di firewall sebelum logout!"
        else
            warn "Port tidak valid!"
        fi
        sleep 3
        ;;
      2)
        prompt_input "Port baru Dropbear (1024-65535)"; read -r np
        if [[ "$np" =~ ^[0-9]+$ ]] && [[ $np -ge 1024 ]] && [[ $np -le 65535 ]]; then
            sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=${np}/" /etc/default/dropbear
            systemctl restart dropbear 2>/dev/null
            echo -e "\n  ${G}✓ Dropbear port diganti ke ${np}${NC}"
        else
            warn "Port tidak valid!"
        fi
        sleep 2
        ;;
    esac
}

adv_nginx_port(){
    clear
    box_top " GANTI PORT NGINX "
    box_empty
    local cur80=$(grep "listen 80" /etc/nginx/sites-available/default 2>/dev/null | head -1)
    local cur81=$(grep "listen 81" /etc/nginx/sites-available/default 2>/dev/null | head -1)
    box_row "  ${D}Port 80: HTTP/WS proxy${NC}"
    box_row "  ${D}Port 81: File download${NC}"
    box_empty
    box_row "  ${Y}⚠ Mengganti port Nginx dapat memutus koneksi!${NC}"
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Ganti port download (81)"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    if [[ "$ch" == "1" ]]; then
        prompt_input "Port download baru (default 81)"; read -r np
        if [[ "$np" =~ ^[0-9]+$ ]] && [[ $np -ge 1024 ]] && [[ $np -le 65535 ]]; then
            sed -i "s/listen 81;/listen ${np};/" /etc/nginx/sites-available/default
            nginx -t >/dev/null 2>&1 && systemctl reload nginx 2>/dev/null && \
                echo -e "\n  ${G}✓ Port download diganti ke ${np}${NC}" || \
                { sed -i "s/listen ${np};/listen 81;/" /etc/nginx/sites-available/default
                  warn "Nginx config error! Dikembalikan ke 81."; }
        else
            warn "Port tidak valid!"
        fi
        sleep 2
    fi
}

adv_check_ports(){
    clear
    box_top " PORT AKTIF (LISTENING) "
    box_empty
    local ports=(22 80 81 222 443 7100 8080 8443 8444 8445 8446 8447 8448 8880 8881)
    for p in "${ports[@]}"; do
        if ss -tlnp 2>/dev/null | grep -q ":${p} "; then
            box_row "  ${G}●${NC} Port ${p} ${D}← listening${NC}"
        else
            box_row "  ${D}○${NC} Port ${p} ${D}← tertutup${NC}"
        fi
    done
    box_empty; box_bot; echo ""; read -rp "  Tekan Enter..."
}

adv_fail2ban(){
    clear
    box_top " FAIL2BAN "
    box_empty

    if ! command -v fail2ban-client >/dev/null 2>&1; then
        box_row "  ${Y}Fail2Ban belum terinstall.${NC}"
        box_empty; box_bot; echo ""
        echo -ne "  Install Fail2Ban? [y/N]: "; read -r c
        [[ "$c" != "y" ]] && return
        apt-get update >/dev/null 2>&1
        apt-get install -y fail2ban >/dev/null 2>&1
        systemctl enable fail2ban >/dev/null 2>&1
        systemctl start fail2ban 2>/dev/null
        ok "Fail2Ban terinstall!"
        sleep 2; adv_fail2ban; return
    fi

    box_status "Fail2Ban" "$(chk fail2ban)"
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Status jails"
    echo -e "  ${G}[2]${NC} Banned IPs"
    echo -e "  ${G}[3]${NC} Unban IP"
    echo -e "  ${G}[4]${NC} Restart Fail2Ban"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
        1) clear; fail2ban-client status 2>/dev/null; echo ""; read -rp "  Enter..." ;;
        2) clear; fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | head -20 || echo "No banned IPs"; echo ""; read -rp "  Enter..." ;;
        3) prompt_input "IP yang di-unban"; read -r ip
           fail2ban-client unban "$ip" 2>/dev/null && ok "IP ${ip} di-unban!" || warn "Gagal!"
           sleep 2 ;;
        4) systemctl restart fail2ban 2>/dev/null && ok "Fail2Ban restarted!" || warn "Gagal!"
           sleep 2 ;;
    esac
}

adv_ufw(){
    clear
    box_top " UFW FIREWALL "
    box_empty

    if ! command -v ufw >/dev/null 2>&1; then
        box_row "  ${Y}UFW belum terinstall.${NC}"
        box_empty; box_bot; echo ""
        echo -ne "  Install & konfigurasi UFW? [y/N]: "; read -r c
        if [[ "$c" == "y" ]]; then
            apt-get install -y ufw >/dev/null 2>&1
            ufw --force reset >/dev/null 2>&1
            ufw default deny incoming >/dev/null 2>&1
            ufw default allow outgoing >/dev/null 2>&1
            for p in 22 80 81 222 443 8443 8444 8445 8446 8447 8448 8880 8881; do
                ufw allow "$p/tcp" >/dev/null 2>&1
            done
            ufw allow 7100:7300/udp >/dev/null 2>&1
            ufw allow 7100:7300/tcp >/dev/null 2>&1
            ufw --force enable >/dev/null 2>&1
            ok "UFW terkonfigurasi!"
        fi
        sleep 2; return
    fi

    box_status "UFW" "$( ufw status 2>/dev/null | grep -q "Status: active" && echo "ON" || echo "OFF" )"
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Status rules"
    echo -e "  ${G}[2]${NC} Tambah rule (allow port)"
    echo -e "  ${G}[3]${NC} Hapus rule (deny port)"
    echo -e "  ${G}[4]${NC} Enable UFW"
    echo -e "  ${G}[5]${NC} Disable UFW"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
        1) clear; ufw status numbered 2>/dev/null; echo ""; read -rp "  Enter..." ;;
        2) prompt_input "Port/proto (contoh: 8080/tcp)"; read -r rule
           ufw allow "$rule" 2>/dev/null && ok "Rule ditambah!" || warn "Gagal!"
           sleep 2 ;;
        3) prompt_input "Nomor rule (dari status numbered)"; read -r rnum
           echo "y" | ufw delete "$rnum" 2>/dev/null && ok "Rule dihapus!" || warn "Gagal!"
           sleep 2 ;;
        4) ufw --force enable 2>/dev/null && ok "UFW enabled!" || warn "Gagal!"; sleep 2 ;;
        5) ufw --force disable 2>/dev/null && ok "UFW disabled!" || warn "Gagal!"; sleep 2 ;;
    esac
}

adv_ssh_hardening(){
    clear
    box_top " SSH HARDENING "
    box_empty
    local cfg="/etc/ssh/sshd_config"
    box_kv "Max Auth Tries" "$(grep "^MaxAuthTries" $cfg 2>/dev/null | awk '{print $2}' || echo "default")"
    box_kv "Root Login"     "$(grep "^PermitRootLogin" $cfg 2>/dev/null | awk '{print $2}' || echo "default")"
    box_kv "Password Auth"  "$(grep "^PasswordAuthentication" $cfg 2>/dev/null | awk '{print $2}' || echo "default")"
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Set MaxAuthTries (brute-force protection)"
    echo -e "  ${G}[2]${NC} Nonaktifkan Root Login"
    echo -e "  ${G}[3]${NC} Aktifkan Root Login"
    echo -e "  ${G}[4]${NC} Lihat failed login attempts"
    echo -e "  ${G}[5]${NC} Blokir user tertentu dari SSH"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
        1) prompt_input "MaxAuthTries [3-6]"; read -r mat
           [[ ! "$mat" =~ ^[3-6]$ ]] && mat=3
           grep -q "^MaxAuthTries" "$cfg" && \
               sed -i "s/^MaxAuthTries.*/MaxAuthTries $mat/" "$cfg" || \
               echo "MaxAuthTries $mat" >> "$cfg"
           systemctl restart sshd 2>/dev/null
           ok "MaxAuthTries diset ke $mat"; sleep 2 ;;
        2) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$cfg"
           grep -q "^PermitRootLogin" "$cfg" || echo "PermitRootLogin no" >> "$cfg"
           systemctl restart sshd 2>/dev/null; ok "Root login dinonaktifkan!"; sleep 2 ;;
        3) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$cfg"
           grep -q "^PermitRootLogin" "$cfg" || echo "PermitRootLogin yes" >> "$cfg"
           systemctl restart sshd 2>/dev/null; warn "Root login diaktifkan!"; sleep 2 ;;
        4) clear; grep "Failed password" /var/log/auth.log 2>/dev/null | tail -30 || echo "No data"
           echo ""; read -rp "  Enter..." ;;
        5) prompt_input "Username yang diblokir"; read -r buser
           grep -q "^DenyUsers" "$cfg" && \
               sed -i "s/^DenyUsers.*/& $buser/" "$cfg" || \
               echo "DenyUsers $buser" >> "$cfg"
           systemctl restart sshd 2>/dev/null; ok "User $buser diblokir dari SSH!"; sleep 2 ;;
    esac
}

adv_block_ip(){
    clear
    box_top " BLOKIR IP "
    box_empty
    local blocked=$(iptables -L INPUT -n 2>/dev/null | grep DROP | awk '{print $4}' | head -10)
    if [[ -n "$blocked" ]]; then
        box_sep_label "IP DIBLOKIR"
        while IFS= read -r ip; do
            [[ -n "$ip" ]] && box_row "  ${R}✗${NC} ${ip}"
        done <<< "$blocked"
    else
        box_row "  ${D}Tidak ada IP yang diblokir.${NC}"
    fi
    box_empty; box_bot; echo ""
    echo -e "  ${G}[1]${NC} Blokir IP"
    echo -e "  ${G}[2]${NC} Buka blokir IP"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
        1) prompt_input "IP yang diblokir"; read -r bip
           iptables -I INPUT -s "$bip" -j DROP 2>/dev/null && ok "IP ${bip} diblokir!" || warn "Gagal!"
           sleep 2 ;;
        2) prompt_input "IP yang dibuka"; read -r uip
           iptables -D INPUT -s "$uip" -j DROP 2>/dev/null && ok "IP ${uip} dibuka!" || warn "Gagal!"
           sleep 2 ;;
    esac
}

adv_bandwidth(){
    clear
    box_top " MONITOR BANDWIDTH "
    box_empty
    if command -v vnstat >/dev/null 2>&1; then
        box_bot; echo ""
        vnstat 2>/dev/null
    else
        box_row "  ${Y}vnStat belum terinstall.${NC}"
        box_empty; box_bot; echo ""
        echo -ne "  Install vnStat? [y/N]: "; read -r c
        if [[ "$c" == "y" ]]; then
            apt-get install -y vnstat >/dev/null 2>&1
            systemctl enable vnstat 2>/dev/null; systemctl start vnstat 2>/dev/null
            ok "vnStat terinstall. Data muncul dalam 5 menit."
        fi
    fi
    echo ""; read -rp "  Tekan Enter..."
}

adv_cron(){
    clear
    box_top " CRON JOBS "
    box_empty; box_bot; echo ""
    echo -e "  ${D}Cron jobs aktif:${NC}"
    crontab -l 2>/dev/null || echo "  Tidak ada cron job."
    echo ""
    echo -e "  ${G}[1]${NC} Tambah auto-backup harian (02:00)"
    echo -e "  ${G}[2]${NC} Tambah auto-hapus expired (setiap jam)"
    echo -e "  ${G}[3]${NC} Hapus semua cron VPN"
    echo -e "  ${G}[0]${NC} Batal"
    prompt_choice; read -r ch

    case "$ch" in
        1) (crontab -l 2>/dev/null | grep -v "vpn_backup"; echo "0 2 * * * /root/tunnel.sh backup_auto") | crontab -
           ok "Auto-backup harian aktif (02:00)!"; sleep 2 ;;
        2) (crontab -l 2>/dev/null | grep -v "vpn_expire"; echo "0 * * * * bash /root/tunnel.sh expire_auto") | crontab -
           ok "Auto-hapus expired tiap jam aktif!"; sleep 2 ;;
        3) crontab -l 2>/dev/null | grep -Ev "vpn_backup|vpn_expire" | crontab -
           ok "Cron VPN dihapus."; sleep 2 ;;
    esac
}

adv_ulimit(){
    clear
    box_top " USER LIMIT SYSTEM "
    box_empty; box_bot; echo ""
    echo -e "  ${D}Limit saat ini:${NC}"
    cat /etc/security/limits.d/99-vpn.conf 2>/dev/null || echo "  File tidak ada."
    echo ""
    echo -e "  ${D}ulimit -n (file descriptors):${NC} $(ulimit -n 2>/dev/null)"
    echo ""
    echo -ne "  Terapkan ulang limit 65535? [y/N]: "; read -r c
    if [[ "$c" == "y" ]]; then
        cat > /etc/security/limits.d/99-vpn.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
        ok "Limit diterapkan! Efektif setelah relogin."; sleep 2
    fi
}

# ═══════════════════════════════════════════════════════════════
#  UNINSTALL
# ═══════════════════════════════════════════════════════════════

uninstall_menu(){
    while true; do
        clear
        _theme_colors
        box_top " HAPUS KOMPONEN "
        box_empty
        box_menu "1" "Uninstall Xray"       "📡"
        box_menu "2" "Uninstall Nginx"      "🌐"
        box_menu "3" "Uninstall HAProxy"    "⚖"
        box_menu "4" "Uninstall Dropbear"   "🔐"
        box_menu "5" "Uninstall UDP Custom" "📶"
        box_menu "6" "Uninstall Bot"        "🤖"
        box_menu "7" "Uninstall Keepalive"  "💓"
        box_empty
        box_sep_label "BERBAHAYA"
        box_menu "99" "HAPUS SEMUA KOMPONEN"   "💥"
        box_sep_label "─"
        box_menu "0" "Kembali"               "◀"
        box_bot
        prompt_choice; read -r ch

        _confirm(){ echo -ne "\n  ${Y}Yakin? [y/N]: ${NC}"; read -r c; [[ "$c" == "y" ]]; }

        case "$ch" in
            1) _confirm && { systemctl stop xray 2>/dev/null; systemctl disable xray 2>/dev/null
               bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
               rm -rf /usr/local/etc/xray /var/log/xray /etc/xray
               ok "Xray dihapus!"; sleep 2; } ;;
            2) _confirm && { apt-get purge -y nginx nginx-common >/dev/null 2>&1; ok "Nginx dihapus!"; sleep 2; } ;;
            3) _confirm && { apt-get purge -y haproxy >/dev/null 2>&1; ok "HAProxy dihapus!"; sleep 2; } ;;
            4) _confirm && { apt-get purge -y dropbear >/dev/null 2>&1; ok "Dropbear dihapus!"; sleep 2; } ;;
            5) _confirm && { systemctl stop udp-custom 2>/dev/null
               rm -f /etc/systemd/system/udp-custom.service /usr/local/bin/udp-custom
               systemctl daemon-reload; ok "UDP Custom dihapus!"; sleep 2; } ;;
            6) _confirm && { systemctl stop vpn-bot 2>/dev/null
               rm -f /etc/systemd/system/vpn-bot.service; rm -rf /root/bot
               rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"
               systemctl daemon-reload; ok "Bot dihapus!"; sleep 2; } ;;
            7) _confirm && { systemctl stop vpn-keepalive 2>/dev/null
               rm -f /etc/systemd/system/vpn-keepalive.service /usr/local/bin/vpn-keepalive.sh
               systemctl daemon-reload; ok "Keepalive dihapus!"; sleep 2; } ;;
            99)
                clear
                echo -e "\n  ${R}${BG}  !! HAPUS SEMUA KOMPONEN !!  ${NC}"
                echo -e "\n  ${Y}Semua data, akun, dan service akan dihapus!${NC}"
                echo -ne "\n  Ketik 'HAPUS' untuk konfirmasi: "; read -r conf
                [[ "$conf" != "HAPUS" ]] && { warn "Dibatalkan."; sleep 2; continue; }
                echo ""
                for s in xray nginx haproxy dropbear udp-custom vpn-keepalive vpn-bot; do
                    systemctl stop "$s" 2>/dev/null; systemctl disable "$s" 2>/dev/null
                    echo -e "  ${R}✗${NC} Stopped $s"
                done
                bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
                apt-get purge -y nginx haproxy dropbear >/dev/null 2>&1
                apt-get autoremove -y >/dev/null 2>&1
                rm -rf /root/akun /root/bot /root/orders /root/domain \
                       /root/.domain_type /root/.bot_token /root/.chat_id \
                       /root/.payment_info /root/.menu_theme /root/backups \
                       /usr/local/etc/xray /var/log/xray /etc/xray
                rm -f /etc/systemd/system/{udp-custom,vpn-keepalive,vpn-bot}.service \
                      /usr/local/bin/{udp-custom,vpn-keepalive.sh,menu} /root/tunnel.sh
                sed -i '/tunnel.sh/d' /root/.bashrc 2>/dev/null
                systemctl daemon-reload
                echo -e "\n  ${G}✓ Semua komponen dihapus.${NC}\n"
                sleep 3; exit 0 ;;
            0) return ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
#  SETUP KEEPALIVE & UDP
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

    mkdir -p /etc/systemd/system/xray.service.d
    cat > /etc/systemd/system/xray.service.d/override.conf << 'EOF'
[Service]
Restart=always
RestartSec=3
LimitNOFILE=65535
EOF

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
    systemctl daemon-reload
    systemctl enable vpn-keepalive 2>/dev/null
    systemctl restart vpn-keepalive 2>/dev/null
}

setup_udp(){
    cat > /usr/local/bin/udp-custom << 'EOF'
#!/usr/bin/env python3
import socket, threading, select, time
PORTS = range(7100, 7301); SSH_HOST = '127.0.0.1'; SSH_PORT = 22; BUF = 8192
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
print(f'UDP: {len(sockets)} ports', flush=True)
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
    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom 2>/dev/null
}

setup_menu_cmd(){
    cat > /usr/local/bin/menu << 'EOF'
#!/bin/bash
[[ -f /root/tunnel.sh ]] && bash /root/tunnel.sh || echo "Script tidak ditemukan!"
EOF
    chmod +x /usr/local/bin/menu
    grep -q "tunnel.sh" /root/.bashrc 2>/dev/null || cat >> /root/.bashrc << 'EOF'

clear
echo -e "\033[1;36m  Ketik 'menu' untuk membuka VPN Manager\033[0m"
EOF
}

# ═══════════════════════════════════════════════════════════════
#  SMART INSTALLER
# ═══════════════════════════════════════════════════════════════

smart_install(){
    show_install_banner
    echo -ne "  ${C}Tekan Enter untuk memulai instalasi...${NC}"; read -r
    setup_domain
    [[ -z "$DOMAIN" ]] && die "Domain tidak dikonfigurasi!"
    select_theme

    local dtype=$(cat "$DOMAIN_TYPE_FILE" 2>/dev/null || echo "random")
    local ip=$(get_ip)
    local ssl_label="Self-Signed"
    [[ "$dtype" == "custom" ]] && ssl_label="Let's Encrypt"

    clear
    show_install_banner
    echo -e "  ${W}Domain  :${NC} ${G}${DOMAIN}${NC}"
    echo -e "  ${W}SSL     :${NC} ${G}${ssl_label}${NC}"
    echo -e "  ${W}Tema    :${NC} ${G}$(get_theme | tr a-z A-Z)${NC}"
    echo -e "  ${W}IP VPS  :${NC} ${G}${ip}${NC}"
    echo ""
    sleep 2

    local LOG="/tmp/vpn_install_$(date +%s).log"
    > "$LOG"

    # ─ STEP 1 ──────────────────────────────────────────────────
    _step_banner 1 10 "SYSTEM UPDATE"
    _run_step "Update package list"
    apt-get update -y >> "$LOG" 2>&1 && printf " ${G}OK${NC}\n" || printf " ${Y}warn${NC}\n"
    _run_step "Upgrade packages"
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG" 2>&1 && printf " ${G}OK${NC}\n" || printf " ${Y}skip${NC}\n"

    # ─ STEP 2 ──────────────────────────────────────────────────
    _step_banner 2 10 "BASE PACKAGES"
    local pkgs=(curl wget unzip uuid-runtime net-tools openssl jq
        python3 python3-pip gnupg2 ca-certificates lsb-release
        apt-transport-https software-properties-common qrencode)
    for p in "${pkgs[@]}"; do _pkg_install "$p"; done

    # ─ STEP 3 ──────────────────────────────────────────────────
    _step_banner 3 10 "VPN SERVICES"
    if command -v xray >/dev/null 2>&1; then
        _skip_step "Xray-core"
    else
        _run_step "Xray-core"
        bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
            >> "$LOG" 2>&1 && printf " ${G}OK${NC}\n" || printf " ${R}FAIL${NC}\n"
    fi
    _pkg_install "nginx"       "Nginx Web Server"
    _pkg_install "openssh-server" "OpenSSH Server"
    _pkg_install "dropbear"   "Dropbear SSH"
    _pkg_install "haproxy"    "HAProxy"
    _pkg_install "stunnel4"   "Stunnel4"
    _pkg_install "certbot"    "Certbot (Let's Encrypt)"
    _pkg_install "netcat-openbsd" "Netcat"

    # ─ STEP 4 ──────────────────────────────────────────────────
    _step_banner 4 10 "SECURITY TOOLS"
    _pkg_install "fail2ban"   "Fail2Ban"
    systemctl enable fail2ban >> "$LOG" 2>&1
    systemctl start  fail2ban >> "$LOG" 2>&1

    _pkg_install "ufw"        "UFW Firewall"
    ufw --force reset    >> "$LOG" 2>&1
    ufw default deny incoming >> "$LOG" 2>&1
    ufw default allow outgoing >> "$LOG" 2>&1
    for p in 22 80 81 222 443 8443 8444 8445 8446 8447 8448 8880 8881; do
        ufw allow "$p/tcp" >> "$LOG" 2>&1
    done
    ufw allow 7100:7300/tcp >> "$LOG" 2>&1
    ufw allow 7100:7300/udp >> "$LOG" 2>&1
    ufw --force enable >> "$LOG" 2>&1
    _ok_step "UFW configured"

    _pkg_install "vnstat"     "vnStat Bandwidth Monitor"
    systemctl enable vnstat >> "$LOG" 2>&1
    systemctl start  vnstat >> "$LOG" 2>&1

    # ─ STEP 5 ──────────────────────────────────────────────────
    _step_banner 5 10 "SYSTEM OPTIMIZATION"
    modprobe tcp_bbr 2>/dev/null; echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
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
    sysctl -p /etc/sysctl.d/99-vpn.conf >> "$LOG" 2>&1
    _ok_step "BBR + TCP optimization"

    cat > /etc/security/limits.d/99-vpn.conf << 'EOF'
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
    _ok_step "File descriptor limit 65535"

    local swap=$(free -m | awk 'NR==3{print $2}')
    if [[ $swap -lt 512 ]]; then
        _run_step "Swapfile 2GB"
        fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 >> "$LOG" 2>&1
        chmod 600 /swapfile; mkswap /swapfile >> "$LOG" 2>&1; swapon /swapfile
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
        printf " ${G}OK${NC}\n"
    else
        _skip_step "Swapfile (ada: ${swap}MB)"
    fi

    # ─ STEP 6 ──────────────────────────────────────────────────
    _step_banner 6 10 "SSL CERTIFICATE"
    mkdir -p /etc/xray
    _run_step "SSL Certificate"
    local stype=$(get_ssl)
    printf " ${G}%s${NC}\n" "$stype"

    # ─ STEP 7 ──────────────────────────────────────────────────
    _step_banner 7 10 "SERVICE CONFIGURATION"
    _run_step "Xray config (8 inbounds, no port conflict)"
    make_xray_config && printf " ${G}OK${NC}\n" || printf " ${R}FAIL${NC}\n"

    _run_step "Nginx (HTTP proxy + download)"
    cat > /etc/nginx/sites-available/default << NGEOF
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    location / { try_files \$uri \$uri/ =404; autoindex on; }
    location /vmess  { proxy_pass http://127.0.0.1:8880; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 86400s; }
    location /vless  { proxy_pass http://127.0.0.1:8881; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 86400s; }
    location /trojan { proxy_pass http://127.0.0.1:8881; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; proxy_read_timeout 86400s; }
}
server {
    listen 81;
    server_name _;
    root /var/www/html;
    autoindex on;
}
NGEOF
    printf " ${G}OK${NC}\n"

    _run_step "Dropbear (port 222)"
    cat > /etc/default/dropbear << 'EOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
    printf " ${G}OK${NC}\n"

    _run_step "HAProxy (443 → VMess 8443)"
    cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    maxconn 65535
    tune.ssl.default-dh-param 2048
defaults
    log global
    mode tcp
    option tcplog
    timeout connect 5s
    timeout client 1h
    timeout server 1h
    maxconn 65535
frontend front_443
    bind *:443
    mode tcp
    default_backend back_xray
backend back_xray
    mode tcp
    server xray 127.0.0.1:8443 check
EOF
    printf " ${G}OK${NC}\n"

    # ─ STEP 8 ──────────────────────────────────────────────────
    _step_banner 8 10 "ADDITIONAL SERVICES"
    _run_step "UDP Custom (port 7100-7300)"
    setup_udp && printf " ${G}OK${NC}\n" || printf " ${R}FAIL${NC}\n"

    _run_step "VPN Keepalive"
    setup_keepalive && printf " ${G}OK${NC}\n" || printf " ${R}FAIL${NC}\n"

    _run_step "Menu command"
    setup_menu_cmd && printf " ${G}OK${NC}\n"

    # ─ STEP 9 ──────────────────────────────────────────────────
    _step_banner 9 10 "WEB INTERFACE"
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/index.html" << HTMLEOF
<!DOCTYPE html><html><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>VPN Server | ${DOMAIN}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;background:#0a0a0a;color:#00ff88;min-height:100vh;
     display:flex;align-items:center;justify-content:center}
.card{border:1px solid #00ff88;padding:40px;max-width:480px;width:100%;
      box-shadow:0 0 20px rgba(0,255,136,.3)}
h1{font-size:1.8em;letter-spacing:4px;margin-bottom:20px;color:#00d4ff}
.info{margin:8px 0;opacity:.8;font-size:.9em}
.badge{margin-top:24px;border:1px solid #00ff88;padding:8px 16px;display:inline-block;
       color:#00ff88;letter-spacing:2px;font-size:.8em}
</style></head><body><div class="card">
<h1>VPN SERVER</h1>
<div class="info">Domain  : ${DOMAIN}</div>
<div class="info">IP      : ${ip}</div>
<div class="info">Version : ${VER}</div>
<div class="badge">● ONLINE</div>
</div></body></html>
HTMLEOF
    _ok_step "Web interface"

    # ─ STEP 10 ─────────────────────────────────────────────────
    _step_banner 10 10 "START SERVICES"
    systemctl daemon-reload >> "$LOG" 2>&1
    for s in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive; do
        systemctl enable  "$s" >> "$LOG" 2>&1
        systemctl restart "$s" >> "$LOG" 2>&1
        if systemctl is-active --quiet "$s" 2>/dev/null; then
            _ok_step "$s"
        else
            _fail_step "$s"
        fi
    done

    # ─ SELESAI ─────────────────────────────────────────────────
    clear
    show_install_banner
    echo -e "${G}  ┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${G}  │                  ✓  INSTALASI SELESAI!                          │${NC}"
    echo -e "${G}  └──────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    printf "  ${W}%-18s${NC}: ${G}%s${NC}\n" "Domain"      "$DOMAIN"
    printf "  ${W}%-18s${NC}: ${G}%s${NC}\n" "IP VPS"       "$ip"
    printf "  ${W}%-18s${NC}: ${G}%s${NC}\n" "SSL"          "$ssl_label"
    printf "  ${W}%-18s${NC}: ${G}%s${NC}\n" "Tema"         "$(get_theme | tr a-z A-Z)"
    echo ""
    printf "  ${C}%-18s${NC}: %s\n" "SSH"        "22  |  Dropbear: 222"
    printf "  ${C}%-18s${NC}: %s\n" "VMess"      "8443/8880/8444 (TLS/HTTP/gRPC)"
    printf "  ${C}%-18s${NC}: %s\n" "VLess"      "8445/8881/8446 (TLS/HTTP/gRPC)"
    printf "  ${C}%-18s${NC}: %s\n" "Trojan"     "8447/8448 (TLS/gRPC)"
    printf "  ${C}%-18s${NC}: %s\n" "HAProxy"    "443 → 8443"
    printf "  ${C}%-18s${NC}: %s\n" "BadVPN UDP" "7100-7300"
    printf "  ${C}%-18s${NC}: %s\n" "Web Panel"  "http://${ip}:81/"
    echo ""
    echo -e "  ${Y}💡 Ketik '${W}menu${Y}' untuk membuka VPN Manager!${NC}"
    echo -e "  ${D}Log: ${LOG}${NC}"
    echo ""
    echo -e "  ${Y}Reboot dalam 5 detik...${NC}"
    sleep 5
    reboot
}

# ═══════════════════════════════════════════════════════════════
#  HELP
# ═══════════════════════════════════════════════════════════════

show_help(){
    clear
    box_top " PANDUAN MENU "
    box_empty
    box_sep_label "AKUN"
    box_row "  ${C}1-4${NC}  Menu SSH / VMess / VLess / Trojan"
    box_row "  ${C}5${NC}    Generator akun trial 1 jam"
    box_row "  ${C}6${NC}    Lihat semua akun aktif"
    box_row "  ${C}7-8${NC}  Cek / hapus akun expired"
    box_sep_label "SISTEM"
    box_row "  ${C}9${NC}    Setup & kelola Telegram Bot"
    box_row "  ${C}10${NC}   Ganti domain VPN"
    box_row "  ${C}11${NC}   Fix/perbarui SSL certificate"
    box_row "  ${C}12${NC}   Optimasi VPS (BBR, swap, limit)"
    box_row "  ${C}13${NC}   Restart semua service"
    box_row "  ${C}14${NC}   Fix all services (auto-repair)"
    box_row "  ${C}15${NC}   Speedtest Ookla"
    box_row "  ${C}16${NC}   Update script dari GitHub"
    box_row "  ${C}17-18${NC} Backup & restore konfigurasi"
    box_row "  ${C}19${NC}   Info port & path"
    box_sep_label "LAINNYA"
    box_row "  ${C}20${NC}   Hapus komponen VPN"
    box_row "  ${C}21${NC}   Ganti tema tampilan"
    box_row "  ${C}99${NC}   Advanced settings (14 submenu)"
    box_row "  ${C}0${NC}    Keluar"
    box_empty
    box_bot
    echo ""; read -rp "  Tekan Enter..."
}

# ═══════════════════════════════════════════════════════════════
#  MAIN LOOP
# ═══════════════════════════════════════════════════════════════

main(){
    check_root
    mkdir -p "$AKUN_DIR" /root/orders
    load_domain

    # First install
    if [[ ! -f "$DOMAIN_FILE" ]]; then
        smart_install
        return
    fi

    setup_menu_cmd

    while true; do
        show_dashboard
        show_main_menu
        prompt_choice; read -r choice

        case "$choice" in
            1)  ssh_menu ;;
            2)  xray_menu "vmess" ;;
            3)  xray_menu "vless" ;;
            4)  xray_menu "trojan" ;;
            5)  trial_menu ;;
            6)  list_all ;;
            7)  check_expired ;;
            8)  delete_expired ;;
            9)  bot_menu ;;
            10) change_domain ;;
            11) fix_ssl ;;
            12) optimize_vps ;;
            13) restart_all ;;
            14) fix_all_svc ;;
            15) speedtest_run ;;
            16) update_script ;;
            17) backup_sys ;;
            18) restore_sys ;;
            19) show_ports ;;
            20) uninstall_menu ;;
            21) select_theme ;;
            99) adv_menu ;;
            0)  clear; echo -e "\n  ${C}Sampai jumpa!${NC}\n"; exit 0 ;;
            help|HELP) show_help ;;
            backup_auto) backup_sys ;;
            expire_auto) delete_expired ;;
            *) ;;
        esac
    done
}

main "$@"
