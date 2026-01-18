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

# Update system
${SUDO} pacman -Syu --noconfirm

echo "=== Finalization Complete ==="