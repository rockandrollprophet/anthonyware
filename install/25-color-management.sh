#!/usr/bin/env bash
set -euo pipefail

echo "=== [25] Color Management ==="

sudo pacman -S --noconfirm --needed \
    colord \
    gnome-color-manager \
    argyllcms

# DisplayCAL (AUR)
yay -S --noconfirm --needed displaycal

sudo systemctl enable --now colord.service

echo "=== Color Management Setup Complete ==="