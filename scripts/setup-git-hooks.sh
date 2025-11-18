#!/bin/bash
set -e

# Setup git pre-commit hook for automatic formatting

HOOKS_DIR=".git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash

# Format Swift files before commit
echo "Running swift-format..."

# Get list of staged Swift files
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' || true)

if [ -n "$SWIFT_FILES" ]; then
    echo "$SWIFT_FILES" | xargs swift format format --in-place --parallel
    echo "$SWIFT_FILES" | xargs git add
    echo "✓ Formatted Swift files"
fi
EOF

# Make hook executable
chmod +x "$PRE_COMMIT_HOOK"

echo "✓ Git hooks configured successfully"
echo "Pre-commit hook will automatically format Swift files before each commit"
