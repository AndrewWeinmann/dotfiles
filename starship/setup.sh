#!/bin/bash
set -e  # Exit on error

# Get the directory where this script lives
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common setup utilities
# shellcheck disable=SC1091
source "$DIRECTORY/../lib/common.sh"

# Setup starship config file
setup_file "starship.toml" "$DIRECTORY/starship.toml" "$HOME/.config/starship.toml"

echo "✓ Starship configuration complete" >&2

# Return success
exit 0
