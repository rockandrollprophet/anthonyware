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

yay -S --noconfirm --needed qpwgraph

sudo systemctl --user enable --now wireplumber

echo "=== Audio Routing Setup Complete ==="