#!/usr/bin/env bash
set -euo pipefail

# Legacy wrapper: the Hyprland installer moved to 04-hyprland.sh
# This wrapper forwards to the new script to preserve numbering compatibility.

SCRIPT_DIR="$(dirname "$0")"
if [ -x "$SCRIPT_DIR/04-hyprland.sh" ]; then
    echo "[03] Forwarding to 04-hyprland.sh"
    bash "$SCRIPT_DIR/04-hyprland.sh"
    exit $?
else
    echo "ERROR: 04-hyprland.sh not found or not executable; run 04-hyprland.sh directly." >&2
    exit 1
fi
    qt6-wayland \
    xdg-desktop-portal-hyprland || { echo "ERROR: Failed to install Hyprland packages"; exit 1; }

# AUR packages (if yay exists)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        grimblast-git \
        eww-wayland \
        hyprpicker || echo "WARNING: Some AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found. Install AUR packages manually if desired: grimblast-git eww-wayland hyprpicker"
fi

# Create config directories using the target user's home
mkdir -p "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/waybar" "$TARGET_HOME/.config/kitty" "$TARGET_HOME/.config/mako" "$TARGET_HOME/.config/eww" "$TARGET_HOME/.config/hyprpaper"

# Placeholder configs (owned by target user)
printf '# Hyprland config\n' | sudo tee "$TARGET_HOME/.config/hypr/hyprland.conf" >/dev/null
printf '# Waybar config\n' | sudo tee "$TARGET_HOME/.config/waybar/config.jsonc" >/dev/null
printf '# Kitty config\n' | sudo tee "$TARGET_HOME/.config/kitty/kitty.conf" >/dev/null
printf '# Mako config\n' | sudo tee "$TARGET_HOME/.config/mako/config" >/dev/null
printf '# Eww config\n' | sudo tee "$TARGET_HOME/.config/eww/eww.yuck" >/dev/null
printf '# Hyprpaper config\n' | sudo tee "$TARGET_HOME/.config/hypr/hyprpaper.conf" >/dev/null

sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" || true

echo "=== Hyprland Desktop Setup Complete ==="