#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
# SC1090/SC1091: Dynamic source paths are intentional

# ============================================================
#  Anthonyware OS 1.0 — Installation Pipeline Orchestrator
#
#  Enhanced with:
#    - Checkpoint & Resume System
#    - Hardware Detection & Optimization
#    - Structured Logging with Colors
#    - Network Resilience & Retry Logic
#    - Config Backup & Validation
#    - Interactive Component Selection
#    - Profile-Based Installation
#    - Post-Install Report Generation
# ============================================================

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Essential libraries that must load first
CRITICAL_LIBS=("logging.sh" "safety.sh" "ux.sh" "checkpoint.sh")

# Load critical libraries with validation
for lib_name in "${CRITICAL_LIBS[@]}"; do
  lib_path="${LIB_DIR}/${lib_name}"
  if [[ ! -f "$lib_path" ]]; then
    echo "FATAL ERROR: Critical library missing: $lib_name"
    echo "Expected at: $lib_path"
    exit 1
  fi
  
  # shellcheck disable=SC1090
  if ! source "$lib_path"; then
    echo "FATAL ERROR: Failed to source critical library: $lib_name"
    exit 1
  fi
  
  # Verify key functions are defined
  case "$lib_name" in
    logging.sh)
      if ! command -v log_init >/dev/null 2>&1; then
        echo "FATAL ERROR: logging.sh did not define log_init function"
        exit 1
      fi
      ;;
    safety.sh)
      if ! command -v safety_check_all >/dev/null 2>&1; then
        echo "FATAL ERROR: safety.sh did not define safety_check_all function"
        exit 1
      fi
      ;;
    ux.sh)
      if ! command -v ux_header >/dev/null 2>&1; then
        echo "FATAL ERROR: ux.sh did not define ux_header function"
        exit 1
      fi
      ;;
    checkpoint.sh)
      if ! command -v checkpoint_init >/dev/null 2>&1; then
        echo "FATAL ERROR: checkpoint.sh did not define checkpoint_init function"
        exit 1
      fi
      ;;
  esac
done

# Source remaining library modules
for lib in "$LIB_DIR"/*.sh; do
  if [[ -f "$lib" ]]; then
    lib_name=$(basename "$lib")
    # Skip already-loaded critical libs
    if [[ " ${CRITICAL_LIBS[*]} " =~ " ${lib_name} " ]]; then
      continue
    fi
    
    # shellcheck disable=SC1090
    if ! source "$lib"; then
      echo "WARNING: Failed to source library: $lib_name"
      echo "Continuing, but some features may be unavailable"
    fi
  fi
done

# Initialize cache if enabled
if command -v cache_init >/dev/null 2>&1; then
  cache_init
fi

# Safety toggles
# - Set DRY_RUN=1 to preview steps without executing
# - Set SAFE_MODE=1 to skip risky/non-essential steps automatically
# - Set CONFIRM_INSTALL=YES to proceed beyond guardrails
# - Optionally set SKIP_STEPS to a comma-separated list of scripts to skip
# - Set PROFILE to use a predefined profile (minimal, developer, workstation, gamer, homelab, full)
# - Set INTERACTIVE=1 to enable interactive component selection
DRY_RUN="${DRY_RUN:-0}"
SAFE_MODE="${SAFE_MODE:-0}"
CONFIRM_INSTALL="${CONFIRM_INSTALL:-}"
SKIP_STEPS_RAW="${SKIP_STEPS:-}"
CREATE_SNAPSHOT="${CREATE_SNAPSHOT:-1}"
PROFILE="${PROFILE:-}"
INTERACTIVE="${INTERACTIVE:-0}"
ENABLE_SNAPSHOTS="${ENABLE_SNAPSHOTS:-0}"   # 1 to enable btrfs snapshot per-script
ROLLBACK_ON_FAIL="${ROLLBACK_ON_FAIL:-1}"    # 1 to rollback from last snapshot if a script fails
SELF_TEST="${SELF_TEST:-0}"                  # 1 to run tests/self-test.sh before install
POSTURE_MODE="${POSTURE_MODE:-warn}"          # enforce|warn|skip
SANDBOX_MODE="${SANDBOX_MODE:-optional}"      # optional|enforce|off
SANDBOX_TOOL="${SANDBOX_TOOL:-auto}"          # auto|firejail|bwrap|none
REPRO_SNAPSHOT_DIR="${REPRO_SNAPSHOT_DIR:-${LOG_DIR:-/var/log/anthonyware-install}/repro}"
METRICS_DIR="${METRICS_DIR:-${LOG_DIR:-/var/log/anthonyware-install}/metrics}"
TUI_MODE="${TUI_MODE:-auto}"
ENABLE_CACHE="${ENABLE_CACHE:-1}"
ENABLE_PARALLEL="${ENABLE_PARALLEL:-0}"
LEAN_MODE="${LEAN_MODE:-0}"
POLICY_MODE="${POLICY_MODE:-warn}"
ENABLE_PLUGINS="${ENABLE_PLUGINS:-1}"
export DRY_RUN SAFE_MODE CONFIRM_INSTALL SKIP_STEPS_RAW CREATE_SNAPSHOT PROFILE INTERACTIVE
export ENABLE_SNAPSHOTS ROLLBACK_ON_FAIL SELF_TEST
export POSTURE_MODE SANDBOX_MODE SANDBOX_TOOL
export REPRO_SNAPSHOT_DIR
export METRICS_DIR TUI_MODE
export ENABLE_CACHE ENABLE_PARALLEL LEAN_MODE POLICY_MODE ENABLE_PLUGINS

# Ensure TARGET_USER and TARGET_HOME are set
if [[ -z "${TARGET_USER:-}" ]]; then
  TARGET_USER="${SUDO_USER:-${USER}}"
  export TARGET_USER
fi

if [[ -z "${TARGET_HOME:-}" ]]; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  export TARGET_HOME
fi

# Repo path for config deployment
if [[ -z "${REPO_PATH:-}" ]]; then
  if [[ -d "${TARGET_HOME}/anthonyware" ]]; then
    REPO_PATH="${TARGET_HOME}/anthonyware"
  elif [[ -d "/root/anthonyware-setup/anthonyware" ]]; then
    REPO_PATH="/root/anthonyware-setup/anthonyware"
  else
    REPO_PATH="${TARGET_HOME}/anthonyware"  # fallback
  fi
  export REPO_PATH
fi

# Log directory - use /var/log for system installs, user home for user installs
if [[ "${EUID}" -eq 0 ]] && [[ ! -d "${TARGET_HOME}" ]]; then
  # Running as root and user home doesn't exist yet - use system location
  LOG_DIR="/var/log/anthonyware-install"
elif [[ -d "${TARGET_HOME}" ]]; then
  LOG_DIR="${TARGET_HOME}/anthonyware-logs"
else
  LOG_DIR="/tmp/anthonyware-logs"
fi
mkdir -p "$LOG_DIR"
export LOG_DIR
  GUIDED_REMEDIATION_FILE="$LOG_DIR/guided-remediation.txt"

# Initialize logging system
log_init
log_info "Anthonyware OS Installation Pipeline Starting"

# Initialize UX system
ux_progress_init
ux_header "Anthonyware OS v2.0 Installation"

# Initialize metrics
if command -v metrics_init >/dev/null 2>&1; then
  metrics_init
fi

# Initialize checkpoint system
checkpoint_init || { log_error "Checkpoint system initialization failed"; exit 1; }
log_info "Checkpoint system initialized"

# Prefetch package metadata in cache
if [[ "$ENABLE_CACHE" == "1" ]] && command -v cache_prefetch_pacman >/dev/null 2>&1; then
  cache_prefetch_pacman &
  CACHE_PID=$!
fi

# Hardware detection
log_info "Detecting hardware..."
hardware_report | tee -a "$LOG_DIR/hardware-report.txt"
DETECTED_GPU=$(detect_gpu)
DETECTED_CPU=$(detect_cpu)
log_info "GPU: $DETECTED_GPU | CPU: $DETECTED_CPU"

# Guard: refuse to run on live ISO environments
if [[ -d /run/archiso || -f /etc/archlive ]]; then
  log_error "Detected live ISO environment (/run/archiso present). Aborting to avoid installing to the live medium."
  echo ""
  ux_error "Cannot install from live ISO environment"
  echo ""
  echo "CORRECT PROCEDURE:"
  echo "  1. Boot into your INSTALLED Arch Linux system"
  echo "  2. Clone the anthonyware repository"
  echo "  3. Run this installer from the installed system"
  echo ""
  echo "If you haven't installed Arch yet:"
  echo "  • Follow the Arch Installation Guide first"
  echo "  • Install base system to your hard drive"
  echo "  • Boot into it, then run this installer"
  echo ""
  exit 3
fi

# Run comprehensive safety checks (network, disk space, pacman lock, etc.)
if ! safety_check_all; then
  log_error "Safety checks failed. Cannot proceed with installation."
  ux_show_troubleshooting
  exit 3
fi

# Health checks (battery can be bypassed with HEALTH_IGNORE_BATTERY=1 or HEALTH_SKIP_ALL=1)
if ! health_check_all; then
  log_error "Health checks failed. Set HEALTH_IGNORE_BATTERY=1 to bypass battery gating or HEALTH_SKIP_ALL=1 to skip all health checks."
  exit 3
fi

# Posture checks (light hardening validation)
if command -v posture_check_all >/dev/null 2>&1; then
  if ! posture_check_all; then
    log_warn "Posture checks reported issues. Set POSTURE_MODE=skip to bypass, or POSTURE_MODE=warn to continue." 
    if [[ "$POSTURE_MODE" == "enforce" ]]; then
      exit 3
    fi
  fi
fi

# Optional self-test harness
if [[ "$SELF_TEST" == "1" ]]; then
  if [[ -x "${REPO_PATH}/scripts/self-test.sh" ]]; then
    log_info "Running self-test harness..."
    if ! bash "${REPO_PATH}/scripts/self-test.sh"; then
      log_warn "Self-test reported failures; continuing installation"
    else
      log_success "Self-test completed"
    fi
  else
    log_warn "self-test harness not found at scripts/self-test.sh"
  fi
fi

# Policy validation
if command -v policy_validate_all >/dev/null 2>&1; then
  if ! policy_validate_all; then
    log_warn "Policy validation reported violations. Set POLICY_MODE=skip to bypass."
    if [[ "$POLICY_MODE" == "enforce" ]]; then
      exit 3
    fi
  fi
fi

# Guard: ensure target home and repo exist (or will be accessible)
if [[ ! -d "$TARGET_HOME" ]]; then
  log_warn "Target home '$TARGET_HOME' not found."
  log_info "This is expected if running before user creation."
  log_info "User configs will be deployed once user home exists."
fi

if [[ ! -d "$REPO_PATH" ]]; then
  log_warn "Repository path '$REPO_PATH' not found."
  log_info "Checked: $REPO_PATH"
  if [[ -d "/root/anthonyware-setup/anthonyware" ]]; then
    REPO_PATH="/root/anthonyware-setup/anthonyware"
    export REPO_PATH
    log_info "Using fallback: $REPO_PATH"
  else
    log_error "Cannot locate anthonyware repository. Aborting."
    exit 3
  fi
fi

# Interactive mode: profile and component selection
if [[ "$INTERACTIVE" == "1" ]] || [[ -z "$PROFILE" && -t 0 ]]; then
  log_info "Interactive mode enabled"
  PROFILE=$(select_profile)
  if [[ -z "$PROFILE" ]]; then
    log_warn "Profile selection cancelled, using full installation"
    PROFILE="full"
  fi
  if [[ "$PROFILE" == "custom" ]]; then
    CUSTOM_COMPONENTS=$(select_custom_components)
  fi
fi

# Set default profile if not specified
PROFILE="${PROFILE:-full}"

# Show installation plan to user
ux_show_plan "$PROFILE" "38"

# Request confirmation unless auto-confirmed
if [[ "$CONFIRM_INSTALL" != "YES" ]] && [[ -t 0 ]]; then
  if ! ux_confirm_install "$PROFILE"; then
    echo "Installation cancelled by user"
    exit 0
  fi
fi

# Preflight: pacman lock cleanup (best-effort, only if no pacman process)
if [[ -e /var/lib/pacman/db.lck ]]; then
  if ! pgrep -x pacman >/dev/null 2>&1; then
    log_info "Removing stale pacman lock /var/lib/pacman/db.lck"
    rm -f /var/lib/pacman/db.lck || true
  else
    log_error "pacman is running; lock present. Abort and rerun later."
    exit 3
  fi
fi

# Initialize backup system
backup_init
log_success "Backup system ready"

# Checkpoint file to track progress
CHECKPOINT_FILE="$LOG_DIR/installation-checkpoint.txt"
touch "$CHECKPOINT_FILE"

# Answers file: non-sensitive install parameters
ANSWERS_FILE_DEFAULT="$LOG_DIR/install-answers.env"
ANSWERS_FILE="${ANSWERS_FILE:-$ANSWERS_FILE_DEFAULT}"
export ANSWERS_FILE

# If an answers file exists, source it; else, collect inputs interactively
if [[ -f "$ANSWERS_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ANSWERS_FILE"
  export TARGET_USER TARGET_HOME REPO_PATH
else
  if [[ -x "${REPO_PATH}/scripts/collect-input.sh" ]]; then
    echo "[INFO] Collecting install inputs..." | tee -a "$LOG_DIR/run-all.log"
    bash "${REPO_PATH}/scripts/collect-input.sh" || true
    if [[ -f "$ANSWERS_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$ANSWERS_FILE"
      export TARGET_USER TARGET_HOME REPO_PATH
    fi
  fi
fi

# Error handler: run troubleshooting on failures and archive logs
on_error() {
  local exit_code=$?
  log_error "Pipeline failed with exit code ${exit_code}"
  log_failure "Installation failed - check logs for details"
  
  if [[ -x "${REPO_PATH}/scripts/troubleshoot-all.sh" ]]; then
    log_info "Running troubleshooting aggregator..."
    bash "${REPO_PATH}/scripts/troubleshoot-all.sh" || true
    local latest
    latest=$(ls -1t /tmp/anthonyware-troubleshoot-* 2>/dev/null | head -1 || true)
    if [[ -n "$latest" && -f "$latest" ]]; then
      cp -f "$latest" "$LOG_DIR/" || true
      log_info "Troubleshoot log copied: $latest"
    fi
  else
    log_warn "scripts/troubleshoot-all.sh not found; skipping auto-troubleshoot"
  fi
  
  # Generate error report
  generate_text_report "${TARGET_HOME}/anthonyware-install-FAILED.txt" 2>/dev/null || true
}

emit_guided_remediation() {
  local script_name="$1" log_path="$2"
  {
    echo "[Remediation] $script_name"
    echo "- Log: ${log_path:-not captured}"
    case "$script_name" in
      00-preflight-checks.sh)
        echo "- Verify network, disk space, and pacman mirrors (run preflight log)."
        ;;
      02-gpu-drivers.sh)
        echo "- Boot with nomodeset if black screen; check GPU model via lspci; rerun with SANDBOX_MODE=off if sandbox blocked drivers."
        ;;
      05-dev-tools.sh)
        echo "- Ensure Docker group exists and user added; retry after relog; check container runtime status."
        ;;
      09-security.sh)
        echo "- AppArmor/Firewalld may block services. Review /var/log/audit/audit.log and relax POSTURE_MODE=warn to continue."
        ;;
      11-vfio-windows-vm.sh)
        echo "- Confirm IOMMU enabled in BIOS; review lspci groups; set ROLLBACK_ON_FAIL=0 to inspect partial state."
        ;;
      *)
        echo "- Rerun the installer with DRY_RUN=1 to preview; tail the failing log for the root cause."
        ;;
    esac
    echo "- If health gating blocked progress, set HEALTH_IGNORE_BATTERY=1 (or HEALTH_SKIP_ALL=1) and rerun."
    echo "- To bypass sandbox issues, set SANDBOX_MODE=off."
    echo
  } >> "$GUIDED_REMEDIATION_FILE"
}

# Set trap after variables and paths are prepared
trap on_error ERR

log_info "Starting Anthonyware OS installation pipeline"
log_info "Target User: $TARGET_USER"
log_info "Target Home: $TARGET_HOME"
log_info "Repository: $REPO_PATH"
log_info "Dry Run: $DRY_RUN | Safe Mode: $SAFE_MODE"

# Load profile if specified
if [[ -n "$PROFILE" ]]; then
  PROFILE_FILE="${REPO_PATH}/profiles/${PROFILE}.conf"
  if [[ -f "$PROFILE_FILE" ]]; then
    log_info "Loading profile: $PROFILE"
    PROFILE_SCRIPTS=()
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "$line" ]] && continue
      if [[ "$line" =~ ^@include ]]; then
        # Handle includes
        local include_file="${line#@include }"
        if [[ -f "${REPO_PATH}/profiles/${include_file}" ]]; then
          while IFS= read -r inc_line; do
            [[ "$inc_line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$inc_line" ]] && continue
            PROFILE_SCRIPTS+=("$inc_line")
          done < "${REPO_PATH}/profiles/${include_file}"
        fi
      else
        PROFILE_SCRIPTS+=("$line")
      fi
    done < "$PROFILE_FILE"
    
    # Override default scripts list
    SCRIPTS=("${PROFILE_SCRIPTS[@]}")
    log_success "Profile loaded: ${#SCRIPTS[@]} scripts selected"
  else
    log_warn "Profile file not found: $PROFILE_FILE, using full installation"
  fi
fi

if [[ ${#SCRIPTS[@]} -eq 0 ]]; then
  SCRIPTS=(
    "00-preflight-checks.sh"
    "01-base-system.sh"
    "02-gpu-drivers.sh"
    "02-qt6-runtime.sh"
    "03-hyprland.sh"
    "04-daily-driver.sh"
    "05-dev-tools.sh"
    "06-ai-ml.sh"
    "07-cad-cnc-3dprinting.sh"
    "08-hardware-support.sh"
    "09-security.sh"
    "10-backups.sh"
    "10-webcam-media.sh"
    "11-vfio-windows-vm.sh"
    "12-printing.sh"
    "13-fonts.sh"
    "14-portals.sh"
    "15-power-management.sh"
    "16-firmware.sh"
    "17-steam.sh"
    "18-networking-tools.sh"
    "19-electrical-engineering.sh"
    "20-fpga-toolchain.sh"
    "21-instrumentation.sh"
    "22-homelab-tools.sh"
    "23-terminal-qol.sh"
    "25-color-management.sh"
    "26-archive-tools.sh"
    "27-zram-swap.sh"
    "28-audio-routing.sh"
    "29-misc-utilities.sh"
    "31-wayland-recording.sh"
    "32-latex-docs.sh"
    "33-user-configs.sh"
    "37-ops-diagnostics.sh"
    "24-cleanup-and-verify.sh"
    "30-finalize.sh"
    "34-diagnostics.sh"
    "35-validation.sh"
    "36-xwayland-legacy.sh"
    "99-update-everything.sh"
  )
fi

# Override with custom selection if requested
if [[ "$PROFILE" == "custom" ]]; then
  REQUIRED_CORE=(
    "00-preflight-checks.sh"
    "01-base-system.sh"
    "02-gpu-drivers.sh"
    "02-qt6-runtime.sh"
    "03-hyprland.sh"
    "14-portals.sh"
    "23-terminal-qol.sh"
    "24-cleanup-and-verify.sh"
    "30-finalize.sh"
    "34-diagnostics.sh"
    "35-validation.sh"
    "99-update-everything.sh"
  )
  SCRIPTS=("${REQUIRED_CORE[@]}")
  IFS=',' read -r -a custom_arr <<< "${CUSTOM_COMPONENTS:-}" || true
  for c in "${custom_arr[@]}"; do
    [[ -z "$c" ]] && continue
    SCRIPTS+=("$c")
  done
fi

# Apply lean mode skip list
if [[ "$LEAN_MODE" == "1" ]] && command -v lean_get_skip_list >/dev/null 2>&1; then
  LEAN_SKIP=$(lean_get_skip_list)
  if [[ -n "$LEAN_SKIP" ]]; then
    if [[ -n "$COMBINED_SKIP" ]]; then
      COMBINED_SKIP="${COMBINED_SKIP},${LEAN_SKIP}"
    else
      COMBINED_SKIP="$LEAN_SKIP"
    fi
    log_info "Lean mode enabled: additional scripts skipped"
  fi
fi

# Default risky/non-essential steps to skip in SAFE_MODE
DEFAULT_SAFE_SKIP=(
  "02-qt6-runtime.sh"
  "02-gpu-drivers.sh"
  "08-hardware-support.sh"
  "16-firmware.sh"
  "17-steam.sh"
  "20-fpga-toolchain.sh"
  "21-instrumentation.sh"
  "31-wayland-recording.sh"
  "35-fusion360-runtime.sh"
  "36-xwayland-legacy.sh"
)

join_csv() {
  local IFS=","; echo "$*"
}

INFERRED_SKIP=""
if [[ "$SAFE_MODE" == "1" ]]; then
  INFERRED_SKIP=$(join_csv "${DEFAULT_SAFE_SKIP[@]}")
fi

# Combine inferred skip list with user-provided SKIP_STEPS
COMBINED_SKIP=""
if [[ -n "$INFERRED_SKIP" && -n "$SKIP_STEPS_RAW" ]]; then
  COMBINED_SKIP="$INFERRED_SKIP,$SKIP_STEPS_RAW"
elif [[ -n "$INFERRED_SKIP" ]]; then
  COMBINED_SKIP="$INFERRED_SKIP"
else
  COMBINED_SKIP="$SKIP_STEPS_RAW"
fi

in_skip_list() {
  local target="$1"
  local list="$COMBINED_SKIP"
  [[ -z "$list" ]] && return 1
  IFS="," read -r -a items <<< "$list"
  for it in "${items[@]}"; do
    if [[ "$target" == "${it}" ]]; then
      return 0
    fi
  done
  return 1
}

echo "=============================================="
echo " Anthonyware OS 1.0 Installer"
echo "=============================================="
echo "Target User:  $TARGET_USER"
echo "Target Home:  $TARGET_HOME"
echo "Log Dir:      $LOG_DIR"
echo "Dry Run:      $DRY_RUN"
echo "Safe Mode:    $SAFE_MODE"
echo "Repository:   $REPO_PATH"
if [[ -n "$PROFILE" ]]; then
  echo "Profile:      $PROFILE"
fi
if [[ -n "$COMBINED_SKIP" ]]; then
  echo "Skip Steps:   $COMBINED_SKIP"
fi
echo "=============================================="
echo

# Show hardware recommendations
if command -v hardware_recommendations >/dev/null 2>&1; then
  log_info "Hardware recommendations:"
  hardware_recommendations
  echo
fi

# Guardrail: require explicit confirmation to proceed
if [[ "$DRY_RUN" != "1" && "$CONFIRM_INSTALL" != "YES" ]]; then
  log_warn "Confirmation required to proceed."
  echo "Set CONFIRM_INSTALL=YES and re-run to continue."
  echo "Tip: Use DRY_RUN=1 to preview steps and SAFE_MODE=1 to skip risky components."
  echo "     Use PROFILE=minimal for a lighter installation."
  echo "     Use INTERACTIVE=1 for guided component selection."
  exit 2
fi

# Show installation confirmation
if [[ "$DRY_RUN" != "1" ]] && command -v confirm_installation >/dev/null 2>&1; then
  if ! confirm_installation "${PROFILE:-unspecified}" "~${TARGET_USER:-user}" "unknown"; then
    log_warn "Installation cancelled by user"
    exit 0
  fi
fi

# DRY RUN preview: list planned steps and exit
if [[ "$DRY_RUN" == "1" ]]; then
  log_info "[DRY RUN] Planned execution order:"
  for script in "${SCRIPTS[@]}"; do
    if [[ ! -f "$(dirname "$0")/$script" ]]; then
      echo "  - $script (missing)"
      continue
    fi
    if in_skip_list "$script"; then
      echo "  - $script [SKIP]"
    else
      echo "  - $script"
    fi
  done
  log_info "[DRY RUN] No changes were made."
  exit 0
fi

# Optional system snapshot before changes (best-effort)
if [[ "$CREATE_SNAPSHOT" == "1" && -x "${REPO_PATH}/scripts/system-snapshot.sh" ]]; then
  log_info "Creating system snapshot before installation..."
  bash "${REPO_PATH}/scripts/system-snapshot.sh" | tee -a "$LOG_DIR/system-snapshot.log" || true
elif [[ "$CREATE_SNAPSHOT" == "1" ]]; then
  log_warn "scripts/system-snapshot.sh not found; skipping snapshot"
fi

# Run pre-install plugin hooks
if command -v plugin_run_hook >/dev/null 2>&1; then
  plugin_run_hook "pre-install"
fi

# Start time tracking
INSTALL_START_TIME=$(date +%s)
export INSTALL_START_TIME
TOTAL_SCRIPTS=${#SCRIPTS[@]}
CURRENT_SCRIPT=0

if command -v timeline_write >/dev/null 2>&1; then
  timeline_write "start" "pipeline" "Installation pipeline started" ""
fi

for script in "${SCRIPTS[@]}"; do
    ((CURRENT_SCRIPT++))
    
    # Show progress with UX improvements
    if command -v ux_progress_update >/dev/null 2>&1; then
      ux_progress_update $CURRENT_SCRIPT $TOTAL_SCRIPTS "$script"
    elif command -v show_progress >/dev/null 2>&1; then
      show_progress $CURRENT_SCRIPT $TOTAL_SCRIPTS "Installing: $script"
    fi
    
    if [[ ! -f "$(dirname "$0")/$script" ]]; then
      log_warn "SKIP: $script (not found)"
      if command -v timeline_write >/dev/null 2>&1; then
        timeline_write "skip" "$script" "Script missing" ""
      fi
      continue
    fi
    
    # Check if already completed via checkpoint system
    if checkpoint_is_completed "$script"; then
        log_info "SKIP: $script (already completed)"
        if command -v timeline_write >/dev/null 2>&1; then
          timeline_write "skip" "$script" "Checkpoint already completed" ""
        fi
        continue
    fi
    
    # Respect SAFE_MODE / SKIP_STEPS
    if in_skip_list "$script"; then
      log_info "SKIP (SAFE_MODE): $script"
      checkpoint_skip "$script"
      if command -v timeline_write >/dev/null 2>&1; then
        timeline_write "skip" "$script" "Skipped by SAFE_MODE/SKIP" ""
      fi
      continue
    fi

    log_info "Running $script"
    SCRIPT_START_TIME=$(date +%s)
    if command -v timeline_write >/dev/null 2>&1; then
      timeline_write "start" "$script" "Begin" ""
    fi

    SNAP_PATH=""
    if [[ "$ENABLE_SNAPSHOTS" == "1" ]] && snapshot_supported; then
      SNAP_PATH=$(snapshot_create "$script-$(date +%s)" || true)
    fi
    
    # Use network retry for network-dependent scripts
    if bash "$(dirname "$0")/$script" 2>&1 | tee "$LOG_DIR/$script.log"; then
        SCRIPT_END_TIME=$(date +%s)
        SCRIPT_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
        log_success "✓ Completed $script (${SCRIPT_DURATION}s)"
        checkpoint_complete "$script"
        if command -v metrics_event >/dev/null 2>&1; then
          metrics_event "success" "$script" "$SCRIPT_DURATION"
        fi
        if command -v timeline_write >/dev/null 2>&1; then
          timeline_write "done" "$script" "Completed" "${SCRIPT_DURATION}s"
        fi
    else
        log_error "FAILED: $script (see log for details)"
        checkpoint_failed "$script"
        SCRIPT_END_TIME=$(date +%s)
        SCRIPT_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
        if command -v metrics_event >/dev/null 2>&1; then
          metrics_event "fail" "$script" "$SCRIPT_DURATION"
        fi
        if command -v timeline_write >/dev/null 2>&1; then
          timeline_write "fail" "$script" "Failed" "${SCRIPT_DURATION}s"
        fi

      if [[ "$ENABLE_SNAPSHOTS" == "1" && "$ROLLBACK_ON_FAIL" == "1" && -n "$SNAP_PATH" ]]; then
        log_warn "Rolling back from snapshot: $SNAP_PATH"
        snapshot_rollback "$SNAP_PATH" || log_warn "Rollback failed from $SNAP_PATH"
      fi
        
      # Run troubleshooting for this failure
      if [[ -x "${REPO_PATH}/scripts/troubleshoot-all.sh" ]]; then
        log_info "Running troubleshooting for failed script: $script"
        bash "${REPO_PATH}/scripts/troubleshoot-all.sh" || true
        tlog=$(ls -1t /tmp/anthonyware-troubleshoot-* 2>/dev/null | head -1 || true)
        if [[ -n "$tlog" && -f "$tlog" ]]; then
          cp -f "$tlog" "$LOG_DIR/${script%.sh}-troubleshoot.log" || true
          log_info "Troubleshoot log archived: $LOG_DIR/${script%.sh}-troubleshoot.log"
        fi
      fi

      emit_guided_remediation "$script" "$LOG_DIR/$script.log"
        
        # Critical scripts should halt installation
        CRITICAL_SCRIPTS=("00-preflight-checks.sh" "01-base-system.sh" "02-gpu-drivers.sh" "02-qt6-runtime.sh" "03-hyprland.sh" "04-daily-driver.sh")
        for critical in "${CRITICAL_SCRIPTS[@]}"; do
            if [[ "$script" == "$critical" ]]; then
                log_error "Cannot continue without $script"
                log_info "Check logs and resume with same command"
                exit 1
            fi
        done
    fi
    echo
done

# Run post-install plugin hooks
if command -v plugin_run_hook >/dev/null 2>&1; then
  plugin_run_hook "post-install"
fi

# Post-install validation
log_info "Running post-install validation..."
if [[ -x "${REPO_PATH}/scripts/post-install-validate.sh" ]]; then
  bash "${REPO_PATH}/scripts/post-install-validate.sh" | tee -a "$LOG_DIR/post-install-validate.log" || true
else
  log_warn "scripts/post-install-validate.sh not found"
fi

# Validate configs before deployment
if command -v validate_all_configs >/dev/null 2>&1; then
  log_info "Validating configuration files..."
  if validate_all_configs; then
    log_success "All configuration files validated"
  else
    log_warn "Some configuration files have validation warnings"
  fi
fi

# Run diagnostics
if [[ -x "${REPO_PATH}/scripts/diagnostics-suite.sh" ]]; then
  bash "${REPO_PATH}/scripts/diagnostics-suite.sh" || true
  dlog=$(ls -1t /tmp/anthonyware-diagnostics-* 2>/dev/null | head -1 || true)
  if [[ -n "$dlog" && -f "$dlog" ]]; then
    cp -f "$dlog" "$LOG_DIR/" || true
    log_info "Diagnostics log copied: $dlog"
  fi
else
  log_warn "scripts/diagnostics-suite.sh not found"
fi

# Generate SBOM and provenance
if command -v repro_generate_sbom >/dev/null 2>&1; then
  repro_generate_sbom "$REPRO_SNAPSHOT_DIR"
  repro_capture_provenance "$REPRO_SNAPSHOT_DIR/provenance.txt"
fi

# Lean mode cleanup
if [[ "$LEAN_MODE" == "1" ]] && command -v lean_cleanup_cache >/dev/null 2>&1; then
  lean_cleanup_cache
  lean_cleanup_locales
  lean_report_savings
fi

# Emit metrics summary
if command -v metrics_summary >/dev/null 2>&1; then
  metrics_summary | tee -a "$LOG_DIR/final-report.txt"
fi

# Calculate total time
INSTALL_END_TIME=$(date +%s)
TOTAL_DURATION=$((INSTALL_END_TIME - INSTALL_START_TIME))
HOURS=$((TOTAL_DURATION / 3600))
MINUTES=$(((TOTAL_DURATION % 3600) / 60))

if command -v timeline_write >/dev/null 2>&1; then
  timeline_write "done" "pipeline" "Installation pipeline completed" "${TOTAL_DURATION}s"
fi

# Show checkpoint stats
echo
checkpoint_stats
echo

echo "=============================================="
echo " Installation Pipeline Complete"
echo "=============================================="
log_success "Total time: ${HOURS}h ${MINUTES}m"
echo "Check logs: tail -f $LOG_DIR/*.log"
echo "Main log: $LOG_DIR/run-all.log"
echo "=============================================="

# Generate post-install report
log_info "Generating installation report..."
if command -v generate_html_report >/dev/null 2>&1; then
  if [[ -d "$TARGET_HOME" ]]; then
    generate_html_report "${TARGET_HOME}/anthonyware-install-report.html"
    log_success "Report saved: ${TARGET_HOME}/anthonyware-install-report.html"
  else
    generate_html_report "/root/anthonyware-install-report.html"
    log_success "Report saved: /root/anthonyware-install-report.html"
  fi
fi

generate_text_report | tee -a "$LOG_DIR/final-report.txt"

log_success "Installation pipeline completed successfully"

# Show next steps
ux_show_next_steps "$PROFILE"