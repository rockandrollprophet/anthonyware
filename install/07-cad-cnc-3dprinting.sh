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
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed fusion360-bin || echo "WARNING: fusion360-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install fusion360-bin manually if desired"
fi

# CNC tools
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        candle \
        universal-gcode-sender-bin \
        bcnc \
        openbuilds-control-bin || echo "WARNING: Some CNC AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install CNC AUR packages manually"
fi

# Laser engraving
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed lasergrbl-bin || echo "WARNING: lasergrbl-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install lasergrbl-bin manually if desired"
fi

# 3D printing slicers
sudo pacman -S --noconfirm --needed \
    prusa-slicer || echo "WARNING: prusa-slicer install failed"

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        cura-bin \
        lychee-slicer-bin || echo "WARNING: Some slicer AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install cura-bin/lychee-slicer-bin manually if desired"
fi

# OctoPrint + Klipper ecosystem
sudo pacman -S --noconfirm --needed \
    octoprint || echo "WARNING: octoprint install failed"

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        mainsail \
        fluidd || echo "WARNING: mainsail/fluidd failed to install"
else
    echo "NOTICE: 'yay' not found; install mainsail/fluidd manually if desired"
fi

echo "=== CAD / CNC / 3D Printing Setup Complete ==="