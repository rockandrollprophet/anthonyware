#!/usr/bin/env bash
# test-framework.sh - Testing framework for Anthonyware installation

set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$TEST_DIR")"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking
declare -a FAILED_TESTS=()

# Helper functions
test_start() {
  echo -e "${BLUE}▶ $1${NC}"
}

test_pass() {
  echo -e "${GREEN}✓ $1${NC}"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}✗ $1${NC}"
  FAILED_TESTS+=("$1")
  ((TESTS_FAILED++))
}

test_skip() {
  echo -e "${YELLOW}⊘ $1${NC}"
  ((TESTS_SKIPPED++))
}

# Test: Script syntax validation
test_script_syntax() {
  test_start "Testing script syntax..."
  
  local failed=0
  while IFS= read -r script; do
    if ! bash -n "$script" 2>/dev/null; then
      test_fail "Syntax error in $(basename "$script")"
      failed=1
    fi
  done < <(find "$REPO_ROOT/install" -name "*.sh" -type f)
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All scripts have valid syntax"
  fi
}

# Test: Required files exist
test_required_files() {
  test_start "Checking required files..."
  
  local required_files=(
    "install-anthonyware.sh"
    "install/00-create-user.sh"
    "install/run-all.sh"
    "install/03-hyprland.sh"
    "install/33-user-configs.sh"
    "configs/hypr/hyprland.conf"
    "configs/kitty/kitty.conf"
    "configs/waybar/config.jsonc"
  )
  
  local failed=0
  for file in "${required_files[@]}"; do
    if [[ ! -f "$REPO_ROOT/$file" ]]; then
      test_fail "Missing required file: $file"
      failed=1
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All required files present"
  fi
}

# Test: Scripts have proper shebang
test_shebangs() {
  test_start "Checking script shebangs..."
  
  local failed=0
  while IFS= read -r script; do
    local first_line=$(head -n1 "$script")
    if [[ ! "$first_line" =~ ^#!/usr/bin/env\ bash$ && ! "$first_line" =~ ^#!/bin/bash$ ]]; then
      test_fail "Invalid/missing shebang in $(basename "$script")"
      failed=1
    fi
  done < <(find "$REPO_ROOT/install" -name "*.sh" -type f)
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All scripts have valid shebangs"
  fi
}

# Test: Scripts are executable
test_executable() {
  test_start "Checking script permissions..."
  
  local failed=0
  local fixed=0
  while IFS= read -r script; do
    if [[ ! -x "$script" ]]; then
      chmod +x "$script" 2>/dev/null || true
      if [[ -x "$script" ]]; then
        echo "  → Fixed permissions for $(basename "$script")"
        ((fixed++))
      else
        test_fail "Not executable: $(basename "$script")"
        failed=1
      fi
    fi
  done < <(find "$REPO_ROOT/install" -name "*.sh" -type f)
  
  if [[ $failed -eq 0 ]]; then
    if [[ $fixed -gt 0 ]]; then
      test_pass "All scripts are executable (fixed $fixed)"
    else
      test_pass "All scripts are executable"
    fi
  fi
}

# Test: No hardcoded sudo
test_no_hardcoded_sudo() {
  test_start "Checking for hardcoded sudo..."
  
  local failed=0
  while IFS= read -r script; do
    # Skip if it has ${SUDO} or $SUDO variable usage
    if grep -q 'sudo ' "$script" && ! grep -q '\${SUDO}' "$script"; then
      # Check if it's in a comment
      if ! grep 'sudo ' "$script" | grep -q '^[[:space:]]*#'; then
        test_fail "Hardcoded sudo in $(basename "$script")"
        failed=1
      fi
    fi
  done < <(find "$REPO_ROOT/install" -name "[0-9]*.sh" -type f)
  
  if [[ $failed -eq 0 ]]; then
    test_pass "No hardcoded sudo commands"
  fi
}

# Test: Config files are valid
test_config_syntax() {
  test_start "Validating config files..."
  
  # Test JSON files
  local failed=0
  while IFS= read -r json_file; do
    if ! python3 -m json.tool "$json_file" >/dev/null 2>&1; then
      test_fail "Invalid JSON: $(basename "$json_file")"
      failed=1
    fi
  done < <(find "$REPO_ROOT/configs" -name "*.json" -type f)
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All config files valid"
  fi
}

# Test: No TODO or FIXME in critical files
test_no_todos() {
  test_start "Checking for TODO/FIXME markers..."
  
  local todos=$(grep -r "TODO\|FIXME" "$REPO_ROOT/install/"*.sh 2>/dev/null || true)
  
  if [[ -n "$todos" ]]; then
    test_skip "Found TODO/FIXME markers (not a failure)"
    echo "$todos" | head -n5
  else
    test_pass "No TODO/FIXME markers in install scripts"
  fi
}

# Test: SDDM package is included
test_sddm_package() {
  test_start "Checking SDDM package installation..."
  
  if grep -q "sddm" "$REPO_ROOT/install/03-hyprland.sh"; then
    test_pass "SDDM package is in 03-hyprland.sh"
  else
    test_fail "SDDM package missing from 03-hyprland.sh"
  fi
}

# Test: User creation is manual
test_manual_user_creation() {
  test_start "Checking user creation workflow..."
  
  if grep -q "read.*username" "$REPO_ROOT/install-anthonyware.sh"; then
    test_fail "install-anthonyware.sh still prompts for username"
  elif [[ ! -f "$REPO_ROOT/install/00-create-user.sh" ]]; then
    test_fail "Missing 00-create-user.sh"
  else
    test_pass "User creation is manual (00-create-user.sh exists)"
  fi
}

# Test: Library files exist
test_library_files() {
  test_start "Checking library files..."
  
  local libs=(
    "install/lib/checkpoint.sh"
    "install/lib/logging.sh"
    "install/lib/hardware.sh"
    "install/lib/validation.sh"
    "install/lib/backup.sh"
    "install/lib/network.sh"
    "install/lib/interactive.sh"
    "install/lib/report.sh"
    "install/lib/version-pin.sh"
    "install/lib/health.sh"
    "install/lib/snapshot.sh"
    "install/lib/overlay.sh"
    "install/lib/secrets.sh"
    "install/lib/sandbox.sh"
    "install/lib/supplychain.sh"
    "install/lib/posture.sh"
    "install/lib/repro.sh"
    "install/lib/metrics.sh"
    "install/lib/tui.sh"
    "install/lib/cache.sh"
    "install/lib/parallel.sh"
    "install/lib/lean.sh"
    "install/lib/policy.sh"
    "install/lib/diff.sh"
    "install/lib/plugin.sh"
  )
  
  local failed=0
  for lib in "${libs[@]}"; do
    if [[ ! -f "$REPO_ROOT/$lib" ]]; then
      test_fail "Missing library: $lib"
      failed=1
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All library files present"
  fi
}

# Test: Profile files exist
test_profile_files() {
  test_start "Checking profile files..."
  
  local profiles=(
    "profiles/minimal.conf"
    "profiles/developer.conf"
    "profiles/workstation.conf"
    "profiles/gamer.conf"
    "profiles/homelab.conf"
    "profiles/laptop.conf"
    "profiles/server.conf"
    "profiles/cloud.conf"
    "profiles/color-managed.conf"
    "profiles/full.conf"
  )
  
  local failed=0
  for profile in "${profiles[@]}"; do
    if [[ ! -f "$REPO_ROOT/$profile" ]]; then
      test_fail "Missing profile: $profile"
      failed=1
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    test_pass "All profile files present"
  fi
}

# Run all tests
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Anthonyware Testing Framework                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo

test_script_syntax
test_required_files
test_shebangs
test_executable
test_no_hardcoded_sudo
test_config_syntax
test_no_todos
test_sddm_package
test_manual_user_creation
test_library_files
test_profile_files

# Summary
echo
echo "╔══════════════════════════════════════════════════════════╗"
echo "║ Test Results                                              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${GREEN}Passed:${NC}  $TESTS_PASSED"
echo -e "${RED}Failed:${NC}  $TESTS_FAILED"
echo -e "${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
echo

if [[ $TESTS_FAILED -gt 0 ]]; then
  echo "Failed tests:"
  for test in "${FAILED_TESTS[@]}"; do
    echo "  - $test"
  done
  exit 1
else
  echo -e "${GREEN}✓ All tests passed!${NC}"
  exit 0
fi
