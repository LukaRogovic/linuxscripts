#!/bin/bash

#===============================================================================
# BLOATWARE DETECTION - TERMINAL UI
# Interactive terminal application for detecting bloatware on Debian-based systems
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

# Counters
TOTAL_BLOAT=0

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

check_package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
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

print_found() {
    echo -e "  ${RED}●${NC} $1"
    ((TOTAL_BLOAT++)) || true
}

print_info() {
    echo -e "  ${YELLOW}○${NC} $1"
}

print_clean() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_item() {
    printf "  ${GREEN}%-35s${NC} : %s\n" "$1" "$2"
}

print_count() {
    printf "  ${CYAN}%-35s${NC} : ${WHITE}%s${NC}\n" "$1" "$2"
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
        
        echo -e "${BOLD}${RED}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║    ██████╗ ██╗      ██████╗  █████╗ ████████╗██╗    ██╗ █████╗ ██████╗     ║"
        echo "║    ██╔══██╗██║     ██╔═══██╗██╔══██╗╚══██╔══╝██║    ██║██╔══██╗██╔══██╗    ║"
        echo "║    ██████╔╝██║     ██║   ██║███████║   ██║   ██║ █╗ ██║███████║██████╔╝    ║"
        echo "║    ██╔══██╗██║     ██║   ██║██╔══██║   ██║   ██║███╗██║██╔══██║██╔══██╗    ║"
        echo "║    ██████╔╝███████╗╚██████╔╝██║  ██║   ██║   ╚███╔███╔╝██║  ██║██║  ██║    ║"
        echo "║    ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝    ║"
        echo "║                                                                            ║"
        echo "║                    DETECTOR FOR DEBIAN-BASED SYSTEMS                       ║"
        echo "║                  - Luka Rogovic <luka032[at]gmail.com -                    ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${WHITE}  Select a category to scan:${NC}"
        echo ""
        echo -e "  ${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Known Bloatware Packages${NC}                                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Snap Packages${NC}                                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Flatpak Packages${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Large Installed Packages${NC}                                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Orphaned Packages${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Residual Config Files${NC}                                              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Startup Applications${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Unnecessary Services${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Cache & Temp Files${NC}                                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}10.${NC} ${GREEN}Browser Data${NC}                                                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}11.${NC} ${GREEN}Cleanup Commands${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} A.${NC} ${YELLOW}Run FULL Scan (All Sections)${NC}                                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${YELLOW}Save Report to File${NC}                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) run_section "bloatware_packages" ;;
            2) run_section "snap_packages" ;;
            3) run_section "flatpak_packages" ;;
            4) run_section "large_packages" ;;
            5) run_section "orphaned_packages" ;;
            6) run_section "residual_configs" ;;
            7) run_section "startup_apps" ;;
            8) run_section "unnecessary_services" ;;
            9) run_section "cache_files" ;;
            10) run_section "browser_data" ;;
            11) run_section "cleanup_commands" ;;
            a|A) run_section "all" ;;
            s|S) save_report ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Bloatware Detector!${NC}"
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
        TOTAL_BLOAT=0
        
        case $section in
            bloatware_packages) show_bloatware_packages ;;
            snap_packages) show_snap_packages ;;
            flatpak_packages) show_flatpak_packages ;;
            large_packages) show_large_packages ;;
            orphaned_packages) show_orphaned_packages ;;
            residual_configs) show_residual_configs ;;
            startup_apps) show_startup_apps ;;
            unnecessary_services) show_unnecessary_services ;;
            cache_files) show_cache_files ;;
            browser_data) show_browser_data ;;
            cleanup_commands) show_cleanup_commands ;;
            all) show_all_sections ;;
        esac
        
        wait_for_menu
        local result=$?
        
        [[ $result -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Section: Known Bloatware Packages
#-------------------------------------------------------------------------------

show_bloatware_packages() {
    print_header "KNOWN BLOATWARE PACKAGES"
    
    BLOATWARE_PACKAGES=(
        # Games
        "gnome-mines" "gnome-sudoku" "gnome-mahjongg" "aisleriot" "gnome-2048"
        "gnome-chess" "gnome-klotski" "gnome-nibbles" "gnome-robots" "gnome-taquin"
        "gnome-tetravex" "quadrapassel" "swell-foop" "tali" "iagno" "lightsoff"
        "four-in-a-row" "five-or-more" "hitori"
        # Amazon/Shopping
        "ubuntu-web-launchers" "amazon-launcher"
        # Legacy
        "zeitgeist" "zeitgeist-core" "zeitgeist-datahub" "activity-log-manager"
        # Telemetry
        "apport" "whoopsie" "ubuntu-report" "popularity-contest" "kerneloops"
        # Potentially unwanted
        "gnome-weather" "gnome-maps" "gnome-contacts" "gnome-documents"
        "gnome-music" "gnome-photos" "totem" "rhythmbox" "shotwell" "cheese"
        "simple-scan" "remmina" "transmission-gtk" "thunderbird"
        "libreoffice-draw" "libreoffice-math" "libreoffice-base"
        # Accessibility (keep if needed)
        "brltty" "orca"
        # Print services
        "cups-browsed"
        # Speech
        "speech-dispatcher" "espeak-ng-data"
    )
    
    print_section "Games (Pre-installed)"
    FOUND=0
    for pkg in gnome-mines gnome-sudoku gnome-mahjongg aisleriot gnome-2048 gnome-chess quadrapassel swell-foop; do
        if check_package_installed "$pkg"; then
            print_found "$pkg"
            FOUND=1
        fi
    done
    [[ $FOUND -eq 0 ]] && print_clean "No pre-installed games found"
    
    print_section "Telemetry & Tracking"
    FOUND=0
    for pkg in apport whoopsie ubuntu-report popularity-contest kerneloops; do
        if check_package_installed "$pkg"; then
            print_found "$pkg - $(dpkg -s "$pkg" 2>/dev/null | grep "^Description:" | cut -d: -f2 | head -c 50)"
            FOUND=1
        fi
    done
    [[ $FOUND -eq 0 ]] && print_clean "No telemetry packages found"
    
    print_section "Legacy/Redundant Packages"
    FOUND=0
    for pkg in zeitgeist zeitgeist-core zeitgeist-datahub activity-log-manager empathy; do
        if check_package_installed "$pkg"; then
            print_found "$pkg"
            FOUND=1
        fi
    done
    [[ $FOUND -eq 0 ]] && print_clean "No legacy packages found"
    
    print_section "Potentially Unused Applications"
    FOUND=0
    for pkg in gnome-weather gnome-maps gnome-contacts gnome-documents gnome-music gnome-photos totem rhythmbox shotwell cheese; do
        if check_package_installed "$pkg"; then
            print_info "$pkg (may be useful - review before removing)"
            FOUND=1
        fi
    done
    [[ $FOUND -eq 0 ]] && print_clean "No potentially unused apps found"
    
    print_section "Accessibility Tools (keep if needed)"
    for pkg in brltty orca speech-dispatcher; do
        if check_package_installed "$pkg"; then
            print_info "$pkg - Keep if you need accessibility features"
        fi
    done
    
    echo ""
    echo -e "  ${CYAN}Total potential bloatware found: ${WHITE}$TOTAL_BLOAT${NC}"
}

#-------------------------------------------------------------------------------
# Section: Snap Packages
#-------------------------------------------------------------------------------

show_snap_packages() {
    print_header "SNAP PACKAGES"
    
    if ! cmd_exists snap; then
        print_clean "Snap is not installed on this system"
        return
    fi
    
    print_section "Installed Snaps"
    SNAP_LIST=$(snap list 2>/dev/null | tail -n +2)
    
    if [[ -z "$SNAP_LIST" ]]; then
        print_clean "No snap packages installed"
        return
    fi
    
    SNAP_COUNT=$(echo "$SNAP_LIST" | wc -l)
    print_count "Total Snap Packages" "$SNAP_COUNT"
    
    echo ""
    echo -e "  ${DIM}Name                           Version                Size${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────${NC}"
    
    snap list 2>/dev/null | tail -n +2 | while read name version rev tracking publisher notes; do
        SIZE=$(snap info "$name" 2>/dev/null | grep "installed:" | awk '{print $NF}' || echo "N/A")
        print_found "$(printf "%-28s %-20s %s" "$name" "${version:0:20}" "$SIZE")"
    done
    
    print_section "Snap Disk Usage"
    if [[ -d /var/lib/snapd/snaps ]]; then
        SNAP_SIZE=$(du -sh /var/lib/snapd/snaps 2>/dev/null | cut -f1)
        print_item "Total Snap Size" "$SNAP_SIZE"
    fi
    
    # snapd memory usage
    if systemctl is-active --quiet snapd 2>/dev/null; then
        print_info "snapd service is running (typically uses 300MB+ RAM)"
    fi
    
    echo ""
    echo -e "  ${YELLOW}Note: Snaps use more disk space and memory than native packages.${NC}"
    echo -e "  ${YELLOW}Consider replacing with APT packages if available.${NC}"
}

#-------------------------------------------------------------------------------
# Section: Flatpak Packages
#-------------------------------------------------------------------------------

show_flatpak_packages() {
    print_header "FLATPAK PACKAGES"
    
    if ! cmd_exists flatpak; then
        print_clean "Flatpak is not installed on this system"
        return
    fi
    
    print_section "Installed Flatpak Applications"
    FLATPAK_LIST=$(flatpak list --app 2>/dev/null)
    
    if [[ -z "$FLATPAK_LIST" ]]; then
        print_clean "No flatpak applications installed"
    else
        FLATPAK_COUNT=$(echo "$FLATPAK_LIST" | wc -l)
        print_count "Total Flatpak Apps" "$FLATPAK_COUNT"
        
        echo ""
        flatpak list --app --columns=name,size 2>/dev/null | while IFS=$'\t' read name size; do
            print_info "$name ($size)"
        done
    fi
    
    print_section "Flatpak Runtimes"
    RUNTIME_COUNT=$(flatpak list --runtime 2>/dev/null | wc -l)
    print_count "Installed Runtimes" "$RUNTIME_COUNT"
    
    print_section "Flatpak Disk Usage"
    if [[ -d /var/lib/flatpak ]]; then
        FLATPAK_SIZE=$(du -sh /var/lib/flatpak 2>/dev/null | cut -f1)
        print_item "Total Flatpak Size" "$FLATPAK_SIZE"
    fi
    
    echo ""
    echo -e "  ${YELLOW}Note: Flatpaks are sandboxed and generally safe to keep.${NC}"
}

#-------------------------------------------------------------------------------
# Section: Large Packages
#-------------------------------------------------------------------------------

show_large_packages() {
    print_header "LARGE INSTALLED PACKAGES"
    
    print_section "Top 25 Largest Packages"
    echo -e "  ${DIM}Package                                           Size${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"
    
    dpkg-query -W -f='${Installed-Size}\t${Package}\n' 2>/dev/null | sort -rn | head -25 | while read size pkg; do
        size_mb=$((size / 1024))
        if [[ $size_mb -gt 100 ]]; then
            printf "  ${RED}●${NC} %-45s %6s MB\n" "$pkg" "$size_mb"
        elif [[ $size_mb -gt 50 ]]; then
            printf "  ${YELLOW}○${NC} %-45s %6s MB\n" "$pkg" "$size_mb"
        else
            printf "  ${GREEN}·${NC} %-45s %6s MB\n" "$pkg" "$size_mb"
        fi
    done
    
    echo ""
    echo -e "  ${DIM}Legend: ${RED}●${NC}${DIM} >100MB  ${YELLOW}○${NC}${DIM} >50MB  ${GREEN}·${NC}${DIM} <50MB${NC}"
}

#-------------------------------------------------------------------------------
# Section: Orphaned Packages
#-------------------------------------------------------------------------------

show_orphaned_packages() {
    print_header "ORPHANED PACKAGES"
    
    print_section "Auto-removable Packages"
    AUTOREMOVE=$(apt-get --dry-run autoremove 2>/dev/null | grep "^Remv" | awk '{print $2}')
    AUTOREMOVE_COUNT=$(echo "$AUTOREMOVE" | grep -c . || echo "0")
    
    if [[ -n "$AUTOREMOVE" && "$AUTOREMOVE_COUNT" -gt 0 ]]; then
        print_found "$AUTOREMOVE_COUNT package(s) can be auto-removed"
        echo ""
        echo "$AUTOREMOVE" | head -20 | while read pkg; do
            echo -e "    ${DIM}$pkg${NC}"
        done
        [[ $AUTOREMOVE_COUNT -gt 20 ]] && echo -e "    ${DIM}... and $((AUTOREMOVE_COUNT - 20)) more${NC}"
    else
        print_clean "No auto-removable packages"
    fi
    
    print_section "Orphaned Libraries (deborphan)"
    if cmd_exists deborphan; then
        ORPHANS=$(deborphan 2>/dev/null)
        if [[ -n "$ORPHANS" ]]; then
            echo "$ORPHANS" | while read pkg; do
                print_found "Orphan: $pkg"
            done
        else
            print_clean "No orphaned libraries found"
        fi
    else
        print_info "Install 'deborphan' for better detection: sudo apt install deborphan"
    fi
}

#-------------------------------------------------------------------------------
# Section: Residual Config Files
#-------------------------------------------------------------------------------

show_residual_configs() {
    print_header "RESIDUAL CONFIGURATION FILES"
    
    print_section "Packages with Leftover Configs"
    RESIDUAL=$(dpkg -l 2>/dev/null | grep "^rc" | awk '{print $2}')
    
    if [[ -n "$RESIDUAL" ]]; then
        RESIDUAL_COUNT=$(echo "$RESIDUAL" | wc -l)
        print_found "$RESIDUAL_COUNT package(s) have residual config files"
        echo ""
        echo "$RESIDUAL" | head -30 | while read pkg; do
            echo -e "    ${DIM}$pkg${NC}"
        done
        [[ $RESIDUAL_COUNT -gt 30 ]] && echo -e "    ${DIM}... and $((RESIDUAL_COUNT - 30)) more${NC}"
        
        echo ""
        echo -e "  ${YELLOW}To remove all residual configs:${NC}"
        echo -e "  ${WHITE}sudo dpkg --purge \$(dpkg -l | grep '^rc' | awk '{print \$2}')${NC}"
    else
        print_clean "No residual configuration files found"
    fi
}

#-------------------------------------------------------------------------------
# Section: Startup Applications
#-------------------------------------------------------------------------------

show_startup_apps() {
    print_header "STARTUP APPLICATIONS"
    
    print_section "System Autostart (/etc/xdg/autostart)"
    if [[ -d /etc/xdg/autostart ]]; then
        SYSTEM_COUNT=$(ls -1 /etc/xdg/autostart/*.desktop 2>/dev/null | wc -l)
        print_count "System autostart entries" "$SYSTEM_COUNT"
        
        echo ""
        ls /etc/xdg/autostart/*.desktop 2>/dev/null | while read desktop; do
            NAME=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d= -f2)
            HIDDEN=$(grep "^Hidden=" "$desktop" 2>/dev/null | cut -d= -f2)
            if [[ "$HIDDEN" == "true" ]]; then
                echo -e "    ${DIM}$NAME (hidden)${NC}"
            else
                echo -e "    ${GREEN}●${NC} $NAME"
            fi
        done | head -20
    fi
    
    print_section "User Autostart (~/.config/autostart)"
    if [[ -d ~/.config/autostart ]]; then
        USER_COUNT=$(ls -1 ~/.config/autostart/*.desktop 2>/dev/null | wc -l)
        print_count "User autostart entries" "$USER_COUNT"
        
        ls ~/.config/autostart/*.desktop 2>/dev/null | while read desktop; do
            NAME=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d= -f2)
            print_info "$NAME"
        done
    else
        print_clean "No user autostart applications"
    fi
}

#-------------------------------------------------------------------------------
# Section: Unnecessary Services
#-------------------------------------------------------------------------------

show_unnecessary_services() {
    print_header "POTENTIALLY UNNECESSARY SERVICES"
    
    print_section "Running Services to Review"
    
    SERVICES=(
        "cups:Printing service - disable if you don't use printers"
        "cups-browsed:Printer browsing - disable if you don't use printers"
        "avahi-daemon:Network discovery (mDNS) - disable if not needed"
        "ModemManager:Mobile broadband - disable if you don't use cellular"
        "whoopsie:Crash reporting - can be disabled for privacy"
        "apport:Bug reporting - can be disabled for privacy"
        "kerneloops:Kernel error reporting - can be disabled"
        "speech-dispatcher:Text-to-speech - disable if not needed"
        "brltty:Braille display - disable if not needed"
        "openvpn:VPN service - disable if not using VPN"
        "bluetooth:Bluetooth - disable if not using Bluetooth"
        "NetworkManager-wait-online:Waits for network - can slow boot"
    )
    
    echo -e "  ${DIM}Service                Status      Description${NC}"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────────────────${NC}"
    
    for entry in "${SERVICES[@]}"; do
        SERVICE=$(echo "$entry" | cut -d: -f1)
        DESC=$(echo "$entry" | cut -d: -f2)
        
        if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
            STATUS="${GREEN}running${NC}"
            printf "  ${YELLOW}●${NC} %-20s [${STATUS}]   %s\n" "$SERVICE" "$DESC"
        elif systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
            STATUS="${YELLOW}enabled${NC}"
            printf "  ${DIM}○${NC} %-20s [${STATUS}]   %s\n" "$SERVICE" "$DESC"
        fi
    done
    
    echo ""
    echo -e "  ${YELLOW}To disable a service:${NC}"
    echo -e "  ${WHITE}sudo systemctl disable --now <service-name>${NC}"
}

#-------------------------------------------------------------------------------
# Section: Cache Files
#-------------------------------------------------------------------------------

show_cache_files() {
    print_header "CACHE & TEMPORARY FILES"
    
    print_section "System Caches"
    
    # APT cache
    if [[ -d /var/cache/apt/archives ]]; then
        APT_SIZE=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)
        print_item "APT package cache" "$APT_SIZE"
    fi
    
    # Journal logs
    if cmd_exists journalctl; then
        JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null | grep -oP '\d+\.?\d*[KMGT]?' | head -1)
        print_item "System journal logs" "${JOURNAL_SIZE:-N/A}"
    fi
    
    print_section "User Caches"
    
    # User cache
    if [[ -d ~/.cache ]]; then
        USER_CACHE=$(du -sh ~/.cache 2>/dev/null | cut -f1)
        print_item "User cache (~/.cache)" "$USER_CACHE"
    fi
    
    # Thumbnail cache
    if [[ -d ~/.cache/thumbnails ]]; then
        THUMB_SIZE=$(du -sh ~/.cache/thumbnails 2>/dev/null | cut -f1)
        print_item "Thumbnail cache" "$THUMB_SIZE"
    fi
    
    # Trash
    if [[ -d ~/.local/share/Trash ]]; then
        TRASH_SIZE=$(du -sh ~/.local/share/Trash 2>/dev/null | cut -f1)
        print_item "Trash" "$TRASH_SIZE"
    fi
    
    print_section "Snap Cache"
    if [[ -d ~/snap ]]; then
        SNAP_USER=$(du -sh ~/snap 2>/dev/null | cut -f1)
        print_item "Snap user data" "$SNAP_USER"
    fi
}

#-------------------------------------------------------------------------------
# Section: Browser Data
#-------------------------------------------------------------------------------

show_browser_data() {
    print_header "BROWSER DATA"
    
    print_section "Browser Profile Sizes"
    
    # Firefox
    if [[ -d ~/.mozilla/firefox ]]; then
        FF_SIZE=$(du -sh ~/.mozilla/firefox 2>/dev/null | cut -f1)
        print_item "Firefox" "$FF_SIZE"
    fi
    
    # Snap Firefox
    if [[ -d ~/snap/firefox ]]; then
        SNAP_FF=$(du -sh ~/snap/firefox 2>/dev/null | cut -f1)
        print_item "Firefox (Snap)" "$SNAP_FF"
    fi
    
    # Chrome
    if [[ -d ~/.config/google-chrome ]]; then
        CHROME_SIZE=$(du -sh ~/.config/google-chrome 2>/dev/null | cut -f1)
        print_item "Google Chrome" "$CHROME_SIZE"
    fi
    
    # Chromium
    if [[ -d ~/.config/chromium ]]; then
        CHROMIUM_SIZE=$(du -sh ~/.config/chromium 2>/dev/null | cut -f1)
        print_item "Chromium" "$CHROMIUM_SIZE"
    fi
    
    # Brave
    if [[ -d ~/.config/BraveSoftware ]]; then
        BRAVE_SIZE=$(du -sh ~/.config/BraveSoftware 2>/dev/null | cut -f1)
        print_item "Brave Browser" "$BRAVE_SIZE"
    fi
    
    # Edge
    if [[ -d ~/.config/microsoft-edge ]]; then
        EDGE_SIZE=$(du -sh ~/.config/microsoft-edge 2>/dev/null | cut -f1)
        print_item "Microsoft Edge" "$EDGE_SIZE"
    fi
    
    echo ""
    echo -e "  ${YELLOW}Browser profiles contain cache, history, cookies, and extensions.${NC}"
    echo -e "  ${YELLOW}Clear from within the browser to avoid losing important data.${NC}"
}

#-------------------------------------------------------------------------------
# Section: Cleanup Commands
#-------------------------------------------------------------------------------

show_cleanup_commands() {
    print_header "CLEANUP COMMANDS"
    
    echo -e "
  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
  ${WHITE}SAFE CLEANUP COMMANDS${NC}
  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

  ${GREEN}# Remove unused packages${NC}
  sudo apt autoremove --purge

  ${GREEN}# Clean APT cache${NC}
  sudo apt clean

  ${GREEN}# Remove residual configs${NC}
  sudo dpkg --purge \$(dpkg -l | grep '^rc' | awk '{print \$2}')

  ${GREEN}# Clear thumbnail cache${NC}
  rm -rf ~/.cache/thumbnails/*

  ${GREEN}# Vacuum system journal (keep 7 days)${NC}
  sudo journalctl --vacuum-time=7d

  ${GREEN}# Empty trash${NC}
  rm -rf ~/.local/share/Trash/*

  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
  ${WHITE}SNAP CLEANUP${NC}
  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

  ${GREEN}# Remove a snap package${NC}
  sudo snap remove --purge <snap-name>

  ${GREEN}# Remove old snap revisions${NC}
  sudo snap set system refresh.retain=2

  ${GREEN}# Remove snapd completely${NC}
  sudo apt remove --purge snapd

  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
  ${WHITE}SERVICE MANAGEMENT${NC}
  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

  ${GREEN}# Disable a service${NC}
  sudo systemctl disable --now <service-name>

  ${GREEN}# Mask a service (prevent starting)${NC}
  sudo systemctl mask <service-name>

  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
  ${RED}⚠ WARNING: Always review packages before removing!${NC}
  ${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
"
}

#-------------------------------------------------------------------------------
# Show All Sections
#-------------------------------------------------------------------------------

show_all_sections() {
    show_bloatware_packages
    echo ""
    show_snap_packages
    echo ""
    show_flatpak_packages
    echo ""
    show_large_packages
    echo ""
    show_orphaned_packages
    echo ""
    show_residual_configs
    echo ""
    show_startup_apps
    echo ""
    show_unnecessary_services
    echo ""
    show_cache_files
    echo ""
    show_browser_data
    
    print_header "SCAN SUMMARY"
    echo -e "\n  ${BOLD}Total potential bloatware items found: ${RED}$TOTAL_BLOAT${NC}"
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
    
    [[ -z "$filename" ]] && filename="bloatware-report-$(date '+%Y%m%d-%H%M%S').txt"
    [[ "$filename" != *.txt ]] && filename="${filename}.txt"
    
    echo -e "  ${YELLOW}Generating report...${NC}"
    
    {
        echo "BLOATWARE DETECTION REPORT"
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
