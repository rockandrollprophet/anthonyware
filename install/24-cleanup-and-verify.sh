#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [24] Cleanup & Verification ==="

# Clean orphan packages
${SUDO} pacman -Rns --noconfirm $(pacman -Qtdq || true)

# Update system one last time
${SUDO} pacman -Syu --noconfirm

# Verify GPU
echo "GPU Info:"
lspci | grep -E "VGA|3D"

# Verify virtualization
echo "Virtualization Extensions:"
grep -E --color=never '(vmx|svm)' /proc/cpuinfo | head

# Verify Wayland
echo "Wayland session check:"
echo $XDG_SESSION_TYPE

echo "=== Cleanup & Verification Complete ==="