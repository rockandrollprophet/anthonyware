#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [33] System Cleaner ==="

# Remove orphan packages
orphans=$(pacman -Qtdq || true)
if [ -n "$orphans" ]; then
    ${SUDO} pacman -Rns --noconfirm $orphans
fi

# Clean package cache
${SUDO} pacman -Scc --noconfirm

echo "=== System Cleanup Complete ==="