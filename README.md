# Dotfiles

A minimal, cross-platform dotfiles repository for managing developer configurations.

## Philosophy

These dotfiles are designed with simplicity and portability in mind:

- **Cross-platform**: Works on macOS, Linux, and Windows (via Git Bash/MSYS)
- **Non-invasive**: Uses symlinks where possible, copies as fallback—existing configs are backed up
- **Modular**: Each tool has its own setup script; run only what you need
- **Focused**: Curated configurations for essential developer tools

## Sections

### [AI](./ai/README.md)

AI coding guidelines symlinked to Codex and Claude config directories. Includes a shared `AGENTS.md` with coding principles and conventions applied across AI tools.

### [Git](./git/README.md)

Git configuration with sensible defaults, global ignore patterns, and GPG signing support. Uses a local config file for machine-specific identity and overrides, keeping sensitive details out of version control.

### [Starship](./starship/README.md)

Minimal Starship prompt configuration with an OS/WSL indicator.

### [WezTerm](./wezterm/README.md)

Cross-platform terminal emulator setup with platform detection for Windows/Unix. Includes font, theme, and window defaults with a local override system for per-machine customization.
