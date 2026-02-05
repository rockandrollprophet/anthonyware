#!/usr/bin/env bash
# Generate removal list - packages NOT essential for minimal working system
set -euo pipefail

echo "=== Generating Safe Removal List ==="
echo

# Get all explicitly installed packages
pacman -Qqe > /tmp/all-explicit.txt

# Create keep list from essential-keep.txt + their dependencies
echo "Building keep list (essential + dependencies)..."
KEEP_FILE="/home/rockandrollprophet/anthonyware/essential-keep.txt"

# Extract dependencies for all essential packages
> /tmp/keep-list.txt
while IFS= read -r pkg; do
    # Skip comments and empty lines
    [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
    
    # Add package itself
    echo "$pkg" >> /tmp/keep-list.txt
    
    # Add all dependencies recursively
    pactree -u "$pkg" 2>/dev/null | tail -n +2 >> /tmp/keep-list.txt || true
done < "$KEEP_FILE"

# Remove duplicates
sort -u /tmp/keep-list.txt > /tmp/keep-list-final.txt

echo "Essential packages + deps: $(wc -l < /tmp/keep-list-final.txt)"

# Find removable packages (explicit packages NOT in keep list)
comm -23 <(sort /tmp/all-explicit.txt) <(sort /tmp/keep-list-final.txt) > /tmp/removable.txt

echo "Removable packages: $(wc -l < /tmp/removable.txt)"
echo

# Categorize by size
echo "=== Top 30 Removable Packages by Size ==="
while IFS= read -r pkg; do
    size=$(pacman -Qi "$pkg" 2>/dev/null | awk '/^Installed Size/ {print $4}')
    unit=$(pacman -Qi "$pkg" 2>/dev/null | awk '/^Installed Size/ {print $5}')
    
    if [[ "$unit" == "GiB" ]]; then
        size_mb=$(echo "$size * 1024" | bc)
    elif [[ "$unit" == "MiB" ]]; then
        size_mb="$size"
    else
        size_mb="0"
    fi
    
    echo "$size_mb|$pkg"
done < /tmp/removable.txt | sort -t'|' -k1 -rn | head -30 | column -t -s'|'

echo
echo "=== Files Created ==="
echo "  /tmp/keep-list-final.txt   - Packages to KEEP"
echo "  /tmp/removable.txt         - Packages safe to REMOVE"
echo
echo "Review /tmp/removable.txt before removing!"
