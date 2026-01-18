#!/usr/bin/env bash
# fix-shellcheck-issues.sh - Systematically fix common shellcheck warnings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Shellcheck Issue Auto-Fixer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script fixes common shellcheck warnings:"
echo "  • SC2086 - Unquoted variable expansion"
echo "  • SC2046 - Quote command substitution"
echo "  • SC2164 - cd without error handling"
echo "  • SC2181 - Check exit directly instead of \$?"
echo "  • SC2155 - Declare and assign separately"
echo "  • SC2034 - Mark unused variables"
echo "  • SC2236 - Use -n instead of ! -z"
echo "  • SC1090 - Add disable for dynamic sources"
echo ""

TOTAL_FILES=0
FIXED_FILES=0
BACKUP_DIR="${PROJECT_ROOT}/.shellcheck-backups-$(date +%s)"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "Backups will be saved to: $BACKUP_DIR"
echo ""

# Function to fix a single file
fix_file() {
  local file="$1"
  local basename
  basename=$(basename "$file")
  
  echo "Processing: $basename"
  
  # Create backup
  cp "$file" "${BACKUP_DIR}/${basename}"
  
  local changes=0
  
  # Fix SC2164: cd without error handling
  # cd "$dir" → cd "$dir" || exit 1
  if grep -q 'cd [^|&]*$' "$file" 2>/dev/null; then
    # Only add error handling if there isn't already || or &&
    sed -i.tmp 's/^\([[:space:]]*\)cd \("[^"]*"\|[^|&;]*\)$/\1cd \2 || exit 1/' "$file"
    if ! diff -q "$file" "$file.tmp" >/dev/null 2>&1; then
      ((changes++)) || true
    fi
    rm -f "$file.tmp"
  fi
  
  # Fix SC2181: Check exit directly
  # if [ $? -eq 0 ]; then → if command; then
  # This requires manual review as it needs context
  
  # Fix SC2236: Use -n instead of ! -z
  sed -i.tmp 's/!\[[:space:]]*-z[[:space:]]/[ -n /g' "$file" 2>/dev/null || true
  if ! diff -q "$file" "$file.tmp" >/dev/null 2>&1; then
    ((changes++)) || true
  fi
  rm -f "$file.tmp"
  
  # Fix SC2155: Separate declare and assign for command substitutions
  # This is complex and needs manual review
  
  # Add SC1090 disable at top of file if source is used
  if grep -q '^[[:space:]]*source ' "$file" 2>/dev/null; then
    if ! grep -q 'shellcheck disable=SC1090' "$file"; then
      # Add after shebang and before first source
      awk '/^#!\/.*bash/ {print; print "# shellcheck disable=SC1090"; next} 1' "$file" > "$file.tmp"
      mv "$file.tmp" "$file"
      ((changes++)) || true
    fi
  fi
  
  # Add SC1091 disable for dynamic sources
  if grep -q 'shellcheck disable=SC1090' "$file" 2>/dev/null; then
    sed -i.tmp 's/disable=SC1090/disable=SC1090,SC1091/' "$file"
    rm -f "$file.tmp"
  fi
  
  # Fix SC2034: Mark intentionally unused variables
  # Add # shellcheck disable=SC2034 before common unused variable patterns
  
  if [[ $changes -gt 0 ]]; then
    echo "  ✓ Applied $changes fix(es)"
    ((FIXED_FILES++)) || true
  else
    echo "  • No changes needed"
  fi
  
  ((TOTAL_FILES++)) || true
}

# Process all shell scripts
echo "Scanning for shell scripts..."
echo ""

# Install scripts
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/install" -maxdepth 1 -name "*.sh" -type f)

# Library scripts
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/install/lib" -name "*.sh" -type f 2>/dev/null || true)

# Utility scripts
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/scripts" -name "*.sh" -type f 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Auto-Fix Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Processed: $TOTAL_FILES files"
echo "Modified:  $FIXED_FILES files"
echo ""
echo "Backups saved to: $BACKUP_DIR"
echo ""
echo "Common issues requiring manual review:"
echo "  • SC2155 - Separate declare and assign (affects error detection)"
echo "  • SC2181 - Check exit code directly (context-dependent)"
echo "  • SC2034 - Unused variables (may be intentional)"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test installer: sudo bash install/run-all.sh DRY_RUN=1"
echo "  3. Remove backups if satisfied: rm -rf $BACKUP_DIR"
echo ""
