#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Configuration Diff Tool
#
#  Compares deployed configurations with repository versions
#  and shows differences
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_PATH="${HOME}/anthonyware"

echo -e "${CYAN}=== Configuration Diff Tool ===${NC}"
echo

# Configuration mappings: repo_path:deployed_path
CONFIG_MAP=(
    "hypr/hyprland.conf:.config/hypr/hyprland.conf"
    "hypr/hyprlock.conf:.config/hypr/hyprlock.conf"
    "hypr/hyprpaper.conf:.config/hypr/hyprpaper.conf"
    "waybar/config.jsonc:.config/waybar/config.jsonc"
    "waybar/style.css:.config/waybar/style.css"
    "kitty/kitty.conf:.config/kitty/kitty.conf"
    "mako/config:.config/mako/config"
    "wofi/config:.config/wofi/config"
    "swaync/config.json:.config/swaync/config.json"
)

show_menu() {
    echo -e "${BLUE}Select an option:${NC}"
    echo "  1) Show all configuration status"
    echo "  2) View diff for specific config"
    echo "  3) Restore config from repository"
    echo "  4) Export current config to repository"
    echo "  5) Compare all configs (detailed)"
    echo "  0) Exit"
    echo
}

show_status() {
    echo -e "${CYAN}Configuration Status:${NC}"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    printf "%-40s %-15s\n" "FILE" "STATUS"
    printf "%-40s %-15s\n" "----" "------"
    
    for mapping in "${CONFIG_MAP[@]}"; do
        IFS=':' read -r repo_path deployed_path <<< "$mapping"
        
        REPO_FILE="$REPO_PATH/configs/$repo_path"
        DEPLOYED_FILE="$HOME/$deployed_path"
        
        if [[ ! -f "$DEPLOYED_FILE" ]]; then
            printf "%-40s " "$deployed_path"
            echo -e "${RED}MISSING${NC}"
        elif [[ ! -f "$REPO_FILE" ]]; then
            printf "%-40s " "$deployed_path"
            echo -e "${YELLOW}NO REPO VER${NC}"
        elif diff -q "$DEPLOYED_FILE" "$REPO_FILE" &>/dev/null; then
            printf "%-40s " "$deployed_path"
            echo -e "${GREEN}SYNCED${NC}"
        else
            printf "%-40s " "$deployed_path"
            echo -e "${YELLOW}MODIFIED${NC}"
        fi
    done
    
    echo
    read -rp "Press Enter to continue..."
}

view_diff() {
    echo
    echo "Select configuration file:"
    echo
    
    local idx=1
    for mapping in "${CONFIG_MAP[@]}"; do
        IFS=':' read -r repo_path deployed_path <<< "$mapping"
        printf "%2d) %s\n" "$idx" "$deployed_path"
        ((idx++))
    done
    
    echo
    read -rp "Selection: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#CONFIG_MAP[@]}" ]]; then
        echo -e "${RED}Invalid selection${NC}"
        read -rp "Press Enter to continue..."
        return
    fi
    
    IFS=':' read -r repo_path deployed_path <<< "${CONFIG_MAP[$((selection-1))]}"
    
    REPO_FILE="$REPO_PATH/configs/$repo_path"
    DEPLOYED_FILE="$HOME/$deployed_path"
    
    echo
    echo -e "${CYAN}Comparing: $deployed_path${NC}"
    echo "Repository: $REPO_FILE"
    echo "Deployed:   $DEPLOYED_FILE"
    echo
    
    if [[ ! -f "$DEPLOYED_FILE" ]]; then
        echo -e "${RED}Deployed file not found${NC}"
    elif [[ ! -f "$REPO_FILE" ]]; then
        echo -e "${YELLOW}Repository version not found${NC}"
    else
        diff -u "$REPO_FILE" "$DEPLOYED_FILE" || echo -e "${GREEN}Files are identical${NC}"
    fi
    
    echo
    read -rp "Press Enter to continue..."
}

restore_config() {
    echo
    echo "Select configuration to restore:"
    echo
    
    local idx=1
    for mapping in "${CONFIG_MAP[@]}"; do
        IFS=':' read -r repo_path deployed_path <<< "$mapping"
        printf "%2d) %s\n" "$idx" "$deployed_path"
        ((idx++))
    done
    
    echo
    read -rp "Selection: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#CONFIG_MAP[@]}" ]]; then
        echo -e "${RED}Invalid selection${NC}"
        read -rp "Press Enter to continue..."
        return
    fi
    
    IFS=':' read -r repo_path deployed_path <<< "${CONFIG_MAP[$((selection-1))]}"
    
    REPO_FILE="$REPO_PATH/configs/$repo_path"
    DEPLOYED_FILE="$HOME/$deployed_path"
    
    echo
    if [[ ! -f "$REPO_FILE" ]]; then
        echo -e "${RED}Repository version not found: $REPO_FILE${NC}"
        read -rp "Press Enter to continue..."
        return
    fi
    
    # Backup existing file
    if [[ -f "$DEPLOYED_FILE" ]]; then
        BACKUP="${DEPLOYED_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$DEPLOYED_FILE" "$BACKUP"
        echo -e "${GREEN}✓${NC} Backed up to: $BACKUP"
    fi
    
    # Create directory if needed
    mkdir -p "$(dirname "$DEPLOYED_FILE")"
    
    # Copy from repository
    cp "$REPO_FILE" "$DEPLOYED_FILE"
    echo -e "${GREEN}✓${NC} Restored: $deployed_path"
    
    echo
    read -rp "Press Enter to continue..."
}

export_config() {
    echo
    echo "Select configuration to export to repository:"
    echo
    
    local idx=1
    for mapping in "${CONFIG_MAP[@]}"; do
        IFS=':' read -r repo_path deployed_path <<< "$mapping"
        printf "%2d) %s\n" "$idx" "$deployed_path"
        ((idx++))
    done
    
    echo
    read -rp "Selection: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#CONFIG_MAP[@]}" ]]; then
        echo -e "${RED}Invalid selection${NC}"
        read -rp "Press Enter to continue..."
        return
    fi
    
    IFS=':' read -r repo_path deployed_path <<< "${CONFIG_MAP[$((selection-1))]}"
    
    REPO_FILE="$REPO_PATH/configs/$repo_path"
    DEPLOYED_FILE="$HOME/$deployed_path"
    
    echo
    if [[ ! -f "$DEPLOYED_FILE" ]]; then
        echo -e "${RED}Deployed file not found: $DEPLOYED_FILE${NC}"
        read -rp "Press Enter to continue..."
        return
    fi
    
    # Backup existing repo file
    if [[ -f "$REPO_FILE" ]]; then
        BACKUP="${REPO_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$REPO_FILE" "$BACKUP"
        echo -e "${GREEN}✓${NC} Backed up repo version to: $BACKUP"
    fi
    
    # Create directory if needed
    mkdir -p "$(dirname "$REPO_FILE")"
    
    # Copy to repository
    cp "$DEPLOYED_FILE" "$REPO_FILE"
    echo -e "${GREEN}✓${NC} Exported to repository: $repo_path"
    echo -e "${YELLOW}Note:${NC} Remember to commit changes to git"
    
    echo
    read -rp "Press Enter to continue..."
}

compare_all() {
    echo -e "${CYAN}Detailed Comparison of All Configs:${NC}"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    for mapping in "${CONFIG_MAP[@]}"; do
        IFS=':' read -r repo_path deployed_path <<< "$mapping"
        
        REPO_FILE="$REPO_PATH/configs/$repo_path"
        DEPLOYED_FILE="$HOME/$deployed_path"
        
        echo -e "${BLUE}$deployed_path${NC}"
        echo "───────────────────────────────────────────────────────"
        
        if [[ ! -f "$DEPLOYED_FILE" ]]; then
            echo -e "${RED}✗ Deployed file not found${NC}"
        elif [[ ! -f "$REPO_FILE" ]]; then
            echo -e "${YELLOW}⚠ Repository version not found${NC}"
        elif diff -q "$DEPLOYED_FILE" "$REPO_FILE" &>/dev/null; then
            echo -e "${GREEN}✓ Files are identical${NC}"
        else
            echo -e "${YELLOW}Modified - showing differences:${NC}"
            diff -u "$REPO_FILE" "$DEPLOYED_FILE" | head -50
            echo "..."
        fi
        
        echo
    done
    
    read -rp "Press Enter to continue..."
}

# Main loop
while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Configuration Diff Tool                    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo
    
    show_menu
    read -rp "Choice: " choice
    
    case "$choice" in
        1) show_status ;;
        2) view_diff ;;
        3) restore_config ;;
        4) export_config ;;
        5) compare_all ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
    esac
done
