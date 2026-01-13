#!/bin/bash
set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT_STEPS=()
FAILED_MODULES=()

# Loop over subdirectories and call setup.sh in each
for dir in "$SCRIPT_DIR"/*/; do
    module=$(basename "$dir")

    if [ -f "$dir/setup.sh" ]; then
        # Print module header
        echo "=== $(echo ${module:0:1} | tr 'a-z' 'A-Z')${module:1} Setup ===" >&2

        # Capture stdout (next steps) and run the script
        if next_step=$("$dir/setup.sh"); then
            if [ -n "$next_step" ]; then
                NEXT_STEPS+=("[$module] $next_step")
            fi
        else
            FAILED_MODULES+=("$module")
        fi

        echo "" >&2
    fi
done

# Report outcomes from called scripts
if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
    printf "\n✗ Failed modules:\n" >&2
    for module in "${FAILED_MODULES[@]}"; do
        echo "  - $module" >&2
    done
    exit 1
fi

# Display all next steps
if [ ${#NEXT_STEPS[@]} -gt 0 ]; then
    echo "=== Next Steps ===" >&2
    for step in "${NEXT_STEPS[@]}"; do
        echo "  - $step" >&2
    done
fi
