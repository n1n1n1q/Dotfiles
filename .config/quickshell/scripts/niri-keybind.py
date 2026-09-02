#!/usr/bin/env python3
"""Surgically edit one keybind inside the niri `binds` fragment written by
niri-split.sh, preserving every other line (comments, props, order).

Every bind in the fragment is a single line:

    <indent><CHORD> [props...] { <action>; }

A bind is identified by its CHORD (niri requires chords to be unique), matched
as the first whitespace-delimited token of the line. A bind this tool has
*disabled* keeps its line but with a `//! ` marker after the indent, so niri
ignores it while the page can still list it:

    <indent>//! <CHORD> [props...] { <action>; }

Usage:
  niri-keybind.py <binds.kdl> rechord  <old-chord> <new-chord>
  niri-keybind.py <binds.kdl> action   <chord>     <action-body>
  niri-keybind.py <binds.kdl> add      <chord>     <action-body>  [overlay-title]
  niri-keybind.py <binds.kdl> remove   <chord>
  niri-keybind.py <binds.kdl> disable  <chord>
  niri-keybind.py <binds.kdl> enable   <chord>

`action-body` is the text that goes inside the braces, e.g.
  spawn "kitty"        ·  focus-column-left        ·  set-column-width "+10%"

Exit 0 = changed and written, 2 = no change needed, 1 = error.
"""
import re
import sys

MARK = "//! "
LINE_RE = re.compile(
    r'^(?P<indent>\s*)(?P<mark>//!\s*)?(?P<chord>[A-Za-z0-9_+]+)'
    r'(?P<props>(?:\s+[^\s{]+)*)\s*\{\s*(?P<action>.*?)\s*;?\s*\}\s*$'
)


def parse(line):
    """(match, disabled) for a bind line (active or //!-disabled), else (None, False)."""
    m = LINE_RE.match(line)
    if not m:
        return None, False
    return m, bool(m.group('mark'))


def find(lines, chord, want=None):
    """Index of the bind whose chord == chord. want: True=disabled only,
    False=active only, None=either."""
    for i, line in enumerate(lines):
        m, dis = parse(line)
        if m and m.group('chord') == chord:
            if want is None or dis == want:
                return i
    return -1


def compose(m, chord=None, action=None, disabled=None):
    ind = m.group('indent')
    mark = MARK if (m.group('mark') if disabled is None else disabled) else ""
    ch = chord if chord is not None else m.group('chord')
    props = m.group('props')
    act = (action if action is not None else m.group('action')).strip().rstrip(';')
    return f"{ind}{mark}{ch}{props} {{ {act}; }}\n"


def closer(lines):
    for i in range(len(lines) - 1, -1, -1):
        if re.sub(r'//.*', '', lines[i]).strip() == '}':
            return i
    return len(lines)


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    path, op = sys.argv[1], sys.argv[2]
    with open(path) as f:
        lines = f.readlines()
    before = list(lines)

    if op == 'rechord':
        old, new = sys.argv[3], sys.argv[4]
        if new != old and find(lines, new) != -1:
            sys.exit(f"chord {new} is already bound")
        i = find(lines, old)
        if i == -1:
            sys.exit(f"no bind for {old}")
        lines[i] = compose(parse(lines[i])[0], chord=new)

    elif op == 'action':
        chord, body = sys.argv[3], sys.argv[4]
        i = find(lines, chord)
        if i == -1:
            sys.exit(f"no bind for {chord}")
        lines[i] = compose(parse(lines[i])[0], action=body)

    elif op == 'add':
        chord, body = sys.argv[3], sys.argv[4]
        title = sys.argv[5] if len(sys.argv) > 5 else ""
        if find(lines, chord) != -1:
            sys.exit(2)
        body = body.strip().rstrip(';')
        props = f' hotkey-overlay-title="{title}"' if title else ""
        at = closer(lines)
        indent = re.match(r'\s*', lines[at]).group(0) + '    ' if at < len(lines) else '    '
        lines.insert(at, f"{indent}{chord}{props} {{ {body}; }}\n")

    elif op == 'remove':
        i = find(lines, sys.argv[3])
        if i == -1:
            sys.exit(2)
        del lines[i]

    elif op == 'disable':
        i = find(lines, sys.argv[3], want=False)
        if i == -1:
            sys.exit(2)
        lines[i] = compose(parse(lines[i])[0], disabled=True)

    elif op == 'enable':
        i = find(lines, sys.argv[3], want=True)
        if i == -1:
            sys.exit(2)
        lines[i] = compose(parse(lines[i])[0], disabled=False)

    else:
        sys.exit(f"unknown op {op}")

    if lines == before:
        sys.exit(2)
    with open(path, 'w') as f:
        f.writelines(lines)


if __name__ == '__main__':
    main()
