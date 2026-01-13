#!/usr/bin/env bash
set -euo pipefail

echo "=== [07] CAD / CNC / 3D Printing Stack ==="

# Core CAD tools
sudo pacman -S --noconfirm --needed \
    blender \
    kicad \
    freecad \
    openscad

# Fusion 360 (AUR)
yay -S --noconfirm --needed fusion360-bin

# CNC tools
yay -S --noconfirm --needed \
    candle \
    universal-gcode-sender-bin \
    bcnc \
    openbuilds-control-bin

# Laser engraving
yay -S --noconfirm --needed lasergrbl-bin

# 3D printing slicers
sudo pacman -S --noconfirm --needed \
    prusa-slicer

yay -S --noconfirm --needed \
    cura-bin \
    lychee-slicer-bin

# OctoPrint + Klipper ecosystem
sudo pacman -S --noconfirm --needed \
    octoprint

yay -S --noconfirm --needed \
    mainsail \
    fluidd

echo "=== CAD / CNC / 3D Printing Setup Complete ==="