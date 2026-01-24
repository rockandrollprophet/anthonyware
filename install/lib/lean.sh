#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# lean.sh - Lean mode helpers to minimize footprint

LEAN_MODE="${LEAN_MODE:-0}"

_lean_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }

# Check if lean mode is enabled
lean_is_enabled() {
  [[ "$LEAN_MODE" == "1" ]]
}

# Get lean mode skip list (documentation, dev headers, optional deps)
lean_get_skip_list() {
  if ! lean_is_enabled; then
    echo ""
    return
  fi
  
  # Scripts to skip in lean mode
  local lean_skip=(
    "06-ai-ml.sh"
    "07-cad-cnc-3dprinting.sh"
    "11-vfio-windows-vm.sh"
    "17-steam.sh"
    "19-electrical-engineering.sh"
    "20-fpga-toolchain.sh"
    "21-instrumentation.sh"
    "31-wayland-recording.sh"
    "32-latex-docs.sh"
    "36-xwayland-legacy.sh"
  )
  
  IFS=','
  echo "${lean_skip[*]}"
}

# Filter package list to remove optional dependencies
lean_filter_packages() {
  local -n pkgs=$1
  
  if ! lean_is_enabled; then
    return 0
  fi
  
  # Remove documentation packages
  pkgs=($(printf '%s\n' "${pkgs[@]}" | grep -v '\-doc$'))
  pkgs=($(printf '%s\n' "${pkgs[@]}" | grep -v '\-docs$'))
  
  # Remove development headers when not needed
  if [[ "${2:-}" != "keep-devel" ]]; then
    pkgs=($(printf '%s\n' "${pkgs[@]}" | grep -v '\-devel$'))
    pkgs=($(printf '%s\n' "${pkgs[@]}" | grep -v '\-dev$'))
  fi
  
  _lean_log_info "Lean mode: filtered to ${#pkgs[@]} packages"
}

# Remove unnecessary locale files to save space
lean_cleanup_locales() {
  if ! lean_is_enabled; then
    return 0
  fi
  
  _lean_log_info "Lean mode: removing unnecessary locales..."
  
  # Keep only en_US locales
  if [[ -d /usr/share/locale ]]; then
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'en*' -exec rm -rf {} + 2>/dev/null || true
  fi
  
  # Remove man pages in other languages
  if [[ -d /usr/share/man ]]; then
    find /usr/share/man -mindepth 1 -maxdepth 1 -type d -name 'man[0-9]*' | while read -r dir; do
      if [[ ! "$dir" =~ /man[0-9]$ ]]; then
        rm -rf "$dir" 2>/dev/null || true
      fi
    done
  fi
  
  _lean_log_info "Lean mode: locale cleanup completed"
}

# Remove cached packages after install to save space
lean_cleanup_cache() {
  if ! lean_is_enabled; then
    return 0
  fi
  
  _lean_log_info "Lean mode: cleaning package cache..."
  
  if command -v pacman >/dev/null 2>&1; then
    pacman -Scc --noconfirm 2>/dev/null || true
  fi
  
  if command -v paru >/dev/null 2>&1; then
    sudo -u "$TARGET_USER" paru -Scc --noconfirm 2>/dev/null || true
  elif command -v yay >/dev/null 2>&1; then
    sudo -u "$TARGET_USER" yay -Scc --noconfirm 2>/dev/null || true
  fi
  
  _lean_log_info "Lean mode: cache cleanup completed"
}

# Report space savings
lean_report_savings() {
  if ! lean_is_enabled; then
    return 0
  fi
  
  _lean_log_info "Lean mode enabled - estimated savings:"
  echo "  - Documentation: ~500MB"
  echo "  - Locale files: ~200MB"
  echo "  - Package cache: ~1-2GB"
  echo "  - Optional scripts: ~5-10GB"
}

export -f lean_is_enabled
export -f lean_get_skip_list
export -f lean_filter_packages
export -f lean_cleanup_locales
export -f lean_cleanup_cache
export -f lean_report_savings
