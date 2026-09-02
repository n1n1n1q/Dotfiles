#!/usr/bin/env python3
"""Surgically set one value inside a niri config fragment written by
niri-split.sh, preserving everything else (comments, gradients, order).

Usage: niri-set.py <fragment.kdl> <key> <value>

layout.kdl / animations.kdl keys:
  gaps                 <int>
  focus-ring.width     <int>          `width N` inside the focus-ring block
  focus-ring.enabled   0|1            add / remove `off` inside focus-ring
  border.width         <int>
  border.enabled       0|1
  animations.enabled   0|1            top-level `off`
  animations.slowdown  <float>        <=0 or 1 removes the line

outputs.kdl keys (NAME is the connector, e.g. eDP-1):
  output.NAME.mode       "WxH@R" | ""     `mode "..."` ("" removes)
  output.NAME.scale      <float>
  output.NAME.transform  normal|90|...    `transform "..."`
  output.NAME.enabled    0|1              bare `off`
  output.NAME.vrr        0|1|ondemand     `variable-refresh-rate [on-demand=true]`
  output.NAME.position   "X,Y" | ""       `position x=X y=Y` ("" removes)

input.kdl keys:
  input.focus-follows-mouse    0|1        bare flag inside `input`
  input.warp-mouse-to-focus    0|1        bare flag inside `input`
  input.touchpad.tap           0|1        bare flag inside `input > touchpad`
  input.touchpad.natural-scroll 0|1
  input.touchpad.dwt           0|1        disable-while-typing
  input.touchpad.accel-speed   <float> | ""   `accel-speed N` ("" removes)
  input.mouse.natural-scroll   0|1
  input.mouse.accel-speed      <float> | ""
  input.keyboard.repeat-delay  <int>
  input.keyboard.repeat-rate   <int>

Exit 0 = changed and written, 2 = no change needed, 1 = error.
"""
import re
import sys


def indent_of(line):
    return line[: len(line) - len(line.lstrip())]


def strip_comment(line):
    return re.sub(r"//.*", "", line)


def find_block(lines, opener_re, lo=0, hi=None):
    """(start, end, body_indent) for a `<opener> {` ... matching `}` — or None.

    `opener_re` matches the opening line (comment-stripped), sans the brace.
    `lo`/`hi` bound the search (for a nested block: pass the parent region).
    """
    if hi is None:
        hi = len(lines)
    depth = 0
    start = None
    pat = re.compile(rf"^\s*{opener_re}\s*\{{")
    for i in range(lo, hi):
        line = lines[i]
        c = strip_comment(line)
        if start is None:
            if pat.match(c):
                start = i
                depth = c.count("{") - c.count("}")
                if depth <= 0:
                    return start, i, indent_of(line) + "    "
            continue
        depth += c.count("{") - c.count("}")
        if depth <= 0:
            return start, i, indent_of(lines[start]) + "    "
    return None


def ensure_subblock(lines, parent, name):
    """Return the region for `name { ... }` inside `parent`, creating an empty
    one right after the parent's opening brace if it isn't there yet."""
    inner = find_block(lines, re.escape(name), parent[0] + 1, parent[1])
    if inner:
        return inner
    bi = parent[2]
    lines.insert(parent[0] + 1, f"{bi}{name} {{\n")
    lines.insert(parent[0] + 2, f"{bi}}}\n")
    return parent[0] + 1, parent[0] + 2, bi + "    "


def set_line(lines, region, key_re, newline):
    """Replace the first line inside region matching key_re with `newline`
    (already terminated), or insert it after the opening brace. newline=None
    removes every matching line."""
    start, end, bi = region
    pat = re.compile(rf"^(\s*)(//\s*)?{key_re}\b.*$")
    hits = [i for i in range(start + 1, end) if pat.match(lines[i])]
    if newline is None:
        for i in reversed(hits):
            del lines[i]
        return bool(hits)
    if hits:
        i = hits[0]
        want = re.sub(r"^\s*", indent_of(lines[i]) or bi, newline, count=1)
        for j in reversed(hits[1:]):
            del lines[j]
        if lines[i] == want:
            return len(hits) > 1
        lines[i] = want
        return True
    lines.insert(start + 1, re.sub(r"^\s*", bi, newline, count=1))
    return True


def set_flag(lines, region, token, present):
    start, end, bi = region
    kill = [i for i in range(start + 1, end)
            if re.match(rf"^\s*(//\s*)?{re.escape(token)}\s*$", lines[i])]
    live = [i for i in kill if strip_comment(lines[i]).strip() == token]
    if present and not live:
        for i in reversed(kill):
            del lines[i]
        lines.insert(start + 1, f"{bi}{token}\n")
        return True
    if not present and live:
        for i in reversed(live):
            del lines[i]
        return True
    return False


def do_output(lines, name, attr, value):
    blk = find_block(lines, rf'output\s+"{re.escape(name)}"')
    if not blk:
        sys.exit(f"no output block for {name}")
    if attr == "mode":
        set_line(lines, blk, "mode", None if not value else f'mode "{value}"\n')
    elif attr == "scale":
        set_line(lines, blk, "scale", f"scale {value}\n")
    elif attr == "transform":
        set_line(lines, blk, "transform", f'transform "{value}"\n')
    elif attr == "enabled":
        set_flag(lines, blk, "off", str(value) in ("0", "false", "off"))
    elif attr == "position":
        if not value:
            set_line(lines, blk, "position", None)
        else:
            x, y = value.replace(" ", "").split(",")
            set_line(lines, blk, "position", f"position x={int(x)} y={int(y)}\n")
    elif attr == "vrr":
        if str(value) in ("0", "false", "off"):
            set_line(lines, blk, "variable-refresh-rate", None)
        elif str(value) in ("ondemand", "on-demand"):
            set_line(lines, blk, "variable-refresh-rate",
                     "variable-refresh-rate on-demand=true\n")
        else:
            set_line(lines, blk, "variable-refresh-rate",
                     "variable-refresh-rate\n")
    else:
        sys.exit(f"unknown output attr {attr}")


def _is_off(value):
    return str(value) in ("0", "false", "off")


def do_input(lines, key, value):
    root = find_block(lines, "input") or sys.exit("no input block")
    parts = key.split(".")

    if len(parts) == 2:                       # input.<flag> at the top level
        flag = parts[1]
        set_flag(lines, root, flag, not _is_off(value))
        return

    _, sub, attr = parts                      # input.<sub>.<attr>
    blk = ensure_subblock(lines, root, sub)
    if attr in ("tap", "natural-scroll", "dwt", "dwtp", "middle-emulation",
               "left-handed", "disabled-on-external-mouse"):
        set_flag(lines, blk, attr, not _is_off(value))
    elif attr == "accel-speed":
        set_line(lines, blk, "accel-speed",
                 None if value == "" else f"accel-speed {float(value):.2f}\n")
    elif attr in ("repeat-delay", "repeat-rate", "scroll-button"):
        set_line(lines, blk, attr, f"{attr} {int(value)}\n")
    elif attr in ("accel-profile", "click-method", "scroll-method",
                  "tap-button-map"):
        set_line(lines, blk, attr,
                 None if value == "" else f'{attr} "{value}"\n')
    else:
        sys.exit(f"unknown input attr {attr}")


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(path) as f:
        lines = f.readlines()
    before = list(lines)

    if key.startswith("output."):
        _, name, attr = key.split(".", 2)
        do_output(lines, name, attr, value)
    elif key.startswith("input."):
        do_input(lines, key, value)
    elif key == "gaps":
        blk = find_block(lines, "layout") or sys.exit("no layout block")
        set_line(lines, blk, "gaps", f"gaps {int(value)}\n")
    elif key in ("focus-ring.width", "border.width"):
        sub = key.split(".")[0]
        blk = find_block(lines, sub) or sys.exit(f"no {sub} block")
        set_line(lines, blk, "width", f"width {int(value)}\n")
    elif key in ("focus-ring.enabled", "border.enabled"):
        sub = key.split(".")[0]
        blk = find_block(lines, sub) or sys.exit(f"no {sub} block")
        set_flag(lines, blk, "off", str(value) in ("0", "false", "off"))
    elif key == "animations.enabled":
        blk = find_block(lines, "animations") or sys.exit("no animations block")
        set_flag(lines, blk, "off", str(value) in ("0", "false", "off"))
    elif key == "animations.slowdown":
        blk = find_block(lines, "animations") or sys.exit("no animations block")
        start, end, bi = blk
        for i in range(end - 1, start, -1):
            if re.match(r"^\s*(//\s*)?slowdown\b", lines[i]):
                del lines[i]
        try:
            v = float(value)
        except ValueError:
            v = 0.0
        if v > 0 and abs(v - 1.0) > 1e-6:
            lines.insert(start + 1, f"{bi}slowdown {value}\n")
    else:
        sys.exit(f"unknown key {key}")

    if lines == before:
        sys.exit(2)
    with open(path, "w") as f:
        f.writelines(lines)


if __name__ == "__main__":
    main()
