#!/bin/bash
# Common setup utilities for dotfiles

is_windows() {
    [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "cygwin" || -n "${MSYSTEM:-}" ]]
}

# Native Windows tools need C:/... paths, not Git Bash's /c/...
native_path() {
    if is_windows; then
        cygpath -m "$1"
    else
        printf '%s\n' "$1"
    fi
}

# Prints the backup path; label defaults to "backup"
backup_file() {
    local target="$1"
    local backup
    backup="$target.${2:-backup}.$(date +%Y%m%d%H%M%S)"
    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="$backup.1"
    done
    mv "$target" "$backup"
    printf '%s\n' "$backup"
}

# nativestrict makes Git Bash create a real Windows symlink or fail instead of copying;
# MSYS is ignored on other platforms
make_symlink() {
    MSYS=winsymlinks:nativestrict ln -s "$1" "$2" 2>/dev/null
}

# True when file matches source or any committed version of it, i.e. it is
# an old copied fallback with nothing worth backing up
is_copy_of() {
    local file="$1"
    local source="$2"
    local repo blob history

    cmp -s "$file" "$source" && return 0
    repo="$(dirname "$source")"
    blob="$(git -C "$repo" hash-object --no-filters -- "$file" 2>/dev/null)" || return 1
    # Captured rather than piped to grep -q, which can SIGPIPE git log under pipefail
    history="$(git -C "$repo" log --format= --raw --no-abbrev -- "$(basename "$source")" 2>/dev/null)" || return 1
    [[ "$history" == *" $blob "* ]]
}

setup_file() {
    local filename="$1"
    local source="$2"
    local target="$3"
    local backup_info=""

    [ -d "${target%/*}" ] || mkdir -p "${target%/*}"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "$filename already linked, skipping" >&2
        return 0
    fi

    if [ -f "$target" ] && [ ! -L "$target" ] && is_copy_of "$target" "$source"; then
        rm "$target"
    elif [ -e "$target" ] || [ -L "$target" ]; then
        backup_info=" | (backed up existing to $(backup_file "$target"))"
    fi

    make_symlink "$source" "$target" || cp "$source" "$target"

    if [ -L "$target" ]; then
        echo "$filename linked$backup_info" >&2
    else
        echo "WARNING: $filename was copied because symlinks are unavailable$backup_info" >&2
        echo "WARNING: repo changes to $filename won't apply until you re-run setup; on Windows, enable Developer Mode for symlinks" >&2
    fi
}
