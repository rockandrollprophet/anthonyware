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

yay -S --noconfirm --needed \
    ltspice \
    scpi-tools

echo "=== Electrical Engineering Setup Complete ==="