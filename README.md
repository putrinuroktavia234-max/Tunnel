<div align="center">

# 🚀 Youzin Crabz Tunel

**by The Professor**

![Version](https://img.shields.io/badge/Version-3.2.2-brightgreen?style=for-the-badge)
![OS](https://img.shields.io/badge/OS-Ubuntu%2022.04-orange?style=for-the-badge&logo=ubuntu)
![Script](https://img.shields.io/badge/Script-Protected-red?style=for-the-badge&logo=openssh)
![Maintained](https://img.shields.io/badge/Maintained-Yes-blue?style=for-the-badge)
![Telegram](https://img.shields.io/badge/Support-@YouzinCrabz-2CA5E0?style=for-the-badge&logo=telegram)

> Panel VPN all-in-one dengan Telegram Bot terintegrasi untuk jualan akun otomatis

</div>

---

## 📋 Deskripsi

**Youzin Crabz Tunel** adalah script panel VPN lengkap berbasis Bash yang mendukung multi-protokol (VMess, VLess, Trojan, SSH) dengan manajemen otomatis melalui HAProxy, Nginx, dan Xray-core. Dilengkapi **Telegram Bot siap pakai** untuk jualan akun VPN secara otomatis tanpa perlu intervensi manual admin.

---

## ✨ Fitur Lengkap

### 👥 Manajemen Akun

| Fitur | Keterangan |
|---|---|
| SSH / OpenVPN | Buat, hapus, renew akun SSH |
| VMess | Support WS TLS, NonTLS, gRPC |
| VLess | Support WS TLS, NonTLS, gRPC |
| Trojan | Support WS TLS, NonTLS, gRPC |
| Trial Account | Akun otomatis hapus setelah 1 jam |
| List Akun | Lihat semua akun aktif |
| Cek Expired | Notifikasi akun hampir expired |
| Auto Delete | Hapus akun expired otomatis |

### 🤖 Telegram Bot (Siap Jualan)

Bot Telegram sudah **terintegrasi penuh** dan siap digunakan untuk bisnis VPN. Tidak perlu coding tambahan — langsung setup token dan berjalan.

| Fitur Bot | Keterangan |
|---|---|
| 🛒 Order Akun | User order langsung via bot, admin konfirmasi |
| 🆓 Trial Gratis | Trial 1 jam otomatis tanpa campur tangan admin |
| 📋 Cek Akun | User bisa cek status akun sendiri |
| 🔔 Notifikasi Admin | Setiap order & aktivitas masuk ke chat admin |
| ⏰ Notif Expired | Reminder otomatis sebelum akun habis |
| 💳 Multi Paket | Bisa set berbagai paket harga & durasi |

> **Cara Setup Bot:**
> 1. Buka Telegram → cari **@BotFather** → `/newbot`
> 2. Copy **Bot Token**
> 3. Cari **@userinfobot** → `/start` → copy **Chat ID**
> 4. Di panel pilih menu **[9] Telegram Bot → [1] Setup Bot**
> 5. Masukkan token & chat ID → Bot langsung aktif & siap terima order

### ⚙️ System Control

| Fitur | Keterangan |
|---|---|
| Change Domain | Ganti domain tanpa reinstall |
| Fix SSL/Cert | Renew Let's Encrypt / Self-Signed |
| Optimize VPS | BBR, TCP tuning, system optimize |
| Restart Services | Restart semua service sekaligus |
| Port Info | Info semua port yang digunakan |
| Speedtest | Test kecepatan VPS |
| Update Panel | Auto update dari GitHub |
| Backup Config | Backup semua konfigurasi |
| Restore Config | Restore dari backup |

### 🔒 Advanced Mode

| Fitur | Keterangan |
|---|---|
| Port Management | Kelola port, cek konflik |
| Protocol Settings | Edit config Xray langsung |
| Auto Backup | Jadwal backup otomatis |
| SSH Brute Protection | Fail2Ban + iptables |
| DDoS Protection | Rate limiting & SYN flood protection |
| Firewall Rules | UFW management |
| Bandwidth Monitor | Monitor realtime bandwidth |
| User IP Limits | Batas IP per akun |
| Custom Payload | Generator payload HTTP |
| Cron Jobs | Kelola cron otomatis |
| System Logs | Viewer & filter log |

---

## 🌐 Arsitektur Port

```
Internet
    │
    ├── :22    → OpenSSH
    ├── :222   → Dropbear
    ├── :80    → Nginx NonTLS
    │              ├── /vmess  → Xray VMess  :8080
    │              ├── /vless  → Xray VLess  :8081
    │              └── /trojan → Xray Trojan :8082
    ├── :81    → Nginx Download (file akun)
    ├── :443   → HAProxy TLS
    │              ├── VMess WS TLS   → Xray :8443
    │              ├── VLess WS TLS   → Xray :8444
    │              ├── Trojan WS TLS  → Xray :8445
    │              ├── VMess gRPC     → Xray :8446
    │              ├── VLess gRPC     → Xray :8447
    │              └── Trojan gRPC    → Xray :8448
    └── :7100-7300 → BadVPN UDP
```

---

## 📦 Requirements

| Komponen | Versi |
|---|---|
| **OS** | Ubuntu 22.04 LTS *(wajib)* |
| **RAM** | Minimal 512MB (Rekomendasi 1GB+) |
| **Storage** | Minimal 5GB |
| **Akses** | Root / sudo |
| **Domain** | Domain aktif yang sudah diarahkan ke IP VPS |

> ⚠️ **Script ini hanya support Ubuntu 22.04 LTS.** Versi Ubuntu lain tidak dijamin berjalan normal.

---

## 🚀 Cara Install

### Install Otomatis (1 Command)

```bash
bash <(wget -qO- https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/install.sh)
```

### Install Manual

```bash
# Download file
wget -O /root/tunnel.enc https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/tunnel.enc
wget -O /root/tunnel_run https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/tunnel_run

# Beri permission
chmod +x /root/tunnel_run

# Jalankan
/root/tunnel_run
```

---

## 🎮 Cara Penggunaan

Setelah install, ketik perintah berikut di terminal:

```bash
menu
```

Panel akan muncul otomatis. Navigasi menggunakan angka sesuai menu yang tampil.

---

## ❌ Uninstall

```
menu → [19] Uninstall Panel → [8] Hapus Semua Script
```

---

## 🔐 Keamanan Script

Script panel ini **terenkripsi dan diproteksi**. Isi script tidak dapat dilihat atau dimodifikasi oleh pihak lain. Ini memastikan:

- Tidak ada yang bisa copy/bajak script kamu
- Konfigurasi & logic panel aman
- Hanya bisa dijalankan, tidak bisa dibaca

---

## ⚠️ Disclaimer

Pengguna bertanggung jawab penuh atas penggunaan script ini. Developer tidak bertanggung jawab atas penyalahgunaan. Script ini dibuat untuk keperluan **edukasi dan personal VPN server**.

---

## 📞 Support & Kendala

Jika ada kendala saat instalasi atau penggunaan, silakan hubungi admin langsung:

<div align="center">

[![Telegram](https://img.shields.io/badge/Telegram-@YouzinCrabz-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/YouzinCrabz)

**Fast response · Siap bantu 24 jam**

</div>

---

<div align="center">

**Youzin Crabz Tunel — The Professor**

*Script VPN terpercaya, aman, dan siap bisnis*

</div>
