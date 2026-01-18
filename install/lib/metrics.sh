#!/usr/bin/env bash# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts# metrics.sh - JSONL metrics and timeline logging

METRICS_DIR=${METRICS_DIR:-"${LOG_DIR:-/var/log/anthonyware-install}/metrics"}
METRICS_FILE="${METRICS_DIR}/metrics.jsonl"
TIMELINE_FILE="${METRICS_DIR}/timeline.jsonl"

_metrics_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }

metrics_init() {
  mkdir -p "$METRICS_DIR"
  : > "$METRICS_FILE"
  : > "$TIMELINE_FILE"
  _metrics_log_info "Metrics initialized at $METRICS_DIR"
}

metrics_event() {
  # metrics_event status script duration_seconds
  local status="$1" script="$2" duration="$3"
  local ts=$(date -Iseconds)
  echo "{\"ts\":\"$ts\",\"status\":\"$status\",\"script\":\"$script\",\"duration_s\":$duration}" >> "$METRICS_FILE"
}

timeline_write() {
  # timeline_write type script message extra
  local type="$1" script="$2" msg="$3" extra="$4"
  local ts=$(date -Iseconds)
  echo "{\"ts\":\"$ts\",\"type\":\"$type\",\"script\":\"$script\",\"msg\":\"$msg\",\"extra\":\"$extra\"}" >> "$TIMELINE_FILE"
}

metrics_summary() {
  # Emits a simple summary to stdout
  if [[ ! -f "$METRICS_FILE" ]]; then
    echo "No metrics captured"; return 0; fi
  local total completed failed
  total=$(wc -l < "$METRICS_FILE" 2>/dev/null || echo 0)
  completed=$(grep -c '"status":"success"' "$METRICS_FILE" 2>/dev/null || echo 0)
  failed=$(grep -c '"status":"fail"' "$METRICS_FILE" 2>/dev/null || echo 0)
  echo "Metrics: total=$total completed=$completed failed=$failed"
}

export -f metrics_init
export -f metrics_event
export -f timeline_write
export -f metrics_summary
