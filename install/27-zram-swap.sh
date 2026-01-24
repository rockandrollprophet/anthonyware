#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [27] ZRAM Swap Setup ==="

${SUDO} pacman -S --noconfirm --needed zram-generator

${SUDO} tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

echo "=== ZRAM Setup Complete ==="