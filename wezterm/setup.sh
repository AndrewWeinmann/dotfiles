#!/bin/bash
set -e  # Exit on error
# Get the directory where this script lives
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common setup utilities
# shellcheck disable=SC1091
source "$DIRECTORY/../lib/common.sh"

# Setup wezterm config file
setup_file ".wezterm.lua" "$DIRECTORY/.wezterm.lua" "$HOME/.wezterm.lua"

# Copy the local wezterm config template if it doesn't exist
if [ ! -f "$HOME/.wezterm.local.lua" ]; then
    echo ".wezterm.local.lua created from template" >&2
    cp "$DIRECTORY/.wezterm.local.lua.template" "$HOME/.wezterm.local.lua"
else
    echo ".wezterm.local.lua already exists, skipping" >&2
fi

echo "✓ Wezterm configuration complete" >&2

# Return success
echo "Update ~/.wezterm.local.lua with any needed overrides"
exit 0
