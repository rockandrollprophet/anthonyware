#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# cache.sh - Package metadata prefetch and caching

CACHE_DIR="${CACHE_DIR:-${LOG_DIR:-/var/log/anthonyware-install}/cache}"
ENABLE_CACHE="${ENABLE_CACHE:-1}"

_cache_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_cache_log_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

cache_init() {
  [[ "$ENABLE_CACHE" != "1" ]] && return 0
  mkdir -p "$CACHE_DIR"
  _cache_log_info "Cache initialized at $CACHE_DIR"
}

# Prefetch package databases to speed up lookups
cache_prefetch_pacman() {
  [[ "$ENABLE_CACHE" != "1" ]] && return 0
  _cache_log_info "Prefetching pacman databases..."
  
  # Update databases without upgrading
  if command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm >/dev/null 2>&1 || _cache_log_warn "pacman -Sy failed"
  fi
  
  # Cache package info for common packages
  local common_pkgs=(
    "base-devel" "git" "wget" "curl" "firefox" "kitty" "hyprland"
    "docker" "python" "nodejs" "npm" "visual-studio-code-bin"
  )
  
  for pkg in "${common_pkgs[@]}"; do
    pacman -Si "$pkg" >"$CACHE_DIR/pacman-${pkg}.cache" 2>/dev/null || true
  done
  
  _cache_log_info "Pacman cache prefetch completed"
}

# Prefetch AUR helper metadata
cache_prefetch_aur() {
  [[ "$ENABLE_CACHE" != "1" ]] && return 0
  if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    return 0
  fi
  
  _cache_log_info "Prefetching AUR metadata..."
  
  local aur_helper
  if command -v paru >/dev/null 2>&1; then
    aur_helper="paru"
  else
    aur_helper="yay"
  fi
  
  # Sync AUR database
  sudo -u "$TARGET_USER" "$aur_helper" -Sy --noconfirm >/dev/null 2>&1 || true
  
  _cache_log_info "AUR cache prefetch completed"
}

# Cache package lists to avoid repeated queries
cache_installed_packages() {
  [[ "$ENABLE_CACHE" != "1" ]] && return 0
  if command -v pacman >/dev/null 2>&1; then
    pacman -Qq > "$CACHE_DIR/installed-packages.txt" 2>/dev/null || true
  fi
}

# Check if package is already installed (using cache)
cache_is_installed() {
  local pkg="$1"
  [[ "$ENABLE_CACHE" != "1" ]] && { pacman -Qq "$pkg" >/dev/null 2>&1; return $?; }
  
  if [[ -f "$CACHE_DIR/installed-packages.txt" ]]; then
    grep -qx "$pkg" "$CACHE_DIR/installed-packages.txt"
    return $?
  else
    pacman -Qq "$pkg" >/dev/null 2>&1
    return $?
  fi
}

# Cleanup old cache entries
cache_cleanup() {
  [[ "$ENABLE_CACHE" != "1" ]] && return 0
  if [[ -d "$CACHE_DIR" ]]; then
    find "$CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null || true
    _cache_log_info "Cache cleanup completed"
  fi
}

export -f cache_init
export -f cache_prefetch_pacman
export -f cache_prefetch_aur
export -f cache_installed_packages
export -f cache_is_installed
export -f cache_cleanup
