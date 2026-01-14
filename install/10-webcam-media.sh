#!/usr/bin/env bash
set -euo pipefail

# 10-webcam-media.sh
# Install webcam tooling and simple media capture apps.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via sudo from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

echo "[10-webcam-media] Installing webcam + media tools..."

pacman --noconfirm --needed -S \
  v4l-utils \
  ffmpeg \
  cheese \
  guvcview

echo "[10-webcam-media] Webcam + media tools installed."

echo "[10-webcam-media] You can test your camera with:"
echo "  - cheese"
echo "  - guvcview"
echo "  - ffplay /dev/video0"
