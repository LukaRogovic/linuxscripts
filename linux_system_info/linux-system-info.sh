#!/bin/bash

#===============================================================================
# LINUX SYSTEM INFORMATION - TERMINAL UI
# Interactive terminal application for comprehensive system information
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
    printf "  ${GREEN}%-32s${NC} : %s\n" "$1" "$2"
}

print_subitem() {
    printf "    ${DIM}%-30s${NC} : %s\n" "$1" "$2"
}

print_item_warn() {
    printf "  ${YELLOW}%-32s${NC} : %s\n" "$1" "$2"
}

print_item_error() {
    printf "  ${RED}%-32s${NC} : %s\n" "$1" "$2"
}

bytes_to_human() {
    local bytes=$1
    if [[ $bytes -ge 1099511627776 ]]; then
        awk "BEGIN {printf \"%.2f TB\", $bytes/1099511627776}"
    elif [[ $bytes -ge 1073741824 ]]; then
        awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}"
    elif [[ $bytes -ge 1048576 ]]; then
        awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}"
    elif [[ $bytes -ge 1024 ]]; then
        awk "BEGIN {printf \"%.2f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

wait_for_menu() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}[R]${NC} Rerun    ${WHITE}[M]${NC} Main Menu    ${WHITE}[Q]${NC} Quit"
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

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s -r
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
        echo "║    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗                   ║"
        echo "║    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║                   ║"
        echo "║    ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║                   ║"
        echo "║    ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║                   ║"
        echo "║    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║                   ║"
        echo "║    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝                   ║"
        echo "║                       ██╗███╗   ██╗███████╗ ██████╗                        ║"
        echo "║                       ██║████╗  ██║██╔════╝██╔═══██╗                       ║"
        echo "║                       ██║██╔██╗ ██║█████╗  ██║   ██║                       ║"
        echo "║                       ██║██║╚██╗██║██╔══╝  ██║   ██║                       ║"
        echo "║                       ██║██║ ╚████║██║     ╚██████╔╝                       ║"
        echo "║                       ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝                        ║"
        echo "║                                                                            ║"
        echo "║                   COMPREHENSIVE LINUX SYSTEM INFORMATION                   ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com -                   ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${WHITE}  Select a category:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Operating System${NC}              ${WHITE}12.${NC} ${GREEN}USB Devices${NC}                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Kernel Information${NC}            ${WHITE}13.${NC} ${GREEN}PCI Devices${NC}                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}CPU Information${NC}               ${WHITE}14.${NC} ${GREEN}Audio Information${NC}                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Memory Information${NC}            ${WHITE}15.${NC} ${GREEN}Desktop Environment${NC}               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Storage Information${NC}           ${WHITE}16.${NC} ${GREEN}Process Information${NC}               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}GPU/Graphics${NC}                  ${WHITE}17.${NC} ${GREEN}Systemd Services${NC}                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Network Information${NC}           ${WHITE}18.${NC} ${GREEN}Users & Security${NC}                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Network Connections${NC}           ${WHITE}19.${NC} ${GREEN}Virtualization${NC}                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Firewall Status${NC}               ${WHITE}20.${NC} ${GREEN}Boot Information${NC}                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}10.${NC} ${GREEN}WiFi & Bluetooth${NC}              ${WHITE}21.${NC} ${GREEN}Battery (Laptops)${NC}                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}11.${NC} ${GREEN}Hardware Overview (DMI)${NC}       ${WHITE}22.${NC} ${GREEN}Sensors & Thermal${NC}                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} A.${NC} ${YELLOW}Run ALL Sections${NC}               ${WHITE} S.${NC} ${YELLOW}Save Full Report${NC}                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) run_section "os_info" ;;
            2) run_section "kernel_info" ;;
            3) run_section "cpu_info" ;;
            4) run_section "memory_info" ;;
            5) run_section "storage_info" ;;
            6) run_section "gpu_info" ;;
            7) run_section "network_info" ;;
            8) run_section "network_connections" ;;
            9) run_section "firewall_info" ;;
            10) run_section "wifi_bluetooth" ;;
            11) run_section "hardware_dmi" ;;
            12) run_section "usb_devices" ;;
            13) run_section "pci_devices" ;;
            14) run_section "audio_info" ;;
            15) run_section "desktop_env" ;;
            16) run_section "process_info" ;;
            17) run_section "systemd_services" ;;
            18) run_section "users_security" ;;
            19) run_section "virtualization" ;;
            20) run_section "boot_info" ;;
            21) run_section "battery_info" ;;
            22) run_section "sensors_thermal" ;;
            a|A) run_section "all" ;;
            s|S) save_report ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Linux System Info!${NC}"
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
# Section Runner
#-------------------------------------------------------------------------------

run_section() {
    local section="$1"
    
    while true; do
        clear_screen
        
        case $section in
            os_info) show_os_info ;;
            kernel_info) show_kernel_info ;;
            cpu_info) show_cpu_info ;;
            memory_info) show_memory_info ;;
            storage_info) show_storage_info ;;
            gpu_info) show_gpu_info ;;
            network_info) show_network_info ;;
            network_connections) show_network_connections ;;
            firewall_info) show_firewall_info ;;
            wifi_bluetooth) show_wifi_bluetooth ;;
            hardware_dmi) show_hardware_dmi ;;
            usb_devices) show_usb_devices ;;
            pci_devices) show_pci_devices ;;
            audio_info) show_audio_info ;;
            desktop_env) show_desktop_env ;;
            process_info) show_process_info ;;
            systemd_services) show_systemd_services ;;
            users_security) show_users_security ;;
            virtualization) show_virtualization ;;
            boot_info) show_boot_info ;;
            battery_info) show_battery_info ;;
            sensors_thermal) show_sensors_thermal ;;
            all) show_all_sections ;;
        esac
        
        wait_for_menu
        local result=$?
        
        [[ $result -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Section: Operating System
#-------------------------------------------------------------------------------

show_os_info() {
    print_header "OPERATING SYSTEM INFORMATION"
    
    print_section "Distribution Details"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release 2>/dev/null
        print_item "Distribution" "${NAME:-N/A}"
        print_item "Version" "${VERSION:-N/A}"
        print_item "Version ID" "${VERSION_ID:-N/A}"
        print_item "Codename" "${VERSION_CODENAME:-N/A}"
        print_item "ID" "${ID:-N/A}"
        print_item "ID Like" "${ID_LIKE:-N/A}"
        print_item "Pretty Name" "${PRETTY_NAME:-N/A}"
    fi
    
    print_section "System Details"
    print_item "Hostname" "$(hostname)"
    print_item "FQDN" "$(hostname -f 2>/dev/null || echo 'N/A')"
    print_item "Machine ID" "$(cat /etc/machine-id 2>/dev/null || echo 'N/A')"
    print_item "Architecture" "$(uname -m) ($(getconf LONG_BIT)-bit)"
    print_item "Uptime" "$(uptime -p 2>/dev/null || uptime)"
    print_item "Last Boot" "$(who -b 2>/dev/null | awk '{print $3, $4}')"
    print_item "Current Time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    print_item "Timezone" "$(timedatectl 2>/dev/null | grep 'Time zone' | awk '{print $3, $4, $5}' || cat /etc/timezone 2>/dev/null)"
    print_item "Locale" "${LANG:-N/A}"
}

#-------------------------------------------------------------------------------
# Section: Kernel Information
#-------------------------------------------------------------------------------

show_kernel_info() {
    print_header "KERNEL INFORMATION"
    
    print_section "Kernel Details"
    print_item "Kernel Name" "$(uname -s)"
    print_item "Kernel Release" "$(uname -r)"
    print_item "Kernel Version" "$(uname -v)"
    
    print_section "Loaded Modules"
    MODULE_COUNT=$(lsmod 2>/dev/null | tail -n +2 | wc -l)
    print_item "Total Loaded Modules" "$MODULE_COUNT"
    
    print_subsection "Top 10 Largest Modules"
    lsmod 2>/dev/null | tail -n +2 | sort -k2 -rn | head -10 | awk '{printf "  %-25s %10s bytes\n", $1, $2}'
    
    print_section "Security Modules"
    if [[ -f /sys/kernel/security/lsm ]]; then
        print_item "Active LSMs" "$(cat /sys/kernel/security/lsm 2>/dev/null)"
    fi
    
    if cmd_exists getenforce; then
        print_item "SELinux" "$(getenforce 2>/dev/null)"
    fi
    
    if cmd_exists aa-status; then
        print_item "AppArmor" "$(aa-status --enabled 2>/dev/null && echo 'Enabled' || echo 'Disabled')"
    fi
}

#-------------------------------------------------------------------------------
# Section: CPU Information
#-------------------------------------------------------------------------------

show_cpu_info() {
    print_header "CPU INFORMATION"
    
    print_section "CPU Details"
    if [[ -f /proc/cpuinfo ]]; then
        print_item "Model" "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "Vendor" "$(grep -m1 'vendor_id' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "CPU Family" "$(grep -m1 'cpu family' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "Stepping" "$(grep -m1 'stepping' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "Current MHz" "$(grep -m1 'cpu MHz' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "Cache Size" "$(grep -m1 'cache size' /proc/cpuinfo | cut -d: -f2 | xargs)"
        print_item "BogoMIPS" "$(grep -m1 'bogomips' /proc/cpuinfo | cut -d: -f2 | xargs)"
    fi
    
    PHYSICAL=$(grep 'physical id' /proc/cpuinfo 2>/dev/null | sort -u | wc -l)
    CORES=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
    print_item "Physical CPUs" "${PHYSICAL:-1}"
    print_item "Logical CPUs" "$CORES"
    
    print_section "CPU Frequency"
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        print_item "Governor" "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
        print_item "Min Freq" "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null | awk '{print $1/1000 " MHz"}')"
        print_item "Max Freq" "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null | awk '{print $1/1000 " MHz"}')"
    fi
    
    print_section "Virtualization"
    if grep -q 'vmx' /proc/cpuinfo 2>/dev/null; then
        print_item "Intel VT-x" "Supported"
    elif grep -q 'svm' /proc/cpuinfo 2>/dev/null; then
        print_item "AMD-V" "Supported"
    else
        print_item "Hardware Virt" "Not detected"
    fi
    
    print_section "CPU Vulnerabilities"
    if [[ -d /sys/devices/system/cpu/vulnerabilities ]]; then
        for vuln in /sys/devices/system/cpu/vulnerabilities/*; do
            NAME=$(basename "$vuln")
            STATUS=$(cat "$vuln" 2>/dev/null)
            if [[ "$STATUS" == *"Vulnerable"* ]]; then
                print_item_error "$NAME" "${STATUS:0:50}"
            elif [[ "$STATUS" == *"Mitigation"* ]]; then
                print_item_warn "$NAME" "${STATUS:0:50}"
            else
                print_item "$NAME" "${STATUS:0:50}"
            fi
        done
    fi
}

#-------------------------------------------------------------------------------
# Section: Memory Information
#-------------------------------------------------------------------------------

show_memory_info() {
    print_header "MEMORY INFORMATION"
    
    print_section "Memory Usage"
    if [[ -f /proc/meminfo ]]; then
        MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        MEM_FREE=$(grep MemFree /proc/meminfo | awk '{print $2}')
        MEM_AVAILABLE=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        MEM_BUFFERS=$(grep Buffers /proc/meminfo | awk '{print $2}')
        MEM_CACHED=$(grep "^Cached:" /proc/meminfo | awk '{print $2}')
        SWAP_TOTAL=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
        SWAP_FREE=$(grep SwapFree /proc/meminfo | awk '{print $2}')
        
        MEM_USED=$((MEM_TOTAL - MEM_FREE - MEM_BUFFERS - MEM_CACHED))
        
        print_item "Total Memory" "$(bytes_to_human $((MEM_TOTAL * 1024)))"
        print_item "Used Memory" "$(bytes_to_human $((MEM_USED * 1024)))"
        print_item "Free Memory" "$(bytes_to_human $((MEM_FREE * 1024)))"
        print_item "Available" "$(bytes_to_human $((MEM_AVAILABLE * 1024)))"
        print_item "Buffers" "$(bytes_to_human $((MEM_BUFFERS * 1024)))"
        print_item "Cached" "$(bytes_to_human $((MEM_CACHED * 1024)))"
        print_item "Memory Usage" "$((MEM_USED * 100 / MEM_TOTAL))%"
        
        print_section "Swap"
        print_item "Total Swap" "$(bytes_to_human $((SWAP_TOTAL * 1024)))"
        print_item "Free Swap" "$(bytes_to_human $((SWAP_FREE * 1024)))"
        if [[ $SWAP_TOTAL -gt 0 ]]; then
            SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
            print_item "Swap Usage" "$((SWAP_USED * 100 / SWAP_TOTAL))%"
        fi
        
        print_section "Additional Info"
        print_item "Dirty Pages" "$(grep Dirty /proc/meminfo | awk '{print $2, $3}')"
        print_item "Shmem" "$(grep Shmem /proc/meminfo | awk '{print $2, $3}')"
        print_item "HugePages Total" "$(grep HugePages_Total /proc/meminfo | awk '{print $2}')"
    fi
}

#-------------------------------------------------------------------------------
# Section: Storage Information
#-------------------------------------------------------------------------------

show_storage_info() {
    print_header "STORAGE INFORMATION"
    
    print_section "Block Devices"
    if cmd_exists lsblk; then
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null | head -20
    fi
    
    print_section "Disk Usage"
    df -h 2>/dev/null | grep -v "^tmpfs\|^devtmpfs\|^overlay" | head -15
    
    print_section "Mount Points"
    mount | grep "^/dev" | head -10
}

#-------------------------------------------------------------------------------
# Section: GPU/Graphics
#-------------------------------------------------------------------------------

show_gpu_info() {
    print_header "GPU/GRAPHICS INFORMATION"
    
    print_section "GPU Devices"
    if cmd_exists lspci; then
        lspci 2>/dev/null | grep -iE 'vga|3d|display' | while read line; do
            echo "  $line"
        done
    fi
    
    if cmd_exists nvidia-smi; then
        print_section "NVIDIA GPU"
        nvidia-smi --query-gpu=name,driver_version,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null | while IFS=',' read name driver mem temp; do
            print_item "Model" "$name"
            print_item "Driver" "$driver"
            print_item "Memory" "$mem"
            print_item "Temperature" "$temp"
        done
    fi
    
    print_section "OpenGL"
    if cmd_exists glxinfo; then
        print_item "Vendor" "$(glxinfo 2>/dev/null | grep 'OpenGL vendor' | cut -d: -f2 | xargs)"
        print_item "Renderer" "$(glxinfo 2>/dev/null | grep 'OpenGL renderer' | cut -d: -f2 | xargs)"
        print_item "Version" "$(glxinfo 2>/dev/null | grep 'OpenGL version' | cut -d: -f2 | xargs)"
    else
        echo -e "  ${DIM}Install mesa-utils for OpenGL info${NC}"
    fi
    
    print_section "Display"
    print_item "DISPLAY" "${DISPLAY:-N/A}"
    print_item "WAYLAND_DISPLAY" "${WAYLAND_DISPLAY:-N/A}"
    
    if cmd_exists xrandr && [[ -n "$DISPLAY" ]]; then
        print_subsection "Connected Displays"
        xrandr 2>/dev/null | grep " connected" | while read line; do
            echo "  $line"
        done
    fi
}

#-------------------------------------------------------------------------------
# Section: Network Information
#-------------------------------------------------------------------------------

show_network_info() {
    print_header "NETWORK INFORMATION"
    
    print_section "Network Interfaces"
    if cmd_exists ip; then
        ip -br addr 2>/dev/null | while read iface state addr rest; do
            print_item "$iface ($state)" "${addr:-No IP}"
        done
    fi
    
    print_section "Interface Details"
    for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 | head -5); do
        echo -e "\n  ${CYAN}$iface:${NC}"
        MAC=$(ip link show "$iface" 2>/dev/null | grep 'link/ether' | awk '{print $2}')
        [[ -n "$MAC" ]] && print_subitem "MAC" "$MAC"
        
        ip addr show "$iface" 2>/dev/null | grep 'inet ' | while read -r line; do
            print_subitem "IPv4" "$(echo "$line" | awk '{print $2}')"
        done
        
        if [[ -f "/sys/class/net/$iface/speed" ]]; then
            SPEED=$(cat "/sys/class/net/$iface/speed" 2>/dev/null)
            [[ -n "$SPEED" && "$SPEED" != "-1" ]] && print_subitem "Speed" "${SPEED} Mbps"
        fi
    done
    
    print_section "Routing"
    ip route 2>/dev/null | head -10
    
    print_section "DNS"
    grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | while read line; do
        echo "  $line"
    done
}

#-------------------------------------------------------------------------------
# Section: Network Connections
#-------------------------------------------------------------------------------

show_network_connections() {
    print_header "NETWORK CONNECTIONS"
    
    print_section "Listening Ports"
    if cmd_exists ss; then
        ss -tuln 2>/dev/null | grep LISTEN | head -20 | while read line; do
            echo "  $line"
        done
    fi
    
    print_section "Established Connections"
    if cmd_exists ss; then
        ESTABLISHED=$(ss -tun state established 2>/dev/null | wc -l)
        print_item "Total Established" "$ESTABLISHED"
    fi
}

#-------------------------------------------------------------------------------
# Section: Firewall
#-------------------------------------------------------------------------------

show_firewall_info() {
    print_header "FIREWALL STATUS"
    
    print_section "Firewall Tools"
    
    if cmd_exists ufw; then
        print_item "UFW Status" "$(ufw status 2>/dev/null | head -1)"
    fi
    
    if cmd_exists firewall-cmd; then
        print_item "Firewalld" "$(firewall-cmd --state 2>/dev/null || echo 'not running')"
    fi
    
    if cmd_exists iptables && [[ $EUID -eq 0 ]]; then
        RULES=$(iptables -L -n 2>/dev/null | grep -c "^Chain")
        print_item "IPTables Chains" "$RULES"
    fi
    
    if cmd_exists nft && [[ $EUID -eq 0 ]]; then
        TABLES=$(nft list tables 2>/dev/null | wc -l)
        print_item "NFTables Tables" "$TABLES"
    fi
}

#-------------------------------------------------------------------------------
# Section: WiFi & Bluetooth
#-------------------------------------------------------------------------------

show_wifi_bluetooth() {
    print_header "WIFI & BLUETOOTH"
    
    print_section "WiFi"
    if cmd_exists nmcli; then
        nmcli -t -f active,ssid,signal,security dev wifi list 2>/dev/null | grep "^yes" | while IFS=: read active ssid signal security; do
            print_item "Connected SSID" "$ssid"
            print_item "Signal Strength" "${signal}%"
            print_item "Security" "$security"
        done
    elif cmd_exists iwconfig; then
        iwconfig 2>/dev/null | grep -E "ESSID|Signal" | head -3
    fi
    
    print_section "Bluetooth"
    if cmd_exists bluetoothctl; then
        print_item "Bluetooth Power" "$(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')"
        
        PAIRED=$(bluetoothctl devices 2>/dev/null)
        if [[ -n "$PAIRED" ]]; then
            print_subsection "Paired Devices"
            echo "$PAIRED" | while read line; do
                echo "  $line"
            done
        fi
    else
        echo -e "  ${DIM}Bluetooth tools not available${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Section: Hardware DMI
#-------------------------------------------------------------------------------

show_hardware_dmi() {
    print_header "HARDWARE OVERVIEW (DMI/SMBIOS)"
    
    if [[ $EUID -eq 0 ]] && cmd_exists dmidecode; then
        print_section "System"
        print_item "Manufacturer" "$(dmidecode -s system-manufacturer 2>/dev/null)"
        print_item "Product Name" "$(dmidecode -s system-product-name 2>/dev/null)"
        print_item "Version" "$(dmidecode -s system-version 2>/dev/null)"
        print_item "Serial" "$(dmidecode -s system-serial-number 2>/dev/null)"
        
        print_section "BIOS"
        print_item "Vendor" "$(dmidecode -s bios-vendor 2>/dev/null)"
        print_item "Version" "$(dmidecode -s bios-version 2>/dev/null)"
        print_item "Release Date" "$(dmidecode -s bios-release-date 2>/dev/null)"
        
        print_section "Baseboard"
        print_item "Manufacturer" "$(dmidecode -s baseboard-manufacturer 2>/dev/null)"
        print_item "Product" "$(dmidecode -s baseboard-product-name 2>/dev/null)"
    else
        print_section "System (from /sys)"
        [[ -f /sys/class/dmi/id/sys_vendor ]] && print_item "Vendor" "$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)"
        [[ -f /sys/class/dmi/id/product_name ]] && print_item "Product" "$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
        [[ -f /sys/class/dmi/id/bios_vendor ]] && print_item "BIOS Vendor" "$(cat /sys/class/dmi/id/bios_vendor 2>/dev/null)"
        [[ -f /sys/class/dmi/id/bios_version ]] && print_item "BIOS Version" "$(cat /sys/class/dmi/id/bios_version 2>/dev/null)"
        
        echo -e "\n  ${DIM}Run as root for full hardware details${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Section: USB Devices
#-------------------------------------------------------------------------------

show_usb_devices() {
    print_header "USB DEVICES"
    
    print_section "Connected USB Devices"
    if cmd_exists lsusb; then
        lsusb 2>/dev/null | while read line; do
            echo "  $line"
        done
    else
        echo -e "  ${DIM}lsusb not available${NC}"
    fi
    
    print_section "USB Tree"
    if cmd_exists lsusb; then
        lsusb -t 2>/dev/null | head -20
    fi
}

#-------------------------------------------------------------------------------
# Section: PCI Devices
#-------------------------------------------------------------------------------

show_pci_devices() {
    print_header "PCI DEVICES"
    
    print_section "PCI Device List"
    if cmd_exists lspci; then
        lspci 2>/dev/null | head -30 | while read line; do
            echo "  $line"
        done
    else
        echo -e "  ${DIM}lspci not available${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Section: Audio
#-------------------------------------------------------------------------------

show_audio_info() {
    print_header "AUDIO INFORMATION"
    
    print_section "Sound Cards"
    if [[ -f /proc/asound/cards ]]; then
        cat /proc/asound/cards 2>/dev/null
    fi
    
    print_section "Audio Sinks (Output)"
    if cmd_exists pactl; then
        pactl list sinks short 2>/dev/null | while read line; do
            echo "  $line"
        done
    fi
    
    print_section "Audio Sources (Input)"
    if cmd_exists pactl; then
        pactl list sources short 2>/dev/null | while read line; do
            echo "  $line"
        done
    fi
}

#-------------------------------------------------------------------------------
# Section: Desktop Environment
#-------------------------------------------------------------------------------

show_desktop_env() {
    print_header "DESKTOP ENVIRONMENT"
    
    print_section "Current Session"
    print_item "Desktop" "${XDG_CURRENT_DESKTOP:-N/A}"
    print_item "Session" "${XDG_SESSION_DESKTOP:-N/A}"
    print_item "Session Type" "${XDG_SESSION_TYPE:-N/A}"
    print_item "Display" "${DISPLAY:-N/A}"
    print_item "Wayland" "${WAYLAND_DISPLAY:-N/A}"
    
    print_section "Theme Settings"
    if cmd_exists gsettings; then
        print_item "GTK Theme" "$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"
        print_item "Icon Theme" "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
        print_item "Cursor Theme" "$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")"
        print_item "Font" "$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'")"
    fi
}

#-------------------------------------------------------------------------------
# Section: Process Information
#-------------------------------------------------------------------------------

show_process_info() {
    print_header "PROCESS INFORMATION"
    
    print_section "Process Statistics"
    print_item "Total Processes" "$(ps aux 2>/dev/null | wc -l)"
    print_item "Running" "$(ps -eo state 2>/dev/null | grep -c R)"
    print_item "Sleeping" "$(ps -eo state 2>/dev/null | grep -c S)"
    print_item "Zombie" "$(ps -eo state 2>/dev/null | grep -c Z)"
    
    print_section "Top 10 CPU Consumers"
    echo -e "  ${DIM}USER       PID    CPU%   COMMAND${NC}"
    ps aux --sort=-%cpu 2>/dev/null | head -11 | tail -10 | awk '{printf "  %-10s %-6s %-6s %s\n", $1, $2, $3"%", $11}'
    
    print_section "Top 10 Memory Consumers"
    echo -e "  ${DIM}USER       PID    MEM%   COMMAND${NC}"
    ps aux --sort=-%mem 2>/dev/null | head -11 | tail -10 | awk '{printf "  %-10s %-6s %-6s %s\n", $1, $2, $4"%", $11}'
}

#-------------------------------------------------------------------------------
# Section: Systemd Services
#-------------------------------------------------------------------------------

show_systemd_services() {
    print_header "SYSTEMD SERVICES"
    
    if ! cmd_exists systemctl; then
        echo -e "  ${YELLOW}Systemd not available${NC}"
        return
    fi
    
    print_section "Service Statistics"
    print_item "Total Services" "$(systemctl list-unit-files --type=service --no-pager 2>/dev/null | grep -c '\.service')"
    print_item "Running" "$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c '\.service')"
    print_item "Failed" "$(systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | grep -c '\.service')"
    
    print_section "Failed Services"
    FAILED=$(systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | grep "\.service")
    if [[ -n "$FAILED" ]]; then
        echo "$FAILED" | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
    else
        echo -e "  ${GREEN}No failed services${NC}"
    fi
    
    print_section "Boot Time"
    if cmd_exists systemd-analyze; then
        systemd-analyze 2>/dev/null | head -3 | while read line; do
            echo "  $line"
        done
    fi
}

#-------------------------------------------------------------------------------
# Section: Users & Security
#-------------------------------------------------------------------------------

show_users_security() {
    print_header "USERS & SECURITY"
    
    print_section "Current User"
    print_item "Username" "$USER"
    print_item "UID" "$UID"
    print_item "Groups" "$(groups)"
    print_item "Home" "$HOME"
    print_item "Shell" "$SHELL"
    
    print_section "Human Users"
    awk -F: '$3 >= 1000 && $3 < 65534 {print "  " $1 " (UID: " $3 ")"}' /etc/passwd 2>/dev/null
    
    print_section "Currently Logged In"
    who 2>/dev/null | while read line; do
        echo "  $line"
    done
    
    print_section "SSH Configuration"
    if [[ -f /etc/ssh/sshd_config ]]; then
        print_item "PermitRootLogin" "$(grep -E '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo 'default')"
        print_item "PasswordAuth" "$(grep -E '^PasswordAuthentication' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo 'default')"
    fi
}

#-------------------------------------------------------------------------------
# Section: Virtualization
#-------------------------------------------------------------------------------

show_virtualization() {
    print_header "VIRTUALIZATION / CONTAINERS"
    
    print_section "Environment Detection"
    
    VIRT_TYPE="None/Bare Metal"
    if cmd_exists systemd-detect-virt; then
        DETECTED=$(systemd-detect-virt 2>/dev/null)
        [[ -n "$DETECTED" && "$DETECTED" != "none" ]] && VIRT_TYPE="$DETECTED"
    fi
    
    grep -q hypervisor /proc/cpuinfo 2>/dev/null && [[ "$VIRT_TYPE" == "None/Bare Metal" ]] && VIRT_TYPE="Unknown Hypervisor"
    
    print_item "Virtualization" "$VIRT_TYPE"
    
    # Container
    CONTAINER="None"
    [[ -f /.dockerenv ]] && CONTAINER="Docker"
    [[ -f /run/.containerenv ]] && CONTAINER="Podman"
    grep -q 'docker' /proc/1/cgroup 2>/dev/null && CONTAINER="Docker"
    [[ -n "$KUBERNETES_SERVICE_HOST" ]] && CONTAINER="Kubernetes Pod"
    
    print_item "Container" "$CONTAINER"
    
    print_section "Docker"
    if cmd_exists docker; then
        if docker info &>/dev/null; then
            print_item "Docker Version" "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
            print_item "Containers" "$(docker ps -a 2>/dev/null | tail -n +2 | wc -l)"
            print_item "Running" "$(docker ps 2>/dev/null | tail -n +2 | wc -l)"
            print_item "Images" "$(docker images 2>/dev/null | tail -n +2 | wc -l)"
        else
            print_item "Docker" "Installed but not accessible"
        fi
    fi
    
    print_section "Podman"
    if cmd_exists podman; then
        print_item "Podman Version" "$(podman --version 2>/dev/null | awk '{print $3}')"
    fi
}

#-------------------------------------------------------------------------------
# Section: Boot Information
#-------------------------------------------------------------------------------

show_boot_info() {
    print_header "BOOT INFORMATION"
    
    print_section "Boot Mode"
    if [[ -d /sys/firmware/efi ]]; then
        print_item "Boot Mode" "UEFI"
        print_item "Secure Boot" "$(mokutil --sb-state 2>/dev/null | head -1 || echo 'Unknown')"
    else
        print_item "Boot Mode" "Legacy BIOS"
    fi
    
    print_section "GRUB"
    if [[ -f /etc/default/grub ]]; then
        print_item "GRUB Config" "Present"
        print_item "Timeout" "$(grep GRUB_TIMEOUT /etc/default/grub 2>/dev/null | cut -d= -f2)"
    fi
    
    print_section "Recent Kernel Messages"
    dmesg 2>/dev/null | tail -10 | while read line; do
        echo "  ${line:0:75}"
    done
}

#-------------------------------------------------------------------------------
# Section: Battery
#-------------------------------------------------------------------------------

show_battery_info() {
    print_header "BATTERY INFORMATION"
    
    if [[ ! -d /sys/class/power_supply/BAT0 && ! -d /sys/class/power_supply/BAT1 ]]; then
        echo -e "\n  ${YELLOW}No battery detected (desktop or no battery)${NC}"
        return
    fi
    
    for bat in /sys/class/power_supply/BAT*; do
        if [[ -d "$bat" ]]; then
            BAT_NAME=$(basename "$bat")
            print_section "$BAT_NAME"
            
            [[ -f "$bat/status" ]] && print_item "Status" "$(cat "$bat/status" 2>/dev/null)"
            [[ -f "$bat/capacity" ]] && print_item "Capacity" "$(cat "$bat/capacity" 2>/dev/null)%"
            [[ -f "$bat/manufacturer" ]] && print_item "Manufacturer" "$(cat "$bat/manufacturer" 2>/dev/null)"
            [[ -f "$bat/model_name" ]] && print_item "Model" "$(cat "$bat/model_name" 2>/dev/null)"
            [[ -f "$bat/technology" ]] && print_item "Technology" "$(cat "$bat/technology" 2>/dev/null)"
            [[ -f "$bat/cycle_count" ]] && print_item "Cycle Count" "$(cat "$bat/cycle_count" 2>/dev/null)"
            
            if [[ -f "$bat/charge_full" && -f "$bat/charge_full_design" ]]; then
                FULL=$(cat "$bat/charge_full" 2>/dev/null)
                DESIGN=$(cat "$bat/charge_full_design" 2>/dev/null)
                if [[ -n "$FULL" && -n "$DESIGN" && "$DESIGN" -gt 0 ]]; then
                    HEALTH=$(echo "scale=1; $FULL * 100 / $DESIGN" | bc 2>/dev/null)
                    print_item "Battery Health" "${HEALTH}%"
                fi
            fi
        fi
    done
}

#-------------------------------------------------------------------------------
# Section: Sensors
#-------------------------------------------------------------------------------

show_sensors_thermal() {
    print_header "SENSORS & THERMAL"
    
    if cmd_exists sensors; then
        print_section "Hardware Sensors"
        sensors 2>/dev/null | head -30
    else
        print_section "Thermal Zones"
        for zone in /sys/class/thermal/thermal_zone*; do
            if [[ -d "$zone" ]]; then
                TYPE=$(cat "$zone/type" 2>/dev/null)
                TEMP=$(cat "$zone/temp" 2>/dev/null)
                if [[ -n "$TEMP" ]]; then
                    TEMP_C=$(echo "scale=1; $TEMP/1000" | bc 2>/dev/null)
                    print_item "$TYPE" "${TEMP_C}°C"
                fi
            fi
        done
        
        echo -e "\n  ${DIM}Install lm-sensors for detailed info: sudo apt install lm-sensors${NC}"
    fi
    
    print_section "Fan Information"
    for hwmon in /sys/class/hwmon/hwmon*; do
        for fan in "$hwmon"/fan*_input; do
            if [[ -f "$fan" ]]; then
                SPEED=$(cat "$fan" 2>/dev/null)
                [[ -n "$SPEED" && "$SPEED" != "0" ]] && print_item "$(basename ${fan%_input})" "${SPEED} RPM"
            fi
        done
    done 2>/dev/null
}

#-------------------------------------------------------------------------------
# Show All Sections
#-------------------------------------------------------------------------------

show_all_sections() {
    show_os_info; echo ""
    show_kernel_info; echo ""
    show_cpu_info; echo ""
    show_memory_info; echo ""
    show_storage_info; echo ""
    show_gpu_info; echo ""
    show_network_info; echo ""
    show_network_connections; echo ""
    show_firewall_info; echo ""
    show_wifi_bluetooth; echo ""
    show_hardware_dmi; echo ""
    show_usb_devices; echo ""
    show_pci_devices; echo ""
    show_audio_info; echo ""
    show_desktop_env; echo ""
    show_process_info; echo ""
    show_systemd_services; echo ""
    show_users_security; echo ""
    show_virtualization; echo ""
    show_boot_info; echo ""
    show_battery_info; echo ""
    show_sensors_thermal
    
    print_header "REPORT COMPLETE"
    echo -e "\n  ${GREEN}Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
}

#-------------------------------------------------------------------------------
# Save Report
#-------------------------------------------------------------------------------

save_report() {
    clear_screen
    print_header "SAVE REPORT"
    
    echo ""
    echo -ne "  ${WHITE}Enter filename (Enter for default): ${NC}"
    read -r filename
    
    [[ -z "$filename" ]] && filename="system-info-$(date '+%Y%m%d-%H%M%S').txt"
    [[ "$filename" != *.txt ]] && filename="${filename}.txt"
    
    echo -e "  ${YELLOW}Generating report...${NC}"
    
    {
        echo "LINUX SYSTEM INFORMATION REPORT"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "========================================"
        
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' WHITE='' NC='' BOLD='' DIM=''
        show_all_sections
    } > "$filename" 2>&1
    
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
    CYAN='\033[0;36m' MAGENTA='\033[0;35m' WHITE='\033[1;37m' NC='\033[0m'
    BOLD='\033[1m' DIM='\033[2m'
    
    echo -e "  ${GREEN}✓ Report saved to: ${WHITE}$filename${NC}"
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

show_main_menu
