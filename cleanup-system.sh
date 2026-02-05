#!/usr/bin/env bash
# Safe package removal script - removes bloat while keeping system functional
set -euo pipefail

REMOVABLE_LIST="/tmp/removable.txt"

if [[ ! -f "$REMOVABLE_LIST" ]]; then
    echo "ERROR: Run generate-removal-list.sh first!"
    exit 1
fi

echo "================================================"
echo "  Safe Package Removal - Minimal System Setup"
echo "================================================"
echo
echo "This will remove $(wc -l < "$REMOVABLE_LIST") packages."
echo
echo "KEEPS: VS Code, Firefox, Neovim, Neovide, Rofi, Hyprland stack"
echo
read -p "Review /tmp/removable.txt first. Continue? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Backup current package list
BACKUP_DIR=~/anthonyware/backups
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pacman -Qqe > "$BACKUP_DIR/packages-before-cleanup-$TIMESTAMP.txt"
echo "✓ Backup saved: $BACKUP_DIR/packages-before-cleanup-$TIMESTAMP.txt"
echo

# Remove packages
echo "Removing packages..."
echo

# Read into array and remove
mapfile -t PACKAGES < "$REMOVABLE_LIST"

if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    sudo pacman -Rns --noconfirm "${PACKAGES[@]}" 2>&1 | tee "$BACKUP_DIR/removal-log-$TIMESTAMP.txt"
    echo
    echo "✓ Removal complete"
else
    echo "No packages to remove"
fi

echo
echo "=== Cleanup Summary ==="
echo "Removed: ${#PACKAGES[@]} packages"
echo "Backup: $BACKUP_DIR/packages-before-cleanup-$TIMESTAMP.txt"
echo "Log: $BACKUP_DIR/removal-log-$TIMESTAMP.txt"
echo
echo "Remaining explicit packages: $(pacman -Qqe | wc -l)"
echo
echo "Run 'sudo pacman -Sc' to clean package cache if needed."
