#!/usr/bin/env bash
set -euo pipefail

echo "=== System Backup (Borg) ==="

REPO="/mnt/backup/borg"

borg create --stats --progress \
    "$REPO::system-$(date +%Y-%m-%d)" \
    /etc /home /var

echo "=== System Backup Complete ==="
