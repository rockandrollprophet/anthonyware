#!/usr/bin/env bash
set -euo pipefail

echo "=== [28] Audio Routing Tools ==="

sudo pacman -S --noconfirm --needed \
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

sudo systemctl --user enable --now wireplumber

echo "=== Audio Routing Setup Complete ==="