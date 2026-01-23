#!/bin/bash

#===============================================================================
# PERMISSION AUDITOR - TERMINAL UI
# Find and fix dangerous file permissions
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

# Default scan paths
DEFAULT_SCAN_PATHS="/home /var/www /tmp /var/tmp /opt"
SYSTEM_PATHS="/usr /bin /sbin /lib /lib64"

# Known legitimate SUID binaries
KNOWN_SUID=(
    "/usr/bin/passwd"
    "/usr/bin/sudo"
    "/usr/bin/su"
    "/usr/bin/newgrp"
    "/usr/bin/gpasswd"
    "/usr/bin/chsh"
    "/usr/bin/chfn"
    "/usr/bin/mount"
    "/usr/bin/umount"
    "/usr/bin/pkexec"
    "/usr/bin/crontab"
    "/usr/bin/at"
    "/usr/bin/fusermount"
    "/usr/bin/fusermount3"
    "/usr/lib/dbus-1.0/dbus-daemon-launch-helper"
    "/usr/lib/openssh/ssh-keysign"
    "/usr/lib/policykit-1/polkit-agent-helper-1"
    "/usr/libexec/polkit-agent-helper-1"
    "/usr/sbin/pppd"
    "/usr/sbin/unix_chkpwd"
    "/bin/su"
    "/bin/mount"
    "/bin/umount"
    "/bin/ping"
    "/bin/ping6"
)

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

cmd_exists() {
    command -v "$1" &> /dev/null
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Note: Running without root. Some files may not be accessible.${NC}"
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
    printf "  ${GREEN}%-35s${NC} : %s\n" "$1" "$2"
}

print_found() {
    echo -e "  ${RED}●${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
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
    echo -e "  ${WHITE}[R]${NC} Rescan    ${WHITE}[M]${NC} Main Menu    ${WHITE}[Q]${NC} Quit"
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

is_known_suid() {
    local file="$1"
    for known in "${KNOWN_SUID[@]}"; do
        [[ "$file" == "$known" ]] && return 0
    done
    return 1
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
        echo "║      ██████╗ ███████╗██████╗ ███╗   ███╗██╗███████╗███████╗██╗ ██████╗     ║"
        echo "║      ██╔══██╗██╔════╝██╔══██╗████╗ ████║██║██╔════╝██╔════╝██║██╔═══██╗    ║"
        echo "║      ██████╔╝█████╗  ██████╔╝██╔████╔██║██║███████╗███████╗██║██║   ██║    ║"
        echo "║      ██╔═══╝ ██╔══╝  ██╔══██╗██║╚██╔╝██║██║╚════██║╚════██║██║██║   ██║    ║"
        echo "║      ██║     ███████╗██║  ██║██║ ╚═╝ ██║██║███████║███████║██║╚██████╔╝    ║"
        echo "║      ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝     ║"
        echo "║                                                                            ║"
        echo "║                              AUDITOR                                       ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com -                   ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${WHITE}  Select an option:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}Find World-Writable Files (777)${NC}                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Find World-Writable Directories${NC}                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Find SUID Binaries${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Find SGID Binaries${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Find Files Without Owner${NC}                                            ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Find Writable Config Files${NC}                                          ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Find Writable Scripts in PATH${NC}                                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Audit Home Directory Permissions${NC}                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Audit SSH File Permissions${NC}                                          ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} A.${NC} ${YELLOW}Run Full Security Audit${NC}                                             ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} F.${NC} ${YELLOW}Fix Common Issues${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${YELLOW}Save Audit Report${NC}                                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) find_world_writable_files ;;
            2) find_world_writable_dirs ;;
            3) find_suid_binaries ;;
            4) find_sgid_binaries ;;
            5) find_noowner_files ;;
            6) find_writable_configs ;;
            7) find_writable_path_scripts ;;
            8) audit_home_permissions ;;
            9) audit_ssh_permissions ;;
            a|A) full_security_audit ;;
            f|F) fix_common_issues ;;
            s|S) save_audit_report ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Permission Auditor!${NC}"
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
# Find World-Writable Files
#-------------------------------------------------------------------------------

find_world_writable_files() {
    while true; do
        clear_screen
        print_header "WORLD-WRITABLE FILES (777)"
        
        echo ""
        echo -e "  ${DIM}Scanning common directories...${NC}"
        echo ""
        
        print_section "World-Writable Files"
        
        local count=0
        local files=()
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                files+=("$file")
                PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                OWNER=$(stat -c '%U:%G' "$file" 2>/dev/null)
                print_found "$file ${DIM}($PERMS, $OWNER)${NC}"
                ((count++))
            fi
        done < <(find /home /var/www /tmp /var/tmp /opt 2>/dev/null -type f -perm -0002 -not -path "*/\.*" 2>/dev/null | head -50)
        
        if [[ $count -eq 0 ]]; then
            print_success "No world-writable files found in scanned directories"
        else
            echo ""
            echo -e "  ${YELLOW}Found $count world-writable file(s)${NC}"
            echo ""
            echo -e "  ${DIM}World-writable files can be modified by any user on the system.${NC}"
            echo -e "  ${DIM}This is a security risk, especially for scripts and configs.${NC}"
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find World-Writable Directories
#-------------------------------------------------------------------------------

find_world_writable_dirs() {
    while true; do
        clear_screen
        print_header "WORLD-WRITABLE DIRECTORIES"
        
        echo ""
        echo -e "  ${DIM}Scanning for world-writable directories...${NC}"
        echo ""
        
        print_section "Without Sticky Bit (DANGEROUS)"
        
        local count=0
        
        while IFS= read -r dir; do
            if [[ -n "$dir" ]]; then
                PERMS=$(stat -c '%a' "$dir" 2>/dev/null)
                print_found "$dir ${DIM}($PERMS)${NC}"
                ((count++))
            fi
        done < <(find / -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -v "^/proc\|^/sys\|^/run" | head -30)
        
        if [[ $count -eq 0 ]]; then
            print_success "No dangerous world-writable directories found"
        else
            echo ""
            echo -e "  ${RED}Found $count directory(ies) without sticky bit!${NC}"
        fi
        
        print_section "With Sticky Bit (Normal)"
        
        local sticky_count=0
        while IFS= read -r dir; do
            if [[ -n "$dir" ]]; then
                PERMS=$(stat -c '%a' "$dir" 2>/dev/null)
                echo -e "  ${GREEN}●${NC} $dir ${DIM}($PERMS)${NC}"
                ((sticky_count++))
            fi
        done < <(find / -type d -perm -1002 2>/dev/null | grep -v "^/proc\|^/sys" | head -20)
        
        echo ""
        echo -e "  ${DIM}Sticky bit prevents users from deleting each other's files.${NC}"
        echo -e "  ${DIM}/tmp and /var/tmp should have sticky bit set (1777).${NC}"
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find SUID Binaries
#-------------------------------------------------------------------------------

find_suid_binaries() {
    while true; do
        clear_screen
        print_header "SUID BINARIES"
        
        echo ""
        echo -e "  ${DIM}Scanning for SUID binaries (runs as owner, usually root)...${NC}"
        echo ""
        
        print_section "Unknown/Suspicious SUID Binaries"
        
        local unknown_count=0
        local known_count=0
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                if is_known_suid "$file"; then
                    ((known_count++))
                else
                    PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                    OWNER=$(stat -c '%U' "$file" 2>/dev/null)
                    print_found "$file ${DIM}($PERMS, owner: $OWNER)${NC}"
                    ((unknown_count++))
                fi
            fi
        done < <(find / -type f -perm -4000 2>/dev/null | grep -v "^/proc\|^/sys" | head -100)
        
        if [[ $unknown_count -eq 0 ]]; then
            print_success "No suspicious SUID binaries found"
        else
            echo ""
            echo -e "  ${YELLOW}Found $unknown_count unknown SUID binary(ies)${NC}"
        fi
        
        print_section "Known Legitimate SUID Binaries"
        echo -e "  ${DIM}Found $known_count known SUID binaries (sudo, passwd, mount, etc.)${NC}"
        
        echo ""
        echo -e "  ${DIM}SUID binaries run with the owner's privileges (often root).${NC}"
        echo -e "  ${DIM}Unexpected SUID binaries could be privilege escalation vectors.${NC}"
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find SGID Binaries
#-------------------------------------------------------------------------------

find_sgid_binaries() {
    while true; do
        clear_screen
        print_header "SGID BINARIES"
        
        echo ""
        echo -e "  ${DIM}Scanning for SGID binaries (runs as group)...${NC}"
        echo ""
        
        print_section "SGID Files"
        
        local count=0
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                GROUP=$(stat -c '%G' "$file" 2>/dev/null)
                echo -e "  ${YELLOW}●${NC} $file ${DIM}($PERMS, group: $GROUP)${NC}"
                ((count++))
            fi
        done < <(find / -type f -perm -2000 2>/dev/null | grep -v "^/proc\|^/sys" | head -50)
        
        if [[ $count -eq 0 ]]; then
            print_success "No SGID binaries found"
        else
            echo ""
            echo -e "  ${DIM}Found $count SGID binary(ies)${NC}"
        fi
        
        echo ""
        echo -e "  ${DIM}SGID binaries run with the group's privileges.${NC}"
        echo -e "  ${DIM}Common legitimate examples: wall, write, crontab${NC}"
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find Files Without Owner
#-------------------------------------------------------------------------------

find_noowner_files() {
    while true; do
        clear_screen
        print_header "FILES WITHOUT OWNER"
        
        echo ""
        echo -e "  ${DIM}Scanning for files with no user or group...${NC}"
        echo ""
        
        print_section "Files Without User"
        
        local nouser_count=0
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                print_found "$file"
                ((nouser_count++))
            fi
        done < <(find / -nouser 2>/dev/null | grep -v "^/proc\|^/sys" | head -30)
        
        if [[ $nouser_count -eq 0 ]]; then
            print_success "No files without user owner"
        fi
        
        print_section "Files Without Group"
        
        local nogroup_count=0
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                print_found "$file"
                ((nogroup_count++))
            fi
        done < <(find / -nogroup 2>/dev/null | grep -v "^/proc\|^/sys" | head -30)
        
        if [[ $nogroup_count -eq 0 ]]; then
            print_success "No files without group owner"
        fi
        
        echo ""
        echo -e "  ${DIM}Files without owner typically remain after user deletion.${NC}"
        echo -e "  ${DIM}They should be assigned to a valid user or removed.${NC}"
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find Writable Config Files
#-------------------------------------------------------------------------------

find_writable_configs() {
    while true; do
        clear_screen
        print_header "WRITABLE CONFIG FILES"
        
        echo ""
        echo -e "  ${DIM}Scanning for world-writable config files in /etc...${NC}"
        echo ""
        
        print_section "World-Writable in /etc"
        
        local count=0
        
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                print_found "$file ${DIM}($PERMS)${NC}"
                ((count++))
            fi
        done < <(find /etc -type f -perm -0002 2>/dev/null | head -30)
        
        if [[ $count -eq 0 ]]; then
            print_success "No world-writable config files in /etc"
        fi
        
        print_section "Group/Other Writable Critical Files"
        
        CRITICAL_FILES=(
            "/etc/passwd"
            "/etc/shadow"
            "/etc/group"
            "/etc/gshadow"
            "/etc/sudoers"
            "/etc/ssh/sshd_config"
            "/etc/crontab"
        )
        
        for file in "${CRITICAL_FILES[@]}"; do
            if [[ -f "$file" ]]; then
                PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                EXPECTED=""
                case "$file" in
                    "/etc/shadow"|"/etc/gshadow") EXPECTED="640 or 600" ;;
                    "/etc/sudoers") EXPECTED="440" ;;
                    *) EXPECTED="644" ;;
                esac
                
                # Check if writable by group or other
                if [[ $((0$PERMS & 0022)) -ne 0 ]]; then
                    print_found "$file ${DIM}($PERMS, should be $EXPECTED)${NC}"
                else
                    print_success "$file ${DIM}($PERMS)${NC}"
                fi
            fi
        done
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Find Writable Scripts in PATH
#-------------------------------------------------------------------------------

find_writable_path_scripts() {
    while true; do
        clear_screen
        print_header "WRITABLE SCRIPTS IN PATH"
        
        echo ""
        echo -e "  ${DIM}Scanning PATH directories for writable scripts...${NC}"
        echo ""
        
        print_section "PATH Directories"
        echo -e "  ${DIM}$PATH${NC}"
        
        print_section "World-Writable Executables in PATH"
        
        local count=0
        
        IFS=':' read -ra PATHDIRS <<< "$PATH"
        for dir in "${PATHDIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                while IFS= read -r file; do
                    if [[ -n "$file" ]]; then
                        PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                        print_found "$file ${DIM}($PERMS)${NC}"
                        ((count++))
                    fi
                done < <(find "$dir" -maxdepth 1 -type f -perm -0002 2>/dev/null)
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            print_success "No world-writable executables in PATH"
        else
            echo ""
            echo -e "  ${RED}CRITICAL: Found $count writable executable(s) in PATH!${NC}"
            echo -e "  ${DIM}Attackers could modify these to run malicious code.${NC}"
        fi
        
        print_section "World-Writable PATH Directories"
        
        local dir_count=0
        for dir in "${PATHDIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                PERMS=$(stat -c '%a' "$dir" 2>/dev/null)
                if [[ $((0$PERMS & 0002)) -ne 0 ]]; then
                    print_found "$dir ${DIM}($PERMS)${NC}"
                    ((dir_count++))
                fi
            fi
        done
        
        if [[ $dir_count -eq 0 ]]; then
            print_success "No world-writable directories in PATH"
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Audit Home Directory Permissions
#-------------------------------------------------------------------------------

audit_home_permissions() {
    while true; do
        clear_screen
        print_header "HOME DIRECTORY PERMISSIONS"
        
        echo ""
        
        print_section "Home Directory Audit"
        
        for dir in /home/*/; do
            if [[ -d "$dir" ]]; then
                USER=$(basename "$dir")
                PERMS=$(stat -c '%a' "$dir" 2>/dev/null)
                OWNER=$(stat -c '%U:%G' "$dir" 2>/dev/null)
                
                # Check permissions
                if [[ $((0$PERMS & 0077)) -ne 0 ]] && [[ "$PERMS" != "750" ]] && [[ "$PERMS" != "700" ]]; then
                    print_warning "$dir ${DIM}($PERMS, $OWNER)${NC} - Should be 700 or 750"
                else
                    print_success "$dir ${DIM}($PERMS, $OWNER)${NC}"
                fi
            fi
        done
        
        print_section "Sensitive Files in Home Directories"
        
        for homedir in /home/*/; do
            USER=$(basename "$homedir")
            
            # Check .bashrc, .profile, etc.
            for file in ".bashrc" ".bash_profile" ".profile" ".bash_logout"; do
                filepath="${homedir}${file}"
                if [[ -f "$filepath" ]]; then
                    PERMS=$(stat -c '%a' "$filepath" 2>/dev/null)
                    if [[ $((0$PERMS & 0002)) -ne 0 ]]; then
                        print_found "$filepath ${DIM}($PERMS)${NC} - World-writable!"
                    fi
                fi
            done
        done
        
        print_section "World-Readable Private Keys"
        
        local key_count=0
        while IFS= read -r key; do
            if [[ -n "$key" ]]; then
                PERMS=$(stat -c '%a' "$key" 2>/dev/null)
                if [[ "$PERMS" != "600" ]] && [[ "$PERMS" != "400" ]]; then
                    print_found "$key ${DIM}($PERMS)${NC} - Should be 600"
                    ((key_count++))
                fi
            fi
        done < <(find /home -name "id_*" -not -name "*.pub" 2>/dev/null)
        
        if [[ $key_count -eq 0 ]]; then
            print_success "All private keys have correct permissions"
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Audit SSH Permissions
#-------------------------------------------------------------------------------

audit_ssh_permissions() {
    while true; do
        clear_screen
        print_header "SSH FILE PERMISSIONS"
        
        echo ""
        
        print_section "System SSH Files"
        
        SSH_FILES=(
            "/etc/ssh/sshd_config:644"
            "/etc/ssh/ssh_config:644"
            "/etc/ssh/ssh_host_rsa_key:600"
            "/etc/ssh/ssh_host_ecdsa_key:600"
            "/etc/ssh/ssh_host_ed25519_key:600"
        )
        
        for entry in "${SSH_FILES[@]}"; do
            file="${entry%%:*}"
            expected="${entry##*:}"
            
            if [[ -f "$file" ]]; then
                PERMS=$(stat -c '%a' "$file" 2>/dev/null)
                if [[ "$PERMS" == "$expected" ]]; then
                    print_success "$file ${DIM}($PERMS)${NC}"
                else
                    print_warning "$file ${DIM}($PERMS, should be $expected)${NC}"
                fi
            fi
        done
        
        print_section "User SSH Directories"
        
        for homedir in /home/*/; do
            USER=$(basename "$homedir")
            SSH_DIR="${homedir}.ssh"
            
            if [[ -d "$SSH_DIR" ]]; then
                PERMS=$(stat -c '%a' "$SSH_DIR" 2>/dev/null)
                if [[ "$PERMS" == "700" ]]; then
                    print_success "$SSH_DIR ${DIM}($PERMS)${NC}"
                else
                    print_warning "$SSH_DIR ${DIM}($PERMS, should be 700)${NC}"
                fi
                
                # Check authorized_keys
                AUTH_KEYS="$SSH_DIR/authorized_keys"
                if [[ -f "$AUTH_KEYS" ]]; then
                    PERMS=$(stat -c '%a' "$AUTH_KEYS" 2>/dev/null)
                    if [[ "$PERMS" == "600" ]] || [[ "$PERMS" == "644" ]]; then
                        print_success "  └─ authorized_keys ${DIM}($PERMS)${NC}"
                    else
                        print_warning "  └─ authorized_keys ${DIM}($PERMS, should be 600)${NC}"
                    fi
                fi
                
                # Check private keys
                for key in "$SSH_DIR"/id_*; do
                    if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
                        PERMS=$(stat -c '%a' "$key" 2>/dev/null)
                        KEYNAME=$(basename "$key")
                        if [[ "$PERMS" == "600" ]] || [[ "$PERMS" == "400" ]]; then
                            print_success "  └─ $KEYNAME ${DIM}($PERMS)${NC}"
                        else
                            print_found "  └─ $KEYNAME ${DIM}($PERMS, should be 600)${NC}"
                        fi
                    fi
                done
            fi
        done
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Full Security Audit
#-------------------------------------------------------------------------------

full_security_audit() {
    clear_screen
    print_header "FULL SECURITY AUDIT"
    
    echo ""
    echo -e "  ${YELLOW}Running comprehensive permission audit...${NC}"
    echo ""
    
    local total_issues=0
    
    # World-writable files
    print_section "World-Writable Files"
    local ww_count=$(find /home /var/www /tmp /var/tmp /opt -type f -perm -0002 2>/dev/null | wc -l)
    if [[ $ww_count -gt 0 ]]; then
        print_warning "Found $ww_count world-writable file(s)"
        ((total_issues += ww_count))
    else
        print_success "No world-writable files in user directories"
    fi
    
    # Dangerous directories
    print_section "World-Writable Directories (no sticky bit)"
    local wwd_count=$(find / -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -v "^/proc\|^/sys\|^/run" | wc -l)
    if [[ $wwd_count -gt 0 ]]; then
        print_found "Found $wwd_count dangerous directory(ies)"
        ((total_issues += wwd_count))
    else
        print_success "No dangerous world-writable directories"
    fi
    
    # Unknown SUID
    print_section "SUID Binaries"
    local suid_count=0
    while IFS= read -r file; do
        is_known_suid "$file" || ((suid_count++))
    done < <(find / -type f -perm -4000 2>/dev/null | grep -v "^/proc\|^/sys")
    
    if [[ $suid_count -gt 0 ]]; then
        print_warning "Found $suid_count unknown SUID binary(ies)"
        ((total_issues += suid_count))
    else
        print_success "Only known SUID binaries found"
    fi
    
    # No owner files
    print_section "Files Without Owner"
    local noowner=$(find / -nouser -o -nogroup 2>/dev/null | grep -v "^/proc\|^/sys" | wc -l)
    if [[ $noowner -gt 0 ]]; then
        print_warning "Found $noowner file(s) without owner"
        ((total_issues += noowner))
    else
        print_success "All files have valid owners"
    fi
    
    # Critical file permissions
    print_section "Critical File Permissions"
    for file in /etc/passwd /etc/shadow /etc/sudoers; do
        if [[ -f "$file" ]]; then
            PERMS=$(stat -c '%a' "$file" 2>/dev/null)
            if [[ $((0$PERMS & 0002)) -ne 0 ]]; then
                print_found "$file is world-writable!"
                ((total_issues++))
            fi
        fi
    done
    print_success "Critical files checked"
    
    # Home directories
    print_section "Home Directory Permissions"
    local home_issues=0
    for dir in /home/*/; do
        PERMS=$(stat -c '%a' "$dir" 2>/dev/null)
        if [[ $((0$PERMS & 0007)) -ne 0 ]]; then
            ((home_issues++))
        fi
    done
    if [[ $home_issues -gt 0 ]]; then
        print_warning "$home_issues home directory(ies) too permissive"
        ((total_issues += home_issues))
    else
        print_success "Home directories have proper permissions"
    fi
    
    # Summary
    print_section "AUDIT SUMMARY"
    echo ""
    if [[ $total_issues -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}No security issues found!${NC}"
    else
        echo -e "  ${RED}${BOLD}Found $total_issues potential security issue(s)${NC}"
        echo ""
        echo -e "  ${DIM}Run individual scans for details, or use 'Fix Common Issues'${NC}"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Fix Common Issues
#-------------------------------------------------------------------------------

fix_common_issues() {
    clear_screen
    print_header "FIX COMMON ISSUES"
    
    if [[ $EUID -ne 0 ]]; then
        print_error "This function requires root privileges"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${CYAN}Select what to fix:${NC}"
    echo ""
    echo -e "  ${WHITE}1.${NC} Fix home directory permissions (set to 750)"
    echo -e "  ${WHITE}2.${NC} Fix SSH directory permissions"
    echo -e "  ${WHITE}3.${NC} Fix /tmp and /var/tmp sticky bit"
    echo -e "  ${WHITE}4.${NC} Remove world-writable from files in /home"
    echo -e "  ${WHITE}5.${NC} Fix critical system file permissions"
    echo -e "  ${WHITE}6.${NC} Assign orphaned files to root"
    echo -e "  ${WHITE}A.${NC} Apply all fixes"
    echo ""
    echo -e "  ${WHITE}M.${NC} Main Menu"
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    case $CHOICE in
        1)
            echo ""
            echo -e "  ${YELLOW}Fixing home directory permissions...${NC}"
            for dir in /home/*/; do
                USER=$(basename "$dir")
                chmod 750 "$dir" && print_success "Fixed $dir"
                chown "$USER:$USER" "$dir" 2>/dev/null
            done
            press_any_key
            ;;
        2)
            echo ""
            echo -e "  ${YELLOW}Fixing SSH permissions...${NC}"
            for homedir in /home/*/; do
                USER=$(basename "$homedir")
                SSH_DIR="${homedir}.ssh"
                if [[ -d "$SSH_DIR" ]]; then
                    chmod 700 "$SSH_DIR"
                    chown -R "$USER:$USER" "$SSH_DIR"
                    [[ -f "$SSH_DIR/authorized_keys" ]] && chmod 600 "$SSH_DIR/authorized_keys"
                    for key in "$SSH_DIR"/id_*; do
                        [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]] && chmod 600 "$key"
                    done
                    print_success "Fixed $SSH_DIR"
                fi
            done
            press_any_key
            ;;
        3)
            echo ""
            echo -e "  ${YELLOW}Setting sticky bit on temp directories...${NC}"
            chmod 1777 /tmp && print_success "Fixed /tmp"
            chmod 1777 /var/tmp && print_success "Fixed /var/tmp"
            press_any_key
            ;;
        4)
            echo ""
            echo -e "  ${YELLOW}Removing world-writable from /home files...${NC}"
            find /home -type f -perm -0002 -exec chmod o-w {} \; 2>/dev/null
            print_success "Removed world-writable permissions from files in /home"
            press_any_key
            ;;
        5)
            echo ""
            echo -e "  ${YELLOW}Fixing critical system file permissions...${NC}"
            chmod 644 /etc/passwd && print_success "/etc/passwd set to 644"
            chmod 640 /etc/shadow && print_success "/etc/shadow set to 640"
            chmod 644 /etc/group && print_success "/etc/group set to 644"
            chmod 640 /etc/gshadow 2>/dev/null && print_success "/etc/gshadow set to 640"
            [[ -f /etc/sudoers ]] && chmod 440 /etc/sudoers && print_success "/etc/sudoers set to 440"
            press_any_key
            ;;
        6)
            echo ""
            print_warning "This will assign all orphaned files to root:root"
            if confirm_action; then
                echo -e "  ${YELLOW}Fixing orphaned files...${NC}"
                find / -nouser -exec chown root {} \; 2>/dev/null
                find / -nogroup -exec chgrp root {} \; 2>/dev/null
                print_success "Orphaned files assigned to root"
            fi
            press_any_key
            ;;
        a|A)
            echo ""
            print_warning "This will apply all fixes"
            if confirm_action; then
                echo ""
                echo -e "  ${YELLOW}Applying all fixes...${NC}"
                echo ""
                
                # Home directories
                for dir in /home/*/; do
                    USER=$(basename "$dir")
                    chmod 750 "$dir"
                    chown "$USER:$USER" "$dir" 2>/dev/null
                done
                print_success "Fixed home directories"
                
                # SSH directories
                for homedir in /home/*/; do
                    USER=$(basename "$homedir")
                    SSH_DIR="${homedir}.ssh"
                    if [[ -d "$SSH_DIR" ]]; then
                        chmod 700 "$SSH_DIR"
                        chown -R "$USER:$USER" "$SSH_DIR"
                        [[ -f "$SSH_DIR/authorized_keys" ]] && chmod 600 "$SSH_DIR/authorized_keys"
                        for key in "$SSH_DIR"/id_*; do
                            [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]] && chmod 600 "$key"
                        done
                    fi
                done
                print_success "Fixed SSH permissions"
                
                # Temp directories
                chmod 1777 /tmp /var/tmp
                print_success "Fixed temp directories"
                
                # World-writable in home
                find /home -type f -perm -0002 -exec chmod o-w {} \; 2>/dev/null
                print_success "Fixed world-writable files in /home"
                
                # Critical files
                chmod 644 /etc/passwd /etc/group
                chmod 640 /etc/shadow /etc/gshadow 2>/dev/null
                [[ -f /etc/sudoers ]] && chmod 440 /etc/sudoers
                print_success "Fixed critical system files"
                
                echo ""
                print_success "All fixes applied!"
            fi
            press_any_key
            ;;
        m|M) return ;;
    esac
}

#-------------------------------------------------------------------------------
# Save Audit Report
#-------------------------------------------------------------------------------

save_audit_report() {
    clear_screen
    print_header "SAVE AUDIT REPORT"
    
    echo ""
    FILENAME=$(get_input "Filename (Enter for default)")
    [[ -z "$FILENAME" ]] && FILENAME="permission-audit-$(date +%Y%m%d-%H%M%S).txt"
    [[ "$FILENAME" != *.txt ]] && FILENAME="${FILENAME}.txt"
    
    echo ""
    echo -e "  ${YELLOW}Generating report...${NC}"
    
    {
        echo "PERMISSION AUDIT REPORT"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "========================================"
        echo ""
        
        echo "=== WORLD-WRITABLE FILES ==="
        find /home /var/www /tmp /var/tmp /opt -type f -perm -0002 2>/dev/null | head -100
        echo ""
        
        echo "=== WORLD-WRITABLE DIRECTORIES (no sticky bit) ==="
        find / -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -v "^/proc\|^/sys\|^/run" | head -50
        echo ""
        
        echo "=== SUID BINARIES ==="
        find / -type f -perm -4000 2>/dev/null | grep -v "^/proc\|^/sys"
        echo ""
        
        echo "=== SGID BINARIES ==="
        find / -type f -perm -2000 2>/dev/null | grep -v "^/proc\|^/sys"
        echo ""
        
        echo "=== FILES WITHOUT OWNER ==="
        find / -nouser -o -nogroup 2>/dev/null | grep -v "^/proc\|^/sys" | head -50
        echo ""
        
        echo "=== HOME DIRECTORY PERMISSIONS ==="
        for dir in /home/*/; do
            stat -c '%a %U:%G %n' "$dir" 2>/dev/null
        done
        echo ""
        
        echo "=== CRITICAL FILE PERMISSIONS ==="
        for file in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers; do
            [[ -f "$file" ]] && stat -c '%a %U:%G %n' "$file" 2>/dev/null
        done
        
    } > "$FILENAME" 2>&1
    
    print_success "Report saved to: $FILENAME"
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

show_main_menu
