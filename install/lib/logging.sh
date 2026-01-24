#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# logging.sh - Structured logging system with rotation and JSON support

LOG_DIR="${LOG_DIR:-/var/log/anthonyware-install}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR
LOG_FORMAT="${LOG_FORMAT:-text}"  # text or json
TIMESTAMP=$(date '+%Y-%m-%d-%H-%M-%S')

# Pre-initialize log files to avoid unbound variable errors
MAIN_LOG="${LOG_DIR}/install-${TIMESTAMP}.log"
ERROR_LOG="${LOG_DIR}/errors.log"
CURRENT_SCRIPT_LOG=""

# ANSI color codes
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_GRAY='\033[0;90m'

# Initialize logging
log_init() {
  mkdir -p "$LOG_DIR"
  export MAIN_LOG
  export ERROR_LOG
  export CURRENT_SCRIPT_LOG
  
  log_info "Logging initialized"
  log_info "Main log: $MAIN_LOG"
  log_info "Error log: $ERROR_LOG"
}

# Set current script context
log_set_script() {
  local script_name="$1"
  export CURRENT_SCRIPT_LOG="${LOG_DIR}/${script_name}.log"
  log_info "Starting script: $script_name"
}

# Internal logging function
_log() {
  local level="$1"
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local script_name="${CURRENT_SCRIPT:-main}"
  
  # Check log level
  case "$LOG_LEVEL" in
    DEBUG) ;;
    INFO) [[ "$level" == "DEBUG" ]] && return ;;
    WARN) [[ "$level" =~ ^(DEBUG|INFO)$ ]] && return ;;
    ERROR) [[ "$level" != "ERROR" ]] && return ;;
  esac
  
  # Format message
  if [[ "$LOG_FORMAT" == "json" ]]; then
    local log_entry=$(jq -n \
      --arg ts "$timestamp" \
      --arg lvl "$level" \
      --arg scr "$script_name" \
      --arg msg "$message" \
      '{timestamp: $ts, level: $lvl, script: $scr, message: $msg}')
    echo "$log_entry" >> "$MAIN_LOG"
  else
    echo "[$timestamp] [$level] [$script_name] $message" >> "$MAIN_LOG"
  fi
  
  # Also write to script-specific log if set
  if [[ -n "$CURRENT_SCRIPT_LOG" ]]; then
    echo "[$timestamp] [$level] $message" >> "$CURRENT_SCRIPT_LOG"
  fi
  
  # Write errors to error log
  if [[ "$level" == "ERROR" ]]; then
    echo "[$timestamp] [$script_name] $message" >> "$ERROR_LOG"
  fi
  
  # Console output with colors (if terminal supports it)
  if [[ -t 1 ]]; then
    case "$level" in
      DEBUG) echo -e "${COLOR_GRAY}[DEBUG] $message${COLOR_RESET}" ;;
      INFO)  echo -e "${COLOR_BLUE}[INFO] $message${COLOR_RESET}" ;;
      WARN)  echo -e "${COLOR_YELLOW}[WARN] $message${COLOR_RESET}" ;;
      ERROR) echo -e "${COLOR_RED}[ERROR] $message${COLOR_RESET}" >&2 ;;
    esac
  else
    echo "[$level] $message"
  fi
}

# Public logging functions
log_debug() { _log "DEBUG" "$@"; }
log_info() { _log "INFO" "$@"; }
log_warn() { _log "WARN" "$@"; }
log_error() { _log "ERROR" "$@"; }

# Success/failure markers
log_success() {
  if [[ -t 1 ]]; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} $*"
  else
    echo "✓ $*"
  fi
  log_info "SUCCESS: $*"
}

log_failure() {
  if [[ -t 1 ]]; then
    echo -e "${COLOR_RED}✗${COLOR_RESET} $*" >&2
  else
    echo "✗ $*" >&2
  fi
  log_error "FAILURE: $*"
}

# Rotate old logs (keep last 10)
log_rotate() {
  local max_logs=10
  cd "$LOG_DIR" || return
  ls -t install-*.log 2>/dev/null | tail -n +$((max_logs + 1)) | xargs -r rm -f
  log_info "Log rotation complete"
}

# Export functions
export -f log_init
export -f log_set_script
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_success
export -f log_failure
export -f log_rotate
export -f _log
