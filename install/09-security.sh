#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [09] Security Stack ==="

# Firewalld
${SUDO} pacman -S --noconfirm --needed firewalld
${SUDO} systemctl enable --now firewalld

# AppArmor
${SUDO} pacman -S --noconfirm --needed apparmor apparmor-parser
${SUDO} systemctl enable --now apparmor

# Firejail
${SUDO} pacman -S --noconfirm --needed firejail firetools

# Fail2ban
${SUDO} pacman -S --noconfirm --needed fail2ban
${SUDO} systemctl enable --now fail2ban

# USBGuard
${SUDO} pacman -S --noconfirm --needed usbguard
${SUDO} systemctl enable --now usbguard

# Encryption tools
${SUDO} pacman -S --noconfirm --needed \
    keepassxc \
    veracrypt \
    gnupg \
    age

echo "=== Security Stack Setup Complete ==="