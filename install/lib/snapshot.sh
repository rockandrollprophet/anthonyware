#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# snapshot.sh - Snapshot and rollback helpers (btrfs-first, safe fallbacks)

SNAPSHOT_ENABLE=${SNAPSHOT_ENABLE:-0}
SNAPSHOT_PREFIX=${SNAPSHOT_PREFIX:-anthonyware}
SNAPSHOT_DIR=${SNAPSHOT_DIR:-/.snapshots}
SNAPSHOT_EXCLUDES=${SNAPSHOT_EXCLUDES:-"/proc /sys /dev /run /tmp /mnt /media"}
ROLLBACK_ON_FAIL=${ROLLBACK_ON_FAIL:-1}

_snapshot_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_snapshot_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_snapshot_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }
_snapshot_log_success(){ if command -v log_success >/dev/null 2>&1; then log_success "$@"; else echo "[OK] $*"; fi; }

snapshot_supported() {
  command -v btrfs >/dev/null 2>&1 && findmnt -n -o FSTYPE / | grep -qi btrfs
}

snapshot_create() {
  local label="$1"
  if ! snapshot_supported; then
    _snapshot_log_warn "Snapshots not supported on this filesystem. Skipping."
    return 1
  fi

  mkdir -p "$SNAPSHOT_DIR"
  local name="${SNAPSHOT_PREFIX}-${label:-$(date +%Y%m%d-%H%M%S)}"
  local target="$SNAPSHOT_DIR/$name"

  if btrfs subvolume snapshot -r / "$target" >/dev/null 2>&1; then
    _snapshot_log_success "Snapshot created: $target"
    echo "$target"
    return 0
  else
    _snapshot_log_warn "Failed to create snapshot at $target"
    return 1
  fi
}

snapshot_rollback() {
  local snap_path="$1"
  if [[ -z "$snap_path" || ! -d "$snap_path" ]]; then
    _snapshot_log_warn "No valid snapshot provided for rollback."
    return 1
  fi

  if ! snapshot_supported; then
    _snapshot_log_warn "Rollback not supported on this filesystem."
    return 1
  fi

  _snapshot_log_warn "Attempting rollback from snapshot: $snap_path (rsync-based, excludes: $SNAPSHOT_EXCLUDES)"

  local exclude_args=()
  for ex in $SNAPSHOT_EXCLUDES; do
    exclude_args+=("--exclude=$ex")
  done

  if rsync -aHAX --delete --numeric-ids "${exclude_args[@]}" "$snap_path/" /; then
    _snapshot_log_success "Rollback completed from $snap_path"
    return 0
  else
    _snapshot_log_error "Rollback failed from $snap_path"
    return 1
  fi
}

export -f snapshot_supported
export -f snapshot_create
export -f snapshot_rollback
