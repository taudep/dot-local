# Secret Management

Local dev secrets are stored in a password manager and injected into the shell on demand. Nothing sensitive is written to disk or checked into git.

The shell helpers live in [`zsh/pm-env`](../zsh/pm-env), symlinked to `~/.pm-env`, and sourced from `~/.bash_aliases`.

## Supported Password Managers

| Tool | CLI | Machines |
|---|---|---|
| 1Password | `op` | Work Mac |
| Bitwarden | `bw` | Personal Mac |

The correct backend is auto-detected from `PATH`. Set `PM_BACKEND=op` or `PM_BACKEND=bw` to force a choice.

## Config Variables

Set these per machine in `~/.zshrc.local` (never commit that file):

| Variable | Required | Default | Description |
|---|---|---|---|
| `PM_NOTE_NAME` | Yes | — | Name of the note containing env vars |
| `PM_BACKEND` | No | auto | Force `op` or `bw` |
| `PM_OP_VAULT` | No | `Employee` | 1Password vault name |

## Note Format

Create a Secure Note (1Password) or note item (Bitwarden) with this body:

```
# Lines starting with # are ignored
# Blank lines are also ignored

GITHUB_TOKEN=your-token-here
ANTHROPIC_API_KEY=your-key-here
JIRA_API_TOKEN=your-token-here

# 'export' prefix is optional — it gets stripped
export JFROG_ACCESS_TOKEN=your-token-here
```

Rules:
- One `KEY=value` per line
- Values must be non-empty (lines with empty values are skipped)
- Keys must match `[A-Za-z_][A-Za-z0-9_]*`

## Shell Functions

### `op-env [note-name]`

Reads the named note and exports all env vars into the current shell.

```zsh
op-env                        # uses $PM_NOTE_NAME
op-env MY-OTHER-NOTE          # override for this call
op-env op://Vault/Item/field  # legacy 1Password URI (passed directly to op read)
```

### `disc-secure`

Convenience wrapper: sets `DISC_SECURE=true`, calls `op-env`, re-sources the prompt config.

```zsh
disc-secure
```

### `bw-unlock`

Bitwarden only. Unlocks the vault and exports `BW_SESSION`. Run once per terminal session before `disc-secure`.

```zsh
bw-unlock
```

## Daily Usage

**1Password (work Mac)**
```zsh
disc-secure
# Touch ID prompt appears if CLI session has expired
# Each exported var is printed:
#   exported: GITHUB_TOKEN
#   exported: ANTHROPIC_API_KEY
#   ...
```

**Bitwarden (personal Mac)**
```zsh
bw-unlock      # enter master password once
disc-secure    # loads all vars from the note
```

## Rotating a Secret

1. Open your password manager and edit the note.
2. Update the `KEY=value` line.
3. In any open terminal, run `op-env` again to reload.

No code changes, no commits, no file edits required.

## Adding a New Secret

Same as rotating — just add a new `KEY=value` line to the note and re-run `op-env`.

## Onboarding a New Machine

See [README.md](../README.md#new-machine-setup) for the full setup steps. The short version:

1. Install the appropriate CLI (`op` or `bw`)
2. Symlink `~/.pm-env` from this repo
3. Set `PM_NOTE_NAME` (and optionally `PM_BACKEND`) in `~/.zshrc.local`
4. Run `disc-secure` (after `bw-unlock` on Bitwarden machines)

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `error: no password manager CLI found` | Neither `op` nor `bw` in PATH | Install the right CLI (`brew install 1password-cli` or `bitwarden-cli`) |
| `error: BW_SESSION not set` | Bitwarden not unlocked | Run `bw-unlock` |
| `op read` fails | 1Password app locked or CLI session expired | Unlock 1Password; CLI will prompt for Touch ID |
| `error: no note name given` | `PM_NOTE_NAME` not set | Add `export PM_NOTE_NAME=your-note-name` to `~/.zshrc.local` |
| A variable isn't exported | Value is empty in the note | Ensure the line has a non-empty value: `KEY=somevalue` |
| Stale value after rotating | Old export still set in session | Re-run `op-env` in the affected terminal |
