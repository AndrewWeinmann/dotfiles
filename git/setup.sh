#!/bin/bash
set -e  # Exit on error

# Get the directory where this script lives
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common setup utilities
# shellcheck disable=SC1091
source "$DIRECTORY/../lib/common.sh"

# Setup git config files
setup_file ".gitconfig" "$DIRECTORY/.gitconfig" "$HOME/.gitconfig"
setup_file ".gitignore" "$DIRECTORY/.gitignore" "$HOME/.gitignore"

# Copy the local gitconfig template if it doesn't exist
if [ ! -f "$HOME/.gitconfig.local" ]; then
    echo ".gitconfig.local created from template" >&2
    cp "$DIRECTORY/.gitconfig.local.template" "$HOME/.gitconfig.local"
else
    echo ".gitconfig.local already exists, skipping" >&2
fi

echo "✓ Git configuration complete" >&2

# Return success & next steps
echo "Update ~/.gitconfig.local with identity & signing info and any needed overrides"
exit 0
