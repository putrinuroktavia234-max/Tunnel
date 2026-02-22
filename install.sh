#!/bin/bash
clear
echo "Installing Tunnel Panel (Root-Only Binary)..."

if [[ $EUID -ne 0 ]]; then
   echo "Run as root!"
   exit 1
fi

apt update -y
apt install -y curl wget

# Download binary dari domain
wget -O /usr/local/bin/menu http://up.theproff.my.id/tunnel
chmod 700 /usr/local/bin/menu

clear
echo "================================="
echo " INSTALLATION SUCCESSFUL ✅"
echo " Jalankan: menu"
echo "================================="
