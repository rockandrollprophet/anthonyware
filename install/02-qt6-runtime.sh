#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# 02-qt6-runtime.sh
# Install full Qt6 runtime stack to harden SDDM + QtQuick themes.

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via ${SUDO} from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

echo "[02-qt6-runtime] Installing Qt6 runtime stack..."

pacman --noconfirm --needed -S \
  qt6-base \
  qt6-declarative \
  qt6-svg \
  qt6-shadertools \
  qt6-tools \
  qt6-5compat \
  qt6-languageserver \
  qt6-multimedia

echo "[02-qt6-runtime] Qt6 runtime installed."

# Optional: SDDM environment file to enforce Qt6 paths
SDDM_ENV_DIR="/etc/sddm.conf.d"
mkdir -p "${SDDM_ENV_DIR}"

SDDM_ENV_FILE="${SDDM_ENV_DIR}/10-qt6-env.conf"
if [[ ! -f "${SDDM_ENV_FILE}.anthonyware.bak" && -f "${SDDM_ENV_FILE}" ]]; then
  cp -v "${SDDM_ENV_FILE}" "${SDDM_ENV_FILE}.anthonyware.bak"
fi

cat > "${SDDM_ENV_FILE}" <<EOF
[General]
# Ensure SDDM greeter sees Qt6 QML + plugins
Environment=QML2_IMPORT_PATH=/usr/lib/qt6/qml
Environment=QT_PLUGIN_PATH=/usr/lib/qt6/plugins
EOF

echo "[02-qt6-runtime] Wrote ${SDDM_ENV_FILE}."
