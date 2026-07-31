#!/bin/bash
# ══════════════════════════════════════════════════════════════
# build.sh — Build ordervpn-src.tar.gz for GitHub Release
# ══════════════════════════════════════════════════════════════
# Usage: bash build.sh [version]
#   version: optional, default reads from ORDERVPN_VERSION in vpn.sh
#
# Output:
#   ordervpn-src.tar.gz — ready to upload as GitHub Release asset
#   Also prints SHA256 to terminal for updating vpn.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/ordervpn-src"
OUTPUT="$SCRIPT_DIR/ordervpn-src.tar.gz"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "ERROR: ordervpn-src/ directory not found at $SRC_DIR"
    exit 1
fi

# ── Version ──
VERSION="${1:-}"
# Handle --force flag
if [[ "$VERSION" == "--force" ]]; then
    VERSION=""
fi
if [[ -z "$VERSION" ]]; then
    VERSION=$(grep -oP 'ORDERVPN_VERSION="\K[^"]+' "$SCRIPT_DIR/vpn.sh" 2>/dev/null || echo "unknown")
fi
echo "=== Build OrderVPN Web v$VERSION ==="

# ── Clean old output ──
rm -f "$OUTPUT"

# ── Verify critical files exist ──
REQUIRED_FILES=(
    "index.php"
    "dashboard.php"
    "login.php"
    "includes/config.php"
    "assets/css/style.css"
    "assets/js/app.js"
)

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$SRC_DIR/$f" ]]; then
        echo "  WARNING: $f NOT FOUND in ordervpn-src/"
        MISSING=$((MISSING+1))
    fi
done

if [[ $MISSING -gt 0 ]]; then
    echo "  WARNING: $MISSING file(s) missing."
    if [[ -t 0 ]]; then
        echo "  Lanjutkan? (y/N)"
        read -r ans
        [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 1
    else
        echo "  Non-interactive mode — lanjutkan..."
    fi
fi

# ── Build tar.gz ──
echo "  Membuat $OUTPUT ..."
# Do not ship runtime uploads/sample user data in the release asset.
tar -czf "$OUTPUT" -C "$SCRIPT_DIR" \
    --exclude='ordervpn-src/uploads/avatars/*' \
    --exclude='ordervpn-src/uploads/bukti/*' \
    ordervpn-src/
SIZE=$(du -h "$OUTPUT" | cut -f1)

# ── SHA256 ──
SHA256=$(sha256sum "$OUTPUT" | awk '{print $1}')
echo ""
echo "  ✔ Build selesai!"
echo "  File  : $OUTPUT"
echo "  Size  : $SIZE"
echo "  SHA256: $SHA256"
echo ""

# ── Update ORDERVPN_TAR_SHA256 in vpn.sh ──
VPN_SH="$SCRIPT_DIR/vpn.sh"
if [[ -f "$VPN_SH" ]]; then
    sed -i "s|ORDERVPN_TAR_SHA256=\"[^\"]*\"|ORDERVPN_TAR_SHA256=\"$SHA256\"|" "$VPN_SH"
    echo "  ✔ ORDERVPN_TAR_SHA256 updated in vpn.sh"
fi

echo ""
echo "  === UPLOAD KE GITHUB RELEASE ==="
echo "  1. Buka: https://github.com/putrinuroktavia234-max/Tunnel/releases"
echo "  2. Edit release v$VERSION (atau buat draft baru)"
echo "  3. Upload ordervpn-src.tar.gz sebagai asset"
echo "  4. Publish release"
echo ""
