#!/usr/bin/env bash
set -euo pipefail

echo "=== [30] Finalization ==="

# Enable essential services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth || true
sudo systemctl enable --now cups || true
sudo systemctl enable --now avahi-daemon || true
sudo systemctl enable --now tlp || true
sudo systemctl enable --now thermald || true
sudo systemctl enable --now libvirtd || true

# Update system
sudo pacman -Syu --noconfirm

echo "=== Finalization Complete ==="