#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$HOME/backups/home-$(date +%Y-%m-%d)"

echo "=== Backing up home directory to $BACKUP_DIR ==="

mkdir -p "$BACKUP_DIR"

rsync -avh --exclude=".cache" "$HOME/" "$BACKUP_DIR/"

echo "=== Home Backup Complete ==="
