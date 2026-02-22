#!/bin/bash

# Cek root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root!"
  exit 1
fi

echo "Installing Tunnel..."

curl -L --fail http://up.theproff.my.id/tunnel -o /usr/local/sbin/tunnel

if [ $? -ne 0 ]; then
  echo "Download failed!"
  exit 1
fi

chmod +x /usr/local/sbin/tunnel

ln -sf /usr/local/sbin/tunnel /usr/local/sbin/menu

# Auto run saat login SSH (root saja)
grep -q "menu" /root/.bashrc || echo 'if [[ -n "$SSH_CONNECTION" ]]; then /usr/local/sbin/menu; fi' >> /root/.bashrc

echo "Install Success"
echo "Logout & Login again"
