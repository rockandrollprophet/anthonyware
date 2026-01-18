#!/usr/bin/env bash# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts# secrets.sh - Helpers for loading and masking secrets

SECRETS_FILE=${SECRETS_FILE:-"${HOME}/.config/anthonyware/secrets.env"}
SECRETS_MODE=${SECRETS_MODE:-optional}   # optional|enforce

_secrets_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_secrets_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_secrets_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

# Load secrets from an env file; supports sops if available
secrets_load_env() {
  local file="${1:-$SECRETS_FILE}"
  if [[ ! -f "$file" ]]; then
    if [[ "$SECRETS_MODE" == "enforce" ]]; then
      _secrets_log_error "Secrets file required but missing: $file"
      return 1
    fi
    _secrets_log_warn "Secrets file not found (optional): $file"
    return 0
  fi

  local tmp="$file"
  if command -v sops >/dev/null 2>&1 && [[ "$file" == *.enc ]]; then
    tmp=$(mktemp)
    if ! sops -d "$file" > "$tmp"; then
      _secrets_log_error "Failed to decrypt secrets file: $file"
      rm -f "$tmp"
      return 1
    fi
  fi

  set -o allexport
  # shellcheck disable=SC1090
  source "$tmp"
  set +o allexport

  [[ "$tmp" != "$file" ]] && rm -f "$tmp"
  _secrets_log_info "Secrets loaded from $file"
}

# Mask a value in a string (best-effort)
secrets_mask_value() {
  local value="$1"
  local replacement="${2:-***}"
  if [[ -z "$value" ]]; then
    cat
    return 0
  fi
  sed "s/${value//\//\\/}/${replacement//\//\\/}/g"
}

export -f secrets_load_env
export -f secrets_mask_value
