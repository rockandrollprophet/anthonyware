#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== Preflight Checks ==="

# Check internet
echo -n "Checking internet connectivity... "
ping -c 1 archlinux.org >/dev/null 2>&1 && echo "OK" || {
    echo "FAILED"
    echo "No internet connection detected."
    exit 1
}

# Check pacman lock
echo -n "Checking pacman lock... "
if [ -f /var/lib/pacman/db.lck ]; then
    echo "LOCKED"
    echo "Pacman is locked. Resolve before continuing."
    exit 1
else
    echo "OK"
fi

# Check virtualization support
echo -n "Checking virtualization support... "
if grep -E --color=never -c '(vmx|svm)' /proc/cpuinfo >/dev/null; then
    echo "OK"
else
    echo "FAILED"
    echo "Your CPU does not support virtualization extensions."
    exit 1
fi

# Check for NVIDIA GPU (for passthrough)
echo -n "Detecting NVIDIA GPU... "
if lspci | grep -i nvidia >/dev/null; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# Check for AMD iGPU (for host)
echo -n "Detecting AMD GPU... "
if lspci | grep -i amd | grep -i vga >/dev/null; then
    echo "FOUND"
else
    echo "NOT FOUND"
fi

# Check kernel version
echo -n "Checking kernel version... "
uname -r

# Check required repos
echo -n "Checking multilib... "
if grep -q "^
[multilib]
" /etc/pacman.conf; then
    echo "ENABLED"
else
    echo "DISABLED"
    echo "Enabling multilib..."
    ${SUDO} sed -i '/
[multilib]
/,/Include/s/^#//' /etc/pacman.conf
    ${SUDO} pacman -Sy
fi

echo "=== Preflight Checks Complete ==="
echo ""
echo "IMPORTANT: yay (AUR helper) must be installed BEFORE the main installation."
echo "Run as a regular user (NOT sudo):"
echo "  bash ${BASH_SOURCE[0]%/*}/00-install-yay.sh"
echo ""
echo "Then continue with the full installation pipeline."