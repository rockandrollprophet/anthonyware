#!/usr/bin/env bash
set -euo pipefail

echo "=== [24] Cleanup & Verification ==="

# Clean orphan packages
sudo pacman -Rns --noconfirm $(pacman -Qtdq || true)

# Update system one last time
sudo pacman -Syu --noconfirm

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