#!/bin/bash

#===============================================================================
# CRON WIZARD - TERMINAL UI
# Visual cron job builder with natural language support
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

select_user() {
    local users=()
    local i=1
    
    echo "" >&2
    echo -e "  ${CYAN}Select user:${NC}" >&2
    echo -e "  ${DIM}─────────────────────────────${NC}" >&2
    
    # Current user
    users+=("$USER")
    echo -e "  ${WHITE}1.${NC} $USER (current)" >&2
    ((i++))
    
    # Root if we have access
    if check_root; then
        # List other users
        while IFS=: read -r username _ uid _ _ _ _; do
            if [[ $uid -ge 1000 && $uid -lt 65534 && "$username" != "$USER" ]]; then
                users+=("$username")
                echo -e "  ${WHITE}$i.${NC} $username" >&2
                ((i++))
            fi
        done < /etc/passwd
        
        users+=("root")
        echo -e "  ${WHITE}$i.${NC} root" >&2
    fi
    
    echo "" >&2
    echo -ne "  ${WHITE}Enter number: ${NC}" >&2
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#users[@]} ]]; then
        echo "${users[$((selection-1))]}"
    else
        echo "$USER"
    fi
}

#-------------------------------------------------------------------------------
# Cron Expression Parser/Builder
#-------------------------------------------------------------------------------

explain_cron() {
    local min="$1" hour="$2" dom="$3" mon="$4" dow="$5"
    local explanation=""
    
    # Minutes
    if [[ "$min" == "*" ]]; then
        explanation="Every minute"
    elif [[ "$min" == "0" ]]; then
        explanation="At the start of the hour"
    elif [[ "$min" =~ ^\*/([0-9]+)$ ]]; then
        explanation="Every ${BASH_REMATCH[1]} minutes"
    elif [[ "$min" =~ ^[0-9]+$ ]]; then
        explanation="At minute $min"
    else
        explanation="At minute(s) $min"
    fi
    
    # Hours
    if [[ "$hour" == "*" ]]; then
        explanation="$explanation, every hour"
    elif [[ "$hour" =~ ^\*/([0-9]+)$ ]]; then
        explanation="$explanation, every ${BASH_REMATCH[1]} hours"
    elif [[ "$hour" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        local start_h="${BASH_REMATCH[1]}"
        local end_h="${BASH_REMATCH[2]}"
        local start_12=$((start_h % 12)); [[ $start_12 -eq 0 ]] && start_12=12
        local end_12=$((end_h % 12)); [[ $end_12 -eq 0 ]] && end_12=12
        local start_ampm="AM"; [[ $start_h -ge 12 ]] && start_ampm="PM"
        local end_ampm="AM"; [[ $end_h -ge 12 ]] && end_ampm="PM"
        explanation="$explanation, between ${start_12}${start_ampm} and ${end_12}${end_ampm}"
    elif [[ "$hour" =~ ^[0-9]+$ ]]; then
        local hour_12=$((hour % 12))
        [[ $hour_12 -eq 0 ]] && hour_12=12
        local ampm="AM"
        [[ $hour -ge 12 ]] && ampm="PM"
        if [[ "$min" =~ ^[0-9]+$ ]]; then
            explanation="At ${hour_12}:$(printf '%02d' "$min") ${ampm}"
        else
            explanation="$explanation, at ${hour_12}${ampm}"
        fi
    else
        explanation="$explanation, during hour(s) $hour"
    fi
    
    # Day of month
    if [[ "$dom" != "*" ]]; then
        if [[ "$dom" =~ ^[0-9]+$ ]]; then
            explanation="$explanation, on day $dom of the month"
        else
            explanation="$explanation, on day(s) $dom of the month"
        fi
    fi
    
    # Month
    if [[ "$mon" != "*" ]]; then
        local months=("" "January" "February" "March" "April" "May" "June" "July" "August" "September" "October" "November" "December")
        if [[ "$mon" =~ ^[0-9]+$ ]] && [[ $mon -ge 1 ]] && [[ $mon -le 12 ]]; then
            explanation="$explanation, in ${months[$mon]}"
        else
            explanation="$explanation, in month(s) $mon"
        fi
    fi
    
    # Day of week
    if [[ "$dow" != "*" ]]; then
        local days=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
        if [[ "$dow" =~ ^[0-6]$ ]]; then
            explanation="$explanation, only on ${days[$dow]}s"
        elif [[ "$dow" == "1-5" ]]; then
            explanation="$explanation, only on weekdays (Mon-Fri)"
        elif [[ "$dow" == "0,6" ]] || [[ "$dow" == "6,0" ]]; then
            explanation="$explanation, only on weekends"
        else
            explanation="$explanation, only on day(s) $dow of week"
        fi
    fi
    
    echo "$explanation"
}

parse_natural_language() {
    local input="$1"
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    local min="*" hour="*" dom="*" mon="*" dow="*"
    
    # Every minute
    if [[ "$input" =~ "every minute" ]]; then
        echo "* * * * *"
        return
    fi
    
    # Every X minutes
    if [[ "$input" =~ every[[:space:]]+([0-9]+)[[:space:]]+minute ]]; then
        echo "*/${BASH_REMATCH[1]} * * * *"
        return
    fi
    
    # Every hour
    if [[ "$input" =~ "every hour" ]] && [[ ! "$input" =~ "every hour at" ]]; then
        echo "0 * * * *"
        return
    fi
    
    # Every hour at X minutes
    if [[ "$input" =~ every[[:space:]]+hour[[:space:]]+at[[:space:]]+([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]} * * * *"
        return
    fi
    
    # Every X hours
    if [[ "$input" =~ every[[:space:]]+([0-9]+)[[:space:]]+hour ]]; then
        echo "0 */${BASH_REMATCH[1]} * * *"
        return
    fi
    
    # Every day at HH:MM or H AM/PM
    if [[ "$input" =~ every[[:space:]]+day[[:space:]]+at[[:space:]]+([0-9]+):?([0-9]*)[[:space:]]*(am|pm)? ]]; then
        hour="${BASH_REMATCH[1]}"
        min="${BASH_REMATCH[2]:-0}"
        local ampm="${BASH_REMATCH[3]}"
        
        if [[ "$ampm" == "pm" && $hour -lt 12 ]]; then
            hour=$((hour + 12))
        elif [[ "$ampm" == "am" && $hour -eq 12 ]]; then
            hour=0
        fi
        
        echo "$min $hour * * *"
        return
    fi
    
    # At HH:MM or H AM/PM (daily)
    if [[ "$input" =~ at[[:space:]]+([0-9]+):?([0-9]*)[[:space:]]*(am|pm)? ]]; then
        hour="${BASH_REMATCH[1]}"
        min="${BASH_REMATCH[2]:-0}"
        local ampm="${BASH_REMATCH[3]}"
        
        if [[ "$ampm" == "pm" && $hour -lt 12 ]]; then
            hour=$((hour + 12))
        elif [[ "$ampm" == "am" && $hour -eq 12 ]]; then
            hour=0
        fi
        
        echo "$min $hour * * *"
        return
    fi
    
    # Every Monday/Tuesday/etc
    local day_map="sunday:0 monday:1 tuesday:2 wednesday:3 thursday:4 friday:5 saturday:6"
    for day_entry in $day_map; do
        local day_name="${day_entry%%:*}"
        local day_num="${day_entry##*:}"
        if [[ "$input" =~ every[[:space:]]+$day_name ]]; then
            dow="$day_num"
            
            # Check for time
            if [[ "$input" =~ at[[:space:]]+([0-9]+):?([0-9]*)[[:space:]]*(am|pm)? ]]; then
                hour="${BASH_REMATCH[1]}"
                min="${BASH_REMATCH[2]:-0}"
                local ampm="${BASH_REMATCH[3]}"
                
                if [[ "$ampm" == "pm" && $hour -lt 12 ]]; then
                    hour=$((hour + 12))
                elif [[ "$ampm" == "am" && $hour -eq 12 ]]; then
                    hour=0
                fi
            else
                min="0"
                hour="0"
            fi
            
            echo "$min $hour * * $dow"
            return
        fi
    done
    
    # Weekdays
    if [[ "$input" =~ "weekday" ]] || [[ "$input" =~ "monday to friday" ]] || [[ "$input" =~ "mon-fri" ]]; then
        dow="1-5"
        if [[ "$input" =~ at[[:space:]]+([0-9]+):?([0-9]*)[[:space:]]*(am|pm)? ]]; then
            hour="${BASH_REMATCH[1]}"
            min="${BASH_REMATCH[2]:-0}"
            local ampm="${BASH_REMATCH[3]}"
            if [[ "$ampm" == "pm" && $hour -lt 12 ]]; then
                hour=$((hour + 12))
            elif [[ "$ampm" == "am" && $hour -eq 12 ]]; then
                hour=0
            fi
        else
            min="0"
            hour="9"
        fi
        echo "$min $hour * * $dow"
        return
    fi
    
    # Weekend
    if [[ "$input" =~ "weekend" ]]; then
        dow="0,6"
        if [[ "$input" =~ at[[:space:]]+([0-9]+):?([0-9]*)[[:space:]]*(am|pm)? ]]; then
            hour="${BASH_REMATCH[1]}"
            min="${BASH_REMATCH[2]:-0}"
            local ampm="${BASH_REMATCH[3]}"
            if [[ "$ampm" == "pm" && $hour -lt 12 ]]; then
                hour=$((hour + 12))
            elif [[ "$ampm" == "am" && $hour -eq 12 ]]; then
                hour=0
            fi
        else
            min="0"
            hour="10"
        fi
        echo "$min $hour * * $dow"
        return
    fi
    
    # Midnight
    if [[ "$input" =~ "midnight" ]]; then
        echo "0 0 * * *"
        return
    fi
    
    # Noon
    if [[ "$input" =~ "noon" ]]; then
        echo "0 12 * * *"
        return
    fi
    
    # Hourly
    if [[ "$input" =~ "hourly" ]]; then
        echo "0 * * * *"
        return
    fi
    
    # Daily
    if [[ "$input" =~ "daily" ]] || [[ "$input" =~ "every day" ]]; then
        echo "0 0 * * *"
        return
    fi
    
    # Weekly
    if [[ "$input" =~ "weekly" ]] || [[ "$input" =~ "every week" ]]; then
        echo "0 0 * * 0"
        return
    fi
    
    # Monthly
    if [[ "$input" =~ "monthly" ]] || [[ "$input" =~ "every month" ]]; then
        echo "0 0 1 * *"
        return
    fi
    
    # Yearly/Annually
    if [[ "$input" =~ "yearly" ]] || [[ "$input" =~ "annually" ]] || [[ "$input" =~ "every year" ]]; then
        echo "0 0 1 1 *"
        return
    fi
    
    # On reboot
    if [[ "$input" =~ "reboot" ]] || [[ "$input" =~ "startup" ]] || [[ "$input" =~ "boot" ]]; then
        echo "@reboot"
        return
    fi
    
    # Not recognized
    echo ""
}

validate_cron_field() {
    local field="$1"
    local min="$2"
    local max="$3"
    
    # Allow *
    [[ "$field" == "*" ]] && return 0
    
    # Allow */n
    [[ "$field" =~ ^\*/[0-9]+$ ]] && return 0
    
    # Allow n-m
    [[ "$field" =~ ^[0-9]+-[0-9]+$ ]] && return 0
    
    # Allow comma-separated
    [[ "$field" =~ ^[0-9,]+$ ]] && return 0
    
    # Allow single number in range
    if [[ "$field" =~ ^[0-9]+$ ]]; then
        [[ $field -ge $min && $field -le $max ]] && return 0
    fi
    
    return 1
}

#-------------------------------------------------------------------------------
# Main Menu
#-------------------------------------------------------------------------------

show_main_menu() {
    while true; do
        clear_screen
        
        echo -e "${BOLD}${YELLOW}"
        echo "╔════════════════════════════════════════════════════════════════════════════╗"
        echo "║                                                                            ║"
        echo "║           ██████╗██████╗  ██████╗ ███╗   ██╗                               ║"
        echo "║          ██╔════╝██╔══██╗██╔═══██╗████╗  ██║                               ║"
        echo "║          ██║     ██████╔╝██║   ██║██╔██╗ ██║                               ║"
        echo "║          ██║     ██╔══██╗██║   ██║██║╚██╗██║                               ║"
        echo "║          ╚██████╗██║  ██║╚██████╔╝██║ ╚████║                               ║"
        echo "║           ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝                               ║"
        echo "║                                                                            ║"
        echo "║                              WIZARD                                        ║"
        echo "║                   - Luka Rogovic <luka032[at]gmail.com -                   ║"
        echo "╚════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        # Quick status
        local cron_count=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l)
        echo -e "  ${DIM}Active cron jobs for $USER: ${WHITE}$cron_count${NC}"
        echo ""
        
        echo -e "${WHITE}  Select an option:${NC}"
        echo ""
        echo -e "  ${CYAN}┌──────────────────────────────────────────────────────────────────────────┐${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 1.${NC} ${GREEN}List Current Cron Jobs${NC}                                              ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 2.${NC} ${GREEN}Create Job (Natural Language)${NC}                                       ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 3.${NC} ${GREEN}Create Job (Visual Builder)${NC}                                         ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 4.${NC} ${GREEN}Create Job (Manual Entry)${NC}                                           ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 5.${NC} ${GREEN}Edit/Delete Jobs${NC}                                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 6.${NC} ${GREEN}Common Templates${NC}                                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 7.${NC} ${GREEN}View Cron Logs${NC}                                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 8.${NC} ${GREEN}Detect Conflicts${NC}                                                    ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} 9.${NC} ${GREEN}Explain Cron Expression${NC}                                             ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} B.${NC} ${YELLOW}Backup Crontab${NC}                                                      ${CYAN}│${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} R.${NC} ${YELLOW}Restore Crontab${NC}                                                     ${CYAN}│${NC}"
        echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────────┤${NC}"
        echo -e "  ${CYAN}│${NC}  ${WHITE} Q.${NC} ${RED}Quit${NC}                                                                ${CYAN}│${NC}"
        echo -e "  ${CYAN}└──────────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${WHITE}Enter your choice: ${NC}"
        
        read -r choice
        
        case $choice in
            1) list_cron_jobs ;;
            2) create_job_natural ;;
            3) create_job_visual ;;
            4) create_job_manual ;;
            5) edit_delete_jobs ;;
            6) common_templates ;;
            7) view_cron_logs ;;
            8) detect_conflicts ;;
            9) explain_expression ;;
            b|B) backup_crontab ;;
            r|R) restore_crontab ;;
            q|Q) 
                clear_screen
                echo -e "${GREEN}Thank you for using Cron Wizard!${NC}"
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
# List Current Cron Jobs
#-------------------------------------------------------------------------------

list_cron_jobs() {
    while true; do
        clear_screen
        print_header "CURRENT CRON JOBS"
        
        print_section "User: $USER"
        
        local jobs=$(crontab -l 2>/dev/null)
        
        if [[ -z "$jobs" ]] || [[ "$jobs" == "no crontab for"* ]]; then
            print_info "No cron jobs configured"
        else
            local i=1
            echo ""
            echo -e "  ${DIM}#   Schedule              Command${NC}"
            echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${NC}"
            
            while IFS= read -r line; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "$line" ]] && continue
                
                # Parse cron line
                if [[ "$line" =~ ^@(reboot|yearly|annually|monthly|weekly|daily|hourly|midnight) ]]; then
                    schedule="@${BASH_REMATCH[1]}"
                    cmd="${line#@* }"
                    printf "  ${WHITE}%-3s${NC} ${CYAN}%-20s${NC} %s\n" "$i." "$schedule" "${cmd:0:45}"
                elif [[ "$line" =~ ^([0-9*,/-]+)[[:space:]]+([0-9*,/-]+)[[:space:]]+([0-9*,/-]+)[[:space:]]+([0-9*,/-]+)[[:space:]]+([0-9*,/-]+)[[:space:]]+(.*) ]]; then
                    schedule="${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]} ${BASH_REMATCH[5]}"
                    cmd="${BASH_REMATCH[6]}"
                    printf "  ${WHITE}%-3s${NC} ${CYAN}%-20s${NC} %s\n" "$i." "$schedule" "${cmd:0:45}"
                fi
                ((i++))
            done <<< "$jobs"
        fi
        
        # System cron jobs (if root)
        if check_root; then
            print_section "System Cron Directories"
            
            for dir in /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly; do
                if [[ -d "$dir" ]]; then
                    local count=$(ls -1 "$dir" 2>/dev/null | wc -l)
                    print_item "$(basename $dir)" "$count script(s)"
                fi
            done
        fi
        
        wait_for_menu
        [[ $? -eq 1 ]] && return
    done
}

#-------------------------------------------------------------------------------
# Create Job - Natural Language
#-------------------------------------------------------------------------------

create_job_natural() {
    clear_screen
    print_header "CREATE JOB - NATURAL LANGUAGE"
    
    print_section "Examples"
    echo -e "  ${DIM}• every day at 5pm${NC}"
    echo -e "  ${DIM}• every monday at 9:30 am${NC}"
    echo -e "  ${DIM}• every 15 minutes${NC}"
    echo -e "  ${DIM}• every hour at 30${NC}"
    echo -e "  ${DIM}• weekdays at 8am${NC}"
    echo -e "  ${DIM}• every weekend at 10am${NC}"
    echo -e "  ${DIM}• midnight${NC}"
    echo -e "  ${DIM}• on reboot${NC}"
    echo -e "  ${DIM}• monthly${NC}"
    echo ""
    
    SCHEDULE_TEXT=$(get_input "Describe when to run")
    
    if [[ -z "$SCHEDULE_TEXT" ]]; then
        print_error "No input provided"
        press_any_key
        return
    fi
    
    CRON_EXPR=$(parse_natural_language "$SCHEDULE_TEXT")
    
    if [[ -z "$CRON_EXPR" ]]; then
        print_error "Could not understand: $SCHEDULE_TEXT"
        print_info "Try using the visual builder instead"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${GREEN}Parsed cron expression:${NC} ${WHITE}$CRON_EXPR${NC}"
    
    if [[ "$CRON_EXPR" != "@"* ]]; then
        IFS=' ' read -r min hour dom mon dow <<< "$CRON_EXPR"
        echo -e "  ${DIM}$(explain_cron "$min" "$hour" "$dom" "$mon" "$dow")${NC}"
    fi
    
    echo ""
    COMMAND=$(get_input "Command to run")
    
    if [[ -z "$COMMAND" ]]; then
        print_error "No command provided"
        press_any_key
        return
    fi
    
    FULL_LINE="$CRON_EXPR $COMMAND"
    
    echo ""
    echo -e "  ${CYAN}Full cron entry:${NC}"
    echo -e "  ${WHITE}$FULL_LINE${NC}"
    echo ""
    
    if confirm_action; then
        (crontab -l 2>/dev/null; echo "$FULL_LINE") | crontab -
        if [[ $? -eq 0 ]]; then
            print_success "Cron job added successfully!"
        else
            print_error "Failed to add cron job"
        fi
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Create Job - Visual Builder
#-------------------------------------------------------------------------------

create_job_visual() {
    clear_screen
    print_header "CREATE JOB - VISUAL BUILDER"
    
    local min="*" hour="*" dom="*" mon="*" dow="*"
    
    while true; do
        clear_screen
        print_header "CREATE JOB - VISUAL BUILDER"
        
        print_section "Current Expression"
        echo -e "  ${WHITE}$min $hour $dom $mon $dow${NC}"
        echo -e "  ${DIM}$(explain_cron "$min" "$hour" "$dom" "$mon" "$dow")${NC}"
        
        print_section "Cron Format Reference"
        echo -e "  ${DIM}┌───────────── minute (0-59)${NC}"
        echo -e "  ${DIM}│ ┌─────────── hour (0-23)${NC}"
        echo -e "  ${DIM}│ │ ┌───────── day of month (1-31)${NC}"
        echo -e "  ${DIM}│ │ │ ┌─────── month (1-12)${NC}"
        echo -e "  ${DIM}│ │ │ │ ┌───── day of week (0-6, 0=Sunday)${NC}"
        echo -e "  ${DIM}│ │ │ │ │${NC}"
        echo -e "  ${DIM}$min $hour $dom $mon $dow${NC}"
        
        print_section "Configure"
        echo -e "  ${WHITE}1.${NC} Minute      ${DIM}(current: $min)${NC}"
        echo -e "  ${WHITE}2.${NC} Hour        ${DIM}(current: $hour)${NC}"
        echo -e "  ${WHITE}3.${NC} Day of Month ${DIM}(current: $dom)${NC}"
        echo -e "  ${WHITE}4.${NC} Month       ${DIM}(current: $mon)${NC}"
        echo -e "  ${WHITE}5.${NC} Day of Week ${DIM}(current: $dow)${NC}"
        echo ""
        echo -e "  ${WHITE}P.${NC} Use preset schedule"
        echo -e "  ${WHITE}C.${NC} Continue with this schedule"
        echo -e "  ${WHITE}M.${NC} Back to main menu"
        echo ""
        
        CHOICE=$(get_input "Select field to edit")
        
        case $CHOICE in
            1)
                echo ""
                echo -e "  ${DIM}Options: * (every), 0-59, */5 (every 5), 0,15,30,45${NC}"
                NEW_VAL=$(get_input "Minute value")
                [[ -n "$NEW_VAL" ]] && min="$NEW_VAL"
                ;;
            2)
                echo ""
                echo -e "  ${DIM}Options: * (every), 0-23, */2 (every 2 hours), 9-17${NC}"
                NEW_VAL=$(get_input "Hour value")
                [[ -n "$NEW_VAL" ]] && hour="$NEW_VAL"
                ;;
            3)
                echo ""
                echo -e "  ${DIM}Options: * (every), 1-31, 1,15 (1st and 15th)${NC}"
                NEW_VAL=$(get_input "Day of month value")
                [[ -n "$NEW_VAL" ]] && dom="$NEW_VAL"
                ;;
            4)
                echo ""
                echo -e "  ${DIM}Options: * (every), 1-12, 1,4,7,10 (quarterly)${NC}"
                NEW_VAL=$(get_input "Month value")
                [[ -n "$NEW_VAL" ]] && mon="$NEW_VAL"
                ;;
            5)
                echo ""
                echo -e "  ${DIM}Options: * (every), 0-6 (0=Sun), 1-5 (weekdays), 0,6 (weekend)${NC}"
                NEW_VAL=$(get_input "Day of week value")
                [[ -n "$NEW_VAL" ]] && dow="$NEW_VAL"
                ;;
            p|P)
                echo ""
                echo -e "  ${WHITE}1.${NC} Every minute"
                echo -e "  ${WHITE}2.${NC} Every 5 minutes"
                echo -e "  ${WHITE}3.${NC} Every 15 minutes"
                echo -e "  ${WHITE}4.${NC} Every hour"
                echo -e "  ${WHITE}5.${NC} Every day at midnight"
                echo -e "  ${WHITE}6.${NC} Every day at 6am"
                echo -e "  ${WHITE}7.${NC} Every Sunday at midnight"
                echo -e "  ${WHITE}8.${NC} First of every month"
                echo ""
                PRESET=$(get_input "Select preset")
                case $PRESET in
                    1) min="*"; hour="*"; dom="*"; mon="*"; dow="*" ;;
                    2) min="*/5"; hour="*"; dom="*"; mon="*"; dow="*" ;;
                    3) min="*/15"; hour="*"; dom="*"; mon="*"; dow="*" ;;
                    4) min="0"; hour="*"; dom="*"; mon="*"; dow="*" ;;
                    5) min="0"; hour="0"; dom="*"; mon="*"; dow="*" ;;
                    6) min="0"; hour="6"; dom="*"; mon="*"; dow="*" ;;
                    7) min="0"; hour="0"; dom="*"; mon="*"; dow="0" ;;
                    8) min="0"; hour="0"; dom="1"; mon="*"; dow="*" ;;
                esac
                ;;
            c|C)
                echo ""
                COMMAND=$(get_input "Command to run")
                
                if [[ -z "$COMMAND" ]]; then
                    print_error "No command provided"
                    press_any_key
                    continue
                fi
                
                FULL_LINE="$min $hour $dom $mon $dow $COMMAND"
                
                echo ""
                echo -e "  ${CYAN}Full cron entry:${NC}"
                echo -e "  ${WHITE}$FULL_LINE${NC}"
                echo ""
                
                if confirm_action; then
                    (crontab -l 2>/dev/null; echo "$FULL_LINE") | crontab -
                    if [[ $? -eq 0 ]]; then
                        print_success "Cron job added successfully!"
                    else
                        print_error "Failed to add cron job"
                    fi
                fi
                press_any_key
                return
                ;;
            m|M) return ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Create Job - Manual Entry
#-------------------------------------------------------------------------------

create_job_manual() {
    clear_screen
    print_header "CREATE JOB - MANUAL ENTRY"
    
    print_section "Cron Format"
    echo -e "  ${DIM}┌───────────── minute (0-59)${NC}"
    echo -e "  ${DIM}│ ┌─────────── hour (0-23)${NC}"
    echo -e "  ${DIM}│ │ ┌───────── day of month (1-31)${NC}"
    echo -e "  ${DIM}│ │ │ ┌─────── month (1-12)${NC}"
    echo -e "  ${DIM}│ │ │ │ ┌───── day of week (0-6)${NC}"
    echo -e "  ${DIM}│ │ │ │ │${NC}"
    echo -e "  ${DIM}* * * * * command${NC}"
    echo ""
    echo -e "  ${DIM}Special: @reboot, @yearly, @monthly, @weekly, @daily, @hourly${NC}"
    echo ""
    
    CRON_LINE=$(get_input "Enter full cron line")
    
    if [[ -z "$CRON_LINE" ]]; then
        print_error "No input provided"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${CYAN}Entry:${NC} ${WHITE}$CRON_LINE${NC}"
    echo ""
    
    if confirm_action; then
        (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
        if [[ $? -eq 0 ]]; then
            print_success "Cron job added successfully!"
        else
            print_error "Failed to add cron job"
        fi
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Edit/Delete Jobs
#-------------------------------------------------------------------------------

edit_delete_jobs() {
    while true; do
        clear_screen
        print_header "EDIT/DELETE CRON JOBS"
        
        local jobs=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$")
        
        if [[ -z "$jobs" ]]; then
            print_info "No cron jobs to edit"
            press_any_key
            return
        fi
        
        print_section "Current Jobs"
        
        local i=1
        local job_array=()
        
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            job_array+=("$line")
            printf "  ${WHITE}%-3s${NC} %s\n" "$i." "${line:0:70}"
            ((i++))
        done <<< "$jobs"
        
        echo ""
        echo -e "  ${WHITE}D.${NC} Delete a job"
        echo -e "  ${WHITE}E.${NC} Edit crontab directly"
        echo -e "  ${WHITE}C.${NC} Clear all jobs"
        echo -e "  ${WHITE}M.${NC} Main Menu"
        echo ""
        
        CHOICE=$(get_input "Select option")
        
        case $CHOICE in
            d|D)
                JOB_NUM=$(get_input "Job number to delete")
                if [[ "$JOB_NUM" =~ ^[0-9]+$ ]] && [[ $JOB_NUM -ge 1 ]] && [[ $JOB_NUM -le ${#job_array[@]} ]]; then
                    local job_to_delete="${job_array[$((JOB_NUM-1))]}"
                    echo ""
                    echo -e "  ${YELLOW}Will delete:${NC} ${job_to_delete:0:60}"
                    echo ""
                    if confirm_action; then
                        crontab -l 2>/dev/null | grep -v -F "$job_to_delete" | crontab -
                        print_success "Job deleted"
                    fi
                else
                    print_error "Invalid job number"
                fi
                press_any_key
                ;;
            e|E)
                echo ""
                print_info "Opening crontab in editor..."
                sleep 1
                crontab -e
                ;;
            c|C)
                echo ""
                print_warning "This will remove ALL cron jobs for $USER"
                if confirm_action; then
                    crontab -r 2>/dev/null
                    print_success "All cron jobs cleared"
                fi
                press_any_key
                ;;
            m|M) return ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Common Templates
#-------------------------------------------------------------------------------

common_templates() {
    clear_screen
    print_header "COMMON CRON TEMPLATES"
    
    print_section "Select a Template"
    echo ""
    echo -e "  ${WHITE} 1.${NC} Backup script - daily at 2am"
    echo -e "  ${WHITE} 2.${NC} Log cleanup - weekly on Sunday"
    echo -e "  ${WHITE} 3.${NC} System update check - daily at 6am"
    echo -e "  ${WHITE} 4.${NC} Database backup - every 6 hours"
    echo -e "  ${WHITE} 5.${NC} Health check - every 5 minutes"
    echo -e "  ${WHITE} 6.${NC} SSL certificate renewal - monthly"
    echo -e "  ${WHITE} 7.${NC} Disk space alert - hourly"
    echo -e "  ${WHITE} 8.${NC} Sync files - every 15 minutes"
    echo -e "  ${WHITE} 9.${NC} Restart service - daily at 4am"
    echo -e "  ${WHITE}10.${NC} Report generation - weekdays at 8am"
    echo ""
    
    CHOICE=$(get_input "Select template number")
    
    local schedule="" description=""
    
    case $CHOICE in
        1) schedule="0 2 * * *"; description="Daily at 2:00 AM" ;;
        2) schedule="0 0 * * 0"; description="Every Sunday at midnight" ;;
        3) schedule="0 6 * * *"; description="Daily at 6:00 AM" ;;
        4) schedule="0 */6 * * *"; description="Every 6 hours" ;;
        5) schedule="*/5 * * * *"; description="Every 5 minutes" ;;
        6) schedule="0 0 1 * *"; description="First day of every month" ;;
        7) schedule="0 * * * *"; description="Every hour" ;;
        8) schedule="*/15 * * * *"; description="Every 15 minutes" ;;
        9) schedule="0 4 * * *"; description="Daily at 4:00 AM" ;;
        10) schedule="0 8 * * 1-5"; description="Weekdays at 8:00 AM" ;;
        *) print_error "Invalid selection"; press_any_key; return ;;
    esac
    
    echo ""
    echo -e "  ${CYAN}Schedule:${NC} ${WHITE}$schedule${NC}"
    echo -e "  ${DIM}$description${NC}"
    echo ""
    
    COMMAND=$(get_input "Command to run")
    
    if [[ -z "$COMMAND" ]]; then
        print_error "No command provided"
        press_any_key
        return
    fi
    
    FULL_LINE="$schedule $COMMAND"
    
    echo ""
    echo -e "  ${CYAN}Full cron entry:${NC}"
    echo -e "  ${WHITE}$FULL_LINE${NC}"
    echo ""
    
    if confirm_action; then
        (crontab -l 2>/dev/null; echo "$FULL_LINE") | crontab -
        if [[ $? -eq 0 ]]; then
            print_success "Cron job added successfully!"
        else
            print_error "Failed to add cron job"
        fi
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# View Cron Logs
#-------------------------------------------------------------------------------

view_cron_logs() {
    while true; do
        clear_screen
        print_header "CRON EXECUTION LOGS"
        
        print_section "Log Sources"
        echo -e "  ${WHITE}1.${NC} System cron log (syslog)"
        echo -e "  ${WHITE}2.${NC} Journalctl cron entries"
        echo -e "  ${WHITE}3.${NC} User's cron mail"
        echo -e "  ${WHITE}4.${NC} Custom log file"
        echo ""
        echo -e "  ${WHITE}M.${NC} Main Menu"
        echo ""
        
        CHOICE=$(get_input "Select log source")
        
        case $CHOICE in
            1)
                clear_screen
                print_header "SYSTEM CRON LOG"
                echo ""
                
                if [[ -f /var/log/cron.log ]]; then
                    tail -50 /var/log/cron.log
                elif [[ -f /var/log/syslog ]]; then
                    grep -i cron /var/log/syslog | tail -50
                else
                    print_error "Cron log not found"
                fi
                press_any_key
                ;;
            2)
                clear_screen
                print_header "JOURNALCTL CRON ENTRIES"
                echo ""
                
                if cmd_exists journalctl; then
                    journalctl -u cron --no-pager -n 50 2>/dev/null || \
                    journalctl -u crond --no-pager -n 50 2>/dev/null || \
                    journalctl | grep -i cron | tail -50
                else
                    print_error "journalctl not available"
                fi
                press_any_key
                ;;
            3)
                clear_screen
                print_header "USER CRON MAIL"
                echo ""
                
                MAIL_FILE="/var/mail/$USER"
                if [[ -f "$MAIL_FILE" ]]; then
                    tail -100 "$MAIL_FILE" | grep -A 20 "Subject: Cron"
                else
                    print_info "No mail file found at $MAIL_FILE"
                    print_info "Cron output may be redirected elsewhere"
                fi
                press_any_key
                ;;
            4)
                LOG_PATH=$(get_input "Enter log file path")
                if [[ -f "$LOG_PATH" ]]; then
                    clear_screen
                    print_header "CUSTOM LOG: $LOG_PATH"
                    echo ""
                    tail -50 "$LOG_PATH"
                else
                    print_error "File not found: $LOG_PATH"
                fi
                press_any_key
                ;;
            m|M) return ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# Detect Conflicts
#-------------------------------------------------------------------------------

detect_conflicts() {
    clear_screen
    print_header "CRON JOB CONFLICT DETECTION"
    
    echo ""
    echo -e "  ${YELLOW}Analyzing cron jobs for potential conflicts...${NC}"
    echo ""
    
    local jobs=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$")
    
    if [[ -z "$jobs" ]]; then
        print_info "No cron jobs to analyze"
        press_any_key
        return
    fi
    
    local job_array=()
    local schedule_array=()
    local conflicts_found=0
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        job_array+=("$line")
        
        # Extract schedule
        if [[ "$line" =~ ^([0-9*,/-]+[[:space:]]+[0-9*,/-]+[[:space:]]+[0-9*,/-]+[[:space:]]+[0-9*,/-]+[[:space:]]+[0-9*,/-]+) ]]; then
            schedule_array+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ ^(@[a-z]+) ]]; then
            schedule_array+=("${BASH_REMATCH[1]}")
        fi
    done <<< "$jobs"
    
    print_section "Overlap Analysis"
    
    # Check for same-minute jobs
    declare -A minute_jobs
    for i in "${!schedule_array[@]}"; do
        sched="${schedule_array[$i]}"
        if [[ -n "${minute_jobs[$sched]}" ]]; then
            echo ""
            print_warning "Jobs running at same time:"
            echo -e "    ${DIM}${job_array[${minute_jobs[$sched]}]:0:60}${NC}"
            echo -e "    ${DIM}${job_array[$i]:0:60}${NC}"
            ((conflicts_found++))
        else
            minute_jobs[$sched]=$i
        fi
    done
    
    # Check for resource-heavy jobs at same time
    print_section "Resource Warnings"
    
    local heavy_count=0
    for job in "${job_array[@]}"; do
        if [[ "$job" =~ (backup|rsync|tar|mysqldump|pg_dump|find) ]]; then
            ((heavy_count++))
            echo -e "  ${YELLOW}●${NC} Heavy job: ${job:0:50}..."
        fi
    done
    
    if [[ $heavy_count -gt 1 ]]; then
        echo ""
        print_warning "Multiple resource-intensive jobs detected"
        print_info "Consider staggering backup/sync operations"
    fi
    
    # Check for every-minute jobs
    print_section "Frequency Warnings"
    
    for i in "${!job_array[@]}"; do
        if [[ "${schedule_array[$i]}" =~ ^\*[[:space:]]+\* ]]; then
            print_warning "Runs every minute: ${job_array[$i]:0:50}"
            ((conflicts_found++))
        fi
    done
    
    print_section "Summary"
    
    if [[ $conflicts_found -eq 0 ]]; then
        print_success "No obvious conflicts detected"
    else
        print_warning "Found $conflicts_found potential issue(s)"
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Explain Expression
#-------------------------------------------------------------------------------

explain_expression() {
    clear_screen
    print_header "EXPLAIN CRON EXPRESSION"
    
    echo ""
    echo -e "  ${DIM}Enter a cron expression to get a human-readable explanation${NC}"
    echo -e "  ${DIM}Example: */15 9-17 * * 1-5${NC}"
    echo ""
    
    EXPR=$(get_input "Cron expression (5 fields)")
    
    if [[ -z "$EXPR" ]]; then
        print_error "No expression provided"
        press_any_key
        return
    fi
    
    # Handle special strings
    if [[ "$EXPR" =~ ^@ ]]; then
        case "$EXPR" in
            "@reboot") echo -e "\n  ${GREEN}Runs once at system startup${NC}" ;;
            "@yearly"|"@annually") echo -e "\n  ${GREEN}Runs once a year (Jan 1 at midnight)${NC}" ;;
            "@monthly") echo -e "\n  ${GREEN}Runs once a month (1st at midnight)${NC}" ;;
            "@weekly") echo -e "\n  ${GREEN}Runs once a week (Sunday at midnight)${NC}" ;;
            "@daily"|"@midnight") echo -e "\n  ${GREEN}Runs once a day (at midnight)${NC}" ;;
            "@hourly") echo -e "\n  ${GREEN}Runs once an hour (at minute 0)${NC}" ;;
            *) print_error "Unknown special string" ;;
        esac
        press_any_key
        return
    fi
    
    # Parse 5-field expression
    IFS=' ' read -r min hour dom mon dow <<< "$EXPR"
    
    if [[ -z "$dow" ]]; then
        print_error "Invalid expression. Expected 5 fields: minute hour day month weekday"
        press_any_key
        return
    fi
    
    echo ""
    print_section "Expression Breakdown"
    echo -e "  ${DIM}┌───────────── minute:       ${WHITE}$min${NC}"
    echo -e "  ${DIM}│ ┌─────────── hour:         ${WHITE}$hour${NC}"
    echo -e "  ${DIM}│ │ ┌───────── day of month: ${WHITE}$dom${NC}"
    echo -e "  ${DIM}│ │ │ ┌─────── month:        ${WHITE}$mon${NC}"
    echo -e "  ${DIM}│ │ │ │ ┌───── day of week:  ${WHITE}$dow${NC}"
    echo -e "  ${DIM}│ │ │ │ │${NC}"
    echo -e "  ${DIM}$min $hour $dom $mon $dow${NC}"
    
    print_section "Human Readable"
    echo -e "  ${GREEN}$(explain_cron "$min" "$hour" "$dom" "$mon" "$dow")${NC}"
    
    print_section "Next Runs (approximate)"
    # Simple next run calculation
    echo -e "  ${DIM}(For exact times, use: systemctl list-timers)${NC}"
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Backup/Restore Crontab
#-------------------------------------------------------------------------------

backup_crontab() {
    clear_screen
    print_header "BACKUP CRONTAB"
    
    local backup_file="crontab-backup-$USER-$(date +%Y%m%d-%H%M%S).txt"
    
    FILENAME=$(get_input "Filename (Enter for: $backup_file)")
    [[ -z "$FILENAME" ]] && FILENAME="$backup_file"
    
    crontab -l > "$FILENAME" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        print_success "Crontab backed up to: $FILENAME"
    else
        print_error "Failed to backup crontab (may be empty)"
    fi
    
    press_any_key
}

restore_crontab() {
    clear_screen
    print_header "RESTORE CRONTAB"
    
    echo ""
    echo -e "  ${DIM}Available backup files:${NC}"
    ls -la crontab-backup-*.txt 2>/dev/null | while read line; do
        echo "    $line"
    done
    echo ""
    
    FILENAME=$(get_input "Backup file to restore")
    
    if [[ -z "$FILENAME" ]]; then
        print_error "No filename provided"
        press_any_key
        return
    fi
    
    if [[ ! -f "$FILENAME" ]]; then
        print_error "File not found: $FILENAME"
        press_any_key
        return
    fi
    
    echo ""
    echo -e "  ${CYAN}Contents of $FILENAME:${NC}"
    echo -e "  ${DIM}─────────────────────────────${NC}"
    cat "$FILENAME"
    echo -e "  ${DIM}─────────────────────────────${NC}"
    echo ""
    
    print_warning "This will replace your current crontab"
    
    if confirm_action; then
        crontab "$FILENAME"
        if [[ $? -eq 0 ]]; then
            print_success "Crontab restored from: $FILENAME"
        else
            print_error "Failed to restore crontab"
        fi
    fi
    
    press_any_key
}

#-------------------------------------------------------------------------------
# Main Entry Point
#-------------------------------------------------------------------------------

show_main_menu
