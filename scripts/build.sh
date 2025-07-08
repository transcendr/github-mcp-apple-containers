#!/bin/bash
# GitHub MCP Server Build Script for Apple Containers
# Enhanced version with version management and configuration options

set -e

# Configuration with defaults
REPO_URL="${GITHUB_MCP_REPO_URL:-https://github.com/github/github-mcp-server.git}"
BUILD_DIR="${BUILD_DIR:-/tmp/github-mcp-build-$$}"
BINARY_NAME="${BINARY_NAME:-github-mcp-server}"
VERSION_TAG="${VERSION_TAG:-latest}"
SKIP_CLEANUP="${SKIP_CLEANUP:-false}"
VERBOSE="${VERBOSE:-false}"

# Determine output directory
if [[ -n "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$OUTPUT_DIR"
elif [[ -d "/workspace" ]]; then
    # Running in container
    OUTPUT_DIR="/workspace/bin"
else
    # Running locally
    OUTPUT_DIR="$(pwd)/bin"
fi

# Colors for output (if terminal supports them)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Logging functions
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
    echo -e "${BLUE}🔹 $1${NC}"
}

# Progress indicator
show_progress() {
    local duration=$1
    local msg="$2"
    local elapsed=0
    
    echo -n "$msg"
    while [[ $elapsed -lt $duration ]]; do
        echo -n "."
        sleep 1
        ((elapsed++))
    done
    echo " done!"
}

# Error handling
cleanup() {
    if [[ "$SKIP_CLEANUP" != "true" && -d "$BUILD_DIR" ]]; then
        log_step "Cleaning up build directory..."
        rm -rf "$BUILD_DIR"
    fi
}

error_exit() {
    log_error "$1"
    cleanup
    exit 1
}

# Trap cleanup on exit
trap cleanup EXIT

# Validation functions
check_dependencies() {
    log_step "Checking build dependencies..."
    
    if ! command -v git &> /dev/null; then
        error_exit "git is required but not installed"
    fi
    
    if ! command -v go &> /dev/null; then
        error_exit "Go is required but not installed"
    fi
    
    local go_version=$(go version | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/go//')
    log_info "Found Go version: $go_version"
    
    # Check minimum Go version (1.21+)
    if [[ $(echo "$go_version" | cut -d. -f1) -lt 1 ]] || \
       [[ $(echo "$go_version" | cut -d. -f1) -eq 1 && $(echo "$go_version" | cut -d. -f2) -lt 21 ]]; then
        error_exit "Go 1.21+ is required, found $go_version"
    fi
}

# Version management
get_version_info() {
    if [[ "$VERSION_TAG" == "latest" ]]; then
        # Get latest release tag
        log_step "Fetching latest release information..."
        VERSION_TAG=$(git ls-remote --tags --refs "$REPO_URL" | \
                     grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
                     sort -t/ -k3 -V | \
                     tail -1 | \
                     cut -d/ -f3)
        
        if [[ -z "$VERSION_TAG" ]]; then
            log_warning "No release tags found, using main branch"
            VERSION_TAG="main"
        else
            log_info "Using latest release: $VERSION_TAG"
        fi
    fi
}

# Build process
clone_repository() {
    log_step "Cloning GitHub MCP Server repository..."
    
    if [[ "$VERSION_TAG" == "main" ]]; then
        git clone --depth 1 "$REPO_URL" "$BUILD_DIR"
    else
        git clone --depth 1 --branch "$VERSION_TAG" "$REPO_URL" "$BUILD_DIR"
    fi
    
    cd "$BUILD_DIR"
    
    log_info "Repository information:"
    echo "  - Version/Tag: $VERSION_TAG"
    echo "  - Latest commit: $(git rev-parse --short HEAD)"
    echo "  - Repository: $REPO_URL"
}

setup_build_environment() {
    log_step "Setting up build environment..."
    
    # Create output directory structure for Apple containers
    mkdir -p "$OUTPUT_DIR"
    
    # Ensure we're in the build directory
    cd "$BUILD_DIR"
    
    # Check if go.mod exists
    if [[ ! -f "go.mod" ]]; then
        error_exit "go.mod not found in repository"
    fi
    
    # Download dependencies
    if [[ "$VERBOSE" == "true" ]]; then
        go mod download
    else
        go mod download > /dev/null 2>&1 || error_exit "Failed to download Go dependencies"
    fi
    
    log_success "Build environment ready"
}

build_binary() {
    log_step "Building ARM64 binary for Apple containers..."
    
    # Build metadata
    local commit_hash=$(git rev-parse HEAD)
    local build_date=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local version_info="$VERSION_TAG"
    
    # Build flags
    local ldflags="-s -w"
    ldflags="$ldflags -X main.version=$version_info"
    ldflags="$ldflags -X main.commit=$commit_hash"
    ldflags="$ldflags -X main.date=$build_date"
    
    log_info "Build configuration:"
    echo "  - Target: linux/arm64"
    echo "  - CGO: disabled (static binary)"
    echo "  - Version: $version_info"
    echo "  - Output: $OUTPUT_DIR/$BINARY_NAME"
    
    # Perform the build
    if [[ "$VERBOSE" == "true" ]]; then
        CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
            -ldflags "$ldflags" \
            -o "$OUTPUT_DIR/$BINARY_NAME" \
            ./cmd/github-mcp-server
    else
        CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build \
            -ldflags "$ldflags" \
            -o "$OUTPUT_DIR/$BINARY_NAME" \
            ./cmd/github-mcp-server > /dev/null 2>&1 || error_exit "Build failed"
    fi
    
    log_success "Binary built successfully"
}

verify_binary() {
    log_step "Verifying built binary..."
    
    local binary_path="$OUTPUT_DIR/$BINARY_NAME"
    
    if [[ ! -f "$binary_path" ]]; then
        error_exit "Binary not found at $binary_path"
    fi
    
    # Check file type (if file command is available)
    if command -v file &> /dev/null; then
        local file_info=$(file "$binary_path")
        log_info "Binary type: $file_info"
        
        # Verify it's a Linux ARM64 binary
        if [[ ! "$file_info" =~ "ARM aarch64" ]] && [[ ! "$file_info" =~ "ARM64" ]]; then
            log_warning "Binary might not be ARM64 architecture"
        fi
    fi
    
    # Check file size and permissions
    local file_size=$(ls -lh "$binary_path" | awk '{print $5}')
    local file_perms=$(ls -l "$binary_path" | awk '{print $1}')
    
    log_info "Binary information:"
    echo "  - Size: $file_size"
    echo "  - Permissions: $file_perms"
    echo "  - Path: $binary_path"
    
    # Make sure it's executable
    chmod +x "$binary_path"
    
    log_success "Binary verification complete"
}

show_usage() {
    cat << EOF
GitHub MCP Server Build Script for Apple Containers

Usage: $0 [OPTIONS]

Options:
    -v, --version TAG       Build specific version/tag (default: latest)
    -o, --output DIR        Output directory (default: auto-detected)
    -n, --name NAME         Binary name (default: github-mcp-server)
    --repo URL              Repository URL (default: official GitHub repo)
    --verbose               Enable verbose output
    --skip-cleanup          Don't remove build directory
    -h, --help              Show this help message

Environment Variables:
    VERSION_TAG             Version/tag to build
    OUTPUT_DIR              Output directory
    BINARY_NAME             Binary filename
    GITHUB_MCP_REPO_URL     Repository URL
    VERBOSE                 Enable verbose output (true/false)
    SKIP_CLEANUP            Skip cleanup (true/false)

Examples:
    $0                      # Build latest release
    $0 -v v1.2.3           # Build specific version
    $0 --verbose           # Build with verbose output
    $0 -o ./bin            # Build to specific directory

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION_TAG="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            BINARY_NAME="$2"
            shift 2
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        --skip-cleanup)
            SKIP_CLEANUP="true"
            shift
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

# Main execution
main() {
    echo "🔨 GitHub MCP Server Build Script for Apple Containers"
    echo "======================================================"
    
    check_dependencies
    get_version_info
    clone_repository
    setup_build_environment
    build_binary
    verify_binary
    
    echo
    log_success "Build completed successfully!"
    echo
    log_info "Next steps:"
    echo "  1. The binary is ready in: $OUTPUT_DIR/$BINARY_NAME"
    echo "  2. Use the run script to execute in Apple containers"
    echo "  3. Configure Claude Desktop or Claude Code CLI"
    echo
    log_info "For more information, see the documentation in docs/"
}

# Run main function
main "$@"