#!/bin/bash

#===============================================================================
# NETWORK CONTROL CENTER - TERMINAL UI
# Comprehensive network configuration and management tool
# Compatible with: All major Linux distributions
# Version: 1.0
# Author: Luka Rogovic <luka032[at]gmail.com>
# GitHub: https://github.com/LukaRogovic/linuxscripts
# Licence: Open source as God wanted it
#===============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This operation requires root privileges.${NC}"
        echo -e "${YELLOW}Please run with sudo.${NC}"
        return 1
    fi
    return 0
}

clear_screen() {
    clear
}

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    printf "${BOLD}${BLUE}┃${NC}  ${WHITE}%-72s${NC}${BOLD}${BLUE}┃${NC}\n" "$1"
    echo -e "${BOLD}${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

print_section() {
    echo -e "\n${CYAN}═══ $1 ═══${NC}"
}

print_subsection() {
    echo -e "\n${YELLOW}--- $1 ---${NC}"
}

print_item() {
    printf "  ${GREEN}%-28s${NC} : %s\n" "$1" "$2"
}

print_item_warn() {
    printf "  ${YELLOW}%-28s${NC} : %s\n" "$1" "$2"
}

print_item_error() {
    printf "  ${RED}%-28s${NC} : %s\n" "$1" "$2"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}ℹ${NC} $1"
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s -r
}

wait_for_menu() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}[R]${NC} Refresh    ${WHITE}[M]${NC} Main Menu    ${WHITE}[Q]${NC} Quit"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    while true; do
        read -n 1 -s -r key
        case $key in
            r|R) return 0 ;;
            m|M) return 1 ;;
            q|Q) clear_screen; echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
        esac
    done
}

confirm_action() {
    echo -ne "  ${YELLOW}Are you sure? [y/N]: ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

get_input() {
    local prompt="$1"
    local var
    echo -ne "  ${WHITE}$prompt: ${NC}" >&2
    read -r var
    echo "$var"
}

select_interface() {
    local prompt="${1:-Select interface}"
    local interfaces=()
    local i=1
    
    echo "" >&2
    echo -e "  ${CYAN}$prompt:${NC}" >&2
    echo -e "  ${DIM}─────────────────────────────${NC}" >&2
    
    for iface in $(ls /sys/class/net/ 2>/dev/null); do
        interfaces+=("$iface")
        STATE=$(cat /sys/class/net/$iface/operstate 2>/dev/null)
        if [[ "$STATE" == "up" ]]; then
            echo -e "  ${WHITE}$i.${NC} ${GREEN}$iface${NC} (UP)" >&2
        else
            echo -e "  ${WHITE}$i.${NC} ${DIM}$iface${NC} ($STATE)" >&2
        fi
        ((i++))
    done
    
    echo "" >&2
    echo -ne "  ${WHITE}Enter number (or name): ${NC}" >&2
    read -r selection
    
    # Check if it's a number
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#interfaces[@]} ]]; then
        echo "${interfaces[$((selection-1))]}"
    else
        # Return as-is (user typed interface name)
        echo "$selection"
    fi
}

select_wifi() {
    local networks=()
    local i=1
    
    echo "" >&2
    echo -e "  ${CYAN}Available WiFi Networks:${NC}" >&2
    echo -e "  ${DIM}─────────────────────────────────────────────${NC}" >&2
    
    # Rescan
    nmcli dev wifi rescan 2>/dev/null
    sleep 1
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            networks+=("$line")
            SIGNAL=$(nmcli -t -f SSID,SIGNAL dev wifi list 2>/dev/null | grep "^${line}:" | head -1 | cut -d: -f2)
            echo -e "  ${WHITE}$i.${NC} $line ${DIM}(${SIGNAL}%)${NC}" >&2
            ((i++))
        fi
    done < <(nmcli -t -f SSID dev wifi list 2>/dev/null | grep -v "^$" | sort -u | head -15)
    
    if [[ ${#networks[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No networks found${NC}" >&2
        echo -ne "  ${WHITE}Enter SSID manually: ${NC}" >&2
        read -r ssid
        echo "$ssid"
        return
    fi
    
    echo "" >&2
    echo -ne "  ${WHITE}Enter number (or SSID): ${NC}" >&2
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#networks[@]} ]]; then
        echo "${networks[$((selection-1))]}"
    else
        echo "$selection"
    fi
}

select_saved_wifi() {
    local connections=()
    local i=1
    
    echo "" >&2
    echo -e "  ${CYAN}Saved WiFi Networks:${NC}" >&2
    echo -e "  ${DIM}─────────────────────────────${NC}" >&2
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            connections+=("$line")
            echo -e "  ${WHITE}$i.${NC} $line" >&2
            ((i++))
        fi
    done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ":.*wireless" | cut -d: -f1)
    
    if [[ ${#connections[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No saved networks${NC}" >&2
        return
    fi
    
    echo "" >&2
    echo -ne "  ${WHITE}Enter number (or name): ${NC}" >&2
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#connections[@]} ]]; then
        echo "${connections[$((selection-1))]}"
    else
        echo "$selection"
    fi
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_main_menu() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${CYAN}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║    ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗         ║"
        echo "║    ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝         ║"
        echo "║    ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝          ║"
        echo "║    ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗          ║"
        echo "║    ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗         ║"
        echo "║    ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝         ║"
        echo "║                                                                            ║"
        echo "║                      CONTROL CENTER                                        ║"
        echo "║                                                                            ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        # Quick status
        echo -e "  ${DIM}Quick Status:${NC}"
        DEFAULT_IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
        DEFAULT_IP=$(ip -4 addr show "$DEFAULT_IFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
        echo -e "  ${GREEN}●${NC} Primary Interface: ${WHITE}${DEFAULT_IFACE:-None}${NC} (${DEFAULT_IP:-No IP})"
        
        if cmd_exists ufw; then
            UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}')
            [[ "$UFW_STATUS" == "active" ]] && echo -e "  ${GREEN}●${NC} Firewall: ${GREEN}Active${NC}" || echo -e "  ${YELLOW}●${NC} Firewall: ${YELLOW}Inactive${NC}"
        fi
        echo ""
        
        echo -e "${WHITE}  Select a category:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Interface Management${NC}          ${WHITE} 6.${NC} ${GREEN}Firewall Configuration${NC}       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}IP Configuration${NC}              ${WHITE} 7.${NC} ${GREEN}Network Diagnostics${NC}          ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}WiFi Management${NC}               ${WHITE} 8.${NC} ${GREEN}Advanced Tools${NC}               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}DNS Configuration${NC}             ${WHITE} 9.${NC} ${GREEN}Traffic Monitor${NC}              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Routing Table${NC}                 ${WHITE}10.${NC} ${GREEN}Connection Status${NC}            ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${YELLOW}Network Summary${NC}                                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) interface_menu ;;
            2) ip_config_menu ;;
            3) wifi_menu ;;
            4) dns_menu ;;
            5) routing_menu ;;
            6) firewall_menu ;;
            7) diagnostics_menu ;;
            8) advanced_menu ;;
            9) traffic_monitor ;;
            10) connection_status ;;
            s|S) network_summary ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Network Control Center!${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Interface Management
#-------------------------------------------------------------------------------

interface_menu() {
    while true; do
        clear_screen
        print_header "INTERFACE MANAGEMENT"
        
        print_section "Network Interfaces"
        echo -e "  ${DIM}Interface        State      MAC Address          MTU     Driver${NC}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${NC}"
        
        for iface in $(ls /sys/class/net/ 2>/dev/null); do
            STATE=$(cat /sys/class/net/$iface/operstate 2>/dev/null)
            MAC=$(cat /sys/class/net/$iface/address 2>/dev/null)
            MTU=$(cat /sys/class/net/$iface/mtu 2>/dev/null)
            DRIVER=$(readlink /sys/class/net/$iface/device/driver 2>/dev/null | xargs basename 2>/dev/null || echo "N/A")
            
            if [[ "$STATE" == "up" ]]; then
                STATE_COLOR="${GREEN}UP${NC}    "
            elif [[ "$STATE" == "down" ]]; then
                STATE_COLOR="${RED}DOWN${NC}  "
            else
                STATE_COLOR="${YELLOW}${STATE:-unknown}${NC}"
            fi
            
            printf "  %-16s ${STATE_COLOR}   %-20s %-7s %s\n" "$iface" "$MAC" "$MTU" "$DRIVER"
        done
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Bring interface UP"
        echo -e "  ${WHITE}2.${NC} Bring interface DOWN"
        echo -e "  ${WHITE}3.${NC} Set MTU"
        echo -e "  ${WHITE}4.${NC} View interface details"
        echo -e "  ${WHITE}5.${NC} Restart NetworkManager"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to bring UP")
                [[ -n "$IFACE" ]] && ip link set "$IFACE" up && print_success "Interface $IFACE is now UP" || print_error "Failed"
                press_any_key
                ;;
            2)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to bring DOWN")
                [[ -n "$IFACE" ]] && ip link set "$IFACE" down && print_success "Interface $IFACE is now DOWN" || print_error "Failed"
                press_any_key
                ;;
            3)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to set MTU")
                MTU=$(get_input "MTU value (e.g., 1500)")
                [[ -n "$IFACE" && -n "$MTU" ]] && ip link set "$IFACE" mtu "$MTU" && print_success "MTU set to $MTU" || print_error "Failed"
                press_any_key
                ;;
            4)
                IFACE=$(select_interface "Select interface to view")
                if [[ -n "$IFACE" ]]; then
                    echo ""
                    ip addr show "$IFACE" 2>/dev/null || print_error "Interface not found"
                fi
                press_any_key
                ;;
            5)
                check_root || { press_any_key; continue; }
                systemctl restart NetworkManager 2>/dev/null && print_success "NetworkManager restarted" || print_error "Failed to restart"
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# IP Configuration
#-------------------------------------------------------------------------------

ip_config_menu() {
    while true; do
        clear_screen
        print_header "IP CONFIGURATION"
        
        print_section "Current IP Addresses"
        ip -br addr 2>/dev/null | while read iface state addrs; do
            if [[ "$state" == "UP" ]]; then
                printf "  ${GREEN}%-15s${NC} %-10s %s\n" "$iface" "$state" "$addrs"
            else
                printf "  ${DIM}%-15s${NC} %-10s %s\n" "$iface" "$state" "$addrs"
            fi
        done
        
        print_section "Default Gateway"
        ip route | grep default | while read line; do
            echo "  $line"
        done
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Set static IP"
        echo -e "  ${WHITE}2.${NC} Set DHCP (auto)"
        echo -e "  ${WHITE}3.${NC} Add secondary IP"
        echo -e "  ${WHITE}4.${NC} Remove IP address"
        echo -e "  ${WHITE}5.${NC} Set default gateway"
        echo -e "  ${WHITE}6.${NC} Flush all IPs on interface"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface for static IP")
                if [[ -n "$IFACE" ]]; then
                    IP=$(get_input "IP address with CIDR (e.g., 192.168.1.100/24)")
                    GW=$(get_input "Gateway (optional, press Enter to skip)")
                    
                    if [[ -n "$IP" ]]; then
                        ip addr flush dev "$IFACE" 2>/dev/null
                        ip addr add "$IP" dev "$IFACE" && print_success "IP $IP set on $IFACE"
                        [[ -n "$GW" ]] && ip route add default via "$GW" 2>/dev/null && print_success "Gateway set to $GW"
                    fi
                fi
                press_any_key
                ;;
            2)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface for DHCP")
                if [[ -n "$IFACE" ]]; then
                    if cmd_exists dhclient; then
                        dhclient -r "$IFACE" 2>/dev/null
                        dhclient "$IFACE" && print_success "DHCP configured on $IFACE"
                    elif cmd_exists dhcpcd; then
                        dhcpcd "$IFACE" && print_success "DHCP configured on $IFACE"
                    else
                        print_error "No DHCP client found"
                    fi
                fi
                press_any_key
                ;;
            3)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface for secondary IP")
                if [[ -n "$IFACE" ]]; then
                    IP=$(get_input "Secondary IP with CIDR (e.g., 192.168.1.101/24)")
                    [[ -n "$IP" ]] && ip addr add "$IP" dev "$IFACE" && print_success "Added $IP to $IFACE"
                fi
                press_any_key
                ;;
            4)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to remove IP from")
                if [[ -n "$IFACE" ]]; then
                    IP=$(get_input "IP to remove (with CIDR)")
                    [[ -n "$IP" ]] && ip addr del "$IP" dev "$IFACE" && print_success "Removed $IP from $IFACE"
                fi
                press_any_key
                ;;
            5)
                check_root || { press_any_key; continue; }
                GW=$(get_input "Gateway IP")
                if [[ -n "$GW" ]]; then
                    ip route del default 2>/dev/null
                    ip route add default via "$GW" && print_success "Default gateway set to $GW"
                fi
                press_any_key
                ;;
            6)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to flush")
                if [[ -n "$IFACE" ]] && confirm_action; then
                    ip addr flush dev "$IFACE" && print_success "Flushed all IPs from $IFACE"
                fi
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# WiFi Management
#-------------------------------------------------------------------------------

wifi_menu() {
    while true; do
        clear_screen
        print_header "WIFI MANAGEMENT"
        
        if ! cmd_exists nmcli; then
            print_error "NetworkManager (nmcli) is required for WiFi management"
            press_any_key
            return
        fi
        
        print_section "WiFi Status"
        WIFI_STATE=$(nmcli radio wifi 2>/dev/null)
        if [[ "$WIFI_STATE" == "enabled" ]]; then
            echo -e "  WiFi Radio: ${GREEN}Enabled${NC}"
        else
            echo -e "  WiFi Radio: ${RED}Disabled${NC}"
        fi
        
        # Current connection
        CURRENT=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes" | cut -d: -f2)
        [[ -n "$CURRENT" ]] && echo -e "  Connected to: ${GREEN}$CURRENT${NC}" || echo -e "  Connected to: ${YELLOW}Not connected${NC}"
        
        print_section "Available Networks"
        echo -e "  ${DIM}SSID                           Signal  Security${NC}"
        echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
        nmcli -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null | tail -n +2 | head -15 | while read line; do
            echo "  $line"
        done
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Connect to network"
        echo -e "  ${WHITE}2.${NC} Disconnect"
        echo -e "  ${WHITE}3.${NC} Rescan networks"
        echo -e "  ${WHITE}4.${NC} Enable WiFi"
        echo -e "  ${WHITE}5.${NC} Disable WiFi"
        echo -e "  ${WHITE}6.${NC} Saved connections"
        echo -e "  ${WHITE}7.${NC} Forget a network"
        echo -e "  ${WHITE}8.${NC} Create Hotspot"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                SSID=$(select_wifi)
                if [[ -n "$SSID" ]]; then
                    PASS=$(get_input "Password (leave empty if open)")
                    if [[ -n "$PASS" ]]; then
                        nmcli dev wifi connect "$SSID" password "$PASS" && print_success "Connected to $SSID" || print_error "Failed to connect"
                    else
                        nmcli dev wifi connect "$SSID" && print_success "Connected to $SSID" || print_error "Failed to connect"
                    fi
                fi
                press_any_key
                ;;
            2)
                # Find wifi interface
                WIFI_IFACE=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ":wifi" | cut -d: -f1 | head -1)
                if [[ -n "$WIFI_IFACE" ]]; then
                    nmcli dev disconnect "$WIFI_IFACE" && print_success "Disconnected from WiFi"
                else
                    print_error "No WiFi interface found"
                fi
                press_any_key
                ;;
            3)
                echo -e "  ${YELLOW}Scanning...${NC}"
                nmcli dev wifi rescan 2>/dev/null
                sleep 2
                ;;
            4)
                nmcli radio wifi on && print_success "WiFi enabled"
                press_any_key
                ;;
            5)
                nmcli radio wifi off && print_success "WiFi disabled"
                press_any_key
                ;;
            6)
                echo ""
                print_subsection "Saved Connections"
                nmcli -f NAME,TYPE connection show | grep wifi
                press_any_key
                ;;
            7)
                SSID=$(select_saved_wifi)
                if [[ -n "$SSID" ]]; then
                    nmcli connection delete "$SSID" && print_success "Forgot $SSID" || print_error "Failed"
                fi
                press_any_key
                ;;
            8)
                check_root || { press_any_key; continue; }
                SSID=$(get_input "Hotspot name")
                PASS=$(get_input "Password (min 8 chars)")
                if [[ -n "$SSID" && ${#PASS} -ge 8 ]]; then
                    WIFI_IFACE=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ":wifi" | cut -d: -f1 | head -1)
                    nmcli dev wifi hotspot ifname "$WIFI_IFACE" ssid "$SSID" password "$PASS" 2>/dev/null && print_success "Hotspot created" || print_error "Failed"
                else
                    print_error "Invalid SSID or password too short"
                fi
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# DNS Configuration
#-------------------------------------------------------------------------------

dns_menu() {
    while true; do
        clear_screen
        print_header "DNS CONFIGURATION"
        
        print_section "Current DNS Servers"
        if cmd_exists resolvectl; then
            resolvectl status 2>/dev/null | grep -A2 "DNS Servers" | head -5
        else
            echo "  From /etc/resolv.conf:"
            grep "^nameserver" /etc/resolv.conf 2>/dev/null | while read line; do
                echo "  $line"
            done
        fi
        
        print_section "DNS Presets"
        echo -e "  ${WHITE}1.${NC} Cloudflare    ${DIM}(1.1.1.1, 1.0.0.1)${NC} - Fast, privacy-focused"
        echo -e "  ${WHITE}2.${NC} Google        ${DIM}(8.8.8.8, 8.8.4.4)${NC} - Reliable"
        echo -e "  ${WHITE}3.${NC} Quad9         ${DIM}(9.9.9.9, 149.112.112.112)${NC} - Security-focused, blocks malware"
        echo -e "  ${WHITE}4.${NC} OpenDNS       ${DIM}(208.67.222.222, 208.67.220.220)${NC} - Family/content filtering"
        echo -e "  ${WHITE}5.${NC} Custom DNS"
        echo -e "  ${WHITE}6.${NC} Restore DHCP DNS"
        echo -e "  ${WHITE}7.${NC} Flush DNS cache"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        set_dns() {
            local dns1="$1"
            local dns2="$2"
            check_root || return 1
            
            # Backup
            cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
            
            # Try systemd-resolved first
            if cmd_exists resolvectl; then
                resolvectl dns $(ip route | grep default | awk '{print $5}' | head -1) "$dns1" "$dns2" 2>/dev/null
            fi
            
            # Also update resolv.conf
            echo "# Generated by Network Control Center" > /etc/resolv.conf
            echo "nameserver $dns1" >> /etc/resolv.conf
            echo "nameserver $dns2" >> /etc/resolv.conf
            
            print_success "DNS set to $dns1 and $dns2"
        }
        
        case $choice in
            1) set_dns "1.1.1.1" "1.0.0.1"; press_any_key ;;
            2) set_dns "8.8.8.8" "8.8.4.4"; press_any_key ;;
            3) set_dns "9.9.9.9" "149.112.112.112"; press_any_key ;;
            4) set_dns "208.67.222.222" "208.67.220.220"; press_any_key ;;
            5)
                DNS1=$(get_input "Primary DNS")
                DNS2=$(get_input "Secondary DNS")
                [[ -n "$DNS1" ]] && set_dns "$DNS1" "${DNS2:-$DNS1}"
                press_any_key
                ;;
            6)
                check_root || { press_any_key; continue; }
                if [[ -f /etc/resolv.conf.backup ]]; then
                    cp /etc/resolv.conf.backup /etc/resolv.conf
                    print_success "Restored from backup"
                else
                    systemctl restart NetworkManager 2>/dev/null && print_success "Restarted NetworkManager"
                fi
                press_any_key
                ;;
            7)
                if cmd_exists resolvectl; then
                    resolvectl flush-caches && print_success "DNS cache flushed"
                elif cmd_exists systemd-resolve; then
                    systemd-resolve --flush-caches && print_success "DNS cache flushed"
                else
                    print_info "No cache to flush or not using systemd-resolved"
                fi
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Routing Table
#-------------------------------------------------------------------------------

routing_menu() {
    while true; do
        clear_screen
        print_header "ROUTING TABLE"
        
        print_section "IPv4 Routes"
        ip -4 route 2>/dev/null | while read line; do
            echo "  $line"
        done
        
        print_section "IPv6 Routes"
        ip -6 route 2>/dev/null | head -10 | while read line; do
            echo "  $line"
        done
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Add static route"
        echo -e "  ${WHITE}2.${NC} Delete route"
        echo -e "  ${WHITE}3.${NC} Change default gateway"
        echo -e "  ${WHITE}4.${NC} Flush routing cache"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                check_root || { press_any_key; continue; }
                echo ""
                echo -e "  ${DIM}Example: 10.0.0.0/8 via 192.168.1.1${NC}"
                DEST=$(get_input "Destination network (CIDR)")
                GW=$(get_input "Gateway")
                [[ -n "$DEST" && -n "$GW" ]] && ip route add "$DEST" via "$GW" && print_success "Route added" || print_error "Failed"
                press_any_key
                ;;
            2)
                check_root || { press_any_key; continue; }
                DEST=$(get_input "Destination to remove")
                [[ -n "$DEST" ]] && ip route del "$DEST" && print_success "Route deleted" || print_error "Failed"
                press_any_key
                ;;
            3)
                check_root || { press_any_key; continue; }
                GW=$(get_input "New default gateway")
                if [[ -n "$GW" ]]; then
                    ip route del default 2>/dev/null
                    ip route add default via "$GW" && print_success "Default gateway changed to $GW"
                fi
                press_any_key
                ;;
            4)
                check_root || { press_any_key; continue; }
                ip route flush cache && print_success "Routing cache flushed"
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Firewall Configuration
#-------------------------------------------------------------------------------

firewall_menu() {
    while true; do
        clear_screen
        print_header "FIREWALL CONFIGURATION"
        
        # Detect firewall
        FIREWALL=""
        if cmd_exists ufw; then
            FIREWALL="ufw"
        elif cmd_exists firewall-cmd; then
            FIREWALL="firewalld"
        elif cmd_exists iptables; then
            FIREWALL="iptables"
        fi
        
        if [[ -z "$FIREWALL" ]]; then
            print_error "No firewall tool found"
            press_any_key
            return
        fi
        
        print_section "Firewall Status ($FIREWALL)"
        
        if [[ "$FIREWALL" == "ufw" ]]; then
            ufw status verbose 2>/dev/null | head -20
        elif [[ "$FIREWALL" == "firewalld" ]]; then
            firewall-cmd --state 2>/dev/null
            firewall-cmd --list-all 2>/dev/null | head -15
        elif [[ "$FIREWALL" == "iptables" ]]; then
            iptables -L -n 2>/dev/null | head -20
        fi
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Enable firewall"
        echo -e "  ${WHITE}2.${NC} Disable firewall"
        echo -e "  ${WHITE}3.${NC} Allow port"
        echo -e "  ${WHITE}4.${NC} Deny port"
        echo -e "  ${WHITE}5.${NC} Delete rule"
        echo -e "  ${WHITE}6.${NC} Allow IP"
        echo -e "  ${WHITE}7.${NC} Block IP"
        echo -e "  ${WHITE}8.${NC} Reset to defaults"
        echo ""
        echo -e "  ${DIM}Presets:${NC}"
        echo -e "  ${WHITE}A.${NC} Allow SSH (22)"
        echo -e "  ${WHITE}B.${NC} Allow HTTP/HTTPS (80,443)"
        echo -e "  ${WHITE}C.${NC} Desktop preset (outgoing only)"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                check_root || { press_any_key; continue; }
                if [[ "$FIREWALL" == "ufw" ]]; then
                    ufw --force enable && print_success "UFW enabled"
                elif [[ "$FIREWALL" == "firewalld" ]]; then
                    systemctl start firewalld && systemctl enable firewalld && print_success "Firewalld enabled"
                fi
                press_any_key
                ;;
            2)
                check_root || { press_any_key; continue; }
                if [[ "$FIREWALL" == "ufw" ]]; then
                    ufw disable && print_success "UFW disabled"
                elif [[ "$FIREWALL" == "firewalld" ]]; then
                    systemctl stop firewalld && print_success "Firewalld stopped"
                fi
                press_any_key
                ;;
            3)
                check_root || { press_any_key; continue; }
                PORT=$(get_input "Port number (e.g., 80 or 80/tcp)")
                if [[ -n "$PORT" ]]; then
                    if [[ "$FIREWALL" == "ufw" ]]; then
                        ufw allow "$PORT" && print_success "Allowed port $PORT"
                    elif [[ "$FIREWALL" == "firewalld" ]]; then
                        firewall-cmd --permanent --add-port="$PORT" && firewall-cmd --reload && print_success "Allowed port $PORT"
                    fi
                fi
                press_any_key
                ;;
            4)
                check_root || { press_any_key; continue; }
                PORT=$(get_input "Port number")
                if [[ -n "$PORT" ]]; then
                    if [[ "$FIREWALL" == "ufw" ]]; then
                        ufw deny "$PORT" && print_success "Denied port $PORT"
                    fi
                fi
                press_any_key
                ;;
            5)
                check_root || { press_any_key; continue; }
                if [[ "$FIREWALL" == "ufw" ]]; then
                    echo ""
                    echo -e "  ${CYAN}Current Rules:${NC}"
                    echo -e "  ${DIM}─────────────────────────────${NC}"
                    ufw status numbered | tail -n +5
                    echo ""
                    RULE=$(get_input "Rule number to delete (e.g., 1)")
                    [[ -n "$RULE" ]] && ufw --force delete "$RULE" && print_success "Rule deleted" || print_error "Failed"
                fi
                press_any_key
                ;;
            6)
                check_root || { press_any_key; continue; }
                IP=$(get_input "IP address to allow")
                if [[ -n "$IP" && "$FIREWALL" == "ufw" ]]; then
                    ufw allow from "$IP" && print_success "Allowed $IP"
                fi
                press_any_key
                ;;
            7)
                check_root || { press_any_key; continue; }
                IP=$(get_input "IP address to block")
                if [[ -n "$IP" && "$FIREWALL" == "ufw" ]]; then
                    ufw deny from "$IP" && print_success "Blocked $IP"
                fi
                press_any_key
                ;;
            8)
                check_root || { press_any_key; continue; }
                if confirm_action; then
                    if [[ "$FIREWALL" == "ufw" ]]; then
                        ufw --force reset && print_success "UFW reset to defaults"
                    fi
                fi
                press_any_key
                ;;
            a|A)
                check_root || { press_any_key; continue; }
                [[ "$FIREWALL" == "ufw" ]] && ufw allow 22/tcp && print_success "SSH allowed"
                press_any_key
                ;;
            b|B)
                check_root || { press_any_key; continue; }
                if [[ "$FIREWALL" == "ufw" ]]; then
                    ufw allow 80/tcp && ufw allow 443/tcp && print_success "HTTP/HTTPS allowed"
                fi
                press_any_key
                ;;
            c|C)
                check_root || { press_any_key; continue; }
                if [[ "$FIREWALL" == "ufw" ]]; then
                    ufw default deny incoming
                    ufw default allow outgoing
                    ufw --force enable
                    print_success "Desktop preset applied (deny incoming, allow outgoing)"
                fi
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Network Diagnostics
#-------------------------------------------------------------------------------

diagnostics_menu() {
    while true; do
        clear_screen
        print_header "NETWORK DIAGNOSTICS"
        
        print_section "Quick Tests"
        echo -e "  ${WHITE}1.${NC} Ping test"
        echo -e "  ${WHITE}2.${NC} Traceroute"
        echo -e "  ${WHITE}3.${NC} DNS lookup"
        echo -e "  ${WHITE}4.${NC} Port check (local)"
        echo -e "  ${WHITE}5.${NC} Port check (remote)"
        echo -e "  ${WHITE}6.${NC} Speed test"
        echo -e "  ${WHITE}7.${NC} Check internet connectivity"
        echo -e "  ${WHITE}8.${NC} Whois lookup"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                echo ""
                echo -e "  ${DIM}Common targets: google.com, 1.1.1.1, 8.8.8.8, your gateway${NC}"
                HOST=$(get_input "Host to ping")
                if [[ -n "$HOST" ]]; then
                    echo ""
                    echo -e "  ${YELLOW}Pinging $HOST...${NC}"
                    echo ""
                    ping -c 5 "$HOST"
                fi
                press_any_key
                ;;
            2)
                echo ""
                echo -e "  ${DIM}Shows the path packets take to reach destination${NC}"
                HOST=$(get_input "Host to trace")
                if [[ -n "$HOST" ]]; then
                    echo ""
                    echo -e "  ${YELLOW}Tracing route to $HOST...${NC}"
                    echo ""
                    if cmd_exists traceroute; then
                        traceroute "$HOST"
                    elif cmd_exists tracepath; then
                        tracepath "$HOST"
                    else
                        print_error "traceroute not installed (sudo apt install traceroute)"
                    fi
                fi
                press_any_key
                ;;
            3)
                echo ""
                echo -e "  ${DIM}Resolve domain name to IP address${NC}"
                HOST=$(get_input "Domain to lookup (e.g., google.com)")
                if [[ -n "$HOST" ]]; then
                    echo ""
                    if cmd_exists dig; then
                        echo -e "  ${CYAN}IP Addresses:${NC}"
                        dig "$HOST" +short | while read ip; do echo "    $ip"; done
                        echo ""
                        echo -e "  ${CYAN}Full DNS Records:${NC}"
                        dig "$HOST" ANY +noall +answer 2>/dev/null | while read line; do echo "    $line"; done
                    elif cmd_exists nslookup; then
                        nslookup "$HOST"
                    elif cmd_exists host; then
                        host "$HOST"
                    fi
                fi
                press_any_key
                ;;
            4)
                echo ""
                print_subsection "Listening Ports"
                echo -e "  ${DIM}Proto    Local Address          Port     Process${NC}"
                echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
                ss -tulnp 2>/dev/null | grep LISTEN | awk '{printf "  %-8s %-22s %-8s %s\n", $1, $5, "", $7}' | head -20
                press_any_key
                ;;
            5)
                echo ""
                echo -e "  ${DIM}Check if a port is open on a remote host${NC}"
                HOST=$(get_input "Host (IP or domain)")
                PORT=$(get_input "Port number")
                if [[ -n "$HOST" && -n "$PORT" ]]; then
                    echo ""
                    echo -e "  ${YELLOW}Checking $HOST:$PORT...${NC}"
                    timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null && print_success "Port $PORT is OPEN on $HOST" || print_error "Port $PORT is CLOSED or filtered on $HOST"
                fi
                press_any_key
                ;;
            6)
                if cmd_exists speedtest-cli; then
                    echo ""
                    speedtest-cli --simple
                elif cmd_exists speedtest; then
                    echo ""
                    speedtest
                else
                    print_info "Install speedtest-cli: pip install speedtest-cli"
                    echo ""
                    echo -e "  ${YELLOW}Running basic download test...${NC}"
                    curl -o /dev/null -w "Download speed: %{speed_download} bytes/sec\n" https://speed.hetzner.de/100MB.bin 2>/dev/null | head -1
                fi
                press_any_key
                ;;
            7)
                echo ""
                echo -e "  ${CYAN}Running connectivity tests...${NC}"
                echo ""
                
                # Test 1: Gateway
                GW=$(ip route | grep default | awk '{print $3}' | head -1)
                if [[ -n "$GW" ]]; then
                    ping -c 1 -W 2 "$GW" &>/dev/null && print_success "Gateway ($GW): Reachable" || print_error "Gateway ($GW): Unreachable"
                else
                    print_error "No default gateway configured"
                fi
                
                # Test 2: IPv4 Internet
                ping -c 1 -W 3 1.1.1.1 &>/dev/null && print_success "IPv4 Internet (1.1.1.1): OK" || print_error "IPv4 Internet (1.1.1.1): FAIL - Check gateway/ISP"
                
                # Test 3: DNS
                ping -c 1 -W 3 google.com &>/dev/null && print_success "DNS Resolution: OK" || print_error "DNS Resolution: FAIL - Check DNS settings"
                
                # Test 4: HTTPS
                curl -s --max-time 5 https://www.google.com &>/dev/null && print_success "HTTPS Traffic: OK" || print_error "HTTPS Traffic: FAIL - Check firewall"
                
                echo ""
                echo -e "  ${DIM}If gateway works but internet fails: ISP issue${NC}"
                echo -e "  ${DIM}If internet works but DNS fails: Change DNS servers${NC}"
                echo -e "  ${DIM}If DNS works but HTTPS fails: Firewall blocking${NC}"
                press_any_key
                ;;
            8)
                echo ""
                echo -e "  ${DIM}Get registration info for a domain${NC}"
                DOMAIN=$(get_input "Domain (e.g., google.com)")
                if [[ -n "$DOMAIN" ]]; then
                    if cmd_exists whois; then
                        echo ""
                        whois "$DOMAIN" | head -40
                    else
                        print_error "whois not installed (sudo apt install whois)"
                    fi
                fi
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Advanced Tools
#-------------------------------------------------------------------------------

advanced_menu() {
    while true; do
        clear_screen
        print_header "ADVANCED TOOLS"
        
        print_section "Tools"
        echo -e "  ${WHITE}1.${NC} Change MAC address"
        echo -e "  ${WHITE}2.${NC} Restore original MAC"
        echo -e "  ${WHITE}3.${NC} Wake-on-LAN"
        echo -e "  ${WHITE}4.${NC} ARP table"
        echo -e "  ${WHITE}5.${NC} Network namespace list"
        echo -e "  ${WHITE}6.${NC} Bridge management"
        echo -e "  ${WHITE}7.${NC} VLAN management"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu    ${WHITE}Q.${NC} Quit"
        echo ""
        echo -ne "  ${WHITE}Enter choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to change MAC")
                if [[ -n "$IFACE" ]]; then
                    NEWMAC=$(get_input "New MAC (or 'random')")
                    # Save original
                    ORIG_MAC=$(cat /sys/class/net/$IFACE/address 2>/dev/null)
                    echo "$ORIG_MAC" > /tmp/orig_mac_$IFACE 2>/dev/null
                    
                    ip link set "$IFACE" down
                    if [[ "$NEWMAC" == "random" ]]; then
                        NEWMAC=$(printf '%02x:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
                    fi
                    ip link set "$IFACE" address "$NEWMAC"
                    ip link set "$IFACE" up
                    print_success "MAC changed to $NEWMAC"
                fi
                press_any_key
                ;;
            2)
                check_root || { press_any_key; continue; }
                IFACE=$(select_interface "Select interface to restore MAC")
                if [[ -n "$IFACE" ]]; then
                    if [[ -f /tmp/orig_mac_$IFACE ]]; then
                        ORIG=$(cat /tmp/orig_mac_$IFACE)
                        ip link set "$IFACE" down
                        ip link set "$IFACE" address "$ORIG"
                        ip link set "$IFACE" up
                        print_success "MAC restored to $ORIG"
                    else
                        print_error "Original MAC not saved"
                    fi
                fi
                press_any_key
                ;;
            3)
                MAC=$(get_input "Target MAC address (xx:xx:xx:xx:xx:xx)")
                if [[ -n "$MAC" ]]; then
                    if cmd_exists wakeonlan; then
                        wakeonlan "$MAC" && print_success "WOL packet sent"
                    elif cmd_exists etherwake; then
                        etherwake "$MAC" && print_success "WOL packet sent"
                    else
                        print_error "Install wakeonlan: sudo apt install wakeonlan"
                    fi
                fi
                press_any_key
                ;;
            4)
                echo ""
                print_subsection "ARP Table"
                ip neigh show
                press_any_key
                ;;
            5)
                echo ""
                print_subsection "Network Namespaces"
                ip netns list 2>/dev/null || echo "  No namespaces or not supported"
                press_any_key
                ;;
            6)
                echo ""
                print_subsection "Bridges"
                bridge link 2>/dev/null || ip link show type bridge 2>/dev/null
                press_any_key
                ;;
            7)
                echo ""
                print_subsection "VLANs"
                ip -d link show | grep -A1 "vlan" 2>/dev/null || echo "  No VLANs configured"
                press_any_key
                ;;
            m|M) return ;;
            q|Q) clear_screen; exit 0 ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Traffic Monitor
#-------------------------------------------------------------------------------

traffic_monitor() {
    clear_screen
    print_header "TRAFFIC MONITOR"
    
    if cmd_exists iftop; then
        echo -e "  ${YELLOW}Starting iftop (press Q to quit)...${NC}"
        sleep 1
        sudo iftop 2>/dev/null || print_error "Run with sudo for iftop"
    elif cmd_exists nethogs; then
        echo -e "  ${YELLOW}Starting nethogs (press Q to quit)...${NC}"
        sleep 1
        sudo nethogs 2>/dev/null || print_error "Run with sudo for nethogs"
    elif cmd_exists nload; then
        echo -e "  ${YELLOW}Starting nload (press Q to quit)...${NC}"
        sleep 1
        nload
    else
        print_section "Live Interface Statistics"
        echo -e "  ${DIM}Press Ctrl+C to stop${NC}"
        echo ""
        
        while true; do
            clear_screen
            print_header "TRAFFIC MONITOR (Ctrl+C to stop)"
            echo ""
            echo -e "  ${DIM}Interface        RX bytes        TX bytes        RX packets      TX packets${NC}"
            echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────${NC}"
            
            for iface in $(ls /sys/class/net/ 2>/dev/null); do
                RX_BYTES=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null)
                TX_BYTES=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null)
                RX_PACKETS=$(cat /sys/class/net/$iface/statistics/rx_packets 2>/dev/null)
                TX_PACKETS=$(cat /sys/class/net/$iface/statistics/tx_packets 2>/dev/null)
                
                # Convert to human readable
                RX_HR=$(numfmt --to=iec $RX_BYTES 2>/dev/null || echo $RX_BYTES)
                TX_HR=$(numfmt --to=iec $TX_BYTES 2>/dev/null || echo $TX_BYTES)
                
                printf "  %-16s %-15s %-15s %-15s %s\n" "$iface" "$RX_HR" "$TX_HR" "$RX_PACKETS" "$TX_PACKETS"
            done
            
            echo ""
            echo -e "  ${DIM}Refreshing every 2 seconds...${NC}"
            sleep 2
        done
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Connection Status
#-------------------------------------------------------------------------------

connection_status() {
    while true; do
        clear_screen
        print_header "CONNECTION STATUS"
        
        print_section "Active Connections"
        echo -e "  ${DIM}Proto  Local Address          Foreign Address        State       PID/Program${NC}"
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────────────${NC}"
        
        ss -tupn 2>/dev/null | tail -n +2 | head -25 | while read proto recv send local foreign state info; do
            printf "  %-6s %-22s %-22s %-11s %s\n" "$proto" "${local:0:22}" "${foreign:0:22}" "$state" "$info"
        done
        
        print_section "Statistics"
        ESTABLISHED=$(ss -t state established 2>/dev/null | wc -l)
        LISTENING=$(ss -tln 2>/dev/null | grep -c LISTEN)
        TIME_WAIT=$(ss -t state time-wait 2>/dev/null | wc -l)
        
        print_item "Established" "$ESTABLISHED"
        print_item "Listening" "$LISTENING"
        print_item "Time-Wait" "$TIME_WAIT"
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Network Summary
#-------------------------------------------------------------------------------

network_summary() {
    while true; do
        clear_screen
        print_header "NETWORK SUMMARY"
        
        print_section "System"
        print_item "Hostname" "$(hostname)"
        print_item "Domain" "$(hostname -d 2>/dev/null || echo 'N/A')"
        
        print_section "Interfaces"
        ip -br addr 2>/dev/null | while read iface state addrs; do
            if [[ "$state" == "UP" ]]; then
                print_item "$iface" "$addrs"
            fi
        done
        
        print_section "Default Route"
        DEFAULT_GW=$(ip route | grep default | head -1)
        echo "  $DEFAULT_GW"
        
        print_section "DNS Servers"
        grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print "  " $2}'
        
        print_section "Firewall"
        if cmd_exists ufw; then
            STATUS=$(ufw status 2>/dev/null | head -1)
            print_item "UFW" "$STATUS"
        fi
        
        print_section "Connectivity"
        ping -c 1 -W 2 1.1.1.1 &>/dev/null && print_item "Internet" "${GREEN}Connected${NC}" || print_item "Internet" "${RED}Disconnected${NC}"
        
        print_section "WiFi"
        if cmd_exists nmcli; then
            SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes" | cut -d: -f2)
            [[ -n "$SSID" ]] && print_item "Connected SSID" "$SSID" || print_item "WiFi" "Not connected"
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

# Check for basic requirements
if ! cmd_exists ip; then
    echo -e "${RED}Error: 'ip' command not found. Install iproute2.${NC}"
    exit 1
fi

show_main_menu
