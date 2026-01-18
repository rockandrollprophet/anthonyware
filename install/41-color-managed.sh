#!/usr/bin/env bash
# Color management enablement
set -euo pipefail

_log(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

_log "Ensuring color management services are active..."

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q colord.service; then
  systemctl enable --now colord.service >/dev/null 2>&1 || _warn "Could not enable colord.service"
fi

# Drop a quickstart note for users to calibrate displays
TARGET_HOME=${TARGET_HOME:-/root}
NOTE_DIR="${TARGET_HOME}/anthonyware-logs"
mkdir -p "$NOTE_DIR"
cat >"$NOTE_DIR/color-managed-notes.txt" <<'EOF'
Color-managed profile active.
- Use displaycal / colormgr to import or calibrate ICC profiles.
- Ensure your monitor is set to its native gamut and correct white point before calibration.
- Reload color profiles after GPU driver updates if colors drift.
EOF

_log "Color management prepared; see ${NOTE_DIR}/color-managed-notes.txt"