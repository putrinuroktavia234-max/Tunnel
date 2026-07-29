# 🔒 Security Policy

## Supported Versions

| Version | Supported | Status |
|---------|-----------|--------|
| 3.12.x | ✅ | Active development |
| < 3.12 | ❌ | End of life |

## 🛡️ Security Features

OrderVPN includes the following security measures:

### Web Panel Security
- **CSRF Protection** — All forms include CSRF token validation
- **Rate Limiting** — Login attempts limited to 5 per 15 minutes per IP
- **OTP Email Verification** — Users must verify email before login
- **Password Hashing** — bcrypt via PHP `password_hash()`
- **SQL Injection Prevention** — PDO prepared statements throughout
- **XSS Prevention** — `htmlspecialchars()` escaping on all output
- **Sudoers Restriction** — `www-data` can only execute `vpn-api` binary

### Server Security
- **Fail2ban** — Brute-force SSH protection
- **UFW Firewall** — Auto-configured port rules
- **DDoS Protection** — Rate limiting & IP ban rules
- **SSL/TLS** — Let's Encrypt or Self-signed certificates
- **SSH Key Authentication** — Passwordless SSH between master and nodes
- **Keepalive** — systemd service monitors connectivity

## 🐛 Reporting a Vulnerability

If you discover a security vulnerability, please **DO NOT** open a public GitHub issue.

### How to Report

1. **Telegram**: Contact [@OrderVPN](https://t.me/OrderVPN) privately
2. **GitHub**: Use the [Security Advisories](https://github.com/putrinuroktavia234-max/Tunnel/security/advisories/new) feature

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

| Step | Timeframe |
|------|-----------|
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 7 days |
| Fix release | Within 30 days (severity dependent) |
| Public disclosure | After fix is released |

### Scope

**In scope:**
- SQL injection in web panel
- Authentication bypass
- CSRF vulnerabilities
- Privilege escalation
- Remote code execution

**Out of scope:**
- Social engineering attacks
- Physical access attacks
- DoS/DDoS on public infrastructure
- Vulnerabilities in third-party software (Xray, Nginx, etc.) — report to respective vendors

## 🏆 Acknowledgments

Security researchers who responsibly disclose vulnerabilities will be credited here (with their permission).

---

*Thank you for helping keep OrderVPN secure.*
