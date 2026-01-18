#!/usr/bin/env bash
# anthonyctl - CLI tool for managing Anthonyware installation

set -euo pipefail

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${LOG_DIR:-${HOME}/anthonyware-logs}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║ anthonyctl v${VERSION}                                       ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
  echo
}

print_usage() {
  cat <<'EOF'
Usage: anthonyctl <command> [options]

COMMANDS:
  status          Show installation status and health
  resume          Resume failed installation from checkpoint
  rollback        Rollback to previous snapshot
  update          Update all components
  validate        Run validation checks
  report          Generate installation report
  metrics         Show installation metrics
  logs            View installation logs
  snapshot        Create system snapshot
  cleanup         Clean up temporary files and caches
  doctor          Run diagnostic checks
  config          Manage configuration
  
OPTIONS:
  -h, --help      Show this help message
  -v, --version   Show version
  --verbose       Enable verbose output
  
EXAMPLES:
  anthonyctl status           # Check installation status
  anthonyctl resume           # Resume from last checkpoint
  anthonyctl rollback         # Rollback to last snapshot
  anthonyctl update           # Update all components
  anthonyctl doctor           # Run diagnostics

For more information, visit the documentation.
EOF
}

cmd_status() {
  print_header
  echo "Installation Status:"
  echo
  
  # Load checkpoint library if available
  if [[ -f "$REPO_ROOT/install/lib/checkpoint.sh" ]]; then
    source "$REPO_ROOT/install/lib/checkpoint.sh"
    checkpoint_init
    checkpoint_stats
  else
    echo "Checkpoint system not available"
  fi
  
  echo
  echo "System Health:"
  if [[ -f "$REPO_ROOT/install/lib/health.sh" ]]; then
    source "$REPO_ROOT/install/lib/health.sh"
    health_check_all || echo -e "${YELLOW}Some health checks failed${NC}"
  fi
}

cmd_resume() {
  print_header
  echo "Resuming installation from last checkpoint..."
  echo
  
  if [[ ! -f "$REPO_ROOT/install/run-all.sh" ]]; then
    echo -e "${RED}Error: Installation script not found${NC}"
    exit 1
  fi
  
  cd "$REPO_ROOT/install"
  sudo CONFIRM_INSTALL=YES bash run-all.sh
}

cmd_rollback() {
  print_header
  echo "Rolling back to previous snapshot..."
  echo
  
  if [[ -f "$REPO_ROOT/install/lib/snapshot.sh" ]]; then
    source "$REPO_ROOT/install/lib/snapshot.sh"
    
    # List available snapshots
    if ! snapshot_supported; then
      echo -e "${RED}Error: Snapshots not supported on this system${NC}"
      exit 1
    fi
    
    echo "Available snapshots:"
    snapshot_list
    echo
    read -rp "Enter snapshot path to rollback to: " snap_path
    
    if [[ -z "$snap_path" ]]; then
      echo "Cancelled"
      exit 0
    fi
    
    snapshot_rollback "$snap_path"
  else
    echo -e "${RED}Error: Snapshot library not available${NC}"
    exit 1
  fi
}

cmd_update() {
  print_header
  echo "Updating all components..."
  echo
  
  if [[ -f "$REPO_ROOT/install/99-update-everything.sh" ]]; then
    sudo bash "$REPO_ROOT/install/99-update-everything.sh"
  else
    echo -e "${YELLOW}Update script not found, running manual update${NC}"
    sudo pacman -Syu --noconfirm
  fi
}

cmd_validate() {
  print_header
  echo "Running validation checks..."
  echo
  
  if [[ -f "$REPO_ROOT/install/35-validation.sh" ]]; then
    sudo bash "$REPO_ROOT/install/35-validation.sh"
  else
    echo -e "${RED}Error: Validation script not found${NC}"
    exit 1
  fi
}

cmd_report() {
  print_header
  echo "Generating installation report..."
  echo
  
  if [[ -f "$REPO_ROOT/install/lib/report.sh" ]]; then
    source "$REPO_ROOT/install/lib/report.sh"
    generate_html_report "${HOME}/anthonyware-report.html"
    echo
    echo -e "${GREEN}Report generated: ${HOME}/anthonyware-report.html${NC}"
  else
    echo -e "${RED}Error: Report library not available${NC}"
    exit 1
  fi
}

cmd_metrics() {
  print_header
  echo "Installation Metrics:"
  echo
  
  if [[ -f "$REPO_ROOT/install/lib/metrics.sh" ]]; then
    source "$REPO_ROOT/install/lib/metrics.sh"
    metrics_summary
  else
    echo "Metrics not available"
  fi
}

cmd_logs() {
  print_header
  echo "Installation Logs:"
  echo
  
  if [[ -d "$LOG_DIR" ]]; then
    echo "Log directory: $LOG_DIR"
    echo
    ls -lh "$LOG_DIR"/*.log 2>/dev/null || echo "No logs found"
    echo
    echo "View logs with: tail -f $LOG_DIR/*.log"
  else
    echo "Log directory not found"
  fi
}

cmd_snapshot() {
  print_header
  echo "Creating system snapshot..."
  echo
  
  if [[ -f "$REPO_ROOT/scripts/system-snapshot.sh" ]]; then
    sudo bash "$REPO_ROOT/scripts/system-snapshot.sh"
  else
    echo -e "${RED}Error: Snapshot script not found${NC}"
    exit 1
  fi
}

cmd_cleanup() {
  print_header
  echo "Cleaning up temporary files..."
  echo
  
  # Clean package cache
  sudo pacman -Sc --noconfirm
  
  # Clean AUR cache
  if command -v paru >/dev/null 2>&1; then
    paru -Sc --noconfirm
  elif command -v yay >/dev/null 2>&1; then
    yay -Sc --noconfirm
  fi
  
  # Clean journal
  sudo journalctl --vacuum-size=100M
  
  # Clean old logs
  find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
  
  echo -e "${GREEN}Cleanup completed${NC}"
}

cmd_doctor() {
  print_header
  echo "Running diagnostic checks..."
  echo
  
  if [[ -f "$REPO_ROOT/scripts/diagnostics-suite.sh" ]]; then
    sudo bash "$REPO_ROOT/scripts/diagnostics-suite.sh"
  elif [[ -f "$REPO_ROOT/install/34-diagnostics.sh" ]]; then
    sudo bash "$REPO_ROOT/install/34-diagnostics.sh"
  else
    echo -e "${YELLOW}Diagnostic scripts not found${NC}"
  fi
}

# Main command dispatcher
main() {
  case "${1:-}" in
    status)
      cmd_status
      ;;
    resume)
      cmd_resume
      ;;
    rollback)
      cmd_rollback
      ;;
    update)
      cmd_update
      ;;
    validate)
      cmd_validate
      ;;
    report)
      cmd_report
      ;;
    metrics)
      cmd_metrics
      ;;
    logs)
      cmd_logs
      ;;
    snapshot)
      cmd_snapshot
      ;;
    cleanup)
      cmd_cleanup
      ;;
    doctor)
      cmd_doctor
      ;;
    -h|--help|help)
      print_header
      print_usage
      ;;
    -v|--version)
      echo "anthonyctl version $VERSION"
      ;;
    *)
      print_header
      echo -e "${RED}Error: Unknown command '${1:-}'${NC}"
      echo
      print_usage
      exit 1
      ;;
  esac
}

main "$@"
