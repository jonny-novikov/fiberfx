#!/usr/bin/env python3
"""sweep.py — the voice + shape gate for Mercury markdown.

Exit 0 only when every file passes. Rules:

  * forbidden words (word-boundary, case-insensitive) anywhere, including code
    comments — code comments are visible text;
  * no exclamation marks in prose (outside fenced code blocks);
  * no double-quoted span of 15+ words (copyright-aligned ceiling);
  * Writerside shape: line 1 starts with '# ', line 2 is the show-structure tag.

Usage:  python3 sweep.py FILE [FILE ...]
"""
from __future__ import annotations

import re
import sys

FORBIDDEN = [
    "just", "simply", "obviously", "effortless", "magical", "revolutionary",
    "blazing", "actually", "genuinely", "honestly", "easy", "seamless",
    "powerful", "honest", "honesty",
]
FORBIDDEN_RE = re.compile(r"\b(" + "|".join(FORBIDDEN) + r")\b", re.IGNORECASE)
QUOTE_RE = re.compile(r"\"([^\"]+)\"")
SHOW_STRUCTURE = '<show-structure depth="2"/>'


def sweep_file(path: str) -> list[str]:
    findings: list[str] = []
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    # Writerside shape
    if not lines or not lines[0].startswith("# "):
        findings.append(f"{path}:1 first line must be an H1 ('# Title')")
    if len(lines) < 2 or lines[1].strip() != SHOW_STRUCTURE:
        findings.append(f"{path}:2 second line must be {SHOW_STRUCTURE}")

    in_fence = False
    for n, line in enumerate(lines, start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue

        # forbidden words: everywhere, fenced code included
        for m in FORBIDDEN_RE.finditer(line):
            findings.append(f"{path}:{n} forbidden word '{m.group(0)}' -> {line.strip()[:80]}")

        # exclamation: prose only
        if not in_fence:
            # ignore '!' inside inline-code backticks
            no_code = re.sub(r"`[^`]*`", "", line)
            if "!" in no_code:
                findings.append(f"{path}:{n} exclamation mark in prose")

        # long quotes: prose only
        if not in_fence:
            for q in QUOTE_RE.findall(line):
                if len(q.split()) >= 15:
                    findings.append(f"{path}:{n} quote of {len(q.split())} words (>=15 ceiling)")

    return findings


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: sweep.py FILE [FILE ...]", file=sys.stderr)
        return 2
    all_findings: list[str] = []
    for path in argv:
        all_findings.extend(sweep_file(path))
    if all_findings:
        for f in all_findings:
            print(f)
        print(f"\nsweep FAIL: {len(all_findings)} finding(s) across {len(argv)} file(s)")
        return 1
    print(f"sweep OK: {len(argv)} file(s) clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
