#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [32] XWayland Legacy Support ==="

${SUDO} pacman -S --noconfirm --needed \
    xorg-xwayland \
    xclip \
    xdotool \
    xorg-xlsclients

echo "=== XWayland Legacy Support Installed ==="