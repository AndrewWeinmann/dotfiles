#!/bin/bash
set -euo pipefail

# Get the directory where this script lives
DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common setup utilities
# shellcheck disable=SC1091
source "$DIRECTORY/../lib/common.sh"

SHARED_CONFIG="$DIRECTORY/.gitconfig"
SHARED_IGNORE="$DIRECTORY/.gitignore"
TEMPLATE="$DIRECTORY/.gitconfig.template"
TARGET="$HOME/.gitconfig"
LEGACY_LOCAL="$HOME/.gitconfig.local"
LEGACY_IGNORE="$HOME/.gitignore"

MARKER="# Managed by dotfiles/git/setup.sh"
SEPARATOR="# ---- machine-specific (identity, signing, tool-written settings) ----"
INCLUDE_PATH="$(native_path "$SHARED_CONFIG")"
IGNORE_PATH="$(native_path "$SHARED_IGNORE")"

# Scratch files live next to ~/.gitconfig so the final mv stays on one filesystem
WORK="$(mktemp -d "$HOME/.gitconfig-setup.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The include must come first so machine-specific values below it win
write_header() {
    cat <<EOF
$MARKER: shared settings come from the include below.
# Everything after it is machine-specific and overrides the shared config.
[include]
	path = "$INCLUDE_PATH"
[core]
	excludesFile = "$IGNORE_PATH"
$SEPARATOR
EOF
}

# Writes the header followed by body; mode_from (default body) supplies the file mode
write_config() {
    local body="$1"
    local mode_from="${2:-$1}"
    # Copy first so the rewritten file keeps the mode (it may hold tokens)
    cp -p "$mode_from" "$WORK/config"
    { write_header; cat "$body"; } > "$WORK/config"
    mv "$WORK/config" "$TARGET"
}

# Keeps the next file's first line from joining a last line that has no newline
cat_with_newline() {
    cat "$1"
    if [ -n "$(tail -c 1 "$1")" ]; then
        echo
    fi
}

is_managed() { head -n 1 "$TARGET" 2>/dev/null | grep -Fq "$MARKER"; }

# Line matches ignore a trailing CR, since the file may have been saved with Windows line endings
has_separator() {
    awk -v sep="$SEPARATOR" '{ sub(/\r$/, "") } $0 == sep { found = 1; exit } END { exit !found }' "$TARGET"
}

has_shared_include() {
    local includes line
    includes="$(git config --file "$TARGET" --get-all include.path 2>/dev/null || true)"
    while IFS= read -r line; do
        [ "$line" = "$INCLUDE_PATH" ] && return 0
    done <<< "$includes"
    return 1
}

# Regenerates only the header of a managed file, keeping the machine-specific part as is
rewrite_header() {
    awk -v sep="$SEPARATOR" 'found { print } { line = $0; sub(/\r$/, "", line) } line == sep { found = 1 }' \
        "$TARGET" > "$WORK/body"
    write_config "$WORK/body" "$TARGET"
}

# Removes a symlink to the repo file or a copy of it
remove_repo_link() {
    local target="$1"
    local source="$2"
    local name="$3"

    if [ -L "$target" ]; then
        # A link into an earlier checkout counts too when its contents are a repo version
        if [ "$(readlink "$target")" = "$source" ] || { [ -f "$target" ] && is_copy_of "$target" "$source"; }; then
            rm "$target"
            echo "$name symlink to the repo removed" >&2
        fi
    elif [ -f "$target" ] && is_copy_of "$target" "$source"; then
        rm "$target"
        echo "$name copy of the repo file removed" >&2
    fi
}

# Replaces a symlink to a config elsewhere with a regular copy of it, so its settings survive
materialize_foreign_link() {
    if [ ! -L "$TARGET" ] || [ "$(readlink "$TARGET")" = "$SHARED_CONFIG" ]; then
        return 0
    fi
    if [ -f "$TARGET" ]; then
        cp -pL "$TARGET" "$WORK/linked"
        echo ".gitconfig symlink pointed elsewhere, backed up to $(backup_file "$TARGET") and kept as a regular file" >&2
        mv "$WORK/linked" "$TARGET"
    else
        echo ".gitconfig symlink was broken, backed up to $(backup_file "$TARGET")" >&2
    fi
}

identity_missing() {
    local name email
    name="$(git config --file "$TARGET" --includes user.name || true)"
    email="$(git config --file "$TARGET" --includes user.email || true)"
    [ -z "$name" ] || [ "$name" = "NAME" ] || [ -z "$email" ] || [ "$email" = "EMAIL" ]
}

migrate_legacy_local() {
    local migrated
    migrated="$(backup_file "$LEGACY_LOCAL" migrated)"
    echo ".gitconfig.local settings moved into .gitconfig (original kept as $migrated)" >&2
}

if ! is_managed; then
    remove_repo_link "$TARGET" "$SHARED_CONFIG" ".gitconfig"
    materialize_foreign_link
fi
remove_repo_link "$LEGACY_IGNORE" "$SHARED_IGNORE" ".gitignore"

if [ ! -e "$TARGET" ]; then
    if [ -f "$LEGACY_LOCAL" ]; then
        write_config "$LEGACY_LOCAL"
        migrate_legacy_local
    else
        write_config "$TEMPLATE"
        echo ".gitconfig created from template" >&2
    fi
elif has_shared_include; then
    echo ".gitconfig already includes the shared config, skipping" >&2
elif is_managed && has_separator; then
    rewrite_header
    echo ".gitconfig shared include updated to this checkout" >&2
else
    echo ".gitconfig existing settings kept below the shared include; remove any the repo now provides" >&2
    if [ -f "$LEGACY_LOCAL" ]; then
        # Appended last because the old shared config included it last, so it still wins
        { cat_with_newline "$TARGET"; cat "$LEGACY_LOCAL"; } > "$WORK/body"
        write_config "$WORK/body" "$TARGET"
        git config --file "$TARGET" --unset-all include.path '^[~][/][.]gitconfig[.]local$' || true
        migrate_legacy_local
    else
        write_config "$TARGET"
    fi
fi

# The old shared config pointed excludesFile at ~/.gitignore; once that file is gone,
# a kept copy of the setting would override the header and disable the global ignores.
# Brackets stop Git Bash from rewriting the pattern as a Windows path.
if [ ! -e "$LEGACY_IGNORE" ]; then
    git config --file "$TARGET" --unset-all core.excludesFile '^[~][/][.]gitignore$' || true
fi

echo "✓ Git configuration complete" >&2

# Return success & next steps
if identity_missing; then
    echo "Update ~/.gitconfig with your identity & signing info"
fi
exit 0
