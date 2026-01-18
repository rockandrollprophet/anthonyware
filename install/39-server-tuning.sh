#!/usr/bin/env bash
# Server-focused sysctl and service trimming
set -euo pipefail

_log(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

_log "Applying server tuning (sysctl, service trimming)..."

# Sysctl for server workloads (best-effort)
cat >/etc/sysctl.d/99-anthonyware-server.conf <<'EOF'
# Anthonyware server tuning
fs.file-max=100000
net.core.somaxconn=4096
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_tw_reuse=1
vm.max_map_count=262144
vm.swappiness=10
EOF
sysctl -p /etc/sysctl.d/99-anthonyware-server.conf >/dev/null 2>&1 || _warn "sysctl apply reported issues"

# Trim desktop-only services when present
if command -v systemctl >/dev/null 2>&1; then
  if systemctl list-unit-files | grep -q bluetooth.service; then
    systemctl disable --now bluetooth.service >/dev/null 2>&1 || true
  fi
  if systemctl list-unit-files | grep -q sddm.service; then
    systemctl disable --now sddm.service >/dev/null 2>&1 || true
  fi
fi

_log "Server tuning completed"