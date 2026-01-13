#!/usr/bin/env bash
set -euo pipefail

echo "=== [14] XDG Portals Setup ==="

sudo pacman -S --noconfirm --needed \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    qt5-wayland \
    qt6-wayland

# Kill any running portal services so they respawn cleanly under Hyprland
killall xdg-desktop-portal xdg-desktop-portal-hyprland 2>/dev/null || true

echo "=== XDG Portals Setup Complete ==="
echo "Portals will start automatically in your Hyprland session."