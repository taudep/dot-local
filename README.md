# dot-local
All my config things for new machines

## Contents

- [`obsidian-web-clipper/`](obsidian-web-clipper/README.md) - Obsidian Web Clipper
  browser extension templates, plus `install-templates.sh` to pull the latest versions
  from GitHub onto a new machine.
- `zsh/` - `.zshrc` and `.zprofile`.
- `git/` - `.gitconfig`.
- `starship/` - `starship.toml` prompt config.
- `doom/` - Doom Emacs `config.el`, `init.el`, `packages.el`.

Referenced as a flake input from
[taudep/taude-nix](https://github.com/taudep/taude-nix) and symlinked into place by
home-manager.
