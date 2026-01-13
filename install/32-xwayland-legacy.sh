#!/usr/bin/env bash
set -euo pipefail

echo "=== [32] XWayland Legacy Support ==="

sudo pacman -S --noconfirm --needed \
    xorg-xwayland \
    xclip \
    xdotool \
    xorg-xlsclients

echo "=== XWayland Legacy Support Installed ==="