#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [17] Steam & Gaming ==="

${SUDO} pacman -S --noconfirm --needed \
    steam \
    steam-native-runtime \
    lutris \
    gamemode \
    mangohud \
    goverlay

# Enable gamemode
${SUDO} systemctl enable --now gamemoded

echo "=== Steam & Gaming Setup Complete ==="