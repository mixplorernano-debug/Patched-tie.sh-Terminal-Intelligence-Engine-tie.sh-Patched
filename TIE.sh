#!/data/data/com.termux/files/usr/bin/bash

# --- CONFIGURATION & COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- DEPENDENCY CHECK ---
check_deps() {
    local deps=("termux-api" "jq" "bc")
    for pkg in "${deps[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            echo -e "${YELLOW}[!] Installing dependency: $pkg...${NC}"
            pkg install "$pkg" -y
        fi
    done
}

# --- CORE INTELLIGENCE FUNCTIONS ---
get_battery_intel() {
    if command -v termux-battery-status &> /dev/null; then
        local batt_json=$(termux-battery-status)
        BATT_PCT=$(echo "$batt_json" | jq -r '.percentage')
        BATT_STAT=$(echo "$batt_json" | jq -r '.status')
        BATT_TEMP=$(echo "$batt_json" | jq -r '.temperature')
    else
        BATT_PCT="N/A"
    fi
}

get_sys_load() {
    UPTIME=$(uptime -p)
    LOAD=$(cut -d' ' -f1-3 /proc/loadavg)
    MEM_FREE=$(free -m | awk '/Mem:/ { print $4 }')
    MEM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
}

get_network_intel() {
    IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
    [ -z "$IP_ADDR" ] && IP_ADDR="Offline"
}

calc_health_score() {
    # Heuristic scoring logic
    local score=100
    [[ "$BATT_PCT" -lt 20 ]] && ((score-=20))
    [[ "$MEM_FREE" -lt 200 ]] && ((score-=30))
    # Check for upgradable packages
    local updates=$(pkg list-upgradable 2>/dev/null | wc -l)
    ((score-=(updates * 2)))
    
    if [ "$score" -gt 80 ]; then HEALTH_COLOR=$GREEN; 
    elif [ "$score" -gt 50 ]; then HEALTH_COLOR=$YELLOW; 
    else HEALTH_COLOR=$RED; fi
    SYSTEM_SCORE=$score
}

# --- UI ENGINE ---
render_dashboard() {
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${BLUE}Terminal Intelligence Engine v3.2.0.1${NC}   ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}Uptime:${NC} $UPTIME"
    echo -e "${CYAN}│${NC}  ${WHITE}Load Avg:${NC} $LOAD"
    echo -e "${CYAN}│${NC}  ${WHITE}Memory:${NC} ${MEM_FREE}MB / ${MEM_TOTAL}MB"
    echo -e "${CYAN}│${NC}  ${WHITE}Battery:${NC} ${BATT_PCT}% [${BATT_STAT}] Temp: ${BATT_TEMP}°C"
    echo -e "${CYAN}│${NC}  ${WHITE}Network:${NC} $IP_ADDR"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│${NC}  ${WHITE}System Health Score:${NC} ${HEALTH_COLOR}${SYSTEM_SCORE}/100${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}Options: [u] Update [c] Clean [q] Quit${NC}"
}

# --- EXECUTION LOOP ---
check_deps
termux-setup-storage

while true; do
    get_battery_intel
    get_sys_load
    get_network_intel
    calc_health_score
    render_dashboard
    
    read -t 5 -n 1 input
    case $input in
        u) 
            echo -e "${GREEN}[*] Synchronizing Repositories...${NC}"
            pkg update -y && pkg upgrade -y
            ;;
        c)
            echo -e "${GREEN}[*] Optimizing Cache...${NC}"
            pkg clean
            rm -rf ~/.cache/*
            ;;
        q)
            exit 0
            ;;
    esac
done
