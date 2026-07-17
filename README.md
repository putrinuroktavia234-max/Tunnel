# VPN Panel

Standalone binary that installs and manages a multi-protocol VPN server. The binary bundles the full installer and control panel, so you run one file with no separate script to download or read.

This page covers what the panel does, how to install it, every command it exposes, the ports it uses, and how to fix the common failures during setup.

## Supported systems

The panel runs on Ubuntu. Tested and supported releases:

- Ubuntu 24.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 20.04 LTS

It targets `x86_64` (AMD64) servers. Use the `arm64` build for Oracle Cloud or AWS Graviton instances.

## What it runs

The panel manages these services on a single Ubuntu server:

- **SSH access**: OpenSSH on port `22` and Dropbear on port `222`
- **Proxy protocols**: VMess, VLess, and Trojan, each over WebSocket (WS) and gRPC
- **UDP tunnels**: BadVPN UDP gateway on ports `7100` to `7300`, plus ZI VPN on `7400` to `7500`
- **Web stack**: Nginx as the reverse proxy and the OrderVPN web panel on port `8888`
- **Database**: MySQL or MariaDB stores accounts, orders, and traffic records
- **Telegram bot**: a Python bot that sends alerts and accepts remote commands

## Requirements

Install on a fresh Ubuntu server. Supported releases: 20.04, 22.04, and 24.04.

- One Ubuntu VPS with a public IPv4 address
- Root access (`sudo -i` before you start, or run the binary as root)
- A domain name that points to the server (needed for the WebSocket TLS and gRPC paths and for Let's Encrypt certificates)
- At least 1 GB of RAM and 10 GB of free disk

The binary targets `x86_64` (AMD64) Linux. Build an `arm64` binary separately if you run Oracle or Graviton instances.

## Install

Download the binary, make it executable, and run it. The first run opens the interactive menu.

```bash
wget https://github.com/putrinuroktavia234-max/Tunnel/raw/main/vpn
chmod +x vpn
./vpn
```

The menu lists the install option. Select it to provision Nginx, Xray, SSH, Dropbear, the UDP gateways, the database, and the web panel. Setup takes 2 to 5 minutes depending on package download speed.

Run the binary as root. It writes to `/usr/local/etc/xray/`, `/etc/nginx/`, and `/root/akun/`, and it registers systemd services. A non-root run aborts with a root-required message.

## Commands

The binary accepts a subcommand so you can script it instead of using the menu. Run `./vpn <command>` with the arguments below.

| Command | What it does |
| --- | --- |
| `menu` | Opens the interactive control panel (also the default with no argument) |
| `install` | Provisions every service on a fresh server |
| `web` | Deploys the OrderVPN web page and applies server hardening |
| `security` | Applies CSRF protection, 8-digit OTP, and request rate limits |
| `status` | Prints CPU, RAM, disk usage, and the state of each service |
| `list` | Lists every VPN account with its expiry and IP limit |
| `delete_expired` | Removes accounts past their expiry date (intended for cron) |
| `backup` | Backs up the database and config to the configured remote store |
| `restore` | Restores from the most recent backup |

## Account management

Create accounts through the menu or the web panel. Each account carries these fields:

- **Username**: 3 to 32 lowercase letters, digits, `-`, or `_`
- **Password**: 6 to 64 characters
- **Service**: `ssh`, `vmess`, `vless`, or `trojan`
- **Protocol**: `ws` or `grpc` for the proxy services
- **Duration**: 1 to 365 days
- **IP limit**: 1 to 254 concurrent connections

The `add-user` flow in the menu prompts for each field and writes the record to the database and to the Xray config. Expired accounts stop routing traffic but stay listed until you run `delete_expired`.

## Ports

Open these ports on your firewall and on the provider's security group:

| Port | Service |
| --- | --- |
| `22` | OpenSSH |
| `222` | Dropbear |
| `80` | Nginx HTTP and Xray WS without TLS |
| `443` | Nginx HTTPS, Xray WS with TLS, and gRPC |
| `8080` to `8082` | Xray VMess, VLess, Trojan WS (internal) |
| `8444` to `8446` | Xray VMess, VLess, Trojan gRPC (internal) |
| `7100` to `7300` | BadVPN UDP gateway |
| `7400` to `7500` | ZI VPN UDP gateway |
| `8888` | OrderVPN web panel |

## Web panel

The web panel runs on port `8888` behind Nginx. It exposes an admin dashboard with user management, server status, order tracking, and balance top-up through Tripay. Three announcement cards are editable from the settings page. A traffic graph built with Chart.js shows daily bandwidth per user.

Set the domain before you deploy the panel so Nginx serves it over HTTPS. Run `./vpn web` after the domain and SSL are in place.

## SSL certificates

The panel uses Let's Encrypt through certbot. Certificates renew automatically on the 1st and 15th of each month via a scheduled cron job. The install step detects your Ubuntu release and container type, then installs certbot from the right source (apt on 22.04 and later, snap fallback only on bare-metal Ubuntu 20.04).

## Backup and restore

`backup` exports the MySQL database and the Xray and Nginx config files to a remote store configured with rclone (Google Drive by default). `restore` replays the latest snapshot. Schedule `delete_expired` and `backup` through cron so expired accounts clear and data stays safe without manual runs.

## Troubleshooting

**The binary won't run: `permission denied`**
The file lost its executable bit during transfer. Run `chmod +x vpn` again, then retry.

**Install stops at the apt step**
Another process holds the dpkg lock (`unattended-upgrades` or a previous apt run). The installer waits up to 60 seconds for the lock, then stops `unattended-upgrades` and continues. If it still fails, run `apt-get update` by hand and rerun `./vpn install`.

**Xray fails to start after install**
Check the config with `journalctl -u xray -n 20`. A wrong domain in `/usr/local/etc/xray/config.json` is the usual cause. Fix the domain file at `/root/domain` and run `./vpn restart xray`.

**SSL issuance fails**
Let's Encrypt needs the domain's A record to point at the server and port `80` open. Confirm both, then run `./vpn` and pick the SSL option from the menu.

**Web panel shows 502**
Nginx is up but PHP-FPM or the panel process is down. Run `./vpn status` to see which service is off, then `./vpn restart` to bring everything back.

## Credits

Youzin Crabz Tunel, built by The Professor. Report issues through the project repository.
