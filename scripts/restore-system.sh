#!/usr/bin/env bash
set -euo pipefail

# Anthonyware — Restore System (best-effort)
# Restores configuration from a previously created snapshot archive

DRY_RUN="${DRY_RUN:-0}"
CONFIRM_RESTORE="${CONFIRM_RESTORE:-}"
TARGET_USER="${SUDO_USER:-${USER}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
LOG_DIR="${TARGET_HOME}/anthonyware-logs"

msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [RESTORE] $*"; }

SNAPSHOT_PATH="${SNAPSHOT_PATH:-}"
if [[ -z "$SNAPSHOT_PATH" ]]; then
  SNAPSHOT_PATH=$(ls -1t "$LOG_DIR"/system-snapshot-*.tar.gz 2>/dev/null | head -1 || true)
fi

if [[ -z "$SNAPSHOT_PATH" || ! -f "$SNAPSHOT_PATH" ]]; then
  msg "No snapshot archive found in ${LOG_DIR}"
  exit 1
fi

msg "Using snapshot: ${SNAPSHOT_PATH}"

if [[ "$DRY_RUN" == "1" ]]; then
  msg "DRY RUN: Listing snapshot contents"
  tar -tzf "$SNAPSHOT_PATH" | sed 's/^/  - /'
  msg "DRY RUN: No changes will be applied"
  exit 0
fi

if [[ "$CONFIRM_RESTORE" != "YES" ]]; then
  msg "Confirmation required. Set CONFIRM_RESTORE=YES to proceed."
  exit 2
fi

msg "Restoring configuration files to / (best-effort)"
# Use tar with overwrite semantics; avoid preserving ownership from archive by using --no-same-owner
# NOTE: This operation is intrusive; ensure you trust the snapshot contents before proceeding.
if tar -xzf "$SNAPSHOT_PATH" -C / --no-same-owner --overwrite; then
  msg "Restore completed successfully"
else
  msg "Restore encountered errors"
  exit 1
fi
