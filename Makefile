# GitHub MCP Server Apple Containers - Development Makefile

.PHONY: help build clean test setup install lint format check-deps docs

# Configuration
BINARY_NAME = github-mcp-server
BIN_DIR = bin
SCRIPTS_DIR = scripts
DOCS_DIR = docs

# Colors
GREEN = \033[32m
YELLOW = \033[33m
RED = \033[31m
BLUE = \033[34m
NC = \033[0m # No Color

# Default target
help: ## Show this help message
	@echo "$(BLUE)GitHub MCP Server Apple Containers - Development Commands$(NC)"
	@echo "========================================================"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make build              # Build the binary"
	@echo "  make test              # Run all tests"
	@echo "  make setup             # Interactive setup"
	@echo "  make install           # Install locally"

# Build targets
build: check-deps ## Build the GitHub MCP server binary
	@echo "$(BLUE)Building GitHub MCP server binary...$(NC)"
	@$(SCRIPTS_DIR)/build.sh --output $(PWD)/$(BIN_DIR)
	@echo "$(GREEN)✅ Build complete$(NC)"

build-verbose: check-deps ## Build with verbose output
	@echo "$(BLUE)Building GitHub MCP server binary (verbose)...$(NC)"
	@$(SCRIPTS_DIR)/build.sh --verbose --output $(PWD)/$(BIN_DIR)

build-version: check-deps ## Build specific version (usage: make build-version VERSION=v1.2.3)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ VERSION required. Usage: make build-version VERSION=v1.2.3$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Building GitHub MCP server version $(VERSION)...$(NC)"
	@$(SCRIPTS_DIR)/build.sh --version $(VERSION) --output $(PWD)/$(BIN_DIR)

# Cleanup targets
clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@rm -rf $(BIN_DIR)
	@rm -rf /tmp/github-mcp-build-*
	@echo "$(GREEN)✅ Clean complete$(NC)"

clean-all: clean ## Clean all generated files including logs
	@echo "$(BLUE)Cleaning all generated files...$(NC)"
	@rm -f *.log debug.log
	@rm -rf test-results/
	@rm -rf coverage/
	@echo "$(GREEN)✅ Full clean complete$(NC)"

# Test targets
test: build ## Run all tests
	@echo "$(BLUE)Running all tests...$(NC)"
	@$(SCRIPTS_DIR)/../tests/test-build.sh
	@$(SCRIPTS_DIR)/../tests/test-run.sh
	@echo "$(GREEN)✅ All tests passed$(NC)"

test-build: ## Test build process only
	@echo "$(BLUE)Testing build process...$(NC)"
	@$(SCRIPTS_DIR)/../tests/test-build.sh

test-run: build ## Test runner script
	@echo "$(BLUE)Testing runner script...$(NC)"
	@$(SCRIPTS_DIR)/../tests/test-run.sh

test-integration: build ## Run integration tests (requires token)
	@if [ -z "$(GITHUB_PERSONAL_ACCESS_TOKEN)" ]; then \
		echo "$(RED)❌ GITHUB_PERSONAL_ACCESS_TOKEN required for integration tests$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Running integration tests...$(NC)"
	@$(SCRIPTS_DIR)/../tests/test-integration.sh

# Setup and installation
setup: ## Run interactive setup
	@echo "$(BLUE)Starting interactive setup...$(NC)"
	@$(SCRIPTS_DIR)/setup.sh --interactive

setup-check: ## Check prerequisites only
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@$(SCRIPTS_DIR)/setup.sh --check-only

install: build ## Install to ~/.local/bin
	@echo "$(BLUE)Installing to ~/.local/bin...$(NC)"
	@$(SCRIPTS_DIR)/install.sh
	@echo "$(GREEN)✅ Installation complete$(NC)"

install-global: build ## Install to /usr/local/bin (requires sudo)
	@echo "$(BLUE)Installing to /usr/local/bin...$(NC)"
	@sudo $(SCRIPTS_DIR)/install.sh --install-dir /usr/local/bin
	@echo "$(GREEN)✅ Global installation complete$(NC)"

# Development targets
dev-setup: ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if ! command -v go >/dev/null 2>&1; then \
		echo "$(RED)❌ Go is required for development$(NC)"; \
		exit 1; \
	fi
	@if ! command -v git >/dev/null 2>&1; then \
		echo "$(RED)❌ Git is required for development$(NC)"; \
		exit 1; \
	fi
	@if ! command -v container >/dev/null 2>&1; then \
		echo "$(RED)❌ Apple containers required for testing$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Development environment ready$(NC)"

check-deps: ## Check build dependencies
	@if ! command -v git >/dev/null 2>&1; then \
		echo "$(RED)❌ Git is required$(NC)"; \
		exit 1; \
	fi
	@if ! command -v go >/dev/null 2>&1; then \
		echo "$(RED)❌ Go is required$(NC)"; \
		exit 1; \
	fi

lint: ## Run linting on shell scripts
	@echo "$(BLUE)Linting shell scripts...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find $(SCRIPTS_DIR) -name "*.sh" -exec shellcheck {} + && \
		echo "$(GREEN)✅ Linting passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  shellcheck not installed, skipping lint$(NC)"; \
	fi

format: ## Format shell scripts
	@echo "$(BLUE)Formatting shell scripts...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		find $(SCRIPTS_DIR) -name "*.sh" -exec shfmt -w {} + && \
		echo "$(GREEN)✅ Formatting complete$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  shfmt not installed, skipping format$(NC)"; \
	fi

# Documentation targets
docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@echo "$(YELLOW)Documentation generation not yet implemented$(NC)"

docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation...$(NC)"
	@echo "$(YELLOW)Documentation serving not yet implemented$(NC)"

# Release targets
version: ## Show version information
	@echo "$(BLUE)Version Information:$(NC)"
	@if [ -f $(BIN_DIR)/$(BINARY_NAME) ]; then \
		echo "Binary: $(shell ls -lh $(BIN_DIR)/$(BINARY_NAME) | awk '{print $$5}')"; \
		echo "Modified: $(shell stat -f %Sm $(BIN_DIR)/$(BINARY_NAME))"; \
	else \
		echo "Binary: not built"; \
	fi
	@echo "Repository: $(shell git rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"

release-check: ## Check if ready for release
	@echo "$(BLUE)Checking release readiness...$(NC)"
	@$(MAKE) test
	@$(MAKE) lint
	@echo "$(GREEN)✅ Ready for release$(NC)"

# Example configurations
config-claude-desktop: ## Show Claude Desktop configuration example
	@echo "$(BLUE)Claude Desktop Configuration:$(NC)"
	@echo "File: ~/.claude_desktop_config.json"
	@echo
	@echo '{'
	@echo '  "mcpServers": {'
	@echo '    "github": {'
	@echo '      "command": "$(PWD)/$(SCRIPTS_DIR)/run.sh",'
	@echo '      "args": ["YOUR_GITHUB_TOKEN_HERE"]'
	@echo '    }'
	@echo '  }'
	@echo '}'

config-claude-code: ## Show Claude Code CLI configuration example
	@echo "$(BLUE)Claude Code CLI Configuration:$(NC)"
	@echo "Command:"
	@echo "  claude mcp add github \"$(PWD)/$(SCRIPTS_DIR)/run.sh\" \"YOUR_GITHUB_TOKEN_HERE\""

# Quick start
quick-start: build setup ## Quick start: build and run setup
	@echo "$(GREEN)✅ Quick start complete!$(NC)"

# All-in-one development workflow
dev: dev-setup build test ## Complete development workflow
	@echo "$(GREEN)✅ Development workflow complete$(NC)"

# Debug information
debug: ## Show debug information
	@echo "$(BLUE)Debug Information:$(NC)"
	@echo "PWD: $(PWD)"
	@echo "Makefile location: $(MAKEFILE_LIST)"
	@echo "Binary directory: $(BIN_DIR)"
	@echo "Scripts directory: $(SCRIPTS_DIR)"
	@echo "Shell: $(SHELL)"
	@echo "PATH: $(PATH)"
	@echo
	@echo "$(BLUE)System:$(NC)"
	@uname -a
	@echo
	@echo "$(BLUE)Go version:$(NC)"
	@go version 2>/dev/null || echo "Go not installed"
	@echo
	@echo "$(BLUE)Git version:$(NC)"
	@git --version 2>/dev/null || echo "Git not installed"
	@echo
	@echo "$(BLUE)Container availability:$(NC)"
	@container --version 2>/dev/null || echo "Apple containers not available"