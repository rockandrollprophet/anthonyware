#!/usr/bin/env bash
set -euo pipefail

echo "=== GPU Check ==="

echo "Detected GPUs:"
lspci | grep -E "VGA|3D"

echo
echo "NVIDIA Modules:"
lsmod | grep nvidia || echo "No NVIDIA modules loaded."

echo
echo "VFIO Bindings:"
lspci -nnk | grep -A3 -E "VGA|3D"

echo "=== GPU Check Complete ==="
