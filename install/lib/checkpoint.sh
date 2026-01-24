#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# checkpoint.sh - Checkpoint and resume system for installation pipeline

CHECKPOINT_DIR="${CHECKPOINT_DIR:-/var/log/anthonyware-install}"
CHECKPOINT_FILE="${CHECKPOINT_DIR}/completed-scripts.log"
FAILED_FILE="${CHECKPOINT_DIR}/failed-scripts.log"
SKIP_FILE="${CHECKPOINT_DIR}/skipped-scripts.log"

# Initialize checkpoint system
checkpoint_init() {
  mkdir -p "$CHECKPOINT_DIR"
  touch "$CHECKPOINT_FILE" "$FAILED_FILE" "$SKIP_FILE"
}

# Mark script as completed
checkpoint_complete() {
  local script_name="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | COMPLETED | $script_name" >> "$CHECKPOINT_FILE"
}

# Mark script as failed
checkpoint_failed() {
  local script_name="$1"
  local error_code="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | FAILED | $script_name | exit_code=$error_code" >> "$FAILED_FILE"
}

# Mark script as skipped
checkpoint_skipped() {
  local script_name="$1"
  local reason="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') | SKIPPED | $script_name | reason=$reason" >> "$SKIP_FILE"
}

# Check if script already completed
checkpoint_is_completed() {
  local script_name="$1"
  grep -q "| COMPLETED | $script_name" "$CHECKPOINT_FILE" 2>/dev/null
}

# Get list of completed scripts
checkpoint_list_completed() {
  [[ -f "$CHECKPOINT_FILE" ]] && cat "$CHECKPOINT_FILE"
}

# Get list of failed scripts
checkpoint_list_failed() {
  [[ -f "$FAILED_FILE" ]] && cat "$FAILED_FILE"
}

# Reset checkpoint (start fresh)
checkpoint_reset() {
  rm -f "$CHECKPOINT_FILE" "$FAILED_FILE" "$SKIP_FILE"
  checkpoint_init
}

# Get progress stats
checkpoint_stats() {
  local total_scripts="${1:-44}"
  local completed=$(grep -c "COMPLETED" "$CHECKPOINT_FILE" 2>/dev/null || echo 0)
  local failed=$(grep -c "FAILED" "$FAILED_FILE" 2>/dev/null || echo 0)
  local skipped=$(grep -c "SKIPPED" "$SKIP_FILE" 2>/dev/null || echo 0)
  local remaining=$((total_scripts - completed - failed - skipped))
  
  cat <<EOF
Progress Statistics:
  Completed: $completed/$total_scripts
  Failed: $failed
  Skipped: $skipped
  Remaining: $remaining
EOF
}

# Export functions
export -f checkpoint_init
export -f checkpoint_complete
export -f checkpoint_failed
export -f checkpoint_skipped
export -f checkpoint_is_completed
export -f checkpoint_list_completed
export -f checkpoint_list_failed
export -f checkpoint_reset
export -f checkpoint_stats
