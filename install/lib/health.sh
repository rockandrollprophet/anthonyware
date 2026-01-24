#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# health.sh - Health gates for installation

# Configuration
HEALTH_BATTERY_MIN=${HEALTH_BATTERY_MIN:-5}          # Minimum acceptable battery percentage
HEALTH_BATTERY_MODE=${HEALTH_BATTERY_MODE:-enforce}  # enforce|warn|skip
HEALTH_IGNORE_BATTERY=${HEALTH_IGNORE_BATTERY:-0}    # 1 to bypass battery checks entirely
HEALTH_SKIP_ALL=${HEALTH_SKIP_ALL:-0}                # 1 to bypass all health checks

# Local logging helpers fall back to echo if logging library is unavailable
_health_log_info()    { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_health_log_warn()    { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_health_log_error()   { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }
_health_log_success() { if command -v log_success >/dev/null 2>&1; then log_success "$@"; else echo "[OK] $*"; fi; }

health_check_battery() {
  if [[ "$HEALTH_IGNORE_BATTERY" == "1" ]]; then
    _health_log_warn "Battery check bypassed (HEALTH_IGNORE_BATTERY=1)"
    return 0
  fi

  shopt -s nullglob
  local batteries=(/sys/class/power_supply/BAT*/capacity)
  shopt -u nullglob

  # No battery present (likely desktop or VM)
  if (( ${#batteries[@]} == 0 )); then
    _health_log_info "No battery detected; assuming desktop/VM or AC-only system"
    return 0
  fi

  local failed=0
  for capfile in "${batteries[@]}"; do
    local cap
    cap=$(cat "$capfile" 2>/dev/null || echo "unknown")

    if [[ "$cap" =~ ^[0-9]+$ ]]; then
      if (( cap < HEALTH_BATTERY_MIN )); then
        case "$HEALTH_BATTERY_MODE" in
          enforce)
            _health_log_error "Battery at ${cap}% (< ${HEALTH_BATTERY_MIN}%). Set HEALTH_IGNORE_BATTERY=1 to bypass."
            failed=1
            ;;
          warn)
            _health_log_warn "Battery at ${cap}% (< ${HEALTH_BATTERY_MIN}%). Proceeding (warn mode)."
            ;;
          skip)
            _health_log_warn "Battery check skipped (HEALTH_BATTERY_MODE=skip)."
            ;;
          *)
            _health_log_warn "Unknown HEALTH_BATTERY_MODE='${HEALTH_BATTERY_MODE}', defaulting to enforce."
            failed=1
            ;;
        esac
      else
        _health_log_info "Battery level: ${cap}% (threshold ${HEALTH_BATTERY_MIN}%)."
      fi
    else
      _health_log_warn "Battery capacity unreadable at ${capfile}. Set HEALTH_IGNORE_BATTERY=1 to bypass enforcement."
      [[ "$HEALTH_BATTERY_MODE" == "enforce" ]] && failed=1
    fi
  done

  [[ $failed -eq 0 ]]
}

health_check_all() {
  if [[ "$HEALTH_SKIP_ALL" == "1" ]]; then
    _health_log_warn "Health checks skipped (HEALTH_SKIP_ALL=1)."
    return 0
  fi

  local failed=0
  health_check_battery || failed=1

  if (( failed )); then
    _health_log_error "Health checks failed."
    return 1
  fi

  _health_log_success "Health checks passed."
  return 0
}

export -f health_check_battery
export -f health_check_all
