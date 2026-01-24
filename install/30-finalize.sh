#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [30] Finalization ==="

# Enable essential services
${SUDO} systemctl enable --now NetworkManager
${SUDO} systemctl enable --now bluetooth || true
${SUDO} systemctl enable --now cups || true
${SUDO} systemctl enable --now avahi-daemon || true
${SUDO} systemctl enable --now tlp || true
${SUDO} systemctl enable --now thermald || true
${SUDO} systemctl enable --now libvirtd || true

# Enable SDDM and set graphical target
echo "Enabling SDDM display manager..."
${SUDO} systemctl enable sddm
${SUDO} systemctl set-default graphical.target

# Copy Hyprland configs to user home and set up wallpaper directory
if [[ -n "${TARGET_USER:-}" ]] && [[ -n "${TARGET_HOME:-}" ]]; then
  echo "Ensuring Hyprland config is deployed..."
  
  # Find config source
  CONFIG_SRC=""
  REPO_SOURCE=""
  if [[ -d "${REPO_PATH:-}/configs/hypr" ]]; then
    CONFIG_SRC="${REPO_PATH}/configs"
    REPO_SOURCE="${REPO_PATH}"
  elif [[ -d "/root/anthonyware-setup/anthonyware/configs/hypr" ]]; then
    CONFIG_SRC="/root/anthonyware-setup/anthonyware/configs"
    REPO_SOURCE="/root/anthonyware-setup/anthonyware"
  fi
  
  if [[ -n "$CONFIG_SRC" ]]; then
    # Deploy Hyprland config files
    mkdir -p "${TARGET_HOME}/.config/hypr"
    cp -f "${CONFIG_SRC}/hypr"/* "${TARGET_HOME}/.config/hypr/" 2>/dev/null || true
    
    # Create wallpaper directory
    mkdir -p "${TARGET_HOME}/Pictures/Wallpapers"
    
    # Create a simple default wallpaper (solid black with gradient)
    # Using ImageMagick or a simple placeholder
    if command -v magick &>/dev/null; then
      magick -size 1920x1080 xc:black "${TARGET_HOME}/Pictures/Wallpapers/default.jpg" 2>/dev/null || true
    else
      # Fallback: create minimal valid JPEG placeholder
      echo "Note: Creating default wallpaper directory (add your wallpaper to ~/Pictures/Wallpapers/)"
      # Create empty placeholder that swww can display
      touch "${TARGET_HOME}/Pictures/Wallpapers/default.jpg"
    fi
    
    chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/hypr" "${TARGET_HOME}/Pictures/Wallpapers" 2>/dev/null || true
    echo "✓ Hyprland config and wallpaper directory deployed"
    
    # Copy repo to user home for easy access and git management
    if [[ -n "$REPO_SOURCE" && -d "$REPO_SOURCE/.git" ]]; then
      echo "Copying Anthonyware repository to user home..."
      USER_REPO="${TARGET_HOME}/anthonyware"
      if [[ ! -d "$USER_REPO" ]]; then
        cp -r "$REPO_SOURCE" "$USER_REPO" 2>/dev/null || true
      fi
      chown -R "${TARGET_USER}:${TARGET_USER}" "$USER_REPO" 2>/dev/null || true
      echo "✓ Repository copied to ~/anthonyware for easy access"
    fi
  fi
fi

# Update system
${SUDO} pacman -Syu --noconfirm

echo "=== Finalization Complete ==="