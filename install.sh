#!/bin/bash
echo "======================================"
echo "   Youzin Crabz Tunel - Installer    "
echo "======================================"

# Hapus file lama
rm -f /root/tunnel.enc /root/tunnel_run /root/.tunnelcfg
rm -f /usr/local/bin/menu
sed -i '/tunnel_run/d' /root/.bashrc 2>/dev/null
sed -i '/mesg n/d' /root/.bashrc 2>/dev/null

# Download file
echo "Downloading files..."
wget -q --show-progress \
  -O /root/tunnel.enc \
  "https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel-Private/main/tunnel.enc"

wget -q --show-progress \
  -O /root/tunnel_run \
  "https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel-Private/main/tunnel_run"

chmod +x /root/tunnel_run

# Simpan password
echo "youzincrabz" > /root/.tunnelcfg
chmod 600 /root/.tunnelcfg

# Buat perintah menu
cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
mesg n 2>/dev/null
clear
/root/tunnel_run
MENUEOF
chmod +x /usr/local/bin/menu

# Auto launch saat login
cat >> /root/.bashrc << 'BASHEOF'

# VPN Panel
if [[ $- == *i* ]]; then
  mesg n 2>/dev/null
  /root/tunnel_run
fi
BASHEOF

echo ""
echo "✔ Install selesai!"
echo "✔ Ketik 'menu' untuk membuka panel"
echo "✔ Panel otomatis muncul saat login"
sleep 2
/root/tunnel_run
