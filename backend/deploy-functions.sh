#!/bin/bash
# ============================================================================
# Unified Cloud Functions Deployment Script
# ============================================================================
# 
# This script auto-discovers and deploys Google Cloud Functions from the
# backend directory. Each function is configured via a function.json file.
#
# Features:
# - Auto-discovery of deployable functions
# - Metadata-driven deployment (function.json)
# - Environment variable management (.env files)
# - Shared dependencies support
# - Interactive and non-interactive modes
# - Local environment variable export
#
# Usage:
#   ./deploy-functions.sh              # Interactive mode
#   ./deploy-functions.sh --all        # Deploy all functions
#   ./deploy-functions.sh <name>       # Deploy specific function
#   ./deploy-functions.sh --list       # List available functions
#   ./deploy-functions.sh --export-env # Export env vars locally
# ============================================================================

set -e

# Ensure we're using bash 4+ (or compatible behavior)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "⚠️  Warning: Bash 3 detected. Some features may not work optimally."
    echo "Consider upgrading: brew install bash"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# Utility Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo "============================================================"
}

# ============================================================================
# Function Discovery
# ============================================================================

discover_functions() {
    # Find all function.json files and return as newline-separated list
    find "$BACKEND_DIR" \( -name "function.json" -o -name "*.function.json" \) 2>/dev/null | while read -r config_file; do
        # Verify it has a name field
        local name="$(jq -r '.name' "$config_file" 2>/dev/null || echo "")"
        if [ -n "$name" ] && [ "$name" != "null" ]; then
            echo "$config_file"
        fi
    done
}

# ============================================================================
# Environment Variable Loading
# ============================================================================

load_env_file() {
    local env_file="$1"
    local function_dir="$2"
    local env_vars=""
    
    if [ -f "$function_dir/$env_file" ]; then
        log_info "Loading environment variables from: $env_file"
        
        # Read .env file and build env vars string
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes and whitespace
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//" | xargs)
            
            # Skip placeholder values
            if [[ "$value" != "your_"* ]] && [ -n "$value" ]; then
                if [ -z "$env_vars" ]; then
                    env_vars="$key=$value"
                else
                    env_vars="$env_vars,$key=$value"
                fi
            fi
        done < "$function_dir/$env_file"
    fi
    
    echo "$env_vars"
}

# ============================================================================
# Deployment Function
# ============================================================================

deploy_function() {
    local config_file="$1"
    local function_dir="$(dirname "$config_file")"
    
    # Parse function.json
    local name=$(jq -r '.name' "$config_file")
    local description=$(jq -r '.description' "$config_file")
    local icon=$(jq -r '.icon // "📦"' "$config_file")
    local entrypoint=$(jq -r '.entrypoint' "$config_file")
    local runtime=$(jq -r '.runtime // "python311"' "$config_file")
    local memory=$(jq -r '.memory // "512MB"' "$config_file")
    local timeout=$(jq -r '.timeout // "60s"' "$config_file")
    local region=$(jq -r '.region // "us-central1"' "$config_file")
    local env_file=$(jq -r '.env_file // ""' "$config_file")
    local shared_deps=$(jq -r '.shared_dependencies // false' "$config_file")
    local main_py_content=$(jq -r '.main_py_content // ""' "$config_file")
    
    log_section "$icon  Deploying: $name"
    log_info "Description: $description"
    log_info "Location: $function_dir"
    
    # Create temporary deploy directory
    local deploy_dir=$(mktemp -d)
    log_info "Preparing deployment package..."
    
    # Copy source files (bash 3 compatible)
    local source_files=$(jq -r '.source_files[]' "$config_file")
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            if [ -f "$function_dir/$file" ]; then
                cp "$function_dir/$file" "$deploy_dir/"
            else
                log_error "Required file not found: $file"
                rm -rf "$deploy_dir"
                return 1
            fi
        fi
    done <<< "$source_files"
    
    # Create custom main.py if specified
    if [ -n "$main_py_content" ] && [ "$main_py_content" != "null" ]; then
        echo "$main_py_content" > "$deploy_dir/main.py"
        log_info "Generated custom main.py"
    fi
    
    # Copy shared dependencies if needed
    if [ "$shared_deps" = "true" ]; then
        local shared_dir="$BACKEND_DIR/shared"
        if [ -d "$shared_dir" ]; then
            mkdir -p "$deploy_dir/shared"
            cp "$shared_dir"/*.py "$deploy_dir/shared/" 2>/dev/null || true
            if [ -f "$shared_dir/requirements.txt" ]; then
                cp "$shared_dir/requirements.txt" "$deploy_dir/shared/requirements.txt"
            fi
            log_info "Copied shared dependencies"
        fi
    fi
    
    # Load environment variables
    local env_vars=""
    if [ -n "$env_file" ] && [ "$env_file" != "null" ]; then
        env_vars=$(load_env_file "$env_file" "$function_dir")
    fi
    
    # Build deploy command
    local deploy_cmd="gcloud functions deploy $name \
      --runtime $runtime \
      --trigger-http \
      --allow-unauthenticated \
      --region $region \
      --memory $memory \
      --timeout $timeout \
      --entry-point $entrypoint \
      --source $deploy_dir \
      --quiet"
    
    # Add environment variables if any
    if [ -n "$env_vars" ]; then
        deploy_cmd="$deploy_cmd --set-env-vars $env_vars"
        log_info "Deploying with $(echo "$env_vars" | tr ',' '\n' | wc -l) environment variables"
    fi
    
    # Execute deployment
    log_info "Deploying to Google Cloud Functions..."
    echo ""
    
    if eval $deploy_cmd; then
        local function_url=$(gcloud functions describe "$name" --region "$region" --format="value(serviceConfig.uri)" 2>/dev/null)
        log_success "Deployed successfully!"
        echo -e "${CYAN}📡 URL:${NC} $function_url"
        
        # Store URL for summary (bash 3 compatible)
        add_deployed_url "$name" "$function_url"
        add_success "$name"
    else
        log_error "Deployment failed for $name"
        add_failed "$name"
    fi
    
    # Cleanup
    rm -rf "$deploy_dir"
    echo ""
}

# ============================================================================
# List Functions
# ============================================================================

list_functions() {
    log_section "📋 Available Cloud Functions"
    
    # Read configs into array (bash 3 compatible)
    local configs_raw=$(discover_functions)
    if [ -z "$configs_raw" ]; then
        log_warning "No functions found with function.json configuration"
        return 1
    fi
    
    # Convert to array
    local configs=()
    while IFS= read -r line; do
        [ -n "$line" ] && configs+=("$line")
    done <<< "$configs_raw"
    
    echo ""
    printf "%-3s %-30s %-50s %s\n" "#" "NAME" "DESCRIPTION" "LOCATION"
    echo "────────────────────────────────────────────────────────────────────────────────────────────"
    
    local idx=1
    for config in "${configs[@]}"; do
        local name=$(jq -r '.name' "$config")
        local description=$(jq -r '.description' "$config")
        local icon=$(jq -r '.icon // "📦"' "$config")
        local dir=$(dirname "$config")
        local rel_dir="${dir#$BACKEND_DIR/}"
        
        printf "${CYAN}%-3s${NC} ${BOLD}%-30s${NC} %-50s ${YELLOW}%s${NC}\n" \
            "$icon" "$name" "$description" "$rel_dir"
        ((idx++))
    done
    
    echo ""
}

# ============================================================================
# Export Environment Variables
# ============================================================================

export_env_vars() {
    log_section "📤 Exporting Environment Variables"
    
    # Read configs into array
    local configs_raw=$(discover_functions)
    local configs=()
    while IFS= read -r line; do
        [ -n "$line" ] && configs+=("$line")
    done <<< "$configs_raw"
    
    local export_file="$BACKEND_DIR/.env.local"
    
    echo "# Auto-generated local environment variables" > "$export_file"
    echo "# Generated on: $(date)" >> "$export_file"
    echo "" >> "$export_file"
    
    for config in "${configs[@]}"; do
        local name=$(jq -r '.name' "$config")
        local env_file=$(jq -r '.env_file // ""' "$config")
        local function_dir="$(dirname "$config")"
        
        if [ -n "$env_file" ] && [ "$env_file" != "null" ] && [ -f "$function_dir/$env_file" ]; then
            echo "# $name" >> "$export_file"
            cat "$function_dir/$env_file" | grep -v '^#' | grep -v '^$' >> "$export_file"
            echo "" >> "$export_file"
            log_success "Exported: $name ($env_file)"
        fi
    done
    
    log_success "Environment variables exported to: $export_file"
    echo ""
    echo "To use these locally, run:"
    echo "  source $export_file"
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

check_prerequisites() {
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI not found. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        log_error "jq not found. Please install jq: brew install jq"
        exit 1
    fi
    
    # Check authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        log_error "Not logged in to gcloud. Run: gcloud auth login"
        exit 1
    fi
    
    # Get project
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        log_error "No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

# Track deployment status (bash 3 compatible)
DEPLOYED_URLS_NAMES=""
DEPLOYED_URLS_VALUES=""
DEPLOY_SUCCESS_LIST=""
DEPLOY_FAILED_LIST=""

# Helper functions for bash 3 compatibility
add_deployed_url() {
    DEPLOYED_URLS_NAMES="$DEPLOYED_URLS_NAMES|$1"
    DEPLOYED_URLS_VALUES="$DEPLOYED_URLS_VALUES|$2"
}

get_deployed_url() {
    local name="$1"
    local idx=0
    IFS='|' read -ra names <<< "$DEPLOYED_URLS_NAMES"
    IFS='|' read -ra values <<< "$DEPLOYED_URLS_VALUES"
    for i in "${!names[@]}"; do
        if [ "${names[$i]}" = "$name" ]; then
            echo "${values[$i]}"
            return
        fi
    done
}

add_success() {
    DEPLOY_SUCCESS_LIST="$DEPLOY_SUCCESS_LIST|$1"
}

add_failed() {
    DEPLOY_FAILED_LIST="$DEPLOY_FAILED_LIST|$1"
}

main() {
    echo ""
    echo -e "${BOLD}${CYAN}☁️  Google Cloud Functions Unified Deployment${NC}"
    echo "============================================================"
    echo ""
    
    # Handle command line arguments
    case "${1:-}" in
        --list|-l)
            list_functions
            exit 0
            ;;
        --export-env|-e)
            export_env_vars
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [FUNCTION_NAME]"
            echo ""
            echo "Options:"
            echo "  --list, -l         List all available functions"
            echo "  --all, -a          Deploy all functions"
            echo "  --export-env, -e   Export all env vars to .env.local"
            echo "  --help, -h         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Interactive mode"
            echo "  $0 --all              # Deploy all functions"
            echo "  $0 image-recognition  # Deploy specific function"
            exit 0
            ;;
    esac
    
    # Pre-flight checks
    check_prerequisites
    
    log_info "Project: $PROJECT_ID"
    echo ""
    
    # Discover functions
    local configs_raw=$(discover_functions)
    
    if [ -z "$configs_raw" ]; then
        log_error "No deployable functions found"
        exit 1
    fi
    
    # Convert to array
    local configs=()
    while IFS= read -r line; do
        [ -n "$line" ] && configs+=("$line")
    done <<< "$configs_raw"
    
    log_success "Found ${#configs[@]} deployable function(s)"
    
    # Determine which functions to deploy
    local functions_to_deploy=()
    
    if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
        # Deploy all functions
        functions_to_deploy=("${configs[@]}")
    elif [ -n "$1" ]; then
        # Deploy specific function by name
        local found=false
        for config in "${configs[@]}"; do
            local name=$(jq -r '.name' "$config")
            if [ "$name" = "$1" ]; then
                functions_to_deploy=("$config")
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            log_error "Function '$1' not found"
            list_functions
            exit 1
        fi
    else
        # Interactive mode
        list_functions
        
        echo "Select functions to deploy:"
        echo "  1) Deploy all"
        echo "  2) Choose specific function(s)"
        echo ""
        read -p "Enter choice [1-2]: " choice
        
        case $choice in
            1)
                functions_to_deploy=("${configs[@]}")
                ;;
            2)
                echo ""
                echo "Enter function names (space-separated):"
                read -a function_names
                
                for fname in "${function_names[@]}"; do
                    for config in "${configs[@]}"; do
                        local name=$(jq -r '.name' "$config")
                        if [ "$name" = "$fname" ]; then
                            functions_to_deploy+=("$config")
                        fi
                    done
                done
                ;;
            *)
                log_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
    
    # Deploy selected functions
    echo ""
    log_section "🚀 Starting Deployment"
    log_info "Deploying ${#functions_to_deploy[@]} function(s)"
    echo ""
    
    for config in "${functions_to_deploy[@]}"; do
        deploy_function "$config"
    done
    
    # Print summary
    log_section "📊 Deployment Summary"
    
    # Convert pipe-separated strings to arrays
    IFS='|' read -ra success_array <<< "$DEPLOY_SUCCESS_LIST"
    IFS='|' read -ra failed_array <<< "$DEPLOY_FAILED_LIST"
    
    # Count (skip empty first element from split)
    local success_count=0
    for item in "${success_array[@]}"; do
        [ -n "$item" ] && ((success_count++))
    done
    
    local failed_count=0
    for item in "${failed_array[@]}"; do
        [ -n "$item" ] && ((failed_count++))
    done
    
    if [ $success_count -gt 0 ]; then
        echo -e "${GREEN}${BOLD}Successfully deployed ($success_count):${NC}"
        for name in "${success_array[@]}"; do
            if [ -n "$name" ]; then
                local url=$(get_deployed_url "$name")
                echo -e "  ${GREEN}✅${NC} $name"
                echo -e "     ${CYAN}${url}${NC}"
            fi
        done
        echo ""
    fi
    
    if [ $failed_count -gt 0 ]; then
        echo -e "${RED}${BOLD}Failed deployments ($failed_count):${NC}"
        for name in "${failed_array[@]}"; do
            if [ -n "$name" ]; then
                echo -e "  ${RED}❌${NC} $name"
            fi
        done
        echo ""
    fi
    
    echo "============================================================"
    log_success "Deployment complete!"
}

# Run main
main "$@"
