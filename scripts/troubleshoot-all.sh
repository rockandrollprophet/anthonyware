#!/usr/bin/env bash
set -euo pipefail

# Anthonyware Troubleshooting Aggregator
# Runs diagnostics, captures key system info, and summarizes logs.

log_file="/tmp/anthonyware-troubleshoot-$(date +%Y%m%d-%H%M%S).log"

log() {
  printf "%s\n" "$*" | tee -a "$log_file"
}

run_step() {
  local title="$1"; shift || true
  log "-- $title"
  { "$@"; } >>"$log_file" 2>&1 || log "   [WARN] $title reported issues"
  log
}

log "=== Anthonyware Troubleshooting ==="
log "Log: $log_file"
log

# 1) Core diagnostics (if present)
if [[ -x scripts/diagnostics-suite.sh ]]; then
  run_step "Diagnostics suite" scripts/diagnostics-suite.sh
else
  log "[WARN] diagnostics-suite.sh not found"
fi

# 2a) Attempt auto-recover steps
if [[ -x scripts/auto-recover.sh ]]; then
  run_step "Auto-recover common issues" scripts/auto-recover.sh
else
  log "[WARN] auto-recover.sh not found"
fi

# 2) Package manager sanity (Arch)
run_step "pacman database check" bash -lc "if command -v pacman >/dev/null; then sudo pacman -D --asdeps >/dev/null; echo OK; else echo 'pacman not found'; fi"
run_step "pacman lock" bash -lc "if [ -e /var/lib/pacman/db.lck ]; then echo LOCKED; else echo clear; fi"

# 3) Journald summary (recent errors)
run_step "Recent journal errors" bash -lc "journalctl -p 3 -xb --no-pager | tail -200"

# 4) Services of interest (best effort)
run_step "Service status: NetworkManager" bash -lc "systemctl status NetworkManager || true"
run_step "Service status: bluetooth" bash -lc "systemctl status bluetooth || true"
run_step "Service status: pipewire" bash -lc "systemctl --user status pipewire pipewire-pulse || true"

# 5) Hardware health quick look
run_step "NVMe list" bash -lc "command -v nvme >/dev/null && nvme list || echo 'nvme not installed'"
run_step "SMART quick" bash -lc "command -v smartctl >/dev/null && smartctl --scan | head -3 | while read -r dev _; do [ -n \"$dev\" ] && smartctl -H \"$dev\"; done || echo 'smartctl not installed'"

# 6) Network basics
run_step "IP addr" ip addr
run_step "Routes" ip route

log "Troubleshooting complete. See log: $log_file"
