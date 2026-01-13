#!/usr/bin/env bash
set -euo pipefail

echo "=== [22] Homelab & Server Tools ==="

sudo pacman -S --noconfirm --needed \
    cockpit \
    tailscale \
    syncthing \
    rclone \
    rsync \
    samba \
    nfs-utils

sudo systemctl enable --now cockpit.socket
sudo systemctl enable --now tailscaled
sudo systemctl enable --now syncthing@"$USER"

echo "=== Homelab Tools Setup Complete ==="