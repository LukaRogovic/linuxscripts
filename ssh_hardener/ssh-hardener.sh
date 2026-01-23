#!/bin/bash

#===============================================================================
# SSH HARDENER - TERMINAL UI
# Secure your SSH server configuration
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

# SSH Config file
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_CONFIG_BACKUP="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"

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

print_item() {
    printf "  ${GREEN}%-32s${NC} : %s\n" "$1" "$2"
}

print_item_warn() {
    printf "  ${YELLOW}%-32s${NC} : %s\n" "$1" "$2"
}

print_item_error() {
    printf "  ${RED}%-32s${NC} : %s\n" "$1" "$2"
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

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
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

get_sshd_value() {
    local key="$1"
    local value=$(grep -E "^${key}\s+" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}' | tail -1)
    if [[ -z "$value" ]]; then
        # Check for commented default
        value=$(grep -E "^#${key}\s+" "$SSHD_CONFIG" 2>/dev/null | awk '{print $2}' | tail -1)
        [[ -n "$value" ]] && value="${value} (default)"
    fi
    echo "${value:-not set}"
}

set_sshd_value() {
    local key="$1"
    local value="$2"
    
    # Remove any existing entries (commented or not)
    sed -i "/^#*${key}\s/d" "$SSHD_CONFIG"
    
    # Add new value
    echo "${key} ${value}" >> "$SSHD_CONFIG"
}

backup_sshd_config() {
    if [[ -f "$SSHD_CONFIG" ]]; then
        cp "$SSHD_CONFIG" "$SSHD_CONFIG_BACKUP"
        print_success "Backup created: $SSHD_CONFIG_BACKUP"
        return 0
    else
        print_error "SSH config not found at $SSHD_CONFIG"
        return 1
    fi
}

restart_sshd() {
    echo ""
    echo -e "  ${YELLOW}Restarting SSH service...${NC}"
    
    if systemctl restart sshd 2>/dev/null; then
        print_success "SSH service restarted (sshd)"
    elif systemctl restart ssh 2>/dev/null; then
        print_success "SSH service restarted (ssh)"
    elif service sshd restart 2>/dev/null; then
        print_success "SSH service restarted (sshd)"
    elif service ssh restart 2>/dev/null; then
        print_success "SSH service restarted (ssh)"
    else
        print_error "Failed to restart SSH service"
        return 1
    fi
    return 0
}

test_sshd_config() {
    echo ""
    echo -e "  ${YELLOW}Testing SSH configuration...${NC}"
    
    if sshd -t 2>/dev/null; then
        print_success "Configuration is valid"
        return 0
    else
        print_error "Configuration has errors!"
        sshd -t
        return 1
    fi
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
        echo "║                         ███████╗███████╗██╗  ██╗                           ║"
        echo "║                         ██╔════╝██╔════╝██║  ██║                           ║"
        echo "║                         ███████╗███████╗███████║                           ║"
        echo "║                         ╚════██║╚════██║██╔══██║                           ║"
        echo "║                         ███████║███████║██║  ██║                           ║"
        echo "║                         ╚══════╝╚══════╝╚═╝  ╚═╝                           ║"
        echo "║                                                                            ║"
        echo "║                                hardener                                    ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com -                   ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        # Quick status
        if [[ -f "$SSHD_CONFIG" ]]; then
            PORT=$(get_sshd_value "Port")
            ROOT_LOGIN=$(get_sshd_value "PermitRootLogin")
            PASS_AUTH=$(get_sshd_value "PasswordAuthentication")
            echo -e "  ${DIM}Current Status:${NC}"
            echo -e "  Port: ${WHITE}${PORT}${NC} | Root Login: ${WHITE}${ROOT_LOGIN}${NC} | Password Auth: ${WHITE}${PASS_AUTH}${NC}"
        fi
        echo ""
        
        echo -e "${WHITE}  Select an option:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}View Current SSH Configuration${NC}                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Change SSH Port${NC}                                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Configure Root Login${NC}                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Configure Password Authentication${NC}                                   ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Configure Key Authentication${NC}                                        ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Generate SSH Key Pair${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Add Authorized Key${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Security Tweaks${NC}                                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Login Restrictions${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} A.${NC} ${YELLOW}Apply Hardening Preset (Recommended)${NC}                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} B.${NC} ${YELLOW}Backup Current Config${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} R.${NC} ${YELLOW}Restore from Backup${NC}                                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} T.${NC} ${YELLOW}Test Configuration${NC}                                                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) view_config ;;
            2) change_port ;;
            3) configure_root_login ;;
            4) configure_password_auth ;;
            5) configure_key_auth ;;
            6) generate_ssh_key ;;
            7) add_authorized_key ;;
            8) security_tweaks ;;
            9) login_restrictions ;;
            a|A) apply_hardening_preset ;;
            b|B) check_root && backup_sshd_config; press_any_key ;;
            r|R) restore_backup ;;
            t|T) check_root && test_sshd_config; press_any_key ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using SSH Hardener!${NC}"
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
# View Current Configuration
#-------------------------------------------------------------------------------

view_config() {
    while true; do
        clear_screen
        print_header "CURRENT SSH CONFIGURATION"
        
        if [[ ! -f "$SSHD_CONFIG" ]]; then
            print_error "SSH config not found at $SSHD_CONFIG"
            press_any_key
            return
        fi
        
        print_section "Connection Settings"
        print_item "Port" "$(get_sshd_value 'Port')"
        print_item "AddressFamily" "$(get_sshd_value 'AddressFamily')"
        print_item "ListenAddress" "$(get_sshd_value 'ListenAddress')"
        
        print_section "Authentication"
        ROOT_LOGIN=$(get_sshd_value 'PermitRootLogin')
        PASS_AUTH=$(get_sshd_value 'PasswordAuthentication')
        PUBKEY_AUTH=$(get_sshd_value 'PubkeyAuthentication')
        
        if [[ "$ROOT_LOGIN" == "yes" ]]; then
            print_item_error "PermitRootLogin" "$ROOT_LOGIN (INSECURE)"
        elif [[ "$ROOT_LOGIN" == "prohibit-password" ]]; then
            print_item_warn "PermitRootLogin" "$ROOT_LOGIN (key only)"
        else
            print_item "PermitRootLogin" "$ROOT_LOGIN"
        fi
        
        if [[ "$PASS_AUTH" == "yes" ]]; then
            print_item_warn "PasswordAuthentication" "$PASS_AUTH (consider disabling)"
        else
            print_item "PasswordAuthentication" "$PASS_AUTH"
        fi
        
        print_item "PubkeyAuthentication" "$PUBKEY_AUTH"
        print_item "PermitEmptyPasswords" "$(get_sshd_value 'PermitEmptyPasswords')"
        print_item "ChallengeResponseAuth" "$(get_sshd_value 'ChallengeResponseAuthentication')"
        
        print_section "Security Settings"
        print_item "Protocol" "$(get_sshd_value 'Protocol')"
        print_item "X11Forwarding" "$(get_sshd_value 'X11Forwarding')"
        print_item "MaxAuthTries" "$(get_sshd_value 'MaxAuthTries')"
        print_item "MaxSessions" "$(get_sshd_value 'MaxSessions')"
        print_item "LoginGraceTime" "$(get_sshd_value 'LoginGraceTime')"
        print_item "ClientAliveInterval" "$(get_sshd_value 'ClientAliveInterval')"
        print_item "ClientAliveCountMax" "$(get_sshd_value 'ClientAliveCountMax')"
        
        print_section "Access Control"
        print_item "AllowUsers" "$(get_sshd_value 'AllowUsers')"
        print_item "AllowGroups" "$(get_sshd_value 'AllowGroups')"
        print_item "DenyUsers" "$(get_sshd_value 'DenyUsers')"
        print_item "DenyGroups" "$(get_sshd_value 'DenyGroups')"
        
        print_section "SSH Service Status"
        if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
            print_item "Service Status" "${GREEN}Running${NC}"
        else
            print_item_error "Service Status" "Not running"
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Change SSH Port
#-------------------------------------------------------------------------------

change_port() {
    clear_screen
    print_header "CHANGE SSH PORT"
    
    check_root || { press_any_key; return; }
    
    CURRENT_PORT=$(get_sshd_value 'Port')
    print_item "Current Port" "$CURRENT_PORT"
    
    echo ""
    echo -e "  ${DIM}Recommended: Use a port above 1024 and below 65535${NC}"
    echo -e "  ${DIM}Common alternatives: 2222, 22222, 2200${NC}"
    echo ""
    
    NEW_PORT=$(get_input "Enter new port number")
    
    if [[ ! "$NEW_PORT" =~ ^[0-9]+$ ]] || [[ "$NEW_PORT" -lt 1 ]] || [[ "$NEW_PORT" -gt 65535 ]]; then
        print_error "Invalid port number"
        press_any_key
        return
    fi
    
    # Check if port is in use
    if ss -tuln | grep -q ":${NEW_PORT}\s"; then
        print_warning "Port $NEW_PORT appears to be in use"
        confirm_action || { press_any_key; return; }
    fi
    
    backup_sshd_config
    set_sshd_value "Port" "$NEW_PORT"
    
    if test_sshd_config; then
        echo ""
        print_warning "IMPORTANT: Update your firewall before restarting SSH!"
        echo -e "  ${DIM}UFW: sudo ufw allow ${NEW_PORT}/tcp${NC}"
        echo -e "  ${DIM}firewalld: sudo firewall-cmd --permanent --add-port=${NEW_PORT}/tcp${NC}"
        echo ""
        echo -ne "  ${WHITE}Restart SSH now? [y/N]: ${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            restart_sshd
        fi
    else
        print_error "Configuration test failed. Restoring backup..."
        cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Configure Root Login
#-------------------------------------------------------------------------------

configure_root_login() {
    clear_screen
    print_header "CONFIGURE ROOT LOGIN"
    
    check_root || { press_any_key; return; }
    
    CURRENT=$(get_sshd_value 'PermitRootLogin')
    print_item "Current Setting" "$CURRENT"
    
    echo ""
    echo -e "  ${CYAN}Options:${NC}"
    echo -e "  ${WHITE}1.${NC} no               - ${GREEN}Disable root login completely (RECOMMENDED)${NC}"
    echo -e "  ${WHITE}2.${NC} prohibit-password - Root login with SSH key only"
    echo -e "  ${WHITE}3.${NC} yes              - ${RED}Allow root login with password (INSECURE)${NC}"
    echo ""
    
    CHOICE=$(get_input "Select option (1-3)")
    
    case $CHOICE in
        1) VALUE="no" ;;
        2) VALUE="prohibit-password" ;;
        3) 
            print_warning "This is not recommended for security!"
            confirm_action || { press_any_key; return; }
            VALUE="yes"
            ;;
        *) print_error "Invalid choice"; press_any_key; return ;;
    esac
    
    backup_sshd_config
    set_sshd_value "PermitRootLogin" "$VALUE"
    
    if test_sshd_config; then
        print_success "PermitRootLogin set to: $VALUE"
        echo ""
        echo -ne "  ${WHITE}Restart SSH to apply? [y/N]: ${NC}"
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] && restart_sshd
    else
        print_error "Configuration test failed. Restoring backup..."
        cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Configure Password Authentication
#-------------------------------------------------------------------------------

configure_password_auth() {
    clear_screen
    print_header "CONFIGURE PASSWORD AUTHENTICATION"
    
    check_root || { press_any_key; return; }
    
    CURRENT=$(get_sshd_value 'PasswordAuthentication')
    print_item "Current Setting" "$CURRENT"
    
    echo ""
    echo -e "  ${CYAN}Options:${NC}"
    echo -e "  ${WHITE}1.${NC} no  - ${GREEN}Disable password auth (key-only, RECOMMENDED)${NC}"
    echo -e "  ${WHITE}2.${NC} yes - Allow password authentication"
    echo ""
    
    print_warning "Before disabling passwords, ensure you have SSH key access!"
    echo ""
    
    CHOICE=$(get_input "Select option (1-2)")
    
    case $CHOICE in
        1) 
            echo ""
            print_warning "Make sure you have added your SSH key to authorized_keys!"
            confirm_action || { press_any_key; return; }
            VALUE="no"
            ;;
        2) VALUE="yes" ;;
        *) print_error "Invalid choice"; press_any_key; return ;;
    esac
    
    backup_sshd_config
    set_sshd_value "PasswordAuthentication" "$VALUE"
    
    # Also disable ChallengeResponseAuthentication if disabling passwords
    if [[ "$VALUE" == "no" ]]; then
        set_sshd_value "ChallengeResponseAuthentication" "no"
        set_sshd_value "UsePAM" "no"
    fi
    
    if test_sshd_config; then
        print_success "PasswordAuthentication set to: $VALUE"
        echo ""
        echo -ne "  ${WHITE}Restart SSH to apply? [y/N]: ${NC}"
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] && restart_sshd
    else
        print_error "Configuration test failed. Restoring backup..."
        cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Configure Key Authentication
#-------------------------------------------------------------------------------

configure_key_auth() {
    clear_screen
    print_header "CONFIGURE KEY AUTHENTICATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Current Settings"
    print_item "PubkeyAuthentication" "$(get_sshd_value 'PubkeyAuthentication')"
    print_item "AuthorizedKeysFile" "$(get_sshd_value 'AuthorizedKeysFile')"
    
    echo ""
    echo -e "  ${CYAN}Options:${NC}"
    echo -e "  ${WHITE}1.${NC} Enable public key authentication"
    echo -e "  ${WHITE}2.${NC} Disable public key authentication"
    echo ""
    
    CHOICE=$(get_input "Select option (1-2)")
    
    case $CHOICE in
        1) VALUE="yes" ;;
        2) 
            print_warning "Disabling key auth may lock you out if password auth is also disabled!"
            confirm_action || { press_any_key; return; }
            VALUE="no"
            ;;
        *) print_error "Invalid choice"; press_any_key; return ;;
    esac
    
    backup_sshd_config
    set_sshd_value "PubkeyAuthentication" "$VALUE"
    
    if test_sshd_config; then
        print_success "PubkeyAuthentication set to: $VALUE"
        echo ""
        echo -ne "  ${WHITE}Restart SSH to apply? [y/N]: ${NC}"
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] && restart_sshd
    else
        print_error "Configuration test failed. Restoring backup..."
        cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Generate SSH Key Pair
#-------------------------------------------------------------------------------

generate_ssh_key() {
    clear_screen
    print_header "GENERATE SSH KEY PAIR"
    
    echo ""
    echo -e "  ${CYAN}Key Types:${NC}"
    echo -e "  ${WHITE}1.${NC} ed25519  - ${GREEN}Modern, secure, fast (RECOMMENDED)${NC}"
    echo -e "  ${WHITE}2.${NC} rsa 4096 - Compatible with older systems"
    echo -e "  ${WHITE}3.${NC} ecdsa    - NIST curves"
    echo ""
    
    CHOICE=$(get_input "Select key type (1-3)")
    
    case $CHOICE in
        1) KEY_TYPE="ed25519"; KEY_OPTS="-t ed25519" ;;
        2) KEY_TYPE="rsa"; KEY_OPTS="-t rsa -b 4096" ;;
        3) KEY_TYPE="ecdsa"; KEY_OPTS="-t ecdsa -b 521" ;;
        *) print_error "Invalid choice"; press_any_key; return ;;
    esac
    
    # Get key file location
    DEFAULT_FILE="$HOME/.ssh/id_${KEY_TYPE}"
    echo ""
    echo -e "  ${DIM}Default location: $DEFAULT_FILE${NC}"
    KEY_FILE=$(get_input "Key file path (Enter for default)")
    [[ -z "$KEY_FILE" ]] && KEY_FILE="$DEFAULT_FILE"
    
    # Check if file exists
    if [[ -f "$KEY_FILE" ]]; then
        print_warning "Key file already exists: $KEY_FILE"
        confirm_action || { press_any_key; return; }
    fi
    
    # Create .ssh directory if needed
    mkdir -p "$(dirname "$KEY_FILE")"
    chmod 700 "$(dirname "$KEY_FILE")"
    
    # Get comment
    COMMENT=$(get_input "Comment (e.g., your@email.com)")
    [[ -n "$COMMENT" ]] && KEY_OPTS="$KEY_OPTS -C \"$COMMENT\""
    
    echo ""
    echo -e "  ${YELLOW}Generating key...${NC}"
    echo ""
    
    # Generate key
    eval ssh-keygen $KEY_OPTS -f "$KEY_FILE"
    
    if [[ $? -eq 0 ]]; then
        echo ""
        print_success "Key pair generated successfully!"
        echo ""
        echo -e "  ${CYAN}Private key:${NC} $KEY_FILE"
        echo -e "  ${CYAN}Public key:${NC}  ${KEY_FILE}.pub"
        echo ""
        echo -e "  ${YELLOW}Public key content (copy this to remote server):${NC}"
        echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
        cat "${KEY_FILE}.pub"
        echo -e "  ${DIM}─────────────────────────────────────────────────${NC}"
    else
        print_error "Failed to generate key"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Add Authorized Key
#-------------------------------------------------------------------------------

add_authorized_key() {
    clear_screen
    print_header "ADD AUTHORIZED KEY"
    
    echo ""
    echo -e "  ${CYAN}Select user to add key for:${NC}"
    echo -e "  ${DIM}─────────────────────────────${NC}"
    
    # List users
    local users=()
    local i=1
    while IFS=: read -r username _ uid _ _ home shell; do
        if [[ $uid -ge 1000 && $uid -lt 65534 && -d "$home" ]]; then
            users+=("$username:$home")
            echo -e "  ${WHITE}$i.${NC} $username ($home)"
            ((i++))
        fi
    done < /etc/passwd
    
    # Add root option
    users+=("root:/root")
    echo -e "  ${WHITE}$i.${NC} root (/root)"
    
    echo ""
    SELECTION=$(get_input "Select user number")
    
    if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [[ $SELECTION -ge 1 ]] && [[ $SELECTION -le ${#users[@]} ]]; then
        IFS=: read -r USERNAME HOMEDIR <<< "${users[$((SELECTION-1))]}"
    else
        print_error "Invalid selection"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${CYAN}Adding key for user: ${WHITE}$USERNAME${NC}"
    
    # Create .ssh directory
    SSH_DIR="$HOMEDIR/.ssh"
    AUTH_KEYS="$SSH_DIR/authorized_keys"
    
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    chown -R "$USERNAME:$USERNAME" "$SSH_DIR" 2>/dev/null || chown -R "$USERNAME" "$SSH_DIR"
    
    echo ""
    echo -e "  ${CYAN}Enter public key (paste the entire line):${NC}"
    echo -ne "  "
    read -r PUBLIC_KEY
    
    if [[ -z "$PUBLIC_KEY" ]]; then
        print_error "No key provided"
        press_any_key
        return
    fi
    
    # Validate key format
    if [[ ! "$PUBLIC_KEY" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2|ssh-dss) ]]; then
        print_warning "Key doesn't appear to be in standard format"
        confirm_action || { press_any_key; return; }
    fi
    
    # Check if key already exists
    if grep -qF "$PUBLIC_KEY" "$AUTH_KEYS" 2>/dev/null; then
        print_warning "This key already exists in authorized_keys"
        press_any_key
        return
    fi
    
    # Add key
    echo "$PUBLIC_KEY" >> "$AUTH_KEYS"
    chown "$USERNAME:$USERNAME" "$AUTH_KEYS" 2>/dev/null || chown "$USERNAME" "$AUTH_KEYS"
    
    print_success "Key added to $AUTH_KEYS"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Security Tweaks
#-------------------------------------------------------------------------------

security_tweaks() {
    while true; do
        clear_screen
        print_header "SECURITY TWEAKS"
        
        check_root || { press_any_key; return; }
        
        print_section "Current Settings"
        print_item "X11Forwarding" "$(get_sshd_value 'X11Forwarding')"
        print_item "MaxAuthTries" "$(get_sshd_value 'MaxAuthTries')"
        print_item "MaxSessions" "$(get_sshd_value 'MaxSessions')"
        print_item "LoginGraceTime" "$(get_sshd_value 'LoginGraceTime')"
        print_item "PermitEmptyPasswords" "$(get_sshd_value 'PermitEmptyPasswords')"
        print_item "ClientAliveInterval" "$(get_sshd_value 'ClientAliveInterval')"
        print_item "ClientAliveCountMax" "$(get_sshd_value 'ClientAliveCountMax')"
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Disable X11 Forwarding"
        echo -e "  ${WHITE}2.${NC} Set Max Auth Tries (default: 6)"
        echo -e "  ${WHITE}3.${NC} Set Max Sessions (default: 10)"
        echo -e "  ${WHITE}4.${NC} Set Login Grace Time"
        echo -e "  ${WHITE}5.${NC} Disable Empty Passwords"
        echo -e "  ${WHITE}6.${NC} Set Client Alive Interval (idle timeout)"
        echo -e "  ${WHITE}7.${NC} Apply all security tweaks"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu"
        echo ""
        
        CHOICE=$(get_input "Select option")
        
        case $CHOICE in
            1)
                backup_sshd_config
                set_sshd_value "X11Forwarding" "no"
                test_sshd_config && print_success "X11Forwarding disabled"
                press_any_key
                ;;
            2)
                TRIES=$(get_input "Max auth tries (recommended: 3)")
                if [[ "$TRIES" =~ ^[0-9]+$ ]]; then
                    backup_sshd_config
                    set_sshd_value "MaxAuthTries" "$TRIES"
                    test_sshd_config && print_success "MaxAuthTries set to $TRIES"
                fi
                press_any_key
                ;;
            3)
                SESSIONS=$(get_input "Max sessions (recommended: 2)")
                if [[ "$SESSIONS" =~ ^[0-9]+$ ]]; then
                    backup_sshd_config
                    set_sshd_value "MaxSessions" "$SESSIONS"
                    test_sshd_config && print_success "MaxSessions set to $SESSIONS"
                fi
                press_any_key
                ;;
            4)
                GRACE=$(get_input "Login grace time in seconds (recommended: 30)")
                if [[ "$GRACE" =~ ^[0-9]+$ ]]; then
                    backup_sshd_config
                    set_sshd_value "LoginGraceTime" "$GRACE"
                    test_sshd_config && print_success "LoginGraceTime set to $GRACE"
                fi
                press_any_key
                ;;
            5)
                backup_sshd_config
                set_sshd_value "PermitEmptyPasswords" "no"
                test_sshd_config && print_success "Empty passwords disabled"
                press_any_key
                ;;
            6)
                INTERVAL=$(get_input "Client alive interval in seconds (e.g., 300)")
                COUNT=$(get_input "Client alive count max (e.g., 2)")
                if [[ "$INTERVAL" =~ ^[0-9]+$ ]] && [[ "$COUNT" =~ ^[0-9]+$ ]]; then
                    backup_sshd_config
                    set_sshd_value "ClientAliveInterval" "$INTERVAL"
                    set_sshd_value "ClientAliveCountMax" "$COUNT"
                    test_sshd_config && print_success "Idle timeout configured"
                fi
                press_any_key
                ;;
            7)
                backup_sshd_config
                set_sshd_value "X11Forwarding" "no"
                set_sshd_value "MaxAuthTries" "3"
                set_sshd_value "MaxSessions" "2"
                set_sshd_value "LoginGraceTime" "30"
                set_sshd_value "PermitEmptyPasswords" "no"
                set_sshd_value "ClientAliveInterval" "300"
                set_sshd_value "ClientAliveCountMax" "2"
                set_sshd_value "AllowAgentForwarding" "no"
                set_sshd_value "AllowTcpForwarding" "no"
                if test_sshd_config; then
                    print_success "All security tweaks applied!"
                    echo ""
                    echo -ne "  ${WHITE}Restart SSH to apply? [y/N]: ${NC}"
                    read -r response
                    [[ "$response" =~ ^[Yy]$ ]] && restart_sshd
                fi
                press_any_key
                ;;
            m|M) return ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Login Restrictions
#-------------------------------------------------------------------------------

login_restrictions() {
    while true; do
        clear_screen
        print_header "LOGIN RESTRICTIONS"
        
        check_root || { press_any_key; return; }
        
        print_section "Current Restrictions"
        print_item "AllowUsers" "$(get_sshd_value 'AllowUsers')"
        print_item "AllowGroups" "$(get_sshd_value 'AllowGroups')"
        print_item "DenyUsers" "$(get_sshd_value 'DenyUsers')"
        print_item "DenyGroups" "$(get_sshd_value 'DenyGroups')"
        
        print_section "Actions"
        echo -e "  ${WHITE}1.${NC} Allow specific users only"
        echo -e "  ${WHITE}2.${NC} Allow specific group only"
        echo -e "  ${WHITE}3.${NC} Deny specific users"
        echo -e "  ${WHITE}4.${NC} Deny specific group"
        echo -e "  ${WHITE}5.${NC} Remove all restrictions"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu"
        echo ""
        
        CHOICE=$(get_input "Select option")
        
        case $CHOICE in
            1)
                echo ""
                echo -e "  ${DIM}Current users on system:${NC}"
                awk -F: '$3 >= 1000 && $3 < 65534 {print "    " $1}' /etc/passwd
                echo ""
                USERS=$(get_input "Users to allow (space-separated)")
                if [[ -n "$USERS" ]]; then
                    backup_sshd_config
                    set_sshd_value "AllowUsers" "$USERS"
                    test_sshd_config && print_success "AllowUsers set to: $USERS"
                fi
                press_any_key
                ;;
            2)
                echo ""
                echo -e "  ${DIM}Example groups: sudo, wheel, ssh${NC}"
                GROUP=$(get_input "Group to allow")
                if [[ -n "$GROUP" ]]; then
                    backup_sshd_config
                    set_sshd_value "AllowGroups" "$GROUP"
                    test_sshd_config && print_success "AllowGroups set to: $GROUP"
                fi
                press_any_key
                ;;
            3)
                USERS=$(get_input "Users to deny (space-separated)")
                if [[ -n "$USERS" ]]; then
                    backup_sshd_config
                    set_sshd_value "DenyUsers" "$USERS"
                    test_sshd_config && print_success "DenyUsers set to: $USERS"
                fi
                press_any_key
                ;;
            4)
                GROUP=$(get_input "Group to deny")
                if [[ -n "$GROUP" ]]; then
                    backup_sshd_config
                    set_sshd_value "DenyGroups" "$GROUP"
                    test_sshd_config && print_success "DenyGroups set to: $GROUP"
                fi
                press_any_key
                ;;
            5)
                backup_sshd_config
                sed -i '/^AllowUsers/d' "$SSHD_CONFIG"
                sed -i '/^AllowGroups/d' "$SSHD_CONFIG"
                sed -i '/^DenyUsers/d' "$SSHD_CONFIG"
                sed -i '/^DenyGroups/d' "$SSHD_CONFIG"
                test_sshd_config && print_success "All restrictions removed"
                press_any_key
                ;;
            m|M) return ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Apply Hardening Preset
#-------------------------------------------------------------------------------

apply_hardening_preset() {
    clear_screen
    print_header "APPLY HARDENING PRESET"
    
    check_root || { press_any_key; return; }
    
    echo ""
    echo -e "  ${CYAN}This will apply the following security settings:${NC}"
    echo ""
    echo -e "  ${WHITE}•${NC} Change SSH port to 2222"
    echo -e "  ${WHITE}•${NC} Disable root login"
    echo -e "  ${WHITE}•${NC} Enable public key authentication"
    echo -e "  ${WHITE}•${NC} Disable empty passwords"
    echo -e "  ${WHITE}•${NC} Set max auth tries to 3"
    echo -e "  ${WHITE}•${NC} Set login grace time to 30s"
    echo -e "  ${WHITE}•${NC} Disable X11 forwarding"
    echo -e "  ${WHITE}•${NC} Set idle timeout (5 min)"
    echo ""
    print_warning "Make sure you have SSH key access before applying!"
    print_warning "Remember to update your firewall for new port!"
    echo ""
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    # Ask about password auth
    echo ""
    echo -e "  ${CYAN}Disable password authentication?${NC}"
    echo -e "  ${DIM}(Only do this if you have SSH key access set up)${NC}"
    echo -ne "  ${WHITE}Disable passwords? [y/N]: ${NC}"
    read -r disable_pass
    
    # Backup
    backup_sshd_config
    
    echo ""
    echo -e "  ${YELLOW}Applying settings...${NC}"
    
    # Apply settings
    set_sshd_value "Port" "2222"
    set_sshd_value "PermitRootLogin" "no"
    set_sshd_value "PubkeyAuthentication" "yes"
    set_sshd_value "PermitEmptyPasswords" "no"
    set_sshd_value "MaxAuthTries" "3"
    set_sshd_value "MaxSessions" "2"
    set_sshd_value "LoginGraceTime" "30"
    set_sshd_value "X11Forwarding" "no"
    set_sshd_value "ClientAliveInterval" "300"
    set_sshd_value "ClientAliveCountMax" "2"
    set_sshd_value "AllowAgentForwarding" "no"
    set_sshd_value "AllowTcpForwarding" "no"
    
    if [[ "$disable_pass" =~ ^[Yy]$ ]]; then
        set_sshd_value "PasswordAuthentication" "no"
        set_sshd_value "ChallengeResponseAuthentication" "no"
    fi
    
    if test_sshd_config; then
        echo ""
        print_success "Hardening preset applied successfully!"
        echo ""
        echo -e "  ${YELLOW}IMPORTANT NEXT STEPS:${NC}"
        echo -e "  ${WHITE}1.${NC} Update firewall: ${DIM}sudo ufw allow 2222/tcp${NC}"
        echo -e "  ${WHITE}2.${NC} Test connection in new terminal before closing this one"
        echo -e "  ${WHITE}3.${NC} Use: ${DIM}ssh -p 2222 user@host${NC}"
        echo ""
        echo -ne "  ${WHITE}Restart SSH now? [y/N]: ${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            restart_sshd
            echo ""
            print_warning "Keep this session open! Test new connection first!"
        fi
    else
        print_error "Configuration test failed. Restoring backup..."
        cp "$SSHD_CONFIG_BACKUP" "$SSHD_CONFIG"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Restore Backup
#-------------------------------------------------------------------------------

restore_backup() {
    clear_screen
    print_header "RESTORE FROM BACKUP"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Backups"
    
    local backups=()
    local i=1
    
    for backup in /etc/ssh/sshd_config.backup.*; do
        if [[ -f "$backup" ]]; then
            backups+=("$backup")
            TIMESTAMP=$(echo "$backup" | grep -oP '\d{8}_\d{6}')
            echo -e "  ${WHITE}$i.${NC} $backup"
            ((i++))
        fi
    done
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_info "No backups found"
        press_any_key
        return
    fi
    
    echo ""
    SELECTION=$(get_input "Select backup to restore (number)")
    
    if [[ "$SELECTION" =~ ^[0-9]+$ ]] && [[ $SELECTION -ge 1 ]] && [[ $SELECTION -le ${#backups[@]} ]]; then
        BACKUP_FILE="${backups[$((SELECTION-1))]}"
        
        print_warning "This will overwrite current configuration!"
        if confirm_action; then
            cp "$BACKUP_FILE" "$SSHD_CONFIG"
            if test_sshd_config; then
                print_success "Configuration restored from $BACKUP_FILE"
                echo ""
                echo -ne "  ${WHITE}Restart SSH to apply? [y/N]: ${NC}"
                read -r response
                [[ "$response" =~ ^[Yy]$ ]] && restart_sshd
            fi
        fi
    else
        print_error "Invalid selection"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

# Check for SSH config
if [[ ! -f "$SSHD_CONFIG" ]]; then
    echo -e "${RED}Error: SSH config not found at $SSHD_CONFIG${NC}"
    echo -e "${YELLOW}Is OpenSSH server installed?${NC}"
    echo -e "${DIM}Install with: sudo apt install openssh-server${NC}"
    exit 1
fi

show_main_menu
