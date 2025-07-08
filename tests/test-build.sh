#!/bin/bash
# Test script for build process validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_SCRIPT="$PROJECT_DIR/scripts/build.sh"

echo "🧪 Testing build process..."

# Test 1: Build script exists and is executable
if [[ ! -x "$BUILD_SCRIPT" ]]; then
    echo "❌ Build script not executable: $BUILD_SCRIPT"
    exit 1
fi

echo "✅ Build script found and executable"

# Test 2: Build script help
if ! "$BUILD_SCRIPT" --help > /dev/null; then
    echo "❌ Build script help failed"
    exit 1
fi

echo "✅ Build script help works"

# Test 3: Prerequisites check
echo "🔍 Checking build prerequisites..."

if ! command -v git &> /dev/null; then
    echo "❌ Git not available"
    exit 1
fi

if ! command -v go &> /dev/null; then
    echo "❌ Go not available"
    exit 1
fi

echo "✅ All build tests passed"