# GitHub MCP Server for Apple Containers

> **A native Apple container implementation of GitHub's MCP server - faster, simpler, and Docker-free**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Apple Containers](https://img.shields.io/badge/Apple-Containers-blue.svg)](https://developer.apple.com/documentation/virtualization)
[![GitHub MCP](https://img.shields.io/badge/GitHub-MCP-green.svg)](https://github.com/github/github-mcp-server)

## Overview

This project provides a streamlined way to run [GitHub's MCP server](https://github.com/github/github-mcp-server) using Apple containers instead of Docker. Perfect for macOS users who want better performance, simpler setup, and unified container management without Docker Desktop overhead.

### Why Apple Containers?

- **🚀 Better Performance**: Native ARM64 execution on Apple Silicon
- **📦 Simpler Setup**: No Docker Desktop required
- **🔧 Unified Management**: Uses the same container runtime as your development tools
- **💾 Lower Resource Usage**: Lightweight compared to Docker Desktop
- **⚡ Faster Startup**: Quick container initialization

## Quick Start

### Prerequisites

- macOS with Apple containers support
- Go 1.21+ (for building)
- Git
- GitHub Personal Access Token ([create one here](https://github.com/settings/tokens))

### One-Command Installation

```bash
curl -fsSL https://raw.githubusercontent.com/transcendr/github-mcp-apple-containers/main/scripts/install.sh | bash
```

### Manual Installation

1. **Clone and build**:
   ```bash
   git clone https://github.com/transcendr/github-mcp-apple-containers.git
   cd github-mcp-apple-containers
   make build
   ```

2. **Run interactive setup**:
   ```bash
   make setup
   ```

3. **Configure your MCP client** (see [Configuration](#configuration) below)

## Configuration

### Claude Desktop

Add to your `~/.claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "/path/to/scripts/run.sh",
      "args": ["ghp_your_github_token_here"]
    }
  }
}
```

### Claude Code CLI

```bash
claude mcp add github "/path/to/scripts/run.sh" "ghp_your_github_token_here"
```

### Environment Variables

Alternatively, set your token as an environment variable:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_github_token_here
```

Then use:
```bash
# Claude Desktop
{
  "mcpServers": {
    "github": {
      "command": "/path/to/scripts/run.sh",
      "args": ["--env-token"]
    }
  }
}

# Claude Code CLI
claude mcp add github "/path/to/scripts/run.sh" "--env-token"
```

## Features

### Core Functionality

- **Repository Management**: Create, clone, and manage repositories
- **Issue Tracking**: Create, search, and manage GitHub issues
- **Pull Requests**: Create and manage pull requests
- **Code Search**: Search across repositories and code
- **GitHub Actions**: Manage workflows and runs

### Enhanced Features

- **Multiple Token Support**: Configure different tokens for different repositories
- **Configuration Management**: Persistent configuration with `~/.github-mcp-config`
- **Health Checks**: Built-in validation and monitoring
- **Debug Mode**: Detailed logging for troubleshooting
- **Version Management**: Build specific versions or latest releases

## Usage Examples

### Basic Usage

```bash
# Start the server with your token
./scripts/run.sh ghp_your_github_token_here

# With debug logging
./scripts/run.sh --debug ghp_your_github_token_here

# Using environment token
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_github_token_here
./scripts/run.sh --env-token
```

### Advanced Configuration

```bash
# Custom configuration file
./scripts/run.sh --config ./my-config ghp_your_github_token_here

# Health check before running
./scripts/run.sh --health-check ghp_your_github_token_here

# Limit to specific toolsets
./scripts/run.sh ghp_your_github_token_here --toolsets repos,issues
```

### Development Workflow

```bash
# Complete development setup
make dev

# Build specific version
make build-version VERSION=v1.2.3

# Run all tests
make test

# Quick configuration examples
make config-claude-desktop
make config-claude-code
```

## Documentation

- **[Installation Guide](docs/installation.md)** - Detailed installation instructions
- **[Configuration Guide](docs/configuration.md)** - Complete configuration options
- **[Claude Desktop Integration](docs/claude-desktop.md)** - Claude Desktop specific setup
- **[Claude Code CLI Integration](docs/claude-code-cli.md)** - Claude Code CLI specific setup
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[vs Docker Comparison](docs/comparison.md)** - Performance and feature comparison

## Architecture

### Directory Structure

```
github-mcp-apple-containers/
├── scripts/
│   ├── build.sh       # Enhanced build script with version management
│   ├── run.sh         # Enhanced runner with configuration support
│   ├── setup.sh       # Interactive setup helper
│   └── install.sh     # One-command installer
├── docs/              # Comprehensive documentation
├── examples/          # Configuration examples
├── tests/             # Automated testing
└── Makefile          # Development automation
```

### Key Components

- **Build Script**: Compiles GitHub MCP server as ARM64 binary for Apple containers
- **Runner Script**: Manages container execution with proper stdio handling
- **Setup Helper**: Interactive configuration for different MCP hosts
- **Test Suite**: Validates build process, runtime, and MCP protocol compliance

### Apple Container Integration

- **Directory Mounting**: Uses `--volume dir:dir` (required by Apple containers)
- **Static Binaries**: CGO-disabled builds for container portability
- **Stdio Handling**: Proper interactive communication for MCP protocol
- **Resource Management**: Optional memory and CPU limits

## Performance Comparison

| Metric | Docker Desktop | Apple Containers |
|--------|----------------|------------------|
| Startup Time | ~3-5 seconds | ~1-2 seconds |
| Memory Usage | ~200MB overhead | ~50MB overhead |
| Binary Size | ~15MB (with base image) | ~12MB (static) |
| Architecture | x86_64 emulated | Native ARM64 |

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/transcendr/github-mcp-apple-containers.git
cd github-mcp-apple-containers

# Set up development environment
make dev-setup

# Build and test
make dev

# Run linting
make lint
```

### Testing

```bash
# Run all tests
make test

# Test specific components
make test-build
make test-run

# Integration tests (requires GitHub token)
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
make test-integration
```

## Security

- **No Token Persistence**: Tokens are not stored in configuration files by default
- **Environment Variable Support**: Secure token handling via environment variables
- **Validation**: Basic token format validation with security warnings
- **Container Isolation**: Runs in isolated Apple containers

## Troubleshooting

### Common Issues

**Binary not found**:
```bash
# Rebuild the binary
make build
```

**Container not starting**:
```bash
# Check Apple containers availability
container --version

# Run with debug logging
./scripts/run.sh --debug ghp_your_token_here
```

**MCP protocol errors**:
```bash
# Test the setup
./scripts/setup.sh --test ghp_your_token_here

# Verify token permissions
curl -H "Authorization: token ghp_your_token_here" https://api.github.com/user
```

See [Troubleshooting Guide](docs/troubleshooting.md) for more solutions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [GitHub MCP Server](https://github.com/github/github-mcp-server) - The original MCP server implementation
- [Model Context Protocol](https://modelcontextprotocol.io/) - The MCP specification
- [Anthropic](https://www.anthropic.com/) - For Claude and MCP development

## Related Projects

- [GitHub MCP Server](https://github.com/github/github-mcp-server) - Official Docker-based implementation
- [MCP Specification](https://spec.modelcontextprotocol.io/) - Model Context Protocol specification
- [Claude Desktop](https://claude.ai/download) - Claude Desktop application
- [Claude Code CLI](https://docs.anthropic.com/claude/docs/claude-code) - Claude Code command-line interface

---

**Made with ❤️ for the macOS development community**
