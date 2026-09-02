#!/usr/bin/env bash
# Split the niri config's `layout`, `animations`, `binds`, `input` and
# `output "..."` blocks out into ~/.config/niri/quickshell/<name>.kdl fragments and drop an
# `include` in their place, so Settings > niri can edit them without touching
# the rest of the user's hand-written config.kdl.
#
# Idempotent (safe to re-run), validates the result, and restores a backup
# if niri rejects it. Blocks are moved verbatim — comments, gradients, struts,
# every output line and all — nothing is regenerated or lost.
set -euo pipefail

CONFIG="${NIRI_CONFIG:-$HOME/.config/niri/config.kdl}"
FRAGDIR="$(dirname "$CONFIG")/quickshell"

# name | opener-regex (awk ERE, anchored) | multi(0/1)
SPECS=(
    "layout|^layout[ \t]*[{]|0"
    "animations|^animations[ \t]*[{]|0"
    "binds|^binds[ \t]*[{]|0"
    "input|^input[ \t]*[{]|0"
    "outputs|^output[ \t]+\"[^\"]+\"[ \t]*[{]|1"
)

[ -f "$CONFIG" ] || { echo "no niri config at $CONFIG" >&2; exit 1; }
mkdir -p "$FRAGDIR"

BACKUP="$CONFIG.pre-split.bak"
cp "$CONFIG" "$BACKUP"

changed=0
for spec in "${SPECS[@]}"; do
    IFS='|' read -r name head multi <<< "$spec"

    if grep -Eq "^[[:space:]]*include[[:space:]]+\"quickshell/${name}\.kdl\"" "$CONFIG"; then
        continue
    fi

    if ! grep -Eq "$head" "$CONFIG"; then
        [ -f "$FRAGDIR/$name.kdl" ] || : > "$FRAGDIR/$name.kdl"
        printf '\ninclude "quickshell/%s.kdl"\n' "$name" >> "$CONFIG"
        changed=1
        continue
    fi

    : > "$FRAGDIR/$name.kdl"   # fresh — we only reach here when not yet split
    tmp="$(mktemp)"
    awk -v head="$head" -v frag="$FRAGDIR/$name.kdl" -v name="$name" -v multi="$multi" '
        BEGIN { depth = 0; capturing = 0; emitted = 0 }
        {
            line = $0
            c = line; sub(/\/\/.*/, "", c)          # ignore // comments for brace math
            if (!capturing && (multi == "1" || emitted == 0) && c ~ head) {
                capturing = 1
                print line >> frag
                depth += gsub(/\{/, "{", c) - gsub(/\}/, "}", c)
                if (!emitted) { print "include \"quickshell/" name ".kdl\""; emitted = 1 }
                next
            }
            if (capturing) {
                print line >> frag
                depth += gsub(/\{/, "{", c) - gsub(/\}/, "}", c)
                if (depth <= 0) capturing = 0
                next
            }
            print line
        }
    ' "$CONFIG" > "$tmp"
    mv "$tmp" "$CONFIG"
    changed=1
done

if [ "$changed" = 0 ]; then
    echo "already split"
    rm -f "$BACKUP"
    exit 0
fi

if niri validate -c "$CONFIG" >/dev/null 2>&1; then
    echo "split ok"
    niri msg action load-config-file >/dev/null 2>&1 || true
    exit 0
fi

echo "niri rejected the split — restoring backup" >&2
cp "$BACKUP" "$CONFIG"
exit 1
