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
    ttf-nerd-fonts-symbols

# Enable printing services
sudo systemctl enable --now cups.service
sudo systemctl enable --now avahi-daemon.service

# Flatpak + Discover
sudo pacman -S --noconfirm --needed flatpak discover
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "=== Daily Driver Setup Complete ==="