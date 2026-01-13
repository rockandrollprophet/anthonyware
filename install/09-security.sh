#!/usr/bin/env bash
set -euo pipefail

echo "=== [09] Security Stack ==="

# Firewalld
sudo pacman -S --noconfirm --needed firewalld
sudo systemctl enable --now firewalld

# AppArmor
sudo pacman -S --noconfirm --needed apparmor apparmor-parser
sudo systemctl enable --now apparmor

# Firejail
sudo pacman -S --noconfirm --needed firejail firetools

# Fail2ban
sudo pacman -S --noconfirm --needed fail2ban
sudo systemctl enable --now fail2ban

# USBGuard
sudo pacman -S --noconfirm --needed usbguard
sudo systemctl enable --now usbguard

# Encryption tools
sudo pacman -S --noconfirm --needed \
    keepassxc \
    veracrypt \
    gnupg \
    age

echo "=== Security Stack Setup Complete ==="