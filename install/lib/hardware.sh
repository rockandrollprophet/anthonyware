#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034
# SC1090/SC1091: Dynamic source paths validated at runtime
# SC2034: Variables may be used by sourcing scripts
# hardware.sh - Hardware detection and optimization

# Detect GPU vendor
detect_gpu() {
  local gpu_info=$(lspci | grep -i 'vga\|3d\|display')
  
  if echo "$gpu_info" | grep -iq nvidia; then
    echo "nvidia"
  elif echo "$gpu_info" | grep -iq amd; then
    echo "amd"
  elif echo "$gpu_info" | grep -iq intel; then
    echo "intel"
  else
    echo "unknown"
  fi
}

# Detect network hardware
detect_network() {
  local has_wifi=0
  local has_ethernet=0
  
  if ip link show | grep -q "wlan\|wlp"; then
    has_wifi=1
  fi
  
  if ip link show | grep -q "eth\|enp"; then
    has_ethernet=1
  fi
  
  echo "wifi=$has_wifi ethernet=$has_ethernet"
}

# Check if running in VM
detect_vm() {
  if systemd-detect-virt --quiet; then
    systemd-detect-virt
  else
    echo "none"
  fi
}

# Detect CPU vendor
detect_cpu() {
  local cpu_info=$(lscpu | grep "Vendor ID" | awk '{print $3}')
  
  case "$cpu_info" in
    GenuineIntel) echo "intel" ;;
    AuthenticAMD) echo "amd" ;;
    *) echo "unknown" ;;
  esac
}

# Check UEFI vs BIOS
detect_firmware() {
  if [[ -d /sys/firmware/efi ]]; then
    echo "uefi"
  else
    echo "bios"
  fi
}

# Get total RAM in GB
detect_ram() {
  local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local ram_gb=$((ram_kb / 1024 / 1024))
  echo "$ram_gb"
}

# Get available disk space in GB
detect_disk_space() {
  local disk="${1:-/}"
  df -BG "$disk" | tail -1 | awk '{print $4}' | sed 's/G//'
}

# Check if specific hardware exists
has_nvidia_gpu() {
  [[ "$(detect_gpu)" == "nvidia" ]]
}

has_amd_gpu() {
  [[ "$(detect_gpu)" == "amd" ]]
}

has_intel_gpu() {
  [[ "$(detect_gpu)" == "intel" ]]
}

has_wifi() {
  local network=$(detect_network)
  [[ "$network" =~ wifi=1 ]]
}

is_vm() {
  [[ "$(detect_vm)" != "none" ]]
}

is_uefi() {
  [[ "$(detect_firmware)" == "uefi" ]]
}

# Generate hardware report
hardware_report() {
  cat <<EOF
╔══════════════════════════════════════════════════════════╗
║ Hardware Detection Report                                ║
╚══════════════════════════════════════════════════════════╝

CPU:        $(detect_cpu | tr '[:lower:]' '[:upper:]')
GPU:        $(detect_gpu | tr '[:lower:]' '[:upper:]')
RAM:        $(detect_ram)GB
Firmware:   $(detect_firmware | tr '[:lower:]' '[:upper:]')
VM:         $(detect_vm)
Network:    $(detect_network)
Disk Space: $(detect_disk_space /)GB available

EOF
}

# Recommend components based on hardware
hardware_recommendations() {
  local gpu=$(detect_gpu)
  local ram=$(detect_ram)
  local is_vm=$(detect_vm)
  
  echo "Recommended components based on hardware:"
  echo
  
  # GPU-based recommendations
  case "$gpu" in
    nvidia)
      echo "  ✓ Install NVIDIA drivers"
      echo "  ✓ Install CUDA toolkit (AI/ML)"
      ;;
    amd)
      echo "  ✓ Install AMD drivers (AMDGPU)"
      echo "  ✓ Install ROCm (AI/ML)"
      ;;
    intel)
      echo "  ✓ Install Intel drivers"
      echo "  ⊙ Skip CUDA/ROCm (no dedicated GPU)"
      ;;
  esac
  
  # RAM-based recommendations
  if [[ $ram -lt 8 ]]; then
    echo "  ⚠ Low RAM detected - consider skipping:"
    echo "    - AI/ML tools (requires 8GB+)"
    echo "    - Multiple VMs"
  elif [[ $ram -lt 16 ]]; then
    echo "  ⊙ Moderate RAM - AI/ML will work but may be slow"
  else
    echo "  ✓ Sufficient RAM for all components"
  fi
  
  # VM recommendations
  if [[ "$is_vm" != "none" ]]; then
    echo "  ⊙ VM detected ($is_vm) - consider skipping:"
    echo "    - GPU-intensive workloads"
    echo "    - Nested virtualization (VFIO)"
    echo "    - Hardware-specific drivers"
  fi
  
  echo
}

# Export functions
export -f detect_gpu
export -f detect_network
export -f detect_vm
export -f detect_cpu
export -f detect_firmware
export -f detect_ram
export -f detect_disk_space
export -f has_nvidia_gpu
export -f has_amd_gpu
export -f has_intel_gpu
export -f has_wifi
export -f is_vm
export -f is_uefi
export -f hardware_report
export -f hardware_recommendations
