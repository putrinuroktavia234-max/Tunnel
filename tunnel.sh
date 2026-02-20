#!/bin/bash

#================================================
# Youzin Crabz Tunel
# The Professor
# GitHub: putrinuroktavia234-max/Tunnel
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
AKUN_DIR="/root/akun"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
SCRIPT_VERSION="3.0.0"
SCRIPT_AUTHOR="The Professor"
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
XRAY_INTERNAL_TLS="8443"
XRAY_WS_NONTLS_PORT="8080"
XRAY_GRPC_PORT="8444"
BADVPN_RANGE="7100-7300"
PRICE_MONTHLY="10000"
DURATION_MONTHLY="30"

#================================================
# ANIMASI INSTALL - CINEMATIC LOADING
#================================================

# Spinner animasi
spinner_frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
bar_frames=('▱▱▱▱▱▱▱▱▱▱' '▰▱▱▱▱▱▱▱▱▱' '▰▰▱▱▱▱▱▱▱▱' '▰▰▰▱▱▱▱▱▱▱' '▰▰▰▰▱▱▱▱▱▱' '▰▰▰▰▰▱▱▱▱▱' '▰▰▰▰▰▰▱▱▱▱' '▰▰▰▰▰▰▰▱▱▱' '▰▰▰▰▰▰▰▰▱▱' '▰▰▰▰▰▰▰▰▰▱' '▰▰▰▰▰▰▰▰▰▰')

# Animasi loading dengan text keren
animated_loading() {
    local msg="$1"
    local duration="${2:-2}"
    local i=0
    local end=$((SECONDS + duration))
    while [[ $SECONDS -lt $end ]]; do
        local frame="${spinner_frames[$((i % 8))]}"
        local dots=""
        case $((i % 4)) in
            0) dots="   " ;;
            1) dots=".  " ;;
            2) dots=".. " ;;
            3) dots="..." ;;
        esac
        printf "\r  ${CYAN}${frame}${NC} ${WHITE}${msg}${NC}${YELLOW}${dots}${NC}   "
        sleep 0.1
        ((i++))
    done
    printf "\r  ${GREEN}✔${NC} ${WHITE}${msg}${NC} ${GREEN}[SELESAI]${NC}           \n"
}

# Progress bar cantik
fancy_progress() {
    local current="$1"
    local total="$2"
    local label="$3"
    local pct=$(( current * 100 / total ))
    local filled=$(( current * 10 / total ))
    local bar="${bar_frames[$filled]}"
    
    printf "\r  ${CYAN}[${NC}${GREEN}%s${NC}${CYAN}]${NC} ${WHITE}%3d%%${NC}  ${DIM}%s${NC}   " \
        "$bar" "$pct" "$label"
}

show_progress() {
    fancy_progress "$1" "$2" "$3"
    echo ""
}

done_msg() {
    printf "  ${GREEN}✔${NC} ${WHITE}%-42s${NC}\n" "$1"
}

fail_msg() {
    printf "  ${RED}✘${NC} ${WHITE}%-42s${NC}\n" "$1"
}

info_msg() {
    printf "  ${CYAN}◈${NC} %s\n" "$1"
}

#================================================
# BANNER INSTALL - YOUZIN CRABZ TUNEL
#================================================

show_install_banner() {
    clear
    echo ""
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}  ✦ ✦ ✦  Script Auto Install by Youzin Crabz  ✦ ✦ ✦${NC}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${WHITE}  Youzin Crabz Tunel${NC}"
    echo -e "      ${DIM}  The Professor${NC}"
    echo ""
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
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

#================================================
# MENU HEADER / FOOTER - REDESIGN RAPI
#================================================

print_menu_header() {
    local title="$1"
    local LINE="══════════════════════════════════════════════════════"
    local W=54
    local len=${#title}
    local pad=$(( (W - len) / 2 ))
    local rpad=$(( W - len - pad ))
    echo ""
    echo -e "${CYAN}╔${LINE}╗${NC}"
    printf "${CYAN}║${NC}%*s${WHITE}${BOLD}%s${NC}%*s${CYAN}║${NC}\n" \
        "$pad" "" "$title" "$rpad" ""
    echo -e "${CYAN}╚${LINE}╝${NC}"
    echo ""
}

print_menu_footer() {
    echo -e "${CYAN}  ╚══════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "  ${CYAN}┌──────────────────────────────────────────────────┐${NC}"
    printf "  ${CYAN}│${NC}  ${YELLOW}▸${NC} ${WHITE}%-47s${NC}${CYAN}│${NC}\n" "$1"
    echo -e "  ${CYAN}└──────────────────────────────────────────────────┘${NC}"
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
    print_menu_header "SETUP DOMAIN"
    echo -e "  ${WHITE}[1]${NC} Pakai domain sendiri"
    echo -e "      ${YELLOW}Contoh: vpn.example.com${NC}"
    echo -e "      ${DIM}SSL: Let's Encrypt${NC}"
    echo ""
    echo -e "  ${WHITE}[2]${NC} Generate domain otomatis"
    local preview
    preview=$(generate_random_domain)
    echo -e "      ${YELLOW}Contoh: ${preview}${NC}"
    echo -e "      ${DIM}SSL: Self-signed${NC}"
    echo ""
    read -p "  Pilih [1/2]: " domain_choice
    case $domain_choice in
        1)
            echo ""
            read -p "  Masukkan domain: " input_domain
            [[ -z "$input_domain" ]] && {
                echo -e "${RED}  ✘ Domain kosong!${NC}"
                sleep 2; setup_domain; return
            }
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
    print_menu_header "SETUP SWAP 1GB"
    local swap_total
    swap_total=$(free -m | \
        awk 'NR==3{print $2}')
    if [[ "$swap_total" -gt 0 ]]; then
        echo -e "  ${YELLOW}Swap ada: ${swap_total}MB${NC}"
        swapoff -a 2>/dev/null
        sed -i '/swapfile/d' /etc/fstab
        rm -f /swapfile
    fi
    echo -e "  ${CYAN}Creating 1GB swap...${NC}"
    fallocate -l 1G /swapfile 2>/dev/null || \
        dd if=/dev/zero of=/swapfile \
           bs=1M count=1024 2>/dev/null
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    swapon /swapfile
    grep -q "/swapfile" /etc/fstab || \
        echo "/swapfile none swap sw 0 0" \
        >> /etc/fstab
    echo -e "  ${GREEN}✔ Swap 1GB OK!${NC}"
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
    echo "tcp_bbr" > \
        /etc/modules-load.d/bbr.conf
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
        echo "ClientAliveInterval 30" \
        >> "$sshcfg"
    grep -q "^ClientAliveCountMax" \
        "$sshcfg" && \
        sed -i \
        's/^ClientAliveCountMax.*/ClientAliveCountMax 6/' \
        "$sshcfg" || \
        echo "ClientAliveCountMax 6" \
        >> "$sshcfg"
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
        << 'XEOF'
[Service]
Restart=always
RestartSec=3
LimitNOFILE=65535
XEOF

    cat > /usr/local/bin/vpn-keepalive.sh \
        << 'KAEOF'
#!/bin/bash
while true; do
    GW=$(ip route | \
        awk '/default/{print $3; exit}')
    [[ -n "$GW" ]] && \
        ping -c1 -W2 "$GW" >/dev/null 2>&1
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1
    sleep 25
done
KAEOF
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
    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' \
            < "$DOMAIN_FILE" | xargs)
    [[ -z "$DOMAIN" ]] && {
        echo -e "  ${RED}✘ Domain belum diset!${NC}"
        sleep 3; return
    }
    echo -e "  Domain: ${GREEN}${DOMAIN}${NC}"
    echo ""
    systemctl stop haproxy 2>/dev/null
    systemctl stop nginx   2>/dev/null
    sleep 1
    get_ssl_cert
    systemctl start nginx   2>/dev/null
    systemctl start haproxy 2>/dev/null
    systemctl restart xray  2>/dev/null
    echo -e "  ${GREEN}✔ Done!${NC}"
    sleep 3
}

#================================================
# SPEEDTEST
#================================================

run_speedtest() {
    clear
    print_menu_header "SPEEDTEST BY OOKLA"

    if ! command -v speedtest >/dev/null 2>&1 && \
       ! command -v speedtest-cli \
           >/dev/null 2>&1; then
        echo -e "  ${CYAN}Installing Speedtest CLI...${NC}"
        curl -s \
            https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh \
            | bash >/dev/null 2>&1
        apt-get install -y speedtest \
            >/dev/null 2>&1
        if ! command -v speedtest \
            >/dev/null 2>&1; then
            pip3 install speedtest-cli \
                --break-system-packages \
                >/dev/null 2>&1
        fi
    fi

    echo -e "  ${YELLOW}Testing... harap tunggu ~30 detik${NC}"
    echo ""

    local result
    if command -v speedtest >/dev/null 2>&1; then
        result=$(speedtest \
            --accept-license \
            --accept-gdpr \
            2>/dev/null)
        if [[ -n "$result" ]]; then
            local server latency dl ul url
            server=$(echo "$result" | \
                grep "Server:" | \
                sed 's/.*Server: //')
            latency=$(echo "$result" | \
                grep "Latency:" | \
                awk '{print $2,$3}')
            dl=$(echo "$result" | \
                grep "Download:" | \
                awk '{print $2,$3}')
            ul=$(echo "$result" | \
                grep "Upload:" | \
                awk '{print $2,$3}')
            url=$(echo "$result" | \
                grep "Result URL:" | \
                awk '{print $NF}')
            echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            printf "  %-16s : %s\n" "Server"   "$server"
            printf "  %-16s : %s\n" "Latency"  "$latency"
            printf "  %-16s : ${GREEN}%s${NC}\n" "Download" "$dl"
            printf "  %-16s : ${GREEN}%s${NC}\n" "Upload"   "$ul"
            [[ -n "$url" ]] && \
            printf "  %-16s : %s\n" "Result URL" "$url"
            echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        else
            echo -e "  ${RED}✘ Speedtest gagal!${NC}"
        fi
    else
        echo -e "  ${RED}✘ Speedtest tidak tersedia!${NC}"
    fi
    echo ""
    read -p "  Press any key to back..."
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
# SHOW SYSTEM INFO - DASHBOARD v3.0
#================================================

show_system_info() {
    clear

    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

    local os_name="Unknown"
    [[ -f /etc/os-release ]] && {
        source /etc/os-release
        os_name="${PRETTY_NAME}"
    }

    local ip_vps ram_used ram_total ram_pct cpu uptime_str
    local ssl_type svc_running svc_total

    ip_vps=$(get_ip)
    ram_used=$(free -m | awk 'NR==2{print $3}')
    ram_total=$(free -m | awk 'NR==2{print $2}')
    ram_pct=$(awk "BEGIN {printf \"%.0f\", ($ram_used/$ram_total)*100}")
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    uptime_str=$(uptime -p | sed 's/up //')

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && \
        domain_type=$(cat "$DOMAIN_TYPE_FILE")

    if [[ "$domain_type" == "custom" ]]; then
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            ssl_type="LetsEncrypt (Active)"
        else
            ssl_type="LetsEncrypt (Warn)"
        fi
    else
        ssl_type="Self-Signed"
    fi

    local services=(xray nginx sshd haproxy dropbear udp-custom vpn-keepalive vpn-bot)
    svc_total=${#services[@]}
    svc_running=0
    for svc in "${services[@]}"; do
        systemctl is-active --quiet "$svc" 2>/dev/null && ((svc_running++))
    done

    local ssh_count vmess_count vless_count trojan_count
    ssh_count=$(ls "$AKUN_DIR"/ssh-*.txt 2>/dev/null | wc -l)
    vmess_count=$(ls "$AKUN_DIR"/vmess-*.txt 2>/dev/null | wc -l)
    vless_count=$(ls "$AKUN_DIR"/vless-*.txt 2>/dev/null | wc -l)
    trojan_count=$(ls "$AKUN_DIR"/trojan-*.txt 2>/dev/null | wc -l)

    # RAM bar
    local ram_filled=$(( ram_pct / 10 ))
    local ram_bar=""
    for ((i=0; i<10; i++)); do
        if [[ $i -lt $ram_filled ]]; then
            ram_bar+="█"
        else
            ram_bar+="░"
        fi
    done

    # Box lebar 54 karakter konten (LINE = 54 karakter)
    local LINE="══════════════════════════════════════════════════════"

    # Cetak baris info: "  LABEL : VALUE" rata kiri, padding kanan otomatis
    # Semua value dipotong agar tidak melebihi lebar box
    _irow() {
        local label="$1"
        local value="$2"
        # Hitung panjang konten tanpa warna
        local content
        content=$(printf "  %-10s: %s" "$label" "$value")
        # Potong max 54 char
        if (( ${#content} > 54 )); then
            content="${content:0:54}"
        fi
        local pad=$(( 54 - ${#content} ))
        printf "${CYAN}║${NC}%s%*s${CYAN}║${NC}\n" "$content" "$pad" ""
    }

    # Cetak baris service: "  ● Label   ON/OFF"
    _srow() {
        local svc="$1" label="$2"
        local dot st
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            dot="${GREEN}●${NC}"; st="ON "
        else
            dot="${RED}○${NC}"; st="OFF"
        fi
        # konten plaintext: "  X Label              ON " = 26 char
        local plain
        plain=$(printf "  X %-14s   %s" "$label" "$st")
        local pad=$(( 54 - ${#plain} ))
        printf "${CYAN}║${NC}  %b %-14s   %s%*s${CYAN}║${NC}\n" \
            "$dot" "$label" "$st" "$pad" ""
    }

    echo -e "${CYAN}╔${LINE}╗${NC}"
    printf "${CYAN}║${NC}  ${WHITE}Youzin Crabz Tunel${NC} ${DIM}- The Professor${NC}%*s${CYAN}║${NC}\n" 5 ""
    echo -e "${CYAN}╠${LINE}╣${NC}"
    _irow "IP VPS"   "$ip_vps"
    _irow "Domain"   "${DOMAIN:-Not Set}"
    _irow "OS"       "${os_name:0:40}"
    _irow "Uptime"   "$uptime_str"
    _irow "CPU"      "${cpu}%"
    _irow "RAM"      "${ram_used}MB/${ram_total}MB [${ram_bar}] ${ram_pct}%"
    _irow "SSL"      "$ssl_type"
    _irow "Services" "${svc_running}/${svc_total} Running"
    echo -e "${CYAN}╠${LINE}╣${NC}"
    # Akun - hitung panjang manual agar pas
    printf "${CYAN}║${NC}  ${WHITE}SSH${NC}:${GREEN}%2d${NC}  ${WHITE}VMess${NC}:${GREEN}%2d${NC}  ${WHITE}VLess${NC}:${GREEN}%2d${NC}  ${WHITE}Trojan${NC}:${GREEN}%2d${NC}%*s${CYAN}║${NC}\n" \
        "$ssh_count" "$vmess_count" "$vless_count" "$trojan_count" 9 ""
    echo -e "${CYAN}╠${LINE}╣${NC}"
    _srow "xray"          "Xray"
    _srow "haproxy"       "HAProxy"
    _srow "nginx"         "Nginx"
    _srow "dropbear"      "Dropbear"
    _srow "sshd"          "SSH"
    _srow "udp-custom"    "UDP Custom"
    _srow "vpn-bot"       "Bot Telegram"
    _srow "vpn-keepalive" "Keepalive"
    echo -e "${CYAN}╚${LINE}╝${NC}"
    echo ""
}

#================================================
# SHOW MAIN MENU - REDESIGN BERSIH & RAPI
#================================================

show_menu() {
    local LINE="══════════════════════════════════════════════════════"
    echo -e "${CYAN}╔${LINE}╗${NC}"
    printf "${CYAN}║${NC}%*s${WHITE}${BOLD}✦  MAIN MENU  ✦${NC}%*s${CYAN}║${NC}\n" 20 "" 19 ""
    echo -e "${CYAN}╠${LINE}╣${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}── ACCOUNT MANAGEMENT ───────────────────────────${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[1]${NC} SSH/OpenVPN   ${CYAN}[4]${NC} Trojan   ${CYAN}[7]${NC} Cek Expired  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[2]${NC} VMess         ${CYAN}[5]${NC} Trial    ${CYAN}[8]${NC} Del Expired  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[3]${NC} VLess         ${CYAN}[6]${NC} List All               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}── SYSTEM & TOOLS ───────────────────────────────${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[9]${NC}  Bot Telegram  ${CYAN}[13]${NC} Restart  ${CYAN}[17]${NC} Backup      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[10]${NC} Domain        ${CYAN}[14]${NC} InfoPort ${CYAN}[18]${NC} Restore    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[11]${NC} Fix SSL       ${CYAN}[15]${NC} Speedtest ${CYAN}[19]${NC} Uninstall ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[12]${NC} Optimize VPS  ${CYAN}[16]${NC} Update   ${CYAN}[20]${NC} Advanced   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${CYAN}[0]${NC} Exit          ${DIM}[help]${NC} Bantuan               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚${LINE}╝${NC}"
    echo ""
}

#================================================
# INFO PORT
#================================================

show_info_port() {
    clear
    print_menu_header "SERVER PORT INFORMATION"
    echo -e "${CYAN}  ┌──────────────────────────────────────────────────┐${NC}"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "SSH" "22"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Dropbear" "222"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Nginx NonTLS" "80"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Nginx Download" "81"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "HAProxy TLS" "443 → Xray 8443"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Xray WS TLS" "443 (via HAProxy)"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Xray WS NonTLS" "80 (via Nginx)"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "Xray gRPC TLS" "8444"
    printf "  ${CYAN}│${NC}  ${WHITE}%-25s${NC} : ${GREEN}%-20s${NC}  ${CYAN}│${NC}\n" "BadVPN UDP" "7100-7300"
    echo -e "${CYAN}  └──────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "  Press any key to back..."
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
                echo -e "  ${RED}✘ EXPIRED${NC}: $uname"
                echo -e "    ${YELLOW}($exp_str)${NC}"
            else
                echo -e "  ${YELLOW}⚠ ${diff} hari${NC}: $uname"
                echo -e "    ${CYAN}($exp_str)${NC}"
            fi
        fi
    done
    shopt -u nullglob
    [[ $found -eq 0 ]] && \
        echo -e "  ${GREEN}✔ Tidak ada akun expired!${NC}"
    echo ""
    read -p "  Press any key to back..."
}

#================================================
# DELETE EXPIRED
#================================================

delete_expired() {
    clear
    print_menu_header "DELETE EXPIRED ACCOUNTS"
    local today count=0
    today=$(date +%s)
    shopt -s nullglob
    for f in "$AKUN_DIR"/*.txt; do
        [[ ! -f "$f" ]] && continue
        local exp_str exp_ts fname uname protocol
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
            echo -e "  ${RED}Deleting${NC}: $fname"
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
        echo -e "  ${GREEN}✔ Deleted ${count} accounts!${NC}"
    else
        echo -e "  ${GREEN}✔ Tidak ada akun expired!${NC}"
    fi
    echo ""
    read -p "  Press any key to back..."
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
        echo -e "  ${RED}✘ Failed update Xray!${NC}"
        sleep 2; return 1
    fi

    mkdir -p "$AKUN_DIR"
    printf \
        "UUID=%s\nQUOTA=%s\nIPLIMIT=%s\nEXPIRED=%s\nCREATED=%s\n" \
        "$uuid" "$quota" "$iplimit" \
        "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

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
 Port gRPC        : 8444
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

    _print_xray_result \
        "$protocol" "$username" "$ip_vps" \
        "$uuid" "$quota" "$iplimit" \
        "$link_tls" "$link_nontls" \
        "$link_grpc" "$days" \
        "$created" "$exp"

    # Kirim ke Telegram dengan format lengkap
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
🔌 Port gRPC  : 8444
━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Dibuat     : ${created}
⏳ Berakhir   : ${exp}
🔗 Download   : ${dl_link}
━━━━━━━━━━━━━━━━━━━━━━━━━
<i>Powered by The Professor</i>"

    read -p "  Press any key to back..."
}

#================================================
# PRINT XRAY RESULT
#================================================

_print_xray_result() {
    local protocol="$1"   username="$2"
    local ip_vps="$3"     uuid="$4"
    local quota="$5"      iplimit="$6"
    local link_tls="$7"   link_nontls="$8"
    local link_grpc="$9"  days="${10}"
    local created="${11}" exp="${12}"

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}${BOLD}YOUZIN CRABZ TUNEL${NC} — ${YELLOW}${protocol^^} Account${NC}"
    echo -e "  ${DIM}The Professor${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Username"    "$username"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "IP VPS"      "$ip_vps"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Domain"      "$DOMAIN"
    printf "  ${WHITE}%-16s${NC} : ${CYAN}%s${NC}\n"  "UUID"        "$uuid"
    printf "  ${WHITE}%-16s${NC} : %s GB\n"            "Quota"       "$quota"
    printf "  ${WHITE}%-16s${NC} : %s IP\n"            "IP Limit"    "$iplimit"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port TLS"    "443"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port NonTLS" "80"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port gRPC"   "8444"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Network"     "WebSocket / gRPC"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Path WS"     "/${protocol}"
    printf "  ${WHITE}%-16s${NC} : %s\n" "ServiceName" "${protocol}-grpc"
    printf "  ${WHITE}%-16s${NC} : %s\n" "TLS"         "enabled"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${YELLOW}%-16s${NC} :\n" "Link TLS"
    echo "  $link_tls"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${YELLOW}%-16s${NC} :\n" "Link NonTLS"
    echo "  $link_nontls"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${YELLOW}%-16s${NC} :\n" "Link gRPC"
    echo "  $link_grpc"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : http://%s:81/%s-%s.txt\n" \
        "Download" "$ip_vps" "$protocol" "$username"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : ${YELLOW}%s Hari${NC}\n" "Aktif Selama" "$days"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Dibuat"    "$created"
    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n"   "Berakhir"  "$exp"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

    local temp
    temp=$(mktemp)

    if [[ "$protocol" == "vmess" ]]; then
        jq --arg uuid "$uuid" \
           --arg email "$username" \
           '(.inbounds[] |
             select(.tag | startswith("vmess"))
             .settings.clients) +=
            [{"id":$uuid,"email":$email,"alterId":0}]' \
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
            [{"password":$password,"email":$email}]' \
           "$XRAY_CONFIG" > "$temp" 2>/dev/null
    fi

    if [[ $? -eq 0 ]] && [[ -s "$temp" ]]; then
        mv "$temp" "$XRAY_CONFIG"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        sleep 1
    else
        rm -f "$temp"
        echo -e "  ${RED}✘ Failed!${NC}"
        sleep 2; return
    fi

    mkdir -p "$AKUN_DIR"
    printf \
        "UUID=%s\nQUOTA=1\nIPLIMIT=1\nEXPIRED=%s\nCREATED=%s\nTRIAL=1\n" \
        "$uuid" "$exp" "$created" \
        > "$AKUN_DIR/${protocol}-${username}.txt"

    (
        sleep 3600
        local tmp2
        tmp2=$(mktemp)
        jq --arg email "$username" \
           'del(.inbounds[].settings.clients[]?
             | select(.email == $email))' \
           "$XRAY_CONFIG" > "$tmp2" \
           2>/dev/null && \
           mv "$tmp2" "$XRAY_CONFIG" || \
           rm -f "$tmp2"
        fix_xray_permissions
        systemctl restart xray 2>/dev/null
        rm -f \
            "$AKUN_DIR/${protocol}-${username}.txt"
        rm -f \
            "$PUBLIC_HTML/${protocol}-${username}.txt"
    ) &
    disown $!

    local link_tls link_nontls link_grpc

    if [[ "$protocol" == "vmess" ]]; then
        local j_tls j_nontls j_grpc
        j_tls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"443","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"tls"}' \
            "$username" "$uuid" "$DOMAIN")
        link_tls="vmess://$(printf '%s' "$j_tls" | base64 -w 0)"
        j_nontls=$(printf \
            '{"v":"2","ps":"%s","add":"bug.com","port":"80","id":"%s","aid":"0","net":"ws","path":"/vmess","type":"none","host":"%s","tls":"none"}' \
            "$username" "$uuid" "$DOMAIN")
        link_nontls="vmess://$(printf '%s' "$j_nontls" | base64 -w 0)"
        j_grpc=$(printf \
            '{"v":"2","ps":"%s","add":"%s","port":"8444","id":"%s","aid":"0","net":"grpc","path":"vmess-grpc","type":"none","host":"bug.com","tls":"tls"}' \
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

    clear
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}${BOLD}YOUZIN CRABZ TUNEL${NC} — ${YELLOW}Trial ${protocol^^} (1 Jam)${NC}"
    echo -e "  ${DIM}The Professor${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Username"    "$username"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "IP VPS"      "$ip_vps"
    printf "  ${WHITE}%-16s${NC} : ${GREEN}%s${NC}\n" "Domain"      "$DOMAIN"
    printf "  ${WHITE}%-16s${NC} : ${CYAN}%s${NC}\n"  "UUID"        "$uuid"
    printf "  ${WHITE}%-16s${NC} : 1 GB\n"             "Quota"
    printf "  ${WHITE}%-16s${NC} : 1 IP\n"             "IP Limit"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port TLS"    "443"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port NonTLS" "80"
    printf "  ${WHITE}%-16s${NC} : %s\n" "Port gRPC"   "8444"
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
    printf "  ${WHITE}%-16s${NC} : %s\n" "Dibuat"   "$created"
    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n"   "Berakhir" "$exp"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "  Press any key to back..."
}

#================================================
# CREATE SSH
#================================================

create_ssh() {
    clear
    print_menu_header "CREATE SSH ACCOUNT"
    read -p "  Username      : " username
    [[ -z "$username" ]] && {
        echo -e "  ${RED}✘ Required!${NC}"
        sleep 2; return
    }
    if id "$username" &>/dev/null; then
        echo -e "  ${RED}✘ User sudah ada!${NC}"
        sleep 2; return
    fi
    read -p "  Password      : " password
    [[ -z "$password" ]] && {
        echo -e "  ${RED}✘ Required!${NC}"
        sleep 2; return
    }
    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "  ${RED}✘ Invalid!${NC}"
        sleep 2; return
    }
    read -p "  Limit IP      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1

    local exp exp_date created ip_vps
    exp=$(date -d "+${days} days" +"%d %b, %Y")
    exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
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

    # Telegram lengkap
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

    read -p "  Press any key to back..."
}

#================================================
# SSH TRIAL
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
    exp=$(date -d "+1 hour" +"%d %b, %Y %H:%M")
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

    (
        sleep 3600
        userdel -f "$username" 2>/dev/null
        rm -f "$AKUN_DIR/ssh-${username}.txt"
        rm -f "$PUBLIC_HTML/ssh-${username}.txt"
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

    read -p "  Press any key to back..."
}

#================================================
# SSH HELPERS
#================================================

_save_ssh_file() {
    local title="$1"    username="$2"
    local password="$3" ip_vps="$4"
    local days="$5"     created="$6"
    local exp="$7"

    mkdir -p "$PUBLIC_HTML"
    cat > "$PUBLIC_HTML/ssh-${username}.txt" \
        << SSHFILE
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
    local title="$1"    username="$2"
    local password="$3" ip_vps="$4"
    local days="$5"     created="$6"
    local exp="$7"

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
    printf "  ${WHITE}%-16s${NC} : %s:80@%s:%s\n" \
        "Format Hc" "$DOMAIN" "$username" "$password"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : http://%s:81/ssh-%s.txt\n" \
        "Save Link" "$ip_vps" "$username"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: ws[crlf][crlf]\n" \
        "Payload" "$DOMAIN"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  ${WHITE}%-16s${NC} : ${YELLOW}%s${NC}\n"    "Aktif Selama"  "$days"
    printf "  ${WHITE}%-16s${NC} : %s\n"                   "Dibuat Pada"   "$created"
    printf "  ${WHITE}%-16s${NC} : ${RED}%s${NC}\n"        "Berakhir Pada" "$exp"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

#================================================
# DELETE / RENEW / LIST / CHECK LOGIN
#================================================

delete_account() {
    local protocol="$1"
    clear
    print_menu_header "DELETE ${protocol^^}"
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${RED}No accounts!${NC}"
        sleep 2; return
    fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "  ${CYAN}▸${NC} $n ${YELLOW}($e)${NC}"
    done
    echo ""
    read -p "  Username to delete: " username
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
    rm -f "$AKUN_DIR/${protocol}-${username}.txt"
    rm -f "$PUBLIC_HTML/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && \
        userdel -f "$username" 2>/dev/null
    echo -e "  ${GREEN}✔ Deleted: ${username}${NC}"
    sleep 2
}

renew_account() {
    local protocol="$1"
    clear
    print_menu_header "RENEW ${protocol^^}"
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${RED}No accounts!${NC}"
        sleep 2; return
    fi
    for f in "${files[@]}"; do
        local n e
        n=$(basename "$f" .txt | sed "s/${protocol}-//")
        e=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        echo -e "  ${CYAN}▸${NC} $n ${YELLOW}($e)${NC}"
    done
    echo ""
    read -p "  Username to renew: " username
    [[ -z "$username" ]] && return
    [[ ! -f "$AKUN_DIR/${protocol}-${username}.txt" ]] && {
        echo -e "  ${RED}✘ Not found!${NC}"
        sleep 2; return
    }
    read -p "  Add days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "  ${RED}✘ Invalid!${NC}"
        sleep 2; return
    }
    local new_exp new_exp_date
    new_exp=$(date -d "+${days} days" +"%d %b, %Y")
    new_exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    sed -i "s/EXPIRED=.*/EXPIRED=${new_exp}/" \
        "$AKUN_DIR/${protocol}-${username}.txt"
    [[ "$protocol" == "ssh" ]] && \
        chage -E "$new_exp_date" "$username" 2>/dev/null
    echo -e "  ${GREEN}✔ Renewed! Exp: ${new_exp}${NC}"
    sleep 3
}

list_accounts() {
    local protocol="$1"
    clear
    print_menu_header "${protocol^^} ACCOUNT LIST"
    shopt -s nullglob
    local files=("$AKUN_DIR"/${protocol}-*.txt)
    shopt -u nullglob
    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${RED}No accounts!${NC}"
        sleep 2; return
    fi
    echo -e "${CYAN}  ┌────────────────────────────────────────────────────┐${NC}"
    printf "  ${CYAN}│${NC} ${WHITE}%-20s %-20s %-6s %-5s${NC} ${CYAN}│${NC}\n" \
        "USERNAME" "EXPIRED" "QUOTA" "TYPE"
    echo -e "${CYAN}  ├────────────────────────────────────────────────────┤${NC}"
    for f in "${files[@]}"; do
        local uname exp quota trial ttype
        uname=$(basename "$f" .txt | sed "s/${protocol}-//")
        exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
        quota=$(grep "QUOTA" "$f" 2>/dev/null | cut -d= -f2)
        trial=$(grep "TRIAL" "$f" 2>/dev/null | cut -d= -f2)
        ttype="Member"
        [[ "$trial" == "1" ]] && ttype="Trial"
        printf "  ${CYAN}│${NC} ${GREEN}%-20s${NC} ${YELLOW}%-20s${NC} %-6s %-5s ${CYAN}│${NC}\n" \
            "$uname" "$exp" "${quota:-N/A}GB" "$ttype"
    done
    echo -e "${CYAN}  └────────────────────────────────────────────────────┘${NC}"
    echo -e "  Total: ${GREEN}${#files[@]}${NC} accounts"
    echo ""
    read -p "  Press any key to back..."
}

check_user_login() {
    local protocol="$1"
    clear
    print_menu_header "ACTIVE ${protocol^^} LOGINS"
    if [[ "$protocol" == "ssh" ]]; then
        echo -e "  ${WHITE}Active SSH sessions:${NC}"
        who 2>/dev/null || echo "  None"
        echo ""
        echo -e "  ${WHITE}Login count:${NC}"
        who 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn
    else
        echo -e "  ${WHITE}Xray ${protocol^^} log:${NC}"
        if [[ -f /var/log/xray/access.log ]]; then
            grep -i "$protocol" /var/log/xray/access.log \
                2>/dev/null | tail -20 || echo "  No data"
        else
            echo "  No log"
        fi
    fi
    echo ""
    read -p "  Press any key to back..."
}

#================================================
# SETUP TELEGRAM BOT
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
    read -p "  Bot Token     : " bot_token
    [[ -z "$bot_token" ]] && {
        echo -e "  ${RED}✘ Token required!${NC}"
        sleep 2; return
    }
    read -p "  Admin Chat ID : " admin_id
    [[ -z "$admin_id" ]] && {
        echo -e "  ${RED}✘ Chat ID required!${NC}"
        sleep 2; return
    }
    echo -e "  ${CYAN}Testing token...${NC}"
    local test_result bot_name
    test_result=$(curl -s --max-time 10 \
        "https://api.telegram.org/bot${bot_token}/getMe")
    if ! echo "$test_result" | grep -q '"ok":true'; then
        echo -e "  ${RED}✘ Token tidak valid!${NC}"
        sleep 2; return
    fi
    bot_name=$(echo "$test_result" | \
        python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d['result']['username'])
" 2>/dev/null)
    echo -e "  ${GREEN}✔ Bot valid! @${bot_name}${NC}"
    echo ""
    read -p "  Nama Pemilik Rekening : " rek_name
    read -p "  Nomor Rek/Dana/GoPay  : " rek_number
    read -p "  Bank / E-Wallet       : " rek_bank
    read -p "  Harga per Bulan (Rp)  : " harga
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
    read -p "  Press any key to back..."
}

#================================================
# INSTALL BOT SERVICE
#================================================

_install_bot_service() {
    mkdir -p /root/bot "$ORDER_DIR"

    pip3 install requests \
        --break-system-packages \
        >/dev/null 2>&1 || \
        pip3 install requests \
        >/dev/null 2>&1

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
    exp_str = (datetime.now() + timedelta(days=days)).strftime('%d %b, %Y')
    created = datetime.now().strftime('%d %b, %Y')
    run_cmd(f'useradd -M -s /bin/false -e {exp_date} {username} 2>/dev/null')
    run_cmd(f'echo "{username}:{password}" | chpasswd')
    with open(f'{AKUN_DIR}/ssh-{username}.txt','w') as f:
        f.write(f'USERNAME={username}\nPASSWORD={password}\nIPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n')
    ip = get_ip()
    with open(f'{HTML_DIR}/ssh-{username}.txt','w') as f:
        f.write(f'''━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  YOUZIN CRABZ TUNEL - SSH Account
  The Professor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Username         : {username}
 Password         : {password}
 IP/Host          : {ip}
 Domain SSH       : {DOMAIN}
 OpenSSH          : 22
 Dropbear         : 222
 Port SSH UDP     : 1-65535
 SSL/TLS          : 443
 BadVPN UDPGW     : 7100,7200,7300
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Aktif Selama     : {days} Hari
 Dibuat Pada      : {created}
 Berakhir Pada    : {exp_str}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''')
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

    run_cmd(cmd)
    run_cmd(f'chmod 644 {cfg}')
    run_cmd('systemctl restart xray')

    with open(f'{AKUN_DIR}/{protocol}-{username}.txt','w') as f:
        f.write(f'UUID={uid}\nQUOTA={quota}\nIPLIMIT=1\nEXPIRED={exp_str}\nCREATED={created}\n')

    ip = get_ip()

    if protocol == 'vmess':
        j_tls = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"443","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"tls"}}'
        link_tls = "vmess://" + base64.b64encode(j_tls.encode()).decode()
        j_ntls = f'{{"v":"2","ps":"{username}","add":"bug.com","port":"80","id":"{uid}","aid":"0","net":"ws","path":"/{protocol}","type":"none","host":"{DOMAIN}","tls":"none"}}'
        link_ntls = "vmess://" + base64.b64encode(j_ntls.encode()).decode()
        j_grpc = f'{{"v":"2","ps":"{username}","add":"{DOMAIN}","port":"8444","id":"{uid}","aid":"0","net":"grpc","path":"{protocol}-grpc","type":"none","host":"bug.com","tls":"tls"}}'
        link_grpc = "vmess://" + base64.b64encode(j_grpc.encode()).decode()
    elif protocol == 'vless':
        link_tls = f"vless://{uid}@bug.com:443?path=%2F{protocol}&security=tls&encryption=none&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"
        link_ntls = f"vless://{uid}@bug.com:80?path=%2F{protocol}&security=none&encryption=none&host={DOMAIN}&type=ws#{username}-NonTLS"
        link_grpc = f"vless://{uid}@{DOMAIN}:8444?mode=gun&security=tls&encryption=none&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"
    elif protocol == 'trojan':
        link_tls = f"trojan://{uid}@bug.com:443?path=%2F{protocol}&security=tls&host={DOMAIN}&type=ws&sni={DOMAIN}#{username}-TLS"
        link_ntls = f"trojan://{uid}@bug.com:80?path=%2F{protocol}&security=none&host={DOMAIN}&type=ws#{username}-NonTLS"
        link_grpc = f"trojan://{uid}@{DOMAIN}:8444?mode=gun&security=tls&type=grpc&serviceName={protocol}-grpc&sni=bug.com#{username}-gRPC"

    with open(f'{HTML_DIR}/{protocol}-{username}.txt','w') as f:
        f.write(f'''━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  YOUZIN CRABZ TUNEL - {protocol.upper()} Account
  The Professor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Username         : {username}
 UUID/Password    : {uid}
 Domain           : {DOMAIN}
 IP VPS           : {ip}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Port TLS         : 443
 Port NonTLS      : 80
 Port gRPC        : 8444
 Network          : WebSocket / gRPC
 Path WS          : /{protocol}
 ServiceName gRPC : {protocol}-grpc
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Link TLS         :
 {link_tls}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Link NonTLS      :
 {link_ntls}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Link gRPC        :
 {link_grpc}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Aktif Selama     : {days} Hari
 Berakhir Pada    : {exp_str}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''')
    return (uid, exp_str, ip, link_tls, link_ntls, link_grpc)

def fmt_ssh_msg(username, password, ip, exp_str, title, durasi="30 Hari"):
    return f'''✅ <b>{title}</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 Youzin Crabz Tunel
👤 Username : <code>{username}</code>
🔑 Password : <code>{password}</code>
🌐 Domain   : <code>{DOMAIN}</code>
🖥️ IP VPS   : <code>{ip}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 OpenSSH  : 22
🔌 Dropbear : 222
🔌 SSL/TLS  : 443
🔌 BadVPN   : 7100,7200,7300
━━━━━━━━━━━━━━━━━━━━━━━━━
⏰ Aktif    : {durasi}
📅 Expired  : {exp_str}
━━━━━━━━━━━━━━━━━━━━━━━━━
<i>The Professor</i>'''

def fmt_xray_msg(protocol, username, uid, ip, exp_str, link_tls, link_ntls, link_grpc, title, durasi="30 Hari"):
    return f'''✅ <b>{title}</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 Youzin Crabz Tunel
👤 Username : <code>{username}</code>
🔑 UUID     : <code>{uid}</code>
🌐 Domain   : <code>{DOMAIN}</code>
🖥️ IP VPS   : <code>{ip}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 Port TLS    : 443
🔌 Port NonTLS : 80
🔌 Port gRPC   : 8444
🔌 Path WS     : /{protocol}
🔌 ServiceName : {protocol}-grpc
━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 <b>Link TLS:</b>
<code>{link_tls}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 <b>Link NonTLS:</b>
<code>{link_ntls}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 <b>Link gRPC:</b>
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
            send(chat_id, f'❌ Gagal buat akun: {e}')
            return
        del_cmd = f'(sleep 3600; jq --arg email "{username}" \'del(.inbounds[].settings.clients[]? | select(.email == $email))\' /usr/local/etc/xray/config.json > /tmp/xd.json && mv /tmp/xd.json /usr/local/etc/xray/config.json; chmod 644 /usr/local/etc/xray/config.json; systemctl restart xray; rm -f {AKUN_DIR}/{protocol}-{username}.txt {HTML_DIR}/{protocol}-{username}.txt) & disown'
        run_cmd(del_cmd)
        msg = fmt_xray_msg(protocol, username, uid, ip, exp_1h, link_tls, link_ntls, link_grpc, f'Trial {protocol.upper()} Berhasil! 🆓', '1 Jam (Auto Hapus)')
        msg += '\n⚠️ <i>Auto hapus setelah 1 jam</i>'
        send(chat_id, msg, markup=kb_main())

def fmt_payment(order):
    pay = get_payment()
    harga = int(pay.get('HARGA', 10000))
    return f'''🛒 <b>Detail Order - Youzin Crabz Tunel</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
🆔 Order ID : <code>{order["order_id"]}</code>
📦 Paket    : {order["protocol"].upper()} 30 Hari
👤 Username : <code>{order["username"]}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
💰 <b>PEMBAYARAN</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
🏦 {pay.get("REK_BANK","N/A")}
📱 No : <code>{pay.get("REK_NUMBER","N/A")}</code>
👤 a/n: {pay.get("REK_NAME","N/A")}
💵 Nominal: <b>Rp {harga:,}</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
📸 Langkah:
1. Transfer Rp {harga:,}
2. Screenshot bukti bayar
3. Kirim ke admin
4. Tunggu konfirmasi
━━━━━━━━━━━━━━━━━━━━━━━━━
<i>The Professor</i>'''

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
    send(chat_id, f'''👋 Halo <b>{fname}</b>!

🤖 <b>Youzin Crabz Tunel Bot</b>
🌐 Server: <code>{DOMAIN}</code>
<i>Powered by The Professor</i>

<b>Menu:</b>
🆓 Trial Gratis → Akun 1 jam
🛒 Order VPN → 30 hari Rp {harga:,}
📋 Cek Akun → Lihat akun aktif
ℹ️ Info Server → Port & domain

Pilih menu di bawah 👇''', markup=kb_main())

def on_help(msg):
    chat_id = msg['chat']['id']
    pay = get_payment()
    harga = int(pay.get('HARGA',10000))
    send(chat_id, f'''❓ <b>PANDUAN BOT - Youzin Crabz Tunel</b>
━━━━━━━━━━━━━━━━━━━━━━━━━

🆓 <b>TRIAL (1 Jam)</b>
• Ketik 🆓 Trial Gratis
• Pilih SSH/VMess/VLess/Trojan
• Akun langsung dikirim
• Auto hapus setelah 1 jam

🛒 <b>ORDER (30 Hari)</b>
• Ketik 🛒 Order VPN
• Pilih protocol
• Masukkan username
• Transfer Rp {harga:,}
• Kirim bukti ke admin
• Akun dikirim setelah konfirmasi

💳 <b>PEMBAYARAN</b>
• Bank : {pay.get("REK_BANK","N/A")}
• No   : {pay.get("REK_NUMBER","N/A")}
• a/n  : {pay.get("REK_NAME","N/A")}
• Harga: Rp {harga:,}/bulan

📞 Masalah? Ketik 📞 Hubungi Admin
━━━━━━━━━━━━━━━━━━━━━━━━━
<i>The Professor</i>''', markup=kb_main())

def on_info(msg):
    chat_id = msg['chat']['id']
    ip = get_ip()
    send(chat_id, f'''ℹ️ <b>INFO SERVER - Youzin Crabz Tunel</b>
━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 Domain : <code>{DOMAIN}</code>
🖥️ IP VPS : <code>{ip}</code>
━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 <b>Port SSH:</b>
   OpenSSH   : 22
   Dropbear  : 222
   SSL/TLS   : 443
   BadVPN    : 7100-7300
━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 <b>Port Xray:</b>
   TLS (WS)  : 443
   NonTLS    : 80
   gRPC TLS  : 8444
   Path WS   : /vmess /vless /trojan
━━━━━━━━━━━━━━━━━━━━━━━━━
<i>The Professor</i>''', markup=kb_main())

def on_cek_akun(msg):
    chat_id = msg['chat']['id']
    found = []
    if not os.path.exists(ORDER_DIR):
        send(chat_id, '📋 Tidak ada akun aktif.', markup=kb_main())
        return
    for fn in os.listdir(ORDER_DIR):
        if not fn.endswith('.json'): continue
        try:
            with open(f'{ORDER_DIR}/{fn}') as f: order = json.load(f)
            if str(order.get('chat_id')) == str(chat_id) and order.get('status') == 'confirmed':
                proto = order.get('protocol','')
                uname = order.get('username','')
                af = f'{AKUN_DIR}/{proto}-{uname}.txt'
                exp = ''
                if os.path.exists(af):
                    with open(af) as a:
                        for line in a:
                            if 'EXPIRED=' in line: exp = line.split('=',1)[1].strip()
                found.append({'protocol':proto,'username':uname,'expired':exp})
        except: pass
    if not found:
        send(chat_id, f'📋 <b>Akun Kamu</b>\n\n❌ Tidak ada akun aktif.\n\nGunakan 🛒 Order VPN.', markup=kb_main())
        return
    text = '📋 <b>Akun Aktif Kamu - Youzin Crabz Tunel</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n'
    for a in found: text += f'📦 {a["protocol"].upper()}\n   👤 {a["username"]}\n   📅 {a["expired"]}\n\n'
    send(chat_id, text, markup=kb_main())

def on_contact(msg):
    chat_id = msg['chat']['id']
    fname = msg['from'].get('first_name','User')
    uname = msg['from'].get('username','')
    send(chat_id, '📞 Pesan diteruskan ke admin.\nTunggu balasan ya!', markup=kb_main())
    send(ADMIN_ID, f'📞 <b>User butuh bantuan! - Youzin Crabz Tunel</b>\n👤 Nama : {fname}\n📱 TG   : @{uname}\n🆔 ID   : <code>{chat_id}</code>')

def on_callback(cb):
    chat_id = cb['message']['chat']['id']
    cb_id = cb['id']
    data = cb['data']
    uname = cb['from'].get('username','')
    fname = cb['from'].get('first_name','User')

    answer_cb(cb_id)

    if data.startswith('trial_'):
        protocol = data.replace('trial_','')
        send(chat_id, f'⏳ Membuat trial {protocol.upper()}...')
        threading.Thread(target=do_trial, args=(protocol, chat_id), daemon=True).start()
    elif data.startswith('order_'):
        protocol = data.replace('order_','')
        pay = get_payment()
        harga = int(pay.get('HARGA',10000))
        with state_lock: user_state[chat_id] = {'step':'wait_username','protocol':protocol}
        send(chat_id, f'🛒 <b>Order {protocol.upper()} 30 Hari</b>\n💰 Harga: <b>Rp {harga:,}</b>\n\n✏️ Ketik username:\n<i>(3-20 karakter, huruf/angka)</i>', markup=kb_cancel())
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
                send(ADMIN_ID, f'✅ Akun {order["protocol"].upper()} <code>{order["username"]}</code> dikirim ke @{order.get("tg_user","?")}')
            else: send(ADMIN_ID, f'❌ Gagal: {result}')
        threading.Thread(target=do_confirm, daemon=True).start()
    elif data.startswith('reject_') and chat_id == ADMIN_ID:
        oid = data.replace('reject_','')
        order = load_order(oid)
        if not order: send(ADMIN_ID,'❌ Tidak ada!'); return
        order['status'] = 'rejected'
        save_order(oid, order)
        send(order['chat_id'], f'❌ <b>Order Ditolak</b>\nID: <code>{oid}</code>\n\nHubungi admin.', markup=kb_main())
        send(ADMIN_ID, f'❌ Order <code>{oid}</code> ditolak.')

def on_msg(msg):
    if 'text' not in msg: return
    chat_id = msg['chat']['id']
    text = msg['text'].strip()
    uname = msg['from'].get('username','')
    fname = msg['from'].get('first_name','User')

    with state_lock: state = user_state.get(chat_id, {})

    if state.get('step') == 'wait_username':
        new_u = text.strip().replace(' ','_')
        if len(new_u) < 3 or len(new_u) > 20:
            send(chat_id, '❌ Username 3-20 karakter!\nCoba lagi:', markup=kb_cancel())
            return
        protocol = state['protocol']
        oid = f'{chat_id}_{int(time.time())}'
        order = {'order_id':oid,'chat_id':chat_id,'username':new_u,'protocol':protocol,'status':'pending','created_at':datetime.now().isoformat(),'tg_user':uname,'tg_name':fname}
        save_order(oid, order)
        with state_lock: user_state.pop(chat_id, None)
        send(chat_id, fmt_payment(order))
        pay = get_payment()
        harga = int(pay.get('HARGA',10000))
        send(ADMIN_ID, f'🔔 <b>ORDER BARU! - Youzin Crabz Tunel</b>\n━━━━━━━━━━━━━━━━━━━━━━━━━\n🆔 ID    : <code>{oid}</code>\n📦 Paket : {protocol.upper()} 30 Hari\n👤 User  : <code>{new_u}</code>\n📱 TG    : @{uname}\n💰 Harga : Rp {harga:,}\n━━━━━━━━━━━━━━━━━━━━━━━━━\n⏳ Tunggu bukti bayar.', markup=kb_confirm(oid))
        return

    if text in ['/start','🏠 Menu']: on_start(msg)
    elif text in ['/help','❓ Bantuan']: on_help(msg)
    elif text == '🆓 Trial Gratis': send(chat_id, '🆓 <b>Trial Gratis 1 Jam</b>\n\nPilih protocol:', markup=kb_trial())
    elif text == '🛒 Order VPN':
        pay = get_payment()
        harga = int(pay.get('HARGA',10000))
        send(chat_id, f'🛒 <b>Order VPN 30 Hari</b>\n💰 Harga: <b>Rp {harga:,}</b>\n\nPilih protocol:', markup=kb_order())
    elif text == '📋 Cek Akun Saya': on_cek_akun(msg)
    elif text == 'ℹ️ Info Server': on_info(msg)
    elif text == '📞 Hubungi Admin': on_contact(msg)
    elif text == '/orders' and chat_id == ADMIN_ID:
        orders = get_pending()
        if not orders: send(ADMIN_ID,'📭 Tidak ada pending.'); return
        pay = get_payment()
        harga = int(pay.get('HARGA',10000))
        for o in orders[:5]:
            send(ADMIN_ID, f'🔔 <b>PENDING</b>\nID: <code>{o["order_id"]}</code>\nPaket: {o["protocol"].upper()}\nUser: <code>{o["username"]}</code>\nTG: @{o.get("tg_user","N/A")}\nHarga: Rp {harga:,}', markup=kb_confirm(o['order_id']))
    elif text.startswith('/konfirm ') and chat_id == ADMIN_ID:
        oid = text.split(' ',1)[1].strip()
        order = load_order(oid)
        if order: send(ADMIN_ID, f'Order: <code>{oid}</code>', markup=kb_confirm(oid))
        else: send(ADMIN_ID,'❌ Tidak ditemukan.')

def main():
    print(f'Youzin Crabz Tunel Bot - Admin: {ADMIN_ID}', flush=True)
    offset = 0
    pool = []
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
        except KeyboardInterrupt: print('Bot stopped.', flush=True); break
        except Exception as e: print(f'Loop: {e}', flush=True); time.sleep(2)

if __name__ == '__main__': main()
BOTEOF

    chmod +x /root/bot/bot.py

    cat > /etc/systemd/system/vpn-bot.service << 'SVCEOF'
[Unit]
Description=Youzin Crabz Tunel Bot
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
        printf "  Status: ${cs}\n"
        echo ""
        echo -e "  ${WHITE}[1]${NC} Setup Bot"
        echo -e "  ${WHITE}[2]${NC} Start Bot"
        echo -e "  ${WHITE}[3]${NC} Stop Bot"
        echo -e "  ${WHITE}[4]${NC} Restart Bot"
        echo -e "  ${WHITE}[5]${NC} Lihat Log"
        echo -e "  ${WHITE}[6]${NC} Order Pending"
        echo -e "  ${WHITE}[7]${NC} Info Bot"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
        case $choice in
            1) setup_telegram_bot ;;
            2)
                systemctl start vpn-bot
                echo -e "  ${GREEN}✔ Started!${NC}"
                sleep 2
                ;;
            3)
                systemctl stop vpn-bot
                echo -e "  ${YELLOW}Stopped!${NC}"
                sleep 2
                ;;
            4)
                systemctl restart vpn-bot
                echo -e "  ${GREEN}✔ Restarted!${NC}"
                sleep 2
                ;;
            5)
                clear
                journalctl -u vpn-bot -n 50 --no-pager
                echo ""
                read -p "  Press any key..."
                ;;
            6)
                clear
                print_menu_header "ORDER PENDING"
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
                    if [[ "$st" == "pending" ]]; then
                        found=1
                        python3 -c "
import json
d=json.load(open('$f'))
print(f'  Order ID : {d[\"order_id\"]}')
print(f'  Protocol : {d[\"protocol\"].upper()}')
print(f'  Username : {d[\"username\"]}')
print(f'  TG User  : @{d.get(\"tg_user\",\"N/A\")}')
print(f'  Status   : {d[\"status\"]}')
print('  ---')
" 2>/dev/null
                    fi
                done
                shopt -u nullglob
                [[ $found -eq 0 ]] && \
                    echo -e "  ${GREEN}✔ Tidak ada pending!${NC}"
                echo ""
                read -p "  Press any key..."
                ;;
            7)
                clear
                print_menu_header "BOT INFO"
                if [[ -f "$BOT_TOKEN_FILE" ]]; then
                    local aid
                    aid=$(cat "$CHAT_ID_FILE" 2>/dev/null)
                    printf "  %-16s : %s\n" "Status"   "$bs"
                    printf "  %-16s : %s\n" "Admin ID" "$aid"
                    if [[ -f "$PAYMENT_FILE" ]]; then
                        source "$PAYMENT_FILE"
                        echo ""
                        printf "  %-16s : %s\n" "Bank"      "$REK_BANK"
                        printf "  %-16s : %s\n" "No Rek"    "$REK_NUMBER"
                        printf "  %-16s : %s\n" "Atas Nama" "$REK_NAME"
                        printf "  %-16s : Rp %s\n" "Harga"    "$HARGA"
                    fi
                else
                    echo -e "  ${RED}Bot belum setup!${NC}"
                fi
                echo ""
                read -p "  Press any key..."
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
    print_menu_header "CREATE VMESS ACCOUNT"
    read -p "  Username      : " username
    [[ -z "$username" ]] && {
        echo -e "  ${RED}✘ Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "  ${RED}✘ Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "  ${RED}✘ Invalid!${NC}"
        sleep 2; return
    }
    read -p "  Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p "  IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vmess" "$username" \
        "$days" "$quota" "$iplimit"
}

create_vless() {
    clear
    print_menu_header "CREATE VLESS ACCOUNT"
    read -p "  Username      : " username
    [[ -z "$username" ]] && {
        echo -e "  ${RED}✘ Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "  ${RED}✘ Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "  ${RED}✘ Invalid!${NC}"
        sleep 2; return
    }
    read -p "  Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p "  IP Limit      : " iplimit
    [[ ! "$iplimit" =~ ^[0-9]+$ ]] && iplimit=1
    create_account_template \
        "vless" "$username" \
        "$days" "$quota" "$iplimit"
}

create_trojan() {
    clear
    print_menu_header "CREATE TROJAN ACCOUNT"
    read -p "  Username      : " username
    [[ -z "$username" ]] && {
        echo -e "  ${RED}✘ Required!${NC}"
        sleep 2; return
    }
    if grep -q "\"email\":\"${username}\"" \
        "$XRAY_CONFIG" 2>/dev/null; then
        echo -e "  ${RED}✘ Username sudah ada!${NC}"
        sleep 2; return
    fi
    read -p "  Expired (days): " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && {
        echo -e "  ${RED}✘ Invalid!${NC}"
        sleep 2; return
    }
    read -p "  Quota (GB)    : " quota
    [[ ! "$quota" =~ ^[0-9]+$ ]] && quota=100
    read -p "  IP Limit      : " iplimit
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
        echo -e "  ${WHITE}[1]${NC} Create SSH"
        echo -e "  ${WHITE}[2]${NC} Trial SSH (1 Jam)"
        echo -e "  ${WHITE}[3]${NC} Delete SSH"
        echo -e "  ${WHITE}[4]${NC} Renew SSH"
        echo -e "  ${WHITE}[5]${NC} Cek Login SSH"
        echo -e "  ${WHITE}[6]${NC} List User SSH"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
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

menu_vmess() {
    while true; do
        clear
        print_menu_header "VMESS MENU"
        echo -e "  ${WHITE}[1]${NC} Create VMess"
        echo -e "  ${WHITE}[2]${NC} Trial VMess (1 Jam)"
        echo -e "  ${WHITE}[3]${NC} Delete VMess"
        echo -e "  ${WHITE}[4]${NC} Renew VMess"
        echo -e "  ${WHITE}[5]${NC} Cek Login VMess"
        echo -e "  ${WHITE}[6]${NC} List User VMess"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
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

menu_vless() {
    while true; do
        clear
        print_menu_header "VLESS MENU"
        echo -e "  ${WHITE}[1]${NC} Create VLess"
        echo -e "  ${WHITE}[2]${NC} Trial VLess (1 Jam)"
        echo -e "  ${WHITE}[3]${NC} Delete VLess"
        echo -e "  ${WHITE}[4]${NC} Renew VLess"
        echo -e "  ${WHITE}[5]${NC} Cek Login VLess"
        echo -e "  ${WHITE}[6]${NC} List User VLess"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
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

menu_trojan() {
    while true; do
        clear
        print_menu_header "TROJAN MENU"
        echo -e "  ${WHITE}[1]${NC} Create Trojan"
        echo -e "  ${WHITE}[2]${NC} Trial Trojan (1 Jam)"
        echo -e "  ${WHITE}[3]${NC} Delete Trojan"
        echo -e "  ${WHITE}[4]${NC} Renew Trojan"
        echo -e "  ${WHITE}[5]${NC} Cek Login Trojan"
        echo -e "  ${WHITE}[6]${NC} List User Trojan"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
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
# INSTALL UDP CUSTOM
#================================================

install_udp_custom() {
    clear
    print_menu_header "INSTALL UDP CUSTOM (7100-7300)"

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
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
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
    systemctl restart udp-custom
    sleep 1

    if systemctl is-active --quiet udp-custom; then
        echo -e "  ${GREEN}✔ UDP OK! (7100-7300)${NC}"
    else
        echo -e "  ${RED}✘ UDP Failed!${NC}"
        journalctl -u udp-custom -n 5 --no-pager
    fi
    sleep 2
}

#================================================
# UPDATE SCRIPT
#================================================

update_menu() {
    clear
    print_menu_header "UPDATE SCRIPT"
    echo -e "  Current Version : ${GREEN}${SCRIPT_VERSION}${NC}"
    echo ""
    echo -e "  ${CYAN}Checking GitHub for updates...${NC}"

    local latest
    latest=$(curl -s --max-time 10 \
        "$VERSION_URL" 2>/dev/null | \
        tr -d '\n\r ' | xargs)

    if [[ -z "$latest" ]]; then
        echo -e "  ${RED}✘ Cannot connect to GitHub!${NC}"
        echo ""
        echo -e "  ${WHITE}Repository: ${CYAN}${GITHUB_USER}/${GITHUB_REPO}${NC}"
        echo ""
        read -p "  Press Enter to back..."
        return
    fi

    echo -e "  Latest Version  : ${GREEN}${latest}${NC}"
    echo ""

    if [[ "$latest" == "$SCRIPT_VERSION" ]]; then
        echo -e "  ${GREEN}✔ You are using the latest version!${NC}"
        echo ""
        read -p "  Press Enter to back..."
        return
    fi

    local current_num latest_num
    current_num=$(echo "$SCRIPT_VERSION" | tr -d '.')
    latest_num=$(echo "$latest" | tr -d '.')

    if [[ "$latest_num" -lt "$current_num" ]]; then
        echo -e "  ${YELLOW}⚠ Your version is newer than GitHub!${NC}"
        echo ""
        read -p "  Downgrade to stable? [y/N]: " confirm
        [[ "$confirm" != "y" ]] && return
    else
        echo -e "  ${YELLOW}⬆ Update tersedia!${NC}"
        echo ""
        read -p "  Update now? [y/N]: " confirm
        [[ "$confirm" != "y" ]] && return
    fi

    echo ""
    echo -e "  ${CYAN}Backing up...${NC}"
    cp "$SCRIPT_PATH" "$BACKUP_PATH" 2>/dev/null && \
        echo -e "  ${GREEN}✔ Backup created${NC}" || \
        echo -e "  ${RED}✘ Backup failed${NC}"

    echo -e "  ${CYAN}Downloading v${latest}...${NC}"
    local tmp="/tmp/tunnel_new.sh"
    curl -L --max-time 60 "$SCRIPT_URL" -o "$tmp" 2>/dev/null

    if [[ ! -s "$tmp" ]]; then
        echo -e "  ${RED}✘ Download failed!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        read -p "  Press Enter to back..."
        return
    fi

    bash -n "$tmp" 2>/dev/null && \
        echo -e "  ${GREEN}✔ Syntax OK${NC}" || {
        echo -e "  ${RED}✘ Syntax error!${NC}"
        cp "$BACKUP_PATH" "$SCRIPT_PATH"
        rm -f "$tmp"
        read -p "  Press Enter to back..."
        return
    }

    mv "$tmp" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"

    echo -e ""
    echo -e "  ${GREEN}✔ Update sukses! v${SCRIPT_VERSION} → v${latest}${NC}"
    echo ""
    echo -e "  ${YELLOW}Restarting in 3 detik...${NC}"
    sleep 3
    exec bash "$SCRIPT_PATH"
}

rollback_script() {
    clear
    print_menu_header "ROLLBACK SCRIPT"
    if [[ ! -f "$BACKUP_PATH" ]]; then
        echo -e "  ${RED}✘ No backup file found!${NC}"
        echo ""
        read -p "  Press Enter to back..."
        return
    fi
    local backup_ver
    backup_ver=$(grep "SCRIPT_VERSION=" \
        "$BACKUP_PATH" 2>/dev/null | \
        head -1 | cut -d'"' -f2)
    echo -e "  Current Version : ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e "  Backup Version  : ${YELLOW}${backup_ver:-Unknown}${NC}"
    echo ""
    read -p "  Rollback now? [y/N]: " confirm
    [[ "$confirm" != "y" ]] && return
    cp "$BACKUP_PATH" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "  ${GREEN}✔ Rollback sukses!${NC}"
    sleep 2
    exec bash "$SCRIPT_PATH"
}

#================================================
# ADVANCED MENU - SEMUA FUNGSI AKTIF
#================================================

menu_advanced() {
    while true; do
        clear
        local LINE="══════════════════════════════════════════════════════"
        echo -e "${CYAN}╔${LINE}╗${NC}"
        printf "${CYAN}║${NC}%*s${WHITE}${BOLD}⚙  ADVANCED SETTINGS${NC}%*s${CYAN}║${NC}\n" 17 "" 17 ""
        echo -e "${CYAN}╠${LINE}╣${NC}"
        echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[1]${NC}  Port Management    ${CYAN}[7]${NC}  Firewall Rules      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[2]${NC}  Protocol Settings  ${CYAN}[8]${NC}  Bandwidth Monitor   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[3]${NC}  Auto Backup        ${CYAN}[9]${NC}  User IP Limits      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[4]${NC}  SSH Brute Protect  ${CYAN}[10]${NC} Custom Payload     ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[5]${NC}  Fail2Ban Setup     ${CYAN}[11]${NC} Cron Jobs          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[6]${NC}  DDoS Protection    ${CYAN}[12]${NC} System Logs        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${CYAN}[0]${NC}  Back to Main Menu                           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                      ${CYAN}║${NC}"
        echo -e "${CYAN}╚${LINE}╝${NC}"
        echo ""
        read -p "  Select [0-12]: " choice

        case $choice in
            1) _adv_port_management ;;
            2) _adv_protocol_settings ;;
            3) _adv_auto_backup ;;
            4) _adv_ssh_brute_protection ;;
            5) _adv_fail2ban ;;
            6) _adv_ddos_protection ;;
            7) _adv_firewall ;;
            8) _adv_bandwidth_monitor ;;
            9) _adv_user_limits ;;
            10) _adv_custom_payload ;;
            11) _adv_cron_jobs ;;
            12) _adv_system_logs ;;
            0) return ;;
        esac
    done
}

_adv_port_management() {
    clear
    print_menu_header "PORT MANAGEMENT"
    echo -e "  ${YELLOW}Current Active Ports:${NC}"
    echo ""
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "SSH" "22"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Dropbear" "222"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Nginx (NonTLS)" "80"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Nginx Download" "81"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "HAProxy (TLS)" "443"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Xray Internal TLS" "8443"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Xray Internal NonTLS" "8080"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "Xray gRPC" "8444"
    printf "  ${WHITE}%-22s${NC} : ${GREEN}%s${NC}\n" "BadVPN UDP" "7100-7300"
    echo ""
    echo -e "  ${CYAN}Listening Ports (ss -tlnp):${NC}"
    echo ""
    ss -tlnp 2>/dev/null | grep -E "LISTEN|22|80|81|222|443|8080|8443|8444" | head -20
    echo ""
    read -p "  Press any key to back..."
}

_adv_protocol_settings() {
    clear
    print_menu_header "PROTOCOL SETTINGS"
    echo ""
    echo -e "  ${YELLOW}Xray Config Info:${NC}"
    echo ""
    if [[ -f "$XRAY_CONFIG" ]]; then
        local inbound_count
        inbound_count=$(jq '.inbounds | length' "$XRAY_CONFIG" 2>/dev/null)
        echo -e "  ${WHITE}Total Inbounds  :${NC} ${GREEN}${inbound_count:-0}${NC}"
        echo ""
        echo -e "  ${CYAN}Inbound List:${NC}"
        jq -r '.inbounds[] | "  → \(.tag) | port \(.port) | \(.protocol)"' \
            "$XRAY_CONFIG" 2>/dev/null
    else
        echo -e "  ${RED}Config tidak ditemukan!${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}Options:${NC}"
    echo -e "  ${WHITE}[1]${NC} Restart Xray"
    echo -e "  ${WHITE}[2]${NC} Lihat Config Xray"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            systemctl restart xray && \
                echo -e "  ${GREEN}✔ Xray restarted!${NC}" || \
                echo -e "  ${RED}✘ Failed!${NC}"
            sleep 2
            ;;
        2)
            clear
            cat "$XRAY_CONFIG" 2>/dev/null || \
                echo "  Config tidak ada"
            echo ""
            read -p "  Press any key..."
            ;;
    esac
}

_adv_auto_backup() {
    clear
    print_menu_header "AUTO BACKUP CONFIG"
    echo ""
    echo -e "  ${YELLOW}Setup Auto Backup Harian:${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC} Enable Auto Backup (setiap hari jam 02:00)"
    echo -e "  ${WHITE}[2]${NC} Disable Auto Backup"
    echo -e "  ${WHITE}[3]${NC} Backup Sekarang"
    echo -e "  ${WHITE}[4]${NC} Lihat Jadwal Backup"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            mkdir -p /root/backups
            # Tambah cron job backup harian
            (crontab -l 2>/dev/null | grep -v "vpn-autobackup"; \
             echo "0 2 * * * tar -czf /root/backups/vpn-backup-\$(date +\%Y\%m\%d).tar.gz /root/akun /root/domain /usr/local/etc/xray/config.json /etc/xray 2>/dev/null") | \
             crontab -
            echo -e "  ${GREEN}✔ Auto backup aktif! (Setiap hari jam 02:00)${NC}"
            sleep 2
            ;;
        2)
            crontab -l 2>/dev/null | grep -v "vpn-autobackup\|vpn-backup" | crontab -
            echo -e "  ${YELLOW}Auto backup dimatikan.${NC}"
            sleep 2
            ;;
        3)
            _menu_backup
            ;;
        4)
            clear
            echo -e "  ${CYAN}Cron Jobs VPN:${NC}"
            crontab -l 2>/dev/null | grep -E "backup|vpn" || echo "  Tidak ada auto backup"
            echo ""
            read -p "  Press any key..."
            ;;
    esac
}

_adv_ssh_brute_protection() {
    clear
    print_menu_header "SSH BRUTE FORCE PROTECTION"
    echo ""
    echo -e "  ${YELLOW}Menggunakan iptables rate limiting:${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC} Aktifkan SSH Brute Protection"
    echo -e "  ${WHITE}[2]${NC} Lihat IP yang diblokir"
    echo -e "  ${WHITE}[3]${NC} Reset semua block"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            # Rate limit SSH: max 5 koneksi per menit per IP
            iptables -I INPUT -p tcp --dport 22 -m state --state NEW \
                -m recent --set --name SSH 2>/dev/null
            iptables -I INPUT -p tcp --dport 22 -m state --state NEW \
                -m recent --update --seconds 60 --hitcount 6 \
                --name SSH -j DROP 2>/dev/null
            iptables -I INPUT -p tcp --dport 222 -m state --state NEW \
                -m recent --set --name DROPBEAR 2>/dev/null
            iptables -I INPUT -p tcp --dport 222 -m state --state NEW \
                -m recent --update --seconds 60 --hitcount 6 \
                --name DROPBEAR -j DROP 2>/dev/null
            # Simpan rules
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
            echo -e "  ${GREEN}✔ SSH Brute Protection AKTIF!${NC}"
            echo -e "  ${DIM}Max 5 koneksi baru per menit per IP${NC}"
            sleep 3
            ;;
        2)
            clear
            echo -e "  ${CYAN}Blokir dari iptables:${NC}"
            iptables -L INPUT -n 2>/dev/null | grep "DROP\|REJECT" | head -20
            echo ""
            read -p "  Press any key..."
            ;;
        3)
            iptables -F 2>/dev/null
            iptables -X 2>/dev/null
            echo -e "  ${GREEN}✔ Semua iptables rules direset!${NC}"
            sleep 2
            ;;
    esac
}

_adv_fail2ban() {
    clear
    print_menu_header "FAIL2BAN SETUP"
    echo ""
    if command -v fail2ban-client >/dev/null 2>&1; then
        echo -e "  ${GREEN}✔ Fail2ban sudah terinstall${NC}"
        echo ""
        echo -e "  ${CYAN}Status:${NC}"
        fail2ban-client status 2>/dev/null | head -20
    else
        echo -e "  ${YELLOW}Fail2ban belum terinstall${NC}"
        echo ""
        read -p "  Install Fail2ban? [y/N]: " c
        if [[ "$c" == "y" ]]; then
            echo -e "  ${CYAN}Installing...${NC}"
            apt-get install -y fail2ban >/dev/null 2>&1

            # Konfigurasi dasar fail2ban untuk SSH
            cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = 22,222
logpath  = %(sshd_log)s
maxretry = 5
bantime  = 7200

[sshd-ddos]
enabled  = true
port     = 22,222
logpath  = %(sshd_log)s
maxretry = 20
findtime = 120
bantime  = 86400
F2BEOF

            systemctl enable fail2ban >/dev/null 2>&1
            systemctl restart fail2ban >/dev/null 2>&1
            echo -e "  ${GREEN}✔ Fail2ban terinstall & dikonfigurasi!${NC}"
        fi
    fi
    echo ""
    read -p "  Press any key to back..."
}

_adv_ddos_protection() {
    clear
    print_menu_header "DDOS PROTECTION"
    echo ""
    echo -e "  ${YELLOW}SYN Flood & DDoS Protection via iptables:${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC} Aktifkan DDoS Protection"
    echo -e "  ${WHITE}[2]${NC} Lihat statistik paket"
    echo -e "  ${WHITE}[3]${NC} Nonaktifkan"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            # SYN flood protection
            sysctl -w net.ipv4.tcp_syncookies=1 >/dev/null 2>&1
            sysctl -w net.ipv4.tcp_max_syn_backlog=2048 >/dev/null 2>&1
            sysctl -w net.ipv4.tcp_synack_retries=2 >/dev/null 2>&1

            # iptables rules
            iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP 2>/dev/null
            iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP 2>/dev/null
            iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP 2>/dev/null

            # Connection limit per IP
            iptables -A INPUT -p tcp --dport 443 \
                -m connlimit --connlimit-above 80 -j REJECT 2>/dev/null
            iptables -A INPUT -p tcp --dport 80 \
                -m connlimit --connlimit-above 80 -j REJECT 2>/dev/null

            iptables-save > /etc/iptables/rules.v4 2>/dev/null
            echo -e "  ${GREEN}✔ DDoS Protection AKTIF!${NC}"
            echo -e "  ${DIM}SYN cookies, TCP flags filtering, connection limit aktif${NC}"
            sleep 3
            ;;
        2)
            clear
            echo -e "  ${CYAN}Statistik iptables:${NC}"
            iptables -L -n -v 2>/dev/null | head -40
            echo ""
            read -p "  Press any key..."
            ;;
        3)
            iptables -F 2>/dev/null
            echo -e "  ${YELLOW}DDoS rules direset.${NC}"
            sleep 2
            ;;
    esac
}

_adv_firewall() {
    clear
    print_menu_header "FIREWALL RULES"
    echo ""
    if command -v ufw >/dev/null 2>&1; then
        echo -e "  ${CYAN}UFW Status:${NC}"
        ufw status numbered 2>/dev/null
        echo ""
        echo -e "  ${WHITE}[1]${NC} Enable UFW"
        echo -e "  ${WHITE}[2]${NC} Disable UFW"
        echo -e "  ${WHITE}[3]${NC} Allow Port Custom"
        echo -e "  ${WHITE}[4]${NC} Block IP"
        echo -e "  ${WHITE}[0]${NC} Back"
        echo ""
        read -p "  Select: " c
        case $c in
            1)
                ufw allow 22/tcp >/dev/null 2>&1
                ufw allow 222/tcp >/dev/null 2>&1
                ufw allow 80/tcp >/dev/null 2>&1
                ufw allow 81/tcp >/dev/null 2>&1
                ufw allow 443/tcp >/dev/null 2>&1
                ufw allow 8444/tcp >/dev/null 2>&1
                ufw allow 7100:7300/udp >/dev/null 2>&1
                echo "y" | ufw enable >/dev/null 2>&1
                echo -e "  ${GREEN}✔ UFW Enabled!${NC}"
                sleep 2
                ;;
            2)
                ufw disable >/dev/null 2>&1
                echo -e "  ${YELLOW}UFW Disabled${NC}"
                sleep 2
                ;;
            3)
                read -p "  Port yang ingin dibuka: " port
                [[ -n "$port" ]] && {
                    ufw allow "$port" >/dev/null 2>&1
                    echo -e "  ${GREEN}✔ Port $port dibuka!${NC}"
                }
                sleep 2
                ;;
            4)
                read -p "  IP yang ingin diblock: " ip
                [[ -n "$ip" ]] && {
                    ufw deny from "$ip" >/dev/null 2>&1
                    echo -e "  ${GREEN}✔ IP $ip diblock!${NC}"
                }
                sleep 2
                ;;
        esac
    else
        echo -e "  ${YELLOW}UFW tidak terinstall.${NC}"
        read -p "  Install UFW? [y/N]: " c
        if [[ "$c" == "y" ]]; then
            apt-get install -y ufw >/dev/null 2>&1
            echo -e "  ${GREEN}✔ UFW terinstall!${NC}"
        fi
        sleep 2
    fi
}

_adv_bandwidth_monitor() {
    clear
    print_menu_header "BANDWIDTH MONITOR"
    echo ""

    if command -v vnstat >/dev/null 2>&1; then
        echo -e "  ${CYAN}Statistik Bandwidth (vnstat):${NC}"
        echo ""
        vnstat 2>/dev/null || echo "  Belum ada data"
        echo ""
        echo -e "  ${WHITE}[1]${NC} Live monitor (ctrl+c untuk stop)"
        echo -e "  ${WHITE}[0]${NC} Back"
        echo ""
        read -p "  Select: " c
        case $c in
            1)
                clear
                echo -e "  ${CYAN}Live Bandwidth (setiap 2 detik):${NC}"
                vnstat -l 2>/dev/null
                ;;
        esac
    else
        echo -e "  ${YELLOW}vnstat tidak terinstall.${NC}"
        echo ""
        read -p "  Install vnstat? [y/N]: " c
        if [[ "$c" == "y" ]]; then
            apt-get install -y vnstat >/dev/null 2>&1
            systemctl enable vnstat >/dev/null 2>&1
            systemctl start vnstat >/dev/null 2>&1
            echo -e "  ${GREEN}✔ vnstat terinstall!${NC}"
            echo -e "  ${DIM}Data akan tersedia setelah beberapa menit.${NC}"
        fi
        sleep 2
    fi
    echo ""
    read -p "  Press any key to back..."
}

_adv_user_limits() {
    clear
    print_menu_header "USER IP LIMITS"
    echo ""
    echo -e "  ${YELLOW}Manajemen Limit Koneksi User:${NC}"
    echo ""

    # Tampilkan akun dengan limit
    shopt -s nullglob
    local files=("$AKUN_DIR"/*.txt)
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${RED}Tidak ada akun!${NC}"
    else
        echo -e "${CYAN}  ┌────────────────────────────────────────────┐${NC}"
        printf "  ${CYAN}│${NC} ${WHITE}%-20s %-10s %-12s${NC} ${CYAN}│${NC}\n" "AKUN" "PROTOKOL" "IP LIMIT"
        echo -e "${CYAN}  ├────────────────────────────────────────────┤${NC}"
        for f in "${files[@]}"; do
            local fname proto uname limit
            fname=$(basename "$f" .txt)
            proto=${fname%%-*}
            uname=${fname#*-}
            limit=$(grep "IPLIMIT" "$f" 2>/dev/null | cut -d= -f2)
            printf "  ${CYAN}│${NC} ${GREEN}%-20s${NC} %-10s ${YELLOW}%-12s${NC} ${CYAN}│${NC}\n" \
                "$uname" "$proto" "${limit:-N/A} IP"
        done
        echo -e "${CYAN}  └────────────────────────────────────────────┘${NC}"
    fi

    echo ""
    echo -e "  ${WHITE}[1]${NC} Update limit akun tertentu"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            read -p "  Nama akun (contoh: vmess-user1): " akun
            read -p "  IP Limit baru: " newlimit
            if [[ -f "$AKUN_DIR/${akun}.txt" ]] && [[ "$newlimit" =~ ^[0-9]+$ ]]; then
                sed -i "s/IPLIMIT=.*/IPLIMIT=${newlimit}/" "$AKUN_DIR/${akun}.txt"
                echo -e "  ${GREEN}✔ IP Limit diupdate: ${newlimit} IP${NC}"
            else
                echo -e "  ${RED}✘ Akun tidak ditemukan!${NC}"
            fi
            sleep 2
            ;;
    esac
}

_adv_custom_payload() {
    clear
    print_menu_header "CUSTOM PAYLOAD GENERATOR"
    echo ""
    echo -e "  ${YELLOW}Generate Payload untuk SSH WebSocket:${NC}"
    echo ""

    [[ -f "$DOMAIN_FILE" ]] && \
        DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)
    local ip_vps
    ip_vps=$(get_ip)

    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}1. Payload HTTP Upgrade (Standard):${NC}"
    printf "  ${GREEN}GET / HTTP/1.1[crlf]Host: %s[crlf]Upgrade: websocket[crlf][crlf]\n${NC}" "$DOMAIN"
    echo ""
    echo -e "  ${WHITE}2. Payload HTTP CONNECT:${NC}"
    printf "  ${GREEN}CONNECT %s:443 HTTP/1.1[crlf]Host: %s[crlf][crlf]\n${NC}" "$DOMAIN" "$DOMAIN"
    echo ""
    echo -e "  ${WHITE}3. Payload GET Simple:${NC}"
    printf "  ${GREEN}GET http://%s/ HTTP/1.1[crlf][crlf]\n${NC}" "$DOMAIN"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${WHITE}Format Hc:${NC} ${GREEN}${DOMAIN}:80@[username]:[password]${NC}"
    echo ""
    read -p "  Press any key to back..."
}

_adv_cron_jobs() {
    clear
    print_menu_header "CRON JOBS"
    echo ""
    echo -e "  ${CYAN}Cron Jobs yang aktif:${NC}"
    echo ""
    crontab -l 2>/dev/null || echo -e "  ${YELLOW}No cron jobs${NC}"
    echo ""
    echo -e "  ${WHITE}[1]${NC} Tambah cron job hapus expired harian"
    echo -e "  ${WHITE}[2]${NC} Tambah cron job restart xray harian"
    echo -e "  ${WHITE}[3]${NC} Hapus semua cron job VPN"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    read -p "  Select: " c
    case $c in
        1)
            (crontab -l 2>/dev/null | grep -v "delete_expired"; \
             echo "0 0 * * * bash /root/tunnel.sh delete_expired_cron 2>/dev/null") | crontab -
            echo -e "  ${GREEN}✔ Auto delete expired: setiap hari jam 00:00${NC}"
            sleep 2
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "restart xray"; \
             echo "0 4 * * * systemctl restart xray >/dev/null 2>&1") | crontab -
            echo -e "  ${GREEN}✔ Auto restart Xray: setiap hari jam 04:00${NC}"
            sleep 2
            ;;
        3)
            crontab -r 2>/dev/null
            echo -e "  ${YELLOW}Semua cron job dihapus!${NC}"
            sleep 2
            ;;
    esac
}

_adv_system_logs() {
    clear
    print_menu_header "SYSTEM LOGS"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Xray Access Logs"
    echo -e "  ${CYAN}[2]${NC} Xray Error Logs"
    echo -e "  ${CYAN}[3]${NC} Nginx Error Logs"
    echo -e "  ${CYAN}[4]${NC} SSH Auth Logs"
    echo -e "  ${CYAN}[5]${NC} System Journal Logs"
    echo -e "  ${CYAN}[6]${NC} HAProxy Logs"
    echo -e "  ${CYAN}[0]${NC} Back"
    echo ""
    read -p "  Select: " log_choice

    case $log_choice in
        1)
            clear
            print_menu_header "XRAY ACCESS LOGS"
            tail -50 /var/log/xray/access.log 2>/dev/null || echo "  No logs"
            ;;
        2)
            clear
            print_menu_header "XRAY ERROR LOGS"
            tail -50 /var/log/xray/error.log 2>/dev/null || echo "  No logs"
            ;;
        3)
            clear
            print_menu_header "NGINX ERROR LOGS"
            tail -50 /var/log/nginx/error.log 2>/dev/null || echo "  No logs"
            ;;
        4)
            clear
            print_menu_header "SSH AUTH LOGS"
            tail -50 /var/log/auth.log 2>/dev/null || echo "  No logs"
            ;;
        5)
            clear
            print_menu_header "SYSTEM LOGS"
            journalctl -n 50 --no-pager
            ;;
        6)
            clear
            print_menu_header "HAPROXY LOGS"
            journalctl -u haproxy -n 50 --no-pager 2>/dev/null || echo "  No logs"
            ;;
    esac
    echo ""
    read -p "  Press any key to back..."
}

#================================================
# UNINSTALL MENU
#================================================

menu_uninstall() {
    while true; do
        clear
        print_menu_header "UNINSTALL MENU"
        echo -e "  ${WHITE}[1]${NC} Uninstall Xray"
        echo -e "  ${WHITE}[2]${NC} Uninstall Nginx"
        echo -e "  ${WHITE}[3]${NC} Uninstall HAProxy"
        echo -e "  ${WHITE}[4]${NC} Uninstall Dropbear"
        echo -e "  ${WHITE}[5]${NC} Uninstall UDP Custom"
        echo -e "  ${WHITE}[6]${NC} Uninstall Bot Telegram"
        echo -e "  ${WHITE}[7]${NC} Uninstall Keepalive"
        echo -e "  ${RED}[8]${NC} ${RED}HAPUS SEMUA SCRIPT${NC}"
        echo -e "  ${WHITE}[0]${NC} Back To Menu"
        echo ""
        read -p "  Select: " choice
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
    clear; print_menu_header "UNINSTALL XRAY"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop xray 2>/dev/null
    systemctl disable xray 2>/dev/null
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray
    rm -f "$AKUN_DIR"/vmess-*.txt "$AKUN_DIR"/vless-*.txt "$AKUN_DIR"/trojan-*.txt
    echo -e "  ${GREEN}✔ Xray uninstalled!${NC}"; sleep 2
}

_uninstall_nginx() {
    clear; print_menu_header "UNINSTALL NGINX"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop nginx 2>/dev/null
    systemctl disable nginx 2>/dev/null
    apt-get purge -y nginx nginx-common >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "  ${GREEN}✔ Nginx uninstalled!${NC}"; sleep 2
}

_uninstall_haproxy() {
    clear; print_menu_header "UNINSTALL HAPROXY"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop haproxy 2>/dev/null
    systemctl disable haproxy 2>/dev/null
    apt-get purge -y haproxy >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "  ${GREEN}✔ HAProxy uninstalled!${NC}"; sleep 2
}

_uninstall_dropbear() {
    clear; print_menu_header "UNINSTALL DROPBEAR"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop dropbear 2>/dev/null
    systemctl disable dropbear 2>/dev/null
    apt-get purge -y dropbear >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "  ${GREEN}✔ Dropbear uninstalled!${NC}"; sleep 2
}

_uninstall_udp() {
    clear; print_menu_header "UNINSTALL UDP"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop udp-custom 2>/dev/null
    systemctl disable udp-custom 2>/dev/null
    rm -f /etc/systemd/system/udp-custom.service
    rm -f /usr/local/bin/udp-custom
    systemctl daemon-reload
    echo -e "  ${GREEN}✔ UDP uninstalled!${NC}"; sleep 2
}

_uninstall_bot() {
    clear; print_menu_header "UNINSTALL BOT"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop vpn-bot 2>/dev/null
    systemctl disable vpn-bot 2>/dev/null
    rm -f /etc/systemd/system/vpn-bot.service
    rm -rf /root/bot
    rm -f "$BOT_TOKEN_FILE" "$CHAT_ID_FILE" "$PAYMENT_FILE"
    systemctl daemon-reload
    echo -e "  ${GREEN}✔ Bot uninstalled!${NC}"; sleep 2
}

_uninstall_keepalive() {
    clear; print_menu_header "UNINSTALL KEEPALIVE"
    read -p "  Yakin? [y/n]: " c
    [[ "$c" != "y" ]] && return
    systemctl stop vpn-keepalive 2>/dev/null
    systemctl disable vpn-keepalive 2>/dev/null
    rm -f /etc/systemd/system/vpn-keepalive.service
    rm -f /usr/local/bin/vpn-keepalive.sh
    systemctl daemon-reload
    echo -e "  ${GREEN}✔ Keepalive uninstalled!${NC}"; sleep 2
}

_uninstall_all() {
    clear
    echo -e "${RED}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}  ║         !! HAPUS SEMUA SCRIPT !!                 ║${NC}"
    echo -e "${RED}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}Akan menghapus SEMUA komponen VPN!${NC}"
    echo ""
    read -p "  Ketik 'HAPUS' untuk konfirmasi: " confirm
    [[ "$confirm" != "HAPUS" ]] && {
        echo -e "  ${YELLOW}Dibatalkan.${NC}"
        sleep 2; return
    }
    echo ""
    for svc in xray nginx haproxy dropbear \
               udp-custom vpn-keepalive vpn-bot; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        printf "  ${RED}✘${NC} Stopped: %s\n" "$svc"
    done
    bash <(curl -Ls \
        https://github.com/XTLS/Xray-install/raw/main/install-release.sh) \
        --remove >/dev/null 2>&1
    apt-get purge -y nginx haproxy dropbear >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    rm -rf /usr/local/etc/xray /var/log/xray /etc/xray \
           /root/akun /root/bot /root/orders /root/domain \
           /root/.domain_type /root/.bot_token \
           /root/.chat_id /root/.payment_info \
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
    echo -e "  ${GREEN}✔ Semua script dihapus!${NC}"
    sleep 3; exit 0
}

#================================================
# HELPER FUNCTIONS
#================================================

_menu_list_all() {
    clear
    print_menu_header "ALL ACCOUNTS"
    local total=0

    shopt -s nullglob
    local ssh_files=("$AKUN_DIR"/ssh-*.txt)
    if [[ ${#ssh_files[@]} -gt 0 ]] && [[ -f "${ssh_files[0]}" ]]; then
        echo -e "  ${GREEN}── SSH ACCOUNTS ─────────────────────────────────${NC}"
        for f in "${ssh_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/ssh-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            printf "  ${CYAN}▸${NC} ${GREEN}%-20s${NC} ${YELLOW}%s${NC}\n" "$uname" "$exp"
            ((total++))
        done
        echo ""
    fi

    local vmess_files=("$AKUN_DIR"/vmess-*.txt)
    if [[ ${#vmess_files[@]} -gt 0 ]] && [[ -f "${vmess_files[0]}" ]]; then
        echo -e "  ${GREEN}── VMESS ACCOUNTS ───────────────────────────────${NC}"
        for f in "${vmess_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vmess-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            printf "  ${CYAN}▸${NC} ${GREEN}%-20s${NC} ${YELLOW}%s${NC}\n" "$uname" "$exp"
            ((total++))
        done
        echo ""
    fi

    local vless_files=("$AKUN_DIR"/vless-*.txt)
    if [[ ${#vless_files[@]} -gt 0 ]] && [[ -f "${vless_files[0]}" ]]; then
        echo -e "  ${GREEN}── VLESS ACCOUNTS ───────────────────────────────${NC}"
        for f in "${vless_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/vless-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            printf "  ${CYAN}▸${NC} ${GREEN}%-20s${NC} ${YELLOW}%s${NC}\n" "$uname" "$exp"
            ((total++))
        done
        echo ""
    fi

    local trojan_files=("$AKUN_DIR"/trojan-*.txt)
    if [[ ${#trojan_files[@]} -gt 0 ]] && [[ -f "${trojan_files[0]}" ]]; then
        echo -e "  ${GREEN}── TROJAN ACCOUNTS ──────────────────────────────${NC}"
        for f in "${trojan_files[@]}"; do
            local uname exp
            uname=$(basename "$f" .txt | sed 's/trojan-//')
            exp=$(grep "EXPIRED" "$f" 2>/dev/null | cut -d= -f2-)
            printf "  ${CYAN}▸${NC} ${GREEN}%-20s${NC} ${YELLOW}%s${NC}\n" "$uname" "$exp"
            ((total++))
        done
        echo ""
    fi
    shopt -u nullglob

    echo -e "  ${WHITE}Total: ${GREEN}${total}${NC} accounts"
    echo ""
    read -p "  Press any key to back..."
}

_menu_backup() {
    clear
    print_menu_header "BACKUP SYSTEM"
    echo -e "  ${YELLOW}Creating backup...${NC}"
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
        /etc/xray/xray.crt \
        /etc/xray/xray.key \
        /usr/local/etc/xray/config.json \
        2>/dev/null

    if [[ -f "$backup_dir/$backup_file" ]]; then
        echo -e "  ${GREEN}✔ Backup created!${NC}"
        echo ""
        echo -e "  File : ${WHITE}$backup_file${NC}"
        echo -e "  Size : ${CYAN}$(du -h "$backup_dir/$backup_file" | awk '{print $1}')${NC}"
        echo -e "  Path : ${YELLOW}$backup_dir/$backup_file${NC}"
    else
        echo -e "  ${RED}✘ Backup failed!${NC}"
    fi

    echo ""
    read -p "  Press any key to back..."
}

_menu_restore() {
    clear
    print_menu_header "RESTORE SYSTEM"

    local backup_dir="/root/backups"

    if [[ ! -d "$backup_dir" ]]; then
        echo -e "  ${RED}No backup directory!${NC}"
        sleep 2; return
    fi

    echo -e "  ${WHITE}Available backups:${NC}"
    echo ""

    shopt -s nullglob
    local backups=($(ls -t "$backup_dir"/*.tar.gz 2>/dev/null))
    shopt -u nullglob

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo -e "  ${RED}No backups found!${NC}"
        sleep 2; return
    fi

    local i=1
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local size=$(du -h "$backup" | awk '{print $1}')
        printf "  ${CYAN}[%d]${NC} %-40s ${YELLOW}%s${NC}\n" "$i" "$filename" "$size"
        ((i++))
    done

    echo ""
    read -p "  Select [1-${#backups[@]}] or 0 to cancel: " choice

    if [[ "$choice" == "0" ]] || [[ ! "$choice" =~ ^[0-9]+$ ]] || \
       [[ "$choice" -lt 1 ]] || [[ "$choice" -gt "${#backups[@]}" ]]; then
        echo -e "  ${YELLOW}Cancelled${NC}"
        sleep 1; return
    fi

    local selected_backup="${backups[$((choice-1))]}"

    echo ""
    echo -e "  ${YELLOW}⚠ This will overwrite current config!${NC}"
    read -p "  Continue? [y/N]: " confirm

    [[ "$confirm" != "y" ]] && { echo -e "  ${YELLOW}Cancelled${NC}"; sleep 1; return; }

    echo ""
    echo -e "  ${CYAN}Restoring...${NC}"
    tar -xzf "$selected_backup" -C / 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo -e "  ${GREEN}✔ Restore successful!${NC}"
        systemctl restart xray nginx haproxy 2>/dev/null
        echo -e "  ${GREEN}✔ Services restarted!${NC}"
    else
        echo -e "  ${RED}✘ Restore failed!${NC}"
    fi

    echo ""
    read -p "  Press any key to back..."
}

_show_help() {
    clear
    print_menu_header "COMMAND GUIDE"
    echo -e "  ${WHITE}Account Management:${NC}"
    echo -e "  ${CYAN}[1-4]${NC}   → Kelola akun SSH/VMess/VLess/Trojan"
    echo -e "  ${CYAN}[5]${NC}     → Generate trial Xray (1 jam)"
    echo -e "  ${CYAN}[6]${NC}     → List semua akun"
    echo -e "  ${CYAN}[7-8]${NC}   → Cek / hapus akun expired"
    echo ""
    echo -e "  ${WHITE}System Tools:${NC}"
    echo -e "  ${CYAN}[9]${NC}     → Telegram bot management"
    echo -e "  ${CYAN}[10]${NC}    → Ganti domain"
    echo -e "  ${CYAN}[11]${NC}    → Fix/renew SSL certificate"
    echo -e "  ${CYAN}[12]${NC}    → Optimize VPS settings"
    echo -e "  ${CYAN}[13]${NC}    → Restart semua service"
    echo -e "  ${CYAN}[14]${NC}    → Lihat info port"
    echo -e "  ${CYAN}[15]${NC}    → Speedtest Ookla"
    echo -e "  ${CYAN}[16]${NC}    → Update script dari GitHub"
    echo -e "  ${CYAN}[17-18]${NC} → Backup & restore"
    echo -e "  ${CYAN}[19]${NC}    → Menu uninstall"
    echo ""
    echo -e "  ${WHITE}Special:${NC}"
    echo -e "  ${CYAN}[20]${NC}    → Advanced settings"
    echo -e "  ${CYAN}[0]${NC}     → Exit"
    echo -e "  ${CYAN}[help]${NC}  → Tampilkan panduan ini"
    echo ""
    read -p "  Press any key to back..."
}

#================================================
# AUTO INSTALL - ANIMASI CINEMATIC
#================================================

auto_install() {
    show_install_banner

    setup_domain
    [[ -z "$DOMAIN" ]] && {
        echo -e "  ${RED}✘ Domain kosong!${NC}"
        exit 1
    }

    local domain_type="custom"
    [[ -f "$DOMAIN_TYPE_FILE" ]] && \
        domain_type=$(cat "$DOMAIN_TYPE_FILE")

    clear
    show_install_banner
    echo -e "  ${WHITE}Domain   :${NC} ${GREEN}${DOMAIN}${NC}"
    echo -e "  ${WHITE}SSL Type :${NC} ${GREEN}$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")${NC}"
    echo ""

    # Loading animasi awal
    animated_loading "Mempersiapkan instalasi" 2
    echo ""

    local total=10
    local step=0
    local LOG="/tmp/install.log"
    > "$LOG"

    _ok() { printf "  ${GREEN}✔${NC} ${WHITE}%-45s${NC}\n" "$1"; }
    _fail() { printf "  ${RED}✘${NC} ${WHITE}%-45s${NC}\n" "$1"; }

    _head() {
        local txt="$1" n="$2" tot="$3"
        echo ""
        echo -e "  ${CYAN}╔══════════════════════════════════════════════════╗${NC}"
        printf  "  ${CYAN}║${NC}  ${YELLOW}STEP %d/%d${NC} — ${WHITE}%-38s${NC}${CYAN}║${NC}\n" "$n" "$tot" "$txt"
        echo -e "  ${CYAN}╚══════════════════════════════════════════════════╝${NC}"
        echo ""
    }

    _pkg() {
        local pkg="$1"
        local sp=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local i=0
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" >> "$LOG" 2>&1 &
        local pid=$!
        while kill -0 $pid 2>/dev/null; do
            printf "\r  ${CYAN}${sp[$((i % 10))]}${NC}  Installing %-30s" "${pkg}..."
            sleep 0.08; ((i++))
        done
        wait $pid
        if [[ $? -eq 0 ]]; then
            printf "\r  ${GREEN}✔${NC}  %-40s\n" "$pkg"
        else
            printf "\r  ${RED}✘${NC}  %-40s\n" "$pkg (gagal)"
        fi
    }

    _run() {
        local label="$1" cmd="$2"
        local sp=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local i=0
        eval "$cmd" >> "$LOG" 2>&1 &
        local pid=$!
        while kill -0 $pid 2>/dev/null; do
            printf "\r  ${CYAN}${sp[$((i % 10))]}${NC}  %-45s" "${label}..."
            sleep 0.08; ((i++))
        done
        wait $pid
        local ret=$?
        if [[ $ret -eq 0 ]]; then
            printf "\r  ${GREEN}✔${NC}  %-45s\n" "$label"
        else
            printf "\r  ${RED}✘${NC}  %-45s\n" "$label (gagal)"
        fi
        return $ret
    }

    # Step 1
    ((step++))
    show_progress $step $total "System Update"
    _head "System Update" $step $total
    _run "apt-get update" "apt-get update -y"
    _run "apt-get upgrade" "DEBIAN_FRONTEND=noninteractive apt-get upgrade -y"

    # Step 2
    ((step++))
    show_progress $step $total "Installing Base Packages"
    _head "Base Packages" $step $total
    local base_pkgs=(curl wget unzip uuid-runtime net-tools openssl jq qrencode iptables-persistent python3 python3-pip)
    for pkg in "${base_pkgs[@]}"; do _pkg "$pkg"; done

    # Step 3
    ((step++))
    show_progress $step $total "Installing VPN Services"
    _head "VPN Services" $step $total
    local svc_pkgs=(nginx openssh-server dropbear haproxy certbot netcat-openbsd)
    for pkg in "${svc_pkgs[@]}"; do _pkg "$pkg"; done

    # Step 4
    ((step++))
    show_progress $step $total "Installing Xray-Core"
    _head "Xray Core" $step $total
    _run "Downloading & Installing Xray" \
        "bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
    mkdir -p "$AKUN_DIR" /var/log/xray /usr/local/etc/xray "$PUBLIC_HTML" "$ORDER_DIR" /root/bot
    if command -v xray >/dev/null 2>&1; then
        local xver
        xver=$(xray version 2>/dev/null | head -1 | awk '{print $2}')
        _ok "Xray ${xver} installed"
    else
        _fail "Xray install failed"
    fi

    # Step 5
    ((step++))
    show_progress $step $total "Setting up Swap Memory"
    _head "Swap Memory 1GB" $step $total
    local cur_swap
    cur_swap=$(free -m | awk 'NR==3{print $2}')
    if [[ "$cur_swap" -lt 512 ]]; then
        _run "Creating swapfile 1GB" "fallocate -l 1G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=1024"
        chmod 600 /swapfile
        _run "Formatting swap" "mkswap /swapfile"
        _run "Enabling swap" "swapon /swapfile"
        grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
        _ok "Swap 1GB active"
    else
        _ok "Swap exists (${cur_swap}MB), skip"
    fi

    # Step 6
    ((step++))
    show_progress $step $total "Getting SSL Certificate"
    _head "SSL Certificate" $step $total
    mkdir -p /etc/xray
    if [[ "$domain_type" == "custom" ]]; then
        _run "Certbot Let's Encrypt for $DOMAIN" \
            "certbot certonly --standalone -d '$DOMAIN' --non-interactive --agree-tos --register-unsafely-without-email"
        if [[ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" /etc/xray/xray.crt
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" /etc/xray/xray.key
            chmod 644 /etc/xray/xray.*
            _ok "Let's Encrypt cert installed"
        else
            _fail "Certbot gagal, pakai self-signed"
            _run "Generating self-signed cert" \
                "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"
            _ok "Self-signed cert generated"
        fi
    else
        _run "Generating self-signed cert" \
            "openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=ID/ST=Jakarta/L=Jakarta/O=VPN/CN=${DOMAIN}' -keyout /etc/xray/xray.key -out /etc/xray/xray.crt"
        _ok "Self-signed cert for $DOMAIN"
    fi
    chmod 644 /etc/xray/xray.* 2>/dev/null

    # Step 7
    ((step++))
    show_progress $step $total "Creating Configs"
    _head "Xray & Nginx Config" $step $total
    _run "Creating Xray config" "create_xray_config"
    _ok "8 inbounds: VMess/VLess/Trojan (WS+gRPC)"
    _ok "TLS:443 | NonTLS:80 | gRPC:8444"

    cat > /etc/nginx/sites-available/default << 'NGXEOF'
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
    keepalive_timeout 300;
    location / {
        try_files $uri $uri/ =404;
        add_header Content-Type text/plain;
    }
}
NGXEOF

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    nginx -t >> "$LOG" 2>&1 && _ok "Nginx config valid" || _fail "Nginx config error"

    # Step 8
    ((step++))
    show_progress $step $total "Configuring Dropbear & HAProxy"
    _head "Dropbear & HAProxy" $step $total

    cat > /etc/default/dropbear << 'DBEOF'
NO_START=0
DROPBEAR_PORT=222
DROPBEAR_EXTRA_ARGS="-K 60 -I 180"
DROPBEAR_BANNER="/etc/issue.net"
DROPBEAR_RECEIVE_WINDOW=65536
DBEOF
    _ok "Dropbear port 222"

    configure_haproxy
    haproxy -c -f /etc/haproxy/haproxy.cfg >> "$LOG" 2>&1 && \
        _ok "HAProxy port 443 → Xray 8443" || \
        _fail "HAProxy config error"

    # Step 9
    ((step++))
    show_progress $step $total "UDP, Keepalive & Optimize"
    _head "System Optimize" $step $total

    _run "Installing UDP Custom (7100-7300)" "install_udp_custom"
    _ok "BadVPN UDP 7100-7300 ready"

    _run "Configuring SSH keepalive" "setup_keepalive"
    _ok "SSH keepalive interval 30s"

    _run "Enabling BBR & TCP optimize" "optimize_vpn"
    _ok "BBR + TCP buffer optimized"

    sed -i 's/^#\?Port.*/Port 22/' /etc/ssh/sshd_config 2>/dev/null
    _ok "SSH port locked to 22"

    _run "Installing Python requests" "pip3 install requests --break-system-packages"
    _ok "Python deps ready"

    # Step 10
    ((step++))
    show_progress $step $total "Starting Services"
    _head "Start All Services" $step $total

    systemctl daemon-reload >> "$LOG" 2>&1

    local svcs=(xray nginx sshd dropbear haproxy udp-custom vpn-keepalive)
    for svc in "${svcs[@]}"; do
        systemctl enable "$svc" >> "$LOG" 2>&1
        systemctl restart "$svc" >> "$LOG" 2>&1
        if systemctl is-active --quiet "$svc"; then
            printf "  ${GREEN}✔${NC} %-20s ${GREEN}RUNNING${NC}\n" "$svc"
        else
            printf "  ${RED}✘${NC} %-20s ${RED}FAILED${NC}\n" "$svc"
        fi
    done

    setup_menu_command
    _ok "Menu command: ketik 'menu'"

    local ip_vps
    ip_vps=$(get_ip)

    cat > "$PUBLIC_HTML/index.html" << IDXEOF
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Youzin Crabz Tunel</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:'Courier New',monospace;background:#0a0a1a;color:#eee;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center}
.box{padding:40px;background:#0d1117;border:1px solid #00d4ff44;border-radius:12px;max-width:500px}
h1{color:#00d4ff;margin-bottom:5px;font-size:1.8em;letter-spacing:2px}
.sub{color:#7ee8fa;font-size:0.9em;margin-bottom:15px}
p{color:#666;margin:4px 0;font-size:0.85em}
.badge{display:inline-block;background:#00d4ff22;color:#00d4ff;padding:4px 16px;border-radius:20px;margin-top:15px;font-size:12px;letter-spacing:1px;border:1px solid #00d4ff33}
.ip{color:#7ee8fa;font-size:1.1em;margin:8px 0}
</style>
</head>
<body>
<div class="box">
<h1>⚡ YOUZIN CRABZ</h1>
<div class="sub">T U N E L</div>
<p class="ip">${DOMAIN}</p>
<p>${ip_vps}</p>
<div class="badge">The Professor</div>
</div>
</body>
</html>
IDXEOF
    _ok "Web index created"

    # Summary
    echo ""
    echo -e "${GREEN}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}  ║      ✔  INSTALASI SELESAI!                       ║${NC}"
    echo -e "${GREEN}  ║      Youzin Crabz Tunel - The Professor          ║${NC}"
    echo -e "${GREEN}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "Domain"      "$DOMAIN"
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "IP VPS"       "$ip_vps"
    printf "  ${WHITE}%-22s${NC}: ${GREEN}%s${NC}\n" "SSL" "$([[ "$domain_type" == "custom" ]] && echo "Let's Encrypt" || echo "Self-Signed")"
    echo ""
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "SSH"          "22"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Dropbear"     "222"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray TLS"     "443 (HAProxy→8443)"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray NonTLS"  "80 (Nginx→8080)"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Xray gRPC"    "8444"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "BadVPN UDP"   "7100-7300"
    printf "  ${WHITE}%-22s${NC}: ${CYAN}%s${NC}\n" "Download"     "http://${ip_vps}:81/"
    echo ""
    printf "  ${YELLOW}%-22s${NC}: ${YELLOW}%s${NC}\n" "Log Install"   "$LOG"
    echo ""
    echo -e "  ${YELLOW}💡 Ketik 'menu' untuk membuka menu!${NC}"
    echo ""
    echo -e "  ${YELLOW}Reboot dalam 5 detik...${NC}"
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
        read -p "  Enter choice [0-20]: " choice

        case $choice in
            1|01) menu_ssh ;;
            2|02) menu_vmess ;;
            3|03) menu_vless ;;
            4|04) menu_trojan ;;
            5|05)
                clear
                print_menu_header "TRIAL XRAY GENERATOR"
                echo -e "  ${CYAN}[1]${NC} VMess Trial"
                echo -e "  ${CYAN}[2]${NC} VLess Trial"
                echo -e "  ${CYAN}[3]${NC} Trojan Trial"
                echo -e "  ${CYAN}[0]${NC} Back"
                echo ""
                read -p "  Select: " trial_choice
                case $trial_choice in
                    1) create_trial_xray "vmess" ;;
                    2) create_trial_xray "vless" ;;
                    3) create_trial_xray "trojan" ;;
                esac
                ;;
            6|06) _menu_list_all ;;
            7|07) cek_expired ;;
            8|08) delete_expired ;;
            9|09) menu_telegram_bot ;;
            10) change_domain ;;
            11) fix_certificate ;;
            12)
                clear
                optimize_vpn
                echo -e "  ${GREEN}✔ Optimization done!${NC}"
                sleep 2
                ;;
            13)
                clear
                print_menu_header "RESTART ALL SERVICES"
                echo ""
                for svc in xray nginx sshd dropbear haproxy udp-custom vpn-keepalive vpn-bot; do
                    if systemctl restart "$svc" 2>/dev/null; then
                        printf "  ${GREEN}✔${NC} %-20s ${GREEN}Restarted${NC}\n" "$svc"
                    else
                        printf "  ${RED}✘${NC} %-20s ${RED}Failed${NC}\n" "$svc"
                    fi
                done
                echo ""
                sleep 2
                ;;
            14) show_info_port ;;
            15) run_speedtest ;;
            16) update_menu ;;
            17) _menu_backup ;;
            18) _menu_restore ;;
            19) menu_uninstall ;;
            20|99) menu_advanced ;;
            0|00)
                clear
                echo -e "  ${CYAN}Goodbye! — Youzin Crabz Tunel${NC}"
                exit 0
                ;;
            help|HELP) _show_help ;;
            *) ;;
        esac
    done
}

#================================================
# ENTRY POINT
#================================================

# Harus root
[[ $EUID -ne 0 ]] && {
    echo -e "${RED}Run as root!${NC}"
    echo "  sudo bash $0"
    exit 1
}

# Load domain
[[ -f "$DOMAIN_FILE" ]] && \
    DOMAIN=$(tr -d '\n\r' < "$DOMAIN_FILE" | xargs)

# First time install
if [[ ! -f "$DOMAIN_FILE" ]]; then
    auto_install
fi

# Setup menu command
setup_menu_command

# Run main menu
main_menu
