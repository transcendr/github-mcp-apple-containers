# Contributing to GitHub MCP Apple Containers

Thank you for your interest in contributing to GitHub MCP Apple Containers! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful, inclusive, and professional in all interactions.

## Getting Started

### Prerequisites

- macOS with Apple containers support
- Go 1.21+ 
- Git
- GitHub Personal Access Token for testing
- Basic familiarity with shell scripting and containers

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/github-mcp-apple-containers.git
   cd github-mcp-apple-containers
   ```

## Development Setup

### Initial Setup

```bash
# Set up development environment
make dev-setup

# Build the project
make build

# Run tests to ensure everything works
make test
```

### Optional Tools

For better development experience, consider installing:

- **shellcheck**: For shell script linting
  ```bash
  brew install shellcheck
  ```

- **shfmt**: For shell script formatting
  ```bash
  brew install shfmt
  ```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/description` - For new features
- `fix/description` - For bug fixes
- `docs/description` - For documentation changes
- `refactor/description` - For code refactoring

### Commit Messages

Follow conventional commit format:
```
type(scope): brief description

Longer description if needed

- Additional details
- References to issues
```

Examples:
- `feat(scripts): add token validation in run script`
- `fix(build): handle missing Go dependencies gracefully`
- `docs(readme): update installation instructions`

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run specific test suites
make test-build        # Build process tests
make test-run          # Runner script tests
make test-integration  # Integration tests (requires GitHub token)
```

### Adding Tests

When adding new functionality:

1. **Add unit tests** in the appropriate `tests/` file
2. **Update integration tests** if needed
3. **Test with real GitHub API** when possible
4. **Document test requirements** in test files

### Test Requirements

For integration tests:
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_test_token
make test-integration
```

## Submitting Changes

### Before Submitting

1. **Run the full test suite**:
   ```bash
   make test
   ```

2. **Run linting**:
   ```bash
   make lint
   ```

3. **Update documentation** if needed

4. **Test with real GitHub MCP clients** (Claude Desktop/Code CLI)

### Pull Request Process

1. **Create a pull request** against the `main` branch
2. **Fill out the PR template** completely
3. **Link related issues** using keywords like "fixes #123"
4. **Request review** from maintainers
5. **Respond to feedback** promptly

### PR Requirements

- [ ] All tests pass
- [ ] Code is properly documented
- [ ] Breaking changes are noted
- [ ] CHANGELOG.md is updated (for significant changes)

## Reporting Issues

### Bug Reports

When reporting bugs, include:

- **Environment details** (macOS version, Go version, etc.)
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Error messages or logs**
- **GitHub token permissions** (if relevant)

### Feature Requests

For feature requests, describe:

- **Use case** - Why is this needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches were considered?
- **Implementation ideas** - Any thoughts on how to implement it?

### Security Issues

For security-related issues:
- **Do NOT open public issues**
- **Email maintainers directly** with details
- **Allow time for responsible disclosure**

## Documentation

### Documentation Guidelines

- **Keep it current** - Update docs when changing functionality
- **Be comprehensive** - Include examples and edge cases
- **Use clear language** - Avoid unnecessary technical jargon
- **Test examples** - Ensure all examples work as shown

### Documentation Structure

- **README.md** - Main overview and quick start
- **docs/** - Detailed guides and references
- **examples/** - Working configuration examples
- **Comments** - Inline documentation for complex code

### Writing Style

- Use clear, concise language
- Include practical examples
- Explain the "why" not just the "what"
- Consider different skill levels

## Development Guidelines

### Shell Scripting Standards

- **Use `set -e`** for error handling
- **Quote variables** to prevent word splitting
- **Use functions** for reusable code
- **Add error messages** for failure cases
- **Include usage information** for scripts

### Code Organization

- **Single responsibility** - Each script/function should have one clear purpose
- **Consistent naming** - Use descriptive, consistent variable and function names
- **Error handling** - Handle edge cases and provide helpful error messages
- **Logging** - Use appropriate log levels (debug, info, warning, error)

### Configuration Management

- **Environment variables** - Use for configuration options
- **Config files** - Support configuration files where appropriate
- **Defaults** - Provide sensible defaults for all options
- **Validation** - Validate configuration at startup

## Release Process

### Version Management

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR** - Breaking changes to user interface
- **MINOR** - New features, GitHub MCP server updates
- **PATCH** - Bug fixes, documentation updates

### Release Checklist

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version numbers are bumped
- [ ] Release notes are prepared

## Areas for Contribution

### High Priority

- **Performance optimizations** - Faster builds, lower resource usage
- **Error handling improvements** - Better error messages and recovery
- **Documentation enhancements** - More examples and guides
- **Test coverage** - Additional test cases and scenarios

### Medium Priority

- **Configuration enhancements** - More flexible configuration options
- **Monitoring features** - Health checks and metrics
- **Platform support** - Linux container support
- **Integration examples** - More MCP client integrations

### Future Ideas

- **GUI configuration tool** - Visual setup interface
- **Auto-update mechanism** - Automatic binary updates
- **Multi-server support** - Manage multiple MCP servers
- **Performance dashboard** - Real-time monitoring

## Getting Help

### Communication Channels

- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and general discussion
- **Pull Request Comments** - For code review discussions

### Resources

- [GitHub MCP Server Documentation](https://github.com/github/github-mcp-server)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Apple Virtualization Framework](https://developer.apple.com/documentation/virtualization)
- [Go Documentation](https://golang.org/doc/)

## Recognition

Contributors will be recognized:
- In the CHANGELOG.md for significant contributions
- In the README.md contributors section
- Through GitHub's contributor graphs and statistics

Thank you for contributing to GitHub MCP Apple Containers! 🎉