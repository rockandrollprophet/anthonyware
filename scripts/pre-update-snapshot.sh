#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Pre-Update Snapshot
#
#  Creates a system snapshot before updates to enable rollback
#  if something goes wrong
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Pre-Update Snapshot ===${NC}"
echo

# Check if we're using Btrfs
ROOT_FS=$(findmnt -no FSTYPE /)
if [[ "$ROOT_FS" != "btrfs" ]]; then
    echo -e "${YELLOW}⚠${NC} Root filesystem is not Btrfs: $ROOT_FS"
    echo "  Btrfs snapshots are not available"
    echo "  Consider using rsync backup instead"
    exit 1
fi

echo -e "${GREEN}✓${NC} Btrfs filesystem detected"
echo

# Check for snapshot tools
SNAPSHOT_TOOL=""

if command -v timeshift &>/dev/null; then
    SNAPSHOT_TOOL="timeshift"
elif command -v snapper &>/dev/null; then
    SNAPSHOT_TOOL="snapper"
else
    echo -e "${YELLOW}⚠${NC} No snapshot tool found"
    echo "  Install timeshift or snapper to create snapshots"
    echo
    read -rp "Install Timeshift? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        sudo pacman -S --noconfirm timeshift
        SNAPSHOT_TOOL="timeshift"
    else
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Using $SNAPSHOT_TOOL for snapshots"
echo

# Create snapshot
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
COMMENT="Pre-update snapshot - $TIMESTAMP"

case "$SNAPSHOT_TOOL" in
    timeshift)
        echo "Creating Timeshift snapshot..."
        if sudo timeshift --create --comments "$COMMENT" --tags D; then
            echo -e "${GREEN}✓${NC} Snapshot created successfully"
        else
            echo -e "${RED}✗${NC} Failed to create snapshot"
            exit 1
        fi
        
        # List recent snapshots
        echo
        echo "Recent snapshots:"
        sudo timeshift --list | tail -10
        ;;
        
    snapper)
        echo "Creating Snapper snapshot..."
        if sudo snapper create --description "$COMMENT"; then
            echo -e "${GREEN}✓${NC} Snapshot created successfully"
        else
            echo -e "${RED}✗${NC} Failed to create snapshot"
            exit 1
        fi
        
        # List recent snapshots
        echo
        echo "Recent snapshots:"
        sudo snapper list | tail -10
        ;;
esac

echo
echo -e "${GREEN}=== Snapshot Complete ===${NC}"
echo
echo "To restore this snapshot if needed:"
if [[ "$SNAPSHOT_TOOL" == "timeshift" ]]; then
    echo "  1. Boot from live USB"
    echo "  2. Run: sudo timeshift --restore"
    echo "  3. Select the snapshot: $COMMENT"
elif [[ "$SNAPSHOT_TOOL" == "snapper" ]]; then
    echo "  1. sudo snapper list"
    echo "  2. sudo snapper rollback <snapshot-number>"
    echo "  3. Reboot"
fi
echo

# Proceed with update
read -rp "Proceed with system update now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo
    echo "Running system update..."
    
    # Update official repositories
    sudo pacman -Syu --noconfirm
    
    # Update AUR packages if yay is available
    if command -v yay &>/dev/null; then
        echo
        echo "Updating AUR packages..."
        yay -Syu --noconfirm
    fi
    
    echo
    echo -e "${GREEN}✓${NC} System update complete"
    
    # Optional: create post-update snapshot
    read -rp "Create post-update snapshot? [y/N] " ans2
    if [[ "$ans2" =~ ^[Yy]$ ]]; then
        COMMENT_POST="Post-update snapshot - $(date '+%Y-%m-%d_%H-%M-%S')"
        if [[ "$SNAPSHOT_TOOL" == "timeshift" ]]; then
            sudo timeshift --create --comments "$COMMENT_POST" --tags D
        else
            sudo snapper create --description "$COMMENT_POST"
        fi
        echo -e "${GREEN}✓${NC} Post-update snapshot created"
    fi
else
    echo "Update cancelled. Snapshot remains available for future use."
fi

echo
echo "Done!"
