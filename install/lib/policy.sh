#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# policy.sh - Policy validation engine (must/should/forbid rules)

POLICY_MODE="${POLICY_MODE:-warn}"  # enforce|warn|skip
POLICY_DIR="${POLICY_DIR:-${REPO_PATH:-/root/anthonyware-setup/anthonyware}/policies}"

_policy_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_policy_log_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_policy_log_error(){ if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

# Policy rule format:
# MUST package_installed firefox "Firefox must be installed"
# SHOULD service_enabled sshd "SSH should be enabled for remote access"
# FORBID package_installed telnet "Telnet is forbidden for security"

policy_check_rule() {
  local severity="$1"  # MUST|SHOULD|FORBID
  local check_type="$2"
  local target="$3"
  local message="$4"
  
  local result=0
  
  case "$check_type" in
    package_installed)
      if pacman -Qq "$target" >/dev/null 2>&1; then
        result=1  # Package is installed
      fi
      ;;
    service_enabled)
      if systemctl is-enabled "$target" >/dev/null 2>&1; then
        result=1  # Service is enabled
      fi
      ;;
    file_exists)
      if [[ -f "$target" ]]; then
        result=1  # File exists
      fi
      ;;
    command_exists)
      if command -v "$target" >/dev/null 2>&1; then
        result=1  # Command exists
      fi
      ;;
    *)
      _policy_log_warn "Unknown check type: $check_type"
      return 0
      ;;
  esac
  
  # Evaluate policy
  case "$severity" in
    MUST)
      if [[ $result -eq 0 ]]; then
        _policy_log_error "POLICY VIOLATION (MUST): $message"
        return 1
      fi
      ;;
    SHOULD)
      if [[ $result -eq 0 ]]; then
        _policy_log_warn "POLICY WARNING (SHOULD): $message"
      fi
      ;;
    FORBID)
      if [[ $result -eq 1 ]]; then
        _policy_log_error "POLICY VIOLATION (FORBID): $message"
        return 1
      fi
      ;;
  esac
  
  return 0
}

# Load and validate policy file
policy_validate_file() {
  local policy_file="$1"
  
  if [[ ! -f "$policy_file" ]]; then
    _policy_log_warn "Policy file not found: $policy_file"
    return 0
  fi
  
  _policy_log_info "Validating policy: $policy_file"
  
  local violations=0
  local warnings=0
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue
    
    # Parse policy rule
    if [[ "$line" =~ ^(MUST|SHOULD|FORBID)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+"(.+)"$ ]]; then
      local severity="${BASH_REMATCH[1]}"
      local check_type="${BASH_REMATCH[2]}"
      local target="${BASH_REMATCH[3]}"
      local message="${BASH_REMATCH[4]}"
      
      if ! policy_check_rule "$severity" "$check_type" "$target" "$message"; then
        if [[ "$severity" == "MUST" || "$severity" == "FORBID" ]]; then
          ((violations++))
        else
          ((warnings++))
        fi
      fi
    fi
  done < "$policy_file"
  
  if [[ $violations -gt 0 ]]; then
    _policy_log_error "Policy validation failed: $violations violation(s)"
    if [[ "$POLICY_MODE" == "enforce" ]]; then
      return 1
    fi
  fi
  
  if [[ $warnings -gt 0 ]]; then
    _policy_log_warn "Policy validation completed with $warnings warning(s)"
  else
    _policy_log_info "Policy validation passed"
  fi
  
  return 0
}

# Validate all policies in directory
policy_validate_all() {
  [[ "$POLICY_MODE" == "skip" ]] && return 0
  
  if [[ ! -d "$POLICY_DIR" ]]; then
    _policy_log_info "No policy directory found, skipping policy validation"
    return 0
  fi
  
  _policy_log_info "Validating all policies in $POLICY_DIR"
  
  local failed=0
  while IFS= read -r policy_file; do
    if ! policy_validate_file "$policy_file"; then
      ((failed++))
    fi
  done < <(find "$POLICY_DIR" -name "*.policy" -type f 2>/dev/null)
  
  if [[ $failed -gt 0 ]]; then
    _policy_log_error "Policy validation failed for $failed file(s)"
    [[ "$POLICY_MODE" == "enforce" ]] && return 1
  fi
  
  return 0
}

export -f policy_check_rule
export -f policy_validate_file
export -f policy_validate_all
