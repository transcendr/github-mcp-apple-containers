# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of GitHub MCP server for Apple containers
- Build script for ARM64 binary compilation
- Runtime script with proper Apple container integration
- Setup helper for Claude Desktop and Claude Code CLI configuration
- Comprehensive documentation and examples

### Technical Features
- Directory-based container mounting (Apple container requirement)
- Token passing via script arguments (Docker `-e` equivalent)
- Cross-platform compatibility (Claude Desktop + Claude Code CLI)
- Native ARM64 performance optimizations

## [0.1.0] - 2025-07-08

### Added
- Initial release
- Basic Apple container support for GitHub MCP server
- Documentation and setup scripts