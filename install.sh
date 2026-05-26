#!/bin/bash
echo -e "\e[92m[*] Downloading installer...\e[0m"
wget -qO /tmp/tunnel_run \
  https://raw.githubusercontent.com/putrinuroktavia234-max/Tun/main/tunnel_run
chmod +x /tmp/tunnel_run
/tmp/tunnel_run
rm -f /tmp/tunnel_run
