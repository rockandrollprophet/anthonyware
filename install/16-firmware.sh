#!/usr/bin/env bash
set -euo pipefail

echo "=== [16] Firmware & Microcode ==="

sudo pacman -S --noconfirm --needed \
    fwupd \
    linux-firmware \
    amd-ucode \
    intel-ucode

sudo systemctl enable --now fwupd.service

echo "=== Firmware Setup Complete ==="