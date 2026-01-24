#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [10] Backup & Snapshot System ==="

# Timeshift + Btrfs integration
${SUDO} pacman -S --noconfirm --needed \
    timeshift \
    timeshift-autosnap \
    btrfs-progs \
    snapper \
    grub-btrfs

# BorgBackup + Vorta
${SUDO} pacman -S --noconfirm --needed \
    borgbackup \
    vorta

# Syncthing
${SUDO} pacman -S --noconfirm --needed syncthing
${SUDO} systemctl enable --now syncthing@"$USER"

# Restic (optional)
${SUDO} pacman -S --noconfirm --needed restic

# Rclone
${SUDO} pacman -S --noconfirm --needed rclone

echo "=== Backup System Setup Complete ==="