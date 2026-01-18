#!/usr/bin/env bash
# apply-quoting-fixes.sh - Systematic variable quoting improvements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/../install"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Applying Variable Quoting Fixes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Common patterns to fix:
# 1. echo $VAR → echo "$VAR" or echo "${VAR}"
# 2. if [ $VAR ... → if [[ "$VAR" ...
# 3. command $VAR → command "$VAR"
# 4. for x in $LIST → for x in "${LIST[@]}"

FIXED_COUNT=0
SCRIPT_COUNT=0

# Function to check if variable should be quoted
should_quote() {
  local line="$1"
  
  # Skip if already quoted
  if [[ "$line" =~ \"\$ ]] || [[ "$line" =~ \$\{ ]]; then
    return 1
  fi
  
  # Check for unquoted variables in common positions
  if [[ "$line" =~ (echo|test|if|while|until|for)\ +\$[A-Z_]+ ]]; then
    return 0
  fi
  
  return 1
}

echo "Scanning install scripts..."

# Process all shell scripts in install directory
while IFS= read -r script; do
  ((SCRIPT_COUNT++))
  echo "Checking: $(basename "$script")"
  
  # Create backup
  cp "$script" "${script}.quotefixbak"
  
  # Apply fixes (using sed for common patterns)
  # Note: These are safe transformations that improve robustness
  
  # Fix: echo $VAR → echo "$VAR" (but avoid if already quoted)
  sed -i 's/echo \$\([A-Z_][A-Z_0-9]*\)\([^"].*\)$/echo "$\1"\2/g' "$script" 2>/dev/null || true
  
  # Fix: [ $VAR ] → [[ "$VAR" ]] in test conditions
  sed -i 's/\[ \$\([A-Z_][A-Z_0-9]*\) /[[ "$\1" /g' "$script" 2>/dev/null || true
  
  # Check if any changes were made
  if ! diff -q "$script" "${script}.quotefixbak" >/dev/null 2>&1; then
    ((FIXED_COUNT++))
    echo "  ✓ Applied fixes"
  else
    echo "  • No changes needed"
  fi
  
  # Remove backup if no changes
  if diff -q "$script" "${script}.quotefixbak" >/dev/null 2>&1; then
    rm "${script}.quotefixbak"
  fi
  
done < <(find "$INSTALL_DIR" -maxdepth 2 -name "*.sh" -type f)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Variable Quoting Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Scanned:  $SCRIPT_COUNT scripts"
echo "Modified: $FIXED_COUNT scripts"
echo ""
echo "Backups created with .quotefixbak extension"
echo "Review changes and remove backups if satisfied:"
echo "  find $INSTALL_DIR -name '*.quotefixbak' -delete"
echo ""
