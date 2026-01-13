#!/usr/bin/env bash
set -euo pipefail

echo "=== [19] Electrical Engineering Tools ==="

sudo pacman -S --noconfirm --needed \
    kicad \
    ngspice \
    qucs-s \
    sigrok-cli \
    pulseview \
    arduino-cli \
    openocd \
    avrdude \
    dfu-util \
    arm-none-eabi-gcc \
    octave \
    gnuplot \
    python-usbtmc

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        ltspice \
        scpi-tools || echo "WARNING: Some EE AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install LTSpice/SCPI tools manually if desired"
fi

echo "=== Electrical Engineering Setup Complete ==="