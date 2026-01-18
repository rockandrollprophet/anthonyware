#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# 35-fusion360-runtime.sh
# Install WINE/Bottles/DXVK/VKD3D runtime for Fusion 360.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via ${SUDO} from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

echo "[35-fusion360-runtime] Installing WINE/Bottles runtime stack..."

pacman --noconfirm --needed -S \
  wine \
  wine-mono \
  wine-gecko \
  winetricks \
  bottles \
  vkd3d \
  vulkan-icd-loader

if command -v yay >/dev/null 2>&1; then
  yay -S --noconfirm --needed \
    vkd3d-proton \
    dxvk-bin \
    fusion360-bin || echo "WARNING: Some Fusion360 packages failed to build via yay"
else
  echo "[35-fusion360-runtime] NOTICE: yay not found; skipping vkd3d-proton, dxvk-bin, fusion360-bin." >&2
fi

echo "[35-fusion360-runtime] Fusion 360 runtime stack installed (installer/configuration still required)."
