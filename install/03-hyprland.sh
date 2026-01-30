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
  rofi \
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
  polkit-kde-agent \
  qt5-wayland \
  qt6-wayland \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  wlr-randr \
  swaync || { echo "ERROR: Failed to install Hyprland packages"; exit 1; }

# Note: 'wlogout' is not available in the official repos as of 2026. Install from AUR if needed.

# Start polkit agent for authentication dialogs
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${TARGET_HOME}/.config}"
XDG_AUTOSTART="${XDG_CONFIG_HOME}/autostart"

if command -v safe_mkdir >/dev/null 2>&1; then
  safe_mkdir "$XDG_AUTOSTART" "$TARGET_USER"
else
  mkdir -p "$XDG_AUTOSTART"
  ${SUDO} chown "$TARGET_USER:$TARGET_USER" "$XDG_AUTOSTART" 2>/dev/null || true
fi

cat > "${XDG_AUTOSTART}/polkit-kde-agent.desktop" <<'EOF'
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
    wdisplays \
    wlogout || echo "WARNING: Some AUR packages failed to install"
else
  echo "NOTICE: 'yay' not found. Install AUR packages manually if desired: grimblast-git eww-wayland hyprpicker wdisplays wlogout"
fi

# Create config directories using XDG_CONFIG_HOME
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${TARGET_HOME}/.config}"

CONFIG_DIRS=("hypr" "waybar" "kitty" "mako" "eww" "hyprpaper")
for dir in "${CONFIG_DIRS[@]}"; do
  if command -v safe_mkdir >/dev/null 2>&1; then
    safe_mkdir "${XDG_CONFIG_HOME}/${dir}" "$TARGET_USER"
  else
    mkdir -p "${XDG_CONFIG_HOME}/${dir}"
    ${SUDO} chown "$TARGET_USER:$TARGET_USER" "${XDG_CONFIG_HOME}/${dir}" 2>/dev/null || true
  fi
done

# Copy actual configs from repo (if available)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${REPO_ROOT}/configs/hypr/hyprland.conf" ]]; then
  cp -v "${REPO_ROOT}/configs/hypr/hyprland.conf" "${XDG_CONFIG_HOME}/hypr/" || echo "WARNING: Failed to copy hyprland.conf"
else
  printf '# Hyprland config\n' | ${SUDO} tee "${XDG_CONFIG_HOME}/hypr/hyprland.conf" >/dev/null
fi

if [[ -f "${REPO_ROOT}/configs/waybar/config.jsonc" ]]; then
  cp -v "${REPO_ROOT}/configs/waybar/config.jsonc" "${XDG_CONFIG_HOME}/waybar/" || echo "WARNING: Failed to copy waybar config"
  if [[ -d "${REPO_ROOT}/configs/waybar/modules" ]]; then
    cp -rv "${REPO_ROOT}/configs/waybar/modules" "${XDG_CONFIG_HOME}/waybar/" || echo "WARNING: Failed to copy waybar modules"
  fi
  if [[ -f "${REPO_ROOT}/configs/waybar/style.css" ]]; then
    cp -v "${REPO_ROOT}/configs/waybar/style.css" "${XDG_CONFIG_HOME}/waybar/" || echo "WARNING: Failed to copy waybar styles"
  fi
else
  printf '# Waybar config\n' | ${SUDO} tee "${XDG_CONFIG_HOME}/waybar/config.jsonc" >/dev/null
fi

if [[ -f "${REPO_ROOT}/configs/kitty/kitty.conf" ]]; then
  cp -v "${REPO_ROOT}/configs/kitty/kitty.conf" "${XDG_CONFIG_HOME}/kitty/" || echo "WARNING: Failed to copy kitty config"
else
  printf '# Kitty config\n' | ${SUDO} tee "${XDG_CONFIG_HOME}/kitty/kitty.conf" >/dev/null
fi

if [[ -f "${REPO_ROOT}/configs/mako/config" ]]; then
  cp -v "${REPO_ROOT}/configs/mako/config" "${XDG_CONFIG_HOME}/mako/" || echo "WARNING: Failed to copy mako config"
else
  printf '# Mako config\n' | ${SUDO} tee "${XDG_CONFIG_HOME}/mako/config" >/dev/null
fi

${SUDO} chown -R "$TARGET_USER:$TARGET_USER" "${XDG_CONFIG_HOME}" || true

echo "✓ Hyprland Desktop Setup Complete"