# Git Configuration

Git setup with global configuration, GPG signing support, and local overrides.

## What's Included

- **`.gitconfig`**: Global Git configuration with default settings and signing configuration
- **`.gitignore`**: Global ignore patterns for common development files and OS artifacts
- **`.gitconfig.local` (template)**: Per-machine overrides for identity and sensitive settings

## Setup

Run the parent `install.sh` or directly run `./setup.sh` in this directory.

The setup process will:

1. Create or symlink `.gitconfig` and `.gitignore` to your home directory
2. Create `.gitconfig.local` from the template if it doesn't exist (existing files are preserved)
3. Back up any existing config files

## Next Steps

After setup, edit `~/.gitconfig.local` to add:

- Your Git user identity (`user.name` and `user.email`)
- GPG signing key details if you use signed commits
- Any machine-specific Git configuration overrides
