#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  Anthonyware OS — Service Manager
#
#  Interactive systemd service management with diagnostics
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# Key services for this distribution
KEY_SERVICES=(
    "NetworkManager:System:Network connectivity"
    "bluetooth:System:Bluetooth support"
    "firewalld:System:Firewall"
    "cups:System:Printing service"
    "avahi-daemon:System:Service discovery (mDNS)"
    "sddm:System:Display manager"
    "pipewire:User:Audio server"
    "pipewire-pulse:User:PulseAudio compatibility"
    "wireplumber:User:Audio session manager"
)

show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Anthonyware OS — Service Manager           ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo
    echo "Select an option:"
    echo
    echo "  ${BLUE}1${NC}) Show all key services status"
    echo "  ${BLUE}2${NC}) Start a service"
    echo "  ${BLUE}3${NC}) Stop a service"
    echo "  ${BLUE}4${NC}) Restart a service"
    echo "  ${BLUE}5${NC}) Enable a service (auto-start)"
    echo "  ${BLUE}6${NC}) Disable a service (no auto-start)"
    echo "  ${BLUE}7${NC}) View service logs"
    echo "  ${BLUE}8${NC}) Check failed services"
    echo "  ${BLUE}9${NC}) Custom service command"
    echo "  ${BLUE}0${NC}) Exit"
    echo
}

check_service_status() {
    local service="$1"
    local scope="$2"
    
    if [[ "$scope" == "User" ]]; then
        systemctl --user is-active --quiet "$service" 2>/dev/null
    else
        systemctl is-active --quiet "$service" 2>/dev/null
    fi
}

show_status() {
    echo -e "${CYAN}Key Services Status:${NC}"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    printf "%-25s %-10s %-10s\n" "SERVICE" "SCOPE" "STATUS"
    printf "%-25s %-10s %-10s\n" "-------" "-----" "------"
    
    for svc in "${KEY_SERVICES[@]}"; do
        IFS=':' read -r name scope desc <<< "$svc"
        
        if [[ "$scope" == "User" ]]; then
            if systemctl --user is-active --quiet "$name" 2>/dev/null; then
                status="${GREEN}active${NC}"
            else
                status="${RED}inactive${NC}"
            fi
        else
            if systemctl is-active --quiet "$name" 2>/dev/null; then
                status="${GREEN}active${NC}"
            else
                status="${RED}inactive${NC}"
            fi
        fi
        
        printf "%-25s %-10s " "$name" "$scope"
        echo -e "$status"
    done
    
    echo
    read -rp "Press Enter to continue..."
}

service_action() {
    local action="$1"
    
    echo
    echo "Available services:"
    echo
    
    local idx=1
    for svc in "${KEY_SERVICES[@]}"; do
        IFS=':' read -r name scope desc <<< "$svc"
        printf "%2d) %-25s [%s] - %s\n" "$idx" "$name" "$scope" "$desc"
        ((idx++))
    done
    
    echo
    read -rp "Select service number (or 'c' for custom): " selection
    
    if [[ "$selection" == "c" || "$selection" == "C" ]]; then
        read -rp "Enter service name: " service_name
        read -rp "User service? [y/N]: " is_user
        [[ "$is_user" =~ ^[Yy]$ ]] && scope="User" || scope="System"
    else
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#KEY_SERVICES[@]}" ]]; then
            IFS=':' read -r service_name scope desc <<< "${KEY_SERVICES[$((selection-1))]}"
        else
            echo -e "${RED}Invalid selection${NC}"
            read -rp "Press Enter to continue..."
            return
        fi
    fi
    
    echo
    if [[ "$scope" == "User" ]]; then
        if [[ "$action" == "enable" || "$action" == "disable" ]]; then
            sudo -u "$SUDO_USER" systemctl --user "$action" "$service_name" 2>&1 && \
                echo -e "${GREEN}✓${NC} Service $action: $service_name" || \
                echo -e "${RED}✗${NC} Failed to $action $service_name"
        else
            sudo -u "$SUDO_USER" systemctl --user "$action" "$service_name" 2>&1 && \
                echo -e "${GREEN}✓${NC} Service $action: $service_name" || \
                echo -e "${RED}✗${NC} Failed to $action $service_name"
        fi
    else
        sudo systemctl "$action" "$service_name" 2>&1 && \
            echo -e "${GREEN}✓${NC} Service $action: $service_name" || \
            echo -e "${RED}✗${NC} Failed to $action $service_name"
    fi
    
    echo
    read -rp "Press Enter to continue..."
}

view_logs() {
    echo
    echo "Available services:"
    echo
    
    local idx=1
    for svc in "${KEY_SERVICES[@]}"; do
        IFS=':' read -r name scope desc <<< "$svc"
        printf "%2d) %-25s [%s]\n" "$idx" "$name" "$scope"
        ((idx++))
    done
    
    echo
    read -rp "Select service number (or 'c' for custom): " selection
    
    if [[ "$selection" == "c" || "$selection" == "C" ]]; then
        read -rp "Enter service name: " service_name
        read -rp "User service? [y/N]: " is_user
        [[ "$is_user" =~ ^[Yy]$ ]] && scope="User" || scope="System"
    else
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#KEY_SERVICES[@]}" ]]; then
            IFS=':' read -r service_name scope desc <<< "${KEY_SERVICES[$((selection-1))]}"
        else
            echo -e "${RED}Invalid selection${NC}"
            read -rp "Press Enter to continue..."
            return
        fi
    fi
    
    echo
    if [[ "$scope" == "User" ]]; then
        journalctl --user -u "$service_name" -n 50 --no-pager
    else
        sudo journalctl -u "$service_name" -n 50 --no-pager
    fi
    
    echo
    read -rp "Press Enter to continue..."
}

check_failed() {
    echo -e "${CYAN}Failed Services:${NC}"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    echo "System services:"
    systemctl --failed --no-pager || echo "  None"
    
    echo
    echo "User services:"
    systemctl --user --failed --no-pager 2>/dev/null || echo "  None"
    
    echo
    read -rp "Press Enter to continue..."
}

custom_command() {
    echo
    read -rp "Enter service name: " service_name
    read -rp "User service? [y/N]: " is_user
    read -rp "Enter systemctl command (status/start/stop/restart/etc): " cmd
    
    echo
    if [[ "$is_user" =~ ^[Yy]$ ]]; then
        sudo -u "$SUDO_USER" systemctl --user "$cmd" "$service_name"
    else
        sudo systemctl "$cmd" "$service_name"
    fi
    
    echo
    read -rp "Press Enter to continue..."
}

# Main loop
while true; do
    show_menu
    read -rp "Choice: " choice
    
    case "$choice" in
        1) show_status ;;
        2) service_action "start" ;;
        3) service_action "stop" ;;
        4) service_action "restart" ;;
        5) service_action "enable" ;;
        6) service_action "disable" ;;
        7) view_logs ;;
        8) check_failed ;;
        9) custom_command ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
    esac
done
