#!/bin/bash
# Common setup utilities for dotfiles

# Detect Windows (Git Bash/MSYS)
is_windows() {
    [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$MSYSTEM" ]]
}

# Function to handle backup and symlink/copy creation
setup_file() {
    local filename="$1"
    local source="$2"
    local target="$3"
    local backup_info=""

    # Create target directory if it doesn't exist
    local target_dir
    target_dir="$(dirname "$target")"
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    # Handle existing file/backup
    if [ -f "$target" ] && [ ! -L "$target" ]; then
        if [ -f "$target.backup" ]; then
            rm "$target"
            backup_info=" | (backup exists, removed old file)"
        else
            mv "$target" "$target.backup"
            backup_info=" | (backed up existing)"
        fi
    fi

    # Create symlink (or copy as fallback)
    if [ -L "$target" ]; then
        echo "$filename already linked, skipping" >&2
    else
        # Try symlink, fall back to copy if it fails
        if is_windows; then
            # On Windows, use MSYS variable for native symlink support
            MSYS=winsymlinks:nativestrict ln -sf "$source" "$target" 2>/dev/null || cp "$source" "$target"
        else
            ln -sf "$source" "$target" 2>/dev/null || cp "$source" "$target"
        fi

        if [ -L "$target" ]; then
            echo "$filename linked$backup_info" >&2
        else
            echo "$filename created (copied - symlinks not available)$backup_info" >&2
        fi
    fi
}
