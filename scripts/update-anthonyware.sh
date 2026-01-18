#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  update-anthonyware.sh
#  Update existing Anthonyware installation
# ============================================================

if [[ "${EUID}" -ne 0 ]]; then
  echo "This script must be run as root: sudo bash update-anthonyware.sh"
  exit 1
fi

TARGET_USER="${SUDO_USER:-${USER}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "ERROR: Cannot determine target user. Run with sudo."
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
REPO_PATH="${TARGET_HOME}/anthonyware"

if [[ ! -d "$REPO_PATH" ]]; then
  REPO_PATH="/root/anthonyware-setup/anthonyware"
fi

if [[ ! -d "$REPO_PATH" ]]; then
  echo "ERROR: Cannot find anthonyware repository"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Anthonyware OS Update                                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "Repository: $REPO_PATH"
echo "User: $TARGET_USER"
echo

# Backup current installation
echo "Creating backup..."
BACKUP_DIR="${TARGET_HOME}/.anthonyware-backups/update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "${TARGET_HOME}/.config" "$BACKUP_DIR/" 2>/dev/null || true
echo "✓ Backup created: $BACKUP_DIR"
echo

# Pull latest changes
echo "Updating repository..."
cd "$REPO_PATH"

# Stash any local changes
git stash push -m "Auto-stash before update $(date)"

# Pull latest
if ! git pull origin main; then
  echo "ERROR: Failed to pull updates"
  echo "Your changes are stashed. Run 'git stash pop' to restore them."
  exit 1
fi

echo "✓ Repository updated"
echo

# Detect changed files
echo "Detecting changes..."
CHANGED_SCRIPTS=$(git diff --name-only HEAD@{1} HEAD | grep "install/.*\.sh$" || true)

if [[ -z "$CHANGED_SCRIPTS" ]]; then
  echo "No installation scripts changed. Checking for config updates..."
  
  CHANGED_CONFIGS=$(git diff --name-only HEAD@{1} HEAD | grep "configs/" || true)
  
  if [[ -n "$CHANGED_CONFIGS" ]]; then
    echo "Configuration files updated:"
    echo "$CHANGED_CONFIGS"
    echo
    read -rp "Redeploy configs? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
      bash "$REPO_PATH/install/33-user-configs.sh"
    fi
  else
    echo "✓ No changes detected. System is up to date."
  fi
  exit 0
fi

echo "Changed scripts:"
echo "$CHANGED_SCRIPTS"
echo

# Ask which scripts to re-run
read -rp "Re-run changed scripts? [Y/n] " answer
if [[ "$answer" =~ ^[Nn]$ ]]; then
  echo "Update cancelled"
  exit 0
fi

# Re-run changed scripts
echo
echo "Re-running changed scripts..."
export CONFIRM_INSTALL=YES
export TARGET_USER
export TARGET_HOME
export REPO_PATH

cd "$REPO_PATH/install"

while IFS= read -r script; do
  script_name=$(basename "$script")
  if [[ -f "$script_name" ]]; then
    echo
    echo "Running: $script_name"
    if bash "$script_name"; then
      echo "✓ $script_name completed"
    else
      echo "✗ $script_name failed"
      read -rp "Continue with remaining scripts? [Y/n] " cont
      [[ "$cont" =~ ^[Nn]$ ]] && exit 1
    fi
  fi
done <<< "$CHANGED_SCRIPTS"

echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Update Complete                                           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo
echo "Backup location: $BACKUP_DIR"
echo "Changes applied successfully"
echo
read -rp "Reboot now? [y/N] " reboot
if [[ "$reboot" =~ ^[Yy]$ ]]; then
  reboot
fi
