#!/usr/bin/env bash
set -euo pipefail

echo "=== [08] Hardware Support ==="

# 3Dconnexion
sudo pacman -S --noconfirm --needed \
    spacenavd \
    libspnav \
    x11-spnav \
    gtkwave

yay -S --noconfirm --needed spnavcfg

sudo systemctl enable --now spacenavd

# Logitech
sudo pacman -S --noconfirm --needed \
    solaar \
    piper \
    ratbagd \
    ltunify

sudo systemctl enable --now ratbagd

# Alienware / Dell
yay -S --noconfirm --needed \
    alienfx \
    awcc-linux \
    dell-bios-fan-control \
    nbfc-linux

# Sensors + thermal control
sudo pacman -S --noconfirm --needed \
    lm_sensors \
    psensor \
    thermald

sudo systemctl enable --now thermald
sudo sensors-detect --auto

echo "=== Hardware Support Setup Complete ==="