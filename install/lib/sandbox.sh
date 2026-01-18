#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# sandbox.sh - Sandboxed execution helpers (best effort)

SANDBOX_MODE=${SANDBOX_MODE:-optional} # optional|enforce|off
SANDBOX_TOOL=${SANDBOX_TOOL:-auto}     # auto|firejail|bwrap|none

_sbx_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_sbx_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_sbx_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

sandbox_available() {
  case "$SANDBOX_TOOL" in
    firejail) command -v firejail >/dev/null 2>&1 ;;
    bwrap)    command -v bwrap >/dev/null 2>&1 ;;
    auto)
      command -v firejail >/dev/null 2>&1 && return 0
      command -v bwrap >/dev/null 2>&1 && return 0
      return 1
      ;;
    none|off) return 1 ;;
    *) return 1 ;;
  esac
}

sandbox_exec() {
  # Usage: sandbox_exec <cmd...>
  if [[ "$SANDBOX_MODE" == "off" ]]; then
    "$@"; return $?
  fi

  local tool="$SANDBOX_TOOL"
  if [[ "$tool" == "auto" ]]; then
    if command -v firejail >/dev/null 2>&1; then tool="firejail"; elif command -v bwrap >/dev/null 2>&1; then tool="bwrap"; else tool="none"; fi
  fi

  case "$tool" in
    firejail)
      if command -v firejail >/dev/null 2>&1; then
        _sbx_log_info "Running sandboxed (firejail): $*"
        firejail --quiet --private --nosound -- "$@"
        return $?
      fi
      ;;
    bwrap)
      if command -v bwrap >/dev/null 2>&1; then
        _sbx_log_info "Running sandboxed (bwrap): $*"
        bwrap --dev-bind / / --proc /proc --tmpfs /tmp --unshare-all -- "$@"
        return $?
      fi
      ;;
  esac

  if [[ "$SANDBOX_MODE" == "enforce" ]]; then
    _sbx_log_error "Sandbox requested but no sandbox tool available"
    return 1
  fi

  _sbx_log_warn "Sandbox tool not available; running unsandboxed: $*"
  "$@"
}

export -f sandbox_available
export -f sandbox_exec
