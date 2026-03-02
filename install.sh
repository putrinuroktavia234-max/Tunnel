#!/bin/bash
echo "======================================"
echo "   Youzin Crabz Tunel - Installer    "
echo "======================================"

wget -q --show-progress \
  -O /root/tunnel.enc \
  "https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel-Private/main/tunnel.enc"

wget -q --show-progress \
  -O /root/tunnel_run \
  "https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel-Private/main/tunnel_run"

chmod +x /root/tunnel_run

# Simpan password di VPS
echo "youzincrabz" > /root/.tunnelcfg
chmod 600 /root/.tunnelcfg

cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
mesg n 2>/dev/null
/root/tunnel_run
MENUEOF
chmod +x /usr/local/bin/menu

if ! grep -q "tunnel_run" /root/.bashrc; then
cat >> /root/.bashrc << 'BASHEOF'

mesg n 2>/dev/null
/root/tunnel_run
BASHEOF
fi

echo "✔ Install selesai! Ketik 'menu' untuk mulai"
sleep 1
/root/tunnel_run
