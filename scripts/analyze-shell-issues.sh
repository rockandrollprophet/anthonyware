#!/usr/bin/env bash
# analyze-shell-issues.sh - Analyze shell scripts for common issues without shellcheck

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Shell Script Issue Analyzer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL_ISSUES=0

# Define patterns to search for
declare -A ISSUES=(
  ["SC2086|Unquoted variable"]='[^"](\$[A-Z_][A-Z0-9_]*)[^"]'
  ["SC2046|Unquoted command sub"]='[^"](\$\([^)]+\))[^"]'
  ["SC2164|cd without error check"]='^[[:space:]]*cd [^|&;]*$'
  ["SC2181|Check \$? directly"]='if.*\$\?'
  ["SC2155|Declare and assign sep"]='local [A-Z_]+="?\$\('
  ["SC2143|Use grep -q"]='if.*-[nz].*\$\(grep'
  ["SC1090|Can'\''t follow source"]='^[[:space:]]*source.*\$'
  ["SC2115|Unset variable in rm"]='rm -rf.*\$\{[A-Z_]+\}'
  ["SC2236|Use -n instead of ! -z"]='! *-z'
  ["SC2166|Avoid -a/-o in test"]=' -[ao] '
  ["SC2002|Useless cat"]='cat .* | '
  ["SC2116|Useless echo"]='[`]\$\(echo'
)

analyze_file() {
  local file="$1"
  local filename issues_found=0
  
  filename=$(basename "$file")
  
  # Skip if not a bash script
  if ! head -n 1 "$file" 2>/dev/null | grep -q '^#!/.*bash'; then
    return
  fi
  
  for pattern_desc in "${!ISSUES[@]}"; do
    IFS='|' read -r code desc <<< "$pattern_desc"
    local pattern="${ISSUES[$pattern_desc]}"
    
    # Search for pattern
    local matches
    matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
    
    if [[ -n "$matches" ]]; then
      if [[ $issues_found -eq 0 ]]; then
        echo ""
        echo "═══ $filename ═══"
      fi
      
      echo "$code: $desc"
      echo "$matches" | while IFS=: read -r line_num match; do
        # Trim leading/trailing whitespace
        match=$(echo "$match" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        echo "  Line $line_num: ${match:0:80}"
      done
      
      local count
      count=$(echo "$matches" | wc -l)
      ((issues_found += count))
      ((TOTAL_ISSUES += count))
    fi
  done
  
  return 0
}

# Process all shell scripts
echo "Analyzing install scripts..."
while IFS= read -r -d '' file; do
  analyze_file "$file"
done < <(find "${PROJECT_ROOT}/install" -maxdepth 1 -name "*.sh" -type f -print0 2>/dev/null || true)

echo ""
echo "Analyzing library scripts..."
while IFS= read -r -d '' file; do
  analyze_file "$file"
done < <(find "${PROJECT_ROOT}/install/lib" -name "*.sh" -type f -print0 2>/dev/null || true)

echo ""
echo "Analyzing utility scripts..."
while IFS= read -r -d '' file; do
  analyze_file "$file"
done < <(find "${PROJECT_ROOT}/scripts" -name "*.sh" -type f -print0 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total issues found: $TOTAL_ISSUES"
echo ""
echo "NOTE: Some patterns may be false positives:"
echo "  • Quoted variables that look unquoted"
echo "  • Intentionally dynamic source paths"
echo "  • Protected command substitutions"
echo ""
echo "Run comprehensive-lint-fix.sh to apply automated fixes"
echo ""
