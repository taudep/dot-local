# dot-local

Personal config files for new machine setup. Clone once, symlink into place, done.

## Contents

- [`zsh/`](zsh/) — `.zshrc`, `.zprofile`, and `pm-env` (password manager helpers)
- [`git/`](git/) — `.gitconfig`
- [`starship/`](starship/) — `starship.toml` prompt config
- [`doom/`](doom/) — Doom Emacs `config.el`, `init.el`, `packages.el`
- [`obsidian-web-clipper/`](obsidian-web-clipper/README.md) — browser extension templates + `install-templates.sh`
- [`docs/secret-management.md`](docs/secret-management.md) — how secrets are loaded from 1Password / Bitwarden

Referenced as a flake input from [taudep/taude-nix](https://github.com/taudep/taude-nix) and symlinked into place by home-manager. For manual setup, follow the steps below.

---

## New Machine Setup

### 1. Clone the repo

```zsh
git clone https://github.com/taudep/dot-local ~/dev/projects/taudep/dot-local
```

### 2. Symlink config files

```zsh
DOTLOCAL=~/dev/projects/taudep/dot-local

ln -sf $DOTLOCAL/zsh/zshrc        ~/.zshrc
ln -sf $DOTLOCAL/zsh/zprofile     ~/.zprofile
ln -sf $DOTLOCAL/zsh/pm-env       ~/.pm-env
ln -sf $DOTLOCAL/git/gitconfig    ~/.gitconfig
ln -sf $DOTLOCAL/starship/starship.toml ~/.config/starship.toml
```

> Doom Emacs config lives at `~/.doom.d/` — symlink individually or copy.

### 3. Install dependencies

```zsh
# Homebrew (macOS)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Starship prompt
brew install starship

# Password manager CLI — install whichever your machine uses
brew install 1password-cli   # work Mac
brew install bitwarden-cli   # personal Mac

# jq (required by Bitwarden helper)
brew install jq
```

### 4. Configure per-machine secrets

Add the following to a **machine-local** file that is **not** checked into git.
`~/.zshrc.local` is a good convention — source it at the bottom of `~/.zshrc`:

```zsh
# ~/.zshrc  (already in this repo)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

Then create `~/.zshrc.local` on each machine:

**Work Mac (1Password)**
```zsh
# ~/.zshrc.local — not tracked in git
export PM_NOTE_NAME=TODD-DISC-SECRETS-ENV
# PM_BACKEND=op is auto-detected when 'op' is in PATH
# export PM_OP_VAULT=Employee  # default, only needed to override
```

**Personal Mac (Bitwarden)**
```zsh
# ~/.zshrc.local — not tracked in git
export PM_BACKEND=bw
export PM_NOTE_NAME=my-dev-secrets
```

### 5. Load secrets

**1Password** — just run:
```zsh
disc-secure
```

**Bitwarden** — unlock first, then load:
```zsh
bw-unlock      # prompts for master password, exports BW_SESSION
disc-secure    # reads the note and exports all env vars
```

See [`docs/secret-management.md`](docs/secret-management.md) for full details on the note format, rotating secrets, and troubleshooting.

### 6. Reload your shell

```zsh
source ~/.zshrc
```

---

## What is NOT in this repo

- Secrets, tokens, API keys, or passwords of any kind
- `~/.zshrc.local` (machine-local, never commit this)
- `~/.disc-secure` (legacy secret file, superseded by `pm-env` + 1Password/Bitwarden)
