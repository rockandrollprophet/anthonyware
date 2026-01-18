#!/usr/bin/env bash
set -euo pipefail

echo "=== Anthonyware Maintenance ==="

sudo pacman -Rns --noconfirm $(pacman -Qtdq || true)
sudo pacman -Scc --noconfirm
sudo journalctl --vacuum-time=7d

echo "=== Maintenance Complete ==="
