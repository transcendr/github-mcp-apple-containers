#!/bin/bash
# GitHub MCP Server Runner for Apple Containers
# Enhanced version with configuration support and logging

set -e

# Default configuration
DEFAULT_BIN_DIR="$(dirname "$(dirname "$(realpath "$0")")")/bin"
DEFAULT_BINARY_NAME="github-mcp-server"
DEFAULT_CONTAINER_BIN_DIR="/usr/local/bin"
DEFAULT_CONTAINER_IMAGE="alpine:latest"
DEFAULT_LOG_LEVEL="info"

# Configuration with defaults
BIN_DIR="${GITHUB_MCP_BIN_DIR:-$DEFAULT_BIN_DIR}"
BINARY_NAME="${GITHUB_MCP_BINARY_NAME:-$DEFAULT_BINARY_NAME}"
CONTAINER_BIN_DIR="${GITHUB_MCP_CONTAINER_BIN_DIR:-$DEFAULT_CONTAINER_BIN_DIR}"
CONTAINER_IMAGE="${GITHUB_MCP_CONTAINER_IMAGE:-$DEFAULT_CONTAINER_IMAGE}"
LOG_LEVEL="${GITHUB_MCP_LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
DEBUG="${GITHUB_MCP_DEBUG:-false}"
HEALTH_CHECK="${GITHUB_MCP_HEALTH_CHECK:-false}"
CONFIG_FILE="${GITHUB_MCP_CONFIG:-$HOME/.github-mcp-config}"

# Colors for output (if terminal supports them)
if [[ -t 2 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    GRAY='\033[0;37m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' GRAY='' NC=''
fi

# Logging functions
log_debug() {
    if [[ "$DEBUG" == "true" || "$LOG_LEVEL" == "debug" ]]; then
        echo -e "${GRAY}[DEBUG] $1${NC}" >&2
    fi
}

log_info() {
    if [[ "$LOG_LEVEL" != "error" ]]; then
        echo -e "${BLUE}[INFO] $1${NC}" >&2
    fi
}

log_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}" >&2
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

log_success() {
    if [[ "$LOG_LEVEL" != "error" ]]; then
        echo -e "${GREEN}[SUCCESS] $1${NC}" >&2
    fi
}

# Configuration management
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Loading configuration from $CONFIG_FILE"
        
        # Source the config file safely
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Remove quotes and export
            value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
            case "$key" in
                BIN_DIR|BINARY_NAME|CONTAINER_BIN_DIR|CONTAINER_IMAGE|LOG_LEVEL|DEBUG|HEALTH_CHECK)
                    declare -g "$key=$value"
                    log_debug "Config: $key=$value"
                    ;;
            esac
        done < "$CONFIG_FILE"
    fi
}

save_config() {
    log_info "Saving configuration to $CONFIG_FILE"
    
    cat > "$CONFIG_FILE" << EOF
# GitHub MCP Server Apple Container Configuration
# Generated on $(date)

# Binary location
BIN_DIR=$BIN_DIR
BINARY_NAME=$BINARY_NAME

# Container configuration
CONTAINER_BIN_DIR=$CONTAINER_BIN_DIR
CONTAINER_IMAGE=$CONTAINER_IMAGE

# Logging
LOG_LEVEL=$LOG_LEVEL
DEBUG=$DEBUG

# Features
HEALTH_CHECK=$HEALTH_CHECK
EOF
    
    log_success "Configuration saved"
}

# Health check function
health_check() {
    if [[ "$HEALTH_CHECK" != "true" ]]; then
        return 0
    fi
    
    log_info "Performing health check..."
    
    # Check if container command exists
    if ! command -v container &> /dev/null; then
        log_error "Apple containers not available (container command not found)"
        return 1
    fi
    
    # Check if binary exists
    if [[ ! -f "$BIN_DIR/$BINARY_NAME" ]]; then
        log_error "Binary not found at $BIN_DIR/$BINARY_NAME"
        return 1
    fi
    
    # Check binary permissions
    if [[ ! -x "$BIN_DIR/$BINARY_NAME" ]]; then
        log_warning "Binary is not executable, fixing permissions"
        chmod +x "$BIN_DIR/$BINARY_NAME"
    fi
    
    # Test container connectivity
    log_debug "Testing container image availability"
    if ! container run --rm "$CONTAINER_IMAGE" echo "test" &> /dev/null; then
        log_error "Container image $CONTAINER_IMAGE not available or container runtime not working"
        return 1
    fi
    
    log_success "Health check passed"
    return 0
}

# Token management
get_token() {
    local token=""
    
    # Try command line argument first
    if [[ -n "$1" ]]; then
        # Validate token format (basic check)
        if [[ "$1" =~ ^gh[ps]_[a-zA-Z0-9]{36,255}$ ]]; then
            token="$1"
            log_debug "Using token from command line argument"
        else
            log_warning "Token format doesn't match GitHub PAT pattern"
            token="$1"  # Use it anyway, might be valid
        fi
    fi
    
    # Try environment variable as fallback
    if [[ -z "$token" && -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
        token="$GITHUB_PERSONAL_ACCESS_TOKEN"
        log_debug "Using token from environment variable"
    fi
    
    # Try environment variable alternative names
    if [[ -z "$token" && -n "$GITHUB_TOKEN" ]]; then
        token="$GITHUB_TOKEN"
        log_debug "Using token from GITHUB_TOKEN environment variable"
    fi
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    echo "$token"
    return 0
}

# Container management
run_container() {
    local token="$1"
    shift
    
    log_info "Starting GitHub MCP server in Apple container"
    log_debug "Container image: $CONTAINER_IMAGE"
    log_debug "Binary path: $BIN_DIR/$BINARY_NAME"
    log_debug "Arguments: $*"
    
    # Container run command with enhanced options
    local container_args=(
        "run"
        "-i"                                              # Interactive for stdio
        "--rm"                                            # Remove container on exit
        "--volume" "$BIN_DIR:$CONTAINER_BIN_DIR:ro"      # Mount binary directory
        "-e" "GITHUB_PERSONAL_ACCESS_TOKEN=$token"       # Pass token
    )
    
    # Add resource limits if specified
    if [[ -n "$CONTAINER_MEMORY_LIMIT" ]]; then
        container_args+=("--memory" "$CONTAINER_MEMORY_LIMIT")
        log_debug "Memory limit: $CONTAINER_MEMORY_LIMIT"
    fi
    
    if [[ -n "$CONTAINER_CPU_LIMIT" ]]; then
        container_args+=("--cpus" "$CONTAINER_CPU_LIMIT")
        log_debug "CPU limit: $CONTAINER_CPU_LIMIT"
    fi
    
    # Add the image and command
    container_args+=("$CONTAINER_IMAGE")
    container_args+=("$CONTAINER_BIN_DIR/$BINARY_NAME")
    container_args+=("stdio")
    container_args+=("$@")
    
    # Execute the container
    log_debug "Executing: container ${container_args[*]}"
    exec container "${container_args[@]}"
}

# Usage information
show_usage() {
    cat << EOF
GitHub MCP Server Runner for Apple Containers

Usage: $0 [OPTIONS] <token> [server-args...]
       $0 [OPTIONS] --env-token [server-args...]

Arguments:
    token                   GitHub Personal Access Token

Options:
    --env-token            Use token from environment variables
    --config FILE          Configuration file (default: ~/.github-mcp-config)
    --bin-dir DIR          Binary directory (default: auto-detected)
    --binary-name NAME     Binary filename (default: github-mcp-server)
    --container-image IMG  Container image (default: alpine:latest)
    --log-level LEVEL      Log level: debug, info, warn, error (default: info)
    --debug                Enable debug logging
    --health-check         Perform health check before running
    --save-config          Save current configuration to file
    -h, --help             Show this help message

Environment Variables:
    GITHUB_PERSONAL_ACCESS_TOKEN    GitHub Personal Access Token
    GITHUB_TOKEN                    Alternative token variable
    GITHUB_MCP_BIN_DIR             Binary directory
    GITHUB_MCP_BINARY_NAME         Binary filename
    GITHUB_MCP_CONTAINER_IMAGE     Container image
    GITHUB_MCP_LOG_LEVEL           Log level
    GITHUB_MCP_DEBUG               Enable debug mode (true/false)
    GITHUB_MCP_HEALTH_CHECK        Enable health check (true/false)
    GITHUB_MCP_CONFIG              Configuration file path

Configuration File Format:
    The configuration file should contain key=value pairs:
    
    BIN_DIR=/path/to/bin
    BINARY_NAME=github-mcp-server
    CONTAINER_IMAGE=alpine:latest
    LOG_LEVEL=info
    DEBUG=false
    HEALTH_CHECK=true

Examples:
    # Basic usage with token
    $0 ghp_xxxxxxxxxxxxxxxxxxxx

    # Use environment token
    export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
    $0 --env-token

    # Debug mode with health check
    $0 --debug --health-check ghp_xxxxxxxxxxxxxxxxxxxx

    # Custom configuration
    $0 --config ./my-config --log-level debug ghp_xxxxxxxxxxxxxxxxxxxx

Claude Desktop Configuration:
    {
      "mcpServers": {
        "github": {
          "command": "/path/to/run.sh",
          "args": ["ghp_xxxxxxxxxxxxxxxxxxxx"]
        }
      }
    }

Claude Code CLI Configuration:
    claude mcp add github /path/to/run.sh ghp_xxxxxxxxxxxxxxxxxxxx

EOF
}

# Parse command line arguments
use_env_token=false
save_config_flag=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env-token)
            use_env_token=true
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --bin-dir)
            BIN_DIR="$2"
            shift 2
            ;;
        --binary-name)
            BINARY_NAME="$2"
            shift 2
            ;;
        --container-image)
            CONTAINER_IMAGE="$2"
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --debug)
            DEBUG="true"
            shift
            ;;
        --health-check)
            HEALTH_CHECK="true"
            shift
            ;;
        --save-config)
            save_config_flag=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            # First non-option argument is the token (if not using env token)
            break
            ;;
    esac
done

# Main execution
main() {
    log_debug "GitHub MCP Server Runner starting"
    
    # Load configuration
    load_config
    
    # Save configuration if requested
    if [[ "$save_config_flag" == "true" ]]; then
        save_config
        exit 0
    fi
    
    # Get token
    local token
    if [[ "$use_env_token" == "true" ]]; then
        if ! token=$(get_token); then
            log_error "No token found in environment variables"
            log_error "Set GITHUB_PERSONAL_ACCESS_TOKEN or GITHUB_TOKEN"
            exit 1
        fi
    else
        if ! token=$(get_token "$1"); then
            log_error "GitHub Personal Access Token required"
            log_error "Usage: $0 <token> [args...]"
            log_error "   or: $0 --env-token [args...]"
            exit 1
        fi
        shift  # Remove token from arguments
    fi
    
    # Validate binary exists
    if [[ ! -f "$BIN_DIR/$BINARY_NAME" ]]; then
        log_error "GitHub MCP server binary not found at $BIN_DIR/$BINARY_NAME"
        log_error "Run the build script first: scripts/build.sh"
        exit 1
    fi
    
    # Health check
    if ! health_check; then
        log_error "Health check failed"
        exit 1
    fi
    
    log_success "Starting GitHub MCP server"
    
    # Run the container
    run_container "$token" "$@"
}

# Run main function
main "$@"