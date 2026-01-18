#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Package Repair Tool
#
#  Fixes common pacman database and dependency issues
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root${NC}"
   exit 1
fi

echo -e "${CYAN}=== Package Repair Tool ===${NC}"
echo

# Check pacman database
echo -e "${CYAN}[1/6] Checking Pacman Database${NC}"
echo "───────────────────────────────────"

if pacman -Qk 2>&1 | grep -q "error"; then
    echo -e "${RED}✗${NC} Database errors detected"
    DB_OK=false
else
    echo -e "${GREEN}✓${NC} Database appears healthy"
    DB_OK=true
fi

echo

# Check for partial upgrades
echo -e "${CYAN}[2/6] Checking for Partial Upgrades${NC}"
echo "───────────────────────────────────"

OUTDATED=$(pacman -Qu 2>/dev/null | wc -l || echo "0")
if [[ "$OUTDATED" -gt 0 ]]; then
    echo -e "${YELLOW}⚠${NC} $OUTDATED packages can be upgraded"
else
    echo -e "${GREEN}✓${NC} System is up to date"
fi

echo

# Check for orphaned packages
echo -e "${CYAN}[3/6] Checking for Orphaned Packages${NC}"
echo "───────────────────────────────────"

ORPHANS=$(pacman -Qtdq 2>/dev/null | wc -l || echo "0")
if [[ "$ORPHANS" -gt 0 ]]; then
    echo -e "${YELLOW}⚠${NC} $ORPHANS orphaned packages found"
    echo "  (no longer required by any installed package)"
else
    echo -e "${GREEN}✓${NC} No orphaned packages"
fi

echo

# Check for broken dependencies
echo -e "${CYAN}[4/6] Checking Dependencies${NC}"
echo "───────────────────────────────────"

BROKEN=$(pacman -Qk 2>&1 | grep -c "warning" || echo "0")
if [[ "$BROKEN" -gt 0 ]]; then
    echo -e "${YELLOW}⚠${NC} $BROKEN dependency warnings detected"
else
    echo -e "${GREEN}✓${NC} No dependency issues found"
fi

echo

# Check pacman cache
echo -e "${CYAN}[5/6] Checking Package Cache${NC}"
echo "───────────────────────────────────"

if [[ -d /var/cache/pacman/pkg ]]; then
    CACHE_SIZE=$(du -sh /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}' || echo "unknown")
    CACHE_COUNT=$(find /var/cache/pacman/pkg -name "*.pkg.tar.*" 2>/dev/null | wc -l || echo "0")
    echo -e "${GREEN}✓${NC} Cache directory exists"
    echo "  Size: $CACHE_SIZE"
    echo "  Packages: $CACHE_COUNT"
else
    echo -e "${RED}✗${NC} Cache directory not found"
fi

echo

# Check mirrors
echo -e "${CYAN}[6/6] Checking Mirrorlist${NC}"
echo "───────────────────────────────────"

if [[ -f /etc/pacman.d/mirrorlist ]]; then
    MIRROR_COUNT=$(grep -c "^Server" /etc/pacman.d/mirrorlist 2>/dev/null || echo "0")
    if [[ "$MIRROR_COUNT" -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} $MIRROR_COUNT mirrors configured"
    else
        echo -e "${RED}✗${NC} No active mirrors found"
    fi
else
    echo -e "${RED}✗${NC} Mirrorlist not found"
fi

echo

# Repair options
echo -e "${CYAN}Repair Options${NC}"
echo "───────────────────────────────────"
echo

if [[ "$DB_OK" == false ]]; then
    read -rp "Repair pacman database? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        echo "Repairing database..."
        pacman -Syy
        pacman-db-upgrade
        echo -e "${GREEN}✓${NC} Database repaired"
    fi
fi

read -rp "Synchronize package databases? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    pacman -Syy
    echo -e "${GREEN}✓${NC} Databases synchronized"
fi

if [[ "$ORPHANS" -gt 0 ]]; then
    read -rp "Remove orphaned packages? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        pacman -Qtdq | pacman -Rns -
        echo -e "${GREEN}✓${NC} Orphaned packages removed"
    fi
fi

read -rp "Clear package cache (keep last 3 versions)? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    paccache -rk3
    echo -e "${GREEN}✓${NC} Cache cleaned"
fi

read -rp "Reinstall all package files? (fixes corrupted files) [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo "This may take a while..."
    pacman -Qkq | grep "warning" | awk '{print $1}' | xargs pacman -S --noconfirm
    echo -e "${GREEN}✓${NC} Packages reinstalled"
fi

read -rp "Update mirrorlist with reflector? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    if command -v reflector &>/dev/null; then
        echo "Updating mirrorlist..."
        reflector --country US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        echo -e "${GREEN}✓${NC} Mirrorlist updated"
    else
        echo -e "${RED}✗${NC} reflector not installed (install: pacman -S reflector)"
    fi
fi

read -rp "Full system upgrade? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    pacman -Syu
    echo -e "${GREEN}✓${NC} System upgraded"
fi

echo
echo -e "${GREEN}=== Package Repair Complete ===${NC}"
echo
echo "Additional commands:"
echo "  • Check all packages:     pacman -Qk"
echo "  • List orphans:           pacman -Qtdq"
echo "  • Reinstall package:      pacman -S <package>"
echo "  • Clear all cache:        pacman -Scc"
echo "  • Check package info:     pacman -Qi <package>"
