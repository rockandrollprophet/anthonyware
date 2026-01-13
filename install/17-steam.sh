#!/usr/bin/env bash
set -euo pipefail

echo "=== [17] Steam & Gaming ==="

sudo pacman -S --noconfirm --needed \
    steam \
    steam-native-runtime \
    lutris \
    gamemode \
    mangohud \
    goverlay

# Enable gamemode
sudo systemctl enable --now gamemoded

echo "=== Steam & Gaming Setup Complete ==="