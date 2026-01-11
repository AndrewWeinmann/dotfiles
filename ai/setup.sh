#!/bin/bash
set -e  # Exit on error

# Get the directory where this script lives
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common setup utilities
# shellcheck disable=SC1091
source "$DIRECTORY/../lib/common.sh"

# Setup AI agent configuration files
setup_file "AGENTS.md → ~/.codex/AGENTS.md" "$DIRECTORY/AGENTS.md" "$HOME/.codex/AGENTS.md"
setup_file "AGENTS.md → ~/.claude/CLAUDE.md" "$DIRECTORY/AGENTS.md" "$HOME/.claude/CLAUDE.md"

echo "✓ AI configuration complete" >&2

exit 0
