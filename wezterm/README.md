# WezTerm Configuration

WezTerm terminal emulator with cross-platform defaults and local overrides.

## What's Included

- **`.wezterm.lua`**: Main configuration with platform detection, font, colors, and window settings
- **`.wezterm.local.lua` (template)**: Per-machine overrides for customization

## Setup

Run the parent `install.sh` or directly run `./setup.sh` in this directory.

The setup process will:

1. Create or symlink `.wezterm.lua` to your home directory
2. Create `.wezterm.local.lua` from the template if it doesn't exist (existing files are preserved)
3. Back up any existing config files

## Next Steps

After setup, edit `~/.wezterm.local.lua` to customize:

- Font size or family
- Color scheme preferences
- Shell or default program
- Any machine-specific WezTerm configuration overrides
