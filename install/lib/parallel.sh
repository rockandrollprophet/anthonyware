#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# parallel.sh - Parallel execution helpers for independent stages

PARALLEL_JOBS="${PARALLEL_JOBS:-4}"
ENABLE_PARALLEL="${ENABLE_PARALLEL:-0}"  # Opt-in for safety

_parallel_log_info(){ if command -v log_info >/dev/null 2>&1; then log_info "$@"; else echo "[INFO] $*"; fi; }
_parallel_log_warn(){ if command -v log_warn >/dev/null 2>&1; then log_warn "$@"; else echo "[WARN] $*"; fi; }

# Run scripts in parallel if they're independent
# Usage: parallel_run_batch script1.sh script2.sh script3.sh
parallel_run_batch() {
  [[ "$ENABLE_PARALLEL" != "1" ]] && {
    # Fallback to sequential
    for script in "$@"; do
      bash "$script" || return 1
    done
    return 0
  }
  
  local scripts=("$@")
  local pids=()
  local failed=0
  
  _parallel_log_info "Running ${#scripts[@]} scripts in parallel (max $PARALLEL_JOBS jobs)"
  
  # Launch scripts with job control
  for script in "${scripts[@]}"; do
    # Wait if we've hit max parallel jobs
    while [[ ${#pids[@]} -ge $PARALLEL_JOBS ]]; do
      for i in "${!pids[@]}"; do
        if ! kill -0 "${pids[$i]}" 2>/dev/null; then
          wait "${pids[$i]}" || ((failed++))
          unset "pids[$i]"
        fi
      done
      pids=("${pids[@]}")  # Reindex array
      sleep 0.1
    done
    
    # Launch script in background
    bash "$script" &
    pids+=($!)
  done
  
  # Wait for remaining jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || ((failed++))
  done
  
  if [[ $failed -gt 0 ]]; then
    _parallel_log_warn "$failed script(s) failed in parallel batch"
    return 1
  fi
  
  _parallel_log_info "Parallel batch completed successfully"
  return 0
}

# Identify independent script groups that can run in parallel
# Returns groups separated by semicolons
parallel_identify_groups() {
  # Conservative grouping: only fonts/portals/firmware can run together safely
  # Most install scripts have dependencies or shared resources
  
  local safe_parallel_groups=(
    "13-fonts.sh,16-firmware.sh,26-archive-tools.sh"
    "23-terminal-qol.sh,25-color-management.sh,28-audio-routing.sh"
  )
  
  for group in "${safe_parallel_groups[@]}"; do
    echo "$group"
  done
}

# Check if parallel execution is safe for current environment
parallel_is_safe() {
  # Disable parallel on:
  # - Low memory systems (< 4GB)
  # - Single core systems
  # - When running in containers
  
  local mem_kb
  mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local mem_gb=$((mem_kb / 1024 / 1024))
  
  if [[ $mem_gb -lt 4 ]]; then
    _parallel_log_warn "Low memory ($mem_gb GB), disabling parallel execution"
    return 1
  fi
  
  local cpu_count
  cpu_count=$(nproc)
  if [[ $cpu_count -lt 2 ]]; then
    _parallel_log_warn "Single CPU core, disabling parallel execution"
    return 1
  fi
  
  if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    _parallel_log_warn "Container detected, disabling parallel execution"
    return 1
  fi
  
  return 0
}

export -f parallel_run_batch
export -f parallel_identify_groups
export -f parallel_is_safe
