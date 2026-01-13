#!/usr/bin/env bash
set -euo pipefail

echo "=== [08] Hardware Support ==="

# 3Dconnexion
sudo pacman -S --noconfirm --needed \
    spacenavd \
    libspnav \
    x11-spnav \
    gtkwave

if command -v yay >/dev/null; then
    yay -S --noconfirm --needed spnavcfg || echo "WARNING: spnavcfg failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install spnavcfg manually if desired"
fi

sudo systemctl enable --now spacenavd

# Logitech
sudo pacman -S --noconfirm --needed \
    solaar \
    piper \
    ratbagd \
    ltunify

sudo systemctl enable --now ratbagd

# Alienware / Dell
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed \
        alienfx \
        awcc-linux \
        dell-bios-fan-control \
        nbfc-linux || echo "WARNING: Some Dell/Alienware AUR packages failed to install"
else
    echo "NOTICE: 'yay' not found; install Alienware/Dell packages manually if desired"
fi

# Sensors + thermal control
sudo pacman -S --noconfirm --needed \
    lm_sensors \
    psensor \
    thermald

sudo systemctl enable --now thermald
sudo sensors-detect --auto

echo "=== Hardware Support Setup Complete ==="