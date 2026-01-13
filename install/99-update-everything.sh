#!/usr/bin/env bash
set -euo pipefail

echo "=== [99] Update Everything ==="

# System update
sudo pacman -Syu --noconfirm

# AUR update
yay -Syu --noconfirm

# Flatpak update
flatpak update -y || true

# Firmware update
sudo fwupdmgr refresh || true
sudo fwupdmgr update || true

echo "=== Full System Update Complete ==="