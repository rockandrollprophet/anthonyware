#!/usr/bin/env bash
set -euo pipefail

# Check if running as root or via sudo
if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "=== [24] Cleanup & Verification ==="

echo "[1/5] Cleaning orphaned packages..."
# Clean orphan packages safely
orphans=$(pacman -Qtdq 2>/dev/null || true)
if [[ -n "$orphans" ]]; then
  orphan_count=$(echo "$orphans" | wc -l)
  echo "Found $orphan_count orphaned package(s), removing..."
  echo "$orphans" | xargs ${SUDO} pacman -Rns --noconfirm || echo "⚠ Some orphans could not be removed (safe to ignore)"
  echo "✓ Orphaned packages cleaned"
else
  echo "✓ No orphaned packages found"
fi

echo ""
echo "[2/5] Running final system update..."
if ${SUDO} pacman -Syu --noconfirm; then
  echo "✓ System updated successfully"
else
  echo "⚠ System update encountered issues (may need manual review)"
fi

echo ""
echo "[3/5] Verifying GPU detection..."
if lspci | grep -E "VGA|3D" | tee /tmp/gpu-info.txt; then
  echo "✓ GPU detected"
else
  echo "⚠ No GPU detected or lspci unavailable"
fi

echo ""
echo "[4/5] Verifying virtualization support..."
if grep -qE '(vmx|svm)' /proc/cpuinfo; then
  virt_type=$(grep -oE '(vmx|svm)' /proc/cpuinfo | head -n1)
  virt_cores=$(grep -cE '(vmx|svm)' /proc/cpuinfo)
  echo "✓ Virtualization enabled: $virt_type ($virt_cores cores)"
else
  echo "⚠ Virtualization extensions not detected"
  echo "  VM functionality may be limited"
fi

echo ""
echo "[5/5] Verifying display session type..."
if [[ -n "${XDG_SESSION_TYPE:-}" ]]; then
  echo "✓ Session type: ${XDG_SESSION_TYPE}"
  if [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; then
    echo "  ✓ Running Wayland (optimal for Hyprland)"
  elif [[ "${XDG_SESSION_TYPE}" == "x11" ]]; then
    echo "  ⚠ Running X11 (Hyprland requires Wayland)"
  fi
else
  echo "⊙ Session type not detected (may not be in graphical session)"
  echo "  This is normal if running from TTY"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Cleanup & Verification Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"