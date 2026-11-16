# Dotfiles

A minimal, cross-platform dotfiles repository for managing developer configurations.

## Philosophy

These dotfiles are designed with simplicity and portability in mind:

- **Cross-platform**: Works on macOS, Linux, and Windows (via Git Bash/MSYS)
- **Non-invasive**: Uses symlinks where possible, copies as fallback—existing configs are backed up
- **Modular**: Each tool has its own setup script; run only what you need
- **Focused**: Curated configurations for essential developer tools

## Install

```bash
git clone git@github.com:AndrewWeinmann/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh
```

On Windows, run it from Git Bash. Symlinks need Developer Mode (Settings > System > For developers); without it, files are copied and the installer warns that repo changes won't apply until you re-run it.

If a machine still has the old `~/.gitconfig` symlink, run `./install.sh` right after pulling: the shared config no longer includes `~/.gitconfig.local`, so identity and signing are missing until the installer migrates it.

Re-running `install.sh` is safe; each module skips work that's already done. Run a single module with its own `setup.sh`, for example `./git/setup.sh`.

## Tests

```bash
bash tests/install.test.sh
```

The tests run the installers against throwaway home directories, so they don't touch your real configuration. CI runs them on Linux, macOS, and Windows, along with shellcheck.

## Sections

### [AI](./ai/README.md)

AI coding guidelines symlinked to Codex and Claude config directories. Includes a shared `AGENTS.md` with coding principles and conventions applied across AI tools.

### [Git](./git/README.md)

Git configuration with sensible defaults, global ignore patterns, and SSH commit signing. The installer generates a per-machine `~/.gitconfig` that includes the shared config, so identity and anything tools write stay out of version control.

### [Starship](./starship/README.md)

Minimal Starship prompt configuration with an OS/WSL indicator.

### [WezTerm](./wezterm/README.md)

Cross-platform terminal emulator setup with platform detection for Windows/Unix. Includes font, theme, and window defaults with a local override system for per-machine customization.
