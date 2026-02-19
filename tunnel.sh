#!/bin/bash

#================================================
# VPN Auto Script v3.1 - FIXED & ENHANCED
# By The Proffessor Squad
# GitHub: putrinuroktavia234-max/Tunnel
#================================================

# NOTE: Removed strict set -euo pipefail from global scope
# to prevent installer from exiting on non-critical errors.
# Each critical section handles errors manually.

# Colors - PROPER ESCAPE
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
BLUE='\e[0;34m'
CYAN='\e[0;36m'
MAGENTA='\e[0;35m'
WHITE='\e[1;37m'
BOLD='\e[1m'
DIM='\e[2m'
NC='\e[0m'

# Background colors
BG_CYAN='\e[46m'
BG_BLUE='\e[44m'
BG_GREEN='\e[42m'
BG_RED='\e[41m'
BG_YELLOW='\e[43m'
BG_MAGENTA='\e[45m'

# Variables
DOMAIN=""
DOMAIN_FILE="/root/domain"
AKUN_DIR="/root/akun"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
SCRIPT_VERSION="3.1.0"
SCRIPT_AUTHOR="By The Proffessor Squad"
GITHUB_USER="putrinuroktavia234-max"
GITHUB_REPO="Tunnel"
GITHUB_BRANCH="main"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/tunnel.sh"
VERSION_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/version"
SCRIPT_PATH="/root/tunnel.sh"
BACKUP_PATH="/root/tunnel.sh.bak"
PUBLIC_HTML="/var/www/html"
BOT_TOKEN_FILE="/root/.bot_token"
CHAT_ID_FILE="/root/.chat_id"
ORDER_DIR="/root/orders"
PAYMENT_FILE="/root/.payment_info"
DOMAIN_TYPE_FILE="/root/.domain_type"
THEME_FILE="/root/.menu_theme"

# Box width constant
BOX_WIDTH=66

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
        if [[ -n "$ip" ]] && [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return
        fi
    done
    ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')
    echo "${ip:-N/A}"
}

is_installed() {
    local package="$1"
    case "$package" in
        "xray") command -v xray >/dev/null 2>&1 ;;
        "nginx") command -v nginx >/dev/null 2>&1 ;;
        "stunnel4") command -v stunnel4 >/dev/null 2>&1 ;;
        "dropbear") command -v dropbear >/dev/null 2>&1 ;;
        "haproxy") command -v haproxy >/dev/null 2>&1 ;;
        "fail2ban") command -v fail2ban-client >/dev/null 2>&1 ;;
        "certbot") command -v certbot >/dev/null 2>&1 ;;
        "unbound") command -v unbound >/dev/null 2>&1 ;;
        "vnstat") command -v vnstat >/dev/null 2>&1 ;;
        "netdata") systemctl is-active --quiet netdata 2>/dev/null ;;
        "bbr") sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -q bbr ;;
        "swap") [[ $(free -m | awk 'NR==3{print $2}') -gt 0 ]] ;;
        "ufw") command -v ufw >/dev/null 2>&1 ;;
        *) command -v "$package" >/dev/null 2>&1 ;;
    esac
}

send_telegram_admin() {
    [[ ! -f "$BOT_TOKEN_FILE" ]] && return
    [[ ! -f "$CHAT_ID_FILE" ]] && return
    local token=$(cat "$BOT_TOKEN_FILE")
    local chatid=$(cat "$CHAT_ID_FILE")
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="$chatid" -d text="$1" -d parse_mode="HTML" \
        --max-time 10 >/dev/null 2>&1
}

generate_random_domain() {
    local ip_vps=$(get_ip)
    local chars="abcdefghijklmnopqrstuvwxyz"
    local random_str=""
    for i in {1..6}; do
        random_str+="${chars:RANDOM%26:1}"
    done
    echo "${random_str}.${ip_vps}.nip.io"
}

#================================================
# BOX DRAWING SYSTEM
#================================================

get_theme() {
    if [[ -f "$THEME_FILE" ]]; then
        cat "$THEME_FILE"
    else
        echo "modern"
    fi
}

get_border_color() {
    local theme=$(get_theme)
    case "$theme" in
        "modern")   echo "$CYAN" ;;
        "minimal")  echo "$BLUE" ;;
        "colorful") echo "$MAGENTA" ;;
        "classic")  echo "$WHITE" ;;
    esac
}

get_accent_color() {
    local theme=$(get_theme)
    case "$theme" in
        "modern")   echo "$YELLOW" ;;
        "minimal")  echo "$CYAN" ;;
        "colorful") echo "$GREEN" ;;
        "classic")  echo "$YELLOW" ;;
    esac
}

draw_box_top() {
    local title="$1"
    local theme=$(get_theme)
    local border=$(get_border_color)
    local accent=$(get_accent_color)

    case "$theme" in
        "modern")
            echo -e "${border}╔$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╗${NC}"
            ;;
        "minimal")
            echo -e "${border}┌$(printf '─%.0s' $(seq 1 $BOX_WIDTH))┐${NC}"
            ;;
        "colorful")
            echo -e "${border}╭$(printf '─%.0s' $(seq 1 $BOX_WIDTH))╮${NC}"
            ;;
        "classic")
            echo -e "${border}+$(printf -- '-%.0s' $(seq 1 $BOX_WIDTH))+${NC}"
            ;;
    esac

    if [[ -n "$title" ]]; then
        local clean_title=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
        local title_len=${#clean_title}
        local padding=$(( (BOX_WIDTH - title_len) / 2 ))
        local padding_right=$((BOX_WIDTH - title_len - padding))

        case "$theme" in
            "modern")
                printf "${border}║${NC}%*s${BOLD}${accent}%s${NC}%*s${border}║${NC}\n" \
                    "$padding" "" "$title" "$padding_right" ""
                ;;
            "minimal")
                printf "${border}│${NC}%*s${BOLD}${accent}%s${NC}%*s${border}│${NC}\n" \
                    "$padding" "" "$title" "$padding_right" ""
                ;;
            "colorful")
                printf "${border}│${NC}%*s${BOLD}${accent}%s${NC}%*s${border}│${NC}\n" \
                    "$padding" "" "$title" "$padding_right" ""
                ;;
            "classic")
                printf "${border}|${NC}%*s${BOLD}${accent}%s${NC}%*s${border}|${NC}\n" \
                    "$padding" "" "$title" "$padding_right" ""
                ;;
        esac
    fi
}

draw_separator() {
    local theme=$(get_theme)
    local border=$(get_border_color)
    case "$theme" in
        "modern")   echo -e "${border}╠$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╣${NC}" ;;
        "minimal")  echo -e "${border}├$(printf '─%.0s' $(seq 1 $BOX_WIDTH))┤${NC}" ;;
        "colorful") echo -e "${border}├$(printf '─%.0s' $(seq 1 $BOX_WIDTH))┤${NC}" ;;
        "classic")  echo -e "${border}+$(printf -- '-%.0s' $(seq 1 $BOX_WIDTH))+${NC}" ;;
    esac
}

draw_box_bottom() {
    local theme=$(get_theme)
    local border=$(get_border_color)
    case "$theme" in
        "modern")   echo -e "${border}╚$(printf '═%.0s' $(seq 1 $BOX_WIDTH))╝${NC}" ;;
        "minimal")  echo -e "${border}└$(printf '─%.0s' $(seq 1 $BOX_WIDTH))┘${NC}" ;;
        "colorful") echo -e "${border}╰$(printf '─%.0s' $(seq 1 $BOX_WIDTH))╯${NC}" ;;
        "classic")  echo -e "${border}+$(printf -- '-%.0s' $(seq 1 $BOX_WIDTH))+${NC}" ;;
    esac
}

_get_char() {
    local theme=$(get_theme)
    case "$theme" in
        "modern"|"colorful") echo "║" ;;
        "minimal") echo "│" ;;
        "classic") echo "|" ;;
    esac
}

print_empty() {
    local border=$(get_border_color)
    local ch=$(_get_char)
    printf "${border}%s${NC}%*s${border}%s${NC}\n" "$ch" "$BOX_WIDTH" "" "$ch"
}

print_section() {
    local title="$1"
    local border=$(get_border_color)
    local ch=$(_get_char)
    local title_clean=$(echo -e "$title" | sed 's/\x1b\[[0-9;]*m//g')
    local title_len=${#title_clean}
    local padding=$((BOX_WIDTH - title_len - 2))
    printf "${border}%s${NC} %b%*s${border}%s${NC}\n" "$ch" "$title" "$padding" "" "$ch"
}

print_info() {
    local label="$1"
    local value="$2"
    local border=$(get_border_color)
    local ch=$(_get_char)
    local label_len=${#label}
    local value_clean=$(echo -e "$value" | sed 's/\x1b\[[0-9;]*m//g')
    local value_len=${#value_clean}
    local separator=" : "
    local total_text=$((label_len + 3 + value_len))
    local padding=$((BOX_WIDTH - total_text - 2))
    printf "${border}%s${NC} ${WHITE}%s${NC}${separator}%b%*s${border}%s${NC}\n" \
        "$ch" "$label" "$value" "$padding" "" "$ch"
}

#================================================
# BEAUTIFUL MENU OPTION PRINTERS
#================================================

print_menu_option() {
    local num="$1"
    local text="$2"
    local icon="${3:-}"
    local border=$(get_border_color)
    local accent=$(get_accent_color)
    local theme=$(get_theme)
    local ch=$(_get_char)

    local display_text="${icon:+$icon }$text"
    local num_str="$num"
    local num_len=${#num_str}
    local text_len=${#display_text}
    # bracket [xx] = 4 + num_len, space before+after = 2, spacing = 2
    local total=$((2 + 4 + num_len + 1 + text_len))
    local padding=$((BOX_WIDTH - total - 2))

    case "$theme" in
        "modern")
            printf "${border}%s${NC}  ${CYAN}[${accent}%s${CYAN}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num_str" "$display_text" "$padding" "" "$ch"
            ;;
        "minimal")
            printf "${border}%s${NC}  ${BLUE}[${CYAN}%s${BLUE}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num_str" "$display_text" "$padding" "" "$ch"
            ;;
        "colorful")
            printf "${border}%s${NC}  ${GREEN}[${YELLOW}%s${GREEN}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num_str" "$display_text" "$padding" "" "$ch"
            ;;
        "classic")
            printf "${border}%s${NC}  ${YELLOW}[%s]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num_str" "$display_text" "$padding" "" "$ch"
            ;;
    esac
}

print_menu_double() {
    local num1="$1" text1="$2" num2="$3" text2="$4"
    local border=$(get_border_color)
    local accent=$(get_accent_color)
    local theme=$(get_theme)
    local ch=$(_get_char)

    local col_width=$(( BOX_WIDTH / 2 ))
    local item1_len=$(( 4 + ${#num1} + 1 + ${#text1} ))
    local item2_len=$(( 4 + ${#num2} + 1 + ${#text2} ))
    local padding1=$(( col_width - item1_len - 2 ))
    local padding2=$(( BOX_WIDTH - col_width - item2_len - 2 ))
    [[ $padding1 -lt 0 ]] && padding1=0
    [[ $padding2 -lt 0 ]] && padding2=0

    case "$theme" in
        "modern")
            printf "${border}%s${NC}  ${CYAN}[${accent}%s${CYAN}]${NC} %s%*s${CYAN}[${accent}%s${CYAN}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num1" "$text1" "$padding1" "" "$num2" "$text2" "$padding2" "" "$ch"
            ;;
        "minimal")
            printf "${border}%s${NC}  ${BLUE}[${CYAN}%s${BLUE}]${NC} %s%*s${BLUE}[${CYAN}%s${BLUE}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num1" "$text1" "$padding1" "" "$num2" "$text2" "$padding2" "" "$ch"
            ;;
        "colorful")
            printf "${border}%s${NC}  ${GREEN}[${YELLOW}%s${GREEN}]${NC} %s%*s${GREEN}[${YELLOW}%s${GREEN}]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num1" "$text1" "$padding1" "" "$num2" "$text2" "$padding2" "" "$ch"
            ;;
        "classic")
            printf "${border}%s${NC}  ${YELLOW}[%s]${NC} %s%*s${YELLOW}[%s]${NC} %s%*s${border}%s${NC}\n" \
                "$ch" "$num1" "$text1" "$padding1" "" "$num2" "$text2" "$padding2" "" "$ch"
            ;;
    esac
}

print_status() {
    local label="$1"
    local status="$2"
    local border=$(get_border_color)
    local ch=$(_get_char)
    local label_len=${#label}
    local status_len=${#status}

    if [[ "$status" == "RUNNING" ]] || [[ "$status" == "ON" ]]; then
        local total=$((3 + label_len + status_len + 3))
        local padding=$((BOX_WIDTH - total - 2))
        printf "${border}%s${NC} ${GREEN}●${NC} %-25s ${GREEN}%s${NC}%*s${border}%s${NC}\n" \
            "$ch" "$label" "$status" "$padding" "" "$ch"
    else
        local total=$((3 + label_len + status_len + 3))
        local padding=$((BOX_WIDTH - total - 2))
        printf "${border}%s${NC} ${RED}○${NC} %-25s ${RED}%s${NC}%*s${border}%s${NC}\n" \
            "$ch" "$label" "$status" "$padding" "" "$ch"
    fi
}

print_divider_text() {
    # Print a thin line with label in center
    local label="$1"
    local border=$(get_border_color)
    local accent=$(get_accent_color)
    local ch=$(_get_char)
    local clean=$(echo -e "$label" | sed 's/\x1b\[[0-9;]*m//g')
    local llen=${#clean}
    local lpad=$(( (BOX_WIDTH - llen - 2) / 2 ))
    local rpad=$(( BOX_WIDTH - llen - 2 - lpad ))
    local theme=$(get_theme)
    local dchar="─"
    [[ "$theme" == "modern" ]] && dchar="═"
    [[ "$theme" == "classic" ]] && dchar="-"
    local lline=$(printf "${dchar}%.0s" $(seq 1 $lpad))
    local rline=$(printf "${dchar}%.0s" $(seq 1 $rpad))
    printf "${border}%s${NC}${DIM}%s${NC} ${accent}%b${NC} ${DIM}%s${NC}${border}%s${NC}\n" \
        "$ch" "$lline" "$label" "$rline" "$ch"
}

#================================================
# BEAUTIFUL THEME SELECTOR
#================================================

select_menu_theme() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}         ${BOLD}${YELLOW}🎨  PILIH TEMA TAMPILAN MENU${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${CYAN}[1]${NC} ${WHITE}MODERN${NC}   ${DIM}╔═══╗ Double border • Cyan accent${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${DIM}╔══════════════════════╗${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${DIM}║  [1] Menu Option     ║${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${DIM}╚══════════════════════╝${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${CYAN}[2]${NC} ${WHITE}MINIMAL${NC}  ${DIM}┌───┐ Single border • Blue accent${NC}             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}${DIM}┌──────────────────────┐${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}${DIM}│  [1] Menu Option     │${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${BLUE}${DIM}└──────────────────────┘${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${CYAN}[3]${NC} ${WHITE}COLORFUL${NC} ${DIM}╭───╮ Rounded border • Green/Yellow${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${MAGENTA}${DIM}╭──────────────────────╮${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${MAGENTA}${DIM}│  [1] Menu Option     │${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${MAGENTA}${DIM}╰──────────────────────╯${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${CYAN}[4]${NC} ${WHITE}CLASSIC${NC}  ${DIM}+---+ ASCII style • Universal compat${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${WHITE}${DIM}+----------------------+${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${WHITE}${DIM}|  [1] Menu Option     |${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${WHITE}${DIM}+----------------------+${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "  ${CYAN}➤${NC} Pilih Tema ${WHITE}[1-4]${NC}: "
    read theme_choice

    case $theme_choice in
        1) echo "modern"   > "$THEME_FILE"; echo -e "\n  ${GREEN}✓ Tema MODERN dipilih!${NC}" ;;
        2) echo "minimal"  > "$THEME_FILE"; echo -e "\n  ${GREEN}✓ Tema MINIMAL dipilih!${NC}" ;;
        3) echo "colorful" > "$THEME_FILE"; echo -e "\n  ${GREEN}✓ Tema COLORFUL dipilih!${NC}" ;;
        4) echo "classic"  > "$THEME_FILE"; echo -e "\n  ${GREEN}✓ Tema CLASSIC dipilih!${NC}" ;;
        *)  echo "modern"  > "$THEME_FILE"; echo -e "\n  ${YELLOW}Default MODERN dipilih!${NC}" ;;
    esac
    sleep 1
}

#================================================
# DOMAIN SETUP
#================================================

setup_domain() {
    clear
    echo ""
    draw_box_top "🌐  KONFIGURASI DOMAIN VPN SERVER"
    print_empty
    draw_box_bottom
    echo ""

    local ip_preview=$(get_ip)
    local domain_preview=$(generate_random_domain)

    echo -e "${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${GREEN}┃${NC}  ${BOLD}${WHITE}OPSI 1${NC} ${CYAN}│${NC} ${WHITE}DOMAIN PRIBADI${NC}                                       ${GREEN}┃${NC}"
    echo -e "${GREEN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
    echo -e "${GREEN}┃${NC}                                                                  ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} Menggunakan domain milik sendiri                           ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} SSL Certificate dari Let's Encrypt (Valid)                ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${YELLOW}✓${NC} Gratis & Auto-Renew setiap 90 hari                         ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}                                                                  ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}  ${RED}⚠${NC}  ${YELLOW}Pastikan domain sudah pointing ke IP VPS ini!${NC}            ${GREEN}┃${NC}"
    echo -e "${GREEN}┃${NC}                                                                  ${GREEN}┃${NC}"
    echo -e "${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""

    echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${BLUE}┃${NC}  ${BOLD}${WHITE}OPSI 2${NC} ${CYAN}│${NC} ${WHITE}DOMAIN OTOMATIS (Wildcard DNS)${NC}                    ${BLUE}┃${NC}"
    echo -e "${BLUE}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
    echo -e "${BLUE}┃${NC}                                                                  ${BLUE}┃${NC}"
    echo -e "${BLUE}┃${NC}  ${YELLOW}✓${NC} Domain auto-generate menggunakan nip.io                    ${BLUE}┃${NC}"
    echo -e "${BLUE}┃${NC}  ${YELLOW}✓${NC} Tidak perlu beli domain                                    ${BLUE}┃${NC}"
    echo -e "${BLUE}┃${NC}  ${YELLOW}✓${NC} SSL Self-Signed (Gratis)                                   ${BLUE}┃${NC}"
    echo -e "${BLUE}┃${NC}                                                                  ${BLUE}┃${NC}"
    printf "${BLUE}┃${NC}  ${CYAN}Preview:${NC} ${BOLD}${WHITE}%-54s${NC}${BLUE}┃${NC}\n" "$domain_preview"
    printf "${BLUE}┃${NC}  ${CYAN}IP VPS :${NC} ${WHITE}%-54s${NC}${BLUE}┃${NC}\n" "$ip_preview"
    echo -e "${BLUE}┃${NC}                                                                  ${BLUE}┃${NC}"
    echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo ""

    echo -ne "  ${CYAN}➤${NC} Masukkan pilihan ${WHITE}[${GREEN}1${WHITE}/${BLUE}2${WHITE}]${NC}: "
    read domain_choice
    echo ""

    case $domain_choice in
        1)
            echo -e "  ${YELLOW}📝 Masukkan domain Anda:${NC}"
            echo -e "  ${DIM}• Domain harus pointing ke IP: ${GREEN}${ip_preview}${NC}"
            echo ""
            echo -ne "  ${CYAN}➤${NC} Domain: ${WHITE}"
            read input_domain
            echo -e "${NC}"

            if [[ -z "$input_domain" ]]; then
                echo -e "  ${RED}✗ Domain tidak boleh kosong!${NC}"
                sleep 2; setup_domain; return
            fi

            if ! echo "$input_domain" | grep -qE '^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'; then
                echo -e "  ${RED}✗ Format domain tidak valid!${NC}"
                sleep 2; setup_domain; return
            fi

            DOMAIN="$input_domain"
            echo "custom" > "$DOMAIN_TYPE_FILE"

            echo ""
            draw_box_top "✓ DOMAIN BERHASIL DISIMPAN"
            print_empty
            print_info "Domain"   "${WHITE}${DOMAIN}${NC}"
            print_info "SSL Type" "${CYAN}Let's Encrypt${NC}"
            print_empty
            draw_box_bottom
            ;;
        2)
            DOMAIN=$(generate_random_domain)
            echo "random" > "$DOMAIN_TYPE_FILE"

            echo ""
            draw_box_top "✓ DOMAIN AUTO-GENERATED"
            print_empty
            print_info "Domain"       "${WHITE}${DOMAIN}${NC}"
            print_info "IP Address"   "${WHITE}${ip_preview}${NC}"
            print_info "SSL Type"     "${CYAN}Self-Signed${NC}"
            print_info "DNS Provider" "${CYAN}nip.io (Wildcard)${NC}"
            print_empty
            print_section "${GREEN}✓${NC} Domain siap tanpa konfigurasi DNS!"
            print_empty
            draw_box_bottom
            ;;
        *)
            echo -e "  ${RED}✗ Pilihan tidak valid!${NC}"
            sleep 2; setup_domain; return
            ;;
    esac

    echo "$DOMAIN" > "$DOMAIN_FILE"
    echo ""
    sleep 2
}

#================================================
# SYSTEM FUNCTIONS
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

setup_swap() {
    local swap_total
    swap_total=$(free -m | awk 'NR==3{print $2}')
    [[ "$swap_total" -gt 512 ]] && return 0

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

setup_keepalive() {
    local sshcfg="/etc/ssh/sshd_config"

    grep -q "^ClientAliveInterval" "$sshcfg" && \
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 30/' "$sshcfg" || \
        echo "ClientAliveInterval 30" >> "$sshcfg"

    grep -q "^ClientAliveCountMax" "$sshcfg" && \
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' "$sshcfg" || \
        echo "ClientAliveCountMax 6" >> "$sshcfg"

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

get_ssl_cert() {
    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")

    mkdir -p /etc/xray

    if [[ "$domain_type" == "custom" ]]; then
        certbot certonly --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos \
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

configure_haproxy() {
    cat > /etc/haproxy/haproxy.cfg << 'HAEOF'
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
    default_backend back_xray_tls

backend back_xray_tls
    mode tcp
    server xray_tls 127.0.0.1:8443 check
HAEOF
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
          "certificates": [{"certificateFile":"/etc/xray/xray.crt","keyFile":"/etc/xray/xray.key"}]
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
# FIX ALL SERVICES (NEW FEATURE)
#================================================

fix_all_services() {
    clear
    echo ""
    draw_box_top "🔧  FIX ALL SERVICES"
    print_empty
    print_section "${YELLOW}Memeriksa & memperbaiki semua service...${NC}"
    print_empty
    draw_separator
    print_empty

    local ch=$(_get_char)
    local border=$(get_border_color)
    local fixed=0
    local failed=0
    local ok=0

    # ── Helper: print result line ─────────────────────────────────
    _fix_line() {
        local label="$1" result="$2" note="$3"
        local lpad=2 llen=${#label} rlen=${#result} nlen=${#note}
        local total=$(( llen + rlen + nlen + 8 ))
        local padding=$(( BOX_WIDTH - total - 2 ))
        [[ $padding -lt 0 ]] && padding=0
        case "$result" in
            OK)      printf "${border}%s${NC}  ${GREEN}[✓]${NC} %-28s ${GREEN}%-10s${NC} ${DIM}%s${NC}%*s${border}%s${NC}\n" \
                         "$ch" "$label" "$result" "$note" "$padding" "" "$ch" ;;
            FIXED)   printf "${border}%s${NC}  ${YELLOW}[↺]${NC} %-28s ${YELLOW}%-10s${NC} ${DIM}%s${NC}%*s${border}%s${NC}\n" \
                         "$ch" "$label" "$result" "$note" "$padding" "" "$ch" ;;
            FAILED)  printf "${border}%s${NC}  ${RED}[✗]${NC} %-28s ${RED}%-10s${NC} ${DIM}%s${NC}%*s${border}%s${NC}\n" \
                         "$ch" "$label" "$result" "$note" "$padding" "" "$ch" ;;
            SKIP)    printf "${border}%s${NC}  ${DIM}[~]${NC} %-28s ${DIM}%-10s${NC} ${DIM}%s${NC}%*s${border}%s${NC}\n" \
                         "$ch" "$label" "$result" "$note" "$padding" "" "$ch" ;;
        esac
    }

    # ── 1. Periksa & perbaiki setiap service ──────────────────────
    local services=("xray" "nginx" "haproxy" "dropbear" "sshd" "udp-custom" "vpn-keepalive" "vpn-bot")
    local svc_labels=("Xray Core" "Nginx" "HAProxy" "Dropbear SSH" "OpenSSH" "UDP Custom" "Keepalive" "Telegram Bot")

    print_divider_text "SERVICE STATUS"
    print_empty

    for i in "${!services[@]}"; do
        local svc="${services[$i]}"
        local label="${svc_labels[$i]}"

        if ! systemctl list-unit-files --quiet "$svc.service" 2>/dev/null | grep -q "$svc"; then
            _fix_line "$label" "SKIP" "not installed"
            continue
        fi

        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            _fix_line "$label" "OK" "running"
            ((ok++))
        else
            # Try to restart
            systemctl restart "$svc" 2>/dev/null
            sleep 1
            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                _fix_line "$label" "FIXED" "restarted"
                ((fixed++))
            else
                _fix_line "$label" "FAILED" "check logs"
                ((failed++))
            fi
        fi
    done

    # ── 2. Periksa file SSL ────────────────────────────────────────
    print_empty
    print_divider_text "SSL CERTIFICATE"
    print_empty

    if [[ -f /etc/xray/xray.crt ]] && [[ -f /etc/xray/xray.key ]]; then
        # Cek expiry
        local exp_date cert_ok=true
        exp_date=$(openssl x509 -enddate -noout -in /etc/xray/xray.crt 2>/dev/null | cut -d= -f2)
        local exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
        local now_epoch=$(date +%s)
        local days_left=$(( (exp_epoch - now_epoch) / 86400 ))

        if [[ $days_left -lt 0 ]]; then
            _fix_line "SSL Certificate" "FAILED" "expired ${days_left}d ago"
            echo ""
            echo -e "  ${YELLOW}↺ Mencoba regenerate self-signed...${NC}"
            _gen_self_signed && {
                _fix_line "SSL Regenerate" "FIXED" "new cert created"
                ((fixed++))
                systemctl restart xray 2>/dev/null
            } || {
                _fix_line "SSL Regenerate" "FAILED" "manual fix needed"
                ((failed++))
            }
        elif [[ $days_left -lt 7 ]]; then
            _fix_line "SSL Certificate" "FIXED" "${days_left}d left - renewing"
            get_ssl_cert
            ((fixed++))
        else
            _fix_line "SSL Certificate" "OK" "${days_left}d remaining"
            ((ok++))
        fi
    else
        _fix_line "SSL Certificate" "FAILED" "file not found"
        echo ""
        echo -e "  ${YELLOW}↺ Membuat SSL baru...${NC}"
        mkdir -p /etc/xray
        _gen_self_signed && {
            _fix_line "SSL Created" "FIXED" "self-signed"
            ((fixed++))
            systemctl restart xray 2>/dev/null
        } || { ((failed++)); }
    fi

    # ── 3. Periksa Xray config ────────────────────────────────────
    print_empty
    print_divider_text "XRAY CONFIGURATION"
    print_empty

    if [[ ! -f "$XRAY_CONFIG" ]]; then
        _fix_line "Xray Config" "FAILED" "not found"
        create_xray_config
        _fix_line "Xray Config" "FIXED" "recreated"
        systemctl restart xray 2>/dev/null
        ((fixed++))
    else
        if jq . "$XRAY_CONFIG" >/dev/null 2>&1; then
            _fix_line "Xray Config JSON" "OK" "valid"
            ((ok++))
        else
            _fix_line "Xray Config JSON" "FAILED" "invalid JSON!"
            ((failed++))
        fi
        fix_xray_permissions
        _fix_line "Xray Permissions" "OK" "fixed"
    fi

    # ── 4. Periksa Nginx config ───────────────────────────────────
    print_empty
    print_divider_text "NGINX"
    print_empty

    if command -v nginx >/dev/null 2>&1; then
        if nginx -t 2>/dev/null; then
            _fix_line "Nginx Config" "OK" "valid"
            ((ok++))
        else
            _fix_line "Nginx Config" "FAILED" "syntax error"
            ((failed++))
        fi
    else
        _fix_line "Nginx" "SKIP" "not installed"
    fi

    # ── 5. Periksa HAProxy config ─────────────────────────────────
    if command -v haproxy >/dev/null 2>&1; then
        if haproxy -c -f /etc/haproxy/haproxy.cfg >/dev/null 2>&1; then
            _fix_line "HAProxy Config" "OK" "valid"
            ((ok++))
        else
            _fix_line "HAProxy Config" "FAILED" "check config"
            configure_haproxy
            _fix_line "HAProxy Config" "FIXED" "reconfigured"
            systemctl restart haproxy 2>/dev/null
            ((fixed++))
        fi
    fi

    # ── 6. Periksa port penting ───────────────────────────────────
    print_empty
    print_divider_text "PORT CHECK"
    print_empty

    local ports=(22 80 443 222 8443 8080 8444)
    local port_labels=("SSH:22" "HTTP:80" "HTTPS:443" "Dropbear:222" "Xray-TLS:8443" "Xray-NonTLS:8080" "gRPC:8444")

    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        local plabel="${port_labels[$i]}"
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            _fix_line "$plabel" "OK" "listening"
            ((ok++))
        else
            _fix_line "$plabel" "FAILED" "not listening"
            ((failed++))
        fi
    done

    # ── 7. Ringkasan ──────────────────────────────────────────────
    print_empty
    draw_separator
    print_empty
    print_info "${GREEN}OK${NC}     (Berjalan normal)" "$ok items"
    print_info "${YELLOW}FIXED${NC}  (Berhasil diperbaiki)" "$fixed items"
    print_info "${RED}FAILED${NC} (Perlu perhatian manual)" "$failed items"
    print_empty

    if [[ $failed -eq 0 ]]; then
        print_section "${GREEN}✓ Semua service dalam kondisi baik!${NC}"
    elif [[ $fixed -gt 0 && $failed -eq 0 ]]; then
        print_section "${YELLOW}✓ Beberapa service berhasil diperbaiki!${NC}"
    else
        print_section "${RED}⚠ Ada service yang tidak bisa diperbaiki otomatis.${NC}"
        print_section "${YELLOW}  Cek log: journalctl -u <nama-service> -n 50${NC}"
    fi

    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# DASHBOARD
#================================================

show_system_info() {
    clear

    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && { source /etc/os-release; os_name="${PRETTY_NAME}"; }

    local ip_vps ram_used ram_total ram_pct cpu uptime_str
    ip_vps=$(get_ip)
    ram_used=$(free -m | awk 'NR==2{print $3}')
    ram_total=$(free -m | awk 'NR==2{print $2}')
    ram_pct=$(awk "BEGIN {printf \"%.1f\", ($ram_used/$ram_total)*100}")
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    uptime_str=$(uptime -p | sed 's/up //')

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")

    local ssl_type ssl_status
    if [[ "$domain_type" == "custom" ]]; then
        ssl_type="Let's Encrypt"
        [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]] && \
            ssl_status="${GREEN}✓ Active${NC}" || ssl_status="${YELLOW}⚠ Missing${NC}"
    else
        ssl_type="Self-Signed"
        ssl_status="${CYAN}~ OK${NC}"
    fi

    local services=(xray nginx sshd haproxy dropbear udp-custom vpn-keepalive vpn-bot)
    local svc_total=${#services[@]}
    local svc_running=0
    for svc in "${services[@]}"; do
        systemctl is-active --quiet "$svc" 2>/dev/null && ((svc_running++))
    done

    local ssh_count vmess_count vless_count trojan_count
    ssh_count=$(ls "$AKUN_DIR"/ssh-*.txt   2>/dev/null | wc -l)
    vmess_count=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    vless_count=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    trojan_count=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)

    echo ""
    draw_box_top "  VPN SERVER DASHBOARD  v${SCRIPT_VERSION}  "
    print_section "${GREEN}Proffessor Squad${NC}  •  ${YELLOW}@ridhani16${NC}"
    draw_separator

    print_divider_text "SERVER INFO"
    print_empty
    print_info "Domain"           "${WHITE}${DOMAIN:-Not Set}${NC}"
    print_info "IP Address"       "${WHITE}$ip_vps${NC}"
    print_info "OS"               "${DIM}$os_name${NC}"
    print_info "Uptime"           "${CYAN}$uptime_str${NC}"
    print_info "CPU Load"         "${YELLOW}${cpu}%${NC}"
    print_info "RAM"              "${YELLOW}${ram_used}MB / ${ram_total}MB (${ram_pct}%)${NC}"
    print_info "SSL"              "$ssl_type  $ssl_status"
    print_info "Services"         "${GREEN}$svc_running${NC} / ${svc_total} Running"

    draw_separator
    print_divider_text "ACCOUNTS"
    print_empty
    print_section " SSH: ${GREEN}${ssh_count}${NC}  │  VMess: ${GREEN}${vmess_count}${NC}  │  VLess: ${GREEN}${vless_count}${NC}  │  Trojan: ${GREEN}${trojan_count}${NC}"

    draw_separator
    print_divider_text "SERVICE STATUS"
    print_empty
    print_status "Xray Core"         "$(check_status xray)"
    print_status "Nginx"             "$(check_status nginx)"
    print_status "SSH (OpenSSH)"     "$(check_status sshd)"
    print_status "HAProxy"           "$(check_status haproxy)"
    print_status "Dropbear"          "$(check_status dropbear)"
    print_status "UDP Custom"        "$(check_status udp-custom)"
    print_status "Keepalive"         "$(check_status vpn-keepalive)"
    print_status "Telegram Bot"      "$(check_status vpn-bot)"

    draw_box_bottom
    echo ""
}

#================================================
# MAIN MENU - BEAUTIFUL
#================================================

show_menu() {
    local accent=$(get_accent_color)
    local border=$(get_border_color)

    draw_box_top "  ✦  MAIN MENU  ✦  "
    print_empty

    # Account Management Section
    print_divider_text "ACCOUNT MANAGEMENT"
    print_empty
    print_menu_double "1" "SSH Menu"        "2"  "VMess Menu"
    print_menu_double "3" "VLess Menu"      "4"  "Trojan Menu"
    print_menu_double "5" "Trial Generator" "6"  "List All Accounts"
    print_menu_double "7" "Check Expired"   "8"  "Delete Expired"
    print_empty

    # System Tools Section
    draw_separator
    print_divider_text "SYSTEM TOOLS"
    print_empty
    print_menu_double "9"  "Telegram Bot"   "15" "Speedtest"
    print_menu_double "10" "Change Domain"  "16" "Update Script"
    print_menu_double "11" "Fix SSL/Cert"   "17" "Backup System"
    print_menu_double "12" "Optimize VPS"   "18" "Restore System"
    print_menu_double "13" "Restart All"    "19" "Service Info"
    print_menu_option  "14" "🔧 Fix All Services (Auto-Repair)"
    print_empty

    # Advanced Section
    draw_separator
    print_divider_text "ADVANCED"
    print_empty
    print_menu_double "20" "Uninstall Menu" "99" "Advanced Settings"
    print_menu_option  "21" "Change Menu Theme"
    print_empty

    # Exit
    draw_separator
    print_menu_option "0"  "Exit Program"
    print_empty
    draw_box_bottom

    echo ""
    echo -e "  ${YELLOW}💡${NC} Type ${WHITE}help${NC} for guide  │  ${YELLOW}📞${NC} Support: ${WHITE}@ridhani16${NC}"
    echo ""
}

#================================================
# PROTOCOL MENUS
#================================================

menu_ssh() {
    while true; do
        clear
        draw_box_top "  🖥️  SSH MENU  "
        print_empty
        print_divider_text "MANAGE"
        print_empty
        print_menu_option "1" "Create SSH Account"      "➕"
        print_menu_option "2" "Trial SSH (1 Hour)"      "⏱️"
        print_menu_option "3" "Delete SSH Account"      "🗑️"
        print_menu_option "4" "Renew SSH Account"       "🔄"
        print_menu_option "5" "Check Active Logins"     "👁️"
        print_menu_option "6" "List All SSH Users"      "📋"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu"       "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) create_ssh ;;
            2) create_trial_account "ssh" ;;
            3) delete_account "ssh" ;;
            4) renew_account "ssh" ;;
            5) check_user_login "ssh" ;;
            6) list_protocol_accounts "ssh" ;;
            0) return ;;
        esac
    done
}

menu_vmess() {
    while true; do
        clear
        draw_box_top "  📡  VMESS MENU  "
        print_empty
        print_divider_text "MANAGE"
        print_empty
        print_menu_option "1" "Create VMess Account"   "➕"
        print_menu_option "2" "Trial VMess (1 Hour)"   "⏱️"
        print_menu_option "3" "Delete VMess Account"   "🗑️"
        print_menu_option "4" "Renew VMess Account"    "🔄"
        print_menu_option "5" "Check Active Logins"    "👁️"
        print_menu_option "6" "List All VMess Users"   "📋"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu"      "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) create_xray_account "vmess" ;;
            2) create_trial_account "vmess" ;;
            3) delete_account "vmess" ;;
            4) renew_account "vmess" ;;
            5) check_user_login "vmess" ;;
            6) list_protocol_accounts "vmess" ;;
            0) return ;;
        esac
    done
}

menu_vless() {
    while true; do
        clear
        draw_box_top "  📡  VLESS MENU  "
        print_empty
        print_divider_text "MANAGE"
        print_empty
        print_menu_option "1" "Create VLess Account"   "➕"
        print_menu_option "2" "Trial VLess (1 Hour)"   "⏱️"
        print_menu_option "3" "Delete VLess Account"   "🗑️"
        print_menu_option "4" "Renew VLess Account"    "🔄"
        print_menu_option "5" "Check Active Logins"    "👁️"
        print_menu_option "6" "List All VLess Users"   "📋"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu"      "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) create_xray_account "vless" ;;
            2) create_trial_account "vless" ;;
            3) delete_account "vless" ;;
            4) renew_account "vless" ;;
            5) check_user_login "vless" ;;
            6) list_protocol_accounts "vless" ;;
            0) return ;;
        esac
    done
}

menu_trojan() {
    while true; do
        clear
        draw_box_top "  🛡️  TROJAN MENU  "
        print_empty
        print_divider_text "MANAGE"
        print_empty
        print_menu_option "1" "Create Trojan Account"  "➕"
        print_menu_option "2" "Trial Trojan (1 Hour)"  "⏱️"
        print_menu_option "3" "Delete Trojan Account"  "🗑️"
        print_menu_option "4" "Renew Trojan Account"   "🔄"
        print_menu_option "5" "Check Active Logins"    "👁️"
        print_menu_option "6" "List All Trojan Users"  "📋"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu"      "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) create_xray_account "trojan" ;;
            2) create_trial_account "trojan" ;;
            3) delete_account "trojan" ;;
            4) renew_account "trojan" ;;
            5) check_user_login "trojan" ;;
            6) list_protocol_accounts "trojan" ;;
            0) return ;;
        esac
    done
}

menu_trial_generator() {
    clear
    draw_box_top "  ⏱️  TRIAL ACCOUNT GENERATOR  "
    print_empty
    print_divider_text "1 HOUR FREE TRIAL"
    print_empty
    print_menu_option "1" "SSH Trial (1 Hour)"     "🖥️"
    print_menu_option "2" "VMess Trial (1 Hour)"   "📡"
    print_menu_option "3" "VLess Trial (1 Hour)"   "📡"
    print_menu_option "4" "Trojan Trial (1 Hour)"  "🛡️"
    print_empty
    draw_separator
    print_menu_option "0" "Back to Main Menu"      "◀"
    print_empty
    draw_box_bottom
    echo ""
    echo -ne "  ${CYAN}➤${NC} Select: "
    read choice
    case $choice in
        1) create_trial_account "ssh" ;;
        2) create_trial_account "vmess" ;;
        3) create_trial_account "vless" ;;
        4) create_trial_account "trojan" ;;
    esac
}

#================================================
# INFO & UTILITY MENUS
#================================================

show_info_port() {
    clear
    draw_box_top "  ℹ️  SERVER PORT INFORMATION  "
    print_empty
    print_divider_text "PORTS"
    print_empty
    print_info "SSH OpenSSH"       "22"
    print_info "SSH Dropbear"      "222"
    print_info "Nginx HTTP"        "80"
    print_info "Nginx Download"    "81"
    print_info "HAProxy TLS"       "443  →  Xray 8443"
    print_info "Xray WS TLS"       "443 (via HAProxy)"
    print_info "Xray WS NonTLS"    "80  (via Nginx)"
    print_info "Xray gRPC TLS"     "8444"
    print_info "BadVPN UDP"        "7100 - 7300"
    print_empty
    draw_separator
    print_divider_text "PATHS"
    print_empty
    print_info "VMess WS"          "/vmess"
    print_info "VLess WS"          "/vless"
    print_info "Trojan WS"         "/trojan"
    print_info "VMess gRPC"        "vmess-grpc"
    print_info "VLess gRPC"        "vless-grpc"
    print_info "Trojan gRPC"       "trojan-grpc"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

list_all_accounts() {
    clear
    draw_box_top "  📋  ALL ACTIVE ACCOUNTS  "
    print_empty

    local total=0
    shopt -s nullglob

    local ssh_files=("$AKUN_DIR"/ssh-*.txt)
    if [[ ${#ssh_files[@]} -gt 0 ]]; then
        print_divider_text "SSH ACCOUNTS"
        print_empty
        for f in "${ssh_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/ssh-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_section "  ${CYAN}•${NC} ${WHITE}$uname${NC}  ${DIM}exp: $exp${NC}"
            ((total++))
        done
        print_empty
    fi

    local vmess_files=("$AKUN_DIR"/vmess-*.txt)
    if [[ ${#vmess_files[@]} -gt 0 ]]; then
        print_divider_text "VMESS ACCOUNTS"
        print_empty
        for f in "${vmess_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vmess-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_section "  ${CYAN}•${NC} ${WHITE}$uname${NC}  ${DIM}exp: $exp${NC}"
            ((total++))
        done
        print_empty
    fi

    local vless_files=("$AKUN_DIR"/vless-*.txt)
    if [[ ${#vless_files[@]} -gt 0 ]]; then
        print_divider_text "VLESS ACCOUNTS"
        print_empty
        for f in "${vless_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vless-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_section "  ${CYAN}•${NC} ${WHITE}$uname${NC}  ${DIM}exp: $exp${NC}"
            ((total++))
        done
        print_empty
    fi

    local trojan_files=("$AKUN_DIR"/trojan-*.txt)
    if [[ ${#trojan_files[@]} -gt 0 ]]; then
        print_divider_text "TROJAN ACCOUNTS"
        print_empty
        for f in "${trojan_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/trojan-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            print_section "  ${CYAN}•${NC} ${WHITE}$uname${NC}  ${DIM}exp: $exp${NC}"
            ((total++))
        done
        print_empty
    fi

    shopt -u nullglob

    draw_separator
    print_info "Total Accounts" "${GREEN}$total${NC}"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

cek_expired() {
    clear
    draw_box_top "  📅  CHECK EXPIRED ACCOUNTS  "
    print_empty

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
                print_section "${RED}✗ EXPIRED${NC}  $uname  ${DIM}($exp_str)${NC}"
            else
                print_section "${YELLOW}⚠ ${diff}d left${NC}  $uname  ${DIM}($exp_str)${NC}"
            fi
        fi
    done
    shopt -u nullglob

    [[ $found -eq 0 ]] && print_section "${GREEN}✓ No expired accounts!${NC}"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

delete_expired() {
    clear
    draw_box_top "  🗑️  DELETE EXPIRED ACCOUNTS  "
    print_empty

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

            print_section "${RED}↺ Deleting${NC}  $fname"

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
        print_empty
        print_section "${GREEN}✓ Deleted $count accounts!${NC}"
    else
        print_section "${GREEN}✓ No expired accounts found!${NC}"
    fi

    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

show_help() {
    clear
    draw_box_top "  📖  COMMAND GUIDE  "
    print_empty
    print_divider_text "Account Management"
    print_empty
    print_section "  ${CYAN}1-4${NC}   Protocol account menus (SSH/VMess/VLess/Trojan)"
    print_section "  ${CYAN}5${NC}     Generate trial accounts (1 hour auto delete)"
    print_section "  ${CYAN}6${NC}     List all active accounts"
    print_section "  ${CYAN}7-8${NC}   Check / delete expired accounts"
    print_empty
    print_divider_text "System Tools"
    print_empty
    print_section "  ${CYAN}9${NC}     Telegram bot management"
    print_section "  ${CYAN}10-11${NC} Domain & SSL management"
    print_section "  ${CYAN}12-13${NC} VPS optimization & restart all"
    print_section "  ${CYAN}14${NC}    🔧 Fix All Services (auto-repair)"
    print_section "  ${CYAN}15${NC}    Speedtest by Ookla"
    print_section "  ${CYAN}16${NC}    Update script from GitHub"
    print_section "  ${CYAN}17-18${NC} Backup & restore system"
    print_section "  ${CYAN}19${NC}    Port & service info"
    print_empty
    print_divider_text "Advanced"
    print_empty
    print_section "  ${CYAN}20${NC}    Uninstall components"
    print_section "  ${CYAN}21${NC}    Change menu theme"
    print_section "  ${CYAN}99${NC}    Advanced settings (12 sub-menus)"
    print_section "  ${CYAN}0${NC}     Exit program"
    print_section "  ${CYAN}help${NC}  Show this guide"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# CREATE SSH ACCOUNT
#================================================

create_ssh() {
    clear
    draw_box_top "  ➕  CREATE SSH ACCOUNT  "
    print_empty
    draw_box_bottom
    echo ""

    read -p "  Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Username required!${NC}"; sleep 2; return; }

    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"; sleep 2; return
    fi

    read -p "  Password      : " password
    [[ -z "$password" ]] && { echo -e "${RED}Password required!${NC}"; sleep 2; return; }

    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid number!${NC}"; sleep 2; return; }

    read -p "  IP Limit      : " iplimit
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
 SSL/TLS          : 443
 SSH WS Non SSL   : 80
 SSH WS SSL       : 443
 BadVPN UDPGW     : 7100,7200,7300
═══════════════════════════════════════════════════════════
 Format HC        : ${DOMAIN}:80@${username}:${password}
═══════════════════════════════════════════════════════════
 Download: http://${ip_vps}:81/ssh-${username}.txt
═══════════════════════════════════════════════════════════
 Active Duration  : ${days} Days
 Created          : ${created}
 Expired          : ${exp}
═══════════════════════════════════════════════════════════
SSHEOF

    clear
    draw_box_top "  ✅  SSH ACCOUNT CREATED  "
    print_empty
    print_divider_text "CREDENTIALS"
    print_empty
    print_info "Username"   "$username"
    print_info "Password"   "$password"
    print_info "IP/Host"    "$ip_vps"
    print_info "Domain"     "$DOMAIN"
    print_empty
    print_divider_text "PORTS"
    print_empty
    print_info "OpenSSH"    "22"
    print_info "Dropbear"   "222"
    print_info "SSL/TLS"    "443"
    print_info "BadVPN UDP" "7100-7300"
    print_empty
    draw_separator
    print_info "Download"   "http://${ip_vps}:81/ssh-${username}.txt"
    print_info "Duration"   "${days} Days"
    print_info "Expired"    "$exp"
    print_empty
    draw_box_bottom

    send_telegram_admin "✅ <b>New SSH Account</b>
👤 User: <code>${username}</code>
🔑 Pass: <code>${password}</code>
🌐 IP: ${ip_vps}
📅 Exp: ${exp}"

    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# CREATE XRAY ACCOUNT
#================================================

create_xray_account() {
    local protocol="$1"
    clear
    draw_box_top "  ➕  CREATE ${protocol^^} ACCOUNT  "
    print_empty
    draw_box_bottom
    echo ""

    read -p "  Username      : " username
    [[ -z "$username" ]] && { echo -e "${RED}Username required!${NC}"; sleep 2; return; }

    if grep -q "\"email\":\"${username}\"" "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "${RED}Username already exists!${NC}"; sleep 2; return
    fi

    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid number!${NC}"; sleep 2; return; }

    read -p "  Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100

    read -p "  IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1

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
        echo -e "${RED}Failed to update Xray config!${NC}"; sleep 2; return
    fi

    mkdir -p "$AKUN_DIR"
    printf "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

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

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/${protocol}-${username}.txt" << DLEOF
═══════════════════════════════════════════════════════════
  ${protocol^^} ACCOUNT
═══════════════════════════════════════════════════════════
 Username         : ${username}
 UUID             : ${uuid}
 Domain           : ${DOMAIN}
 Quota            : ${quota} GB
 IP Limit         : ${iplimit} IP
═══════════════════════════════════════════════════════════
 Port TLS         : 443
 Port NonTLS      : 80
 Port gRPC        : 8444
 Path WS          : /${protocol}
 ServiceName gRPC : ${protocol}-grpc
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

    clear
    draw_box_top "  ✅  ${protocol^^} ACCOUNT CREATED  "
    print_empty
    print_divider_text "CREDENTIALS"
    print_empty
    print_info "Username" "$username"
    print_info "UUID"     "$uuid"
    print_info "Domain"   "$DOMAIN"
    print_info "Quota"    "${quota} GB"
    print_info "IP Limit" "${iplimit} IP"
    print_empty
    print_divider_text "PORTS"
    print_empty
    print_info "Port TLS"    "443"
    print_info "Port NonTLS" "80"
    print_info "Port gRPC"   "8444"
    print_info "Path WS"     "/${protocol}"
    print_empty
    print_divider_text "LINKS"
    print_empty
    print_section "${CYAN}TLS:${NC}"
    print_section "${WHITE}${link_tls}${NC}"
    print_empty
    print_section "${CYAN}NonTLS:${NC}"
    print_section "${WHITE}${link_nontls}${NC}"
    print_empty
    draw_separator
    print_info "Download" "http://${ip_vps}:81/${protocol}-${username}.txt"
    print_info "Duration" "${days} Days"
    print_info "Expired"  "$exp"
    print_empty
    draw_box_bottom

    send_telegram_admin "✅ <b>New ${protocol^^} Account</b>
👤 User: <code>${username}</code>
🔑 UUID: <code>${uuid}</code>
🌐 Domain: ${DOMAIN}
📅 Exp: ${exp}"

    echo ""
    read -p "  Tekan Enter untuk kembali..."
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

        (
            sleep 3600
            userdel -f "$username" 2>/dev/null
            rm -f "$AKUN_DIR/ssh-${username}.txt" "$PUBLIC_HTML/ssh-${username}.txt"
        ) & disown

        clear
        draw_box_top "  ⏱️  SSH TRIAL ACCOUNT  "
        print_empty
        print_info "Username" "$username"
        print_info "Password" "$password"
        print_info "Domain"   "$DOMAIN"
        print_info "OpenSSH"  "22"
        print_info "Dropbear" "222"
        print_info "Duration" "1 Hour (Auto Delete)"
        print_info "Expired"  "$exp"
        print_empty
        print_section "${YELLOW}⚠ Account will be auto-deleted after 1 hour${NC}"
        print_empty
        draw_box_bottom
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
            echo -e "${RED}Failed!${NC}"; sleep 2; return
        fi

        local link_tls
        if [[ "$protocol" == "vmess" ]]; then
            local j_tls=$(printf '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
                "$username" "$uuid" "$DOMAIN")
            link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
        elif [[ "$protocol" == "vless" ]]; then
            link_tls="vless://${uuid}@bug.com:443?path=%2Fvless&security=tls&encryption=none&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        elif [[ "$protocol" == "trojan" ]]; then
            link_tls="trojan://${uuid}@bug.com:443?path=%2Ftrojan&security=tls&host=${DOMAIN}&type=ws&sni=${DOMAIN}#${username}"
        fi

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
        draw_box_top "  ⏱️  ${protocol^^} TRIAL ACCOUNT  "
        print_empty
        print_info "Username" "$username"
        print_info "UUID"     "$uuid"
        print_info "Domain"   "$DOMAIN"
        print_info "Port TLS" "443"
        print_info "Path"     "/${protocol}"
        print_empty
        print_section "${CYAN}TLS Link:${NC}"
        print_section "${WHITE}${link_tls}${NC}"
        print_empty
        print_info "Duration" "1 Hour (Auto Delete)"
        print_info "Expired"  "$exp"
        print_empty
        print_section "${YELLOW}⚠ Account will be auto-deleted after 1 hour${NC}"
        print_empty
        draw_box_bottom
    fi

    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# DELETE ACCOUNT
#================================================

delete_account() {
    local protocol="$1"
    clear
    draw_box_top "  🗑️  DELETE ${protocol^^} ACCOUNT  "
    print_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        print_section "${RED}No accounts found!${NC}"
        draw_box_bottom; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        print_section "  ${CYAN}•${NC} ${WHITE}$n${NC}  ${DIM}exp: $e${NC}"
    done

    print_empty
    draw_box_bottom
    echo ""
    read -p "  Username to delete: " username
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
    echo -e "  ${GREEN}✓ Account deleted: ${username}${NC}"
    sleep 2
}

#================================================
# RENEW ACCOUNT
#================================================

renew_account() {
    local protocol="$1"
    clear
    draw_box_top "  🔄  RENEW ${protocol^^} ACCOUNT  "
    print_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        print_section "${RED}No accounts found!${NC}"
        draw_box_bottom; sleep 2; return
    fi

    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        print_section "  ${CYAN}•${NC} ${WHITE}$n${NC}  ${DIM}exp: $e${NC}"
    done

    print_empty
    draw_box_bottom
    echo ""
    read -p "  Username to renew: " username
    [[ -z "$username" ]] && return

    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && {
        echo -e "${RED}Account not found!${NC}"; sleep 2; return
    }

    read -p "  Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${RED}Invalid number!${NC}"; sleep 2; return; }

    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")

    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && chage -E "$new_exp_date" "$username" 2>/dev/null

    echo ""
    echo -e "  ${GREEN}✓ Renewed! New expiry: ${new_exp}${NC}"
    sleep 2
}

#================================================
# LIST PROTOCOL ACCOUNTS
#================================================

list_protocol_accounts() {
    local protocol="$1"
    clear
    draw_box_top "  📋  ${protocol^^} ACCOUNT LIST  "
    print_empty

    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        print_section "${RED}No accounts found!${NC}"
    else
        print_divider_text "ACTIVE ACCOUNTS"
        print_empty
        for f in "${files[@]}"; do
            local uname exp quota trial
            uname=$(basename "$f" .txt | sed "s/${protocol}-//")
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2)
            quota=$(grep "QUOTA" "$f" 2>/dev/null | cut -d= -f2)
            trial=$(grep "TRIAL" "$f" 2>/dev/null | cut -d= -f2)

            if [[ "$trial" == "1" ]]; then
                print_section "  ${YELLOW}[TRIAL ]${NC} ${WHITE}$uname${NC}  ${DIM}exp: $exp${NC}"
            else
                print_section "  ${GREEN}[MEMBER]${NC} ${WHITE}$uname${NC}  ${DIM}quota: ${quota}GB  exp: $exp${NC}"
            fi
        done
        print_empty
        draw_separator
        print_info "Total" "${GREEN}${#files[@]}${NC} accounts"
    fi

    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# CHECK USER LOGIN
#================================================

check_user_login() {
    local protocol="$1"
    clear
    draw_box_top "  👁️  ACTIVE ${protocol^^} LOGINS  "
    print_empty

    if [[ "$protocol" == "ssh" ]]; then
        print_divider_text "SSH SESSIONS"
        print_empty
        local active_users=$(who 2>/dev/null | awk '{print $1}' | sort | uniq)
        if [[ -z "$active_users" ]]; then
            print_section "${YELLOW}No active SSH sessions${NC}"
        else
            while IFS= read -r user; do
                local login_count=$(who | grep -c "^$user ")
                local login_time=$(who | grep "^$user " | head -1 | awk '{print $3, $4}')
                print_section "${GREEN}●${NC} ${WHITE}$user${NC}"
                print_section "  Connections: ${CYAN}$login_count${NC}  Login: ${DIM}$login_time${NC}"
                print_empty
            done <<< "$active_users"
        fi
    else
        print_divider_text "${protocol^^} CONNECTIONS"
        print_empty
        if [[ ! -f /var/log/xray/access.log ]]; then
            print_section "${YELLOW}Log file not found${NC}"
        else
            local recent_logs=$(grep "accepted" /var/log/xray/access.log 2>/dev/null | \
                grep -i "$protocol" | tail -50)

            if [[ -z "$recent_logs" ]]; then
                print_section "${YELLOW}No recent ${protocol^^} connections${NC}"
            else
                local active_users=$(echo "$recent_logs" | grep -oP 'email: \K[^,]+' | sort | uniq)
                if [[ -z "$active_users" ]]; then
                    print_section "${YELLOW}No active users detected${NC}"
                else
                    while IFS= read -r uname; do
                        local conn_count=$(echo "$recent_logs" | grep -c "email: $uname")
                        print_section "${GREEN}●${NC} ${WHITE}$uname${NC}"
                        print_section "  Connections: ${CYAN}$conn_count${NC}"
                        print_empty
                    done <<< "$active_users"
                fi
            fi
        fi
    fi

    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

#================================================
# ADVANCED MENU
#================================================

menu_advanced() {
    while true; do
        clear
        draw_box_top "  ⚙️  ADVANCED SETTINGS  "
        print_empty
        print_divider_text "NETWORK & SECURITY"
        print_empty
        print_menu_double "1" "Port Management"    "7"  "Firewall Rules"
        print_menu_double "2" "Protocol Settings"  "8"  "Bandwidth Monitor"
        print_menu_double "3" "Auto Backup"        "9"  "User Limits"
        print_menu_double "4" "SSH Protection"     "10" "Custom Scripts"
        print_menu_double "5" "Fail2Ban Setup"     "11" "Cron Jobs"
        print_menu_double "6" "DDoS Protection"    "12" "System Logs"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu" "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select [0-12]: "
        read choice
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
    draw_box_top "  🔌  PORT MANAGEMENT  "
    print_empty
    print_divider_text "CURRENT CONFIG"
    print_empty
    print_info "SSH OpenSSH"      "22"
    print_info "SSH Dropbear"     "222"
    print_info "Nginx HTTP"       "80"
    print_info "Nginx Download"   "81"
    print_info "HAProxy TLS"      "443"
    print_info "Xray Int. TLS"    "8443"
    print_info "Xray Int. NonTLS" "8080"
    print_info "Xray gRPC"        "8444"
    print_info "BadVPN UDP"       "7100-7300"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

_adv_protocol_settings() {
    clear
    draw_box_top "  📡  PROTOCOL SETTINGS  "
    print_empty
    print_divider_text "XRAY SETTINGS"
    print_empty
    local inbound_count=$(jq '.inbounds | length' "$XRAY_CONFIG" 2>/dev/null)
    print_info "Total Inbounds"   "${inbound_count:-0}"
    print_info "VMess Encrypt"    "Auto (alterId:0)"
    print_info "VLess Encrypt"    "None"
    print_info "WS Paths"         "/vmess /vless /trojan"
    print_info "gRPC Services"    "vmess-grpc vless-grpc trojan-grpc"
    print_info "SNI"              "bug.com"
    print_empty
    draw_box_bottom
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

_adv_auto_backup() {
    clear
    draw_box_top "  💾  AUTO BACKUP  "
    print_empty
    print_menu_option "1" "Enable Daily Backup (02:00)"   "📅"
    print_menu_option "2" "Enable Weekly Backup (Sun)"    "📆"
    print_menu_option "3" "Disable Auto Backup"           "🚫"
    print_menu_option "4" "Manual Backup Now"             "💾"
    print_menu_option "5" "View Backup History"           "📋"
    print_empty
    draw_separator
    print_menu_option "0" "Back"                          "◀"
    print_empty
    draw_box_bottom
    echo ""
    echo -ne "  ${CYAN}➤${NC} Select: "
    read backup_choice
    case $backup_choice in
        1) (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/menu backup_auto") | crontab -
           echo -e "  ${GREEN}✓ Daily backup enabled${NC}"; sleep 2 ;;
        2) (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/menu backup_auto") | crontab -
           echo -e "  ${GREEN}✓ Weekly backup enabled${NC}"; sleep 2 ;;
        3) crontab -l 2>/dev/null | grep -v "backup_auto" | crontab -
           echo -e "  ${GREEN}✓ Auto backup disabled${NC}"; sleep 2 ;;
        4) menu_backup ;;
        5) clear
           draw_box_top "  📋  BACKUP HISTORY  "
           print_empty
           if [[ -d /root/backups ]]; then
               for b in /root/backups/*.tar.gz; do
                   [[ -f "$b" ]] || continue
                   local sz=$(du -h "$b" | awk '{print $1}')
                   print_section "  ${CYAN}•${NC} $(basename "$b")  ${DIM}($sz)${NC}"
               done
           else
               print_section "${YELLOW}No backups found${NC}"
           fi
           print_empty; draw_box_bottom
           echo ""; read -p "  Tekan Enter..." ;;
    esac
}

_adv_ssh_protection() {
    clear
    draw_box_top "  🔒  SSH PROTECTION  "
    print_empty
    print_menu_option "1" "Set Max Auth Tries (3-6)"  "🔢"
    print_menu_option "2" "Disable Root Login"        "🚫"
    print_menu_option "3" "Enable Root Login"         "✅"
    print_menu_option "4" "View Failed Logins"        "👁️"
    print_empty
    draw_separator
    print_menu_option "0" "Back"                      "◀"
    print_empty
    draw_box_bottom
    echo ""
    echo -ne "  ${CYAN}➤${NC} Select: "
    read ssh_choice
    case $ssh_choice in
        1) read -p "  Max tries [3-6]: " max_tries
           [[ ! "$max_tries" =~ ^[3-6]$ ]] && max_tries=3
           sed -i "s/^#*MaxAuthTries.*/MaxAuthTries $max_tries/" /etc/ssh/sshd_config
           systemctl restart sshd
           echo -e "  ${GREEN}✓ Set to $max_tries${NC}"; sleep 2 ;;
        2) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
           systemctl restart sshd
           echo -e "  ${GREEN}✓ Root login disabled${NC}"; sleep 2 ;;
        3) sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
           systemctl restart sshd
           echo -e "  ${YELLOW}✓ Root login enabled${NC}"; sleep 2 ;;
        4) clear; draw_box_top "FAILED SSH LOGINS"; draw_box_bottom; echo ""
           grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20
           echo ""; read -p "  Tekan Enter..." ;;
    esac
}

_adv_fail2ban() {
    clear
    draw_box_top "  🚧  FAIL2BAN SETUP  "
    print_empty
    if ! command -v fail2ban-client >/dev/null 2>&1; then
        print_section "${YELLOW}Fail2Ban not installed${NC}"
        draw_box_bottom
        echo ""
        read -p "  Install Fail2Ban? [y/N]: " install_f2b
        if [[ "$install_f2b" == "y" ]]; then
            apt-get update >/dev/null 2>&1
            apt-get install -y fail2ban >/dev/null 2>&1
            systemctl enable fail2ban; systemctl start fail2ban
            echo -e "  ${GREEN}✓ Installed${NC}"
        fi
    else
        draw_box_bottom
        echo ""
        systemctl status fail2ban --no-pager | head -5
        echo ""
        fail2ban-client status 2>/dev/null
    fi
    echo ""
    read -p "  Tekan Enter untuk kembali..."
}

_adv_ddos_protection() {
    clear
    draw_box_top "  🛡️  DDOS PROTECTION  "
    print_empty
    print_menu_option "1" "Enable SYN Cookies"           "🍪"
    print_menu_option "2" "Configure Connection Limits"  "🔢"
    print_menu_option "3" "Enable ICMP Rate Limiting"    "📶"
    print_menu_option "4" "View Current Settings"        "👁️"
    print_empty
    draw_separator
    print_menu_option "0" "Back"                         "◀"
    print_empty
    draw_box_bottom
    echo ""
    echo -ne "  ${CYAN}➤${NC} Select: "
    read ddos_choice
    case $ddos_choice in
        1) sysctl -w net.ipv4.tcp_syncookies=1
           echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
           echo -e "  ${GREEN}✓ Enabled${NC}"; sleep 2 ;;
        2) echo -e "net.ipv4.tcp_max_syn_backlog = 4096\nnet.core.somaxconn = 1024" >> /etc/sysctl.conf
           sysctl -p >/dev/null 2>&1
           echo -e "  ${GREEN}✓ Configured${NC}"; sleep 2 ;;
        3) sysctl -w net.ipv4.icmp_ratelimit=1000
           echo "net.ipv4.icmp_ratelimit=1000" >> /etc/sysctl.conf
           echo -e "  ${GREEN}✓ Enabled${NC}"; sleep 2 ;;
        4) clear
           sysctl net.ipv4.tcp_syncookies net.ipv4.tcp_max_syn_backlog net.core.somaxconn 2>/dev/null
           echo ""; read -p "  Tekan Enter..." ;;
    esac
}

_adv_firewall() {
    clear
    draw_box_top "  🔥  FIREWALL RULES  "
    print_empty
    if command -v ufw >/dev/null 2>&1; then
        draw_box_bottom; echo ""
        ufw status numbered
    else
        print_section "${YELLOW}UFW not installed${NC}"
        draw_box_bottom; echo ""
        read -p "  Install UFW? [y/N]: " install_ufw
        if [[ "$install_ufw" == "y" ]]; then
            apt-get install -y ufw >/dev/null 2>&1
            ufw --force enable
            ufw allow 22,80,81,222,443,8444/tcp
            ufw allow 7100:7300/tcp; ufw allow 7100:7300/udp
            echo -e "  ${GREEN}✓ Installed & configured${NC}"
        fi
    fi
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

_adv_bandwidth() {
    clear
    draw_box_top "  📊  BANDWIDTH MONITOR  "
    print_empty
    if command -v vnstat >/dev/null 2>&1; then
        draw_box_bottom; echo ""
        vnstat
    else
        print_section "${YELLOW}vnStat not installed${NC}"
        draw_box_bottom; echo ""
        read -p "  Install vnStat? [y/N]: " install_vn
        if [[ "$install_vn" == "y" ]]; then
            apt-get install -y vnstat >/dev/null 2>&1
            systemctl enable vnstat; systemctl start vnstat
            echo -e "  ${GREEN}✓ Installed (wait 5 min for data)${NC}"
        fi
    fi
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

_adv_user_limits() {
    clear
    draw_box_top "  🔢  USER LIMITS  "
    print_empty
    draw_box_bottom; echo ""
    cat /etc/security/limits.d/99-vpn.conf 2>/dev/null || echo "  No custom limits set"
    echo ""
    ulimit -a | head -10
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

_adv_custom_scripts() {
    clear
    draw_box_top "  📜  CUSTOM SCRIPTS  "
    print_empty
    if [[ -d /root/scripts ]]; then
        for s in /root/scripts/*.sh; do
            [[ -f "$s" ]] && print_section "  ${CYAN}•${NC} $(basename "$s")"
        done
    else
        print_section "${YELLOW}No scripts found${NC}"
        print_section "  Create dir: ${CYAN}mkdir -p /root/scripts${NC}"
    fi
    print_empty; draw_box_bottom
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

_adv_cron_jobs() {
    clear
    draw_box_top "  ⏰  CRON JOBS  "
    print_empty; draw_box_bottom; echo ""
    crontab -l 2>/dev/null || echo "  No cron jobs configured"
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

_adv_system_logs() {
    while true; do
        clear
        draw_box_top "  📋  SYSTEM LOGS  "
        print_empty
        print_menu_option "1" "Xray Access Logs"    "📄"
        print_menu_option "2" "Xray Error Logs"     "❌"
        print_menu_option "3" "Nginx Error Logs"    "🌐"
        print_menu_option "4" "SSH Auth Logs"       "🔐"
        print_menu_option "5" "System Journal"      "📰"
        print_empty
        draw_separator
        print_menu_option "0" "Back"                "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read log_choice
        case $log_choice in
            1) clear; tail -50 /var/log/xray/access.log 2>/dev/null || echo "No logs"; echo ""; read -p "  Enter..." ;;
            2) clear; tail -50 /var/log/xray/error.log  2>/dev/null || echo "No logs"; echo ""; read -p "  Enter..." ;;
            3) clear; tail -50 /var/log/nginx/error.log 2>/dev/null || echo "No logs"; echo ""; read -p "  Enter..." ;;
            4) clear; tail -50 /var/log/auth.log        2>/dev/null || echo "No logs"; echo ""; read -p "  Enter..." ;;
            5) clear; journalctl -n 50 --no-pager;                     echo ""; read -p "  Enter..." ;;
            0) return ;;
        esac
    done
}

#================================================
# UPDATE MENU
#================================================

update_menu() {
    clear
    draw_box_top "  🔄  UPDATE SCRIPT  "
    print_empty
    print_info "Current Version" "${GREEN}${SCRIPT_VERSION}${NC}"
    print_empty
    draw_box_bottom
    echo ""
    echo -e "  ${CYAN}Checking GitHub...${NC}"

    local latest
    latest=$(curl -s --max-time 10 "$VERSION_URL" 2>/dev/null | tr -d '\n\r ' | xargs)

    if [[ -z "$latest" ]]; then
        echo -e "  ${RED}✗ Cannot connect to GitHub!${NC}"; sleep 2; return
    fi

    echo -e "  Latest: ${GREEN}${latest}${NC}"; echo ""

    if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
        echo -e "  ${GREEN}✓ Already up to date!${NC}"; sleep 2; return
    fi

    read -p "  Update now? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return

    echo ""
    echo -e "  ${CYAN}[1/4]${NC} Backup...    "; cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null && echo -e "  ${GREEN}✓${NC}" || { echo -e "  ${RED}✗${NC}"; return; }
    echo -e "  ${CYAN}[2/4]${NC} Download...  "; local tmp="/tmp/tunnel_new.sh"
    curl -sL "$SCRIPT_URL" -o "$tmp"; [[ -s "$tmp" ]] && echo -e "  ${GREEN}✓${NC}" || { echo -e "  ${RED}✗${NC}"; return; }
    echo -e "  ${CYAN}[3/4]${NC} Validate...  "; bash -n "$tmp" 2>/dev/null && echo -e "  ${GREEN}✓${NC}" || { echo -e "  ${RED}✗${NC}"; rm -f "$tmp"; return; }
    echo -e "  ${CYAN}[4/4]${NC} Apply...     "; mv "$tmp" "$SCRIPT_PATH"; chmod +x "$SCRIPT_PATH"; echo -e "  ${GREEN}✓${NC}"

    echo ""; echo -e "  ${GREEN}✓ Update successful! Restarting...${NC}"; sleep 2
    exec bash "$SCRIPT_PATH"
}

#================================================
# BACKUP & RESTORE
#================================================

menu_backup() {
    clear
    draw_box_top "  💾  BACKUP SYSTEM  "
    print_empty
    print_section "${YELLOW}Creating backup...${NC}"
    draw_box_bottom
    echo ""

    local backup_dir="/root/backups"
    local backup_file="vpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p "$backup_dir"

    tar -czf "$backup_dir/$backup_file" \
        /root/domain /root/.domain_type /root/akun \
        /root/.bot_token /root/.chat_id /root/.payment_info \
        /root/.menu_theme /etc/xray/xray.crt /etc/xray/xray.key \
        /usr/local/etc/xray/config.json 2>/dev/null

    if [[ -f "$backup_dir/$backup_file" ]]; then
        clear
        draw_box_top "  ✅  BACKUP COMPLETED  "
        print_empty
        print_info "Filename" "$backup_file"
        print_info "Size"     "$(du -h "$backup_dir/$backup_file" | awk '{print $1}')"
        print_info "Location" "$backup_dir/"
        print_empty
        draw_box_bottom
    else
        echo -e "  ${RED}✗ Backup failed!${NC}"
    fi

    echo ""; read -p "  Tekan Enter untuk kembali..."
}

menu_restore() {
    clear
    draw_box_top "  📥  RESTORE SYSTEM  "
    print_empty

    local backup_dir="/root/backups"
    if [[ ! -d "$backup_dir" ]]; then
        print_section "${RED}Backup directory not found!${NC}"
        draw_box_bottom; sleep 2; return
    fi

    print_section "${WHITE}Available Backups:${NC}"
    print_empty
    draw_box_bottom
    echo ""

    shopt -s nullglob
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "  ${RED}No backups found!${NC}"; sleep 2; return
    fi

    local i=1
    for backup in "${backups[@]}"; do
        local sz=$(du -h "$backup" | awk '{print $1}')
        printf "  ${CYAN}[%d]${NC} %-44s ${YELLOW}%s${NC}\n" "$i" "$(basename "$backup")" "$sz"
        ((i++))
    done

    echo ""
    read -p "  Select [1-${#backups[@]}] or 0: " choice
    [[ "$choice" == "0" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]] || \
       [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#backups[@]}" ]] && return

    local selected="${backups[$((choice-1))]}"
    echo ""
    echo -e "  ${YELLOW}⚠ This will overwrite current config!${NC}"
    read -p "  Continue? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return

    echo ""
    echo -e "  ${CYAN}Restoring...${NC}"
    tar -xzf "$selected" -C / 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Restore successful!${NC}"
        systemctl restart xray nginx haproxy 2>/dev/null
    else
        echo -e "  ${RED}✗ Restore failed!${NC}"
    fi

    echo ""; read -p "  Tekan Enter untuk kembali..."
}

#================================================
# SYSTEM TOOLS
#================================================

change_domain() {
    clear
    draw_box_top "  🌐  CHANGE DOMAIN  "
    print_empty
    print_info "Current Domain" "${GREEN}${DOMAIN:-Not Set}${NC}"
    print_empty
    draw_box_bottom
    echo ""
    echo -e "  ${YELLOW}Starting domain reconfiguration...${NC}"
    sleep 1
    setup_domain
    echo ""
    echo -e "  ${YELLOW}⚠ Jalankan 'Fix SSL/Cert' setelah ini!${NC}"
    sleep 3
}

fix_certificate() {
    clear
    draw_box_top "  🔐  FIX / RENEW SSL CERTIFICATE  "
    print_empty
    [[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && {
        print_section "${RED}Domain not configured!${NC}"
        draw_box_bottom; sleep 3; return
    }
    print_info "Domain" "$DOMAIN"
    print_empty
    draw_box_bottom
    echo ""
    echo -e "  ${CYAN}Stopping services...${NC}"
    systemctl stop haproxy nginx 2>/dev/null; sleep 1

    echo -e "  ${CYAN}Getting SSL certificate...${NC}"
    get_ssl_cert

    echo -e "  ${CYAN}Starting services...${NC}"
    systemctl start nginx haproxy 2>/dev/null
    systemctl restart xray 2>/dev/null

    echo -e "  ${GREEN}✓ Certificate updated!${NC}"; sleep 2
}

run_speedtest() {
    clear
    draw_box_top "  🚀  SPEEDTEST BY OOKLA  "
    print_empty

    if ! command -v speedtest >/dev/null 2>&1; then
        print_section "${YELLOW}Installing Speedtest CLI...${NC}"
        draw_box_bottom; echo ""
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
    else
        print_section "${YELLOW}Testing... Please wait ~30 seconds${NC}"
        draw_box_bottom
        echo ""
    fi

    command -v speedtest >/dev/null 2>&1 && speedtest --accept-license --accept-gdpr
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

restart_all_services() {
    clear
    draw_box_top "  🔄  RESTART ALL SERVICES  "
    print_empty
    print_divider_text "RESTARTING"
    print_empty

    for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive vpn-bot; do
        if systemctl restart "$svc" 2>/dev/null; then
            print_status "$svc" "RUNNING"
        else
            print_status "$svc" "STOPPED"
        fi
    done

    print_empty
    draw_box_bottom
    echo ""; sleep 2
}

optimize_vps() {
    clear
    draw_box_top "  ⚡  OPTIMIZE VPS  "
    print_empty
    print_section "${CYAN}Optimizing system...${NC}"
    draw_box_bottom; echo ""

    optimize_vpn

    echo -e "  ${GREEN}✓ BBR enabled${NC}"
    echo -e "  ${GREEN}✓ TCP tuning applied${NC}"
    echo -e "  ${GREEN}✓ File limits increased${NC}"
    echo -e "  ${GREEN}✓ Network optimized${NC}"
    echo ""; read -p "  Tekan Enter untuk kembali..."
}

#================================================
# TELEGRAM BOT
#================================================

setup_telegram_bot() {
    clear
    draw_box_top "  🤖  TELEGRAM BOT SETUP  "
    print_empty
    print_section "${WHITE}Cara mendapatkan Bot Token:${NC}"
    print_section "  1. Buka Telegram, cari ${CYAN}@BotFather${NC}"
    print_section "  2. Ketik /newbot dan ikuti instruksi"
    print_section "  3. Copy TOKEN yang diberikan"
    print_empty
    print_section "${WHITE}Cara mendapatkan Chat ID:${NC}"
    print_section "  1. Cari ${CYAN}@userinfobot${NC} di Telegram"
    print_section "  2. Ketik /start untuk melihat ID Anda"
    print_empty
    draw_box_bottom
    echo ""

    read -p "  Bot Token     : " bot_token
    [[ -z "$bot_token" ]] && { echo -e "${RED}Token required!${NC}"; sleep 2; return; }

    read -p "  Admin Chat ID : " admin_id
    [[ -z "$admin_id" ]] && { echo -e "${RED}Chat ID required!${NC}"; sleep 2; return; }

    echo ""
    echo -e "  ${CYAN}Testing token...${NC}"
    local test_result=$(curl -s --max-time 10 \
        "https://api.telegram.org/bot${bot_token}/getMe")

    if ! echo "$test_result" | grep -q '"ok":true'; then
        echo -e "  ${RED}✗ Invalid token!${NC}"; sleep 2; return
    fi

    echo -e "  ${GREEN}✓ Valid bot!${NC}"; echo ""

    read -p "  Account Name  : " rek_name
    read -p "  Account Number: " rek_number
    read -p "  Bank/E-Wallet : " rek_bank
    read -p "  Price/Month   : " harga
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

    install_bot_service

    echo ""
    echo -e "  ${GREEN}✓ Bot configured!${NC}"
    sleep 2
}

install_bot_service() {
    mkdir -p /root/bot "$ORDER_DIR"
    pip3 install requests --break-system-packages >/dev/null 2>&1

    cat > /root/bot/bot.py << 'BOTEOF'
#!/usr/bin/env python3
import os, json, time
try:
    import requests
except:
    os.system('pip3 install requests --break-system-packages -q')
    import requests

TOKEN    = open('/root/.bot_token').read().strip()
ADMIN_ID = int(open('/root/.chat_id').read().strip())
DOMAIN   = open('/root/domain').read().strip() if os.path.exists('/root/domain') else 'N/A'
API      = f'https://api.telegram.org/bot{TOKEN}'

def send(chat_id, text):
    try:
        requests.post(f'{API}/sendMessage',
            data={'chat_id': chat_id, 'text': text, 'parse_mode': 'HTML'}, timeout=5)
    except: pass

def get_updates(offset=0):
    try:
        r = requests.get(f'{API}/getUpdates',
            params={'offset': offset, 'timeout': 15}, timeout=20)
        return r.json().get('result', [])
    except: return []

def on_start(msg):
    chat_id = msg['chat']['id']
    fname   = msg['from'].get('first_name', 'User')
    send(chat_id, f'👋 Halo <b>{fname}</b>!\n\n🤖 <b>Bot VPN Proffessor Squad</b>\n🌐 Server: <code>{DOMAIN}</code>\n\nHubungi admin untuk order VPN!')

def on_msg(msg):
    if 'text' not in msg: return
    if msg['text'].strip() in ['/start']: on_start(msg)

def main():
    print(f'Bot VPN - Admin: {ADMIN_ID}', flush=True)
    offset = 0
    while True:
        try:
            updates = get_updates(offset)
            for upd in updates:
                offset = upd['update_id'] + 1
                if 'message' in upd: on_msg(upd['message'])
        except KeyboardInterrupt: break
        except: time.sleep(2)

if __name__ == '__main__': main()
BOTEOF

    chmod +x /root/bot/bot.py

    cat > /etc/systemd/system/vpn-bot.service << 'SVCEOF'
[Unit]
Description=VPN Bot
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /root/bot/bot.py
Restart=always
RestartSec=3

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
        draw_box_top "  🤖  TELEGRAM BOT  "
        print_empty
        print_status "Bot Service" "$bs"
        print_empty
        draw_separator
        print_empty
        print_menu_option "1" "Setup Bot"    "⚙️"
        print_menu_option "2" "Start Bot"    "▶️"
        print_menu_option "3" "Stop Bot"     "⏹️"
        print_menu_option "4" "Restart Bot"  "🔄"
        print_menu_option "5" "View Logs"    "📋"
        print_empty
        draw_separator
        print_menu_option "0" "Back to Main Menu" "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) setup_telegram_bot ;;
            2) systemctl start   vpn-bot; echo -e "  ${GREEN}Started!${NC}";   sleep 1 ;;
            3) systemctl stop    vpn-bot; echo -e "  ${YELLOW}Stopped!${NC}";   sleep 1 ;;
            4) systemctl restart vpn-bot; echo -e "  ${GREEN}Restarted!${NC}"; sleep 1 ;;
            5) clear; journalctl -u vpn-bot -n 50 --no-pager; echo ""; read -p "  Tekan Enter..." ;;
            0) return ;;
        esac
    done
}

#================================================
# UDP CUSTOM
#================================================

install_udp_custom() {
    if is_installed "udp-custom"; then return 0; fi

    cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/usr/bin/env python3
import socket, threading, select, time

PORTS    = range(7100, 7301)
SSH_HOST = '127.0.0.1'
SSH_PORT = 22
BUF      = 8192

def handle(data, addr, sock):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10); s.connect((SSH_HOST, SSH_PORT))
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
        s.bind(('0.0.0.0', port)); s.setblocking(False)
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
Description=UDP Custom BadVPN
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/udp-custom
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UDPSVC

    systemctl daemon-reload
    systemctl enable udp-custom 2>/dev/null
    systemctl restart udp-custom 2>/dev/null
}

#================================================
# UNINSTALL MENU
#================================================

menu_uninstall() {
    while true; do
        clear
        draw_box_top "  🗑️  UNINSTALL MENU  "
        print_empty
        print_menu_option "1" "Uninstall Xray"       "📡"
        print_menu_option "2" "Uninstall Nginx"      "🌐"
        print_menu_option "3" "Uninstall HAProxy"    "⚖️"
        print_menu_option "4" "Uninstall Dropbear"   "🔐"
        print_menu_option "5" "Uninstall UDP Custom" "📶"
        print_menu_option "6" "Uninstall Bot"        "🤖"
        print_menu_option "7" "Uninstall Keepalive"  "💓"
        print_empty
        draw_separator
        print_section "${RED}⚠ [99] REMOVE ALL COMPONENTS${NC}"
        draw_separator
        print_menu_option "0" "Back to Main Menu"    "◀"
        print_empty
        draw_box_bottom
        echo ""
        echo -ne "  ${CYAN}➤${NC} Select: "
        read choice
        case $choice in
            1) uninstall_xray ;;
            2) uninstall_nginx ;;
            3) uninstall_haproxy ;;
            4) uninstall_dropbear ;;
            5) uninstall_udp ;;
            6) uninstall_bot ;;
            7) uninstall_keepalive ;;
            99) uninstall_all ;;
            0) return ;;
        esac
    done
}

uninstall_xray() {
    clear
    draw_box_top "  🗑️  UNINSTALL XRAY  "
    print_empty
    print_section "${YELLOW}This will remove Xray and all accounts${NC}"
    draw_box_bottom
    echo ""
    read -p "  Continue? [y/N]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop xray 2>/dev/null; systemctl disable xray 2>/dev/null
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray
    rm -f "$AKUN_DIR"/vmess-*.txt "$AKUN_DIR"/vless-*.txt "$AKUN_DIR"/trojan-*.txt
    echo -e "  ${GREEN}✓ Xray uninstalled${NC}"; sleep 2
}

uninstall_nginx()    { clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop nginx 2>/dev/null; apt-get purge -y nginx nginx-common >/dev/null 2>&1; echo -e "  ${GREEN}✓ Nginx uninstalled${NC}"; sleep 2; }
uninstall_haproxy()  { clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop haproxy 2>/dev/null; apt-get purge -y haproxy >/dev/null 2>&1; echo -e "  ${GREEN}✓ HAProxy uninstalled${NC}"; sleep 2; }
uninstall_dropbear() { clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop dropbear 2>/dev/null; apt-get purge -y dropbear >/dev/null 2>&1; echo -e "  ${GREEN}✓ Dropbear uninstalled${NC}"; sleep 2; }
uninstall_udp()      { clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop udp-custom 2>/dev/null; rm -f /etc/systemd/system/udp-custom.service /usr/local/bin/udp-custom; systemctl daemon-reload; echo -e "  ${GREEN}✓ UDP Custom uninstalled${NC}"; sleep 2; }
uninstall_bot()      { clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop vpn-bot 2>/dev/null; rm -f /etc/systemd/system/vpn-bot.service; rm -rf /root/bot; rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"; systemctl daemon-reload; echo -e "  ${GREEN}✓ Bot uninstalled${NC}"; sleep 2; }
uninstall_keepalive(){ clear; read -p "  Continue? [y/N]: " c; [[ "$c" != "y" ]] && return; systemctl stop vpn-keepalive 2>/dev/null; rm -f /etc/systemd/system/vpn-keepalive.service /usr/local/bin/vpn-keepalive.sh; systemctl daemon-reload; echo -e "  ${GREEN}✓ Keepalive uninstalled${NC}"; sleep 2; }

uninstall_all() {
    clear
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                    ║${NC}"
    echo -e "${RED}║           ⚠️   REMOVE ALL VPN COMPONENTS   ⚠️                     ║${NC}"
    echo -e "${RED}║                                                                    ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}This will remove ALL VPN components and data!${NC}"
    echo ""
    read -p "  Type 'DELETE' to confirm: " confirm
    [[ "$confirm" != "DELETE" ]] && { echo -e "  ${YELLOW}Cancelled${NC}"; sleep 2; return; }

    echo ""; echo -e "  ${RED}Removing all components...${NC}"; echo ""
    for svc in xray nginx haproxy dropbear udp-custom vpn-keepalive vpn-bot; do
        systemctl stop "$svc" 2>/dev/null; systemctl disable "$svc" 2>/dev/null
        echo -e "  ${RED}✗${NC} Stopped: $svc"
    done

    echo ""
    bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) --remove >/dev/null 2>&1
    apt-get purge -y nginx haproxy dropbear >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1

    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray \
           /root/akun /root/bot /root/orders /root/domain \
           /root/.domain_type /root/.bot_token /root/.chat_id \
           /root/.payment_info /root/.menu_theme /root/backups \
           /root/tunnel.sh.bak

    rm -f /etc/systemd/system/udp-custom.service \
          /etc/systemd/system/vpn-keepalive.service \
          /etc/systemd/system/vpn-bot.service \
          /usr/local/bin/udp-custom /usr/local/bin/vpn-keepalive.sh \
          /usr/local/bin/menu /root/tunnel.sh

    sed -i '/tunnel.sh/d' /root/.bashrc 2>/dev/null
    systemctl daemon-reload

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║           ✓  ALL COMPONENTS REMOVED SUCCESSFULLY                  ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""; sleep 3; exit 0
}

#================================================
# INSTALL BANNER
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
# SMART INSTALLER - FIXED (No more Netdata 2x)
#================================================

smart_install() {
    show_install_banner
    setup_domain
    [[ -z "$DOMAIN" ]] && { echo -e "${RED}Domain not configured!${NC}"; exit 1; }

    select_menu_theme

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && domain_type=$(cat "$DOMAIN_TYPE_FILE")

    clear
    show_install_banner
    echo -e "  Domain   : ${GREEN}${DOMAIN}${NC}"
    echo -e "  SSL Type : ${GREEN}$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")${NC}"
    echo -e "  Theme    : ${GREEN}$(get_theme)${NC}"
    echo ""
    sleep 2

    local LOG="/tmp/install_$(date +%s).log"
    > "$LOG"

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

    _ok()   { echo -e "  ${GREEN}[✓]${NC} $1"; }
    _skip() { echo -e "  ${YELLOW}[⊘]${NC} $1 ${YELLOW}(already installed)${NC}"; }
    _fail() { echo -e "  ${RED}[✗]${NC} $1"; }

    _pkg() {
        local pkg="$1"
        if dpkg -l 2>/dev/null | grep -q "^ii.*$pkg"; then
            _skip "$pkg"; return 0
        fi
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >> "$LOG" 2>&1
        [[ $? -eq 0 ]] && _ok "$pkg" || _fail "$pkg"
    }

    # Step 1: System Update
    _install_header "STEP 1/10 - SYSTEM UPDATE"
    echo -e "${CYAN}Updating package lists...${NC}"
    apt-get update -y >> "$LOG" 2>&1 && _ok "Package lists updated" || _fail "Update failed"
    echo -e "${CYAN}Upgrading system...${NC}"
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG" 2>&1 && _ok "System upgraded" || true

    # Step 2: Base Packages
    _install_header "STEP 2/10 - BASE PACKAGES"
    local base_pkgs=(curl wget unzip uuid-runtime net-tools openssl jq qrencode
        python3 python3-pip software-properties-common gnupg2
        ca-certificates lsb-release apt-transport-https)
    for pkg in "${base_pkgs[@]}"; do _pkg "$pkg"; done

    # Step 3: VPN Services
    _install_header "STEP 3/10 - VPN SERVICES"

    if is_installed "xray"; then _skip "Xray-core"
    else
        echo -e "${CYAN}Installing Xray-core...${NC}"
        bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh) >> "$LOG" 2>&1
        [[ $? -eq 0 ]] && _ok "Xray-core" || _fail "Xray-core"
    fi

    is_installed "nginx"    && _skip "Nginx"           || _pkg "nginx"
    is_installed "sshd"     && _skip "OpenSSH Server"  || _pkg "openssh-server"
    is_installed "dropbear" && _skip "Dropbear"        || _pkg "dropbear"
    is_installed "haproxy"  && _skip "HAProxy"         || _pkg "haproxy"
    is_installed "stunnel4" && _skip "Stunnel4"        || _pkg "stunnel4"
    is_installed "certbot"  && _skip "Certbot"         || _pkg "certbot"
    _pkg "netcat-openbsd"

    # Step 4: Additional Tools
    _install_header "STEP 4/10 - ADDITIONAL TOOLS"

    if is_installed "fail2ban"; then _skip "Fail2Ban"
    else
        _pkg "fail2ban" && {
            systemctl enable fail2ban 2>/dev/null || true
            systemctl start  fail2ban 2>/dev/null || true
        }
    fi

    if is_installed "ufw"; then _skip "UFW Firewall"
    else
        _pkg "ufw" && {
            ufw --force enable            >> "$LOG" 2>&1 || true
            ufw allow 22,80,81,222,443,8444/tcp >> "$LOG" 2>&1 || true
            ufw allow 7100:7300/tcp       >> "$LOG" 2>&1 || true
            ufw allow 7100:7300/udp       >> "$LOG" 2>&1 || true
            _ok "UFW configured"
        }
    fi

    if is_installed "unbound"; then _skip "Unbound DNS"
    else
        _pkg "unbound" && {
            systemctl enable unbound 2>/dev/null || true
            systemctl start  unbound 2>/dev/null || true
        }
    fi

    if is_installed "vnstat"; then _skip "vnStat"
    else
        _pkg "vnstat" && {
            systemctl enable vnstat 2>/dev/null || true
            systemctl start  vnstat 2>/dev/null || true
        }
    fi

    # ── NETDATA: hanya satu kali, dengan timeout & fallback ──────
    if is_installed "netdata"; then
        _skip "Netdata"
    else
        echo -e "${CYAN}Installing Netdata (optional, max 2 menit)...${NC}"
        if timeout 120 bash <(curl -Ss https://my-netdata.io/kickstart.sh) \
               --dont-wait --non-interactive >> "$LOG" 2>&1; then
            _ok "Netdata"
        else
            _skip "Netdata (optional, skipped - timeout/error)"
        fi
    fi
    # ─────────────────────────────────────────────────────────────

    # Step 5: Optimization
    _install_header "STEP 5/10 - SYSTEM OPTIMIZATION"

    if is_installed "bbr"; then _skip "BBR TCP Congestion"
    else
        modprobe tcp_bbr 2>/dev/null
        echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
        _ok "BBR enabled"
    fi

    if is_installed "swap"; then _skip "Swapfile"
    else
        echo -e "${CYAN}Creating 2GB swapfile...${NC}"
        setup_swap && _ok "Swapfile 2GB" || _fail "Swapfile"
    fi

    echo -e "${CYAN}Applying network tuning...${NC}"
    optimize_vpn && _ok "Network optimized"

    command -v logrotate >/dev/null 2>&1 && _skip "Logrotate" || _pkg "logrotate"

    if systemctl is-active --quiet cron 2>/dev/null; then _skip "Cron"
    else
        _pkg "cron"
        systemctl enable cron 2>/dev/null || true
        systemctl start  cron 2>/dev/null || true
    fi

    # Step 6: SSL Certificate
    _install_header "STEP 6/10 - SSL CERTIFICATE"
    echo -e "${CYAN}Getting SSL certificate...${NC}"
    mkdir -p /etc/xray

    if [[ "$domain_type" == "custom" ]]; then
        echo -e "${CYAN}Trying Let's Encrypt...${NC}"
        certbot certonly --standalone -d "$DOMAIN" \
            --non-interactive --agree-tos \
            --register-unsafely-without-email >> "$LOG" 2>&1

        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem"   /etc/xray/xray.key
            _ok "Let's Encrypt certificate"
        else
            echo -e "  ${YELLOW}Let's Encrypt failed, using self-signed...${NC}"
            _gen_self_signed && _ok "Self-signed certificate"
        fi
    else
        _gen_self_signed && _ok "Self-signed certificate for $DOMAIN"
    fi
    chmod 644 /etc/xray/xray.* 2>/dev/null

    # Step 7: Configure Services
    _install_header "STEP 7/10 - SERVICE CONFIGURATION"

    echo -e "${CYAN}Creating Xray config...${NC}"
    create_xray_config && _ok "Xray config (8 inbounds)"

    echo -e "${CYAN}Configuring Nginx...${NC}"
    cat > /etc/nginx/sites-available/default << 'NGXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    location / { try_files $uri $uri/ =404; autoindex on; }
    location /vmess  { proxy_pass http://127.0.0.1:8080; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_read_timeout 86400s; }
    location /vless  { proxy_pass http://127.0.0.1:8080; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_read_timeout 86400s; }
    location /trojan { proxy_pass http://127.0.0.1:8080; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host $host; proxy_read_timeout 86400s; }
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
    configure_haproxy && _ok "HAProxy 443 → 8443"

    # Step 8: Additional Services
    _install_header "STEP 8/10 - ADDITIONAL SERVICES"

    echo -e "${CYAN}Installing UDP Custom...${NC}"
    install_udp_custom && _ok "UDP Custom 7100-7300"

    echo -e "${CYAN}Setting up Keepalive...${NC}"
    setup_keepalive && _ok "Keepalive service"

    echo -e "${CYAN}Setting up menu command...${NC}"
    setup_menu_command && _ok "Menu command (type: menu)"

    # Step 9: Web Interface
    _install_header "STEP 9/10 - WEB INTERFACE"
    local ip_vps=$(get_ip)
    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html><html><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>VPN Server - ${DOMAIN}</title>
<style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Segoe UI',sans-serif;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);min-height:100vh;display:flex;align-items:center;justify-content:center;color:#fff}.container{max-width:500px;padding:40px;background:rgba(255,255,255,0.1);backdrop-filter:blur(10px);border-radius:20px;box-shadow:0 8px 32px rgba(0,0,0,0.3);text-align:center}h1{font-size:2.5em;margin-bottom:10px}.domain{font-size:1.2em;color:#e0e0e0;margin-bottom:20px}.ip{color:#ffd700;font-weight:bold}.badge{display:inline-block;background:rgba(255,255,255,0.2);padding:8px 20px;border-radius:25px;margin-top:20px;font-size:.9em;text-transform:uppercase;letter-spacing:2px}</style>
</head><body><div class="container">
<h1>🚀 VPN Server</h1>
<div class="domain">${DOMAIN}</div>
<div class="ip">${ip_vps}</div>
<div class="badge">Online & Ready</div>
</div></body></html>
IDXEOF
    _ok "Web index page"

    # Step 10: Start Services
    _install_header "STEP 10/10 - START SERVICES"
    systemctl daemon-reload >> "$LOG" 2>&1

    local services=(xray nginx sshd dropbear haproxy udp-custom vpn-keepalive)
    for svc in "${services[@]}"; do
        systemctl enable  "$svc" >> "$LOG" 2>&1
        systemctl restart "$svc" >> "$LOG" 2>&1
        if systemctl is-active --quiet "$svc"; then _ok "$svc"
        else _fail "$svc"
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
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "Domain"     "$DOMAIN"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "IP Address"  "$ip_vps"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "SSL Type"    "$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")"
    printf "  ${WHITE}%-20s${NC}: ${GREEN}%s${NC}\n" "Menu Theme"  "$(get_theme)"
    echo ""
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "SSH"         "22"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Dropbear"    "222"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray TLS"    "443"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray NonTLS" "80"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Xray gRPC"   "8444"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "BadVPN UDP"  "7100-7300"
    printf "  ${WHITE}%-20s${NC}: ${CYAN}%s${NC}\n" "Web Panel"   "http://${ip_vps}:81/"
    echo ""
    printf "  ${WHITE}%-20s${NC}: ${YELLOW}%s${NC}\n" "Install Log" "$LOG"
    printf "  ${WHITE}%-20s${NC}: ${YELLOW}%s${NC}\n" "Support"     "@ridhani16"
    echo ""
    echo -e "  ${GREEN}💡 Ketik '${WHITE}menu${GREEN}' untuk membuka VPN Manager!${NC}"
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
        echo -ne "  ${CYAN}➤${NC} Enter choice: "
        read choice

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
            14) fix_all_services ;;        # ← NEW
            15) run_speedtest ;;
            16) update_menu ;;
            17) menu_backup ;;
            18) menu_restore ;;
            19) show_info_port ;;
            20) menu_uninstall ;;
            21) select_menu_theme ;;
            99) menu_advanced ;;
            0)  clear; echo -e "  ${CYAN}Goodbye!${NC}"; exit 0 ;;
            help|HELP) show_help ;;
            *) ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Script ini harus dijalankan sebagai root!${NC}"
    echo "  Usage: sudo bash $0"
    exit 1
fi

mkdir -p "$AKUN_DIR" "$ORDER_DIR"

[[ -f "$DOMAIN_FILE" ]] && DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

if [[ ! -f "$DOMAIN_FILE" ]]; then
    smart_install
fi

setup_menu_command
main_menu
