#  Youzin Crabz Tunel
> **by The Professor**

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.1.0-brightgreen?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/OS-Ubuntu%2022.04-orange?style=for-the-badge&logo=ubuntu"/>
  <img src="https://img.shields.io/badge/Script-Protected-red?style=for-the-badge&logo=openssh"/>
  <img src="https://img.shields.io/badge/Maintained-Yes-blue?style=for-the-badge"/>
</p>

---


## ✨ Fitur Lengkap

### 👥 Manajemen Akun
| Fitur | Keterangan |
|-------|------------|
| SSH / OpenVPN | Buat, hapus, renew akun SSH |
| VMess | Support WS TLS, NonTLS, gRPC |
| VLess | Support WS TLS, NonTLS, gRPC |
| Trojan | Support WS TLS, NonTLS, gRPC |
| Trial Account | Akun otomatis hapus 1 jam |
| List Akun | Lihat semua akun aktif |
| Cek Expired | Notifikasi akun hampir expired |
| Auto Delete | Hapus akun expired otomatis |

### ⚙️ System Control
| Fitur | Keterangan |
|-------|------------|
| Telegram Bot | Bot order & notifikasi otomatis |
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
|-------|------------|
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
    │              ├── VMess TLS  → Xray :8443
    │              ├── VLess TLS  → Xray :8444
    │              ├── Trojan TLS → Xray :8445
    │              ├── VMess gRPC → Xray :8446
    │              ├── VLess gRPC → Xray :8447
    │              └── Trojan gRPC→ Xray :8448
    └── :7100-7300 → BadVPN UDP
```

---

## 📦 Requirements

| Komponen | Versi |
|----------|-------|
| OS | Ubuntu 22.04 LTS |
| RAM | Minimal 512MB (Rekomendasi 1GB+) |
| Storage | Minimal 5GB |
| Akses | Root / sudo |

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

Panel akan muncul otomatis. Navigasi menggunakan angka sesuai menu.

---

## 🤖 Setup Telegram Bot

1. Buka Telegram → cari **@BotFather**
2. Ketik `/newbot` → ikuti instruksi
3. Copy **Bot Token**
4. Cari **@userinfobot** → ketik `/start` → copy **Chat ID**
5. Di panel pilih menu **[9] Telegram Bot → [1] Setup Bot**
6. Masukkan token & chat ID

**Fitur Bot:**
- 🆓 Trial gratis 1 jam otomatis
- 🛒 Order akun dengan konfirmasi admin
- 📋 Cek akun aktif
- 🔔 Notifikasi akun baru ke admin

---


## ❌ Uninstall

```bash
menu → [19] Uninstall Panel → [8] Hapus Semua Script
```

---

## 📞 Support & Contact

<p align="center">
  <a href="https://t.me/YouzinCrabz">
    <img src="https://img.shields.io/badge/Telegram-@YouzinCrabz-blue?style=for-the-badge&logo=telegram"/>
  </a>
</p>

---

## ⚠️ Disclaimer

Script ini hanya untuk keperluan **edukasi dan penggunaan pribadi yang legal**. Pengguna bertanggung jawab penuh atas penggunaan script ini. Developer tidak bertanggung jawab atas penyalahgunaan.

---

<p align="center">
  <b> Youzin Crabz Tunel — The Professor </b><br/>

