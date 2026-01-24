#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# interactive.sh - Interactive component selection

# Display interactive menu (CLI fallback)
show_menu() {
  local title="$1"
  shift
  local options=("$@")
  
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║ $title"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo
  
  local i=1
  for option in "${options[@]}"; do
    echo "  $i) $option"
    ((i++))
  done
  echo
}

# Select profile interactively
select_profile() {
  local options=(
    "minimal" "Minimal (Base + Hyprland)"
    "developer" "Developer (Adds dev tools)"
    "workstation" "Workstation (Full featured)"
    "gamer" "Gamer (Gaming focused)"
    "homelab" "Homelab (Server/admin tools)"
    "laptop" "Laptop (Power tuned)"
    "server" "Server (Headless/hardening)"
    "cloud" "Cloud (Lean headless)"
    "color-managed" "Color Managed (Display accuracy)"
    "full" "Everything"
    "custom" "Custom (select components)"
  )

  if command -v tui_menu >/dev/null 2>&1; then
    local choice
    choice=$(tui_menu "Installation Profile" "${options[@]}")
    echo "${choice:-minimal}"
    return 0
  fi

  clear
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║ Anthonyware OS - Installation Profile Selection          ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo
  echo "Choose an installation profile:"
  echo
  echo "  1) Minimal        (Base + Hyprland only - 10GB, 15 min)"
  echo "  2) Developer      (Minimal + dev tools - 20GB, 30 min)"
  echo "  3) Workstation    (Full featured - 35GB, 60 min)"
  echo "  4) Gamer          (Minimal + gaming - 25GB, 25 min)"
  echo "  5) Homelab        (Developer + homelab - 25GB, 40 min)"
  echo "  6) Laptop         (Power tuned laptop - 25GB, 30 min)"
  echo "  7) Server         (Headless/hardened - 15GB, 20 min)"
  echo "  8) Cloud          (Lean headless - 12GB, 15 min)"
  echo "  9) Color Managed  (Display accuracy - 30GB, 40 min)"
  echo " 10) Full           (Everything - 50GB, 75 min)"
  echo " 11) Custom         (Select individual components)"
  echo
  read -rp "Select profile [1-11]: " choice
  
  case "$choice" in
    1) echo "minimal" ;;
    2) echo "developer" ;;
    3) echo "workstation" ;;
    4) echo "gamer" ;;
    5) echo "homelab" ;;
    6) echo "laptop" ;;
    7) echo "server" ;;
    8) echo "cloud" ;;
    9) echo "color-managed" ;;
    10) echo "full" ;;
    11) echo "custom" ;;
    *) echo "minimal" ;;
  esac
}

# Custom component selection
select_custom_components() {
  local optional=(
    "04-daily-driver.sh" "Daily Driver Apps" "on"
    "05-dev-tools.sh" "Development Tools" "on"
    "06-ai-ml.sh" "AI/ML Toolkit" "off"
    "07-cad-cnc-3dprinting.sh" "CAD/CNC/3D Printing" "off"
    "08-hardware-support.sh" "Hardware Support" "off"
    "09-security.sh" "Security Tools" "on"
    "10-backups.sh" "Backup Tools" "on"
    "10-webcam-media.sh" "Webcam/Media" "off"
    "11-vfio-windows-vm.sh" "VFIO/Windows VM" "off"
    "12-printing.sh" "Printing Support" "off"
    "17-steam.sh" "Gaming (Steam)" "off"
    "18-networking-tools.sh" "Networking Tools" "off"
    "19-electrical-engineering.sh" "Electrical Engineering" "off"
    "20-fpga-toolchain.sh" "FPGA Toolchain" "off"
    "21-instrumentation.sh" "Instrumentation" "off"
    "22-homelab-tools.sh" "Homelab Tools" "off"
    "31-wayland-recording.sh" "Wayland Recording" "off"
    "32-latex-docs.sh" "LaTeX Documentation" "off"
  )

  if command -v tui_checklist >/dev/null 2>&1; then
    local selection
    selection=$(tui_checklist "Custom Components" "${optional[@]}")
    echo "$selection"
    return 0
  fi

  local components=()
  clear
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║ Custom Component Selection                                ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo
  echo "Select components to install (Y/n for each):"
  echo
  echo "✓ Base System (required)"
  echo "✓ Hyprland Desktop (required)"
  echo "✓ GPU Drivers (required)"
  echo

  local total=${#optional[@]}
  local idx=0
  while [[ $idx -lt $total ]]; do
    local script="${optional[$idx]}"; local name="${optional[$((idx+1))]}"
    read -rp "  $name? [Y/n] " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
      components+=("$script")
    fi
    idx=$((idx+3))
  done

  IFS=','
  echo "${components[*]}"
}

# Confirm installation
confirm_installation() {
  local profile="$1"
  local estimated_time="$2"
  local estimated_size="$3"

  if command -v tui_yesno >/dev/null 2>&1; then
    tui_yesno "Installation Summary" "Profile: $profile\nTime: $estimated_time\nDisk: $estimated_size\nProceed?"
    return $?
  fi

  clear
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║ Installation Summary                                      ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo
  echo "Profile:         $profile"
  echo "Estimated time:  $estimated_time"
  echo "Disk space:      $estimated_size"
  echo
  hardware_report 2>/dev/null || true
  echo
  read -rp "Proceed with installation? [Y/n] " answer
  
  if [[ "$answer" =~ ^[Nn]$ ]]; then
    return 1
  fi
  
  return 0
}

# Show progress with percentage
show_progress() {
  local current="$1"
  local total="$2"
  local script="$3"
  
  local percent=$((current * 100 / total))
  local filled=$((percent / 2))
  local empty=$((50 - filled))
  
  printf "\r["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] %3d%% (%d/%d) %s" "$percent" "$current" "$total" "$script"
}

# Export functions
export -f show_menu
export -f select_profile
export -f select_custom_components
export -f confirm_installation
export -f show_progress
