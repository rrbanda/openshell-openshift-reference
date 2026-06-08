#!/usr/bin/env bash
# Install git hooks for this repository.
# Run once after cloning: ./scripts/setup-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

ln -sf ../../scripts/hooks/pre-commit-secrets "$HOOKS_DIR/pre-commit"
ln -sf ../../scripts/hooks/pre-push-secrets "$HOOKS_DIR/pre-push"

echo "Installed:"
echo "  pre-commit -> scripts/hooks/pre-commit-secrets"
echo "  pre-push   -> scripts/hooks/pre-push-secrets"
echo ""
echo "Both hooks block commits/pushes containing secrets, tokens, or credentials."
echo "Bypass (not recommended): git commit --no-verify / git push --no-verify"
