#!/usr/bin/env bash
# Fetches the latest Obsidian Web Clipper templates from GitHub and reports
# which local Chromium browsers have the extension installed. Importing a
# template into the browser is still a manual step (Web Clipper has no
# file-based install path) - see the instructions printed at the end.
#
# Usage:
#   install-templates.sh [DEST]        Download the latest templates into DEST
#                                       (default: ~/obsidian-web-clipper-templates)
#   install-templates.sh --verify DIR  Compare GitHub templates against files you've
#                                       exported from the browser (Settings > Templates
#                                       > ... menu > Export) into DIR. Read-only - never
#                                       downloads or writes anything.
set -euo pipefail

REPO="taudep/dot-local"
BRANCH="main"
SUBDIR="obsidian-web-clipper"
EXT_ID="cnjifjpddelmedmihgijeibhnjfabmlf"
API_URL="https://api.github.com/repos/$REPO/contents/$SUBDIR?ref=$BRANCH"

if [[ "${1:-}" == "--verify" ]]; then
    installed_dir="${2:-}"
    if [[ -z "$installed_dir" || ! -d "$installed_dir" ]]; then
        echo "Usage: $0 --verify DIR" >&2
        echo "DIR must be a folder containing templates exported from the browser" >&2
        echo "(Settings > Templates > select a template > ... menu > Export)." >&2
        exit 1
    fi
    echo "Comparing github.com/$REPO@$BRANCH templates against exports in: $installed_dir"
    echo
    curl -fsSL "$API_URL" | python3 -c '
import json, sys, os, glob, urllib.request, difflib

github_items = [i for i in json.load(sys.stdin) if i["type"] == "file" and i["name"].endswith(".json")]
installed_dir = sys.argv[1]

def load(path_or_url, is_url):
    data = urllib.request.urlopen(path_or_url).read() if is_url else open(path_or_url, "rb").read()
    return json.loads(data)

github_by_name = {}
for item in github_items:
    tpl = load(item["download_url"], True)
    github_by_name[tpl.get("name", item["name"])] = tpl

installed_by_name = {}
for path in glob.glob(os.path.join(installed_dir, "*.json")):
    try:
        tpl = load(path, False)
    except (json.JSONDecodeError, OSError):
        continue
    if "name" in tpl:
        installed_by_name[tpl["name"]] = tpl

same, differs, not_exported, extra = [], [], [], []
for name, gh_tpl in sorted(github_by_name.items()):
    if name not in installed_by_name:
        not_exported.append(name)
    elif gh_tpl == installed_by_name[name]:
        same.append(name)
    else:
        differs.append(name)
for name in sorted(set(installed_by_name) - set(github_by_name)):
    extra.append(name)

for name in same:
    print(f"  = up to date:   {name}")
for name in not_exported:
    print(f"  ? not exported: {name}  (export it from the browser to verify)")
for name in extra:
    print(f"  + local only:   {name}  (not tracked in the repo)")
for name in differs:
    print(f"  ! DIFFERS:      {name}  (installed copy != GitHub - do NOT delete+reimport without reviewing)")

if differs:
    print()
    print("--- diffs (installed vs. github) ---")
    for name in differs:
        a = json.dumps(installed_by_name[name], indent=2, sort_keys=True).splitlines(keepends=True)
        b = json.dumps(github_by_name[name], indent=2, sort_keys=True).splitlines(keepends=True)
        print(f"\n### {name}")
        sys.stdout.writelines(difflib.unified_diff(a, b, fromfile="installed", tofile="github"))
        print()

print()
print(f"{len(same)} up to date, {len(differs)} differ, {len(not_exported)} not exported, {len(extra)} local-only")
' "$installed_dir"
    exit 0
fi

DEST="${1:-$HOME/obsidian-web-clipper-templates}"

mkdir -p "$DEST"

echo "Fetching latest templates from github.com/$REPO@$BRANCH..."
api_url="$API_URL"

files=$(curl -fsSL "$api_url" | python3 -c '
import json, sys
for item in json.load(sys.stdin):
    if item["type"] == "file" and item["name"].endswith(".json"):
        print(item["name"] + "\t" + item["download_url"])
')

new=0 updated=0 unchanged=0
while IFS=$'\t' read -r name url; do
    dest_file="$DEST/$name"
    tmp_file=$(mktemp)
    curl -fsSL "$url" -o "$tmp_file"
    if [[ ! -f "$dest_file" ]]; then
        mv "$tmp_file" "$dest_file"
        echo "  + new:       $name"
        new=$((new + 1))
    elif ! cmp -s "$tmp_file" "$dest_file"; then
        mv "$tmp_file" "$dest_file"
        echo "  ~ updated:   $name"
        updated=$((updated + 1))
    else
        rm "$tmp_file"
        echo "  = unchanged: $name"
        unchanged=$((unchanged + 1))
    fi
done <<<"$files"

echo
echo "Templates saved to: $DEST"
echo "  $new new, $updated updated, $unchanged unchanged"
echo

echo "Checking for the Obsidian Web Clipper extension (Chromium browsers)..."
browser_dirs=(
    "Google Chrome:$HOME/Library/Application Support/Google/Chrome"
    "Brave:$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
    "Microsoft Edge:$HOME/Library/Application Support/Microsoft Edge"
    "Arc:$HOME/Library/Application Support/Arc/User Data"
    "Vivaldi:$HOME/Library/Application Support/Vivaldi"
)

found_any=0
for entry in "${browser_dirs[@]}"; do
    browser="${entry%%:*}"
    base="${entry#*:}"
    [[ -d "$base" ]] || continue
    while IFS= read -r -d '' ext_dir; do
        profile_dir="$(dirname "$(dirname "$ext_dir")")"
        echo "  found in $browser ($(basename "$profile_dir"))"
        found_any=1
    done < <(find "$base" -maxdepth 4 -type d -path "*/Extensions/$EXT_ID" -print0 2>/dev/null)
done

if [[ "$found_any" -eq 0 ]]; then
    echo "  no Chromium browsers with the extension found on this machine."
fi
echo "  (Firefox/Safari installs aren't checked - import there manually too if you use them.)"

cat <<EOF

Next steps, per browser found above:
  1. Click the Obsidian Web Clipper toolbar icon, then "Settings".
  2. Go to the Templates tab.
  3. Click "Import" and choose a file from: $DEST
     - Import always adds a new template rather than overwriting, so if a
       template with that name already exists, delete the old one first.
     - Not sure if your installed copy has local edits worth keeping? Export
       it first (... menu > Export), then run:
         $0 --verify <folder with exports>
EOF
