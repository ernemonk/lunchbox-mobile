#!/bin/bash
# Unified local development server launcher
# Allows running multiple Cloud Functions locally with automatic port management

set -e

BACKEND_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$BACKEND_DIR"

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Track running processes
declare -a PIDS=()
declare -a FUNCTION_NAMES=()

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Stopping all local servers...${NC}"
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✅ All servers stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Port assignments
declare -A FUNCTION_PORTS=(
    ["barcode-enrichment"]=8080
    ["image-recognition"]=8081
    ["generate-recipes"]=8082
)

# Function entry points
declare -A FUNCTION_TARGETS=(
    ["barcode-enrichment"]="barcode_enrichment"
    ["image-recognition"]="image_recognition"
    ["generate-recipes"]="generate_recipes"
)

# Function source files
declare -A FUNCTION_SOURCES=(
    ["barcode-enrichment"]="main.py"
    ["image-recognition"]="image_recognition.py"
    ["generate-recipes"]="main.py"
)

# Function descriptions
declare -A FUNCTION_DESCRIPTIONS=(
    ["barcode-enrichment"]="🔖 Barcode Lookup & Enrichment"
    ["image-recognition"]="🍎 Image Recognition (Cloud Vision)"
    ["generate-recipes"]="🤖 AI Recipe Generation (Gemini)"
)

# Discover available functions
discover_functions() {
    local functions=()
    for dir in "$BACKEND_DIR"/*; do
        if [ -d "$dir" ] && [ -f "$dir/function.json" ]; then
            local func_name=$(basename "$dir")
            functions+=("$func_name")
        fi
    done
    echo "${functions[@]}"
}

# Check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Setup function environment
setup_function() {
    local func_name=$1
    local func_dir="$BACKEND_DIR/$func_name"
    
    cd "$func_dir"
    
    # Create venv if needed
    if [ ! -d "venv" ]; then
        echo -e "${CYAN}📦 Creating virtual environment for $func_name...${NC}"
        python3 -m venv venv
        venv/bin/pip install -q --upgrade pip
        venv/bin/pip install -q functions-framework flask flask-cors
        venv/bin/pip install -q -r requirements.txt
    fi
    
    # Load environment variables
    local env_file=""
    case "$func_name" in
        "barcode-enrichment")
            env_file=".env.barcode"
            ;;
        "generate-recipes")
            env_file=".env.recipes"
            ;;
    esac
    
    if [ -n "$env_file" ] && [ -f "$env_file" ]; then
        echo -e "${CYAN}🔑 Loading environment from $env_file${NC}"
        export $(grep -v '^#' "$env_file" | xargs)
    fi
    
    # Special handling for image-recognition
    if [ "$func_name" = "image-recognition" ]; then
        if [ -f "../local-dev/vision-key.json" ]; then
            export GOOGLE_APPLICATION_CREDENTIALS="$BACKEND_DIR/local-dev/vision-key.json"
        elif [ -f "vision-key.json" ]; then
            export GOOGLE_APPLICATION_CREDENTIALS="$func_dir/vision-key.json"
        fi
    fi
}

# Start a function server
start_function() {
    local func_name=$1
    local port=${FUNCTION_PORTS[$func_name]}
    local target=${FUNCTION_TARGETS[$func_name]}
    local source=${FUNCTION_SOURCES[$func_name]}
    local func_dir="$BACKEND_DIR/$func_name"
    
    # Check if port is available
    if ! check_port $port; then
        echo -e "${RED}❌ Port $port is already in use. Kill the process first:${NC}"
        echo "   lsof -ti:$port | xargs kill -9"
        return 1
    fi
    
    # Setup environment
    setup_function "$func_name"
    
    # Start the server in background
    cd "$func_dir"
    
    echo -e "${GREEN}🚀 Starting $func_name on port $port...${NC}"
    
    # Start functions-framework in background, redirect output to log file
    mkdir -p "$BACKEND_DIR/logs"
    local log_file="$BACKEND_DIR/logs/${func_name}.log"
    
    venv/bin/functions-framework \
        --target="$target" \
        --source="$source" \
        --port="$port" \
        > "$log_file" 2>&1 &
    
    local pid=$!
    PIDS+=($pid)
    FUNCTION_NAMES+=("$func_name")
    
    # Wait a bit and check if it started
    sleep 2
    if kill -0 $pid 2>/dev/null; then
        echo -e "${GREEN}✅ $func_name running on http://localhost:$port (PID: $pid)${NC}"
        echo -e "${CYAN}   Logs: $log_file${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to start $func_name${NC}"
        echo -e "${RED}   Check logs: $log_file${NC}"
        return 1
    fi
}

# Show menu and get selection
show_menu() {
    local functions=($(discover_functions))
    
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   🚀 Lunchbox Local Development Server   ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Available functions:${NC}"
    echo ""
    
    local i=1
    for func in "${functions[@]}"; do
        local desc=${FUNCTION_DESCRIPTIONS[$func]:-"$func"}
        local port=${FUNCTION_PORTS[$func]:-"????"}
        echo -e "  ${GREEN}[$i]${NC} $desc"
        echo -e "      ${CYAN}Function:${NC} $func"
        echo -e "      ${CYAN}Port:${NC} $port"
        echo ""
        i=$((i + 1))
    done
    
    echo -e "  ${GREEN}[A]${NC} All functions"
    echo -e "  ${GREEN}[Q]${NC} Quit"
    echo ""
    echo -e "${YELLOW}Select functions to run (e.g., 1 or 1,2,3 or A):${NC} "
    read -r selection
    
    echo "$selection|${functions[@]}"
}

# Parse selection
parse_selection() {
    local selection=$1
    shift
    local functions=("$@")
    local selected=()
    
    # Handle 'A' or 'a' for all
    if [[ "$selection" =~ ^[Aa]$ ]]; then
        selected=("${functions[@]}")
    # Handle 'Q' or 'q' for quit
    elif [[ "$selection" =~ ^[Qq]$ ]]; then
        echo ""
        exit 0
    # Handle comma-separated numbers
    else
        IFS=',' read -ra NUMS <<< "$selection"
        for num in "${NUMS[@]}"; do
            num=$(echo "$num" | xargs) # trim whitespace
            if [[ "$num" =~ ^[0-9]+$ ]]; then
                local index=$((num - 1))
                if [ $index -ge 0 ] && [ $index -lt ${#functions[@]} ]; then
                    selected+=("${functions[$index]}")
                fi
            fi
        done
    fi
    
    echo "${selected[@]}"
}

# Main function
main() {
    # Show menu and get selection
    local menu_result=$(show_menu)
    local selection=$(echo "$menu_result" | cut -d'|' -f1)
    local all_functions=$(echo "$menu_result" | cut -d'|' -f2)
    
    local selected_functions=($(parse_selection "$selection" $all_functions))
    
    if [ ${#selected_functions[@]} -eq 0 ]; then
        echo -e "${RED}No valid functions selected${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}Starting ${#selected_functions[@]} function(s)...${NC}"
    echo ""
    
    # Start each selected function
    for func in "${selected_functions[@]}"; do
        start_function "$func" || true
        echo ""
    done
    
    if [ ${#PIDS[@]} -eq 0 ]; then
        echo -e "${RED}No functions started successfully${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║          🎉 All servers running!          ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Running functions:${NC}"
    for i in "${!FUNCTION_NAMES[@]}"; do
        local func_name="${FUNCTION_NAMES[$i]}"
        local port="${FUNCTION_PORTS[$func_name]}"
        echo -e "  • ${CYAN}$func_name${NC} → http://localhost:$port"
    done
    echo ""
    echo -e "${YELLOW}📝 Logs directory: $BACKEND_DIR/logs/${NC}"
    echo -e "${YELLOW}🛑 Press Ctrl+C to stop all servers${NC}"
    echo ""
    
    # Wait for all processes
    for pid in "${PIDS[@]}"; do
        wait $pid 2>/dev/null || true
    done
}

# Run main
main
