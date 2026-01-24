#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [25] Color Management ==="

${SUDO} pacman -S --noconfirm --needed \
    colord \
    gnome-color-manager \
    argyllcms \
    imagemagick

# DisplayCAL (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed displaycal || echo "WARNING: displaycal failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install displaycal manually if desired"
fi

${SUDO} systemctl enable --now colord.service

echo "=== Color Management Setup Complete ==="