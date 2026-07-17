# VPN Panel — Standalone Binary

**SSH • VMess • VLess • Trojan • WebSocket • gRPC • Multi-VPS • OrderVPN Web**

Script auto-install VPN lengkap — compiled jadi satu file binary. Tinggal download & jalanin.

---

## Cara Install

**VPS AMD64 (Intel/AMD):**
```bash
wget https://github.com/putrinuroktavia234-max/Tunnel/raw/main/vpn-linux-amd64 -O vpn
chmod +x vpn
./vpn
```

**VPS ARM64 (Oracle, AWS Graviton, dll):**
```bash
wget https://github.com/putrinuroktavia234-max/Tunnel/raw/main/vpn-linux-arm64 -O vpn
chmod +x vpn
./vpn
```

---

## Perintah

| Perintah | Fungsi |
|----------|--------|
| `./vpn` / `./vpn menu` | Buka menu interaktif |
| `./vpn install` | Installasi awal semua service |
| `./vpn web` | Deploy web panel |
| `./vpn status` | Tampilkan status server |
| `./vpn list` | List semua akun |
| `./vpn delete_expired` | Hapus akun expired |
| `./vpn backup` | Backup data |
| `./vpn restore` | Restore data |

---

## Fitur

- **SSH** — OpenSSH + Dropbear
- **VMess / VLess / Trojan** — WebSocket TLS/NonTLS + gRPC
- **UDP** — BadVPN + ZI VPN
- **Web Panel** — OrderVPN dengan dashboard, order, top-up
- **Telegram Bot** — Notifikasi & management multi-VPS
- **Auto Backup** — Google Drive (rclone)
- **DDoS Protection** — 40+ iptables rules
- **Fail2ban** — Brute force protection
- **BBR Optimization** — TCP tuning
- **Health Check** — Verifikasi 50+ service
- **SSL Let's Encrypt** — Auto-renew

---

## Credits

**Youzin Crabz Tunel — The Professor**
