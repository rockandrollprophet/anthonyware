#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  usb-integrity-check.sh
#  Verify Anthonyware repo on USB is complete and valid
#  Checks for required files and git status
# ============================================================

echo "=== Anthonyware USB Integrity Check ==="
echo

ERRORS=0

# Check if we're in a git repo
if [[ ! -d .git ]]; then
  echo "[FAIL] Not a git repository (no .git directory)"
  ERRORS=$((ERRORS + 1))
else
  echo "[ OK ] Git repository detected"
fi

echo

# Check working tree status
echo "[*] Checking git status..."
if ! git diff --quiet 2>/dev/null; then
  echo "[WARN] Uncommitted modifications in working directory"
else
  echo "[ OK ] Working directory clean"
fi

if ! git diff --cached --quiet 2>/dev/null; then
  echo "[WARN] Staged changes present"
else
  echo "[ OK ] No staged changes"
fi

echo

# Check for required files
echo "[*] Verifying required files..."

REQUIRED_FILES=(
  "README.md"
  "install-anthonyware.sh"
  "run-from-usb.sh"
  "install/run-all.sh"
  "install/33-user-configs.sh"
  "install/35-validation.sh"
  "usb/autorun.service"
  "usb/anthonyware-usb-autorun"
  "usb/install-autorun-into-live.sh"
  "usb/ventoy/ventoy.json"
  "scripts/usb-integrity-check.sh"
  "scripts/usb-self-update.sh"
)

missing_count=0
for file in "${REQUIRED_FILES[@]}"; do
  if [[ -e "$file" ]]; then
    echo "[ OK ] $file"
  else
    echo "[FAIL] Missing: $file"
    ERRORS=$((ERRORS + 1))
    missing_count=$((missing_count + 1))
  fi
done

echo

# Check executability of scripts
echo "[*] Checking script executability..."

SCRIPTS=(
  "install-anthonyware.sh"
  "run-from-usb.sh"
  "usb/anthonyware-usb-autorun"
  "usb/install-autorun-into-live.sh"
  "scripts/usb-integrity-check.sh"
  "scripts/usb-self-update.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" ]]; then
    if [[ -x "$script" ]]; then
      echo "[ OK ] $script is executable"
    else
      echo "[WARN] $script is NOT executable (chmod +x needed)"
    fi
  fi
done

echo

# Check for safety lock marker
echo "[*] Checking autorun safety lock..."
if [[ -f "USB_AUTORUN_ENABLED" ]]; then
  echo "[WARN] USB_AUTORUN_ENABLED present - autorun is ARMED"
else
  echo "[ OK ] USB_AUTORUN_ENABLED not present - autorun is DISARMED"
fi

echo

# Summary
echo "=============================================="
if [[ $ERRORS -eq 0 ]]; then
  echo "✓ Integrity check PASSED"
  exit 0
else
  echo "✗ Integrity check FAILED ($ERRORS issues)"
  exit 1
fi
