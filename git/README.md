# Git Configuration

Shared Git defaults, global ignore patterns, and SSH commit signing, with a per-machine `~/.gitconfig` for identity and local settings.

## What's Included

- **`.gitconfig`**: Shared settings and aliases, included from `~/.gitconfig`
- **`.gitignore`**: Global ignore patterns for local files, OS artifacts, and credentials, used as `core.excludesFile`
- **`.gitconfig.template`**: Identity and signing placeholders for a new machine

## How It Works

`~/.gitconfig` is a regular file the installer generates, not a symlink:

```ini
[include]
	path = "/path/to/dotfiles/git/.gitconfig"
[core]
	excludesFile = "/path/to/dotfiles/git/.gitignore"
# ---- machine-specific (identity, signing, tool-written settings) ----
[user]
	name = ...
```

`git config --global <key>` reads only `~/.gitconfig` itself, so shared values look missing there. Use `git config <key>` or add `--includes` to see them.

Git applies later values over earlier ones, so everything below the include overrides the shared defaults. When a tool or installer runs `git config --global` (Git for Windows, `git lfs install`, `git maintenance register`), the setting goes into this local file instead of the repo.

## Setup

Run the parent `install.sh` or directly run `./setup.sh` in this directory.

The setup process will:

1. Remove an old `~/.gitconfig` or `~/.gitignore` symlink (or stale copy) that points at this repo
2. Create `~/.gitconfig` with the include, then either your existing `~/.gitconfig.local` (moved aside to `~/.gitconfig.local.migrated.<timestamp>`) or the template
3. If `~/.gitconfig` already exists without the include, add the include at the top and keep your existing settings below it

Re-running setup leaves an already-configured `~/.gitconfig` unchanged.

## Next Steps

If setup reports it, edit `~/.gitconfig` to set:

- Your Git identity (`user.name` and `user.email`)
- Your SSH signing key, if it isn't `~/.ssh/id_ed25519.pub`
- Any machine-specific overrides

After migrating a machine that used to symlink, re-run any tool that had written global settings into the shared file. On Linux and macOS that includes `git lfs install` (Git for Windows already sets the LFS filter system-wide), and `git maintenance register` in any repository it maintains.
