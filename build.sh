#!/bin/bash
# ============================================================
# OrderVPN Web — Build & Release Helper
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_DIR="${SCRIPT_DIR}/ordervpn-src"
VPN_SH="${SCRIPT_DIR}/vpn.sh"
TARBALL="${SCRIPT_DIR}/ordervpn-src.tar.gz"
VERSION="${1:-3.12.0}"

echo "[build] Building ordervpn-src.tar.gz (version ${VERSION})..."

if [[ ! -d "$WEB_DIR" ]]; then
    echo "[build] ERROR: $WEB_DIR not found" >&2
    exit 1
fi

# Create tarball from parent directory with ordervpn-src/ as top-level folder
cd "$SCRIPT_DIR"
tar -czf "$TARBALL" "$(basename "$WEB_DIR")/"

# Calculate SHA256
HASH=$(sha256sum "$TARBALL" | awk '{print $1}')

echo "[build] Tarball: $TARBALL"
echo "[build] SHA256:  $HASH"

# Update hash in vpn.sh
if [[ -f "$VPN_SH" ]]; then
    if grep -q '^ORDERVPN_TAR_SHA256="PLACEHOLDER_SHA256"' "$VPN_SH"; then
        sed -i "s|^ORDERVPN_TAR_SHA256=\"PLACEHOLDER_SHA256\"|ORDERVPN_TAR_SHA256=\"${HASH}\"|" "$VPN_SH"
    else
        sed -i "s|^ORDERVPN_TAR_SHA256=\".*\"|ORDERVPN_TAR_SHA256=\"${HASH}\"|" "$VPN_SH"
    fi
    echo "[build] Updated ORDERVPN_TAR_SHA256 in $(basename "$VPN_SH")"
fi

echo "[build] Done."
