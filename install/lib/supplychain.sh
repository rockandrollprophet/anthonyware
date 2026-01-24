#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# supplychain.sh - Basic supply-chain safeguards

_schain_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_schain_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_schain_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

verify_checksum() {
  local file="$1"
  local expected="$2"
  if [[ ! -f "$file" ]]; then
    _schain_log_error "File not found for checksum: $file"
    return 1
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    local got
    got=$(sha256sum "$file" | awk '{print $1}')
    if [[ "$got" == "$expected" ]]; then
      _schain_log_info "Checksum OK for $file"
      return 0
    else
      _schain_log_error "Checksum mismatch for $file"
      return 1
    fi
  fi
  _schain_log_warn "sha256sum not available; skipping checksum for $file"
  return 0
}

verify_signature() {
  local file="$1"
  local sig="$2"
  local keyring="${3:-}"
  if [[ ! -f "$file" || ! -f "$sig" ]]; then
    _schain_log_error "File or signature missing for verification"
    return 1
  fi
  if ! command -v gpg >/dev/null 2>&1; then
    _schain_log_warn "gpg not available; skipping signature verification"
    return 0
  fi
  local cmd=(gpg --verify "$sig" "$file")
  if [[ -n "$keyring" ]]; then
    cmd=(gpg --no-default-keyring --keyring "$keyring" --verify "$sig" "$file")
  fi
  if "${cmd[@]}" >/dev/null 2>&1; then
    _schain_log_info "Signature OK for $file"
    return 0
  else
    _schain_log_error "Signature verification failed for $file"
    return 1
  fi
}

export -f verify_checksum
export -f verify_signature
