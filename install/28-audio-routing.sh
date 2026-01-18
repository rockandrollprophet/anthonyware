#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [28] Audio Routing Tools ==="

${SUDO} pacman -S --noconfirm --needed \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    helvum

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed qpwgraph || echo "WARNING: qpwgraph failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install qpwgraph manually if desired"
fi

${SUDO} systemctl --user enable --now wireplumber

echo "=== Audio Routing Setup Complete ==="