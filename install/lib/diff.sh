#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# diff.sh - Dry-run diff and idempotence validation

DIFF_MODE="${DIFF_MODE:-0}"
DIFF_OUTPUT="${DIFF_OUTPUT:-${LOG_DIR:-/tmp}/install-diff.txt}"

_diff_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }

# Capture system state for comparison
diff_capture_state() {
  local output_file="$1"
  
  _diff_log_info "Capturing system state to $output_file..."
  
  {
    echo "=== Installed Packages ==="
    pacman -Q 2>/dev/null || true
    echo
    
    echo "=== Enabled Services ==="
    systemctl list-unit-files --state=enabled 2>/dev/null || true
    echo
    
    echo "=== Users ==="
    cut -d: -f1 /etc/passwd || true
    echo
    
    echo "=== Groups ==="
    cut -d: -f1 /etc/group || true
    echo
    
    echo "=== Config Files (checksums) ==="
    find /etc -type f -name "*.conf" -exec md5sum {} \; 2>/dev/null || true
    echo
    
    echo "=== File System ==="
    df -h || true
    echo
  } > "$output_file"
  
  _diff_log_info "State captured: $output_file"
}

# Compare two state snapshots
diff_compare_states() {
  local before="$1"
  local after="$2"
  local output="${3:-${DIFF_OUTPUT}}"
  
  _diff_log_info "Comparing states: $before vs $after"
  
  if [[ ! -f "$before" || ! -f "$after" ]]; then
    _diff_log_info "Missing state files for comparison"
    return 1
  fi
  
  diff -u "$before" "$after" > "$output" 2>&1 || true
  
  if [[ -s "$output" ]]; then
    _diff_log_info "Changes detected (see $output)"
    return 0
  else
    _diff_log_info "No changes detected - installation is idempotent"
    return 0
  fi
}

# Run idempotence test (run install twice, compare state)
diff_test_idempotence() {
  local script="$1"
  
  _diff_log_info "Testing idempotence for $script..."
  
  local state_before="/tmp/state-before-$$.txt"
  local state_middle="/tmp/state-middle-$$.txt"
  local state_after="/tmp/state-after-$$.txt"
  
  # Capture initial state
  diff_capture_state "$state_before"
  
  # Run first time
  _diff_log_info "First run..."
  bash "$script" || true
  
  # Capture middle state
  diff_capture_state "$state_middle"
  
  # Run second time
  _diff_log_info "Second run (should be idempotent)..."
  bash "$script" || true
  
  # Capture final state
  diff_capture_state "$state_after"
  
  # Compare middle and after (should be identical)
  local diff_output="/tmp/idempotence-diff-$$.txt"
  diff_compare_states "$state_middle" "$state_after" "$diff_output"
  
  if [[ -s "$diff_output" ]]; then
    _diff_log_info "WARNING: Script is not idempotent - see $diff_output"
    cat "$diff_output"
    return 1
  else
    _diff_log_info "Script is idempotent ✓"
    return 0
  fi
}

# Generate human-readable diff report
diff_generate_report() {
  local diff_file="$1"
  local report_file="${2:-${diff_file%.txt}-report.html}"
  
  if [[ ! -f "$diff_file" ]]; then
    _diff_log_info "No diff file found: $diff_file"
    return 1
  fi
  
  _diff_log_info "Generating diff report: $report_file"
  
  cat > "$report_file" <<'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Installation Diff Report</title>
  <style>
    body { font-family: monospace; margin: 20px; }
    .added { background: #d4edda; color: #155724; }
    .removed { background: #f8d7da; color: #721c24; }
    .context { color: #666; }
  </style>
</head>
<body>
  <h1>Installation Diff Report</h1>
  <pre>
EOF
  
  # Convert diff to HTML with colors
  while IFS= read -r line; do
    if [[ "$line" =~ ^\+ ]]; then
      echo "<span class='added'>$line</span>" >> "$report_file"
    elif [[ "$line" =~ ^\- ]]; then
      echo "<span class='removed'>$line</span>" >> "$report_file"
    else
      echo "<span class='context'>$line</span>" >> "$report_file"
    fi
  done < "$diff_file"
  
  cat >> "$report_file" <<'EOF'
  </pre>
</body>
</html>
EOF
  
  _diff_log_info "Report generated: $report_file"
}

export -f diff_capture_state
export -f diff_compare_states
export -f diff_test_idempotence
export -f diff_generate_report
