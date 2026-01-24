#!/usr/bin/env bash
# Cloud/VM footprint tuning
set -euo pipefail

_log(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

_log "Applying cloud tuning (journald limits, headless target)..."

# Keep journal lean on cloud images
install -d /etc/systemd/journald.conf.d
cat >/etc/systemd/journald.conf.d/10-anthonyware-cloud.conf <<'EOF'
[Journal]
SystemMaxUse=200M
SystemMaxFileSize=50M
MaxRetentionSec=7day
EOF
systemctl restart systemd-journald.service >/dev/null 2>&1 || _warn "journald restart reported issues"

# Prefer headless default target
if command -v systemctl >/dev/null 2>&1; then
  systemctl set-default multi-user.target >/dev/null 2>&1 || true
  if systemctl list-unit-files | grep -q sddm.service; then
    systemctl disable --now sddm.service >/dev/null 2>&1 || true
  fi
fi

_log "Cloud tuning completed"