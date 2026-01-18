#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [99] Update Everything ==="

# System update
${SUDO} pacman -Syu --noconfirm

# AUR update
if command -v yay >/dev/null; then
    yay -Syu --noconfirm || echo "WARNING: 'yay' update failed"
else
    echo "NOTICE: 'yay' not found; skipping AUR update"
fi

# Flatpak update
flatpak update -y || true

# Firmware update
${SUDO} fwupdmgr refresh || true
${SUDO} fwupdmgr update || true

echo "=== Full System Update Complete ==="