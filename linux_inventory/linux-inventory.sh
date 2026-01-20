#!/bin/bash

#===============================================================================
# LINUX SOFTWARE INVENTORY - TERMINAL UI
# Interactive terminal application for system inventory
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
REVERSE='\033[7m'

# Get terminal size
TERM_COLS=$(tput cols 2>/dev/null || echo 80)
TERM_ROWS=$(tput lines 2>/dev/null || echo 24)

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

clear_screen() {
    clear
}

print_center() {
    local text="$1"
    local width=${2:-$TERM_COLS}
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

print_line() {
    local char="${1:-─}"
    local width=${2:-$TERM_COLS}
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

print_box_top() {
    local width=${1:-$TERM_COLS}
    echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((width-2))))╗${NC}"
}

print_box_bottom() {
    local width=${1:-$TERM_COLS}
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((width-2))))╝${NC}"
}

print_box_line() {
    local text="$1"
    local width=${2:-$TERM_COLS}
    local inner_width=$((width - 4))
    printf "${CYAN}║${NC} %-${inner_width}s ${CYAN}║${NC}\n" "$text"
}

print_box_center() {
    local text="$1"
    local width=${2:-$TERM_COLS}
    local inner_width=$((width - 4))
    local padding=$(( (inner_width - ${#text}) / 2 ))
    printf "${CYAN}║${NC}%*s%s%*s${CYAN}║${NC}\n" $((padding + 1)) "" "$text" $((inner_width - padding - ${#text} + 1)) ""
}

print_box_empty() {
    local width=${1:-$TERM_COLS}
    local inner_width=$((width - 4))
    printf "${CYAN}║${NC} %*s ${CYAN}║${NC}\n" $inner_width ""
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    printf "${BOLD}${BLUE}┃${NC}  ${WHITE}%-72s${NC}${BOLD}${BLUE}┃${NC}\n" "$title"
    echo -e "${BOLD}${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

print_subsection() {
    echo ""
    echo -e "${YELLOW}--- $1 ---${NC}"
}

print_item() {
    printf "  ${GREEN}%-35s${NC} : %s\n" "$1" "$2"
}

print_subitem() {
    printf "    ${DIM}%-33s${NC} : %s\n" "$1" "$2"
}

print_count() {
    printf "  ${CYAN}%-35s${NC} : ${WHITE}%s${NC}\n" "$1" "$2"
}

bytes_to_human() {
    local bytes=$1
    if [[ $bytes -ge 1073741824 ]]; then
        awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}"
    elif [[ $bytes -ge 1048576 ]]; then
        awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}"
    elif [[ $bytes -ge 1024 ]]; then
        awk "BEGIN {printf \"%.2f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s -r
}

wait_for_menu() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}[R]${NC} Rerun this section    ${WHITE}[M]${NC} Main Menu    ${WHITE}[Q]${NC} Quit"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    while true; do
        read -n 1 -s -r key
        case $key in
            r|R) return 0 ;;  # Rerun
            m|M) return 1 ;;  # Menu
            q|Q) exit 0 ;;    # Quit
        esac
    done
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_main_menu() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${MAGENTA}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║              ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗                        ║"
        echo "║              ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝                        ║"
        echo "║              ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝                         ║"
        echo "║              ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗                         ║"
        echo "║              ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗                        ║"
        echo "║              ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝                        ║"
        echo "║                                                                            ║"
        echo "║                    SOFTWARE INVENTORY TOOL                                 ║"
        echo "║                                                                            ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${WHITE}  Select a category to view:${NC}"
        echo ""
        echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Operating System Information${NC}                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Kernel Information${NC}                                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Package Managers${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Installed Packages${NC} (System)                                        ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Snap Packages${NC}                                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Flatpak Packages${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}GUI Applications${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Systemd Services${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Desktop Environment & Themes${NC}                                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}10.${NC} ${GREEN}Startup Applications${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}11.${NC} ${GREEN}Inventory Summary${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} A.${NC} ${YELLOW}Run ALL Sections${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${YELLOW}Save Full Report to File${NC}                                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) run_section "os_info" ;;
            2) run_section "kernel_info" ;;
            3) run_section "package_managers" ;;
            4) run_section "installed_packages" ;;
            5) run_section "snap_packages" ;;
            6) run_section "flatpak_packages" ;;
            7) run_section "gui_applications" ;;
            8) run_section "systemd_services" ;;
            9) run_section "desktop_themes" ;;
            10) run_section "startup_apps" ;;
            11) run_section "summary" ;;
            a|A) run_section "all" ;;
            s|S) save_report ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Linux Software Inventory Tool!${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}Invalid option. Press any key to continue...${NC}"
                read -n 1 -s -r
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
            package_managers) show_package_managers ;;
            installed_packages) show_installed_packages ;;
            snap_packages) show_snap_packages ;;
            flatpak_packages) show_flatpak_packages ;;
            gui_applications) show_gui_applications ;;
            systemd_services) show_systemd_services ;;
            desktop_themes) show_desktop_themes ;;
            startup_apps) show_startup_apps ;;
            summary) show_summary ;;
            all) show_all_sections ;;
        esac
        
        wait_for_menu
        local result=$?
        
        if [[ $result -eq 1 ]]; then
            return  # Go back to menu
        fi
        # Otherwise, loop continues (rerun)
    done
}

#-------------------------------------------------------------------------------
# Section: Operating System Information
#-------------------------------------------------------------------------------

show_os_info() {
    print_header "OPERATING SYSTEM INFORMATION"
    
    print_section "Distribution Details"
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release 2>/dev/null
        print_item "Distribution Name" "${NAME:-N/A}"
        print_item "Distribution ID" "${ID:-N/A}"
        print_item "ID Like" "${ID_LIKE:-N/A}"
        print_item "Version" "${VERSION:-N/A}"
        print_item "Version ID" "${VERSION_ID:-N/A}"
        print_item "Version Codename" "${VERSION_CODENAME:-N/A}"
        print_item "Pretty Name" "${PRETTY_NAME:-N/A}"
        print_item "Home URL" "${HOME_URL:-N/A}"
    fi
    
    if cmd_exists lsb_release; then
        print_section "LSB Information"
        print_item "Distributor ID" "$(lsb_release -i 2>/dev/null | cut -f2)"
        print_item "Description" "$(lsb_release -d 2>/dev/null | cut -f2)"
        print_item "Release" "$(lsb_release -r 2>/dev/null | cut -f2)"
        print_item "Codename" "$(lsb_release -c 2>/dev/null | cut -f2)"
    fi
    
    print_section "System Details"
    print_item "Hostname" "$(hostname)"
    print_item "Hostname FQDN" "$(hostname -f 2>/dev/null || echo 'N/A')"
    print_item "Machine ID" "$(cat /etc/machine-id 2>/dev/null || echo 'N/A')"
    print_item "Architecture" "$(uname -m)"
    print_item "Architecture Bits" "$(getconf LONG_BIT)-bit"
    print_item "Uptime" "$(uptime -p 2>/dev/null || uptime)"
    print_item "Current Date/Time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    print_item "Timezone" "$(timedatectl 2>/dev/null | grep 'Time zone' | awk '{print $3}' || cat /etc/timezone 2>/dev/null || echo 'N/A')"
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
    print_item "Kernel Type" "$(uname -o)"
    
    print_section "Kernel Modules"
    MODULE_COUNT=$(lsmod 2>/dev/null | tail -n +2 | wc -l)
    print_count "Total Loaded Modules" "$MODULE_COUNT"
    
    print_subsection "Top 15 Largest Modules (by size)"
    echo -e "  ${DIM}Module Name                    Size         Used by${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
    lsmod 2>/dev/null | tail -n +2 | sort -k2 -rn | head -15 | awk '{printf "  %-28s %10s    %s\n", $1, $2, $4}'
    
    print_section "Key Kernel Parameters"
    if cmd_exists sysctl; then
        print_item "vm.swappiness" "$(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')"
        print_item "vm.dirty_ratio" "$(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'N/A')"
        print_item "kernel.pid_max" "$(sysctl -n kernel.pid_max 2>/dev/null || echo 'N/A')"
        print_item "fs.file-max" "$(sysctl -n fs.file-max 2>/dev/null || echo 'N/A')"
        print_item "net.ipv4.ip_forward" "$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'N/A')"
    fi
}

#-------------------------------------------------------------------------------
# Section: Package Managers
#-------------------------------------------------------------------------------

show_package_managers() {
    print_header "PACKAGE MANAGERS"
    
    print_section "System Package Managers"
    
    # APT
    if cmd_exists apt; then
        APT_COUNT=$(dpkg -l 2>/dev/null | grep -c "^ii" || echo "0")
        APT_VERSION=$(apt --version 2>/dev/null | head -1 | awk '{print $2}')
        print_item "APT" "v${APT_VERSION} (${APT_COUNT} packages)"
        print_subitem "Config" "/etc/apt/sources.list"
    fi
    
    # DPKG
    if cmd_exists dpkg; then
        DPKG_VERSION=$(dpkg --version 2>/dev/null | head -1 | awk '{print $NF}')
        print_item "DPKG" "v${DPKG_VERSION}"
    fi
    
    # DNF
    if cmd_exists dnf; then
        DNF_COUNT=$(dnf list installed 2>/dev/null | tail -n +2 | wc -l)
        DNF_VERSION=$(dnf --version 2>/dev/null | head -1)
        print_item "DNF" "v${DNF_VERSION} (${DNF_COUNT} packages)"
    fi
    
    # RPM
    if cmd_exists rpm; then
        RPM_COUNT=$(rpm -qa 2>/dev/null | wc -l)
        RPM_VERSION=$(rpm --version 2>/dev/null | awk '{print $NF}')
        print_item "RPM" "v${RPM_VERSION} (${RPM_COUNT} packages)"
    fi
    
    # Pacman
    if cmd_exists pacman; then
        PACMAN_COUNT=$(pacman -Q 2>/dev/null | wc -l)
        PACMAN_VERSION=$(pacman --version 2>/dev/null | head -1 | grep -oP 'v[\d.]+')
        print_item "Pacman" "${PACMAN_VERSION} (${PACMAN_COUNT} packages)"
    fi
    
    # Zypper
    if cmd_exists zypper; then
        ZYPPER_VERSION=$(zypper --version 2>/dev/null | awk '{print $2}')
        print_item "Zypper" "v${ZYPPER_VERSION}"
    fi
    
    print_section "Universal Package Managers"
    
    # Snap
    if cmd_exists snap; then
        SNAP_COUNT=$(snap list 2>/dev/null | tail -n +2 | wc -l)
        SNAP_VERSION=$(snap version 2>/dev/null | grep "^snap " | awk '{print $2}')
        print_item "Snap" "v${SNAP_VERSION} (${SNAP_COUNT} snaps)"
        if [[ -d /var/lib/snapd/snaps ]]; then
            SNAP_SIZE=$(du -sh /var/lib/snapd/snaps 2>/dev/null | cut -f1)
            print_subitem "Total Snap Size" "$SNAP_SIZE"
        fi
    else
        print_item "Snap" "Not installed"
    fi
    
    # Flatpak
    if cmd_exists flatpak; then
        FLATPAK_APPS=$(flatpak list --app 2>/dev/null | wc -l)
        FLATPAK_RUNTIMES=$(flatpak list --runtime 2>/dev/null | wc -l)
        FLATPAK_VERSION=$(flatpak --version 2>/dev/null | awk '{print $2}')
        print_item "Flatpak" "v${FLATPAK_VERSION} (${FLATPAK_APPS} apps, ${FLATPAK_RUNTIMES} runtimes)"
        if [[ -d /var/lib/flatpak ]]; then
            FLATPAK_SIZE=$(du -sh /var/lib/flatpak 2>/dev/null | cut -f1)
            print_subitem "Total Flatpak Size" "$FLATPAK_SIZE"
        fi
    else
        print_item "Flatpak" "Not installed"
    fi
    
    print_section "Language Package Managers"
    
    # pip
    if cmd_exists pip3; then
        PIP3_COUNT=$(pip3 list 2>/dev/null | tail -n +3 | wc -l)
        PIP3_VERSION=$(pip3 --version 2>/dev/null | awk '{print $2}')
        print_item "pip3 (Python)" "v${PIP3_VERSION} (${PIP3_COUNT} packages)"
    fi
    
    # npm
    if cmd_exists npm; then
        NPM_GLOBAL=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l)
        NPM_VERSION=$(npm --version 2>/dev/null)
        print_item "npm (Node.js)" "v${NPM_VERSION} (${NPM_GLOBAL} global packages)"
    fi
    
    # cargo
    if cmd_exists cargo; then
        CARGO_VERSION=$(cargo --version 2>/dev/null | awk '{print $2}')
        print_item "Cargo (Rust)" "v${CARGO_VERSION}"
    fi
    
    # gem
    if cmd_exists gem; then
        GEM_COUNT=$(gem list 2>/dev/null | wc -l)
        GEM_VERSION=$(gem --version 2>/dev/null)
        print_item "RubyGems" "v${GEM_VERSION} (${GEM_COUNT} gems)"
    fi
}

#-------------------------------------------------------------------------------
# Section: Installed Packages
#-------------------------------------------------------------------------------

show_installed_packages() {
    print_header "INSTALLED PACKAGES"
    
    if cmd_exists dpkg; then
        print_section "APT/DPKG Packages (Debian-based)"
        
        TOTAL_PACKAGES=$(dpkg -l 2>/dev/null | grep -c "^ii")
        TOTAL_SIZE=$(dpkg-query -W -f='${Installed-Size}\n' 2>/dev/null | awk '{sum+=$1} END {print sum}')
        TOTAL_SIZE_HR=$(bytes_to_human $((TOTAL_SIZE * 1024)))
        
        print_count "Total Installed Packages" "$TOTAL_PACKAGES"
        print_count "Total Installed Size" "$TOTAL_SIZE_HR"
        
        print_subsection "Top 30 Largest Packages"
        echo -e "  ${DIM}Package Name                                      Size        Description${NC}"
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────────${NC}"
        dpkg-query -W -f='${Installed-Size}\t${Package}\t${binary:Summary}\n' 2>/dev/null | sort -rn | head -30 | while read size pkg desc; do
            size_mb=$(echo "scale=2; $size/1024" | bc 2>/dev/null || echo "$size")
            printf "  %-46s %8s MB  %.35s\n" "${pkg:0:46}" "$size_mb" "${desc:0:35}"
        done
        
        print_subsection "Packages by Section (Top 15)"
        dpkg-query -W -f='${Section}\n' 2>/dev/null | sort | uniq -c | sort -rn | head -15 | while read count section; do
            printf "  %-40s %s packages\n" "$section" "$count"
        done
        
    elif cmd_exists rpm; then
        print_section "RPM Packages (Red Hat-based)"
        
        TOTAL_PACKAGES=$(rpm -qa 2>/dev/null | wc -l)
        print_count "Total Installed Packages" "$TOTAL_PACKAGES"
        
        print_subsection "Top 30 Largest Packages"
        rpm -qa --queryformat '%{SIZE}\t%{NAME}\t%{SUMMARY}\n' 2>/dev/null | sort -rn | head -30 | while read size pkg desc; do
            size_mb=$(echo "scale=2; $size/1048576" | bc 2>/dev/null || echo "$size")
            printf "  %-46s %8s MB  %.35s\n" "${pkg:0:46}" "$size_mb" "${desc:0:35}"
        done
        
    elif cmd_exists pacman; then
        print_section "Pacman Packages (Arch-based)"
        
        TOTAL_PACKAGES=$(pacman -Q 2>/dev/null | wc -l)
        print_count "Total Installed Packages" "$TOTAL_PACKAGES"
        
        print_subsection "Top 30 Largest Packages"
        pacman -Qi 2>/dev/null | awk '/^Name/{name=$3} /^Installed Size/{print $4, $5, name}' | sort -rn | head -30 | while read size unit pkg; do
            printf "  %-48s %8s %s\n" "$pkg" "$size" "$unit"
        done
        
        EXPLICIT=$(pacman -Qe 2>/dev/null | wc -l)
        AUR=$(pacman -Qm 2>/dev/null | wc -l)
        print_count "Explicitly Installed" "$EXPLICIT"
        print_count "AUR/Foreign Packages" "$AUR"
    fi
}

#-------------------------------------------------------------------------------
# Section: Snap Packages
#-------------------------------------------------------------------------------

show_snap_packages() {
    print_header "SNAP PACKAGES"
    
    if ! cmd_exists snap; then
        echo -e "\n  ${YELLOW}Snap is not installed on this system.${NC}"
        return
    fi
    
    SNAP_COUNT=$(snap list 2>/dev/null | tail -n +2 | wc -l)
    print_count "Total Snap Packages" "$SNAP_COUNT"
    
    if [[ $SNAP_COUNT -eq 0 ]]; then
        echo -e "\n  ${DIM}No snap packages installed.${NC}"
        return
    fi
    
    print_section "Installed Snaps"
    echo -e "  ${DIM}Name                           Version                    Rev    Notes${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    snap list 2>/dev/null | tail -n +2 | while read name version rev tracking publisher notes; do
        printf "  %-30s %-26s %-6s %s\n" "$name" "${version:0:26}" "$rev" "$notes"
    done
    
    print_section "Snap Disk Usage"
    if [[ -d /var/lib/snapd/snaps ]]; then
        SNAP_SIZE=$(du -sh /var/lib/snapd/snaps 2>/dev/null | cut -f1)
        print_item "Total Size" "$SNAP_SIZE"
    fi
    
    print_section "Snap Services"
    SNAP_SERVICES=$(snap services 2>/dev/null | tail -n +2)
    if [[ -n "$SNAP_SERVICES" ]]; then
        echo "$SNAP_SERVICES" | while read line; do
            echo "  $line"
        done
    else
        echo -e "  ${DIM}No snap services running.${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Section: Flatpak Packages
#-------------------------------------------------------------------------------

show_flatpak_packages() {
    print_header "FLATPAK PACKAGES"
    
    if ! cmd_exists flatpak; then
        echo -e "\n  ${YELLOW}Flatpak is not installed on this system.${NC}"
        return
    fi
    
    print_section "Installed Applications"
    FLATPAK_APP_COUNT=$(flatpak list --app 2>/dev/null | wc -l)
    print_count "Total Applications" "$FLATPAK_APP_COUNT"
    
    if [[ $FLATPAK_APP_COUNT -gt 0 ]]; then
        echo -e "\n  ${DIM}Application                                      Version          Origin${NC}"
        echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
        
        flatpak list --app --columns=name,version,origin 2>/dev/null | while IFS=$'\t' read name version origin; do
            printf "  %-48s %-16s %s\n" "${name:0:48}" "${version:0:16}" "$origin"
        done
    fi
    
    print_section "Installed Runtimes"
    FLATPAK_RUNTIME_COUNT=$(flatpak list --runtime 2>/dev/null | wc -l)
    print_count "Total Runtimes" "$FLATPAK_RUNTIME_COUNT"
    
    print_section "Configured Remotes"
    flatpak remotes --columns=name,url 2>/dev/null | while read name url; do
        print_item "$name" "$url"
    done
    
    print_section "Disk Usage"
    if [[ -d /var/lib/flatpak ]]; then
        FLATPAK_SIZE=$(du -sh /var/lib/flatpak 2>/dev/null | cut -f1)
        print_item "Total Size" "$FLATPAK_SIZE"
    fi
}

#-------------------------------------------------------------------------------
# Section: GUI Applications
#-------------------------------------------------------------------------------

show_gui_applications() {
    print_header "GUI APPLICATIONS"
    
    print_section "Application Counts"
    
    SYSTEM_APPS=0
    USER_APPS=0
    FLATPAK_DESKTOP=0
    SNAP_DESKTOP=0
    
    [[ -d /usr/share/applications ]] && SYSTEM_APPS=$(ls -1 /usr/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d ~/.local/share/applications ]] && USER_APPS=$(ls -1 ~/.local/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d /var/lib/flatpak/exports/share/applications ]] && FLATPAK_DESKTOP=$(ls -1 /var/lib/flatpak/exports/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d /var/lib/snapd/desktop/applications ]] && SNAP_DESKTOP=$(ls -1 /var/lib/snapd/desktop/applications/*.desktop 2>/dev/null | wc -l)
    
    TOTAL_APPS=$((SYSTEM_APPS + USER_APPS + FLATPAK_DESKTOP + SNAP_DESKTOP))
    
    print_count "System Applications" "$SYSTEM_APPS"
    print_count "User Applications" "$USER_APPS"
    print_count "Flatpak Applications" "$FLATPAK_DESKTOP"
    print_count "Snap Applications" "$SNAP_DESKTOP"
    echo ""
    print_count "TOTAL GUI Applications" "$TOTAL_APPS"
    
    print_section "Application Categories"
    for dir in /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications; do
        if [[ -d "$dir" ]]; then
            grep -h "^Categories=" "$dir"/*.desktop 2>/dev/null
        fi
    done | cut -d= -f2 | tr ';' '\n' | grep -v "^$" | sort | uniq -c | sort -rn | head -15 | while read count cat; do
        printf "  %-35s %s apps\n" "$cat" "$count"
    done
    
    print_section "Sample Applications (System)"
    ls /usr/share/applications/*.desktop 2>/dev/null | head -20 | while read desktop; do
        NAME=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d= -f2)
        if [[ -n "$NAME" ]]; then
            printf "  %s\n" "$NAME"
        fi
    done
}

#-------------------------------------------------------------------------------
# Section: Systemd Services
#-------------------------------------------------------------------------------

show_systemd_services() {
    print_header "SYSTEMD SERVICES"
    
    if ! cmd_exists systemctl; then
        echo -e "\n  ${YELLOW}Systemd is not available on this system.${NC}"
        return
    fi
    
    print_section "Service Statistics"
    
    TOTAL_SERVICES=$(systemctl list-unit-files --type=service --no-pager 2>/dev/null | grep -c "\.service")
    ENABLED_SERVICES=$(systemctl list-unit-files --type=service --state=enabled --no-pager 2>/dev/null | grep -c "\.service")
    DISABLED_SERVICES=$(systemctl list-unit-files --type=service --state=disabled --no-pager 2>/dev/null | grep -c "\.service")
    RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c "\.service")
    FAILED_SERVICES=$(systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | grep -c "\.service")
    
    print_count "Total Service Units" "$TOTAL_SERVICES"
    print_count "Enabled Services" "$ENABLED_SERVICES"
    print_count "Disabled Services" "$DISABLED_SERVICES"
    print_count "Running Services" "$RUNNING_SERVICES"
    
    if [[ $FAILED_SERVICES -gt 0 ]]; then
        echo -e "  ${RED}Failed Services              : $FAILED_SERVICES${NC}"
    else
        print_count "Failed Services" "$FAILED_SERVICES"
    fi
    
    print_section "Running Services"
    echo -e "  ${DIM}Service Name                                      Sub State${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────${NC}"
    systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep "\.service" | head -25 | while read unit load active sub desc; do
        SERVICE=$(echo "$unit" | sed 's/\.service$//')
        printf "  %-48s %s\n" "${SERVICE:0:48}" "$sub"
    done
    
    if [[ $FAILED_SERVICES -gt 0 ]]; then
        print_section "Failed Services"
        systemctl list-units --type=service --state=failed --no-pager 2>/dev/null | grep "\.service" | while read unit load active sub desc; do
            SERVICE=$(echo "$unit" | sed 's/\.service$//')
            echo -e "  ${RED}$SERVICE${NC}"
        done
    fi
    
    print_section "Systemd Timers"
    TIMER_COUNT=$(systemctl list-timers --no-pager 2>/dev/null | grep -c "\.timer")
    print_count "Active Timers" "$TIMER_COUNT"
    
    print_section "Boot Analysis"
    if cmd_exists systemd-analyze; then
        systemd-analyze 2>/dev/null | head -3 | while read line; do
            echo "  $line"
        done
    fi
}

#-------------------------------------------------------------------------------
# Section: Desktop Environment & Themes
#-------------------------------------------------------------------------------

show_desktop_themes() {
    print_header "DESKTOP ENVIRONMENT & THEMES"
    
    print_section "Current Desktop Environment"
    print_item "XDG_CURRENT_DESKTOP" "${XDG_CURRENT_DESKTOP:-N/A}"
    print_item "XDG_SESSION_DESKTOP" "${XDG_SESSION_DESKTOP:-N/A}"
    print_item "XDG_SESSION_TYPE" "${XDG_SESSION_TYPE:-N/A}"
    print_item "DISPLAY" "${DISPLAY:-N/A}"
    print_item "WAYLAND_DISPLAY" "${WAYLAND_DISPLAY:-N/A}"
    
    print_section "Display Managers"
    DM_LIST=("gdm" "gdm3" "sddm" "lightdm" "lxdm")
    for dm in "${DM_LIST[@]}"; do
        if systemctl is-active "$dm" 2>/dev/null | grep -q "active"; then
            print_item "$dm" "active"
        elif systemctl is-enabled "$dm" 2>/dev/null | grep -q "enabled"; then
            print_item "$dm" "enabled (not active)"
        fi
    done
    
    print_section "Current Theme Settings"
    if cmd_exists gsettings; then
        print_item "GTK Theme" "$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo 'N/A')"
        print_item "Icon Theme" "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo 'N/A')"
        print_item "Cursor Theme" "$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || echo 'N/A')"
        print_item "Font" "$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'" || echo 'N/A')"
        print_item "Color Scheme" "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || echo 'N/A')"
    fi
    
    print_section "Installed Themes"
    
    # GTK Themes
    THEME_COUNT=0
    for dir in /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes"; do
        if [[ -d "$dir" ]]; then
            for theme in "$dir"/*/; do
                if [[ -d "${theme}gtk-3.0" ]] || [[ -d "${theme}gtk-4.0" ]]; then
                    ((THEME_COUNT++))
                fi
            done
        fi
    done
    print_count "GTK Themes" "$THEME_COUNT"
    
    # Icon Themes
    ICON_COUNT=0
    for dir in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
        if [[ -d "$dir" ]]; then
            for icon in "$dir"/*/; do
                if [[ -f "${icon}index.theme" ]]; then
                    ((ICON_COUNT++))
                fi
            done
        fi
    done
    print_count "Icon Themes" "$ICON_COUNT"
    
    # Cursor Themes
    CURSOR_COUNT=0
    for dir in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
        if [[ -d "$dir" ]]; then
            for cursor in "$dir"/*/; do
                if [[ -d "${cursor}cursors" ]]; then
                    ((CURSOR_COUNT++))
                fi
            done
        fi
    done
    print_count "Cursor Themes" "$CURSOR_COUNT"
    
    # Fonts
    print_section "Fonts"
    if cmd_exists fc-list; then
        FONT_FAMILIES=$(fc-list : family 2>/dev/null | sort -u | wc -l)
        print_count "Font Families" "$FONT_FAMILIES"
    fi
}

#-------------------------------------------------------------------------------
# Section: Startup Applications
#-------------------------------------------------------------------------------

show_startup_apps() {
    print_header "STARTUP APPLICATIONS"
    
    print_section "System Autostart (/etc/xdg/autostart)"
    if [[ -d /etc/xdg/autostart ]]; then
        SYSTEM_AUTOSTART=$(ls -1 /etc/xdg/autostart/*.desktop 2>/dev/null | wc -l)
        print_count "System Autostart Entries" "$SYSTEM_AUTOSTART"
        
        echo ""
        ls /etc/xdg/autostart/*.desktop 2>/dev/null | while read desktop; do
            NAME=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d= -f2)
            HIDDEN=$(grep "^Hidden=" "$desktop" 2>/dev/null | cut -d= -f2)
            if [[ "$HIDDEN" != "true" ]] && [[ -n "$NAME" ]]; then
                printf "  %-50s ${DIM}(system)${NC}\n" "$NAME"
            fi
        done | head -20
    else
        echo -e "  ${DIM}No system autostart directory found.${NC}"
    fi
    
    print_section "User Autostart (~/.config/autostart)"
    if [[ -d ~/.config/autostart ]]; then
        USER_AUTOSTART=$(ls -1 ~/.config/autostart/*.desktop 2>/dev/null | wc -l)
        print_count "User Autostart Entries" "$USER_AUTOSTART"
        
        echo ""
        ls ~/.config/autostart/*.desktop 2>/dev/null | while read desktop; do
            NAME=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d= -f2)
            if [[ -n "$NAME" ]]; then
                printf "  %-50s ${DIM}(user)${NC}\n" "$NAME"
            fi
        done
    else
        echo -e "  ${DIM}No user autostart directory found.${NC}"
    fi
}

#-------------------------------------------------------------------------------
# Section: Summary
#-------------------------------------------------------------------------------

show_summary() {
    print_header "INVENTORY SUMMARY"
    
    echo ""
    echo -e "  ${BOLD}${WHITE}Category                                    Count${NC}"
    echo -e "  ${DIM}═══════════════════════════════════════════════════════${NC}"
    
    # System packages
    if cmd_exists dpkg; then
        printf "  %-42s %s\n" "System Packages (dpkg)" "$(dpkg -l 2>/dev/null | grep -c '^ii')"
    elif cmd_exists rpm; then
        printf "  %-42s %s\n" "System Packages (rpm)" "$(rpm -qa 2>/dev/null | wc -l)"
    elif cmd_exists pacman; then
        printf "  %-42s %s\n" "System Packages (pacman)" "$(pacman -Q 2>/dev/null | wc -l)"
    fi
    
    # Universal packages
    if cmd_exists snap; then
        printf "  %-42s %s\n" "Snap Packages" "$(snap list 2>/dev/null | tail -n +2 | wc -l)"
    fi
    if cmd_exists flatpak; then
        printf "  %-42s %s\n" "Flatpak Applications" "$(flatpak list --app 2>/dev/null | wc -l)"
    fi
    
    # GUI apps
    SYSTEM_APPS=0
    USER_APPS=0
    FLATPAK_DESKTOP=0
    SNAP_DESKTOP=0
    [[ -d /usr/share/applications ]] && SYSTEM_APPS=$(ls -1 /usr/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d ~/.local/share/applications ]] && USER_APPS=$(ls -1 ~/.local/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d /var/lib/flatpak/exports/share/applications ]] && FLATPAK_DESKTOP=$(ls -1 /var/lib/flatpak/exports/share/applications/*.desktop 2>/dev/null | wc -l)
    [[ -d /var/lib/snapd/desktop/applications ]] && SNAP_DESKTOP=$(ls -1 /var/lib/snapd/desktop/applications/*.desktop 2>/dev/null | wc -l)
    TOTAL_APPS=$((SYSTEM_APPS + USER_APPS + FLATPAK_DESKTOP + SNAP_DESKTOP))
    printf "  %-42s %s\n" "GUI Applications (.desktop)" "$TOTAL_APPS"
    
    # Services
    if cmd_exists systemctl; then
        printf "  %-42s %s\n" "Systemd Services (total)" "$(systemctl list-unit-files --type=service --no-pager 2>/dev/null | grep -c '\.service')"
        printf "  %-42s %s\n" "Systemd Services (running)" "$(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c '\.service')"
    fi
    
    # Kernel modules
    printf "  %-42s %s\n" "Kernel Modules (loaded)" "$(lsmod 2>/dev/null | tail -n +2 | wc -l)"
    
    # Themes
    THEME_COUNT=0
    ICON_COUNT=0
    CURSOR_COUNT=0
    for dir in /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes"; do
        [[ -d "$dir" ]] && for theme in "$dir"/*/; do
            [[ -d "${theme}gtk-3.0" || -d "${theme}gtk-4.0" ]] && ((THEME_COUNT++))
        done
    done
    for dir in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
        [[ -d "$dir" ]] && for icon in "$dir"/*/; do
            [[ -f "${icon}index.theme" ]] && ((ICON_COUNT++))
            [[ -d "${icon}cursors" ]] && ((CURSOR_COUNT++))
        done
    done
    
    printf "  %-42s %s\n" "GTK Themes" "$THEME_COUNT"
    printf "  %-42s %s\n" "Icon Themes" "$ICON_COUNT"
    printf "  %-42s %s\n" "Cursor Themes" "$CURSOR_COUNT"
    
    # Fonts
    if cmd_exists fc-list; then
        printf "  %-42s %s\n" "Font Families" "$(fc-list : family 2>/dev/null | sort -u | wc -l)"
    fi
    
    echo -e "  ${DIM}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Report generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
}

#-------------------------------------------------------------------------------
# Show All Sections
#-------------------------------------------------------------------------------

show_all_sections() {
    show_os_info
    echo ""
    show_kernel_info
    echo ""
    show_package_managers
    echo ""
    show_installed_packages
    echo ""
    show_snap_packages
    echo ""
    show_flatpak_packages
    echo ""
    show_gui_applications
    echo ""
    show_systemd_services
    echo ""
    show_desktop_themes
    echo ""
    show_startup_apps
    echo ""
    show_summary
}

#-------------------------------------------------------------------------------
# Save Report
#-------------------------------------------------------------------------------

save_report() {
    clear_screen
    print_header "SAVE REPORT TO FILE"
    
    echo ""
    echo -e "  ${WHITE}Enter filename (or press Enter for default):${NC}"
    echo -ne "  ${CYAN}Filename: ${NC}"
    read -r filename
    
    if [[ -z "$filename" ]]; then
        filename="linux-inventory-$(date '+%Y%m%d-%H%M%S').txt"
    fi
    
    # Add .txt extension if not present
    [[ "$filename" != *.txt ]] && filename="${filename}.txt"
    
    echo ""
    echo -e "  ${YELLOW}Generating report...${NC}"
    
    # Generate report without colors
    {
        echo "LINUX SOFTWARE INVENTORY REPORT"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "========================================"
        echo ""
        
        # Temporarily disable colors
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' WHITE='' NC='' BOLD='' DIM=''
        
        show_all_sections
        
    } > "$filename" 2>&1
    
    # Restore colors
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
    CYAN='\033[0;36m' MAGENTA='\033[0;35m' WHITE='\033[1;37m' NC='\033[0m'
    BOLD='\033[1m' DIM='\033[2m'
    
    echo ""
    echo -e "  ${GREEN}✓ Report saved to: ${WHITE}$filename${NC}"
    echo ""
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

# Check for minimum requirements
if [[ ! -f /etc/os-release ]]; then
    echo "Warning: /etc/os-release not found. Some features may not work."
fi

# Start the application
show_main_menu
