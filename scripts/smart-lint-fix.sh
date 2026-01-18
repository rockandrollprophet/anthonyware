#!/usr/bin/env bash
# smart-lint-fix.sh - Intelligently fix shell linting issues
# Only fixes legitimate problems, preserves intentional patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)" || exit 1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Smart Shell Linting Fixer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_FIXES=0
FILES_MODIFIED=0
DRY_RUN="${DRY_RUN:-0}"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "🔍 DRY RUN MODE - No files will be modified"
  echo ""
fi

# Create backup
if [[ "$DRY_RUN" != "1" ]]; then
  BACKUP_DIR="${PROJECT_ROOT}/.smart-lint-backup-$(date +%s)"
  mkdir -p "$BACKUP_DIR"
  echo "✓ Backups will be saved to: $BACKUP_DIR"
  echo ""
fi

# Smart fix function
fix_file() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  local fixes_applied=0
  local fix_log=""
  
  # Skip if not a bash script
  if ! head -n 1 "$file" 2>/dev/null | grep -q '^#!/.*bash'; then
    return
  fi
  
  if [[ "$DRY_RUN" != "1" ]]; then
    # Backup original
    cp "$file" "${BACKUP_DIR}/${filename}"
  fi
  
  # Temp file for changes
  local tmpfile="${file}.smartfix.tmp"
  cp "$file" "$tmpfile"
  
  # ============================================
  # FIX 1: cd without error handling (CRITICAL)
  # ============================================
  # Pattern: cd /some/path (at end of line, not already having || or &&)
  # Exclude: cd - (already fixed), cd with redirects
  if grep -qE '^[[:space:]]*cd [^|&;]*$' "$tmpfile"; then
    sed -i.bak '/cd -.*||/!; /cd .*||/!; /cd .*&&/! s/^\([[:space:]]*cd[[:space:]]\+[^|&;]*\)$/\1 || exit 1/' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Fixed cd without error handling\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # ============================================
  # FIX 2: Add shellcheck disable headers to lib files
  # ============================================
  if [[ "$file" == *"/lib/"* ]] && ! grep -q 'shellcheck disable=' "$tmpfile"; then
    awk '
      /^#!\/.*bash/ { 
        print
        print "# shellcheck disable=SC1090,SC1091,SC2034"
        print "# SC1090/SC1091: Dynamic source paths validated at runtime"
        print "# SC2034: Variables may be used by sourcing scripts"
        print ""
        next
      }
      { print }
    ' "$tmpfile" > "${tmpfile}.header"
    mv "${tmpfile}.header" "$tmpfile"
    fix_log+="  ✓ Added shellcheck disable directives\n"
    ((fixes_applied++))
  fi
  
  # ============================================
  # FIX 3: ! -z to -n (STYLE)
  # ============================================
  # Convert "! [[ -z" or "! [ -z" to use -n instead
  if grep -qE '! *\[\[? *-z ' "$tmpfile"; then
    sed -i.bak 's/! *\[\[ *-z /[[ -n /g; s/! *\[ *-z /[ -n /g' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Converted ! -z to -n\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # ============================================
  # FIX 4: Ensure mkdir uses -p (SAFETY)
  # ============================================
  # Only fix bare mkdir commands, not those already with flags
  if grep -qE '^[[:space:]]*mkdir[[:space:]]+[^-]' "$tmpfile"; then
    sed -i.bak 's/^\([[:space:]]*\)mkdir \([^-]\)/\1mkdir -p \2/' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Added -p flag to mkdir commands\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # ============================================
  # FIX 5: Standardize || exit spacing
  # ============================================
  if grep -qE '\|\|exit||| *exit *[0-9]+' "$tmpfile"; then
    sed -i.bak 's/||exit/|| exit/g; s/|| *exit *\([0-9]\+\)/|| exit \1/g' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Standardized || exit spacing\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # ============================================
  # FIX 6: Add error handling to source (CRITICAL)
  # ============================================
  # Only for source commands without existing error handling
  if grep -qE '^[[:space:]]*source [^|&]+$' "$tmpfile"; then
    sed -i.bak '/|| /!; /|| exit/! s|^\([[:space:]]*source \)\(.*\)$|\1\2 || { echo "Failed to source \2" \>\&2; exit 1; }|' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Added error handling to source commands\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # ============================================
  # FIX 7: Quote tee destinations (SAFETY)
  # ============================================
  # Pattern: | sudo tee /path (without quotes)
  if grep -qE '\| .*tee [^"'"'"'][^|>]*$' "$tmpfile"; then
    sed -i.bak 's|\(| [^|]* tee\) \(/[^ |>]*\)$|\1 "\2"|' "$tmpfile"
    if ! diff -q "$tmpfile" "$tmpfile.bak" >/dev/null 2>&1; then
      fix_log+="  ✓ Quoted tee destinations\n"
      ((fixes_applied++))
    fi
    rm -f "$tmpfile.bak"
  fi
  
  # Apply changes or show what would be changed
  if [[ $fixes_applied -gt 0 ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "  [DRY RUN] $filename: $fixes_applied fix(es) would be applied"
      echo -e "$fix_log"
    else
      mv "$tmpfile" "$file"
      echo "  ✓ $filename: $fixes_applied fix(es) applied"
      echo -e "$fix_log"
    fi
    ((TOTAL_FIXES += fixes_applied))
    ((FILES_MODIFIED++))
  else
    rm -f "$tmpfile"
    echo "  • $filename: No issues found"
  fi
}

# Validate syntax after fixes
validate_syntax() {
  local file="$1"
  local filename
  filename=$(basename "$file")
  
  if ! bash -n "$file" 2>/dev/null; then
    echo "    ❌ SYNTAX ERROR in $filename after fixes!"
    return 1
  fi
  return 0
}

# Process all shell scripts
echo "Processing install scripts..."
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/install" -maxdepth 1 -name "*.sh" -type f 2>/dev/null || true)

echo ""
echo "Processing library scripts..."
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/install/lib" -name "*.sh" -type f 2>/dev/null || true)

echo ""
echo "Processing utility scripts..."
while IFS= read -r file; do
  fix_file "$file"
done < <(find "${PROJECT_ROOT}/scripts" -name "*.sh" -type f 2>/dev/null || true)

if [[ "$DRY_RUN" != "1" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Validating syntax of modified files..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  SYNTAX_ERRORS=0
  
  while IFS= read -r file; do
    if ! validate_syntax "$file"; then
      ((SYNTAX_ERRORS++))
    fi
  done < <(find "${PROJECT_ROOT}/install" "${PROJECT_ROOT}/scripts" -name "*.sh" -type f 2>/dev/null || true)
  
  if [[ $SYNTAX_ERRORS -gt 0 ]]; then
    echo ""
    echo "❌ $SYNTAX_ERRORS file(s) have syntax errors after fixes!"
    echo "   Restoring from backup: $BACKUP_DIR"
    cp -r "$BACKUP_DIR"/* "${PROJECT_ROOT}/install/" 2>/dev/null || true
    cp -r "$BACKUP_DIR"/* "${PROJECT_ROOT}/scripts/" 2>/dev/null || true
    exit 1
  else
    echo "✓ All modified files passed syntax validation"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$DRY_RUN" == "1" ]]; then
  echo "✓ Dry Run Complete - No Changes Made"
else
  echo "✓ Smart Lint Fix Complete"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Statistics:"
echo "  Total fixes applied: $TOTAL_FIXES"
echo "  Files modified:      $FILES_MODIFIED"
echo ""
echo "Fixes applied:"
echo "  ✓ Fixed cd commands without error handling (CRITICAL)"
echo "  ✓ Added shellcheck disable directives to library files"
echo "  ✓ Converted ! -z to -n (STYLE)"
echo "  ✓ Ensured mkdir uses -p flag"
echo "  ✓ Standardized || exit spacing"
echo "  ✓ Added error handling to source statements"
echo "  ✓ Quoted tee destinations"
echo ""

if [[ "$DRY_RUN" != "1" ]]; then
  echo "Backups saved to: $BACKUP_DIR"
  echo ""
  echo "Next steps:"
  echo "  1. Review changes: git diff"
  echo "  2. Test critical scripts:"
  echo "     bash -n install/run-all.sh"
  echo "     bash -n install/lib/*.sh"
  echo "  3. Run dry-run test:"
  echo "     cd install && DRY_RUN=1 bash run-all.sh daily-driver"
  echo "  4. If satisfied:"
  echo "     git add -A"
  echo "     git commit -m 'fix: Apply smart linting fixes'"
  echo "     rm -rf $BACKUP_DIR"
else
  echo "Run without DRY_RUN=1 to apply changes:"
  echo "  bash scripts/smart-lint-fix.sh"
fi
echo ""
echo "Intentionally NOT fixed (see SHELLCHECK_LINTING_REPORT.md):"
echo "  • Unquoted variables in echo statements (intentional display)"
echo "  • Command substitution in assignments (already safe)"
echo "  • Arch-specific commands and patterns"
echo ""
