#!/usr/bin/env bash
set -euo pipefail

echo "=== [21] Instrumentation & Lab Tools ==="

sudo pacman -S --noconfirm --needed \
    python-usbtmc \
    libsigrok \
    libsigrokdecode \
    sigrok-cli \
    pulseview

yay -S --noconfirm --needed \
    scpi-tools

echo "=== Instrumentation Setup Complete ==="