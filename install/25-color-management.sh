#!/usr/bin/env bash
set -euo pipefail

echo "=== [25] Color Management ==="

sudo pacman -S --noconfirm --needed \
    colord \
    gnome-color-manager \
    argyllcms

# DisplayCAL (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed displaycal || echo "WARNING: displaycal failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install displaycal manually if desired"
fi

sudo systemctl enable --now colord.service

echo "=== Color Management Setup Complete ==="