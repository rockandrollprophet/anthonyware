#!/usr/bin/env bash
set -euo pipefail

echo "=== [31] Wayland Screen Recording ==="

sudo pacman -S --noconfirm --needed \
    wf-recorder \
    obs-studio \
    obs-vkcapture

echo "=== Wayland Recording Setup Complete ==="