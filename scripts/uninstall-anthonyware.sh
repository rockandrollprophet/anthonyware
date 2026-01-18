#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  uninstall-anthonyware.sh
#  Safe uninstallation of Anthonyware components
# ============================================================

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must be run as root: sudo bash uninstall-anthonyware.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-${USER}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "ERROR: Cannot determine target user. Run with sudo."
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Anthonyware OS Uninstallation                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "⚠️  WARNING: This will remove Anthonyware components"
echo
echo "What will be removed:"
echo "  - Desktop environment (Hyprland, Waybar, etc.)"
echo "  - Configuration files"
echo "  - Optional: Additional packages"
echo
echo "What will be kept:"
echo "  - User data in home directory"
echo "  - Base system packages"
echo "  - Backups (if any)"
echo
read -rp "Continue with uninstallation? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Uninstallation cancelled"
  exit 0
fi

# Create final backup
echo
echo "Creating final backup..."
BACKUP_DIR="${TARGET_HOME}/.anthonyware-backups/uninstall-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "${TARGET_HOME}/.config" "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"

# Stop services
echo
echo "Stopping services..."
systemctl stop sddm 2>/dev/null || true
systemctl --user stop syncthing@${TARGET_USER} 2>/dev/null || true
echo "✓ Services stopped"

# Disable services
echo "Disabling services..."
systemctl disable sddm 2>/dev/null || true
systemctl set-default multi-user.target 2>/dev/null || true
echo "✓ Services disabled"

# Ask about package removal
echo
read -rp "Remove installed packages? (This may take a while) [y/N] " remove_pkgs
if [[ "$remove_pkgs" =~ ^[Yy]$ ]]; then
  echo "Removing packages..."
  
  # Desktop environment
  pacman -R --noconfirm hyprland waybar wofi kitty mako sddm 2>/dev/null || true
  
  # Optional: Remove more packages
  read -rp "Remove development tools? [y/N] " remove_dev
  if [[ "$remove_dev" =~ ^[Yy]$ ]]; then
    pacman -R --noconfirm docker podman vscode 2>/dev/null || true
  fi
  
  read -rp "Remove CAD/CNC tools? [y/N] " remove_cad
  if [[ "$remove_cad" =~ ^[Yy]$ ]]; then
    pacman -R --noconfirm freecad kicad openscad 2>/dev/null || true
  fi
  
  echo "✓ Packages removed"
fi

# Remove configuration files
echo
read -rp "Remove configuration files? [Y/n] " remove_configs
if [[ ! "$remove_configs" =~ ^[Nn]$ ]]; then
  echo "Removing configurations..."
  
  rm -rf "${TARGET_HOME}/.config/hypr" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/waybar" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/kitty" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/mako" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/wofi" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/eww" 2>/dev/null || true
  rm -rf "${TARGET_HOME}/.config/swaync" 2>/dev/null || true
  rm -f "${TARGET_HOME}/.anthonyware-installed" 2>/dev/null || true
  
  # System configs
  rm -rf /etc/sddm.conf.d/10-qt6-env.conf 2>/dev/null || true
  
  echo "✓ Configurations removed"
fi

# Remove repository
echo
read -rp "Remove anthonyware repository? [y/N] " remove_repo
if [[ "$remove_repo" =~ ^[Yy]$ ]]; then
  rm -rf "${TARGET_HOME}/anthonyware" 2>/dev/null || true
  rm -rf "/root/anthonyware-setup" 2>/dev/null || true
  echo "✓ Repository removed"
fi

# Remove logs
echo
read -rp "Remove installation logs? [y/N] " remove_logs
if [[ "$remove_logs" =~ ^[Yy]$ ]]; then
  rm -rf "${TARGET_HOME}/anthonyware-logs" 2>/dev/null || true
  rm -rf /var/log/anthonyware-install 2>/dev/null || true
  echo "✓ Logs removed"
fi

echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Uninstallation Complete                                   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "Backup saved to: $BACKUP_DIR"
echo
echo "Your system will boot to a text console."
echo "To restore:"
echo "  1. Copy configs from backup: cp -r $BACKUP_DIR/.config ~/"
echo "  2. Reinstall Anthonyware or install another desktop"
echo
read -rp "Reboot now? [y/N] " reboot
if [[ "$reboot" =~ ^[Yy]$ ]]; then
  reboot
fi
