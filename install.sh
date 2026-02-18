#!/bin/bash

clear
echo "Checking License..."

MYIP=$(curl -s https://api.ipify.org)
HWID=$(echo -n "$MYIP-$(cat /etc/machine-id 2>/dev/null)" | base64)

SERVER="https://scrip-hudaacuan.workers.dev"

curl -s "$SERVER/?ip=$MYIP&hwid=$HWID" -o tunnel.sh

if grep -q "License" tunnel.sh; then
    echo "License Invalid / Expired"
    rm -f tunnel.sh
    exit 1
fi

bash tunnel.sh
rm -f tunnel.sh
