#!/usr/bin/env bash
set -euo pipefail

echo "=== [04] Daily Driver Applications ==="

sudo pacman -S --noconfirm --needed \
    dolphin \
    dolphin-plugins \
    kio-extras \
    ark \
    vlc \
    gimp \
    obs-studio \
    pavucontrol \
    blueman \
    kdeconnect \
    solaar \
    filelight \
    neofetch \
    htop \
    btop \
    mission-center \
    cups \
    cups-pdf \
    system-config-printer \
    avahi \
    nss-mdns \
    fwupd \
    qbittorrent \
    libreoffice-fresh \
    noto-fonts \
    noto-fonts-emoji \
    ttf-jetbrains-mono \
    ttf-fira-code \
    ttf-nerd-fonts-symbols \
    imv \
    qalculate-gtk \
    brightnessctl \
    font-manager \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    ffmpeg \
    zathura \
    zathura-pdf-mupdf \
    network-manager-applet \
    bluez \
    bluez-utils \
    pulseaudio-bluetooth \
    xdg-utils \
    xdg-user-dirs

# Enable printing services
sudo systemctl enable --now cups.service
sudo systemctl enable --now avahi-daemon.service

# Enable bluetooth
sudo systemctl enable --now bluetooth.service

# Flatpak + Discover
sudo pacman -S --noconfirm --needed flatpak discover
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Zen Browser (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed zen-browser-bin || echo "WARNING: zen-browser-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install zen-browser-bin manually if desired"
fi

echo "=== Daily Driver Setup Complete ==="