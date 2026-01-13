#!/usr/bin/env bash
set -euo pipefail

echo "=== [10] Backup & Snapshot System ==="

# Timeshift + Btrfs integration
sudo pacman -S --noconfirm --needed \
    timeshift \
    timeshift-autosnap \
    btrfs-progs \
    snapper \
    grub-btrfs

# BorgBackup + Vorta
sudo pacman -S --noconfirm --needed \
    borgbackup \
    vorta

# Syncthing
sudo pacman -S --noconfirm --needed syncthing
sudo systemctl enable --now syncthing@"$USER"

# Restic (optional)
sudo pacman -S --noconfirm --needed restic

# Rclone
sudo pacman -S --noconfirm --needed rclone

echo "=== Backup System Setup Complete ==="