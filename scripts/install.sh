#!/bin/bash
# GitHub MCP Server One-Command Installer for Apple Containers
# This script downloads, builds, and sets up the GitHub MCP server

set -e

# Configuration
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
REPO_URL="https://github.com/transcendr/github-mcp-apple-containers.git"
TEMP_DIR="/tmp/github-mcp-install-$$"

# Colors
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

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_step() {
    echo -e "${BOLD}🔹 $1${NC}"
}

cleanup() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

# Check prerequisites
check_prerequisites() {
    log_step "Checking system requirements"
    
    # Check for Apple containers
    if ! command -v container &> /dev/null; then
        log_error "Apple containers not available"
        log_error "This tool requires Apple containers to be installed"
        exit 1
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed"
        exit 1
    fi
    
    # Check for Go
    if ! command -v go &> /dev/null; then
        log_error "Go is required but not installed"
        log_error "Please install Go 1.21+ from https://golang.org/"
        exit 1
    fi
    
    log_success "System requirements satisfied"
}

# Download repository
download_repo() {
    log_step "Downloading GitHub MCP Apple Containers"
    
    git clone "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    log_success "Repository downloaded"
}

# Build binary
build_binary() {
    log_step "Building GitHub MCP server binary"
    
    if ! ./scripts/build.sh; then
        log_error "Failed to build binary"
        exit 1
    fi
    
    log_success "Binary built successfully"
}

# Install scripts
install_scripts() {
    log_step "Installing scripts to $INSTALL_DIR"
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy scripts
    cp scripts/run.sh "$INSTALL_DIR/github-mcp-run"
    cp scripts/setup.sh "$INSTALL_DIR/github-mcp-setup"
    
    # Copy binary
    mkdir -p "$INSTALL_DIR/github-mcp-bin"
    cp bin/github-mcp-server "$INSTALL_DIR/github-mcp-bin/"
    
    # Update paths in run script
    sed -i.bak "s|DEFAULT_BIN_DIR=.*|DEFAULT_BIN_DIR=\"$INSTALL_DIR/github-mcp-bin\"|" "$INSTALL_DIR/github-mcp-run"
    rm "$INSTALL_DIR/github-mcp-run.bak"
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/github-mcp-run"
    chmod +x "$INSTALL_DIR/github-mcp-setup"
    
    log_success "Scripts installed"
}

# Add to PATH
add_to_path() {
    local shell_config=""
    
    # Detect shell configuration file
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_config="$HOME/.bashrc"
        [[ -f "$HOME/.bash_profile" ]] && shell_config="$HOME/.bash_profile"
    fi
    
    if [[ -n "$shell_config" ]]; then
        log_step "Adding $INSTALL_DIR to PATH in $shell_config"
        
        # Check if already in PATH
        if ! grep -q "$INSTALL_DIR" "$shell_config" 2>/dev/null; then
            echo "" >> "$shell_config"
            echo "# GitHub MCP Apple Containers" >> "$shell_config"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
            
            log_success "Added to PATH in $shell_config"
            log_warning "Please run 'source $shell_config' or restart your terminal"
        else
            log_info "Already in PATH"
        fi
    else
        log_warning "Could not detect shell configuration file"
        log_info "Please manually add $INSTALL_DIR to your PATH"
    fi
}

# Show completion message
show_completion() {
    echo
    log_success "GitHub MCP Server for Apple Containers installed successfully!"
    echo
    log_info "Installed components:"
    echo "  - github-mcp-run: Main runner script"
    echo "  - github-mcp-setup: Interactive setup helper"
    echo "  - Binary: $INSTALL_DIR/github-mcp-bin/github-mcp-server"
    echo
    log_info "Next steps:"
    echo "  1. Add GitHub token to environment:"
    echo "     export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here"
    echo
    echo "  2. Run interactive setup:"
    echo "     github-mcp-setup"
    echo
    echo "  3. Or configure manually:"
    echo "     # Claude Desktop"
    echo "     Add to ~/.claude_desktop_config.json"
    echo
    echo "     # Claude Code CLI"
    echo "     claude mcp add github github-mcp-run your_token_here"
    echo
    log_info "For more information, visit the documentation"
}

# Usage information
show_usage() {
    cat << EOF
GitHub MCP Server One-Command Installer for Apple Containers

Usage: $0 [OPTIONS]

Options:
    --install-dir DIR     Installation directory (default: ~/.local/bin)
    --repo URL           Repository URL (for development)
    -h, --help           Show this help message

Environment Variables:
    INSTALL_DIR          Installation directory

Examples:
    $0                                    # Install to ~/.local/bin
    $0 --install-dir /usr/local/bin      # Install to /usr/local/bin

EOF
}

# Main execution
main() {
    echo -e "${BOLD}🚀 GitHub MCP Server Installer for Apple Containers${NC}"
    echo "=================================================="
    echo
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
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
    
    # Expand tilde in install directory
    INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
    
    log_info "Installing to: $INSTALL_DIR"
    echo
    
    check_prerequisites
    download_repo
    build_binary
    install_scripts
    add_to_path
    show_completion
}

# Run main function
main "$@"