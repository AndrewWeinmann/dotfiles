#!/bin/bash
# Runs the installers against throwaway HOME directories and checks the results.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO/lib/common.sh"

# Keep the machine's own Git config out of every assertion
export GIT_CONFIG_NOSYSTEM=1
unset GIT_CONFIG_GLOBAL XDG_CONFIG_HOME

SHARED_CONFIG="$REPO/git/.gitconfig"
SHARED_IGNORE="$REPO/git/.gitignore"
SHARED_CONFIG_NATIVE="$(native_path "$SHARED_CONFIG")"
SHARED_IGNORE_NATIVE="$(native_path "$SHARED_IGNORE")"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
FAILURES=0

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1"; FAILURES=$((FAILURES + 1)); }

assert_eq() {
    local description="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        pass "$description"
    else
        fail "$description (expected '$expected', got '$actual')"
    fi
}

assert_true() {
    local description="$1"
    shift
    if "$@"; then pass "$description"; else fail "$description"; fi
}

new_home() { mktemp -d "$SANDBOX/home.XXXXXX"; }

# Run git/setup.sh with the given HOME; prints its next-step output
git_setup() { HOME="$1" "$REPO/git/setup.sh" 2>/dev/null; }

global() {
    local home="$1"
    shift
    HOME="$home" git config --global --includes "$@" || true
}

checksum() { cksum < "$1"; }
is_regular_file() { [ -f "$1" ] && [ ! -L "$1" ]; }
is_absent() { [ ! -e "$1" ] && [ ! -L "$1" ]; }
has_no_scratch_dirs() {
    local dir
    for dir in "$1"/.gitconfig-setup.*; do
        [ -e "$dir" ] && return 1
    done
    return 0
}
file_mode() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }
origin_of() { global "$1" --show-origin "$2" | cut -f1; }

count_backups() { find "$(dirname "$1")" -maxdepth 1 -name "$(basename "$1").${2:-backup}.*" | wc -l | tr -d ' '; }

echo "# Fresh install"
home="$(new_home)"
next_steps="$(git_setup "$home")"
assert_true "creates a regular ~/.gitconfig" is_regular_file "$home/.gitconfig"
assert_eq "includes the shared config" "$SHARED_CONFIG_NATIVE" "$(global "$home" --get include.path)"
assert_eq "loads shared aliases" "checkout" "$(global "$home" alias.co)"
assert_eq "fills identity from the template" "NAME" "$(global "$home" user.name)"
assert_true "asks for identity" grep -q "identity" <<< "$next_steps"
before="$(checksum "$home/.gitconfig")"
git_setup "$home" > /dev/null
assert_eq "re-running leaves ~/.gitconfig unchanged" "$before" "$(checksum "$home/.gitconfig")"

echo "# Migration from symlinks and .gitconfig.local"
home="$(new_home)"
if make_symlink "$SHARED_CONFIG" "$home/.gitconfig" && make_symlink "$SHARED_IGNORE" "$home/.gitignore"; then
    printf '[user]\n\tname = Test User\n\temail = test@example.com\n' > "$home/.gitconfig.local"
    shared_before="$(checksum "$SHARED_CONFIG")"
    next_steps="$(git_setup "$home")"
    assert_true "replaces the symlink with a regular file" is_regular_file "$home/.gitconfig"
    assert_true "removes the ~/.gitignore symlink" is_absent "$home/.gitignore"
    assert_eq "keeps identity from .gitconfig.local" "Test User" "$(global "$home" user.name)"
    assert_true "removes .gitconfig.local" is_absent "$home/.gitconfig.local"
    assert_true "keeps a migrated copy" test "$(count_backups "$home/.gitconfig.local" migrated)" = 1
    assert_eq "does not ask for identity" "" "$next_steps"
    HOME="$home" git config --global test.written yes
    assert_eq "global writes stay out of the repo file" "$shared_before" "$(checksum "$SHARED_CONFIG")"
    assert_eq "global writes land in ~/.gitconfig" "yes" "$(git config --file "$home/.gitconfig" test.written || true)"
    assert_eq "identity comes from ~/.gitconfig" "file:$(native_path "$home/.gitconfig")" "$(origin_of "$home" user.name)"
    assert_eq "aliases come from the repo file" "file:$SHARED_CONFIG_NATIVE" "$(origin_of "$home" alias.co)"
else
    echo "# skip - symlinks are unavailable here"
fi

echo "# Symlinks to files outside the repo"
home="$(new_home)"
printf '[user]\n\tname = Linked User\n\temail = linked@example.com\n' > "$home/elsewhere.gitconfig"
printf 'custom-pattern\n' > "$home/elsewhere.gitignore"
if make_symlink "$home/elsewhere.gitconfig" "$home/.gitconfig" && make_symlink "$home/elsewhere.gitignore" "$home/.gitignore"; then
    git_setup "$home" > /dev/null
    assert_true "turns the link into a regular file" is_regular_file "$home/.gitconfig"
    assert_eq "keeps the linked settings" "Linked User" "$(global "$home" user.name)"
    assert_eq "backs up the link" "1" "$(count_backups "$home/.gitconfig")"
    assert_true "leaves the linked file alone" grep -q "Linked User" "$home/elsewhere.gitconfig"
    assert_true "leaves an unrelated ~/.gitignore link in place" test -L "$home/.gitignore"
else
    echo "# skip - symlinks are unavailable here"
fi

echo "# Symlinks into an earlier checkout"
home="$(new_home)"
mkdir -p "$home/old-checkout/git"
git -C "$REPO" show "$(git -C "$REPO" log --format=%H -- git/.gitconfig | tail -n 1):git/.gitconfig" > "$home/old-checkout/git/.gitconfig"
cp "$SHARED_IGNORE" "$home/old-checkout/git/.gitignore"
if make_symlink "$home/old-checkout/git/.gitconfig" "$home/.gitconfig" && make_symlink "$home/old-checkout/git/.gitignore" "$home/.gitignore"; then
    git_setup "$home" > /dev/null
    assert_eq "drops the old checkout's settings" "" "$(git config --file "$home/.gitconfig" alias.co || true)"
    assert_eq "makes no backup of the old link" "0" "$(count_backups "$home/.gitconfig")"
    assert_true "removes the old ~/.gitignore link" is_absent "$home/.gitignore"
else
    echo "# skip - symlinks are unavailable here"
fi

echo "# Migration from a copied config"
home="$(new_home)"
cp "$SHARED_CONFIG" "$home/.gitconfig"
git_setup "$home" > /dev/null
assert_eq "drops the stale copy's settings" "" "$(git config --file "$home/.gitconfig" alias.co || true)"
assert_eq "includes the shared config" "$SHARED_CONFIG_NATIVE" "$(global "$home" --get include.path)"

echo "# Migration from a copy of an older shared config"
home="$(new_home)"
oldest="$(git -C "$REPO" log --format=%H -- git/.gitconfig | tail -n 1)"
git -C "$REPO" show "$oldest:git/.gitconfig" > "$home/.gitconfig"
git_setup "$home" > /dev/null
assert_eq "drops the older copy's settings" "" "$(git config --file "$home/.gitconfig" alias.co || true)"
assert_eq "includes the shared config" "$SHARED_CONFIG_NATIVE" "$(global "$home" --get include.path)"

echo "# Edited copy of an older shared config"
home="$(new_home)"
git -C "$REPO" show "$oldest:git/.gitconfig" > "$home/.gitconfig"
printf '[user]\n\tname = Edited\n' >> "$home/.gitconfig"
git_setup "$home" > /dev/null
assert_eq "keeps the edits" "Edited" "$(global "$home" user.name)"
assert_eq "drops the legacy ~/.gitignore excludesFile" "$SHARED_IGNORE_NATIVE" "$(global "$home" core.excludesFile)"

echo "# Repository moved since the last install"
home="$(new_home)"
git_setup "$home" > /dev/null
printf '[include]\n\tpath = /work/git/.gitconfig\n' >> "$home/.gitconfig"
sed -e "s|$SHARED_CONFIG_NATIVE|/old/place/git/.gitconfig|" \
    -e "s|$SHARED_IGNORE_NATIVE|/old/place/git/.gitignore|" "$home/.gitconfig" > "$home/moved"
mv "$home/moved" "$home/.gitconfig"
git_setup "$home" > /dev/null
assert_eq "points the include at this checkout" "$SHARED_CONFIG_NATIVE" "$(git config --file "$home/.gitconfig" --get-all include.path | head -n 1)"
assert_eq "keeps machine-specific includes" "/work/git/.gitconfig" "$(git config --file "$home/.gitconfig" --get-all include.path | tail -n 1)"
assert_eq "points excludesFile at this checkout" "$SHARED_IGNORE_NATIVE" "$(git config --file "$home/.gitconfig" --get-all core.excludesFile)"
assert_eq "keeps a single managed header" "1" "$(grep -c "Managed by dotfiles" "$home/.gitconfig")"

echo "# Managed config saved with Windows line endings"
home="$(new_home)"
git_setup "$home" > /dev/null
sed -e "s|$SHARED_CONFIG_NATIVE|/old/place/git/.gitconfig|" "$home/.gitconfig" \
    | awk '{ printf "%s\r\n", $0 }' > "$home/crlf"
mv "$home/crlf" "$home/.gitconfig"
git_setup "$home" > /dev/null
assert_eq "rewrites the header instead of adding one" "1" "$(grep -c "Managed by dotfiles" "$home/.gitconfig")"
assert_eq "points the include at this checkout" "$SHARED_CONFIG_NATIVE" "$(git config --file "$home/.gitconfig" --get-all include.path)"
assert_eq "keeps the machine-specific part" "NAME" "$(global "$home" user.name)"
assert_true "leaves no scratch files behind" has_no_scratch_dirs "$home"

echo "# Existing user-authored config"
home="$(new_home)"
printf '[user]\n\tname = Mine\n[alias]\n\tco = custom-co\n' > "$home/.gitconfig"
chmod 600 "$home/.gitconfig"
mode_before="$(file_mode "$home/.gitconfig")"
next_steps="$(git_setup "$home")"
assert_true "asks for the missing email" grep -q "identity" <<< "$next_steps"
assert_eq "keeps the file mode" "$mode_before" "$(file_mode "$home/.gitconfig")"
assert_eq "includes the shared config" "$SHARED_CONFIG_NATIVE" "$(global "$home" --get include.path)"
assert_eq "existing values override shared ones" "custom-co" "$(global "$home" alias.co)"
assert_eq "shared values fill the gaps" "branch" "$(global "$home" alias.br)"
assert_eq "keeps existing identity" "Mine" "$(global "$home" user.name)"
before="$(checksum "$home/.gitconfig")"
git_setup "$home" > /dev/null
assert_eq "re-running leaves ~/.gitconfig unchanged" "$before" "$(checksum "$home/.gitconfig")"

echo "# Existing config alongside .gitconfig.local"
home="$(new_home)"
printf '[alias]\n\tco = custom-co\n[include]\n\tpath = ~/.gitconfig.local' > "$home/.gitconfig"
printf '[user]\n\tname = Local User\n\temail = local@example.com\n' > "$home/.gitconfig.local"
git_setup "$home" > /dev/null
assert_eq "keeps identity from .gitconfig.local" "Local User" "$(global "$home" user.name)"
assert_eq "keeps existing settings" "custom-co" "$(global "$home" alias.co)"
assert_true "removes .gitconfig.local" is_absent "$home/.gitconfig.local"
assert_eq "keeps a migrated copy" "1" "$(count_backups "$home/.gitconfig.local" migrated)"
assert_eq "drops the include of the moved file" "$SHARED_CONFIG_NATIVE" "$(git config --file "$home/.gitconfig" --get-all include.path)"

echo "# Global ignore file"
repo="$SANDBOX/ignore-repo"
git init -q "$repo"
touch "$repo/secret.pem" "$repo/notes.txt"
is_ignored() { HOME="$home" git -C "$repo" check-ignore -q "$1"; }
is_not_ignored() { ! is_ignored "$1"; }
assert_true "ignores shared patterns" is_ignored secret.pem
assert_true "keeps other files" is_not_ignored notes.txt

echo "# Copied fallbacks"
home="$(new_home)"
cp "$REPO/starship/starship.toml" "$home/starship.toml"
setup_file "starship.toml" "$REPO/starship/starship.toml" "$home/starship.toml" 2>/dev/null
setup_file "starship.toml" "$REPO/starship/starship.toml" "$home/starship.toml" 2>/dev/null
assert_eq "re-running over an identical copy makes no backups" "0" "$(count_backups "$home/starship.toml")"
printf 'mine\n' > "$home/other.toml"
setup_file "other.toml" "$REPO/starship/starship.toml" "$home/other.toml" 2>/dev/null
assert_eq "backs up a file that differs" "1" "$(count_backups "$home/other.toml")"

echo "# Full install"
home="$(new_home)"
if HOME="$home" "$REPO/install.sh" > /dev/null 2>&1; then
    pass "install.sh succeeds"
else
    fail "install.sh succeeds"
fi
for file in .gitconfig .wezterm.lua .wezterm.local.lua .config/starship.toml .claude/CLAUDE.md .codex/AGENTS.md; do
    assert_true "installs ~/$file" test -e "$home/$file"
done

echo
if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES check(s) failed"
    exit 1
fi
echo "All checks passed"
