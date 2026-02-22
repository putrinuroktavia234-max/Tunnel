#!/bin/bash
clear
echo "Installing Tunnel Panel..."

apt update -y
apt install -y curl wget -y

# Download binary terenkripsi dari domain
wget -O /usr/local/bin/menu http://up.theproff.my.id/tunnel
chmod +x /usr/local/bin/menu

clear
echo "================================="
echo " INSTALLATION SUCCESSFUL ✅"
echo " Ketik: menu"
echo "================================="
