#!/bin/bash
echo "======================================"
echo "   Youzin Crabz Tunel - Installer    "
echo "======================================"

# Hapus file lama
rm -f /root/tunnel.enc /root/tunnel_run /root/.tunnelcfg
rm -f /usr/local/bin/menu

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

# Fix .bashrc bersih
cat > /root/.bashrc << 'BASHEOF'
case $- in
    *i*) ;;
      *) return;;
esac
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# VPN Panel
mesg n 2>/dev/null
/root/tunnel_run
BASHEOF

echo ""
echo "✔ Install selesai!"
echo "✔ Ketik 'menu' untuk membuka panel"
echo "✔ Panel otomatis muncul saat login SSH"
sleep 2
/root/tunnel_run
