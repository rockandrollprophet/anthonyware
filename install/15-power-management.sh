#!/usr/bin/env bash
set -euo pipefail

echo "=== [15] Power Management ==="

sudo pacman -S --noconfirm --needed \
    tlp \
    tlp-rdw \
    powertop \
    auto-cpufreq \
    thermald

sudo systemctl enable --now tlp
sudo systemctl enable --now thermald

echo "=== Power Management Setup Complete ==="