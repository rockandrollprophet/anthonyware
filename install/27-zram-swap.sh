#!/usr/bin/env bash
set -euo pipefail

echo "=== [27] ZRAM Swap Setup ==="

sudo pacman -S --noconfirm --needed zram-generator

sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

echo "=== ZRAM Setup Complete ==="