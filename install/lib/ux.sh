#!/usr/bin/env bash
# ux.sh - User experience improvements: progress, estimates, guidance

# ============================================================
# Progress Indication
# ============================================================

# ANSI colors for rich output
UX_COLOR_RESET='\033[0m'
UX_COLOR_BLUE='\033[0;34m'
UX_COLOR_GREEN='\033[0;32m'
UX_COLOR_YELLOW='\033[0;33m'
UX_COLOR_RED='\033[0;31m'
UX_COLOR_CYAN='\033[0;36m'
UX_COLOR_GRAY='\033[0;90m'

# Unicode symbols
UX_SYM_CHECK="✓"
UX_SYM_CROSS="✗"
UX_SYM_ARROW="→"
UX_SYM_WARN="⚠"
UX_SYM_INFO="ℹ"
UX_SYM_STAR="★"

# Print section header
ux_header() {
  local title="$1"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${UX_COLOR_CYAN}${title}${UX_COLOR_RESET}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Print step with progress
ux_step() {
  local current="$1"
  local total="$2"
  local description="$3"
  
  echo -e "${UX_COLOR_BLUE}[${current}/${total}]${UX_COLOR_RESET} ${description}..."
}

# Print success message
ux_success() {
  local message="$1"
  echo -e "${UX_COLOR_GREEN}${UX_SYM_CHECK}${UX_COLOR_RESET} ${message}"
}

# Print warning message
ux_warn() {
  local message="$1"
  echo -e "${UX_COLOR_YELLOW}${UX_SYM_WARN}${UX_COLOR_RESET} ${message}"
}

# Print error message
ux_error() {
  local message="$1"
  echo -e "${UX_COLOR_RED}${UX_SYM_CROSS}${UX_COLOR_RESET} ${message}"
}

# Print info message
ux_info() {
  local message="$1"
  echo -e "${UX_COLOR_GRAY}${UX_SYM_INFO}${UX_COLOR_RESET} ${message}"
}

# ============================================================
# Time Estimation
# ============================================================

# Estimate installation time based on profile
ux_estimate_time() {
  local profile="$1"
  local base_time=15  # Base system: 15 min
  
  case "$profile" in
    minimal) echo "$((base_time + 5))" ;;
    developer) echo "$((base_time + 25))" ;;
    workstation) echo "$((base_time + 35))" ;;
    gamer) echo "$((base_time + 30))" ;;
    homelab) echo "$((base_time + 40))" ;;
    laptop) echo "$((base_time + 20))" ;;
    server) echo "$((base_time + 25))" ;;
    cloud) echo "$((base_time + 15))" ;;
    color-managed) echo "$((base_time + 30))" ;;
    full) echo "$((base_time + 60))" ;;
    *) echo "$((base_time + 30))" ;;
  esac
}

# Show installation plan summary
ux_show_plan() {
  local profile="$1"
  local scripts_count="$2"
  
  local estimated_time
  estimated_time=$(ux_estimate_time "$profile")
  
  ux_header "Installation Plan"
  
  echo "Profile:         ${UX_COLOR_CYAN}${profile}${UX_COLOR_RESET}"
  echo "Scripts to run:  ${scripts_count}"
  echo "Estimated time:  ~${estimated_time} minutes"
  echo ""
  
  # Profile description
  case "$profile" in
    minimal)
      echo "Minimal: Base Hyprland desktop only"
      ;;
    developer)
      echo "Developer: Hyprland + dev tools (Git, Docker, Rust, Python)"
      ;;
    workstation)
      echo "Workstation: Developer + daily apps + multimedia"
      ;;
    gamer)
      echo "Gamer: Workstation + Steam, gaming tools"
      ;;
    homelab)
      echo "Homelab: Developer + virtualization + containers"
      ;;
    laptop)
      echo "Laptop: Workstation + power management + battery optimization"
      ;;
    server)
      echo "Server: Headless services + hardening + minimal footprint"
      ;;
    cloud)
      echo "Cloud: Server + cloud-native tools + minimal surface"
      ;;
    color-managed)
      echo "Color-managed: Workstation + color calibration for creative work"
      ;;
    full)
      echo "Full: Everything included (max installation)"
      ;;
  esac
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================
# Progress Tracking
# ============================================================

# Initialize progress tracking
ux_progress_init() {
  export UX_START_TIME=$(date +%s)
  export UX_CURRENT_SCRIPT=0
  export UX_TOTAL_SCRIPTS=0
}

# Update progress
ux_progress_update() {
  local current="$1"
  local total="$2"
  local script_name="$3"
  
  export UX_CURRENT_SCRIPT="$current"
  export UX_TOTAL_SCRIPTS="$total"
  
  local elapsed=$(($(date +%s) - UX_START_TIME))
  local elapsed_min=$((elapsed / 60))
  local elapsed_sec=$((elapsed % 60))
  
  # Calculate estimated remaining time
  local avg_time_per_script=$((elapsed / current))
  local remaining_scripts=$((total - current))
  local estimated_remaining=$((avg_time_per_script * remaining_scripts))
  local remaining_min=$((estimated_remaining / 60))
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${UX_COLOR_CYAN}Progress: ${current}/${total} scripts${UX_COLOR_RESET}"
  echo -e "${UX_COLOR_GRAY}Current:  ${script_name}${UX_COLOR_RESET}"
  echo -e "${UX_COLOR_GRAY}Elapsed:  ${elapsed_min}m ${elapsed_sec}s${UX_COLOR_RESET}"
  
  if [[ $current -gt 1 ]]; then
    echo -e "${UX_COLOR_GRAY}Remaining: ~${remaining_min} minutes${UX_COLOR_RESET}"
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ============================================================
# Post-Install Guidance
# ============================================================

# Show next steps after installation
ux_show_next_steps() {
  local profile="$1"
  
  ux_header "Installation Complete! Next Steps"
  
  echo "1. ${UX_SYM_STAR} Reboot your system:"
  echo "   sudo reboot"
  echo ""
  
  echo "2. ${UX_SYM_STAR} Select Hyprland at login screen (SDDM)"
  echo ""
  
  echo "3. ${UX_SYM_STAR} Review installation logs:"
  echo "   anthonyctl logs"
  echo "   # Or directly: less ${LOG_DIR:-/var/log/anthonyware-install}/install-*.log"
  echo ""
  
  case "$profile" in
    developer|workstation|full)
      echo "4. ${UX_SYM_STAR} Activate Docker group (if installed):"
      echo "   newgrp docker"
      echo "   # Or logout/login to persist"
      echo ""
      echo "5. ${UX_SYM_STAR} Configure Git:"
      echo "   git config --global user.name \"Your Name\""
      echo "   git config --global user.email \"you@example.com\""
      echo ""
      ;;
    gamer)
      echo "4. ${UX_SYM_STAR} Launch Steam and enable Proton:"
      echo "   Steam → Settings → Compatibility → Enable Steam Play"
      echo ""
      ;;
    laptop)
      echo "4. ${UX_SYM_STAR} Review power management settings:"
      echo "   sudo tlp-stat"
      echo ""
      ;;
  esac
  
  echo "${UX_SYM_INFO} Additional resources:"
  echo "  • Hyprland docs: https://wiki.hyprland.org/"
  echo "  • Config files: ~/.config/hypr/"
  echo "  • Keybindings: SUPER+? or check ~/.config/hypr/hyprland.conf"
  echo ""
  
  echo "═══════════════════════════════════════════════════"
  echo -e "${UX_COLOR_GREEN}${UX_SYM_CHECK} Anthonyware OS Installation Complete${UX_COLOR_RESET}"
  echo "═══════════════════════════════════════════════════"
}

# Show troubleshooting tips
ux_show_troubleshooting() {
  ux_header "Installation Failed - Troubleshooting"
  
  echo "Common issues and solutions:"
  echo ""
  
  echo "1. Network connectivity issues:"
  echo "   • Check: ping archlinux.org"
  echo "   • Fix: nmtui (NetworkManager TUI)"
  echo ""
  
  echo "2. Package conflicts:"
  echo "   • Check: pacman -Qkk"
  echo "   • Fix: sudo pacman -Scc && sudo pacman -Syyu"
  echo ""
  
  echo "3. Insufficient disk space:"
  echo "   • Check: df -h /"
  echo "   • Fix: sudo pacman -Scc (clean package cache)"
  echo "   • Fix: ncdu / (find large directories)"
  echo ""
  
  echo "4. Locked pacman database:"
  echo "   • Check: ls -la /var/lib/pacman/db.lck"
  echo "   • Fix: sudo rm /var/lib/pacman/db.lck"
  echo ""
  
  echo "5. GRUB/bootloader issues:"
  echo "   • Restore backup: sudo cp /etc/default/grub.vfio.bak /etc/default/grub"
  echo "   • Regenerate: sudo grub-mkconfig -o /boot/grub/grub.cfg"
  echo ""
  
  echo "Get help:"
  echo "  • Review logs: anthonyctl logs"
  echo "  • Generate diagnostics: anthonyctl doctor"
  echo "  • Create rescue bundle: scripts/rescue-bundle.sh"
  echo ""
  
  echo "Resume installation:"
  echo "  • After fixing issues: sudo bash install/run-all.sh"
  echo "  • Checkpoint system will skip completed scripts"
  echo ""
}

# Show confirmation prompt with details
ux_confirm_install() {
  local profile="$1"
  
  ux_show_plan "$profile" "${UX_TOTAL_SCRIPTS:-38}"
  
  echo ""
  echo "${UX_SYM_WARN} This will:"
  echo "  • Install ~2-5GB of packages"
  echo "  • Modify system configuration"
  echo "  • Configure bootloader (GRUB)"
  echo "  • Enable system services"
  echo ""
  
  read -p "Continue with installation? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Installation cancelled."
    return 1
  fi
  
  echo ""
  echo "Starting installation..."
  return 0
}

# Export functions
export -f ux_header
export -f ux_step
export -f ux_success
export -f ux_warn
export -f ux_error
export -f ux_info
export -f ux_estimate_time
export -f ux_show_plan
export -f ux_progress_init
export -f ux_progress_update
export -f ux_show_next_steps
export -f ux_show_troubleshooting
export -f ux_confirm_install
