# ⚡ Youzin Crabz Tunel
**by The Professor** — VPN Panel Management Script

---

## 📋 Deskripsi

Youzin Crabz Tunel adalah script manajemen VPN panel berbasis terminal untuk Ubuntu. Script ini otomatis menginstall dan mengkonfigurasi semua layanan VPN yang dibutuhkan dalam satu perintah, lengkap dengan menu interaktif dan Telegram Bot untuk manajemen akun.

> ⚠️ **Script ini dikompilasi ke binary** — tidak dapat diedit atau dimodifikasi.

---

## ✅ Sistem yang Didukung

| OS | Versi | Status |
|---|---|---|

| Ubuntu | 22.04 LTS | ✅ Didukung |


> OS lain tidak didukung.

---

## 📦 Layanan yang Diinstall Otomatis

| Layanan | Fungsi |
|---|---|
| **Xray-Core** | Engine utama VMess / VLess / Trojan |
| **Nginx** | Reverse proxy WebSocket NonTLS |
| **HAProxy** | Load balancer TLS port 443 |
| **Dropbear** | SSH alternatif port 222 |
| **OpenSSH** | SSH utama port 22 |
| **Certbot** | SSL Let's Encrypt otomatis |
| **BadVPN UDP** | Custom UDP port 7100–7300 |
| **Telegram Bot** | Manajemen akun via Telegram |

---

## 🔌 Port yang Digunakan

| Port | Layanan |
|---|---|
| `22` | SSH (OpenSSH) |
| `80` | Nginx NonTLS / WebSocket |
| `81` | Nginx Download Page |
| `222` | Dropbear SSH |
| `443` | HAProxy TLS → Xray |
| `8443` | Xray TLS internal |
| `8444` | Xray gRPC TLS |
| `7100–7300` | BadVPN UDP Custom |

---

## 🚀 Cara Install

### Persyaratan
- VPS Ubuntu 20.04 / 22.04 / 24.04
- Login sebagai **root**
- RAM minimal **512 MB** (rekomendasi 1 GB+)
- Domain yang sudah diarahkan ke IP VPS (untuk SSL Let's Encrypt)

### Langkah Install

**1. Download script**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/install.sh)
```


Script akan otomatis memulai proses instalasi, meminta domain, lalu menginstall semua komponen. Setelah selesai VPS akan **reboot otomatis**.

**4. Buka menu setelah reboot**
```bash
menu
```

---

## 📱 Fitur Menu

```
[1]  SSH / OpenVPN        [5]  Trial Account
[2]  VMess Account        [6]  List All Accounts
[3]  VLess Account        [7]  Check Expired
[4]  Trojan Account       [8]  Delete Expired

[9]  Telegram Bot         [15] Speedtest VPS
[10] Change Domain        [16] Update Panel
[11] Fix SSL / Cert       [17] Backup Config
[12] Optimize VPS         [18] Restore Config
[13] Restart Services     [19] Uninstall Panel
[14] Port Info            [20] Advanced Mode

[0]  Exit Panel
```

---

## 🤖 Telegram Bot

Panel ini dilengkapi Telegram Bot untuk mempermudah manajemen akun tanpa perlu masuk ke VPS.

### Fitur Bot
- **Trial Gratis** — Buat akun trial SSH / VMess / VLess / Trojan
- **Order VPN** — Pelanggan order akun langsung via Telegram
- **Cek Akun** — Pelanggan cek status akun mereka
- **Info Server** — Tampilkan info VPS dan layanan
- **Konfirmasi Pembayaran** — Admin approve/reject order
- **Notifikasi Otomatis** — Bot kirim link akun setelah dikonfirmasi

### Setup Bot
1. Buka menu → pilih **[9] Telegram Bot**
2. Masukkan **Bot Token** dari @BotFather
3. Masukkan **Admin Telegram ID**
4. Isi info pembayaran (nama rekening, nomor, bank, harga)
5. Bot langsung aktif

---

## 🔐 Protokol VPN yang Didukung

### VMess
- WebSocket TLS port 443
- WebSocket NonTLS port 80
- gRPC TLS port 8444

### VLess
- WebSocket TLS port 443
- WebSocket NonTLS port 80
- gRPC TLS port 8444

### Trojan
- WebSocket TLS port 443
- WebSocket NonTLS port 80
- gRPC TLS port 8444

### SSH
- OpenSSH port 22
- Dropbear port 222
- Support payload / WebSocket

---


## 🗑️ Uninstall

```bash
menu
# pilih [19] Uninstall Panel
```

---

## 📞 Kontak

- Telegram: [@YouzinCrabz]

---

> Script ini dilindungi dalam bentuk binary. Dilarang mendistribusikan ulang tanpa izin.
