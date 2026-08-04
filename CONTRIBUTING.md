# 🤝 Contributing to OrderVPN

Thank you for your interest in contributing to OrderVPN! 

Since this is a **proprietary project**, contributions are handled differently than typical open-source projects.

## 📋 Ways to Contribute

### 1. 🐛 Bug Reports

Found a bug? Please report it:

1. Check if the issue already exists in [Issues](https://github.com/putrinuroktavia234-max/Tunnel/issues)
2. If not, open a new issue with:
   - **Title**: Clear, descriptive title
   - **Environment**: Ubuntu version, VPS specs, script version
   - **Steps to reproduce**: Detailed step-by-step
   - **Expected behavior**: What should happen
   - **Actual behavior**: What actually happens
   - **Logs**: Relevant error messages or screenshots

### 2. 💡 Feature Requests

Have an idea? We'd love to hear it:

1. Open an issue with the `enhancement` label
2. Describe the feature and why it would be useful
3. If possible, suggest how it could be implemented

### 3. 🔒 Security Vulnerabilities

**Do NOT open a public issue for security vulnerabilities.**

See [SECURITY.md](SECURITY.md) for the responsible disclosure process.

## ⚠️ Important Notes

### Code Contributions

This project is **proprietary**. Source code modifications are permitted for personal use only. If you have a fix or improvement:

1. Contact [@OrderVPN](https://t.me/OrderVPN) on Telegram
2. Describe your proposed change
3. If accepted, you'll be guided on how to submit

### What We're Looking For

- 🐛 Bug fixes (especially Ubuntu 24.04 compatibility)
- 🚀 Performance improvements
- 🌍 Multi-OS support (Debian, CentOS)
- 🎨 UI/UX improvements for web panel
- 📖 Documentation improvements
- 🔒 Security hardening

## 📝 Code Style

### Shell Scripts (*.sh)

```bash
# Use 4-space indentation
# Functions use snake_case
function_name() {
    local var="value"
    echo -e "  ${CYAN}Message${NC}"
}

# Comments in English or Indonesian
# Use ANSI colors: RED, GREEN, YELLOW, CYAN, WHITE, NC
# Box drawing: ━ ─ for separators
```

### PHP (Web Panel)

```php
<?php
// Use PDO prepared statements
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$id]);

// Escape output
echo esc($user_input);

// Use getSetting() for config values
$appName = getSetting('app_name', 'OrderVPN');
```

### CSS

```css
/* Use CSS variables for theming */
:root {
    --accent: #6366f1;
    --card: #0f1623;
}

/* Mobile-first approach */
/* Minify for production */
```

## 🧪 Testing

Before submitting a fix, test on:

- [ ] Ubuntu 20.04 LTS
- [ ] Ubuntu 22.04 LTS
- [ ] Ubuntu 24.04 LTS
- [ ] Container (LXC/OpenVZ) — if applicable

### Quick Test Commands

```bash
# Private installer source is validated in Tunnel-source.
# Public repository checks are limited to the web-panel shell scripts.
find ordervpn-src -type f -name '*.sh' -print0 | xargs -0 -r -n1 bash -n
find ordervpn-src -type f -name '*.sh' -print0 | xargs -0 -r -n1 shellcheck

# The protected VPN binary is tested from the Tunnel-source workflow.
```

## 📜 License Reminder

By contributing, you acknowledge that:
- All contributions become part of the proprietary project
- The Author retains all rights to the Software
- You will not redistribute the modified source

See [LICENSE](LICENSE) for full terms.

---

<div align="center">

Questions? Contact **[@OrderVPN](https://t.me/OrderVPN)** on Telegram

</div>
