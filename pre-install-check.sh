#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  pre-install-check.sh
#  Run this BEFORE install-anthonyware.sh
#  Validates system readiness for Anthonyware installation
# ============================================================

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Anthonyware OS — Pre-Installation Validation        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo

ERRORS=0

# ============================================================
#  1. Root Check
# ============================================================
echo "[1/10] Checking privileges..."
if [[ $EUID -ne 0 ]]; then
   echo "  ✗ FAIL: Must run as root (use: sudo ./pre-install-check.sh)"
   ((ERRORS++))
else
   echo "  ✓ OK: Running as root"
fi

# ============================================================
#  2. Boot Mode (UEFI/BIOS)
# ============================================================
echo "[2/10] Checking boot mode..."
if [[ -d /sys/firmware/efi/efivars ]]; then
   echo "  ✓ OK: UEFI mode detected"
else
   echo "  ⚠ WARNING: Legacy BIOS mode (UEFI recommended)"
fi

# ============================================================
#  3. Internet Connectivity
# ============================================================
echo "[3/10] Checking internet connectivity..."
if ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
   echo "  ✓ OK: Internet connected"
else
   echo "  ✗ FAIL: No internet connection"
   echo "     Connect WiFi with: iwctl"
   echo "     Or ethernet: ip link set eth0 up"
   ((ERRORS++))
fi

# ============================================================
#  4. DNS Resolution
# ============================================================
echo "[4/10] Checking DNS resolution..."
if nslookup archlinux.org >/dev/null 2>&1; then
   echo "  ✓ OK: DNS working"
else
   echo "  ⚠ WARNING: DNS may not be configured"
fi

# ============================================================
#  5. Disk Space
# ============================================================
echo "[5/10] Checking available disks..."
DISK="${1:-/dev/nvme0n1}"

if [[ -b "$DISK" ]]; then
   SIZE=$(lsblk -bdn -o SIZE "$DISK" 2>/dev/null || echo "0")
   SIZE_GB=$((SIZE / 1024 / 1024 / 1024))
   
   if [[ $SIZE_GB -ge 30 ]]; then
      echo "  ✓ OK: $DISK has ${SIZE_GB}GB (minimum 30GB)"
   else
      echo "  ✗ FAIL: $DISK only has ${SIZE_GB}GB (need 30GB minimum)"
      ((ERRORS++))
   fi
else
   echo "  ⚠ WARNING: $DISK not found (specify as arg: $0 /dev/sdX)"
fi

# ============================================================
#  6. Available Disks List
# ============================================================
echo "[6/10] Available disks:"
lsblk -d -o NAME,SIZE,TYPE | grep disk | while read -r line; do
   echo "     /dev/$line"
done

# ============================================================
#  7. RAM Check
# ============================================================
echo "[7/10] Checking RAM..."
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$((RAM_KB / 1024 / 1024))

if [[ $RAM_GB -ge 8 ]]; then
   echo "  ✓ OK: ${RAM_GB}GB RAM (recommended 8GB+)"
elif [[ $RAM_GB -ge 4 ]]; then
   echo "  ⚠ WARNING: ${RAM_GB}GB RAM (4GB minimum, 8GB recommended)"
else
   echo "  ✗ FAIL: ${RAM_GB}GB RAM (need 4GB minimum)"
   ((ERRORS++))
fi

# ============================================================
#  8. CPU Architecture
# ============================================================
echo "[8/10] Checking CPU..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
   echo "  ✓ OK: x86_64 architecture"
else
   echo "  ✗ FAIL: Unsupported architecture: $ARCH"
   ((ERRORS++))
fi

# ============================================================
#  9. Required Commands
# ============================================================
echo "[9/10] Checking required commands..."
REQUIRED_CMDS=(pacman git bash sgdisk mkfs.fat mkfs.btrfs mount arch-chroot)
MISSING=0

for cmd in "${REQUIRED_CMDS[@]}"; do
   if command -v "$cmd" >/dev/null 2>&1; then
      echo "  ✓ $cmd"
   else
      echo "  ✗ MISSING: $cmd"
      ((MISSING++))
      ((ERRORS++))
   fi
done

if [[ $MISSING -eq 0 ]]; then
   echo "  ✓ All required commands present"
fi

# ============================================================
#  10. Pacman Keyring
# ============================================================
echo "[10/10] Checking pacman keyring..."
if pacman-key --list-keys >/dev/null 2>&1; then
   echo "  ✓ OK: Pacman keyring initialized"
else
   echo "  ⚠ WARNING: Pacman keyring may need initialization"
   echo "     Run: pacman-key --init && pacman-key --populate archlinux"
fi

# ============================================================
#  SUMMARY
# ============================================================
echo
echo "════════════════════════════════════════════════════════"
if [[ $ERRORS -eq 0 ]]; then
   echo " ✓ READY: All checks passed!"
   echo
   echo " Next steps:"
   echo "   1. Review install-anthonyware.sh configuration"
   echo "   2. Backup any important data (disk will be WIPED)"
   echo "   3. Run: sudo ./install-anthonyware.sh"
   echo
   echo " ⚠️  WARNING: This will ERASE $DISK completely!"
   echo
else
   echo " ✗ NOT READY: $ERRORS errors found"
   echo
   echo " Fix errors above before proceeding."
   echo
   exit 1
fi
echo "════════════════════════════════════════════════════════"
