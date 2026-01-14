#!/usr/bin/env bash
set -euo pipefail

echo "=== [04] Hyprland Desktop Setup ==="

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ "$TARGET_USER" = "root" ]; then
    echo "ERROR: Do not run this script as pure root."
    exit 1
fi

# Preflight checks
for cmd in pacman mkdir; do
    if ! command -v "$cmd" >/dev/null; then
        echo "ERROR: Required command '$cmd' missing."
        exit 1
    fi
done

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
    xdg-desktop-portal-hyprland \
    wlr-randr || { echo "ERROR: Failed to install Hyprland packages"; exit 1; }

# AUR packages (if yay exists)
if command -v yay >/dev/null; then
    echo "[04-hyprland] Installing AUR Wayland tools..."
    yay -S --noconfirm --needed \
        grimblast-git \
        eww-wayland \
        hyprpicker \
        wdisplays || echo "WARNING: Some AUR packages failed to install"
else
    echo "[04-hyprland] NOTICE: 'yay' not found. Install AUR packages manually if desired: grimblast-git eww-wayland hyprpicker wdisplays"
fi

# Create config directories using the target user's home
mkdir -p "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/waybar" "$TARGET_HOME/.config/kitty" "$TARGET_HOME/.config/mako" "$TARGET_HOME/.config/eww" "$TARGET_HOME/.config/hyprpaper"

# Placeholder configs (owned by target user)
printf '# Hyprland config
' | sudo tee "$TARGET_HOME/.config/hypr/hyprland.conf" >/dev/null
printf '# Waybar config
' | sudo tee "$TARGET_HOME/.config/waybar/config.jsonc" >/dev/null
printf '# Kitty config
' | sudo tee "$TARGET_HOME/.config/kitty/kitty.conf" >/dev/null
printf '# Mako config
' | sudo tee "$TARGET_HOME/.config/mako/config" >/dev/null
printf '# Eww config
' | sudo tee "$TARGET_HOME/.config/eww/eww.yuck" >/dev/null
printf '# Hyprpaper config
' | sudo tee "$TARGET_HOME/.config/hypr/hyprpaper.conf" >/dev/null

sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" || true

echo "=== Hyprland Desktop Setup Complete ==="
