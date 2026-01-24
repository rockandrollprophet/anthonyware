#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# overlay.sh - Atomic-ish config/application deployment helper

# Applies a directory to a destination by staging to a temp path, then swapping.
# Features: rsync with delete into a temp dir, optional backup of old dest, atomic rename on same filesystem.

OVERLAY_BACKUP=${OVERLAY_BACKUP:-1}                    # 1 to keep a .bak timestamped backup of existing dest
OVERLAY_RSYNC_OPTS=${OVERLAY_RSYNC_OPTS:-"-aHAX --delete"}

_overlay_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_overlay_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_overlay_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }
_overlay_log_success(){ if command -v log_success >/dev/null 2>&1; then log_success "$@"; else echo "[OK] $*"; fi; }

overlay_apply_dir() {
  local src="$1"
  local dest="$2"

  if [[ -z "$src" || -z "$dest" ]]; then
    _overlay_log_error "overlay_apply_dir: src or dest missing"
    return 1
  fi
  if [[ ! -d "$src" ]]; then
    _overlay_log_warn "overlay_apply_dir: source not found: $src"
    return 1
  fi

  local dest_parent
  dest_parent=$(dirname "$dest")
  mkdir -p "$dest_parent"

  local staged
  staged=$(mktemp -d "$dest_parent/.overlay-XXXXXX") || return 1

  # Stage with rsync
  if ! rsync $OVERLAY_RSYNC_OPTS "$src/" "$staged/"; then
    _overlay_log_error "overlay_apply_dir: rsync failed for $src"
    rm -rf "$staged"
    return 1
  fi

  local backup=""
  if [[ -e "$dest" ]]; then
    if [[ "$OVERLAY_BACKUP" == "1" ]]; then
      backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$backup" || { _overlay_log_warn "overlay_apply_dir: backup move failed"; backup=""; }
    else
      rm -rf "$dest"
    fi
  fi

  if mv "$staged" "$dest"; then
    _overlay_log_success "overlay_apply_dir: applied $src -> $dest"
    return 0
  else
    _overlay_log_error "overlay_apply_dir: move failed for $dest"
    rm -rf "$staged"
    if [[ -n "$backup" && -e "$backup" ]]; then
      mv "$backup" "$dest" || true
    fi
    return 1
  fi
}

export -f overlay_apply_dir
