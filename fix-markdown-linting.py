#!/usr/bin/env python3
"""
Fix markdown linting errors across all documentation files.
Handles: MD022, MD031, MD032, MD040, MD060 issues
"""

import os
import re
from pathlib import Path

def fix_markdown_file(filepath):
    """Fix all markdown linting issues in a file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Fix MD022: Add blank lines around headings
    # Pattern: heading without blank line before
    content = re.sub(
        r'(\S)\n(#{1,6} )',
        r'\1\n\n\2',
        content
    )
    
    # Pattern: heading without blank line after
    content = re.sub(
        r'(#{1,6} [^\n]*)\n([^\n])',
        lambda m: m.group(1) + '\n\n' + m.group(2) if m.group(2) not in ['#', '-', ' ', '*', '|', '`'] else m.group(0),
        content
    )
    
    # Fix MD031: Add blank lines around code blocks
    # Before code block
    content = re.sub(
        r'(\S)\n(```)',
        r'\1\n\n\2',
        content
    )
    
    # After code block
    content = re.sub(
        r'(```)\n([^\n])',
        lambda m: m.group(1) + '\n\n' + m.group(2) if m.group(2) not in [' ', '\n'] else m.group(0),
        content
    )
    
    # Fix MD032: Add blank lines around lists
    # Before list
    content = re.sub(
        r'(\S)\n([-*] )',
        r'\1\n\n\2',
        content
    )
    
    # After list (before non-list content)
    content = re.sub(
        r'([-*] [^\n]*)\n([^\n\-\*\s])',
        lambda m: m.group(1) + '\n\n' + m.group(2),
        content
    )
    
    # Fix MD040: Add language to fenced code blocks
    # Pattern: ``` without language should be ```bash or ```
    content = re.sub(
        r'```\n',
        r'```bash\n',
        content
    )
    
    # Fix MD060: Fix table formatting (add spaces around pipes)
    # Pattern: |text| -> | text |
    lines = content.split('\n')
    fixed_lines = []
    
    for line in lines:
        if '|' in line and not line.strip().startswith('#'):
            # Check if it's a table line (has pipes)
            parts = line.split('|')
            if len(parts) > 2:
                # Ensure spaces around pipes
                fixed_parts = []
                for part in parts:
                    part = part.strip()
                    if part or fixed_parts:  # Keep empty cells between pipes
                        fixed_parts.append(part)
                
                # Reconstruct with proper spacing
                if all(p in ['', '-', '---', '----', '-----'] for p in fixed_parts[1:-1]):
                    # Separator row
                    line = '| ' + ' | '.join(p if p in ['', '-', '---', '----', '-----'] else '-' * (max(1, len(p)-2)) for p in fixed_parts) + ' |'
                else:
                    # Regular table row
                    line = '| ' + ' | '.join(p for p in fixed_parts) + ' |'
        
        fixed_lines.append(line)
    
    content = '\n'.join(fixed_lines)
    
    # Clean up multiple consecutive blank lines (max 2)
    content = re.sub(r'\n\n\n+', r'\n\n', content)
    
    # Write back if changed
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    repo_root = Path('.')
    
    # Find all markdown files
    md_files = list(repo_root.glob('*.md')) + list(repo_root.glob('**/*.md'))
    md_files = [f for f in md_files if '.git' not in str(f)]
    
    fixed = 0
    for md_file in sorted(md_files):
        try:
            if fix_markdown_file(str(md_file)):
                print(f"✓ Fixed: {md_file.relative_to(repo_root)}")
                fixed += 1
            else:
                print(f"- No changes: {md_file.relative_to(repo_root)}")
        except Exception as e:
            print(f"✗ Error: {md_file.relative_to(repo_root)}: {e}")
    
    print(f"\nFixed {fixed} files")

if __name__ == '__main__':
    main()
