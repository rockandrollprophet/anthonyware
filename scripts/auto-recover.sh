#!/usr/bin/env bash
set -euo pipefail

# Anthonyware Auto-Recover (best-effort)
# Attempts safe fixes for common issues.

log() { printf "%s\n" "$*"; }

log "=== Auto-Recover: starting ==="

# 1) pacman lock recovery (if no pacman processes)
if [[ -e /var/lib/pacman/db.lck ]]; then
  if ! pgrep -x pacman >/dev/null 2>&1; then
    age=$(expr $(date +%s) - $(stat -c %Y /var/lib/pacman/db.lck || echo $(date +%s)))
    if [[ $age -gt 1800 ]]; then
      log "pacman lock older than 30m and no pacman running: removing lock"
      rm -f /var/lib/pacman/db.lck || true
      log "pacman lock removed"
    else
      log "pacman lock is recent; leaving in place"
    fi
  else
    log "pacman process running; will not remove lock"
  fi
else
  log "pacman lock not present"
fi

# 2) NetworkManager nudge (if service exists)
if systemctl list-units --type=service | grep -q NetworkManager; then
  log "Restarting NetworkManager (best-effort)"
  systemctl restart NetworkManager || true
else
  log "NetworkManager not present or not a systemd service"
fi

# 3) Refresh pacman databases
if command -v pacman >/dev/null; then
  log "Refreshing pacman databases (Syy)"
  pacman -Syy --noconfirm || true
fi

# 4) Sensors setup hint (no interactive run)
if command -v sensors >/dev/null; then
  log "Sensors available. Run 'sudo sensors-detect' manually for full setup if needed."
fi

log "=== Auto-Recover: done ==="
