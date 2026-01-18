#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [22] Homelab & Server Tools ==="

${SUDO} pacman -S --noconfirm --needed \
    cockpit \
    tailscale \
    syncthing \
    rclone \
    rsync \
    samba \
    nfs-utils

${SUDO} systemctl enable --now cockpit.socket
${SUDO} systemctl enable --now tailscaled
${SUDO} systemctl enable --now syncthing@"$USER"

echo "=== Homelab Tools Setup Complete ==="