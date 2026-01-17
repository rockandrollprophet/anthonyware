#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS 1.0 — Installation Pipeline Orchestrator
#
#  Enhanced with:
#    - Retry logic for network failures
#    - Critical script validation
#    - Checkpoint system
#    - Enhanced logging with timestamps
# ============================================================

# Enable dry-run mode (set DRY_RUN=1 before running to skip destructive operations)
DRY_RUN="${DRY_RUN:-0}"
export DRY_RUN

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
  REPO_PATH="${TARGET_HOME}/anthonyware"
  export REPO_PATH
fi

LOG_DIR="${TARGET_HOME}/anthonyware-logs"
mkdir -p "$LOG_DIR"

# Checkpoint file to track progress
CHECKPOINT_FILE="$LOG_DIR/installation-checkpoint.txt"
touch "$CHECKPOINT_FILE"

# Error handler: run troubleshooting on failures and archive logs
on_error() {
  local exit_code=$?
  echo "[ERROR] Pipeline failed with exit code ${exit_code}" | tee -a "$LOG_DIR/run-all.log"
  if [[ -x "${REPO_PATH}/scripts/troubleshoot-all.sh" ]]; then
    echo "[INFO] Running troubleshooting aggregator..." | tee -a "$LOG_DIR/run-all.log"
    bash "${REPO_PATH}/scripts/troubleshoot-all.sh" || true
    # Archive latest troubleshoot log into LOG_DIR
    local latest
    latest=$(ls -1t /tmp/anthonyware-troubleshoot-* 2>/dev/null | head -1 || true)
    if [[ -n "$latest" && -f "$latest" ]]; then
      cp -f "$latest" "$LOG_DIR/" || true
      echo "[INFO] Troubleshoot log copied: $latest" | tee -a "$LOG_DIR/run-all.log"
    fi
  else
    echo "[WARN] scripts/troubleshoot-all.sh not found; skipping auto-troubleshoot" | tee -a "$LOG_DIR/run-all.log"
  fi
}

# Set trap after variables and paths are prepared
trap on_error ERR

# Enhanced logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_DIR/run-all.log"
}

log_message "INFO" "Starting Anthonyware OS installation pipeline"
log_message "INFO" "Target User: $TARGET_USER"
log_message "INFO" "Target Home: $TARGET_HOME"
log_message "INFO" "Repository: $REPO_PATH"

SCRIPTS=(
  "00-preflight-checks.sh"
  "01-base-system.sh"
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
  "24-cleanup-and-verify.sh"
  "25-color-management.sh"
  "26-archive-tools.sh"
  "27-zram-swap.sh"
  "28-audio-routing.sh"
  "29-misc-utilities.sh"
  "30-finalize.sh"
  "31-wayland-recording.sh"
  "32-latex-docs.sh"
  "33-cleaner.sh"
  "34-diagnostics.sh"
  "35-fusion360-runtime.sh"
  "36-xwayland-legacy.sh"
  "37-ops-diagnostics.sh"
  "33-user-configs.sh"
  "35-validation.sh"
  "99-update-everything.sh"
)

echo "=============================================="
echo " Anthonyware OS 1.0 Installer"
echo "=============================================="
echo "Target User:  $TARGET_USER"
echo "Target Home:  $TARGET_HOME"
echo "Log Dir:      $LOG_DIR"
echo "Dry Run:      $DRY_RUN"
echo "Repository:   $REPO_PATH"
echo "=============================================="
echo

for script in "${SCRIPTS[@]}"; do
    if [[ ! -f "$(dirname "$0")/$script" ]]; then
      log_message "WARN" "SKIP: $script (not found)"
      continue
    fi
    
    # Check if already completed
    if grep -q "^COMPLETED:$script$" "$CHECKPOINT_FILE" 2>/dev/null; then
        log_message "INFO" "SKIP: $script (already completed)"
        continue
    fi
    
    log_message "INFO" "Running $script"
    
    # Retry logic for network-dependent scripts
    MAX_RETRIES=3
    RETRY_COUNT=0
    SUCCESS=false
    
    while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
        if bash "$(dirname "$0")/$script" 2>&1 | tee "$LOG_DIR/$script.log"; then
            log_message "INFO" "✓ Completed $script"
            echo "COMPLETED:$script" >> "$CHECKPOINT_FILE"
            SUCCESS=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; then
                log_message "WARN" "Failed (attempt $RETRY_COUNT/$MAX_RETRIES), retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    if [[ "$SUCCESS" == false ]]; then
        log_message "ERROR" "FAILED: $script after $MAX_RETRIES attempts (see log for details)"
      # Run troubleshooting for this failure and archive log
      if [[ -x "${REPO_PATH}/scripts/troubleshoot-all.sh" ]]; then
        log_message "INFO" "Running troubleshooting for failed script: $script"
        bash "${REPO_PATH}/scripts/troubleshoot-all.sh" || true
        tlog=$(ls -1t /tmp/anthonyware-troubleshoot-* 2>/dev/null | head -1 || true)
        if [[ -n "$tlog" && -f "$tlog" ]]; then
          cp -f "$tlog" "$LOG_DIR/${script%.sh}-troubleshoot.log" || true
          log_message "INFO" "Troubleshoot log archived: $LOG_DIR/${script%.sh}-troubleshoot.log"
        fi
      fi
        
        # Critical scripts should halt installation
        CRITICAL_SCRIPTS=("00-preflight-checks.sh" "01-base-system.sh" "03-hyprland.sh")
        for critical in "${CRITICAL_SCRIPTS[@]}"; do
            if [[ "$script" == "$critical" ]]; then
                log_message "CRITICAL" "Cannot continue without $script"
                log_message "INFO" "Check logs and run again: bash run-all.sh"
                exit 1
            fi
        done
    fi
    echo
done

# Post-install health checks
echo "[INFO] Running post-install validation and diagnostics..." | tee -a "$LOG_DIR/run-all.log"
if [[ -x "${REPO_PATH}/scripts/post-install-validate.sh" ]]; then
  bash "${REPO_PATH}/scripts/post-install-validate.sh" | tee -a "$LOG_DIR/post-install-validate.log" || true
else
  echo "[WARN] scripts/post-install-validate.sh not found" | tee -a "$LOG_DIR/run-all.log"
fi
if [[ -x "${REPO_PATH}/scripts/diagnostics-suite.sh" ]]; then
  bash "${REPO_PATH}/scripts/diagnostics-suite.sh" || true
  dlog=$(ls -1t /tmp/anthonyware-diagnostics-* 2>/dev/null | head -1 || true)
  if [[ -n "$dlog" && -f "$dlog" ]]; then
    cp -f "$dlog" "$LOG_DIR/" || true
    echo "[INFO] Diagnostics log copied: $dlog" | tee -a "$LOG_DIR/run-all.log"
  fi
else
  echo "[WARN] scripts/diagnostics-suite.sh not found" | tee -a "$LOG_DIR/run-all.log"
fi

echo "=============================================="
echo " Installation Pipeline Complete"
echo "=============================================="
echo "Check logs: tail -f $LOG_DIR/*.log"
echo "Main log: $LOG_DIR/run-all.log"
echo "Checkpoint: $CHECKPOINT_FILE"
echo "=============================================="

log_message "INFO" "Installation pipeline completed successfully"