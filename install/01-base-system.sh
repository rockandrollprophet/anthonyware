#!/usr/bin/env bash
set -euo pipefail

echo "=== [01] Base System Setup ==="

# Update system
sudo pacman -Syu --noconfirm

# Enable parallel downloads + color
sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

# Install core packages
sudo pacman -S --noconfirm --needed \
    base-devel \
    git \
    curl \
    wget \
    unzip \
    zip \
    tar \
    reflector \
    linux-headers \
    linux-firmware \
    amd-ucode \
    intel-ucode \
    networkmanager \
    network-manager-applet \
    plasma-nm \
    xdg-user-dirs \
    xdg-utils \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk

# Enable NetworkManager
sudo systemctl enable --now NetworkManager

# Generate user directories
xdg-user-dirs-update

# Install yay (AUR helper)
if ! command -v yay >/dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
fi

# Optimize mirrors
sudo reflector --country "United States" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "=== Base System Setup Complete ==="