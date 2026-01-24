#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [04] Daily Driver Applications ==="

${SUDO} pacman -S --noconfirm --needed \
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
    xdg-user-dirs \
    imagemagick \
    rawtherapee \
    krita

# Image processing CLI tools
${SUDO} pacman -S --noconfirm --needed \
    optipng \
    jpegoptim \
    webp \
    libwebp

# Rendering and visualization (already in Blender from CAD, but adding CLI support)
${SUDO} pacman -S --noconfirm --needed \
    python-pillow \
    python-imageio

# Enable printing services
if command -v safe_enable_service >/dev/null 2>&1; then
  safe_enable_service cups "CUPS printing service"
  safe_enable_service avahi-daemon "Avahi mDNS/DNS-SD"
else
  if systemctl list-unit-files | grep -q "^cups.service"; then
    ${SUDO} systemctl enable --now cups.service || echo "⚠ Failed to enable CUPS"
  fi
  if systemctl list-unit-files | grep -q "^avahi-daemon.service"; then
    ${SUDO} systemctl enable --now avahi-daemon.service || echo "⚠ Failed to enable Avahi"
  fi
fi

echo "✓ Daily driver applications installed"
${SUDO} systemctl enable --now avahi-daemon.service

# Enable bluetooth
${SUDO} systemctl enable --now bluetooth.service

# Flatpak + Discover
${SUDO} pacman -S --noconfirm --needed flatpak discover
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Optional WiFi connect step (interactive)
read -rp "Connect to WiFi now with nmtui? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v nmtui >/dev/null; then
        nmtui
    else
        echo "nmtui not found. Use: nmcli device wifi connect <SSID> password <PASSWORD>"
    fi
fi

# Zen Browser (AUR)
if command -v yay >/dev/null; then
    yay -S --noconfirm --needed zen-browser-bin || echo "WARNING: zen-browser-bin failed to install via yay"
else
    echo "NOTICE: 'yay' not found; install zen-browser-bin manually if desired"
fi

echo "=== Daily Driver Setup Complete ==="
echo "Graphics tools installed:"
echo "  - GIMP: General image editing"
echo "  - Krita: Digital painting"
echo "  - RawTherapee: RAW photo processing"
echo "  - ImageMagick: CLI image manipulation"
echo "  - Blender: 3D rendering, modeling, animation (via CAD script)"