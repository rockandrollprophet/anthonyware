#!/usr/bin/env bash
# fix-markdown-lint.sh - Automatically fix common markdown linting issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Markdown Linting Fixer                              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo

cd "$REPO_ROOT"

# Function to fix blank lines around fenced code blocks (MD031)
fix_fenced_code_blocks() {
  local file="$1"
  echo "  Fixing fenced code blocks in: $file"
  
  # This is complex to do with sed, so we'll use a simple Python script if available
  if command -v python3 &>/dev/null; then
    python3 - "$file" << 'PYTHON_EOF'
import sys
import re

def fix_fences(content):
    lines = content.split('\n')
    result = []
    in_code_block = False
    prev_blank = False
    
    for i, line in enumerate(lines):
        # Detect code fence
        if re.match(r'^```', line):
            if not in_code_block:  # Opening fence
                # Add blank line before if needed
                if result and not prev_blank and result[-1].strip():
                    result.append('')
                result.append(line)
                in_code_block = True
                prev_blank = False
            else:  # Closing fence
                result.append(line)
                in_code_block = False
                # Add blank line after if next line exists and is not blank
                if i + 1 < len(lines) and lines[i + 1].strip():
                    result.append('')
                    prev_blank = True
                else:
                    prev_blank = False
        else:
            result.append(line)
            prev_blank = not line.strip()
    
    return '\n'.join(result)

if __name__ == '__main__':
    filepath = sys.argv[1]
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    fixed = fix_fences(content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(fixed)

PYTHON_EOF
  else
    echo "    WARNING: Python3 not available, skipping automatic fence fixes"
  fi
}

# Function to fix blank lines around headings (MD022)
fix_heading_blanks() {
  local file="$1"
  echo "  Fixing heading spacing in: $file"
  
  if command -v python3 &>/dev/null; then
    python3 - "$file" << 'PYTHON_EOF'
import sys
import re

def fix_headings(content):
    lines = content.split('\n')
    result = []
    
    for i, line in enumerate(lines):
        # Check if this is a heading
        if re.match(r'^#{1,6} ', line):
            # Add blank line before heading (unless it's the first line)
            if i > 0 and result and result[-1].strip():
                result.append('')
            result.append(line)
            # We'll add blank after when we process next line
        else:
            # If previous line was a heading and this line is not blank, add blank
            if result and re.match(r'^#{1,6} ', result[-1]) and line.strip():
                result.append('')
            result.append(line)
    
    return '\n'.join(result)

if __name__ == '__main__':
    filepath = sys.argv[1]
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    fixed = fix_headings(content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(fixed)

PYTHON_EOF
  fi
}

# Function to fix bare URLs (MD034)
fix_bare_urls() {
  local file="$1"
  echo "  Fixing bare URLs in: $file"
  
  # Simple sed replacement for common bare URL patterns
  sed -i.bak -E 's|: (http[s]?://[^ ]+)$|: <\1>|g' "$file"
  rm -f "${file}.bak"
}

# Function to remove trailing punctuation from headings (MD026)
fix_heading_punctuation() {
  local file="$1"
  echo "  Fixing heading punctuation in: $file"
  
  # Remove trailing colons, periods, etc from headings
  sed -i.bak -E 's/^(#{1,6} .+)[:.!?]$/\1/g' "$file"
  rm -f "${file}.bak"
}

# Find all markdown files
echo "Searching for markdown files..."
MARKDOWN_FILES=$(find "$REPO_ROOT" -type f -name "*.md" | grep -v node_modules || true)

if [[ -z "$MARKDOWN_FILES" ]]; then
  echo "No markdown files found."
  exit 0
fi

FILE_COUNT=$(echo "$MARKDOWN_FILES" | wc -l)
echo "Found $FILE_COUNT markdown files"
echo

# Process each file
FIXED_COUNT=0
for file in $MARKDOWN_FILES; do
  echo "Processing: $file"
  
  # Create backup
  cp "$file" "${file}.backup"
  
  # Apply fixes
  fix_fenced_code_blocks "$file" 2>/dev/null || true
  fix_heading_blanks "$file" 2>/dev/null || true
  fix_bare_urls "$file" 2>/dev/null || true
  fix_heading_punctuation "$file" 2>/dev/null || true
  
  # Check if file changed
  if ! diff -q "$file" "${file}.backup" &>/dev/null; then
    ((FIXED_COUNT++))
    echo "  ✓ Fixed"
  else
    echo "  - No changes needed"
  fi
  
  # Remove backup
  rm -f "${file}.backup"
  echo
done

echo "╔══════════════════════════════════════════════════════╗"
echo "║ Markdown Linting Fix Complete                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo
echo "Summary:"
echo "  Total files:  $FILE_COUNT"
echo "  Files fixed:  $FIXED_COUNT"
echo
echo "Note: Some complex issues may require manual fixes."
echo "      Run a markdown linter to verify: markdownlint *.md"
echo
