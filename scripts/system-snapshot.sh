#!/usr/bin/env bash
set -euo pipefail

# Anthonyware — System Snapshot (best-effort)
# Creates a compressed archive of key system configuration paths

TARGET_USER="${SUDO_USER:-${USER}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
LOG_DIR="${TARGET_HOME}/anthonyware-logs"
mkdir -p "$LOG_DIR"

TS="$(date '+%Y%m%d-%H%M%S')"
OUTFILE="${LOG_DIR}/system-snapshot-${TS}.tar.gz"

msg() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SNAPSHOT] $*"; }

# Candidate paths to include (only existing ones will be archived)
CANDIDATES=(
  "/etc/pacman.conf"
  "/etc/pacman.d/mirrorlist"
  "/etc/systemd"
  "/etc/NetworkManager"
  "/etc/wireplumber"
  "/etc/pipewire"
  "/etc/xdg"
  "/etc/mkinitcpio.conf"
  "/etc/sddm.conf"
  "/etc/sddm.conf.d"
  "/etc/ssh"
)

EXISTING=()
for p in "${CANDIDATES[@]}"; do
  if [[ -e "$p" ]]; then
    EXISTING+=("$p")
  fi
done

if [[ ${#EXISTING[@]} -eq 0 ]]; then
  msg "No known config paths found; snapshot skipped."
  exit 0
fi

msg "Archiving ${#EXISTING[@]} paths to ${OUTFILE}"
# Use tar with --ignore-failed-read to avoid aborting on transient issues
if tar -czf "$OUTFILE" --ignore-failed-read "${EXISTING[@]}"; then
  msg "Snapshot created: ${OUTFILE}"
else
  msg "Snapshot failed to create"
  exit 1
fi
