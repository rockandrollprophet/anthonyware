#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  33-user-configs.sh
#  Deploy ALL user-level configs into $TARGET_HOME/.config
#  Fixes permissions, ownership, and appends shell RC entries.
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lib/overlay.sh" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/lib/overlay.sh"
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "This script must be run as root (via sudo from run-all.sh)." >&2
  exit 1
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
if [[ -z "${TARGET_USER}" || "${TARGET_USER}" == "root" ]]; then
  echo "ERROR: TARGET_USER is not set or is root. Run via run-all.sh, not as pure root." >&2
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "=== [33] User Config Deployment ==="
echo "[user-configs] Deploying configs into ${TARGET_HOME}"

# Determine repo location - check multiple possible paths
if [[ -n "${REPO_PATH:-}" ]] && [[ -d "${REPO_PATH}/configs" ]]; then
  CONFIG_SRC="${REPO_PATH}/configs"
elif [[ -d "${TARGET_HOME}/anthonyware/configs" ]]; then
  CONFIG_SRC="${TARGET_HOME}/anthonyware/configs"
elif [[ -d "/root/anthonyware-setup/anthonyware/configs" ]]; then
  CONFIG_SRC="/root/anthonyware-setup/anthonyware/configs"
else
  echo "ERROR: Cannot find anthonyware configs directory"
  echo "Searched:"
  echo "  - ${REPO_PATH:-REPO_PATH not set}/configs"
  echo "  - ${TARGET_HOME}/anthonyware/configs"
  echo "  - /root/anthonyware-setup/anthonyware/configs"
  exit 1
fi

echo "[user-configs] Using config source: ${CONFIG_SRC}"

# Ensure .config exists
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${TARGET_HOME}/.config}"
mkdir -p "${XDG_CONFIG_HOME}"

# List of config directories to deploy
CONFIG_DIRS=(
  "hypr"
  "hyprlock"
  "hypridle"
  "waybar"
  "kitty"
  "fastfetch"
  "eww"
  "swaync"
  "mako"
  "wofi"
)

for dir in "${CONFIG_DIRS[@]}"; do
  SRC="${CONFIG_SRC}/${dir}"
  DEST="${XDG_CONFIG_HOME}/${dir}"

  if [[ -d "${SRC}" ]]; then
    echo "[user-configs] Applying ${dir} → ${DEST}"
    mkdir -p "${XDG_CONFIG_HOME}"
    if command -v overlay_apply_dir >/dev/null 2>&1; then
      if ! overlay_apply_dir "${SRC}" "${DEST}"; then
        echo "ERROR: Failed to apply ${dir}"; exit 1;
      fi
    else
      mkdir -p "${DEST}"
      cp -rT "${SRC}" "${DEST}" || { echo "ERROR: Failed to copy ${dir}"; exit 1; }
    fi
  else
    echo "[user-configs] WARNING: Missing config directory: ${SRC}"
  fi
done

# Fix permissions
echo "[user-configs] Fixing permissions..."
chown -R "${TARGET_USER}:${TARGET_USER}" "${XDG_CONFIG_HOME}" || { echo "ERROR: Failed to chown .config"; exit 1; }

# Create and configure Zsh RC
ZSHRC="${TARGET_HOME}/.zshrc"
echo "[user-configs] Configuring ${ZSHRC}..."

if [[ ! -f "$ZSHRC" ]]; then
  touch "$ZSHRC"
fi

# Add anthonyware marker if not present
if ! grep -q "# Added by Anthonyware installer" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# Added by Anthonyware installer"
    echo "# Enable Starship prompt"
    if command -v starship >/dev/null 2>&1; then
      echo 'eval "$(starship init zsh)"'
    fi
    echo "# Enable Atuin shell history"
    if command -v atuin >/dev/null 2>&1; then
      echo 'eval "$(atuin init zsh)"'
    fi
    echo "# Add local bins to PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$ZSHRC"
fi

chown "${TARGET_USER}:${TARGET_USER}" "$ZSHRC" || { echo "ERROR: Failed to chown .zshrc"; exit 1; }

# Create marker file
echo "[user-configs] Creating installation marker..."
touch "${TARGET_HOME}/.anthonyware-installed"
chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.anthonyware-installed"

# Attempt to enable user systemd services
echo "[user-configs] Enabling user services..."
if systemctl --user -M "${TARGET_USER}" is-active --quiet syncthing@"${TARGET_USER}" 2>/dev/null || \
   systemctl --user -M "${TARGET_USER}" list-units --all | grep -q syncthing 2>/dev/null; then
  sudo -u "${TARGET_USER}" systemctl --user enable syncthing@"${TARGET_USER}" 2>/dev/null || true
  sudo -u "${TARGET_USER}" systemctl --user start syncthing@"${TARGET_USER}" 2>/dev/null || true
fi

echo "=== [33] User config deployment complete ==="
