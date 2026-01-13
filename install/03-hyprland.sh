#!/usr/bin/env bash
set -euo pipefail

echo "=== [03] Hyprland Desktop Setup ==="

# Core Hyprland packages
sudo pacman -S --noconfirm --needed \
    hyprland \
    waybar \
    wofi \
    kitty \
    mako \
    hyprpaper \
    hyprlock \
    hypridle \
    swww \
    grim \
    slurp \
    swappy \
    wl-clipboard \
    cliphist \
    wlogout \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland

# AUR packages
yay -S --noconfirm --needed \
    grimblast-git \
    eww-wayland \
    hyprpicker

# Create config directories
mkdir -p ~/.config/{hypr,waybar,kitty,mako,eww,hyprpaper}

# Placeholder configs
echo "# Hyprland config" > ~/.config/hypr/hyprland.conf
echo "# Waybar config" > ~/.config/waybar/config.jsonc
echo "# Kitty config" > ~/.config/kitty/kitty.conf
echo "# Mako config" > ~/.config/mako/config
echo "# Eww config" > ~/.config/eww/eww.yuck
echo "# Hyprpaper config" > ~/.config/hypr/hyprpaper.conf

echo "=== Hyprland Desktop Setup Complete ==="