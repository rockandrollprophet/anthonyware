#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — GPU Troubleshooter
#
#  Diagnoses and fixes common GPU and driver issues
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== GPU Troubleshooter ===${NC}"
echo

# Detect GPU
echo -e "${CYAN}[1/6] Detecting GPUs${NC}"
echo "───────────────────────────────────"

if command -v lspci &>/dev/null; then
    GPUS=$(lspci | grep -iE 'vga|3d|display')
    if [[ -n "$GPUS" ]]; then
        echo "$GPUS" | while read -r line; do
            echo "  • $line"
        done
        
        # Identify vendor
        if echo "$GPUS" | grep -iq 'nvidia'; then
            GPU_VENDOR="nvidia"
            echo -e "${GREEN}✓${NC} NVIDIA GPU detected"
        elif echo "$GPUS" | grep -iq 'amd'; then
            GPU_VENDOR="amd"
            echo -e "${GREEN}✓${NC} AMD GPU detected"
        elif echo "$GPUS" | grep -iq 'intel'; then
            GPU_VENDOR="intel"
            echo -e "${GREEN}✓${NC} Intel GPU detected"
        else
            GPU_VENDOR="unknown"
            echo -e "${YELLOW}⚠${NC} Unknown GPU vendor"
        fi
    else
        GPU_VENDOR="none"
        echo -e "${RED}✗${NC} No GPU detected"
    fi
else
    GPU_VENDOR="unknown"
    echo -e "${YELLOW}⚠${NC} lspci not available"
fi

echo

# Check drivers
echo -e "${CYAN}[2/6] Checking GPU Drivers${NC}"
echo "───────────────────────────────────"

case "$GPU_VENDOR" in
    nvidia)
        if lsmod | grep -q nvidia; then
            echo -e "${GREEN}✓${NC} NVIDIA kernel modules loaded"
            NVIDIA_VER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "unknown")
            echo "  Driver version: $NVIDIA_VER"
        else
            echo -e "${RED}✗${NC} NVIDIA kernel modules NOT loaded"
        fi
        
        if command -v nvidia-smi &>/dev/null; then
            echo -e "${GREEN}✓${NC} nvidia-smi available"
        else
            echo -e "${RED}✗${NC} nvidia-smi not found"
        fi
        ;;
        
    amd)
        if lsmod | grep -q amdgpu; then
            echo -e "${GREEN}✓${NC} AMDGPU kernel module loaded"
        else
            echo -e "${RED}✗${NC} AMDGPU kernel module NOT loaded"
        fi
        
        if command -v rocm-smi &>/dev/null; then
            echo -e "${GREEN}✓${NC} ROCm tools available"
        else
            echo -e "${YELLOW}⚠${NC} ROCm tools not installed (optional)"
        fi
        ;;
        
    intel)
        if lsmod | grep -q i915; then
            echo -e "${GREEN}✓${NC} Intel i915 kernel module loaded"
        else
            echo -e "${YELLOW}⚠${NC} Intel i915 kernel module not loaded"
        fi
        ;;
        
    *)
        echo -e "${YELLOW}⚠${NC} Cannot check drivers for unknown GPU"
        ;;
esac

echo

# Check Vulkan
echo -e "${CYAN}[3/6] Checking Vulkan Support${NC}"
echo "───────────────────────────────────"

if command -v vulkaninfo &>/dev/null; then
    VULKAN_DEVICES=$(vulkaninfo --summary 2>/dev/null | grep -c "GPU" || echo "0")
    if [[ "$VULKAN_DEVICES" -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} Vulkan is working ($VULKAN_DEVICES device(s))"
    else
        echo -e "${RED}✗${NC} No Vulkan devices found"
    fi
else
    echo -e "${YELLOW}⚠${NC} vulkaninfo not found (install vulkan-tools)"
fi

echo

# Check OpenGL
echo -e "${CYAN}[4/6] Checking OpenGL Support${NC}"
echo "───────────────────────────────────"

if command -v glxinfo &>/dev/null; then
    GL_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer" || echo "unknown")
    GL_VERSION=$(glxinfo 2>/dev/null | grep "OpenGL version" || echo "unknown")
    
    if [[ "$GL_RENDERER" != "unknown" ]]; then
        echo -e "${GREEN}✓${NC} OpenGL is working"
        echo "  $GL_RENDERER"
        echo "  $GL_VERSION"
    else
        echo -e "${RED}✗${NC} OpenGL not working"
    fi
else
    echo -e "${YELLOW}⚠${NC} glxinfo not found (install mesa-utils)"
fi

echo

# Check CUDA (NVIDIA only)
if [[ "$GPU_VENDOR" == "nvidia" ]]; then
    echo -e "${CYAN}[5/6] Checking CUDA${NC}"
    echo "───────────────────────────────────"
    
    if command -v nvcc &>/dev/null; then
        CUDA_VER=$(nvcc --version | grep "release" | awk '{print $5}' | cut -d',' -f1)
        echo -e "${GREEN}✓${NC} CUDA installed: $CUDA_VER"
    else
        echo -e "${YELLOW}⚠${NC} CUDA toolkit not installed (optional)"
    fi
    
    if nvidia-smi &>/dev/null; then
        echo
        nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv
    fi
    echo
else
    echo -e "${CYAN}[5/6] CUDA Check (NVIDIA Only)${NC}"
    echo "───────────────────────────────────"
    echo -e "${YELLOW}⚠${NC} Not applicable (non-NVIDIA GPU)"
    echo
fi

# Check display server
echo -e "${CYAN}[6/6] Checking Display Server${NC}"
echo "───────────────────────────────────"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo -e "${GREEN}✓${NC} Running on Wayland: $WAYLAND_DISPLAY"
elif [[ -n "${DISPLAY:-}" ]]; then
    echo -e "${GREEN}✓${NC} Running on X11: $DISPLAY"
else
    echo -e "${RED}✗${NC} No display server detected"
fi

echo

# Repair options
echo -e "${CYAN}Repair Options${NC}"
echo "───────────────────────────────────"
echo

if [[ "$GPU_VENDOR" == "nvidia" ]]; then
    if ! lsmod | grep -q nvidia; then
        read -rp "Load NVIDIA kernel modules? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            echo "Loading NVIDIA modules..."
            sudo modprobe nvidia nvidia_modeset nvidia_uvm nvidia_drm
            echo -e "${GREEN}✓${NC} Modules loaded"
        fi
    fi
    
    read -rp "Show detailed NVIDIA info (nvidia-smi)? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        nvidia-smi
    fi
    
elif [[ "$GPU_VENDOR" == "amd" ]]; then
    if ! lsmod | grep -q amdgpu; then
        read -rp "Load AMDGPU kernel module? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            echo "Loading AMDGPU module..."
            sudo modprobe amdgpu
            echo -e "${GREEN}✓${NC} Module loaded"
        fi
    fi
fi

echo
echo -e "${GREEN}=== GPU Troubleshooting Complete ===${NC}"
echo
echo "Additional commands:"
echo "  • List GPUs:          lspci | grep -i vga"
echo "  • Kernel messages:    dmesg | grep -i gpu"
echo "  • Driver logs:        journalctl -k | grep -i nvidia"
echo "  • Vulkan devices:     vulkaninfo --summary"
