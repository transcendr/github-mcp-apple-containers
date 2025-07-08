#!/bin/bash
# GitHub MCP Server Setup Helper for Apple Containers
# Enhanced version with interactive configuration and validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BINARY_NAME="github-mcp-server"

# Detect if running as installed version or from source
if [[ "$(basename "$0")" == "github-mcp-setup" ]]; then
    # Running as installed version
    RUNNER_SCRIPT="$(dirname "$(realpath "$0")")/github-mcp-run"
    BUILD_SCRIPT=""  # Build script not available in installed version
    BIN_DIR="$(dirname "$(realpath "$0")")/github-mcp-bin"
else
    # Running from source
    RUNNER_SCRIPT="$SCRIPT_DIR/run.sh"
    BUILD_SCRIPT="$SCRIPT_DIR/build.sh"
    BIN_DIR="$PROJECT_DIR/bin"
fi

# Colors for output
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_step() {
    echo -e "${BOLD}🔹 $1${NC}" >&2
}

# Interactive functions
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " response
            response=${response:-y}
        else
            read -p "$prompt [y/N]: " response
            response=${response:-n}
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

ask_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

# System validation
check_prerequisites() {
    log_step "Checking system prerequisites"
    
    local issues=0
    
    # Check for Apple containers
    if ! command -v container &> /dev/null; then
        log_error "Apple containers not available (container command not found)"
        log_info "This tool requires Apple containers to be installed and available"
        ((issues++))
    else
        log_success "Apple containers available"
    fi
    
    # Check for git (needed for building)
    if ! command -v git &> /dev/null; then
        log_warning "Git not found - needed for building from source"
        ((issues++))
    else
        log_success "Git available"
    fi
    
    # Check for Go (needed for building)
    if ! command -v go &> /dev/null; then
        log_warning "Go not found - needed for building from source"
        log_info "You can still use pre-built binaries"
    else
        local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/go//')
        log_success "Go available (version $go_version)"
    fi
    
    return $issues
}

# Binary management
check_binary() {
    log_step "Checking GitHub MCP server binary"
    
    if [[ -f "$BIN_DIR/$BINARY_NAME" ]]; then
        local file_size=$(ls -lh "$BIN_DIR/$BINARY_NAME" | awk '{print $5}')
        log_success "Binary found ($file_size)"
        return 0
    else
        log_warning "Binary not found at $BIN_DIR/$BINARY_NAME"
        return 1
    fi
}

build_binary() {
    log_step "Building GitHub MCP server binary"
    
    # Check if we're running as installed version (no build script available)
    if [[ -z "$BUILD_SCRIPT" ]]; then
        log_error "Cannot build binary from installed version"
        log_info "Binary building is only available when running from source"
        log_info "Please download the repository and run setup from source, or"
        log_info "use the pre-built binary that was installed"
        return 1
    fi
    
    if [[ ! -f "$BUILD_SCRIPT" ]]; then
        log_error "Build script not found at $BUILD_SCRIPT"
        return 1
    fi
    
    log_info "Starting build process..."
    if "$BUILD_SCRIPT" --output "$BIN_DIR"; then
        log_success "Binary built successfully"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

# Token management
validate_token() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        return 1
    fi
    
    # Basic format validation
    if [[ ! "$token" =~ ^gh[ps]_[a-zA-Z0-9]{36,255}$ ]]; then
        log_warning "Token format doesn't match standard GitHub PAT pattern"
        log_info "This might still be a valid token (fine-grained PATs have different formats)"
    fi
    
    return 0
}

get_github_token() {
    log_step "GitHub Personal Access Token configuration"
    
    local token=""
    
    # Check environment variables first
    if [[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
        token="$GITHUB_PERSONAL_ACCESS_TOKEN"
        log_info "Found token in GITHUB_PERSONAL_ACCESS_TOKEN environment variable"
    elif [[ -n "$GITHUB_TOKEN" ]]; then
        token="$GITHUB_TOKEN"
        log_info "Found token in GITHUB_TOKEN environment variable"
    fi
    
    if [[ -n "$token" ]]; then
        if validate_token "$token"; then
            log_success "GitHub token configured"
            echo "$token"
            return 0
        else
            log_warning "Found token but validation failed"
        fi
    fi
    
    # Interactive token input
    echo >&2
    log_info "You need a GitHub Personal Access Token to use the GitHub MCP server"
    log_info "You can create one at: https://github.com/settings/tokens"
    echo >&2
    log_info "Required permissions:"
    echo "  - repo (for repository access)" >&2
    echo "  - issues (for issue management)" >&2
    echo "  - pull_requests (for PR management)" >&2
    echo >&2
    
    while true; do
        token=$(ask_input "Enter your GitHub Personal Access Token" "")
        
        if [[ -z "$token" ]]; then
            log_warning "Token cannot be empty"
            continue
        fi
        
        if validate_token "$token"; then
            echo "$token"
            return 0
        else
            if ask_yes_no "Token format looks unusual. Use it anyway?"; then
                echo "$token"
                return 0
            fi
        fi
    done
}

# Configuration generation
generate_claude_desktop_config() {
    local token="$1"
    local config_path="$2"
    
    cat > "$config_path" << EOF
{
  "mcpServers": {
    "github": {
      "command": "$RUNNER_SCRIPT",
      "args": ["$token"]
    }
  }
}
EOF
    
    log_success "Claude Desktop configuration generated: $config_path"
}

generate_claude_code_command() {
    local token="$1"
    
    echo "claude mcp add github \"$RUNNER_SCRIPT\" \"$token\""
}

# MCP client configuration
configure_mcp_clients() {
    local token="$1"
    
    # Initialize configuration tracking variables
    CLAUDE_DESKTOP_CONFIG_FILE=""
    CLAUDE_DESKTOP_BACKUP_FILE=""
    CLAUDE_CODE_CLI_CONFIGURED=""
    
    log_step "MCP Client Configuration"
    
    echo "Which MCP clients would you like to configure?"
    echo "1) Claude Desktop only"
    echo "2) Claude Code CLI only" 
    echo "3) Both Claude Desktop and Claude Code CLI"
    echo "4) Show commands only (no file generation)"
    echo
    
    local choice
    while true; do
        read -p "Choose an option (1-4): " choice
        case $choice in
            1|2|3|4) break ;;
            *) echo "Please enter 1, 2, 3, or 4" ;;
        esac
    done
    
    echo
    
    case $choice in
        1|3)
            # Claude Desktop configuration
            log_step "Configuring Claude Desktop"
            local config_file
            config_file=$(ask_input "Claude Desktop config file path" "$HOME/.claude_desktop_config.json")
            
            if [[ -f "$config_file" ]]; then
                if ask_yes_no "File exists. Backup and overwrite?" "y"; then
                    local backup_file="$config_file.backup"
                    cp "$config_file" "$backup_file"
                    log_info "Backup created: $backup_file"
                    CLAUDE_DESKTOP_BACKUP_FILE="$backup_file"
                else
                    config_file="$config_file.github-mcp"
                    log_info "Using alternative path: $config_file"
                fi
            fi
            
            generate_claude_desktop_config "$token" "$config_file"
            CLAUDE_DESKTOP_CONFIG_FILE="$config_file"
            echo
            ;;
    esac
    
    case $choice in
        2|3)
            # Claude Code CLI configuration
            log_step "Configuring Claude Code CLI"
            local claude_cmd
            claude_cmd=$(generate_claude_code_command "$token")
            
            if ask_yes_no "Run the Claude Code CLI configuration command now?" "y"; then
                log_info "Running: $claude_cmd"
                if eval "$claude_cmd"; then
                    log_success "Claude Code CLI configured successfully"
                    CLAUDE_CODE_CLI_CONFIGURED="yes"
                    
                    # Verify the configuration immediately
                    log_info "Verifying configuration..."
                    local verify_status
                    verify_status=$(check_claude_mcp_status)
                    case "$verify_status" in
                        configured:*)
                            log_success "Configuration verified successfully"
                            ;;
                        not_configured)
                            log_warning "Configuration not found in 'claude mcp list'"
                            log_info "You may need to restart Claude Code CLI"
                            ;;
                        *)
                            log_info "Verification inconclusive (this is normal)"
                            ;;
                    esac
                else
                    log_warning "Claude Code CLI configuration failed"
                    log_info "You can run it manually: $claude_cmd"
                    CLAUDE_CODE_CLI_CONFIGURED="failed"
                fi
            else
                log_info "Manual command: $claude_cmd"
                CLAUDE_CODE_CLI_CONFIGURED="manual"
            fi
            echo
            ;;
    esac
    
    case $choice in
        4)
            # Show commands only
            log_step "Configuration Commands"
            
            echo "Claude Desktop:"
            echo "  File: ~/.claude_desktop_config.json"
            echo "  Content:"
            cat << EOF
{
  "mcpServers": {
    "github": {
      "command": "$RUNNER_SCRIPT",
      "args": ["$token"]
    }
  }
}
EOF
            echo
            echo "Claude Code CLI:"
            echo "  Command: $(generate_claude_code_command "$token")"
            echo
            ;;
    esac
    
    log_success "MCP client configuration complete"
}

# Test functions
test_runner_script() {
    local token="$1"
    
    log_step "Testing runner script"
    
    if [[ ! -x "$RUNNER_SCRIPT" ]]; then
        log_error "Runner script not executable: $RUNNER_SCRIPT"
        return 1
    fi
    
    # Test basic validation (without actually running the server)
    if "$RUNNER_SCRIPT" --help &> /dev/null; then
        log_success "Runner script validation passed"
        return 0
    else
        log_error "Runner script validation failed"
        return 1
    fi
}

test_mcp_protocol() {
    local token="$1"
    
    log_step "Testing MCP protocol communication"
    
    # Create a simple MCP initialize message
    local init_message='{"jsonrpc": "2.0", "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0"}}, "id": 1}'
    
    log_info "Sending MCP initialize message..."
    
    # Test with a timeout
    if echo "$init_message" | timeout 10s "$RUNNER_SCRIPT" "$token" 2>/dev/null | grep -q '"result"'; then
        log_success "MCP protocol test passed"
        return 0
    else
        log_warning "MCP protocol test failed or timed out"
        log_info "This might be normal if GitHub API access is restricted"
        return 1
    fi
}

# Claude MCP status checking
check_claude_mcp_status() {
    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        echo "not_available"
        return
    fi
    
    # Get MCP list and look for github entry
    local mcp_list
    if ! mcp_list=$(claude mcp list 2>/dev/null); then
        echo "error"
        return
    fi
    
    # Parse the output to find github entry
    local github_line
    if github_line=$(echo "$mcp_list" | grep "^github:"); then
        # Extract the configuration details
        local config_details="${github_line#github: }"
        echo "configured:$config_details"
    else
        echo "not_configured"
    fi
}

# Configuration templates
show_configuration_summary() {
    local token="$1"
    
    echo
    log_step "Configuration Summary"
    echo
    
    # Show actual configuration status
    if [[ -n "$CLAUDE_DESKTOP_CONFIG_FILE" ]]; then
        echo -e "${BOLD}✅ Claude Desktop Configuration:${NC}"
        echo "File: $CLAUDE_DESKTOP_CONFIG_FILE"
        if [[ -n "$CLAUDE_DESKTOP_BACKUP_FILE" ]]; then
            echo -e "${YELLOW}📁 Previous config backed up to: $CLAUDE_DESKTOP_BACKUP_FILE${NC}"
        fi
        echo
        cat << EOF
{
  "mcpServers": {
    "github": {
      "command": "$RUNNER_SCRIPT",
      "args": ["$token"]
    }
  }
}
EOF
        echo
    else
        echo -e "${BOLD}Claude Desktop Configuration:${NC}"
        echo "Not configured (example shown below)"
        echo "File: ~/.claude_desktop_config.json"
        echo
        cat << EOF
{
  "mcpServers": {
    "github": {
      "command": "$RUNNER_SCRIPT",
      "args": ["$token"]
    }
  }
}
EOF
        echo
    fi
    
    # Check current Claude Code CLI status
    local claude_status
    claude_status=$(check_claude_mcp_status)
    
    if [[ -n "$CLAUDE_CODE_CLI_CONFIGURED" ]]; then
        case "$CLAUDE_CODE_CLI_CONFIGURED" in
            "yes")
                echo -e "${BOLD}✅ Claude Code CLI Configuration:${NC}"
                # Verify the configuration actually worked
                case "$claude_status" in
                    configured:*)
                        local current_config="${claude_status#configured:}"
                        echo "Successfully configured and verified!"
                        echo "Current: $current_config"
                        ;;
                    not_configured)
                        echo "Setup reported success but verification failed"
                        echo -e "${YELLOW}⚠️  Not found in 'claude mcp list' - may need to restart Claude Code CLI${NC}"
                        ;;
                    not_available)
                        echo "Successfully configured (Claude CLI not available for verification)"
                        ;;
                    error)
                        echo "Successfully configured (verification error)"
                        ;;
                esac
                ;;
            "failed")
                echo -e "${BOLD}❌ Claude Code CLI Configuration:${NC}"
                echo "Configuration failed - manual setup required"
                ;;
            "manual")
                echo -e "${BOLD}📋 Claude Code CLI Configuration:${NC}"
                echo "Manual setup required"
                ;;
        esac
        echo "Command: $(generate_claude_code_command "$token")"
        echo
    else
        # Show current status for options that didn't configure Claude Code CLI
        echo -e "${BOLD}Claude Code CLI Status:${NC}"
        case "$claude_status" in
            configured:*)
                local current_config="${claude_status#configured:}"
                echo -e "${GREEN}✅ Already configured${NC}"
                echo "Current: $current_config"
                ;;
            not_configured)
                echo "Not configured"
                echo "To configure: $(generate_claude_code_command "$token")"
                ;;
            not_available)
                echo "Claude CLI not available"
                echo "Install Claude Code CLI to use this option"
                ;;
            error)
                echo "Status check failed"
                echo "To configure: $(generate_claude_code_command "$token")"
                ;;
        esac
        echo
    fi
    
    echo -e "${BOLD}Direct Usage:${NC}"
    echo "Command:"
    echo "  $RUNNER_SCRIPT \"$token\""
    
    echo
    echo -e "${BOLD}Available Toolsets:${NC}"
    echo "  - repos: Repository management"
    echo "  - issues: Issue tracking"
    echo "  - pull_requests: Pull request management"
    echo "  - search: Code and repository search"
    echo "  - workflows: GitHub Actions workflows"
    
    echo
    echo -e "${BOLD}Advanced Usage:${NC}"
    echo "  # Limit to specific toolsets"
    echo "  $RUNNER_SCRIPT \"$token\" --toolsets repos,issues"
    echo
    echo "  # Debug mode"
    echo "  $RUNNER_SCRIPT --debug \"$token\""
    echo
    echo "  # Custom configuration"
    echo "  $RUNNER_SCRIPT --config ~/.github-mcp-config \"$token\""
}

# Interactive setup
interactive_setup() {
    log_step "Interactive GitHub MCP Server Setup"
    echo
    
    # Check if we need to build
    if ! check_binary; then
        echo
        if [[ -z "$BUILD_SCRIPT" ]]; then
            # Running as installed version - binary should have been installed
            log_error "Binary not found in expected location"
            log_info "Expected location: $BIN_DIR/$BINARY_NAME"
            log_info "This suggests an incomplete installation"
            echo
            log_info "Possible solutions:"
            echo "  1. Reinstall using the install script"
            echo "  2. Run setup from the source repository"
            echo "  3. Check if installation completed successfully"
            return 1
        else
            # Running from source - offer to build
            if ask_yes_no "Binary not found. Build it now?" "y"; then
                if ! build_binary; then
                    log_error "Failed to build binary"
                    return 1
                fi
            else
                log_error "Binary is required to continue"
                return 1
            fi
        fi
    fi
    
    # Get GitHub token
    echo
    local token
    if ! token=$(get_github_token); then
        log_error "GitHub token is required"
        return 1
    fi
    
    # Test the setup
    echo
    if ask_yes_no "Test the runner script?" "y"; then
        test_runner_script "$token"
        
        if ask_yes_no "Test MCP protocol communication?" "n"; then
            test_mcp_protocol "$token"
        fi
    fi
    
    # Generate configurations
    echo
    configure_mcp_clients "$token"
    
    # Show summary
    echo
    show_configuration_summary "$token"
    
    echo
    log_success "Setup completed successfully!"
    log_info "You can now use the GitHub MCP server with Claude"
}

# Usage information
show_usage() {
    cat << EOF
GitHub MCP Server Setup Helper for Apple Containers

Usage: $0 [OPTIONS]

Options:
    --interactive          Run interactive setup (default)
    --check-only          Check prerequisites and binary only
    --build-only          Build binary only
    --show-config         Show configuration examples
    --test TOKEN          Test setup with provided token
    -h, --help            Show this help message

Environment Variables:
    GITHUB_PERSONAL_ACCESS_TOKEN    GitHub Personal Access Token
    GITHUB_TOKEN                    Alternative token variable

Examples:
    $0                              # Interactive setup
    $0 --check-only                 # Check system only
    $0 --build-only                 # Build binary only
    $0 --test ghp_xxxxxxxxxxxx      # Test with token

EOF
}

# Main execution
main() {
    echo -e "${BOLD}🚀 GitHub MCP Server Setup for Apple Containers${NC}"
    echo "=============================================="
    echo
    
    local mode="interactive"
    local test_token=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --interactive)
                mode="interactive"
                shift
                ;;
            --check-only)
                mode="check"
                shift
                ;;
            --build-only)
                mode="build"
                shift
                ;;
            --show-config)
                mode="show-config"
                shift
                ;;
            --test)
                mode="test"
                test_token="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites first
    if ! check_prerequisites; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    # Execute based on mode
    case "$mode" in
        "check")
            check_binary
            ;;
        "build")
            build_binary
            ;;
        "show-config")
            local example_token="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            show_configuration_summary "$example_token"
            ;;
        "test")
            if [[ -z "$test_token" ]]; then
                log_error "Token required for testing"
                exit 1
            fi
            check_binary || build_binary
            test_runner_script "$test_token"
            test_mcp_protocol "$test_token"
            ;;
        "interactive")
            interactive_setup
            ;;
        *)
            log_error "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"