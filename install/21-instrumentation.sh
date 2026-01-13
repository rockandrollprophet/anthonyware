#!/usr/bin/env bash
set -euo pipefail

echo "=== [21] Instrumentation & Lab Tools ==="

sudo pacman -S --noconfirm --needed \
    python-usbtmc \
    libsigrok \
    libsigrokdecode \
    sigrok-cli \
    pulseview

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        scpi-tools || echo "WARNING: scpi-tools failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install scpi-tools manually if desired"
fi

echo "=== Instrumentation Setup Complete ==="