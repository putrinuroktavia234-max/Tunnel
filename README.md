# 🦀 YouzinCrabz Tunnel

> Auto-install VPN panel untuk VPS Ubuntu — SSH, VMess, VLess, Trojan, WebSocket, gRPC, dan web panel penjualan akun.

[![Version](https://img.shields.io/badge/version-3.12.0-blue)](https://github.com/putrinuroktavia234-max/Tunnel)
[![Ubuntu](https://img.shields.io/badge/ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange)](https://ubuntu.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## ✨ Fitur

- **Multi-Protokol VPN** — SSH, Dropbear, VMess, VLess, Trojan (WebSocket + gRPC)
- **UDP Gateway** — BadVPN + ZI VPN UDP
- **Auto Install** — Satu command install semua: Xray, Nginx, SSL, dependensi
- **Dashboard Panel** — Menu interaktif untuk kelola akun, cek status, monitoring
- **OrderVPN Web** — Web panel untuk jualan akun otomatis (registrasi, OTP email, topup)
- **Telegram Bot** — Notifikasi dan remote command (opsional)

---

## 🚀 Install

```bash
wget https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/vpn.sh
chmod +x vpn.sh
./vpn.sh
```

Script akan otomatis masuk ke mode install dan menanyakan domain. Pilih:
- **Domain sendiri** → `vpn.example.com` (rekomendasi untuk SSL Let's Encrypt)
- **Generate otomatis** → domain `nip.io` otomatis (tanpa perlu beli domain)

Setelah instalasi selesai, panel bisa diakses dengan command `menu`.

---

## 📋 Persyaratan

| Komponen | Minimal |
|----------|---------|
| OS | Ubuntu 20.04 / 22.04 / 24.04 |
| Akses | root |
| RAM | 1 GB |
| Disk | 10 GB |
| Port | 22, 80, 443 terbuka |

---

## 🎛️ Menu Panel

Ketik `menu` untuk membuka dashboard:

| # | Menu | Keterangan |
|---|------|------------|
| 1-4 | SSH / VMess / VLess / Trojan | Buat & kelola akun VPN |
| 5 | List All Accounts | Lihat semua akun |
| 6 | Renew / Extend | Perpanjang masa aktif akun |
| 9 | Telegram Bot | Setup notifikasi bot |
| 10 | Change Domain | Ganti domain |
| 11 | SSL Manager | Perbaiki/renew sertifikat |
| 12 | Optimize VPS | Tuning BBR + sysctl |
| 21 | OrderVPN Web | Deploy web panel penjualan |
| 22 | DDoS Protect | Proteksi serangan DDoS |
| 23 | Traffic Monitor | Monitoring bandwidth |

---

## 🌐 OrderVPN Web Panel

Panel web untuk jualan akun VPN otomatis. Fitur: registrasi user, verifikasi email OTP, order akun, topup saldo, monitoring traffic.

### Deploy

1. Buka `menu` → pilih **21**
2. Pilih domain web (sendiri / otomatis)
3. Script akan setup Nginx, MySQL, PHP-FPM, dan konfigurasi otomatis
4. Masukkan SMTP untuk kirim email OTP

### Setup SMTP Gmail

Buat **App Password** di Google:
1. Buka https://myaccount.google.com/security
2. Aktifkan 2-Step Verification
3. Buat App Password → pilih *Mail* + *Other*
4. Masukkan 16-digit password saat diminta script

### Akses

```
https://domain-anda.com/ordervpn
```

---

## 🔧 CLI Commands

```bash
./vpn.sh menu              # Buka panel interaktif
./vpn.sh install           # Ulangi instalasi
./vpn.sh web               # Deploy ulang web panel
./vpn.sh security          # Hardening CSRF/OTP/rate limit
./vpn.sh status            # Cek status sistem
./vpn.sh list              # List semua akun
./vpn.sh delete_expired    # Hapus akun expired (cron)
```

---

## 🔌 Ports

| Port | Service |
|------|---------|
| 22 | OpenSSH |
| 222 | Dropbear |
| 80, 443 | Nginx HTTP/HTTPS |
| 8080-8082 | Xray WebSocket |
| 8444-8446 | Xray gRPC |
| 7100-7300 | BadVPN UDP |
| 7400-7500 | ZI VPN UDP |

---

## 🐛 Troubleshooting

**Web panel tidak bisa dibuka?**
```bash
systemctl status nginx php*-fpm
tail -f /var/log/nginx/error.log
```

**Email OTP tidak terkirim?**
- Pastikan pakai App Password (bukan password Gmail biasa)
- Cek konfigurasi di `/var/www/html/ordervpn/.env`

**SSL error?**
- Pastikan domain sudah pointing ke IP VPS
- Jalankan `menu` → pilih **11** (SSL Manager)

---

## 🛠️ Development

Untuk mengedit source web panel:

```bash
# Edit file di ordervpn-src/
bash build.sh            # Build tarball + update SHA256 di vpn.sh
git commit -m "..." && git push
```

Build script otomatis menghitung SHA256 dan update variabel `ORDERVPN_TAR_SHA256` di `vpn.sh`.

---

## 📄 Lisensi

[MIT License](LICENSE) — © The Professor
