# Obsidian Web Clipper templates

Templates for the official [Obsidian Web Clipper](https://obsidian.md/clipper) browser
extension, kept here so they're versioned and easy to pull onto a new machine.

| File | Template name | Behavior |
|---|---|---|
| `0-inbox-clippings-clipper.json` | 0 Inbox Clippings | create |
| `add-to-todo-clipper.json` | Add to TODO | create |
| `github-repository-clipper.json` | GitHub Repository | create |
| `hacker-news-clipper.json` | Hacker News | create |
| `link-clipper.json` | Link | create |

## Why there's no fully automatic installer

Web Clipper has no CLI or file-based way to load templates. It stores them in the
browser's `chrome.storage.sync` (which is how they sync across any Chrome you're signed
into with the same Google account), and the only supported way to add or change one is
through the extension's own Settings UI. `install-templates.sh` handles everything up to
that point - importing is a manual, few-click step by design, so a script can't silently
overwrite something you edited by hand in the browser.

## `install-templates.sh`

```
install-templates.sh [DEST]
```
Downloads the latest `*.json` templates straight from this repo on GitHub (`main`
branch, via the GitHub API - always current, no local checkout required) into `DEST`
(default `~/obsidian-web-clipper-templates`). Reports each file as new / updated /
unchanged, then scans common Chromium browser profiles (Chrome, Brave, Edge, Arc,
Vivaldi) for the extension and prints where it's installed.

```
install-templates.sh --verify DIR
```
Read-only safety check. In the browser, export a template you care about (Settings >
Templates > select it > `...` menu > Export) into `DIR`, then run this to compare it
against the GitHub version (matched by the template's `name` field, not filename). Use
this **before** deleting and re-importing a template, so you don't lose local edits.
Reports each template as:
- `= up to date` - installed copy matches GitHub, nothing to do
- `! DIFFERS` - shown with a diff; review before overwriting
- `? not exported` - on GitHub but you haven't exported a copy to check yet
- `+ local only` - exported locally but not tracked in this repo

### Installing or updating a template in the browser

1. Run `install-templates.sh` to fetch the latest files.
2. If you already have that template installed and might have edited it locally, export
   it and run `install-templates.sh --verify DIR` first.
3. In the extension: Settings > Templates > Import > pick the file from the downloaded
   folder.
4. Import always adds a new template rather than overwriting - if one with that name
   already exists and you've confirmed via `--verify` that it's safe to replace, delete
   the old one first.
5. Repeat per browser (see the "found in ..." list the script prints).

## Adding or editing a template

Edit or add a template in the browser's UI, then use the `...` menu > "Copy to
clipboard" (or Export) to get its JSON, and save it here as `<name>-clipper.json`. Keep
the schema Web Clipper expects: `schemaVersion`, `name`, `behavior`,
`noteContentFormat`, `properties`, `triggers`, `noteNameFormat`, `path`.
