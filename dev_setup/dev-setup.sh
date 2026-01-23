#!/bin/bash

#===============================================================================
# DEV ENVIRONMENT SETUP - TERMINAL UI
# Interactive installer for development stacks
# Compatible with: Debian/Ubuntu-based distributions
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

# Log file
LOG_FILE="/tmp/dev-setup-$(date +%Y%m%d-%H%M%S).log"

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
    printf "  ${GREEN}%-25s${NC} : %s\n" "$1" "$2"
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

print_installing() {
    echo -e "  ${YELLOW}▶${NC} Installing $1..."
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -n 1 -s -r
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

run_cmd() {
    local cmd="$1"
    echo "$ $cmd" >> "$LOG_FILE"
    eval "$cmd" >> "$LOG_FILE" 2>&1
    return $?
}

update_apt() {
    echo -e "  ${YELLOW}Updating package lists...${NC}"
    apt-get update >> "$LOG_FILE" 2>&1
}

get_installed_version() {
    local cmd="$1"
    if cmd_exists "$cmd"; then
        $cmd --version 2>/dev/null | head -1
    else
        echo "Not installed"
    fi
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_main_menu() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${GREEN}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║             ██████╗ ███████╗██╗   ██╗                                      ║"
        echo "║             ██╔══██╗██╔════╝██║   ██║                                      ║"
        echo "║             ██║  ██║█████╗  ██║   ██║                                      ║"
        echo "║             ██║  ██║██╔══╝  ╚██╗ ██╔╝                                      ║"
        echo "║             ██████╔╝███████╗ ╚████╔╝                                       ║"
        echo "║             ╚═════╝ ╚══════╝  ╚═══╝                                        ║"
        echo "║                                                                            ║"
        echo "║                           SETUP WIZARD                                     ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com -                   ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${WHITE}  Select a development stack:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}LAMP Stack${NC}         (Linux, Apache, MySQL, PHP)                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}LEMP Stack${NC}         (Linux, Nginx, MySQL, PHP)                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Node.js${NC}            (Node.js, npm, nvm)                              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Python${NC}             (Python 3, pip, venv, pyenv)                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Docker${NC}             (Docker Engine, Docker Compose)                  ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Go (Golang)${NC}        (Go compiler and tools)                          ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}Rust${NC}               (Rust compiler, Cargo)                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Java${NC}               (OpenJDK, Maven, Gradle)                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Ruby${NC}               (Ruby, rbenv, Rails)                             ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}10.${NC} ${GREEN}.NET${NC}               (.NET SDK and runtime)                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}11.${NC} ${GREEN}Git & Tools${NC}        (Git, GitHub CLI, GitLab CLI)                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}12.${NC} ${GREEN}Databases${NC}          (MySQL, PostgreSQL, MongoDB, Redis)              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}13.${NC} ${GREEN}Code Editors${NC}       (VS Code, Neovim, Sublime)                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}14.${NC} ${GREEN}DevOps Tools${NC}       (Kubernetes, Terraform, Ansible)                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}15.${NC} ${GREEN}Cloud CLIs${NC}         (AWS, GCloud, Azure CLI)                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}16.${NC} ${GREEN}Terminal Tools${NC}     (tmux, htop, zsh, fzf)                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}17.${NC} ${GREEN}API Tools${NC}          (HTTPie, jq, Postman)                            ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} S.${NC} ${YELLOW}Show Installed Dev Tools${NC}                                            ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} L.${NC} ${YELLOW}View Installation Log${NC}                                               ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} U.${NC} ${RED}Uninstall Tools${NC}                                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) install_lamp ;;
            2) install_lemp ;;
            3) install_nodejs ;;
            4) install_python ;;
            5) install_docker ;;
            6) install_golang ;;
            7) install_rust ;;
            8) install_java ;;
            9) install_ruby ;;
            10) install_dotnet ;;
            11) install_git_tools ;;
            12) install_databases ;;
            13) install_editors ;;
            14) install_devops ;;
            15) install_cloud_cli ;;
            16) install_terminal_tools ;;
            17) install_api_tools ;;
            s|S) show_installed ;;
            l|L) view_log ;;
            u|U) show_uninstall_menu ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Dev Setup Wizard!${NC}"
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
# LAMP Stack
#-------------------------------------------------------------------------------

install_lamp() {
    clear_screen
    print_header "LAMP STACK INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Components"
    echo -e "  ${WHITE}•${NC} Apache2 Web Server"
    echo -e "  ${WHITE}•${NC} MySQL/MariaDB Database"
    echo -e "  ${WHITE}•${NC} PHP (with common extensions)"
    echo ""
    
    # PHP version selection
    print_section "PHP Version"
    echo -e "  ${WHITE}1.${NC} PHP 8.2 (Latest stable)"
    echo -e "  ${WHITE}2.${NC} PHP 8.1"
    echo -e "  ${WHITE}3.${NC} PHP 8.0"
    echo -e "  ${WHITE}4.${NC} PHP 7.4 (Legacy)"
    echo ""
    
    PHP_CHOICE=$(get_input "Select PHP version (1-4)")
    
    case $PHP_CHOICE in
        1) PHP_VER="8.2" ;;
        2) PHP_VER="8.1" ;;
        3) PHP_VER="8.0" ;;
        4) PHP_VER="7.4" ;;
        *) PHP_VER="8.2" ;;
    esac
    
    # Database selection
    print_section "Database"
    echo -e "  ${WHITE}1.${NC} MySQL 8.0"
    echo -e "  ${WHITE}2.${NC} MariaDB"
    echo ""
    
    DB_CHOICE=$(get_input "Select database (1-2)")
    
    echo ""
    print_warning "This will install Apache, PHP $PHP_VER, and database server"
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # Add PHP repository
    print_installing "PHP repository"
    run_cmd "apt-get install -y software-properties-common"
    run_cmd "add-apt-repository -y ppa:ondrej/php"
    run_cmd "apt-get update"
    
    # Install Apache
    print_installing "Apache2"
    run_cmd "apt-get install -y apache2"
    run_cmd "systemctl enable apache2"
    run_cmd "systemctl start apache2"
    print_success "Apache2 installed"
    
    # Install PHP
    print_installing "PHP $PHP_VER"
    run_cmd "apt-get install -y php${PHP_VER} php${PHP_VER}-cli php${PHP_VER}-common php${PHP_VER}-mysql php${PHP_VER}-xml php${PHP_VER}-curl php${PHP_VER}-gd php${PHP_VER}-mbstring php${PHP_VER}-zip php${PHP_VER}-bcmath php${PHP_VER}-intl libapache2-mod-php${PHP_VER}"
    print_success "PHP $PHP_VER installed"
    
    # Install Database
    if [[ "$DB_CHOICE" == "2" ]]; then
        print_installing "MariaDB"
        run_cmd "apt-get install -y mariadb-server mariadb-client"
        print_success "MariaDB installed"
    else
        print_installing "MySQL"
        run_cmd "apt-get install -y mysql-server mysql-client"
        print_success "MySQL installed"
    fi
    
    run_cmd "systemctl enable mysql"
    run_cmd "systemctl start mysql"
    
    # Install Composer
    print_installing "Composer"
    run_cmd "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"
    print_success "Composer installed"
    
    # Restart Apache
    run_cmd "systemctl restart apache2"
    
    print_section "Installation Complete"
    print_success "LAMP stack installed successfully!"
    echo ""
    print_info "Apache web root: /var/www/html"
    print_info "PHP version: $(php -v 2>/dev/null | head -1)"
    print_info "Run 'sudo mysql_secure_installation' to secure database"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# LEMP Stack
#-------------------------------------------------------------------------------

install_lemp() {
    clear_screen
    print_header "LEMP STACK INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Components"
    echo -e "  ${WHITE}•${NC} Nginx Web Server"
    echo -e "  ${WHITE}•${NC} MySQL/MariaDB Database"
    echo -e "  ${WHITE}•${NC} PHP-FPM"
    echo ""
    
    # PHP version selection
    print_section "PHP Version"
    echo -e "  ${WHITE}1.${NC} PHP 8.2 (Latest stable)"
    echo -e "  ${WHITE}2.${NC} PHP 8.1"
    echo -e "  ${WHITE}3.${NC} PHP 8.0"
    echo ""
    
    PHP_CHOICE=$(get_input "Select PHP version (1-3)")
    
    case $PHP_CHOICE in
        1) PHP_VER="8.2" ;;
        2) PHP_VER="8.1" ;;
        3) PHP_VER="8.0" ;;
        *) PHP_VER="8.2" ;;
    esac
    
    echo ""
    print_warning "This will install Nginx, PHP-FPM $PHP_VER, and MySQL"
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # Add PHP repository
    print_installing "PHP repository"
    run_cmd "apt-get install -y software-properties-common"
    run_cmd "add-apt-repository -y ppa:ondrej/php"
    run_cmd "apt-get update"
    
    # Install Nginx
    print_installing "Nginx"
    run_cmd "apt-get install -y nginx"
    run_cmd "systemctl enable nginx"
    run_cmd "systemctl start nginx"
    print_success "Nginx installed"
    
    # Install PHP-FPM
    print_installing "PHP-FPM $PHP_VER"
    run_cmd "apt-get install -y php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-common php${PHP_VER}-mysql php${PHP_VER}-xml php${PHP_VER}-curl php${PHP_VER}-gd php${PHP_VER}-mbstring php${PHP_VER}-zip php${PHP_VER}-bcmath php${PHP_VER}-intl"
    print_success "PHP-FPM $PHP_VER installed"
    
    # Install MySQL
    print_installing "MySQL"
    run_cmd "apt-get install -y mysql-server mysql-client"
    run_cmd "systemctl enable mysql"
    run_cmd "systemctl start mysql"
    print_success "MySQL installed"
    
    # Install Composer
    print_installing "Composer"
    run_cmd "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"
    print_success "Composer installed"
    
    print_section "Installation Complete"
    print_success "LEMP stack installed successfully!"
    echo ""
    print_info "Nginx web root: /var/www/html"
    print_info "PHP-FPM socket: /run/php/php${PHP_VER}-fpm.sock"
    print_info "Configure Nginx to use PHP-FPM"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Node.js
#-------------------------------------------------------------------------------

install_nodejs() {
    clear_screen
    print_header "NODE.JS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Installation Method"
    echo -e "  ${WHITE}1.${NC} NVM (Node Version Manager) - ${GREEN}Recommended${NC}"
    echo -e "  ${WHITE}2.${NC} NodeSource Repository (specific version)"
    echo -e "  ${WHITE}3.${NC} System package (apt)"
    echo ""
    
    METHOD=$(get_input "Select method (1-3)")
    
    case $METHOD in
        1)
            print_section "NVM Installation"
            echo ""
            print_info "NVM will be installed for user: $SUDO_USER"
            
            if ! confirm_action; then
                press_any_key
                return
            fi
            
            # Install NVM for the actual user
            print_installing "NVM"
            sudo -u "$SUDO_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash' >> "$LOG_FILE" 2>&1
            
            print_success "NVM installed"
            echo ""
            print_info "Run these commands as your normal user:"
            echo -e "  ${DIM}source ~/.bashrc${NC}"
            echo -e "  ${DIM}nvm install --lts${NC}"
            echo -e "  ${DIM}nvm use --lts${NC}"
            ;;
        2)
            print_section "Node.js Version"
            echo -e "  ${WHITE}1.${NC} Node.js 20 LTS (Latest LTS)"
            echo -e "  ${WHITE}2.${NC} Node.js 18 LTS"
            echo -e "  ${WHITE}3.${NC} Node.js 21 (Current)"
            echo ""
            
            VER_CHOICE=$(get_input "Select version (1-3)")
            
            case $VER_CHOICE in
                1) NODE_VER="20" ;;
                2) NODE_VER="18" ;;
                3) NODE_VER="21" ;;
                *) NODE_VER="20" ;;
            esac
            
            echo ""
            update_apt
            
            print_installing "NodeSource repository"
            run_cmd "apt-get install -y ca-certificates curl gnupg"
            run_cmd "mkdir -p /etc/apt/keyrings"
            run_cmd "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg"
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VER}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list >> "$LOG_FILE"
            run_cmd "apt-get update"
            
            print_installing "Node.js $NODE_VER"
            run_cmd "apt-get install -y nodejs"
            print_success "Node.js installed"
            ;;
        3)
            update_apt
            print_installing "Node.js (system package)"
            run_cmd "apt-get install -y nodejs npm"
            print_success "Node.js installed"
            ;;
        *)
            print_error "Invalid selection"
            press_any_key
            return
            ;;
    esac
    
    # Install common global packages
    echo ""
    echo -ne "  ${WHITE}Install common tools (yarn, pm2, nodemon)? [y/N]: ${NC}"
    read -r install_tools
    
    if [[ "$install_tools" =~ ^[Yy]$ ]]; then
        if cmd_exists npm; then
            print_installing "Yarn"
            run_cmd "npm install -g yarn"
            print_installing "PM2"
            run_cmd "npm install -g pm2"
            print_installing "Nodemon"
            run_cmd "npm install -g nodemon"
            print_success "Tools installed"
        fi
    fi
    
    print_section "Installation Complete"
    if cmd_exists node; then
        print_info "Node.js version: $(node --version 2>/dev/null)"
        print_info "npm version: $(npm --version 2>/dev/null)"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Python
#-------------------------------------------------------------------------------

install_python() {
    clear_screen
    print_header "PYTHON INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Current Python Status"
    print_item "Python3" "$(get_installed_version python3)"
    print_item "pip3" "$(get_installed_version pip3)"
    
    print_section "Installation Options"
    echo -e "  ${WHITE}1.${NC} Python 3 + pip + venv (System packages)"
    echo -e "  ${WHITE}2.${NC} Pyenv (Multiple Python versions)"
    echo -e "  ${WHITE}3.${NC} Both"
    echo ""
    
    CHOICE=$(get_input "Select option (1-3)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "3" ]]; then
        print_installing "Python 3 and tools"
        run_cmd "apt-get install -y python3 python3-pip python3-venv python3-dev python3-setuptools python3-wheel"
        print_success "Python 3 installed"
        
        # Install common packages
        print_installing "Common Python packages"
        run_cmd "pip3 install --upgrade pip"
        run_cmd "pip3 install virtualenv pipenv black flake8 pylint"
        print_success "Python packages installed"
    fi
    
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "3" ]]; then
        print_installing "Pyenv dependencies"
        run_cmd "apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
        
        print_installing "Pyenv"
        sudo -u "$SUDO_USER" bash -c 'curl https://pyenv.run | bash' >> "$LOG_FILE" 2>&1
        
        print_success "Pyenv installed"
        echo ""
        print_info "Add to your ~/.bashrc:"
        echo -e '  ${DIM}export PYENV_ROOT="$HOME/.pyenv"${NC}'
        echo -e '  ${DIM}export PATH="$PYENV_ROOT/bin:$PATH"${NC}'
        echo -e '  ${DIM}eval "$(pyenv init -)"${NC}'
    fi
    
    print_section "Installation Complete"
    print_info "Python version: $(python3 --version 2>/dev/null)"
    print_info "pip version: $(pip3 --version 2>/dev/null | awk '{print $2}')"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Docker
#-------------------------------------------------------------------------------

install_docker() {
    clear_screen
    print_header "DOCKER INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Components"
    echo -e "  ${WHITE}•${NC} Docker Engine"
    echo -e "  ${WHITE}•${NC} Docker Compose"
    echo -e "  ${WHITE}•${NC} Docker CLI"
    echo ""
    
    if cmd_exists docker; then
        print_warning "Docker appears to be already installed"
        print_info "Version: $(docker --version 2>/dev/null)"
        echo ""
        echo -ne "  ${WHITE}Reinstall? [y/N]: ${NC}"
        read -r reinstall
        [[ ! "$reinstall" =~ ^[Yy]$ ]] && { press_any_key; return; }
    fi
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    # Remove old versions
    print_info "Removing old Docker versions..."
    run_cmd "apt-get remove -y docker docker-engine docker.io containerd runc" || true
    
    update_apt
    
    # Install prerequisites
    print_installing "Prerequisites"
    run_cmd "apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release"
    
    # Add Docker repository
    print_installing "Docker repository"
    run_cmd "install -m 0755 -d /etc/apt/keyrings"
    run_cmd "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
    run_cmd "chmod a+r /etc/apt/keyrings/docker.gpg"
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    run_cmd "apt-get update"
    
    # Install Docker
    print_installing "Docker Engine"
    run_cmd "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    print_success "Docker installed"
    
    # Start Docker
    run_cmd "systemctl enable docker"
    run_cmd "systemctl start docker"
    
    # Add user to docker group
    if [[ -n "$SUDO_USER" ]]; then
        print_info "Adding $SUDO_USER to docker group..."
        run_cmd "usermod -aG docker $SUDO_USER"
        print_success "User added to docker group"
        print_warning "Log out and back in for group changes to take effect"
    fi
    
    print_section "Installation Complete"
    print_info "Docker version: $(docker --version 2>/dev/null)"
    print_info "Compose version: $(docker compose version 2>/dev/null)"
    
    # Test installation
    echo ""
    echo -ne "  ${WHITE}Run hello-world test? [y/N]: ${NC}"
    read -r run_test
    if [[ "$run_test" =~ ^[Yy]$ ]]; then
        docker run hello-world
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Go (Golang)
#-------------------------------------------------------------------------------

install_golang() {
    clear_screen
    print_header "GO (GOLANG) INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Go Version"
    echo -e "  ${WHITE}1.${NC} Go 1.22 (Latest)"
    echo -e "  ${WHITE}2.${NC} Go 1.21"
    echo -e "  ${WHITE}3.${NC} Go 1.20"
    echo ""
    
    CHOICE=$(get_input "Select version (1-3)")
    
    case $CHOICE in
        1) GO_VER="1.22.0" ;;
        2) GO_VER="1.21.6" ;;
        3) GO_VER="1.20.13" ;;
        *) GO_VER="1.22.0" ;;
    esac
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    # Remove old installation
    if [[ -d /usr/local/go ]]; then
        print_info "Removing old Go installation..."
        rm -rf /usr/local/go
    fi
    
    # Download and install
    print_installing "Go $GO_VER"
    cd /tmp
    run_cmd "wget -q https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz"
    run_cmd "tar -C /usr/local -xzf go${GO_VER}.linux-amd64.tar.gz"
    rm -f go${GO_VER}.linux-amd64.tar.gz
    
    # Setup environment
    if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    
    print_success "Go installed"
    
    print_section "Installation Complete"
    print_info "Go version: $(/usr/local/go/bin/go version 2>/dev/null)"
    print_info "Add to your PATH: export PATH=\$PATH:/usr/local/go/bin"
    print_info "Set GOPATH: export GOPATH=\$HOME/go"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Rust
#-------------------------------------------------------------------------------

install_rust() {
    clear_screen
    print_header "RUST INSTALLATION"
    
    print_section "Installation"
    echo -e "  Rust will be installed using rustup (official installer)"
    echo -e "  This installs: rustc, cargo, rustup"
    echo ""
    
    if cmd_exists rustc; then
        print_warning "Rust appears to be already installed"
        print_info "Version: $(rustc --version 2>/dev/null)"
        echo ""
    fi
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    print_installing "Rust via rustup"
    
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y' 2>&1 | tee -a "$LOG_FILE"
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tee -a "$LOG_FILE"
    fi
    
    print_success "Rust installed"
    
    print_section "Installation Complete"
    print_info "Run: source \$HOME/.cargo/env"
    print_info "Or restart your terminal"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Java
#-------------------------------------------------------------------------------

install_java() {
    clear_screen
    print_header "JAVA INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Java Version"
    echo -e "  ${WHITE}1.${NC} OpenJDK 21 (Latest LTS)"
    echo -e "  ${WHITE}2.${NC} OpenJDK 17 (LTS)"
    echo -e "  ${WHITE}3.${NC} OpenJDK 11 (LTS)"
    echo -e "  ${WHITE}4.${NC} OpenJDK 8 (Legacy)"
    echo ""
    
    CHOICE=$(get_input "Select version (1-4)")
    
    case $CHOICE in
        1) JAVA_VER="21" ;;
        2) JAVA_VER="17" ;;
        3) JAVA_VER="11" ;;
        4) JAVA_VER="8" ;;
        *) JAVA_VER="21" ;;
    esac
    
    print_section "Build Tools"
    echo -e "  ${WHITE}1.${NC} Maven only"
    echo -e "  ${WHITE}2.${NC} Gradle only"
    echo -e "  ${WHITE}3.${NC} Both Maven and Gradle"
    echo -e "  ${WHITE}4.${NC} None"
    echo ""
    
    TOOLS=$(get_input "Select build tools (1-4)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # Install Java
    print_installing "OpenJDK $JAVA_VER"
    run_cmd "apt-get install -y openjdk-${JAVA_VER}-jdk openjdk-${JAVA_VER}-jre"
    print_success "Java installed"
    
    # Install build tools
    if [[ "$TOOLS" == "1" ]] || [[ "$TOOLS" == "3" ]]; then
        print_installing "Maven"
        run_cmd "apt-get install -y maven"
        print_success "Maven installed"
    fi
    
    if [[ "$TOOLS" == "2" ]] || [[ "$TOOLS" == "3" ]]; then
        print_installing "Gradle"
        run_cmd "apt-get install -y gradle"
        print_success "Gradle installed"
    fi
    
    print_section "Installation Complete"
    print_info "Java version: $(java -version 2>&1 | head -1)"
    [[ "$TOOLS" != "4" ]] && print_info "JAVA_HOME: /usr/lib/jvm/java-${JAVA_VER}-openjdk-amd64"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Ruby
#-------------------------------------------------------------------------------

install_ruby() {
    clear_screen
    print_header "RUBY INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Installation Method"
    echo -e "  ${WHITE}1.${NC} rbenv (Version manager) - ${GREEN}Recommended${NC}"
    echo -e "  ${WHITE}2.${NC} System package"
    echo ""
    
    METHOD=$(get_input "Select method (1-2)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    if [[ "$METHOD" == "1" ]]; then
        # Install dependencies
        print_installing "Dependencies"
        run_cmd "apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev"
        
        # Install rbenv
        print_installing "rbenv"
        sudo -u "$SUDO_USER" bash -c 'curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash' >> "$LOG_FILE" 2>&1
        
        print_success "rbenv installed"
        echo ""
        print_info "Add to ~/.bashrc:"
        echo -e '  ${DIM}export PATH="$HOME/.rbenv/bin:$PATH"${NC}'
        echo -e '  ${DIM}eval "$(rbenv init -)"${NC}'
        echo ""
        print_info "Then run: rbenv install 3.3.0 && rbenv global 3.3.0"
    else
        print_installing "Ruby (system package)"
        run_cmd "apt-get install -y ruby ruby-dev ruby-bundler"
        print_success "Ruby installed"
    fi
    
    # Install Rails option
    echo ""
    echo -ne "  ${WHITE}Install Ruby on Rails? [y/N]: ${NC}"
    read -r install_rails
    
    if [[ "$install_rails" =~ ^[Yy]$ ]]; then
        print_installing "Ruby on Rails"
        if [[ "$METHOD" == "2" ]]; then
            run_cmd "gem install rails"
        else
            print_info "After setting up rbenv, run: gem install rails"
        fi
    fi
    
    print_section "Installation Complete"
    if [[ "$METHOD" == "2" ]]; then
        print_info "Ruby version: $(ruby --version 2>/dev/null)"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# .NET
#-------------------------------------------------------------------------------

install_dotnet() {
    clear_screen
    print_header ".NET INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section ".NET Version"
    echo -e "  ${WHITE}1.${NC} .NET 8.0 (Latest LTS)"
    echo -e "  ${WHITE}2.${NC} .NET 7.0"
    echo -e "  ${WHITE}3.${NC} .NET 6.0 (LTS)"
    echo ""
    
    CHOICE=$(get_input "Select version (1-3)")
    
    case $CHOICE in
        1) DOTNET_VER="8.0" ;;
        2) DOTNET_VER="7.0" ;;
        3) DOTNET_VER="6.0" ;;
        *) DOTNET_VER="8.0" ;;
    esac
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # Install Microsoft package repository
    print_installing "Microsoft repository"
    run_cmd "apt-get install -y wget"
    run_cmd "wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb"
    run_cmd "dpkg -i packages-microsoft-prod.deb"
    rm -f packages-microsoft-prod.deb
    run_cmd "apt-get update"
    
    # Install .NET SDK
    print_installing ".NET SDK $DOTNET_VER"
    run_cmd "apt-get install -y dotnet-sdk-${DOTNET_VER}"
    print_success ".NET SDK installed"
    
    print_section "Installation Complete"
    print_info ".NET version: $(dotnet --version 2>/dev/null)"
    print_info "Create new project: dotnet new console -n MyApp"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Git & Tools
#-------------------------------------------------------------------------------

install_git_tools() {
    clear_screen
    print_header "GIT & TOOLS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Tools"
    echo -e "  ${WHITE}1.${NC} Git"
    echo -e "  ${WHITE}2.${NC} GitHub CLI (gh)"
    echo -e "  ${WHITE}3.${NC} GitLab CLI (glab)"
    echo -e "  ${WHITE}4.${NC} Git LFS (Large File Storage)"
    echo -e "  ${WHITE}5.${NC} All of the above"
    echo ""
    
    CHOICE=$(get_input "Select option (1-5)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "5" ]]; then
        print_installing "Git"
        run_cmd "apt-get install -y git"
        print_success "Git installed"
    fi
    
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "5" ]]; then
        print_installing "GitHub CLI"
        run_cmd "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
        run_cmd "chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y gh"
        print_success "GitHub CLI installed"
    fi
    
    if [[ "$CHOICE" == "3" ]] || [[ "$CHOICE" == "5" ]]; then
        print_installing "GitLab CLI"
        run_cmd "curl -fsSL https://gitlab.com/gitlab-org/cli/-/raw/main/scripts/install.sh | sh" || print_warning "GitLab CLI installation may require manual setup"
    fi
    
    if [[ "$CHOICE" == "4" ]] || [[ "$CHOICE" == "5" ]]; then
        print_installing "Git LFS"
        run_cmd "apt-get install -y git-lfs"
        run_cmd "git lfs install"
        print_success "Git LFS installed"
    fi
    
    print_section "Installation Complete"
    cmd_exists git && print_info "Git: $(git --version 2>/dev/null)"
    cmd_exists gh && print_info "GitHub CLI: $(gh --version 2>/dev/null | head -1)"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Databases
#-------------------------------------------------------------------------------

install_databases() {
    clear_screen
    print_header "DATABASE INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Databases"
    echo -e "  ${WHITE}1.${NC} MySQL"
    echo -e "  ${WHITE}2.${NC} PostgreSQL"
    echo -e "  ${WHITE}3.${NC} MongoDB"
    echo -e "  ${WHITE}4.${NC} Redis"
    echo -e "  ${WHITE}5.${NC} SQLite"
    echo ""
    
    CHOICE=$(get_input "Select database (1-5)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    case $CHOICE in
        1)
            print_installing "MySQL"
            run_cmd "apt-get install -y mysql-server mysql-client"
            run_cmd "systemctl enable mysql"
            run_cmd "systemctl start mysql"
            print_success "MySQL installed"
            print_info "Run: sudo mysql_secure_installation"
            ;;
        2)
            print_installing "PostgreSQL"
            run_cmd "apt-get install -y postgresql postgresql-contrib"
            run_cmd "systemctl enable postgresql"
            run_cmd "systemctl start postgresql"
            print_success "PostgreSQL installed"
            print_info "Default user: postgres"
            ;;
        3)
            print_installing "MongoDB"
            run_cmd "curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg"
            echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null
            run_cmd "apt-get update"
            run_cmd "apt-get install -y mongodb-org"
            run_cmd "systemctl enable mongod"
            run_cmd "systemctl start mongod"
            print_success "MongoDB installed"
            ;;
        4)
            print_installing "Redis"
            run_cmd "apt-get install -y redis-server"
            run_cmd "systemctl enable redis-server"
            run_cmd "systemctl start redis-server"
            print_success "Redis installed"
            print_info "Test with: redis-cli ping"
            ;;
        5)
            print_installing "SQLite"
            run_cmd "apt-get install -y sqlite3 libsqlite3-dev"
            print_success "SQLite installed"
            ;;
    esac
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Code Editors
#-------------------------------------------------------------------------------

install_editors() {
    clear_screen
    print_header "CODE EDITORS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Editors"
    echo -e "  ${WHITE}1.${NC} Visual Studio Code"
    echo -e "  ${WHITE}2.${NC} Neovim"
    echo -e "  ${WHITE}3.${NC} Sublime Text"
    echo -e "  ${WHITE}4.${NC} Vim"
    echo ""
    
    CHOICE=$(get_input "Select editor (1-4)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    case $CHOICE in
        1)
            print_installing "Visual Studio Code"
            run_cmd "apt-get install -y wget gpg"
            run_cmd "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg"
            run_cmd "install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg"
            echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
            rm -f packages.microsoft.gpg
            run_cmd "apt-get update"
            run_cmd "apt-get install -y code"
            print_success "VS Code installed"
            print_info "Launch with: code"
            ;;
        2)
            print_installing "Neovim"
            run_cmd "apt-get install -y neovim"
            print_success "Neovim installed"
            print_info "Launch with: nvim"
            print_info "Config: ~/.config/nvim/init.vim"
            ;;
        3)
            print_installing "Sublime Text"
            run_cmd "wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null"
            echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
            run_cmd "apt-get update"
            run_cmd "apt-get install -y sublime-text"
            print_success "Sublime Text installed"
            print_info "Launch with: subl"
            ;;
        4)
            print_installing "Vim"
            run_cmd "apt-get install -y vim"
            print_success "Vim installed"
            ;;
    esac
    
    press_any_key
}

#-------------------------------------------------------------------------------
# DevOps Tools
#-------------------------------------------------------------------------------

install_devops() {
    clear_screen
    print_header "DEVOPS TOOLS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Tools"
    echo -e "  ${WHITE}1.${NC} kubectl (Kubernetes CLI)"
    echo -e "  ${WHITE}2.${NC} Minikube (Local Kubernetes)"
    echo -e "  ${WHITE}3.${NC} k9s (Kubernetes TUI)"
    echo -e "  ${WHITE}4.${NC} Helm (Kubernetes package manager)"
    echo -e "  ${WHITE}5.${NC} Terraform"
    echo -e "  ${WHITE}6.${NC} Ansible"
    echo -e "  ${WHITE}7.${NC} Vagrant"
    echo -e "  ${WHITE}8.${NC} All Kubernetes tools (1-4)"
    echo -e "  ${WHITE}9.${NC} All tools"
    echo ""
    
    CHOICE=$(get_input "Select option (1-9)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # kubectl
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "kubectl"
        run_cmd "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y kubectl"
        print_success "kubectl installed"
    fi
    
    # Minikube
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Minikube"
        run_cmd "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
        run_cmd "install minikube-linux-amd64 /usr/local/bin/minikube"
        rm -f minikube-linux-amd64
        print_success "Minikube installed"
        print_info "Start with: minikube start"
    fi
    
    # k9s
    if [[ "$CHOICE" == "3" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "k9s"
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        run_cmd "curl -LO https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
        run_cmd "tar -xzf k9s_Linux_amd64.tar.gz -C /usr/local/bin k9s"
        rm -f k9s_Linux_amd64.tar.gz
        print_success "k9s installed"
    fi
    
    # Helm
    if [[ "$CHOICE" == "4" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Helm"
        run_cmd "curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y helm"
        print_success "Helm installed"
    fi
    
    # Terraform
    if [[ "$CHOICE" == "5" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Terraform"
        run_cmd "apt-get install -y gnupg software-properties-common"
        run_cmd "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null"
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y terraform"
        print_success "Terraform installed"
    fi
    
    # Ansible
    if [[ "$CHOICE" == "6" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Ansible"
        run_cmd "apt-get install -y software-properties-common"
        run_cmd "add-apt-repository -y --update ppa:ansible/ansible"
        run_cmd "apt-get install -y ansible"
        print_success "Ansible installed"
    fi
    
    # Vagrant
    if [[ "$CHOICE" == "7" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Vagrant"
        run_cmd "wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null"
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y vagrant"
        print_success "Vagrant installed"
    fi
    
    print_section "Installation Complete"
    cmd_exists kubectl && print_info "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
    cmd_exists minikube && print_info "minikube: $(minikube version --short 2>/dev/null)"
    cmd_exists helm && print_info "helm: $(helm version --short 2>/dev/null)"
    cmd_exists terraform && print_info "terraform: $(terraform version 2>/dev/null | head -1)"
    cmd_exists ansible && print_info "ansible: $(ansible --version 2>/dev/null | head -1)"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Cloud CLIs
#-------------------------------------------------------------------------------

install_cloud_cli() {
    clear_screen
    print_header "CLOUD CLI INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Cloud CLIs"
    echo -e "  ${WHITE}1.${NC} AWS CLI"
    echo -e "  ${WHITE}2.${NC} Google Cloud SDK (gcloud)"
    echo -e "  ${WHITE}3.${NC} Azure CLI"
    echo -e "  ${WHITE}4.${NC} DigitalOcean CLI (doctl)"
    echo -e "  ${WHITE}5.${NC} Heroku CLI"
    echo -e "  ${WHITE}6.${NC} All cloud CLIs"
    echo ""
    
    CHOICE=$(get_input "Select option (1-6)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # AWS CLI
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "6" ]]; then
        print_installing "AWS CLI"
        run_cmd "apt-get install -y unzip"
        cd /tmp
        run_cmd "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
        run_cmd "unzip -o awscliv2.zip"
        run_cmd "./aws/install --update"
        rm -rf aws awscliv2.zip
        print_success "AWS CLI installed"
        print_info "Configure with: aws configure"
    fi
    
    # Google Cloud SDK
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "6" ]]; then
        print_installing "Google Cloud SDK"
        run_cmd "apt-get install -y apt-transport-https ca-certificates gnupg"
        run_cmd "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg"
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
        run_cmd "apt-get update"
        run_cmd "apt-get install -y google-cloud-cli"
        print_success "Google Cloud SDK installed"
        print_info "Initialize with: gcloud init"
    fi
    
    # Azure CLI
    if [[ "$CHOICE" == "3" ]] || [[ "$CHOICE" == "6" ]]; then
        print_installing "Azure CLI"
        run_cmd "curl -sL https://aka.ms/InstallAzureCLIDeb | bash"
        print_success "Azure CLI installed"
        print_info "Login with: az login"
    fi
    
    # DigitalOcean CLI
    if [[ "$CHOICE" == "4" ]] || [[ "$CHOICE" == "6" ]]; then
        print_installing "DigitalOcean CLI (doctl)"
        DOCTL_VERSION=$(curl -s https://api.github.com/repos/digitalocean/doctl/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        run_cmd "curl -LO https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz"
        run_cmd "tar -xzf doctl-${DOCTL_VERSION}-linux-amd64.tar.gz -C /usr/local/bin"
        rm -f doctl-${DOCTL_VERSION}-linux-amd64.tar.gz
        print_success "doctl installed"
        print_info "Auth with: doctl auth init"
    fi
    
    # Heroku CLI
    if [[ "$CHOICE" == "5" ]] || [[ "$CHOICE" == "6" ]]; then
        print_installing "Heroku CLI"
        run_cmd "curl https://cli-assets.heroku.com/install-ubuntu.sh | sh"
        print_success "Heroku CLI installed"
        print_info "Login with: heroku login"
    fi
    
    print_section "Installation Complete"
    cmd_exists aws && print_info "AWS CLI: $(aws --version 2>/dev/null)"
    cmd_exists gcloud && print_info "gcloud: $(gcloud --version 2>/dev/null | head -1)"
    cmd_exists az && print_info "Azure CLI: $(az --version 2>/dev/null | head -1)"
    cmd_exists doctl && print_info "doctl: $(doctl version 2>/dev/null)"
    cmd_exists heroku && print_info "Heroku CLI: $(heroku --version 2>/dev/null)"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Terminal Tools
#-------------------------------------------------------------------------------

install_terminal_tools() {
    clear_screen
    print_header "TERMINAL TOOLS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Tools"
    echo -e "  ${WHITE}1.${NC} tmux (Terminal multiplexer)"
    echo -e "  ${WHITE}2.${NC} htop (Process viewer)"
    echo -e "  ${WHITE}3.${NC} btop (Modern resource monitor)"
    echo -e "  ${WHITE}4.${NC} fzf (Fuzzy finder)"
    echo -e "  ${WHITE}5.${NC} ripgrep (Fast grep)"
    echo -e "  ${WHITE}6.${NC} bat (Better cat)"
    echo -e "  ${WHITE}7.${NC} exa/eza (Better ls)"
    echo -e "  ${WHITE}8.${NC} zsh + Oh My Zsh"
    echo -e "  ${WHITE}9.${NC} Starship (Shell prompt)"
    echo -e "  ${WHITE}10.${NC} All basic tools (1-7)"
    echo -e "  ${WHITE}11.${NC} All tools"
    echo ""
    
    CHOICE=$(get_input "Select option (1-11)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # tmux
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "tmux"
        run_cmd "apt-get install -y tmux"
        print_success "tmux installed"
    fi
    
    # htop
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "htop"
        run_cmd "apt-get install -y htop"
        print_success "htop installed"
    fi
    
    # btop
    if [[ "$CHOICE" == "3" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "btop"
        run_cmd "apt-get install -y btop" || {
            # Fallback for older Ubuntu versions
            run_cmd "snap install btop"
        }
        print_success "btop installed"
    fi
    
    # fzf
    if [[ "$CHOICE" == "4" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "fzf"
        run_cmd "apt-get install -y fzf"
        print_success "fzf installed"
        print_info "Add to .bashrc: source /usr/share/doc/fzf/examples/key-bindings.bash"
    fi
    
    # ripgrep
    if [[ "$CHOICE" == "5" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "ripgrep"
        run_cmd "apt-get install -y ripgrep"
        print_success "ripgrep installed (use: rg)"
    fi
    
    # bat
    if [[ "$CHOICE" == "6" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "bat"
        run_cmd "apt-get install -y bat"
        print_success "bat installed (use: batcat or create alias)"
    fi
    
    # exa/eza
    if [[ "$CHOICE" == "7" ]] || [[ "$CHOICE" == "10" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "eza (modern ls replacement)"
        run_cmd "apt-get install -y eza" || {
            # Install eza from GitHub if not in repos
            run_cmd "wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg"
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list > /dev/null
            run_cmd "apt-get update"
            run_cmd "apt-get install -y eza"
        }
        print_success "eza installed"
    fi
    
    # zsh + Oh My Zsh
    if [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "zsh"
        run_cmd "apt-get install -y zsh"
        
        print_installing "Oh My Zsh"
        if [[ -n "$SUDO_USER" ]]; then
            sudo -u "$SUDO_USER" bash -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' >> "$LOG_FILE" 2>&1
        fi
        print_success "zsh + Oh My Zsh installed"
        print_info "Change shell with: chsh -s \$(which zsh)"
    fi
    
    # Starship
    if [[ "$CHOICE" == "9" ]] || [[ "$CHOICE" == "11" ]]; then
        print_installing "Starship prompt"
        run_cmd "curl -sS https://starship.rs/install.sh | sh -s -- -y"
        print_success "Starship installed"
        print_info "Add to .bashrc: eval \"\$(starship init bash)\""
    fi
    
    print_section "Installation Complete"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# API Tools
#-------------------------------------------------------------------------------

install_api_tools() {
    clear_screen
    print_header "API TOOLS INSTALLATION"
    
    check_root || { press_any_key; return; }
    
    print_section "Available Tools"
    echo -e "  ${WHITE}1.${NC} HTTPie (Modern HTTP client)"
    echo -e "  ${WHITE}2.${NC} curl (Command-line HTTP client)"
    echo -e "  ${WHITE}3.${NC} jq (JSON processor)"
    echo -e "  ${WHITE}4.${NC} yq (YAML processor)"
    echo -e "  ${WHITE}5.${NC} Postman"
    echo -e "  ${WHITE}6.${NC} Insomnia"
    echo -e "  ${WHITE}7.${NC} xh (Fast HTTPie alternative)"
    echo -e "  ${WHITE}8.${NC} All CLI tools (1-4, 7)"
    echo -e "  ${WHITE}9.${NC} All tools"
    echo ""
    
    CHOICE=$(get_input "Select option (1-9)")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    update_apt
    
    # HTTPie
    if [[ "$CHOICE" == "1" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "HTTPie"
        run_cmd "apt-get install -y httpie"
        print_success "HTTPie installed (use: http or https)"
    fi
    
    # curl
    if [[ "$CHOICE" == "2" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "curl"
        run_cmd "apt-get install -y curl"
        print_success "curl installed"
    fi
    
    # jq
    if [[ "$CHOICE" == "3" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "jq"
        run_cmd "apt-get install -y jq"
        print_success "jq installed"
    fi
    
    # yq
    if [[ "$CHOICE" == "4" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "yq"
        YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        run_cmd "wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /usr/local/bin/yq"
        run_cmd "chmod +x /usr/local/bin/yq"
        print_success "yq installed"
    fi
    
    # Postman
    if [[ "$CHOICE" == "5" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Postman"
        run_cmd "snap install postman"
        print_success "Postman installed"
    fi
    
    # Insomnia
    if [[ "$CHOICE" == "6" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "Insomnia"
        run_cmd "snap install insomnia"
        print_success "Insomnia installed"
    fi
    
    # xh
    if [[ "$CHOICE" == "7" ]] || [[ "$CHOICE" == "8" ]] || [[ "$CHOICE" == "9" ]]; then
        print_installing "xh"
        XH_VERSION=$(curl -s https://api.github.com/repos/ducaale/xh/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        run_cmd "curl -LO https://github.com/ducaale/xh/releases/download/v${XH_VERSION}/xh-v${XH_VERSION}-linux-x86_64.tar.gz"
        run_cmd "tar -xzf xh-v${XH_VERSION}-linux-x86_64.tar.gz"
        run_cmd "mv xh-v${XH_VERSION}-linux-x86_64/xh /usr/local/bin/"
        rm -rf xh-v${XH_VERSION}-linux-x86_64*
        print_success "xh installed"
    fi
    
    print_section "Installation Complete"
    cmd_exists http && print_info "HTTPie: $(http --version 2>/dev/null)"
    cmd_exists jq && print_info "jq: $(jq --version 2>/dev/null)"
    cmd_exists yq && print_info "yq: $(yq --version 2>/dev/null)"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Uninstall Menu
#-------------------------------------------------------------------------------

show_uninstall_menu() {
    while true; do
        clear_screen
        print_header "UNINSTALL DEVELOPMENT TOOLS"
        
        echo -e "${WHITE}  Select category to uninstall:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${RED}LAMP/LEMP Stack${NC}    (Apache/Nginx, MySQL, PHP)                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${RED}Node.js${NC}            (Node, npm, nvm)                              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${RED}Python Tools${NC}       (pip packages, pyenv)                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${RED}Docker${NC}             (Docker Engine, Compose)                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${RED}Go${NC}                 (Go compiler)                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${RED}Rust${NC}               (Rust, Cargo)                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${RED}Java${NC}               (OpenJDK, Maven, Gradle)                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${RED}Ruby${NC}               (Ruby, rbenv)                                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${RED}.NET${NC}               (.NET SDK)                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}10.${NC} ${RED}Git Tools${NC}          (gh, glab, git-lfs)                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}11.${NC} ${RED}Databases${NC}          (MySQL, PostgreSQL, MongoDB, Redis)           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}12.${NC} ${RED}Code Editors${NC}       (VS Code, Neovim, Sublime)                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}13.${NC} ${RED}DevOps Tools${NC}       (kubectl, Terraform, Ansible)                 ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}14.${NC} ${RED}Cloud CLIs${NC}         (AWS, gcloud, az, doctl)                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}15.${NC} ${RED}Terminal Tools${NC}     (tmux, htop, fzf, etc.)                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE}16.${NC} ${RED}API Tools${NC}          (HTTPie, jq, Postman)                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} M.${NC} ${GREEN}Main Menu${NC}                                                          ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) uninstall_lamp_lemp ;;
            2) uninstall_nodejs ;;
            3) uninstall_python_tools ;;
            4) uninstall_docker ;;
            5) uninstall_golang ;;
            6) uninstall_rust ;;
            7) uninstall_java ;;
            8) uninstall_ruby ;;
            9) uninstall_dotnet ;;
            10) uninstall_git_tools ;;
            11) uninstall_databases ;;
            12) uninstall_editors ;;
            13) uninstall_devops ;;
            14) uninstall_cloud_cli ;;
            15) uninstall_terminal_tools ;;
            16) uninstall_api_tools ;;
            m|M) return ;;
            *) 
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Uninstall Functions
#-------------------------------------------------------------------------------

print_uninstalling() {
    echo -e "  ${RED}▶${NC} Removing $1..."
}

uninstall_lamp_lemp() {
    clear_screen
    print_header "UNINSTALL WEB STACK"
    
    check_root || { press_any_key; return; }
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists apache2; then
        installed["apache2"]=$idx
        menu_items+=("$idx|Apache2")
        ((idx++))
    fi
    if cmd_exists nginx; then
        installed["nginx"]=$idx
        menu_items+=("$idx|Nginx")
        ((idx++))
    fi
    if cmd_exists php; then
        installed["php"]=$idx
        menu_items+=("$idx|PHP (all versions)")
        ((idx++))
    fi
    if cmd_exists mysql; then
        installed["mysql"]=$idx
        menu_items+=("$idx|MySQL")
        ((idx++))
    fi
    if cmd_exists mariadb; then
        installed["mariadb"]=$idx
        menu_items+=("$idx|MariaDB")
        ((idx++))
    fi
    if cmd_exists composer; then
        installed["composer"]=$idx
        menu_items+=("$idx|Composer")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No web stack components are installed."
        press_any_key
        return
    fi
    
    # Add "All installed" option
    local all_idx=$idx
    menu_items+=("$idx|All installed components")
    
    print_section "Installed components"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option (1-$all_idx)")
    
    print_warning "This will remove selected software and its configuration!"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    # Apache
    if [[ -n "${installed[apache2]}" ]] && { [[ "$CHOICE" == "${installed[apache2]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Apache2"
        run_cmd "systemctl stop apache2" || true
        run_cmd "apt-get purge -y apache2 apache2-utils apache2-bin libapache2-mod-php*"
        print_success "Apache2 removed"
    fi
    
    # Nginx
    if [[ -n "${installed[nginx]}" ]] && { [[ "$CHOICE" == "${installed[nginx]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Nginx"
        run_cmd "systemctl stop nginx" || true
        run_cmd "apt-get purge -y nginx nginx-common nginx-full"
        print_success "Nginx removed"
    fi
    
    # PHP
    if [[ -n "${installed[php]}" ]] && { [[ "$CHOICE" == "${installed[php]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "PHP"
        run_cmd "apt-get purge -y 'php*'"
        print_success "PHP removed"
    fi
    
    # MySQL
    if [[ -n "${installed[mysql]}" ]] && { [[ "$CHOICE" == "${installed[mysql]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "MySQL"
        run_cmd "systemctl stop mysql" || true
        run_cmd "apt-get purge -y mysql-server mysql-client mysql-common"
        print_warning "Data in /var/lib/mysql may still exist"
        print_success "MySQL removed"
    fi
    
    # MariaDB
    if [[ -n "${installed[mariadb]}" ]] && { [[ "$CHOICE" == "${installed[mariadb]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "MariaDB"
        run_cmd "systemctl stop mariadb" || true
        run_cmd "apt-get purge -y mariadb-server mariadb-client mariadb-common"
        print_success "MariaDB removed"
    fi
    
    # Composer
    if [[ -n "${installed[composer]}" ]] && { [[ "$CHOICE" == "${installed[composer]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Composer"
        rm -f /usr/local/bin/composer
        print_success "Composer removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_nodejs() {
    clear_screen
    print_header "UNINSTALL NODE.JS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    if cmd_exists node; then
        installed["node"]=$idx
        menu_items+=("$idx|Node.js ($(node --version 2>/dev/null))")
        ((idx++))
    fi
    if [[ -n "$USER_HOME" ]] && [[ -d "$USER_HOME/.nvm" ]]; then
        installed["nvm"]=$idx
        menu_items+=("$idx|NVM (for user: $SUDO_USER)")
        ((idx++))
    fi
    if cmd_exists npm; then
        local global_pkgs=$(npm ls -g --depth=0 2>/dev/null | grep -v 'npm@' | tail -n +2 | wc -l)
        if [[ $global_pkgs -gt 0 ]]; then
            installed["npm_global"]=$idx
            menu_items+=("$idx|Global npm packages ($global_pkgs packages)")
            ((idx++))
        fi
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No Node.js components are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed components")
    
    print_section "Installed components"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    print_warning "This will remove Node.js and related tools!"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    # System Node.js
    if [[ -n "${installed[node]}" ]] && { [[ "$CHOICE" == "${installed[node]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Node.js"
        run_cmd "apt-get purge -y nodejs npm"
        run_cmd "apt-get autoremove -y"
        rm -f /etc/apt/sources.list.d/nodesource.list
        rm -f /etc/apt/keyrings/nodesource.gpg
        print_success "Node.js removed"
    fi
    
    # NVM
    if [[ -n "${installed[nvm]}" ]] && { [[ "$CHOICE" == "${installed[nvm]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "NVM"
        rm -rf "$USER_HOME/.nvm"
        print_info "Remove NVM lines from ~/.bashrc manually"
        print_success "NVM removed"
    fi
    
    # Global packages
    if [[ -n "${installed[npm_global]}" ]] && { [[ "$CHOICE" == "${installed[npm_global]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Global npm packages"
        if cmd_exists npm; then
            npm ls -g --depth=0 2>/dev/null | grep -v 'npm@' | awk -F'@' '{print $1}' | tail -n +2 | xargs -r npm uninstall -g
        fi
        print_success "Global packages removed"
    fi
    
    press_any_key
}

uninstall_python_tools() {
    clear_screen
    print_header "UNINSTALL PYTHON TOOLS"
    
    check_root || { press_any_key; return; }
    
    print_warning "Python 3 itself will NOT be removed (system dependency)"
    echo ""
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    # Check for pip packages
    local pip_pkgs=""
    cmd_exists virtualenv && pip_pkgs+="virtualenv "
    cmd_exists black && pip_pkgs+="black "
    cmd_exists flake8 && pip_pkgs+="flake8 "
    cmd_exists pylint && pip_pkgs+="pylint "
    cmd_exists pipenv && pip_pkgs+="pipenv "
    if [[ -n "$pip_pkgs" ]]; then
        installed["pip_pkgs"]=$idx
        menu_items+=("$idx|pip packages (${pip_pkgs% })")
        ((idx++))
    fi
    
    if [[ -n "$USER_HOME" ]] && [[ -d "$USER_HOME/.pyenv" ]]; then
        installed["pyenv"]=$idx
        menu_items+=("$idx|pyenv (for user: $SUDO_USER)")
        ((idx++))
    fi
    
    if dpkg -l | grep -q python3-dev 2>/dev/null; then
        installed["dev_pkgs"]=$idx
        menu_items+=("$idx|Python dev packages (python3-dev, venv, etc.)")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No Python tools are installed (beyond base Python)."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed tools")
    
    print_section "Installed Python tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    # pip packages
    if [[ -n "${installed[pip_pkgs]}" ]] && { [[ "$CHOICE" == "${installed[pip_pkgs]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "pip packages"
        pip3 uninstall -y virtualenv pipenv black flake8 pylint 2>/dev/null || true
        print_success "pip packages removed"
    fi
    
    # pyenv
    if [[ -n "${installed[pyenv]}" ]] && { [[ "$CHOICE" == "${installed[pyenv]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "pyenv"
        rm -rf "$USER_HOME/.pyenv"
        print_info "Remove pyenv lines from ~/.bashrc manually"
        print_success "pyenv removed"
    fi
    
    # Dev packages
    if [[ -n "${installed[dev_pkgs]}" ]] && { [[ "$CHOICE" == "${installed[dev_pkgs]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Python dev packages"
        run_cmd "apt-get purge -y python3-dev python3-venv python3-setuptools python3-wheel"
        run_cmd "apt-get autoremove -y"
        print_success "Dev packages removed"
    fi
    
    press_any_key
}

uninstall_docker() {
    clear_screen
    print_header "UNINSTALL DOCKER"
    
    check_root || { press_any_key; return; }
    
    if ! cmd_exists docker; then
        print_info "Docker is not installed."
        press_any_key
        return
    fi
    
    print_section "Docker is installed"
    print_item "Version" "$(docker --version 2>/dev/null)"
    
    # Show Docker data info
    if [[ -d /var/lib/docker ]]; then
        local docker_size=$(du -sh /var/lib/docker 2>/dev/null | cut -f1)
        print_item "Data size" "$docker_size"
    fi
    echo ""
    
    print_section "Options"
    echo -e "  ${WHITE}1.${NC} Remove Docker (keep images and containers)"
    echo -e "  ${WHITE}2.${NC} Remove Docker and all data (images, containers, volumes)"
    echo ""
    
    CHOICE=$(get_input "Select option (1-2)")
    
    print_warning "This will remove Docker from your system!"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    print_uninstalling "Docker"
    
    run_cmd "systemctl stop docker" || true
    run_cmd "apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    run_cmd "apt-get autoremove -y"
    
    if [[ "$CHOICE" == "2" ]]; then
        print_uninstalling "Docker data"
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
        print_success "Docker data removed"
    fi
    
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg
    
    print_success "Docker removed"
    
    press_any_key
}

uninstall_golang() {
    clear_screen
    print_header "UNINSTALL GO"
    
    check_root || { press_any_key; return; }
    
    if ! cmd_exists go && [[ ! -d /usr/local/go ]]; then
        print_info "Go is not installed."
        press_any_key
        return
    fi
    
    print_section "Go is installed"
    print_item "Version" "$(go version 2>/dev/null || echo 'Unknown')"
    print_item "Location" "/usr/local/go"
    echo ""
    
    print_warning "This will remove Go from /usr/local/go"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    print_uninstalling "Go"
    
    rm -rf /usr/local/go
    sed -i '/\/usr\/local\/go\/bin/d' /etc/profile
    
    print_success "Go removed"
    print_info "Remove GOPATH and Go PATH entries from your shell config manually"
    
    press_any_key
}

uninstall_rust() {
    clear_screen
    print_header "UNINSTALL RUST"
    
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    if ! cmd_exists rustc && [[ ! -d "$USER_HOME/.cargo" ]]; then
        print_info "Rust is not installed."
        press_any_key
        return
    fi
    
    print_section "Rust is installed"
    if cmd_exists rustc; then
        print_item "rustc" "$(rustc --version 2>/dev/null)"
    fi
    if cmd_exists cargo; then
        print_item "cargo" "$(cargo --version 2>/dev/null)"
    fi
    echo ""
    
    print_warning "This will remove Rust and Cargo"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    print_uninstalling "Rust"
    
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" bash -c 'rustup self uninstall -y' 2>/dev/null || true
    else
        rustup self uninstall -y 2>/dev/null || true
    fi
    
    print_success "Rust removed"
    
    press_any_key
}

uninstall_java() {
    clear_screen
    print_header "UNINSTALL JAVA"
    
    check_root || { press_any_key; return; }
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists java; then
        installed["java"]=$idx
        local java_ver=$(java -version 2>&1 | head -1)
        menu_items+=("$idx|OpenJDK ($java_ver)")
        ((idx++))
    fi
    if cmd_exists mvn; then
        installed["maven"]=$idx
        menu_items+=("$idx|Maven ($(mvn --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists gradle; then
        installed["gradle"]=$idx
        menu_items+=("$idx|Gradle ($(gradle --version 2>/dev/null | grep Gradle))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No Java tools are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed components")
    
    print_section "Installed Java tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[java]}" ]] && { [[ "$CHOICE" == "${installed[java]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "OpenJDK"
        run_cmd "apt-get purge -y 'openjdk-*'"
        print_success "OpenJDK removed"
    fi
    
    if [[ -n "${installed[maven]}" ]] && { [[ "$CHOICE" == "${installed[maven]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Maven"
        run_cmd "apt-get purge -y maven"
        print_success "Maven removed"
    fi
    
    if [[ -n "${installed[gradle]}" ]] && { [[ "$CHOICE" == "${installed[gradle]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Gradle"
        run_cmd "apt-get purge -y gradle"
        print_success "Gradle removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_ruby() {
    clear_screen
    print_header "UNINSTALL RUBY"
    
    check_root || { press_any_key; return; }
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    if cmd_exists ruby; then
        installed["ruby"]=$idx
        menu_items+=("$idx|Ruby ($(ruby --version 2>/dev/null))")
        ((idx++))
    fi
    if [[ -n "$USER_HOME" ]] && [[ -d "$USER_HOME/.rbenv" ]]; then
        installed["rbenv"]=$idx
        menu_items+=("$idx|rbenv (for user: $SUDO_USER)")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "Ruby is not installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed components")
    
    print_section "Installed Ruby tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[ruby]}" ]] && { [[ "$CHOICE" == "${installed[ruby]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Ruby"
        run_cmd "apt-get purge -y ruby ruby-dev ruby-bundler"
        run_cmd "apt-get autoremove -y"
        print_success "Ruby removed"
    fi
    
    if [[ -n "${installed[rbenv]}" ]] && { [[ "$CHOICE" == "${installed[rbenv]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "rbenv"
        rm -rf "$USER_HOME/.rbenv"
        print_info "Remove rbenv lines from ~/.bashrc manually"
        print_success "rbenv removed"
    fi
    
    press_any_key
}

uninstall_dotnet() {
    clear_screen
    print_header "UNINSTALL .NET"
    
    check_root || { press_any_key; return; }
    
    if ! cmd_exists dotnet; then
        print_info ".NET is not installed."
        press_any_key
        return
    fi
    
    print_section ".NET is installed"
    print_item "Version" "$(dotnet --version 2>/dev/null)"
    # List installed SDKs
    echo ""
    echo -e "  ${DIM}Installed SDKs:${NC}"
    dotnet --list-sdks 2>/dev/null | while read -r sdk; do
        echo -e "    ${DIM}- $sdk${NC}"
    done
    echo ""
    
    print_warning "This will remove all .NET SDK versions"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    print_uninstalling ".NET SDK"
    
    run_cmd "apt-get purge -y 'dotnet-*' 'aspnetcore-*'"
    run_cmd "apt-get autoremove -y"
    rm -f /etc/apt/sources.list.d/microsoft-prod.list
    
    print_success ".NET removed"
    
    press_any_key
}

uninstall_git_tools() {
    clear_screen
    print_header "UNINSTALL GIT TOOLS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed components
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists git; then
        installed["git"]=$idx
        menu_items+=("$idx|Git ($(git --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists gh; then
        installed["gh"]=$idx
        menu_items+=("$idx|GitHub CLI ($(gh --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists glab; then
        installed["glab"]=$idx
        menu_items+=("$idx|GitLab CLI ($(glab --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists git-lfs; then
        installed["git_lfs"]=$idx
        menu_items+=("$idx|Git LFS ($(git-lfs --version 2>/dev/null))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No Git tools are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed tools")
    
    print_section "Installed Git tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[git]}" ]] && { [[ "$CHOICE" == "${installed[git]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Git"
        run_cmd "apt-get purge -y git"
        print_success "Git removed"
    fi
    
    if [[ -n "${installed[gh]}" ]] && { [[ "$CHOICE" == "${installed[gh]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "GitHub CLI"
        run_cmd "apt-get purge -y gh"
        rm -f /etc/apt/sources.list.d/github-cli.list
        print_success "GitHub CLI removed"
    fi
    
    if [[ -n "${installed[glab]}" ]] && { [[ "$CHOICE" == "${installed[glab]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "GitLab CLI"
        rm -f /usr/local/bin/glab 2>/dev/null || true
        print_success "GitLab CLI removed"
    fi
    
    if [[ -n "${installed[git_lfs]}" ]] && { [[ "$CHOICE" == "${installed[git_lfs]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Git LFS"
        run_cmd "apt-get purge -y git-lfs"
        print_success "Git LFS removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_databases() {
    clear_screen
    print_header "UNINSTALL DATABASES"
    
    check_root || { press_any_key; return; }
    
    # Detect installed databases
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists mysql; then
        installed["mysql"]=$idx
        menu_items+=("$idx|MySQL ($(mysql --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists psql; then
        installed["postgresql"]=$idx
        menu_items+=("$idx|PostgreSQL ($(psql --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists mongod; then
        installed["mongodb"]=$idx
        menu_items+=("$idx|MongoDB ($(mongod --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists redis-server; then
        installed["redis"]=$idx
        menu_items+=("$idx|Redis ($(redis-server --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists sqlite3; then
        installed["sqlite"]=$idx
        menu_items+=("$idx|SQLite ($(sqlite3 --version 2>/dev/null))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No databases are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed databases")
    
    print_section "Installed databases"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    print_warning "This will remove the database software. Data may remain in /var/lib/"
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[mysql]}" ]] && { [[ "$CHOICE" == "${installed[mysql]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "MySQL"
        run_cmd "systemctl stop mysql" || true
        run_cmd "apt-get purge -y mysql-server mysql-client mysql-common"
        print_success "MySQL removed"
    fi
    
    if [[ -n "${installed[postgresql]}" ]] && { [[ "$CHOICE" == "${installed[postgresql]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "PostgreSQL"
        run_cmd "systemctl stop postgresql" || true
        run_cmd "apt-get purge -y postgresql postgresql-contrib"
        print_success "PostgreSQL removed"
    fi
    
    if [[ -n "${installed[mongodb]}" ]] && { [[ "$CHOICE" == "${installed[mongodb]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "MongoDB"
        run_cmd "systemctl stop mongod" || true
        run_cmd "apt-get purge -y mongodb-org"
        rm -f /etc/apt/sources.list.d/mongodb-org-*.list
        print_success "MongoDB removed"
    fi
    
    if [[ -n "${installed[redis]}" ]] && { [[ "$CHOICE" == "${installed[redis]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Redis"
        run_cmd "systemctl stop redis-server" || true
        run_cmd "apt-get purge -y redis-server"
        print_success "Redis removed"
    fi
    
    if [[ -n "${installed[sqlite]}" ]] && { [[ "$CHOICE" == "${installed[sqlite]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "SQLite"
        run_cmd "apt-get purge -y sqlite3"
        print_success "SQLite removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_editors() {
    clear_screen
    print_header "UNINSTALL CODE EDITORS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed editors
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if [[ -x /usr/bin/code ]] || cmd_exists code || dpkg -l code 2>/dev/null | grep -q '^ii'; then
        installed["vscode"]=$idx
        menu_items+=("$idx|Visual Studio Code (apt)")
        ((idx++))
    elif snap list 2>/dev/null | grep -q 'code'; then
        installed["vscode_snap"]=$idx
        menu_items+=("$idx|Visual Studio Code (snap)")
        ((idx++))
    fi
    if [[ -x /usr/bin/nvim ]] || cmd_exists nvim || dpkg -l neovim 2>/dev/null | grep -q '^ii'; then
        installed["neovim"]=$idx
        menu_items+=("$idx|Neovim")
        ((idx++))
    fi
    if [[ -x /usr/bin/subl ]] || cmd_exists subl || dpkg -l sublime-text 2>/dev/null | grep -q '^ii'; then
        installed["sublime"]=$idx
        menu_items+=("$idx|Sublime Text")
        ((idx++))
    fi
    if dpkg -l vim 2>/dev/null | grep -q '^ii'; then
        installed["vim"]=$idx
        menu_items+=("$idx|Vim")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No code editors are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed editors")
    
    print_section "Installed editors"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[vscode]}" ]] && { [[ "$CHOICE" == "${installed[vscode]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "VS Code (apt)"
        run_cmd "apt-get purge -y code"
        run_cmd "apt-get autoremove -y"
        rm -f /etc/apt/sources.list.d/vscode.list
        rm -f /etc/apt/keyrings/packages.microsoft.gpg
        print_success "VS Code removed"
    fi
    
    if [[ -n "${installed[vscode_snap]}" ]] && { [[ "$CHOICE" == "${installed[vscode_snap]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "VS Code (snap)"
        run_cmd "snap remove code"
        print_success "VS Code removed"
    fi
    
    if [[ -n "${installed[neovim]}" ]] && { [[ "$CHOICE" == "${installed[neovim]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Neovim"
        run_cmd "apt-get purge -y neovim"
        print_success "Neovim removed"
    fi
    
    if [[ -n "${installed[sublime]}" ]] && { [[ "$CHOICE" == "${installed[sublime]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Sublime Text"
        run_cmd "apt-get purge -y sublime-text"
        rm -f /etc/apt/sources.list.d/sublime-text.list
        print_success "Sublime Text removed"
    fi
    
    if [[ -n "${installed[vim]}" ]] && { [[ "$CHOICE" == "${installed[vim]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Vim"
        run_cmd "apt-get purge -y vim"
        print_success "Vim removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_devops() {
    clear_screen
    print_header "UNINSTALL DEVOPS TOOLS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed tools
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists kubectl; then
        installed["kubectl"]=$idx
        menu_items+=("$idx|kubectl")
        ((idx++))
    fi
    if cmd_exists minikube; then
        installed["minikube"]=$idx
        menu_items+=("$idx|Minikube ($(minikube version --short 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists k9s; then
        installed["k9s"]=$idx
        menu_items+=("$idx|k9s")
        ((idx++))
    fi
    if cmd_exists helm; then
        installed["helm"]=$idx
        menu_items+=("$idx|Helm ($(helm version --short 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists terraform; then
        installed["terraform"]=$idx
        menu_items+=("$idx|Terraform ($(terraform version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists ansible; then
        installed["ansible"]=$idx
        menu_items+=("$idx|Ansible ($(ansible --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists vagrant; then
        installed["vagrant"]=$idx
        menu_items+=("$idx|Vagrant ($(vagrant --version 2>/dev/null))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No DevOps tools are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed tools")
    
    print_section "Installed DevOps tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[kubectl]}" ]] && { [[ "$CHOICE" == "${installed[kubectl]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "kubectl"
        run_cmd "apt-get purge -y kubectl"
        rm -f /etc/apt/sources.list.d/kubernetes.list
        print_success "kubectl removed"
    fi
    
    if [[ -n "${installed[minikube]}" ]] && { [[ "$CHOICE" == "${installed[minikube]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Minikube"
        rm -f /usr/local/bin/minikube
        print_success "Minikube removed"
    fi
    
    if [[ -n "${installed[k9s]}" ]] && { [[ "$CHOICE" == "${installed[k9s]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "k9s"
        rm -f /usr/local/bin/k9s
        print_success "k9s removed"
    fi
    
    if [[ -n "${installed[helm]}" ]] && { [[ "$CHOICE" == "${installed[helm]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Helm"
        run_cmd "apt-get purge -y helm"
        rm -f /etc/apt/sources.list.d/helm-stable-debian.list
        print_success "Helm removed"
    fi
    
    if [[ -n "${installed[terraform]}" ]] && { [[ "$CHOICE" == "${installed[terraform]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Terraform"
        run_cmd "apt-get purge -y terraform"
        print_success "Terraform removed"
    fi
    
    if [[ -n "${installed[ansible]}" ]] && { [[ "$CHOICE" == "${installed[ansible]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Ansible"
        run_cmd "apt-get purge -y ansible"
        print_success "Ansible removed"
    fi
    
    if [[ -n "${installed[vagrant]}" ]] && { [[ "$CHOICE" == "${installed[vagrant]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Vagrant"
        run_cmd "apt-get purge -y vagrant"
        rm -f /etc/apt/sources.list.d/hashicorp.list
        print_success "Vagrant removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_cloud_cli() {
    clear_screen
    print_header "UNINSTALL CLOUD CLIs"
    
    check_root || { press_any_key; return; }
    
    # Detect installed CLIs
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists aws; then
        installed["aws"]=$idx
        menu_items+=("$idx|AWS CLI ($(aws --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists gcloud; then
        installed["gcloud"]=$idx
        menu_items+=("$idx|Google Cloud SDK")
        ((idx++))
    fi
    if cmd_exists az; then
        installed["azure"]=$idx
        menu_items+=("$idx|Azure CLI ($(az --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists doctl; then
        installed["doctl"]=$idx
        menu_items+=("$idx|DigitalOcean CLI ($(doctl version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists heroku; then
        installed["heroku"]=$idx
        menu_items+=("$idx|Heroku CLI ($(heroku --version 2>/dev/null))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No cloud CLIs are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed CLIs")
    
    print_section "Installed cloud CLIs"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[aws]}" ]] && { [[ "$CHOICE" == "${installed[aws]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "AWS CLI"
        rm -rf /usr/local/aws-cli
        rm -f /usr/local/bin/aws /usr/local/bin/aws_completer
        print_success "AWS CLI removed"
    fi
    
    if [[ -n "${installed[gcloud]}" ]] && { [[ "$CHOICE" == "${installed[gcloud]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Google Cloud SDK"
        run_cmd "apt-get purge -y google-cloud-cli"
        rm -f /etc/apt/sources.list.d/google-cloud-sdk.list
        print_success "Google Cloud SDK removed"
    fi
    
    if [[ -n "${installed[azure]}" ]] && { [[ "$CHOICE" == "${installed[azure]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Azure CLI"
        run_cmd "apt-get purge -y azure-cli"
        print_success "Azure CLI removed"
    fi
    
    if [[ -n "${installed[doctl]}" ]] && { [[ "$CHOICE" == "${installed[doctl]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "doctl"
        rm -f /usr/local/bin/doctl
        print_success "doctl removed"
    fi
    
    if [[ -n "${installed[heroku]}" ]] && { [[ "$CHOICE" == "${installed[heroku]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Heroku CLI"
        run_cmd "apt-get purge -y heroku" || rm -rf /usr/local/lib/heroku /usr/local/bin/heroku
        print_success "Heroku CLI removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_terminal_tools() {
    clear_screen
    print_header "UNINSTALL TERMINAL TOOLS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed tools
    declare -A installed
    declare -a menu_items
    local idx=1
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    if cmd_exists tmux; then
        installed["tmux"]=$idx
        menu_items+=("$idx|tmux ($(tmux -V 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists htop; then
        installed["htop"]=$idx
        menu_items+=("$idx|htop")
        ((idx++))
    fi
    if cmd_exists btop; then
        installed["btop"]=$idx
        menu_items+=("$idx|btop")
        ((idx++))
    fi
    if cmd_exists fzf; then
        installed["fzf"]=$idx
        menu_items+=("$idx|fzf ($(fzf --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists rg; then
        installed["ripgrep"]=$idx
        menu_items+=("$idx|ripgrep ($(rg --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists batcat || cmd_exists bat; then
        installed["bat"]=$idx
        menu_items+=("$idx|bat")
        ((idx++))
    fi
    if cmd_exists eza; then
        installed["eza"]=$idx
        menu_items+=("$idx|eza")
        ((idx++))
    fi
    if cmd_exists zsh; then
        installed["zsh"]=$idx
        local zsh_info="zsh ($(zsh --version 2>/dev/null))"
        [[ -n "$USER_HOME" ]] && [[ -d "$USER_HOME/.oh-my-zsh" ]] && zsh_info+=" + Oh My Zsh"
        menu_items+=("$idx|$zsh_info")
        ((idx++))
    fi
    if cmd_exists starship; then
        installed["starship"]=$idx
        menu_items+=("$idx|Starship ($(starship --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No terminal tools are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed tools")
    
    print_section "Installed terminal tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[tmux]}" ]] && { [[ "$CHOICE" == "${installed[tmux]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "tmux"
        run_cmd "apt-get purge -y tmux"
        print_success "tmux removed"
    fi
    
    if [[ -n "${installed[htop]}" ]] && { [[ "$CHOICE" == "${installed[htop]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "htop"
        run_cmd "apt-get purge -y htop"
        print_success "htop removed"
    fi
    
    if [[ -n "${installed[btop]}" ]] && { [[ "$CHOICE" == "${installed[btop]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "btop"
        run_cmd "apt-get purge -y btop" || run_cmd "snap remove btop"
        print_success "btop removed"
    fi
    
    if [[ -n "${installed[fzf]}" ]] && { [[ "$CHOICE" == "${installed[fzf]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "fzf"
        run_cmd "apt-get purge -y fzf"
        print_success "fzf removed"
    fi
    
    if [[ -n "${installed[ripgrep]}" ]] && { [[ "$CHOICE" == "${installed[ripgrep]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "ripgrep"
        run_cmd "apt-get purge -y ripgrep"
        print_success "ripgrep removed"
    fi
    
    if [[ -n "${installed[bat]}" ]] && { [[ "$CHOICE" == "${installed[bat]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "bat"
        run_cmd "apt-get purge -y bat"
        print_success "bat removed"
    fi
    
    if [[ -n "${installed[eza]}" ]] && { [[ "$CHOICE" == "${installed[eza]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "eza"
        run_cmd "apt-get purge -y eza"
        print_success "eza removed"
    fi
    
    if [[ -n "${installed[zsh]}" ]] && { [[ "$CHOICE" == "${installed[zsh]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "zsh"
        run_cmd "apt-get purge -y zsh"
        if [[ -n "$USER_HOME" ]] && [[ -d "$USER_HOME/.oh-my-zsh" ]]; then
            rm -rf "$USER_HOME/.oh-my-zsh"
        fi
        print_success "zsh + Oh My Zsh removed"
    fi
    
    if [[ -n "${installed[starship]}" ]] && { [[ "$CHOICE" == "${installed[starship]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Starship"
        rm -f /usr/local/bin/starship
        print_success "Starship removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

uninstall_api_tools() {
    clear_screen
    print_header "UNINSTALL API TOOLS"
    
    check_root || { press_any_key; return; }
    
    # Detect installed tools
    declare -A installed
    declare -a menu_items
    local idx=1
    
    if cmd_exists http; then
        installed["httpie"]=$idx
        menu_items+=("$idx|HTTPie ($(http --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists curl; then
        installed["curl"]=$idx
        menu_items+=("$idx|curl ($(curl --version 2>/dev/null | head -1))")
        ((idx++))
    fi
    if cmd_exists jq; then
        installed["jq"]=$idx
        menu_items+=("$idx|jq ($(jq --version 2>/dev/null))")
        ((idx++))
    fi
    if cmd_exists yq; then
        installed["yq"]=$idx
        menu_items+=("$idx|yq ($(yq --version 2>/dev/null))")
        ((idx++))
    fi
    if snap list 2>/dev/null | grep -q postman; then
        installed["postman"]=$idx
        menu_items+=("$idx|Postman")
        ((idx++))
    fi
    if snap list 2>/dev/null | grep -q insomnia; then
        installed["insomnia"]=$idx
        menu_items+=("$idx|Insomnia")
        ((idx++))
    fi
    if cmd_exists xh; then
        installed["xh"]=$idx
        menu_items+=("$idx|xh")
        ((idx++))
    fi
    
    if [[ ${#menu_items[@]} -eq 0 ]]; then
        print_info "No API tools are installed."
        press_any_key
        return
    fi
    
    local all_idx=$idx
    [[ ${#menu_items[@]} -gt 1 ]] && menu_items+=("$idx|All installed tools")
    
    print_section "Installed API tools"
    for item in "${menu_items[@]}"; do
        local num="${item%%|*}"
        local name="${item#*|}"
        echo -e "  ${WHITE}${num}.${NC} ${name}"
    done
    echo ""
    
    CHOICE=$(get_input "Select option")
    
    if ! confirm_action; then
        press_any_key
        return
    fi
    
    echo ""
    
    if [[ -n "${installed[httpie]}" ]] && { [[ "$CHOICE" == "${installed[httpie]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "HTTPie"
        run_cmd "apt-get purge -y httpie"
        print_success "HTTPie removed"
    fi
    
    if [[ -n "${installed[curl]}" ]] && { [[ "$CHOICE" == "${installed[curl]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "curl"
        print_warning "curl is often a system dependency - removing may break other tools"
        run_cmd "apt-get purge -y curl"
        print_success "curl removed"
    fi
    
    if [[ -n "${installed[jq]}" ]] && { [[ "$CHOICE" == "${installed[jq]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "jq"
        run_cmd "apt-get purge -y jq"
        print_success "jq removed"
    fi
    
    if [[ -n "${installed[yq]}" ]] && { [[ "$CHOICE" == "${installed[yq]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "yq"
        rm -f /usr/local/bin/yq
        print_success "yq removed"
    fi
    
    if [[ -n "${installed[postman]}" ]] && { [[ "$CHOICE" == "${installed[postman]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Postman"
        run_cmd "snap remove postman"
        print_success "Postman removed"
    fi
    
    if [[ -n "${installed[insomnia]}" ]] && { [[ "$CHOICE" == "${installed[insomnia]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "Insomnia"
        run_cmd "snap remove insomnia"
        print_success "Insomnia removed"
    fi
    
    if [[ -n "${installed[xh]}" ]] && { [[ "$CHOICE" == "${installed[xh]}" ]] || [[ "$CHOICE" == "$all_idx" ]]; }; then
        print_uninstalling "xh"
        rm -f /usr/local/bin/xh
        print_success "xh removed"
    fi
    
    run_cmd "apt-get autoremove -y"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Show Installed Dev Tools
#-------------------------------------------------------------------------------

show_installed() {
    clear_screen
    print_header "INSTALLED DEVELOPMENT TOOLS"
    
    # Get user home for checking user-installed tools
    local USER_HOME=""
    [[ -n "$SUDO_USER" ]] && USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    [[ -z "$USER_HOME" ]] && USER_HOME="$HOME"
    
    print_section "Languages & Runtimes"
    print_item "Node.js" "$(if cmd_exists node; then node --version 2>/dev/null; elif [[ -d "$USER_HOME/.nvm" ]]; then echo 'Installed via NVM'; else echo 'Not installed'; fi)"
    print_item "Python" "$(cmd_exists python3 && python3 --version 2>/dev/null || echo 'Not installed')"
    print_item "PHP" "$(cmd_exists php && php -v 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Ruby" "$(cmd_exists ruby && ruby --version 2>/dev/null | cut -d' ' -f1-2 || echo 'Not installed')"
    print_item "Go" "$(if cmd_exists go; then go version 2>/dev/null | cut -d' ' -f3; elif [[ -x /usr/local/go/bin/go ]]; then /usr/local/go/bin/go version 2>/dev/null | cut -d' ' -f3; else echo 'Not installed'; fi)"
    print_item "Rust" "$(if cmd_exists rustc; then rustc --version 2>/dev/null; elif [[ -x "$USER_HOME/.cargo/bin/rustc" ]]; then "$USER_HOME/.cargo/bin/rustc" --version 2>/dev/null; else echo 'Not installed'; fi)"
    print_item "Java" "$(cmd_exists java && java -version 2>&1 | head -1 || echo 'Not installed')"
    print_item ".NET" "$(cmd_exists dotnet && echo ".NET $(dotnet --version 2>/dev/null)" || echo 'Not installed')"
    
    print_section "Version Managers"
    print_item "NVM" "$([[ -d "$USER_HOME/.nvm" ]] && echo 'Installed' || echo 'Not installed')"
    print_item "pyenv" "$([[ -d "$USER_HOME/.pyenv" ]] && echo 'Installed' || echo 'Not installed')"
    print_item "rbenv" "$([[ -d "$USER_HOME/.rbenv" ]] && echo 'Installed' || echo 'Not installed')"
    
    print_section "Package Managers"
    print_item "npm" "$(cmd_exists npm && echo "npm $(npm --version 2>/dev/null)" || echo 'Not installed')"
    print_item "Yarn" "$(cmd_exists yarn && yarn --version 2>/dev/null || echo 'Not installed')"
    print_item "pip" "$(cmd_exists pip3 && pip3 --version 2>/dev/null | cut -d' ' -f1-2 || echo 'Not installed')"
    print_item "Composer" "$(cmd_exists composer && composer --version 2>/dev/null | cut -d' ' -f1-3 || echo 'Not installed')"
    print_item "Cargo" "$(if cmd_exists cargo; then cargo --version 2>/dev/null; elif [[ -x "$USER_HOME/.cargo/bin/cargo" ]]; then "$USER_HOME/.cargo/bin/cargo" --version 2>/dev/null; else echo 'Not installed'; fi)"
    print_item "gem" "$(cmd_exists gem && echo "gem $(gem --version 2>/dev/null)" || echo 'Not installed')"
    print_item "Maven" "$(cmd_exists mvn && mvn --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Gradle" "$(cmd_exists gradle && gradle --version 2>/dev/null | grep Gradle || echo 'Not installed')"
    
    print_section "Containers & VMs"
    print_item "Docker" "$(cmd_exists docker && docker --version 2>/dev/null | cut -d' ' -f1-3 || echo 'Not installed')"
    print_item "Docker Compose" "$(cmd_exists docker && docker compose version 2>/dev/null | cut -d' ' -f1-4 || echo 'Not installed')"
    print_item "Vagrant" "$(cmd_exists vagrant && vagrant --version 2>/dev/null || echo 'Not installed')"
    
    print_section "Web Servers"
    print_item "Apache" "$(cmd_exists apache2 && apache2 -v 2>/dev/null | head -1 | cut -d' ' -f3 || echo 'Not installed')"
    print_item "Nginx" "$(cmd_exists nginx && nginx -v 2>&1 | cut -d'/' -f2 || echo 'Not installed')"
    
    print_section "Databases"
    print_item "MySQL" "$(cmd_exists mysql && mysql --version 2>/dev/null | cut -d' ' -f1-3 || echo 'Not installed')"
    print_item "MariaDB" "$(cmd_exists mariadb && mariadb --version 2>/dev/null | cut -d' ' -f1-3 || echo 'Not installed')"
    print_item "PostgreSQL" "$(cmd_exists psql && psql --version 2>/dev/null || echo 'Not installed')"
    print_item "MongoDB" "$(cmd_exists mongod && mongod --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Redis" "$(cmd_exists redis-server && redis-server --version 2>/dev/null | cut -d' ' -f1-3 || echo 'Not installed')"
    print_item "SQLite" "$(cmd_exists sqlite3 && sqlite3 --version 2>/dev/null | cut -d' ' -f1 || echo 'Not installed')"
    
    print_section "Version Control"
    print_item "Git" "$(cmd_exists git && git --version 2>/dev/null || echo 'Not installed')"
    print_item "GitHub CLI" "$(cmd_exists gh && gh --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "GitLab CLI" "$(cmd_exists glab && glab --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Git LFS" "$(cmd_exists git-lfs && git-lfs --version 2>/dev/null || echo 'Not installed')"
    
    print_section "DevOps Tools"
    print_item "kubectl" "$(cmd_exists kubectl && kubectl version --client -o yaml 2>/dev/null | grep gitVersion | cut -d':' -f2 | tr -d ' ' || echo 'Not installed')"
    print_item "Minikube" "$(cmd_exists minikube && minikube version --short 2>/dev/null || echo 'Not installed')"
    print_item "k9s" "$(cmd_exists k9s && k9s version --short 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Helm" "$(cmd_exists helm && helm version --short 2>/dev/null || echo 'Not installed')"
    print_item "Terraform" "$(cmd_exists terraform && terraform version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Ansible" "$(cmd_exists ansible && ansible --version 2>/dev/null | head -1 || echo 'Not installed')"
    
    print_section "Cloud CLIs"
    print_item "AWS CLI" "$(cmd_exists aws && aws --version 2>/dev/null | cut -d' ' -f1 || echo 'Not installed')"
    print_item "Google Cloud" "$(cmd_exists gcloud && gcloud --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Azure CLI" "$(cmd_exists az && echo "azure-cli $(az version 2>/dev/null | grep '"azure-cli"' | cut -d'"' -f4)" || echo 'Not installed')"
    print_item "doctl" "$(cmd_exists doctl && doctl version 2>/dev/null | cut -d' ' -f1-2 || echo 'Not installed')"
    print_item "Heroku CLI" "$(cmd_exists heroku && heroku --version 2>/dev/null | cut -d' ' -f1 || echo 'Not installed')"
    
    print_section "Code Editors"
    local vscode_ver=$(dpkg -l code 2>/dev/null | grep '^ii' | awk '{print $3}')
    if [[ -n "$vscode_ver" ]]; then
        print_item "VS Code" "$vscode_ver"
    elif snap list code 2>/dev/null | grep -q code; then
        print_item "VS Code" "Installed (snap)"
    else
        print_item "VS Code" "Not installed"
    fi
    local neovim_ver=$(dpkg -l neovim 2>/dev/null | grep '^ii' | awk '{print $3}')
    if [[ -n "$neovim_ver" ]]; then
        print_item "Neovim" "$neovim_ver"
    else
        print_item "Neovim" "Not installed"
    fi
    
    local vim_ver=$(dpkg -l vim 2>/dev/null | grep '^ii' | awk '{print $3}')
    if [[ -n "$vim_ver" ]]; then
        print_item "Vim" "$vim_ver"
    else
        print_item "Vim" "Not installed"
    fi
    
    local subl_ver=$(dpkg -l sublime-text 2>/dev/null | grep '^ii' | awk '{print $3}')
    if [[ -n "$subl_ver" ]]; then
        print_item "Sublime Text" "$subl_ver"
    elif snap list sublime-text 2>/dev/null | grep -q sublime; then
        print_item "Sublime Text" "Installed (snap)"
    else
        print_item "Sublime Text" "Not installed"
    fi
    
    print_section "Terminal Tools"
    print_item "tmux" "$(cmd_exists tmux && tmux -V 2>/dev/null || echo 'Not installed')"
    print_item "htop" "$(cmd_exists htop && htop --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "btop" "$(cmd_exists btop && btop --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "fzf" "$(cmd_exists fzf && echo "fzf $(fzf --version 2>/dev/null)" || echo 'Not installed')"
    print_item "ripgrep" "$(cmd_exists rg && rg --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "bat" "$(if cmd_exists batcat; then batcat --version 2>/dev/null | head -1; elif cmd_exists bat; then bat --version 2>/dev/null | head -1; else echo 'Not installed'; fi)"
    print_item "eza" "$(cmd_exists eza && eza --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "zsh" "$(cmd_exists zsh && zsh --version 2>/dev/null || echo 'Not installed')"
    print_item "Oh My Zsh" "$([[ -d "$USER_HOME/.oh-my-zsh" ]] && echo 'Installed' || echo 'Not installed')"
    print_item "Starship" "$(cmd_exists starship && starship --version 2>/dev/null | head -1 || echo 'Not installed')"
    
    print_section "API Tools"
    print_item "curl" "$(cmd_exists curl && curl --version 2>/dev/null | head -1 | cut -d' ' -f1-2 || echo 'Not installed')"
    print_item "HTTPie" "$(cmd_exists http && http --version 2>/dev/null || echo 'Not installed')"
    print_item "xh" "$(cmd_exists xh && xh --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "jq" "$(cmd_exists jq && jq --version 2>/dev/null || echo 'Not installed')"
    print_item "yq" "$(cmd_exists yq && yq --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "Postman" "$(snap list 2>/dev/null | grep -q postman && echo 'Installed (snap)' || echo 'Not installed')"
    print_item "Insomnia" "$(snap list 2>/dev/null | grep -q insomnia && echo 'Installed (snap)' || echo 'Not installed')"
    
    print_section "Node.js Tools"
    print_item "PM2" "$(cmd_exists pm2 && pm2 --version 2>/dev/null || echo 'Not installed')"
    print_item "Nodemon" "$(cmd_exists nodemon && nodemon --version 2>/dev/null || echo 'Not installed')"
    
    print_section "Python Tools"
    print_item "virtualenv" "$(cmd_exists virtualenv && virtualenv --version 2>/dev/null || echo 'Not installed')"
    print_item "pipenv" "$(cmd_exists pipenv && pipenv --version 2>/dev/null || echo 'Not installed')"
    print_item "black" "$(cmd_exists black && black --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "flake8" "$(cmd_exists flake8 && flake8 --version 2>/dev/null | head -1 || echo 'Not installed')"
    print_item "pylint" "$(cmd_exists pylint && pylint --version 2>/dev/null | head -1 || echo 'Not installed')"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# View Log
#-------------------------------------------------------------------------------

view_log() {
    clear_screen
    print_header "INSTALLATION LOG"
    
    if [[ -f "$LOG_FILE" ]]; then
        print_info "Log file: $LOG_FILE"
        echo ""
        tail -50 "$LOG_FILE"
    else
        print_info "No log file found for this session"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

# Check if running on Debian/Ubuntu
if [[ ! -f /etc/debian_version ]]; then
    echo -e "${YELLOW}Warning: This script is designed for Debian/Ubuntu systems.${NC}"
    echo -e "${YELLOW}Some installations may not work on your distribution.${NC}"
    echo ""
fi

show_main_menu
