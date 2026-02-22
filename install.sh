#!/bin/bash

clear
echo "===================================="
echo "      INSTALLING TUNNEL SYSTEM      "
echo "===================================="
sleep 1

# Download binary utama
echo "[+] Downloading core..."
wget -q -O /usr/local/bin/tunnel http://up.theproff.my.id/tunnel

# Permission
chmod +x /usr/local/bin/tunnel

# Lock file agar tidak bisa diubah
chattr +i /usr/local/bin/tunnel 2>/dev/null

echo "[+] Installation complete!"
sleep 1

# Jalankan program
/usr/local/bin/tunnel
