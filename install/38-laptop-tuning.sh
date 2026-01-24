#!/usr/bin/env bash
# Laptop-specific power and thermal tuning
set -euo pipefail

_log(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

_log "Applying laptop tuning (power profiles, TLP if available)..."

# Prefer power-profiles-daemon when present
if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q power-profiles-daemon.service; then
  systemctl enable --now power-profiles-daemon.service || _warn "Could not enable power-profiles-daemon"
fi

# Apply TLP conservative defaults when TLP is installed
if command -v tlp >/dev/null 2>&1; then
  install -d /etc/tlp.d
  cat >/etc/tlp.d/90-anthonyware-laptop.conf <<'EOF'
# Anthonyware laptop tuning
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
PLATFORM_PROFILE_ON_BAT=low-power
PLATFORM_PROFILE_ON_AC=balanced
RESTORE_DEVICE_STATE_ON_STARTUP=1
EOF
  tlp start || _warn "TLP start reported issues"
fi

# Encourage swap-backed suspend if zram is enabled
if systemctl list-units --all | grep -q zram-swap.service; then
  _log "zram swap detected; favor suspend-then-hibernate where supported"
fi

_log "Laptop tuning completed"