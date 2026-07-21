# VPN Panel + OrderVPN Web

Standalone bash installer untuk VPS Ubuntu yang menginstall dan mengelola server multi-protokol VPN (SSH, VMess, VLess, Trojan) dan web panel OrderVPN untuk penjualan akun otomatis.

## Fitur Utama

- **VPN Multi-Protokol**: SSH, Dropbear, VMess, VLess, Trojan (WS + gRPC)
- **UDP Gateway**: BadVPN dan ZI VPN UDP
- **OrderVPN Web**: Web panel untuk registrasi user, order akun, topup saldo, dan monitoring
- **Telegram Bot**: Notifikasi dan remote command (opsional)
- **Auto Install**: Satu script mengurus semua (Xray, Nginx, MySQL, PHP, Web Panel)

## Persyaratan

- VPS Ubuntu 20.04 / 22.04 / 24.04
- Akses root
- Minimal 1 GB RAM, 10 GB disk
- Domain yang sudah di-pointing ke IP VPS (opsional tapi direkomendasikan untuk SSL)

## Cara Install

### 1. Download dan Jalankan Script

```bash
wget https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/vpn.sh
chmod +x vpn.sh
./vpn.sh
```

Saat pertama kali dijalankan, script akan otomatis masuk ke mode install dan menanyakan domain.

### 2. Pilih Domain

Pilih opsi:
- **Domain sendiri** → masukkan domain seperti `vpn.example.com`
- **Generate otomatis** → script membuatkan domain nip.io otomatis

### 3. Selesaikan Installasi

Installasi akan otomatis menginstall:
- Xray Core
- Nginx
- Dropbear
- MySQL/MariaDB
- PHP-FPM + module
- Web panel OrderVPN

## Cara Menggunakan Menu

Setelah installasi selesai, ketik `menu` untuk membuka panel:

```bash
menu
```

Menu utama akan muncul dengan pilihan 0-24.

| No | Menu | Fungsi |
|----|------|--------|
| 1 | SSH / OpenVPN | Kelola akun SSH |
| 2 | VMess Account | Kelola akun VMess |
| 3 | VLess Account | Kelola akun VLess |
| 4 | Trojan Account | Kelola akun Trojan |
| 5 | List All Accounts | Lihat semua akun |
| 21 | OrderVPN Web | Deploy web panel OrderVPN |
| 22 | DDoS Protect | Proteksi DDoS |
| 23 | Traffic Monitor | Monitoring traffic |

## Menu 21: OrderVPN Web

### Apa itu OrderVPN Web?

OrderVPN Web adalah web panel untuk jualan akun VPN. User bisa:
- Register/login
- Verifikasi email via OTP
- Pesan akun VPN
- Topup saldo
- Lihat traffic dan status akun

### Cara Deploy

1. Buka menu:
   ```bash
   menu
   ```

2. Pilih nomor **21** (OrderVPN Web).

3. Pilih opsi domain web:
   - **Pakai domain sendiri** → masukkan domain seperti `web.example.com`
   - **Generate otomatis** → script membuatkan domain otomatis
   - **Pakai domain utama** → pakai domain yang sudah diset sebelumnya

4. Script akan otomatis:
   - Download source web dari GitHub Release atau file lokal
   - Verifikasi SHA256 (untuk keamanan)
   - Ekstrak ke `/var/www/html/ordervpn`
   - Setup database MySQL
   - Install PHP-FPM dan module
   - Setup Nginx config
   - Menanyakan konfigurasi SMTP untuk email OTP

### Setup SMTP untuk Email OTP

Saat deploy web, script akan menanyakan SMTP untuk kirim email OTP:

```text
SMTP Host [smtp.gmail.com]: 
SMTP Port [587]: 
SMTP User [emailkamu@gmail.com]: 
SMTP Password (App Password): 
SMTP From [emailkamu@gmail.com]: 
SMTP Secure [tls]: 
```

Untuk **Gmail**, kamu **WAJIB** membuat **App Password**:

1. Buka https://myaccount.google.com/
2. Pilih **Security**
3. Aktifkan **2-Step Verification** dulu (wajib)
4. Cari **App passwords**
5. Pilih **Mail** dan device, lalu klik **Generate**
6. Copy password 16 digit, itu yang dimasukkan ke prompt SMTP Password

### Akses Web Panel

Setelah deploy selesai, buka browser:

```text
https://domain-utama-anda.com/ordervpn
```

atau jika pakai subdomain:

```text
https://web.example.com
```

## Build dan Release Web

### Struktur Web Source

Source web ada di folder:

```
ordervpn-src/
├── index.php           # Landing page + auth
├── dashboard.php     # User dashboard
├── admin/index.php   # Admin panel
├── includes/         # Config dan helper
├── api/              # API endpoint
├── cron/             # Cron jobs
├── install.sql       # Database schema
└── .env.example      # Template environment
```

### Build Tarball

Setelah mengubah source web, jalankan:

```bash
bash build.sh
```

Script ini akan:
1. Membuat `ordervpn-src.tar.gz`
2. Hitung SHA256
3. Update otomatis `ORDERVPN_TAR_SHA256` di `vpn.sh`

### Push ke GitHub

```bash
git add -A
git commit -m "deskripsi perubahan"
git push origin main
```

### Buat GitHub Release

Supaya menu 21 bisa download web dari GitHub, buat Release:

1. Buka https://github.com/putrinuroktavia234-max/Tunnel/releases
2. Klik **Draft a new release**
3. Pilih atau buat tag baru, contoh: `v3.12.0`
4. Upload file `ordervpn-src.tar.gz` sebagai attachment
5. Klik **Publish release**

Setelah release dibuat, `vpn.sh` akan otomatis download dari URL release tersebut dan verifikasi SHA256.

## Cara Update Script

Untuk mengupdate script ke versi terbaru:

```bash
wget -O /root/vpn.sh https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/vpn.sh
chmod +x /root/vpn.sh
```

Lalu jalankan `menu` lagi.

## CLI Commands

Selain menu interaktif, script juga bisa dipanggil langsung:

```bash
./vpn.sh menu           # Buka menu interaktif
./vpn.sh install        # Installasi awal
./vpn.sh web            # Deploy web panel
./vpn.sh security       # Terapkan hardening CSRF/OTP/rate limit
./vpn.sh status         # Lihat status sistem
./vpn.sh list           # List semua akun
./vpn.sh delete_expired # Hapus akun expired (untuk cron)
```

## Ports

| Port | Service |
|------|---------|
| 22 | OpenSSH |
| 222 | Dropbear |
| 80 | Nginx HTTP |
| 443 | Nginx HTTPS |
| 8080-8082 | Xray WS internal |
| 8444-8446 | Xray gRPC internal |
| 7100-7300 | BadVPN UDP |
| 7400-7500 | ZI VPN UDP |

## Troubleshooting

### Web tidak bisa dibuka

1. Cek Nginx status:
   ```bash
   systemctl status nginx
   ```

2. Cek PHP-FPM status:
   ```bash
   systemctl status php*-fpm
   ```

3. Cek error log:
   ```bash
   tail -f /var/log/nginx/error.log
   ```

### Email OTP tidak terkirim

1. Cek konfigurasi SMTP di `/var/www/html/ordervpn/.env`
2. Pastikan menggunakan **App Password** untuk Gmail, bukan password Gmail biasa
3. Cek error log PHP:
   ```bash
   tail -f /var/log/php*-fpm.log
   ```

### SSL Certificate Error

1. Pastikan domain sudah pointing ke IP VPS
2. Pastikan port 80 terbuka
3. Jalankan menu SSL (nomor 11) untuk fix certificate

## Keamanan

- File `.env` memiliki permission `600`
- CSRF protection otomatis diaktifkan
- Rate limiting untuk OTP dan autentikasi
- SHA256 verification untuk source web yang di-download

## Build dan Kontribusi

Jika ingin mengubah source web:

1. Edit file di `ordervpn-src/`
2. Jalankan `bash build.sh`
3. Commit dan push
4. Buat GitHub Release baru dan upload `ordervpn-src.tar.gz`

## Lisensi

Released under the [MIT License](LICENSE).
