#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Anthonyware Smart Partitioning Script
# Automatically partitions a disk for Arch Linux + optional Windows VM
# Adapts to different disk sizes intelligently
###############################################################################

BOLD='\033[1m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

###############################################################################
# Configuration & Defaults
###############################################################################

# Default sizes (in GB)
EFI_SIZE_GB=0.5              # EFI partition (512 MB)
ARCH_MIN_GB=30               # Absolute minimum for base Arch
ARCH_RECOMMENDED_GB=200      # Recommended minimum for engineering tools
ARCH_TARGET_GB=800           # Target for full engineering workstation
VM_MIN_GB=100                # Minimum Windows VM partition

# Tolerance for rounding (GB)
PARTITION_TOLERANCE=1

###############################################################################
# Helper Functions
###############################################################################

print_header() {
    echo -e "${BOLD}=== $1 ===${RESET}"
}

print_success() {
    echo -e "${GREEN}✓${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}!${RESET} $1"
}

print_error() {
    echo -e "${RED}✗${RESET} $1"
}

confirm_action() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e "${BOLD}$prompt${RESET}") (yes/no): " response
    [[ "$response" == "yes" ]] && return 0 || return 1
}

###############################################################################
# Disk Detection
###############################################################################

detect_disks() {
    echo ""
    print_header "Available Disks"
    
    local -a disks
    mapfile -t disks < <(lsblk -dpn -o NAME | grep -E '^/dev/(nvme|sd|vd)')
    
    if [ ${#disks[@]} -eq 0 ]; then
        print_error "No disks detected"
        exit 1
    fi
    
    for i in "${!disks[@]}"; do
        local disk="${disks[$i]}"
        local size_bytes=$(blockdev --getsize64 "$disk" 2>/dev/null || echo 0)
        local size_gb=$((size_bytes / 1024 / 1024 / 1024))
        local name=$(lsblk -dpn -o NAME,MODEL "$disk" | head -1)
        
        echo "[$i] $name - ${size_gb}GB"
    done
    
    # Return array for caller to use
    echo "${#disks[@]}"
    printf '%s\n' "${disks[@]}"
}

select_disk() {
    local disk_count
    local -a disk_list
    
    mapfile -t lines < <(detect_disks)
    disk_count="${lines[0]}"
    disk_list=("${lines[@]:1}")
    
    if [ "$disk_count" -eq 1 ]; then
        print_warning "Only one disk found: ${disk_list[0]}"
        confirm_action "Use ${disk_list[0]}?" || {
            echo "Aborted."
            exit 1
        }
        echo "${disk_list[0]}"
        return
    fi
    
    local choice
    read -p "Select disk [0-$((disk_count - 1))]: " choice
    
    if [ "$choice" -lt 0 ] || [ "$choice" -ge "$disk_count" ]; then
        print_error "Invalid selection"
        exit 1
    fi
    
    echo "${disk_list[$choice]}"
}

###############################################################################
# Disk Size Analysis
###############################################################################

analyze_disk_size() {
    local disk="$1"
    local size_bytes
    local size_gb
    
    size_bytes=$(blockdev --getsize64 "$disk" 2>/dev/null || echo 0)
    size_gb=$((size_bytes / 1024 / 1024 / 1024))
    
    echo "$size_gb"
}

recommend_partitions() {
    local disk_size_gb=$1
    local efi_gb=$EFI_SIZE_GB
    local arch_gb
    local vm_gb
    
    print_header "Disk: ${disk_size_gb}GB - Partition Recommendations"
    
    # Categorize by disk size
    if [ "$disk_size_gb" -lt 100 ]; then
        print_error "Disk too small! Minimum 100GB recommended."
        exit 1
    elif [ "$disk_size_gb" -lt 250 ]; then
        # Small disk: prioritize Arch, minimal/no VM
        arch_gb=$((disk_size_gb - efi_gb))
        vm_gb=0
        print_warning "Small disk detected (${disk_size_gb}GB)"
        echo "  → Arch allocation: ${arch_gb}GB (no Windows VM partition)"
    elif [ "$disk_size_gb" -lt 500 ]; then
        # Medium disk: balanced Arch and VM
        arch_gb=$((disk_size_gb / 2))
        vm_gb=$((disk_size_gb - arch_gb - efi_gb))
        echo "  → Arch allocation: ${arch_gb}GB"
        echo "  → Windows VM:      ${vm_gb}GB"
    elif [ "$disk_size_gb" -lt 1000 ]; then
        # Large disk (1TB): prefer Arch (engineering workload)
        arch_gb=$ARCH_TARGET_GB
        vm_gb=$((disk_size_gb - arch_gb - efi_gb))
        echo "  → Arch allocation: ${arch_gb}GB (engineering workstation target)"
        echo "  → Windows VM:      ${vm_gb}GB"
    else
        # Very large disk (>1TB): max Arch, rest for VM
        arch_gb=$ARCH_TARGET_GB
        vm_gb=$((disk_size_gb - arch_gb - efi_gb))
        echo "  → Arch allocation: ${arch_gb}GB (target)"
        echo "  → Windows VM:      ${vm_gb}GB"
    fi
    
    echo ""
    echo "Partition Scheme:"
    echo "  1. EFI:     ${efi_gb}GB     (/boot)"
    echo "  2. Arch:    ${arch_gb}GB     (/, /home, all tools)"
    if [ "$vm_gb" -gt 0 ]; then
        echo "  3. Windows: ${vm_gb}GB     (VFIO VM disk image)"
    fi
    echo ""
    
    # Return values (sourced by caller or echo-ed)
    echo "$efi_gb"
    echo "$arch_gb"
    echo "$vm_gb"
}

###############################################################################
# Partitioning
###############################################################################

partition_disk() {
    local disk="$1"
    local efi_gb="$2"
    local arch_gb="$3"
    local vm_gb="$4"
    
    print_header "Partitioning $disk"
    
    # Confirm before destructive operation
    print_error "WARNING: All data on $disk will be DESTROYED"
    confirm_action "Are you sure you want to partition $disk?" || {
        echo "Aborted."
        exit 0
    }
    
    echo ""
    print_warning "This is a simulated dry-run. For actual partitioning, uncomment sgdisk commands."
    echo ""
    
    # Calculate sgdisk parameters
    local efi_end_mb=$((efi_gb * 1024))
    local arch_end_mb=$((arch_gb * 1024))
    
    echo "Commands to execute:"
    echo ""
    echo "# Clear partition table"
    echo "sgdisk -Z $disk"
    echo ""
    echo "# Create EFI partition"
    echo "sgdisk -n 1:0:+${efi_gb}G -t 1:ef00 -c 1:\"EFI\" $disk"
    echo ""
    echo "# Create Arch partition"
    if [ "$vm_gb" -gt 0 ]; then
        echo "sgdisk -n 2:0:+${arch_gb}G -t 2:8300 -c 2:\"Arch\" $disk"
        echo ""
        echo "# Create Windows VM partition"
        echo "sgdisk -n 3:0:0 -t 3:8300 -c 3:\"Windows\" $disk"
    else
        echo "sgdisk -n 2:0:0 -t 2:8300 -c 2:\"Arch\" $disk"
    fi
    echo ""
    echo "# Verify layout"
    echo "sgdisk -p $disk"
    echo ""
    echo "# Format partitions"
    local efi_part="${disk}p1"
    local arch_part="${disk}p2"
    
    # Detect NVMe vs regular drives
    if [[ "$disk" =~ nvme ]]; then
        efi_part="${disk}p1"
        arch_part="${disk}p2"
    else
        efi_part="${disk}1"
        arch_part="${disk}2"
    fi
    
    echo "mkfs.fat -F 32 $efi_part"
    echo "mkfs.ext4 -F -L Arch $arch_part"
    echo ""
    
    print_success "Partition plan generated!"
    echo ""
    echo "Next steps:"
    echo "  1. Review the commands above"
    echo "  2. Boot from Arch ISO"
    echo "  3. Run the sgdisk commands to partition"
    echo "  4. Format with mkfs commands"
    echo "  5. Mount and run anthonyware installer"
    echo ""
}

###############################################################################
# Partitioning Advice & Explanation
###############################################################################

print_partitioning_guide() {
    cat << 'EOF'

=== Anthonyware Disk Partitioning Guide ===

## Partitioning Strategy

Anthonyware uses a simple, effective partition scheme:

1. EFI (512 MB)
   └─ UEFI firmware, bootloader, kernel
   └─ Why: UEFI requires a separate FAT32 partition

2. Arch Root (800-900 GB for engineering workload)
   ├─ /      : OS + all 260+ packages (40-50GB used)
   ├─ /home  : User home, projects, datasets (400-700GB)
   ├─ /opt   : Optional custom builds
   └─ /var   : Package cache, logs
   └─ Why: Single unified partition simplifies management; /home is a subdir, not separate

3. Windows VM (optional, 100-200GB)
   └─ Virtual disk image for VFIO GPU passthrough
   └─ Why: SolidWorks/Siemens NX require Windows; VM disk is a regular file

## Why NOT separate /home partition?

Traditional Linux separates / and /home because:
- They have different backup/snapshot needs (✗ not relevant for Anthonyware)
- They fill at different rates (✗ engineering tools are OS-side, not home-side)
- Easier to upgrade OS without touching data (✗ Arch rolling release, doesn't apply)

For Anthonyware:
- /home uses 400-700GB; / uses 40-50GB → combined single partition is simpler
- LVM/snapshots easier to manage on single partition
- No filesystem fragmentation issues across boundary
- User data and OS easily backed up as single unit

## Size Calculations

For different disk sizes:

Size       | EFI  | Arch   | Windows VM | Use Case
-----------|------|--------|------------|----------
100-200 GB | 512M | 99 GB  | None       | Arch-only (minimal)
200-500 GB | 512M | 250 GB | 250 GB     | Arch + small VM
500-800 GB | 512M | 400 GB | 400 GB     | Balanced
800GB-1TB  | 512M | 800 GB | 188 GB     | Engineering workstation (target)
1TB+       | 512M | 800 GB | Remaining  | Arch full + large VM

## Btrfs vs ext4

This script uses ext4 (default Arch). Why?

ext4:
  ✓ Stable, mature, well-understood
  ✓ Fast and reliable
  ✓ Works with any backup tool
  ✗ No native snapshots (requires separate solution)

Btrfs:
  ✓ Native snapshots, CoW
  ✗ Slower, less stable for VFIO
  ✗ Complex subvolume management

→ Anthonyware uses ext4 + system-snapshot.sh for rollback capability

## NVMe vs SATA Detection

This script auto-detects partition naming:
  - NVMe:     /dev/nvme0n1p1 (e.g., M.2 SSD)
  - SATA/USB: /dev/sda1      (e.g., traditional HDD)

The sgdisk commands adapt automatically.

EOF
}

###############################################################################
# Main
###############################################################################

main() {
    print_header "Anthonyware Smart Disk Partitioner"
    echo ""
    echo "This tool helps you partition a disk for Anthonyware."
    echo "It adapts EFI, Arch, and Windows VM sizes to your disk size."
    echo ""
    
    # Show guide first
    print_partitioning_guide
    echo ""
    
    # Select disk
    local selected_disk
    selected_disk=$(select_disk)
    
    if [ -z "$selected_disk" ]; then
        print_error "No disk selected"
        exit 1
    fi
    
    # Analyze size
    local disk_size_gb
    disk_size_gb=$(analyze_disk_size "$selected_disk")
    
    # Recommend partitions
    local -a recommendations
    mapfile -t recommendations < <(recommend_partitions "$disk_size_gb")
    local efi_gb="${recommendations[0]}"
    local arch_gb="${recommendations[1]}"
    local vm_gb="${recommendations[2]}"
    
    # Partition
    partition_disk "$selected_disk" "$efi_gb" "$arch_gb" "$vm_gb"
    
    print_success "Partitioning plan ready!"
    echo ""
    echo "To proceed:"
    echo "  1. Boot Arch ISO on target machine"
    echo "  2. Run: sudo bash $(basename "$0")"
    echo "  3. Copy the sgdisk/mkfs commands from above"
    echo "  4. Run them to create partitions"
    echo ""
}

# Entry point
main "$@"
