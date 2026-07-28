<div align="center">

# 🛡️ YouzinCrabz Tunnel — VPN Panel v3.12

### Multi-Protocol VPN Management System with Web Panel & Multi-VPS Support

**SSH · VMess · VLess · Trojan · UDP Custom · ZIVPN** — dalam satu script auto-install.

[![Version](https://img.shields.io/badge/version-3.12.0-blue.svg?style=for-the-badge)](#)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange.svg?style=for-the-badge&logo=ubuntu&logoColor=white)](#)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg?style=for-the-badge)](LICENSE)
[![Xray](https://img.shields.io/badge/Xray-1.8.23-black.svg?style=for-the-badge&logo=xray&logoColor=white)](#)

</div>

---

## 📋 Daftar Isi

- [ Tentang Project](#tentang-project)
- [ Fitur Utama](#fitur-utama)
- [ Protokol yang Didukung](#protokol-yang-didukung)
- [ Persyaratan Sistem](#persyaratan-sistem)
- [ Instalasi](#instalasi)
- [ Menu Lengkap](#menu-lengkap)
- [ OrderVPN Web Panel](#ordervpn-web-panel)
- [ Bot Telegram](#bot-telegram)
- [ Multi-VPS Management](#multi-vps-management)
- [ Keamanan](#keamanan)
- [ Struktur Project](#struktur-project)
- [ License](#license)
- [ Kontak](#kontak)

---

<a id="tentang-project"></a>

## 🎯 Tentang Project

**YouzinCrabz Tunnel** adalah script auto-install VPN panel all-in-one untuk VPS Ubuntu. Dibuat oleh **The Professor** dengan fokus pada kemudahan, kecepatan, dan tampilan yang rapi (mobile-friendly).

Script ini menggabungkan **3 komponen utama** dalam satu kesatuan:

| Komponen | Fungsi |
|----------|--------|
| **vpn.sh** | Script utama — CLI menu interaktif dengan 24+ menu |
| **OrderVPN Web Panel** | Web panel PHP untuk jualan VPN online (auto-order, topup, trial) |
| **Multi-VPS Bridge** | Sistem untuk menghubungkan banyak VPS ke panel utama |

> ⚠️ **Script ini bersifat proprietary.** Lihat file [LICENSE](LICENSE) untuk detail ketentuan penggunaan.

---

<a id="fitur-utama"></a>

## ✨ Fitur Utama

### 🔥 Core VPN Engine
- ✅ **Auto-install** semua service VPN dalam 1 perintah
- ✅ **Multi-protokol**: SSH, OpenVPN, VMess, VLess, Trojan (WS + gRPC)
- ✅ **UDP Custom** & **ZIVPN UDP** untuk game tunneling
- ✅ **Xray v1.8.23** dengan 6 inbound (WS + gRPC untuk setiap protokol)
- ✅ **Auto SSL** — Let's Encrypt (domain custom) atau Self-signed (auto-generate)
- ✅ **SSL Auto-Renew** — cron job tanggal 1 & 15 setiap bulan
- ✅ **Cert & Key verification** — mencegah mismatch SSL

### 🖥️ Sistem & Optimasi
- ✅ **BBR Congestion Control** — auto-enable untuk kecepatan maksimal
- ✅ **Sysctl tuning** — TCP keepalive, fastopen, MTU probing, buffer besar
- ✅ **Auto Swap** — 1GB/2GB swap otomatis untuk VPS low-RAM
- ✅ **VPN Keepalive** — systemd service ping otomatis
- ✅ **Fail2ban** — proteksi brute-force SSH
- ✅ **UFW Firewall** — auto-konfigurasi port
- ✅ **Optimize VPS** — file descriptor limits, journald tuning

### 🛡️ Keamanan
- ✅ **DDoS Protection** — rate limiting & IP ban rules
- ✅ **Traffic Monitor** — pantau bandwidth real-time
- ✅ **Health Check** — cek status semua service sekaligus
- ✅ **CSRF Protection** — token CSRF di semua form web
- ✅ **Rate Limiting** — batasi login attempt (anti brute-force)
- ✅ **OTP Email Verification** — verifikasi user via email saat register
- ✅ **Password Hashing** — bcrypt via PHP `password_hash()`

### 🌐 Web Panel (OrderVPN)
- ✅ **Landing page** modern dengan animasi
- ✅ **User registration** dengan OTP email
- ✅ **Dashboard** — kelola akun VPN, lihat config link
- ✅ **Topup saldo** — QRIS + manual transfer
- ✅ **Promo codes** — sistem diskon
- ✅ **Trial gratis** — 1 jam untuk semua protokol
- ✅ **Admin panel** — kelola server, user, topup, settings
- ✅ **Multi-server** — pilih server saat order
- ✅ **Notifikasi Telegram** ke admin saat order/topup baru

---

<a id="protokol-yang-didukung"></a>

## 🔌 Protokol yang Didukung

| Protokol | Transport | Port | Keterangan |
|----------|-----------|------|------------|
| **SSH / OpenVPN** | TCP | 22 / 222 (Dropbear) | Classic tunneling, stabil |
| **VMess** | WebSocket + gRPC | 8080 / 8444 | Protocol Xray, encrypted |
| **VLess** | WebSocket + gRPC | 8081 / 8445 | Lightweight, no encryption overhead |
| **Trojan** | WebSocket + gRPC | 8082 / 8446 | Anti-DPI, tahan blocking |
| **UDP Custom** | UDP | Custom | Game tunneling, support badvpn |
| **ZIVPN UDP** | UDP | Custom | UDP custom alternatif |

> Setiap protokol mendukung **WS (non-TLS)** dan **gRPC** secara bersamaan. Nginx reverse proxy handle port 443 untuk TLS.

---

<a id="persyaratan-sistem"></a>

## 📦 Persyaratan Sistem

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Ubuntu 20.04 LTS | Ubuntu 22.04 / 24.04 LTS |
| **RAM** | 512 MB | 1 GB+ (auto-swap aktif) |
| **Storage** | 10 GB | 20 GB+ |
| **Access** | Root (sudo) | Root |
| **Network** | Public IPv4 | IPv4 + Domain |
| **Software** | curl, bash | Python 3, jq, nginx (auto-install) |

> ℹ️ Script otomatis mendeteksi versi Ubuntu dan container (OpenVZ/LXC), lalu menyesuaikan instalasi.

---

<a id="instalasi"></a>

## 🚀 Instalasi

### Metode 1: One-Liner (Recommended)

```bash
bash <(curl -sL https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/vpn.sh)
```

### Metode 2: Manual Clone

```bash
git clone https://github.com/putrinuroktavia234-max/Tunnel.git
cd Tunnel
chmod +x vpn.sh
bash vpn.sh
```

### Metode 3: Download Langsung

```bash
wget -O vpn.sh https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/vpn.sh
bash vpn.sh
```

### Alur Instalasi Otomatis

```
┌─────────────────────────────────────────────────────┐
│  1. Deteksi OS & Versi Ubuntu                        │
│  2. Install dependencies (jq, nginx, python3, dll)   │
│  3. Install Xray v1.8.23 + konfigurasi 6 inbound      │
│  4. Setup domain (custom atau auto-generate nip.io)   │
│  5. Generate SSL (Let's Encrypt / Self-signed)        │
│  6. Install SSH/Dropbear + configure fail2ban         │
│  7. Install UDP Custom + ZIVPN UDP                    │
│  8. Optimize sysctl (BBR, TCP tuning)                 │
│  9. Setup VPN Keepalive (systemd service)             │
│  10. Setup cron auto-delete expired accounts          │
│  11. (Opsional) Deploy OrderVPN Web Panel             │
│  12. Auto-start menu saat SSH login                   │
└─────────────────────────────────────────────────────┘
```

> ✅ Setelah instalasi selesai, menu panel **otomatis muncul** setiap kali Anda login SSH sebagai root. Ketik `menu` untuk membuka kembali.

---

<a id="menu-lengkap"></a>

## 📋 Menu Lengkap

Script memiliki **24 menu utama** yang dibagi dalam beberapa kategori:

### 👤 Account Management

| Menu | Fungsi |
|------|--------|
| `1` | **SSH / OpenVPN** — Buat, trial, hapus, renew akun SSH |
| `2` | **VMess Account** — Buat, trial, hapus, renew akun VMess |
| `3` | **VLess Account** — Buat, trial, hapus, renew akun VLess |
| `4` | **Trojan Account** — Buat, trial, hapus, renew akun Trojan |
| `5` | **List All Accounts** — Tampilkan semua akun aktif |
| `6` | **Renew / Extend Akun** — Perpanjang masa aktif akun |
| `7` | **Check Expired** — Cek akun yang sudah expired |
| `8` | **Delete Expired** — Hapus otomatis akun expired |

### ⚙️ System Control

| Menu | Fungsi |
|------|--------|
| `9` | **Telegram Bot** — Setup & kelola bot Telegram (lihat detail di bawah) |
| `10` | **Change Domain** — Ganti domain VPS |
| `11` | **SSL Manager** — Fix/renew certificate SSL |
| `12` | **Optimize VPS** — Tuning sysctl, BBR, file limits |
| `13` | **Restart Service** — Restart Xray, Nginx, SSH, dll |
| `14` | **Speedtest VPS** — Test kecepatan internet VPS |
| `15` | **Backup Config** — Backup semua konfigurasi |
| `16` | **Restore Config** — Restore dari backup |
| `17` | **Uninstall Panel** — Uninstall bersih semua service |
| `18` | **Advanced Mode** — Sub-menu fitur lanjutan |

### 🌐 Extended Features

| Menu | Fungsi |
|------|--------|
| `19` | **Port Info** — Tampilkan semua port yang digunakan |
| `20` | **ZI VPN UDP** — Install/kelola ZIVPN UDP |
| `21` | **OrderVPN Web** — Deploy/kelola web panel |
| `22` | **DDoS Protect** — Aktifkan proteksi DDoS |
| `23` | **Traffic Monitor** — Pantau bandwidth real-time |
| `24` | **Health Check** — Cek kesehatan semua service |

---

<a id="ordervpn-web-panel"></a>

## 🌐 OrderVPN Web Panel

OrderVPN adalah **web panel PHP** untuk menjual akun VPN secara online. Terintegrasi langsung dengan vpn.sh.

### Fitur Web Panel

```
┌──────────────────────────────────────────────────────┐
│  👤 USER SIDE                                        │
│  ├── Register + OTP Email Verification               │
│  ├── Login dengan username/email                     │
│  ├── Dashboard — lihat & kelola akun VPN             │
│  ├── Order akun — pilih server + protokol + durasi   │
│  ├── Trial gratis 1 jam (SSH/VMess/VLess/Trojan)     │
│  ├── Topup saldo (QRIS / manual transfer)            │
│  ├── Promo code — diskon saat checkout               │
│  ├── Upload / hapus avatar                           │
│  ├── Ganti password                                  │
│  └── Hapus akun sendiri                              │
│                                                      │
│  🛡️ ADMIN SIDE                                       │
│  ├── Kelola server (tambah/edit/hapus VPS)           │
│  ├── Approve / reject topup                          │
│  ├── Atur saldo user                                 │
│  ├── Settings: nama app, harga, domain, wildcard     │
│  ├── Settings: SMTP, Telegram notif, QRIS, Tripay    │
│  ├── Lihat semua transaksi                           │
│  └── Monitoring server real-time (heartbeat 5 menit) │
└──────────────────────────────────────────────────────┘
```

### Cara Deploy

1. Pastikan vpn.sh sudah terinstall
2. Buka menu **`21`** → **OrderVPN Web**
3. Ikuti wizard setup:
   - Setup domain web (custom / auto-generate / pakai domain utama)
   - Setup database (auto-create, password random)
   - Setup password admin
4. Akses panel di `https://domain-kamu/ordervpn/`

### Database Schema

Panel menggunakan **MySQL/MariaDB** dengan tabel berikut:

| Tabel | Fungsi |
|-------|--------|
| `users` | Data user (username, email, password, saldo, role) |
| `servers` | Daftar VPS yang terhubung |
| `vpn_accounts` | Akun VPN yang dibuat user |
| `transactions` | Riwayat transaksi (topup, order, refund) |
| `topup_requests` | Request topup saldo |
| `promo_codes` | Kode promo diskon |
| `app_settings` | Konfigurasi aplikasi (key-value) |
| `login_attempts` | Log login untuk rate limiting |
| `wildcard_domains` | Domain wildcard untuk config |

---

<a id="bot-telegram"></a>

## 🤖 Bot Telegram

Script mendukung **bot Telegram** yang dapat Anda konfigurasi sendiri untuk **manajemen VPN via chat**.

### Cara Setup Bot Telegram (Menu 9)

1. Buka menu **`9`** → **Telegram Bot** di panel
2. Pilih **`[1] Setup VPN Bot`**
3. Ikuti petunjuk di layar:

```
Cara mendapatkan Bot Token:
  1. Buka Telegram, cari @BotFather
  2. Ketik /newbot, ikuti instruksi
  3. Copy TOKEN yang diberikan

Cara mendapatkan Chat ID:
  1. Cari @userinfobot di Telegram
  2. Ketik /start, lihat ID kamu
```

4. Masukkan **Bot Token** dan **Admin Chat ID**
5. Script akan **test token** ke API Telegram otomatis
6. Jika valid, bot akan dibuat & dijalankan sebagai **systemd service** (`vpn-bot`)

### Fitur Bot Telegram

| Fitur | Keterangan |
|-------|------------|
| **Create Account** | Buat akun SSH/VMess/VLess/Trojan langsung dari chat |
| **Trial Gratis** | Buat akun trial 1 jam, pilih protokol via inline button |
| **Delete Account** | Hapus akun via chat |
| **Renew Account** | Perpanjang masa aktif akun |
| **Cek Status Server** | Lihat CPU, RAM, uptime, jumlah akun |
| **Order Pending** | Lihat & approve order yang pending |
| **Notifikasi Admin** | Notif otomatis saat order/topup baru masuk |

### Mengelola Bot

Dari menu **`9`**:

| Pilihan | Fungsi |
|---------|--------|
| `[1]` | Setup / re-setup bot |
| `[2]` | Start / Stop / Restart bot service |
| `[3]` | Lihat log bot (journalctl) |
| `[4]` | Lihat order pending |
| `[5]` | Info bot (status, token, chat ID) |

> Bot berjalan sebagai **systemd service** (`vpn-bot.service`), jadi auto-restart jika crash dan survive reboot.

---

<a id="multi-vps-management"></a>

## 🖧 Multi-VPS Management

Script mendukung **multi-VPS** — hubungkan banyak VPS ke panel utama (master).

### Arsitektur

```
┌─────────────────────┐
│   MASTER VPS        │
│  (vpn.sh + Web)     │
│                     │
│  ┌───────────────┐  │
│  │ OrderVPN Web  │  │
│  │   Panel       │  │
│  └───────┬───────┘  │
│          │ SSH      │
│  ┌───────┴───────┐  │
│  │  VPN Manager  │  │
│  │  (PHP class)  │  │
│  └───┬───┬───┬───┘  │
└──────┼───┼───┼──────┘
       │   │   │
   ┌───┴┐ ┌┴──┐ ┌───┐
   │ VPS│ │VPS│ │VPS│  ← Node VPN
   │ #1 │ │#2 │ │#3 │     (join.sh + vpn-api)
   └────┘ └───┘ └───┘
```

### Cara Menambahkan VPS Node

Di VPS node baru, jalankan:

```bash
bash <(curl -sL http://IP-MASTER:8888/ordervpn/join.sh) \
  --master=IP_MASTER \
  --secret=JOIN_SECRET \
  --code=SV01 \
  --name="VPS-Singapore"
```

**join.sh** akan:
1. ✅ Mendaftarkan VPS ke master panel
2. ✅ Generate SSH key & tambah ke `authorized_keys`
3. ✅ Install vpn-api bridge (create/delete/status akun)
4. ✅ Download & jalankan `deploy-node.sh` dari master
5. ✅ Install Xray + 6 inbound (WS + gRPC)
6. ✅ Setup cron heartbeat (setiap 5 menit ke master)
7. ✅ Setup cron cleanup expired accounts

### vpn-api Bridge

`vpn-api` adalah binary bash di setiap VPS node yang menerima perintah dari panel:

```bash
# Buat akun
sudo /usr/local/bin/vpn-api create vmess user123 30 100 2

# Hapus akun
sudo /usr/local/bin/vpn-api delete vmess user123

# Status server
sudo /usr/local/bin/vpn-api status

# Monitor (CPU, RAM, akun count)
sudo /usr/local/bin/vpn-api monitor
```

> Komunikasi master → node via **SSH key-based** (passwordless) atau **sshpass** (password).

---

<a id="keamanan"></a>

## 🔒 Keamanan

### Fitur Keamanan Bawaan

| Fitur | Status |
|-------|--------|
| CSRF Token (web panel) | ✅ Aktif di semua form |
| Rate Limiting Login | ✅ Max 5 attempt / 15 menit |
| OTP Email Verification | ✅ Saat register user baru |
| Password Hashing | ✅ bcrypt (`password_hash`) |
| Fail2ban SSH | ✅ Auto-install |
| UFW Firewall | ✅ Auto-config port |
| DDoS Protection | ✅ Rate limiting rules |
| SSL/TLS | ✅ Let's Encrypt / Self-signed |
| Sudoers Restriction | ✅ www-data hanya bisa panggil vpn-api |

### Best Practice yang Disarankan

```bash
# 1. Ganti port SSH default
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
systemctl restart ssh

# 2. Disable password login (hanya key-based)
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# 3. Update sistem rutin
apt update && apt upgrade -y

# 4. Backup rutin via menu 15
```

> 📋 Lihat [SECURITY.md](SECURITY.md) untuk policy reporting vulnerability.

---

<a id="struktur-project"></a>

## 📁 Struktur Project

```
Tunnel/
├── vpn.sh                          # Script utama (CLI panel, 28K+ baris)
├── login.php                       # Halaman login OrderVPN
├── LICENSE                         # License file
├── README.md                       # File ini
├── SECURITY.md                     # Security policy
├── CONTRIBUTING.md                 # Panduan kontribusi
├── .gitignore                      # Git ignore rules
│
└── ordervpn-src/                   # OrderVPN Web Panel
    ├── index.php                   # Landing page
    ├── dashboard.php               # User dashboard
    ├── login.php                   # Halaman login web
    ├── change_password.php         # Ganti password
    ├── database.sql                # Schema database MySQL
    ├── join.sh                     # Script join VPS ke master
    ├── deploy-node.sh              # Deploy VPN node (dipanggil join.sh)
    ├── vpn-api.sh                  # API bridge untuk VPS node
    │
    ├── includes/
    │   ├── config.php              # Konfigurasi DB, fungsi helper, Telegram notif
    │   ├── vpn_manager.php         # Class VPNManager (create/delete via SSH/local)
    │   └── security.php            # CSRF, rate limiting
    │
    ├── api/                        # API endpoints (AJAX)
    │   ├── create_order.php        # Buat order akun VPN
    │   ├── topup.php               # Request topup saldo
    │   ├── check_promo.php         # Validasi kode promo
    │   ├── get_bridge.php          # Download vpn-api bridge
    │   ├── register_vps.php        # Register/heartbeat VPS node
    │   ├── update_profile.php      # Update profil user
    │   ├── upload_avatar.php       # Upload avatar
    │   ├── delete_avatar.php       # Hapus avatar
    │   ├── delete_account.php      # Hapus akun user
    │   └── logout.php              # Logout
    │
    ├── admin/
    │   └── index.php               # Admin panel (kelola server, user, topup, settings)
    │
    ├── cron/
    │   └── expire_accounts.php     # Cron job: expire akun yang lewat masa aktif
    │
    └── assets/
        └── css/
            └── style.css           # Stylesheet web panel
```

---

<a id="license"></a>

## 📄 License

Project ini menggunakan **Proprietary License** — lihat file [LICENSE](LICENSE) untuk detail lengkap.

### Ringkasan Ketentuan:

| Aksi | Diizinkan? |
|------|------------|
| Penggunaan pribadi | ✅ Ya |
| Modifikasi untuk diri sendiri | ✅ Ya |
| Distribusi ulang source code | ❌ Tidak |
| Jual ulang script ini | ❌ Tidak |
| Komersial tanpa izin | ❌ Tidak |
| Menghapus copyright notice | ❌ Tidak |

> Untuk penggunaan komersial atau lisensi khusus, hubungi author.

---

<a id="kontak"></a>

## 📞 Kontak

| Platform | Link |
|----------|------|
| **Telegram** | [@YouzinCrabz](https://t.me/YouzinCrabz) |
| **GitHub** | [putrinuroktavia234-max/Tunnel](https://github.com/putrinuroktavia234-max/Tunnel) |
| **Author** | The Professor |

---

<div align="center">

**Made with 💜 by The Professor**

**YouzinCrabz Tunnel v3.12.0** — *Freedom to tunnel.*

</div>
