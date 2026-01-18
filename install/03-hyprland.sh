#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [03] Hyprland Desktop Setup ==="

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
${SUDO} pacman -S --noconfirm --needed \
    hyprland \
    sddm \
    sddm-kcm \
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
    xdg-desktop-portal-gtk \
    wlr-randr \
    swaync || { echo "ERROR: Failed to install Hyprland packages"; exit 1; }

# Start polkit agent for authentication dialogs
mkdir -p "$TARGET_HOME/.config/autostart"
cat > "$TARGET_HOME/.config/autostart/polkit-kde-agent.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=PolicyKit Authentication Agent
Exec=/usr/lib/polkit-kde-authentication-agent-1
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

# AUR packages (if yay exists)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        grimblast-git \
        eww-wayland \
        hyprpicker \
        wdisplays || echo "WARNING: Some AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found. Install AUR packages manually if desired: grimblast-git eww-wayland hyprpicker wdisplays"
fi

# Create config directories using the target user's home
mkdir -p "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/waybar" "$TARGET_HOME/.config/kitty" "$TARGET_HOME/.config/mako" "$TARGET_HOME/.config/eww" "$TARGET_HOME/.config/hyprpaper"

# Placeholder configs (owned by target user)
printf '# Hyprland config\n' | ${SUDO} tee "$TARGET_HOME/.config/hypr/hyprland.conf" >/dev/null
printf '# Waybar config\n' | ${SUDO} tee "$TARGET_HOME/.config/waybar/config.jsonc" >/dev/null
printf '# Kitty config\n' | ${SUDO} tee "$TARGET_HOME/.config/kitty/kitty.conf" >/dev/null
printf '# Mako config\n' | ${SUDO} tee "$TARGET_HOME/.config/mako/config" >/dev/null
printf '# Eww config\n' | ${SUDO} tee "$TARGET_HOME/.config/eww/eww.yuck" >/dev/null
printf '# Hyprpaper config\n' | ${SUDO} tee "$TARGET_HOME/.config/hypr/hyprpaper.conf" >/dev/null

${SUDO} chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" || true

echo "=== Hyprland Desktop Setup Complete ==="