#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  validate-configs.sh
#  Verify user config files are present and correct
# ============================================================

TARGET_USER="${TARGET_USER:-${SUDO_USER:-$USER}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

echo "=== Config Validation for ${TARGET_USER} ==="
echo "Home: ${TARGET_HOME}"
echo

ERRORS=0

check_dir() {
  local path="$1"
  if [[ -d "$path" ]]; then
    echo "[ ✓ ] Directory: $path"
  else
    echo "[ ✗ ] Missing: $path"
    ((ERRORS++))
  fi
}

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "[ ✓ ] File: $path"
  else
    echo "[ ✗ ] Missing: $path"
    ((ERRORS++))
  fi
}

echo "— Config Directories —"
check_dir "${TARGET_HOME}/.config/hypr"
check_dir "${TARGET_HOME}/.config/hyprlock"
check_dir "${TARGET_HOME}/.config/hypridle"
check_dir "${TARGET_HOME}/.config/waybar"
check_dir "${TARGET_HOME}/.config/kitty"
check_dir "${TARGET_HOME}/.config/fastfetch"
check_dir "${TARGET_HOME}/.config/eww"
check_dir "${TARGET_HOME}/.config/swaync"
check_dir "${TARGET_HOME}/.config/mako"
check_dir "${TARGET_HOME}/.config/wofi"

echo
echo "— RC Files —"
check_file "${TARGET_HOME}/.zshrc"
check_file "${TARGET_HOME}/.bashrc"

echo
echo "— Marker Files —"
check_file "${TARGET_HOME}/.anthonyware-installed"

echo
echo "=== Results ==="
if [[ $ERRORS -eq 0 ]]; then
  echo "✓ All configs present."
  exit 0
else
  echo "✗ $ERRORS config(s) missing."
  exit 1
fi
