#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  33-user-configs.sh
#  Deploy ALL user-level configs into $TARGET_HOME/.config
#  Fixes permissions, ownership, and appends shell RC entries.
# ============================================================

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

# Determine repo location
CONFIG_SRC="${REPO_PATH:-${TARGET_HOME}/anthonyware}/configs"

# Ensure .config exists
mkdir -p "${TARGET_HOME}/.config"

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
  DEST="${TARGET_HOME}/.config/${dir}"

  if [[ -d "${SRC}" ]]; then
    echo "[user-configs] Copying ${dir} → ${DEST}"
    mkdir -p "${DEST}"
    cp -rT "${SRC}" "${DEST}" || { echo "ERROR: Failed to copy ${dir}"; exit 1; }
  else
    echo "[user-configs] WARNING: Missing config directory: ${SRC}"
  fi
done

# Fix permissions
echo "[user-configs] Fixing permissions..."
chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config" || { echo "ERROR: Failed to chown .config"; exit 1; }

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
