#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Install yay (AUR Helper)
# Must be run as regular user (NOT root/sudo)
################################################################################

echo "=== Installing yay AUR Helper ==="

# Check we're NOT running as root
if [[ "${EUID}" -eq 0 ]]; then
    echo "ERROR: Do NOT run this script as root/sudo"
    echo "Run as regular user: bash install/00-install-yay.sh"
    exit 1
fi

# Check if yay already installed
if command -v yay &>/dev/null; then
    echo "✓ yay already installed"
    yay --version
    exit 0
fi

# Install dependencies (as root)
echo "Installing build dependencies..."
sudo pacman -S --noconfirm --needed base-devel git

# Clone yay repo
YAY_DIR="/tmp/yay-install"
rm -rf "${YAY_DIR}"
git clone https://aur.archlinux.org/yay-bin.git "${YAY_DIR}"
cd "${YAY_DIR}"

# Build and install
echo "Building yay..."
makepkg -si --noconfirm

# Cleanup
cd ~
rm -rf "${YAY_DIR}"

echo "✓ yay installed successfully"
yay --version
