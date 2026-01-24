#!/usr/bin/env bash# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts# repro.sh - Reproducibility helpers (SBOM, provenance, templating)

REPRO_SOURCES_DIR=${REPRO_SOURCES_DIR:-"/usr/share/licenses"}
REPRO_SNAPSHOT_DIR=${REPRO_SNAPSHOT_DIR:-"/var/log/anthonyware-install/repro"}

_repro_log_info()  { if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_repro_log_warn()  { if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }
_repro_log_error() { if command -v log_error >/dev/null 2>&1; then log_error "$@"; else echo "[ERROR] $*"; fi; }

# Generate simple SBOM (package lists) into a directory
repro_generate_sbom() {
  local out_dir="${1:-$REPRO_SNAPSHOT_DIR}"
  mkdir -p "$out_dir"

  if command -v pacman >/dev/null 2>&1; then
    pacman -Q > "$out_dir/pacman-packages.txt" 2>/dev/null || true
  fi
  if command -v yay >/dev/null 2>&1; then
    yay -Q > "$out_dir/aur-packages.txt" 2>/dev/null || true
  fi
  if command -v pip >/dev/null 2>&1; then
    pip list --format=freeze > "$out_dir/pip-packages.txt" 2>/dev/null || true
  fi
  if command -v npm >/dev/null 2>&1; then
    npm list --global --depth=0 > "$out_dir/npm-packages.txt" 2>/dev/null || true
  fi

  _repro_log_info "SBOM package manifests written to $out_dir"
}

# Capture provenance: git commit, profile, hardware hash
repro_capture_provenance() {
  local out_file="${1:-$REPRO_SNAPSHOT_DIR/provenance.txt}"
  mkdir -p "$(dirname "$out_file")"

  {
    echo "timestamp=$(date -Iseconds)"
    if command -v git >/dev/null 2>&1; then
      echo "git_commit=$(git -C "${REPO_PATH:-.}" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    fi
    echo "profile=${PROFILE:-unknown}"
    echo "user=${TARGET_USER:-unknown}"
    echo "hostname=$(hostname 2>/dev/null || echo unknown)"
    if command -v hardware_report >/dev/null 2>&1; then
      echo "hardware_hash=$(hardware_report 2>/dev/null | sha256sum | awk '{print $1}')"
    fi
  } > "$out_file"

  _repro_log_info "Provenance captured at $out_file"
}

# Render template with envsubst if available, fallback to simple var replace
repro_render_template() {
  local src="$1" dest="$2"
  if [[ ! -f "$src" ]]; then
    _repro_log_error "Template not found: $src"
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  if command -v envsubst >/dev/null 2>&1; then
    envsubst < "$src" > "$dest"
  else
    # Minimal fallback: copy as-is
    cp "$src" "$dest"
  fi
  _repro_log_info "Rendered template $src -> $dest"
}

export -f repro_generate_sbom
export -f repro_capture_provenance
export -f repro_render_template
