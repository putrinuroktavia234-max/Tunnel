#!/bin/bash
wget -qO /tmp/tunnel_run \
  https://raw.githubusercontent.com/putrinuroktavia234-max/Tunnel/main/tunnel_run
chmod +x /tmp/tunnel_run
/tmp/tunnel_run
rm -f /tmp/tunnel_run
