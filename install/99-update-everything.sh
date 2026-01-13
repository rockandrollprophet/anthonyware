#!/usr/bin/env bash
set -euo pipefail

echo "=== [99] Update Everything ==="

# System update
sudo pacman -Syu --noconfirm

# AUR update
if command -v yay >/dev/null; then
    yay -Syu --noconfirm || echo "WARNING: 'yay' update failed"
else
    echo "NOTICE: 'yay' not found; skipping AUR update"
fi

# Flatpak update
flatpak update -y || true

# Firmware update
sudo fwupdmgr refresh || true
sudo fwupdmgr update || true

echo "=== Full System Update Complete ==="