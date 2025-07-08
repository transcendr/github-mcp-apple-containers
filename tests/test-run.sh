#!/bin/bash
# Test script for runner script validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RUN_SCRIPT="$PROJECT_DIR/scripts/run.sh"

echo "🧪 Testing runner script..."

# Test 1: Runner script exists and is executable
if [[ ! -x "$RUN_SCRIPT" ]]; then
    echo "❌ Runner script not executable: $RUN_SCRIPT"
    exit 1
fi

echo "✅ Runner script found and executable"

# Test 2: Runner script help
if ! "$RUN_SCRIPT" --help > /dev/null; then
    echo "❌ Runner script help failed"
    exit 1
fi

echo "✅ Runner script help works"

# Test 3: Container command availability
if ! command -v container &> /dev/null; then
    echo "⚠️  Apple containers not available (skipping container tests)"
else
    echo "✅ Apple containers available"
fi

echo "✅ All runner tests passed"