#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# posture.sh - Host posture checks (lightweight)

POSTURE_MODE=${POSTURE_MODE:-warn} # enforce|warn|skip

_posture_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_posture_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_posture_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

posture_check_sysctl() {
  local key="$1" expected="$2"
  local val
  val=$(sysctl -n "$key" 2>/dev/null || echo "missing")
  if [[ "$val" == "$expected" ]]; then
    _posture_log_info "sysctl $key=$val (ok)"
    return 0
  fi
  _posture_log_warn "sysctl $key=$val (expected $expected)"
  [[ "$POSTURE_MODE" == "enforce" ]] && return 1
  return 0
}

posture_check_service_disabled() {
  local svc="$1"
  if systemctl is-enabled "$svc" >/dev/null 2>&1; then
    _posture_log_warn "Service should be disabled: $svc"
    [[ "$POSTURE_MODE" == "enforce" ]] && return 1
  else
    _posture_log_info "Service not enabled: $svc"
  fi
  return 0
}

posture_check_all() {
  [[ "$POSTURE_MODE" == "skip" ]] && { _posture_log_warn "Posture checks skipped (POSTURE_MODE=skip)"; return 0; }
  local failed=0

  # Sample checks (light):
  posture_check_sysctl "kernel.unprivileged_userns_clone" "0" || failed=1
  posture_check_service_disabled "telnet.socket" || failed=1

  if (( failed )); then
    if [[ "$POSTURE_MODE" == "enforce" ]]; then
      _posture_log_error "Posture checks failed (enforce)."
      return 1
    fi
    _posture_log_warn "Posture checks reported issues (warn)."
    return 0
  fi
  _posture_log_info "Posture checks passed."
  return 0
}

export -f posture_check_all
export -f posture_check_sysctl
export -f posture_check_service_disabled
