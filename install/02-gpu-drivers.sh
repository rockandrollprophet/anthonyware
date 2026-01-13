#!/usr/bin/env bash
set -euo pipefail

echo "=== ANTHONYWARE GPU DRIVER + IOMMU SETUP ==="

# ---------------------------------------------------------
# 0. Determine real user + home + repo path
# ---------------------------------------------------------
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
REPO="${REPO:-$TARGET_HOME/anthonyware}"

echo "Running as: $TARGET_USER"
echo "Target home: $TARGET_HOME"
echo "Repo path: $REPO"

if [ "$TARGET_USER" = "root" ]; then
    echo "ERROR: Do not run this script as pure root."
    exit 1
fi

if [ ! -d "$REPO" ]; then
    echo "ERROR: Repo not found at $REPO"
    exit 1
fi

# ---------------------------------------------------------
# 1. Preflight command checks
# ---------------------------------------------------------
required_cmds=( pacman sed cp mkdir lspci modinfo )
optional_cmds=( grub-mkconfig mkinitcpio )

echo "[0/6] Running preflight checks..."

for cmd in "${required_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null; then
        echo "ERROR: Required command '$cmd' missing."
        exit 1
    fi
done

for cmd in "${optional_cmds[@]}"; do
    if ! command -v "$cmd" >/dev/null; then
        echo "WARNING: Optional tool '$cmd' missing. Some steps may be skipped."
    fi
done

# ---------------------------------------------------------
# 2. Detect GPU vendor
# ---------------------------------------------------------
echo "[1/6] Detecting GPU vendor..."

GPU_VENDOR="unknown"

if lspci | grep -qi "NVIDIA"; then
    GPU_VENDOR="nvidia"
elif lspci | grep -qi "AMD"; then
    GPU_VENDOR="amd"
elif lspci | grep -qi "Intel"; then
    GPU_VENDOR="intel"
fi

echo "Detected GPU vendor: $GPU_VENDOR"

# ---------------------------------------------------------
# 3. Install GPU drivers (repo only)
# ---------------------------------------------------------
echo "[2/6] Installing GPU drivers..."

case "$GPU_VENDOR" in
    nvidia)
        sudo pacman -Syu --noconfirm || echo "WARNING: pacman -Syu failed; continuing"
        # Ensure kernel headers for current kernel exist for module builds (NVIDIA, CUDA)
        if ! pacman -Si linux-headers >/dev/null 2>&1 && ! pacman -Si linux-lts-headers >/dev/null 2>&1; then
            echo "WARNING: No linux headers package found in repos; NVIDIA/CUDA kernel modules may fail to build."
        fi
        sudo pacman -S --noconfirm --needed nvidia nvidia-utils nvidia-settings dkms linux-headers || { echo "ERROR: Failed to install NVIDIA packages or linux-headers"; exit 1; }
        ;;
    amd)
        sudo pacman -Syu --noconfirm || echo "WARNING: pacman -Syu failed; continuing"
        sudo pacman -S --noconfirm --needed mesa vulkan-radeon libva-mesa-driver mesa-vdpau xf86-video-amdgpu linux-headers || { echo "ERROR: Failed to install AMD packages or linux-headers"; exit 1; }
        ;;
    intel)
        sudo pacman -Syu --noconfirm || echo "WARNING: pacman -Syu failed; continuing"
        sudo pacman -S --noconfirm --needed mesa intel-media-driver vulkan-intel linux-headers || { echo "ERROR: Failed to install Intel packages or linux-headers"; exit 1; }
        ;;
    *)
        echo "WARNING: Unknown GPU vendor. Skipping driver install."
        ;;
esac

# ---------------------------------------------------------
# 4. Validate VFIO modules (only add modules that exist)
# ---------------------------------------------------------
echo "[3/6] Validating VFIO modules..."

vfio_modules=( vfio vfio_pci vfio_iommu_type1 vfio_virqfd )
valid_modules=()

for m in "${vfio_modules[@]}"; do
    if modinfo "$m" >/dev/null 2>&1; then
        valid_modules+=( "$m" )
    else
        echo "NOTICE: Kernel module '$m' not found; skipping."
    fi
done

if (( ${#valid_modules[@]} )); then
    echo "Writing valid VFIO modules to /etc/modules-load.d/vfio.conf"
    sudo cp /etc/modules-load.d/vfio.conf /etc/modules-load.d/vfio.conf.anthonyware.bak 2>/dev/null || true
    printf "%s
" "${valid_modules[@]}" | sudo tee /etc/modules-load.d/vfio.conf >/dev/null
else
    echo "WARNING: No valid VFIO modules found for kernel $(uname -r)"
fi

# ---------------------------------------------------------
# 5. Safe GRUB edits (idempotent)
# ---------------------------------------------------------
echo "[4/6] Updating GRUB kernel parameters (safe mode)..."

if command -v grub-mkconfig >/dev/null && [ -f /etc/default/grub ]; then
    sudo cp /etc/default/grub /etc/default/grub.vfio.bak

    # Insert vendor-specific IOMMU flags only if missing
    case "$GPU_VENDOR" in
        amd)
            if ! grep -q "amd_iommu=on" /etc/default/grub; then
                sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX=")(.*)"/\1\2 amd_iommu=on iommu=pt"/' /etc/default/grub
                echo "Added amd_iommu=on iommu=pt"
            else
                echo "IOMMU flags already present."
            fi
            ;;
        intel)
            if ! grep -q "intel_iommu=on" /etc/default/grub; then
                sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX=")(.*)"/\1\2 intel_iommu=on iommu=pt"/' /etc/default/grub
                echo "Added intel_iommu=on iommu=pt"
            else
                echo "IOMMU flags already present."
            fi
            ;;
        nvidia|unknown)
            echo "No vendor-specific IOMMU flags added automatically for vendor: $GPU_VENDOR"
            ;;
    esac

    sudo grub-mkconfig -o /boot/grub/grub.cfg || { echo "ERROR: grub-mkconfig failed."; exit 1; }
else
    echo "GRUB not detected; skipping GRUB edits."
fi

# ---------------------------------------------------------
# 6. Safe mkinitcpio HOOKS insertion
# ---------------------------------------------------------
echo "[5/6] Updating mkinitcpio HOOKS (safe mode)..."

if command -v mkinitcpio >/dev/null && [ -f /etc/mkinitcpio.conf ]; then
    if ! grep -q "vfio_pci" /etc/mkinitcpio.conf; then
        sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.vfio.bak
        sudo sed -E -i 's/^(HOOKS=\()([^\)]*)(\))/\1\2 vfio_pci\3/' /etc/mkinitcpio.conf
        echo "Inserted vfio_pci into HOOKS."
    else
        echo "vfio_pci already present in HOOKS."
    fi

    sudo mkinitcpio -P || { echo "ERROR: mkinitcpio failed."; exit 1; }
else
    echo "mkinitcpio not available; skipping HOOKS edits."
fi

# ---------------------------------------------------------
# 7. Blacklist NVIDIA on host (for passthrough)
# ---------------------------------------------------------
echo "[6/6] Writing NVIDIA blacklist (if necessary)..."

sudo tee /etc/modprobe.d/blacklist-nvidia.conf >/dev/null <<'EOF'
blacklist nvidia
blacklist nvidia_uvm
blacklist nvidia_modeset
blacklist nvidia_drm
EOF

echo "=== GPU DRIVER + IOMMU SETUP COMPLETE ==="
if [ "$GPU_VENDOR" != "unknown" ]; then
    echo "Reboot required to activate drivers and IOMMU settings."
fi