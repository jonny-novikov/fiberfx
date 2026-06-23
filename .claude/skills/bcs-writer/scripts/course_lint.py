#!/usr/bin/env python3
"""course_lint.py — the BCS course gate. Exit 0 is the only shippable state.

Checks each rendered course page for the rules calibrated into this skill:

  slug        internal links are slug routes (/bcs/ideas/identity-contract),
              never bcs.N.M or numeric-segment forms.
  svg         exactly one mandatory interactive figure (.anat + data-seg + readout).
  gate-dump   no meaningless gate blocks (PASS n/n; "G1 ... ok" ladders).
  doors       the /echo-persistence door is present; /elixir is absent.
  grounding   no number rides a bench that has no committed .out. The known-thin
              benches are banned outright; any bench/ or *.out path cited in a
              caption must resolve under --repo. (A figure that exists may cite it.)
  balance     section/figure/svg/footer/main/header tags balance.

Usage:  python3 course_lint.py page1.html [page2.html ...] [--repo /path/to/repo]
"""
import sys, os, re

THIN_BENCHES = ["branding-vs-decimal", "valkey-id"]   # no committed .out in tree
BENCH_TOKENS = ["ns/op", "bytes/key", "bytes/entry"]   # benchmark-number tells


def lint(path, repo=None):
    d = open(path, encoding="utf-8").read()
    P = []

    # --- slug routes only ---
    for href in re.findall(r'href="(/bcs[^"]*)"', d):
        if re.search(r'/bcs\.\d', href) or re.search(r'bcs\.\d+(\.\d+)*', href) \
           or re.search(r'/bcs(/[a-z0-9-]+)*/\d', href):
            P.append(f"non-slug link: {href}")
    if re.search(r'\bbcs\.\d+(\.\d+)*\.html\b', d):
        P.append("bcs.N.M.html link form present (use slug routes)")

    # --- one interactive figure ---
    if d.count('class="anat" id="anat"') != 1:
        P.append(f'expected exactly one interactive .anat figure, found {d.count(chr(34)+"anat"+chr(34))}')
    if d.count("data-seg=") < 2:
        P.append("interactive figure has fewer than 2 segments")
    if 'id="readout"' not in d:
        P.append("interactive figure has no #readout")

    # --- no gate dumps ---
    if re.search(r'PASS\s+\d+\s*/\s*\d+', d):
        P.append("gate-dump: 'PASS n/n' present")
    if re.search(r'(?m)^\s*G[1-9]\b.{0,60}\bok\b', d):
        P.append("gate-dump: 'G# ... ok' ladder present")

    # --- doors ---
    if "/echo-persistence" not in d:
        P.append("missing /echo-persistence door")
    if "/elixir" in d:
        P.append("retired /elixir link present")

    # --- grounding: no thin benches, cited bench/.out paths must resolve ---
    for b in THIN_BENCHES:
        if b in d:
            ok = repo and os.path.isdir(os.path.join(repo, "docs/echo/bcs/content/bench", b))
            if not ok:
                P.append(f"grounding: cites thin bench '{b}' (no committed .out in tree)")
    for tok in BENCH_TOKENS:
        if tok in d:
            P.append(f"grounding: benchmark token '{tok}' present without a resolvable committed .out")
    if repo:
        for m in re.findall(r'(bench/[\w/.-]+|[\w/.-]+\.out)\b', d):
            cand = os.path.join(repo, "docs/echo/bcs/content", m)
            cand2 = os.path.join(repo, m)
            if not (os.path.exists(cand) or os.path.exists(cand2)):
                P.append(f"grounding: cited path does not resolve: {m}")

    # --- tag balance ---
    for t in ["section", "figure", "svg", "footer", "main", "header"]:
        o = len(re.findall(r'<%s[ >]' % t, d))
        c = d.count('</%s>' % t)
        if o != c:
            P.append(f"tag imbalance <{t}>: {o} open / {c} close")

    return P


def main(argv):
    repo = None
    files = []
    i = 0
    while i < len(argv):
        if argv[i] == "--repo":
            repo = argv[i + 1]; i += 2
        else:
            files.append(argv[i]); i += 1
    fail = 0
    for f in files:
        probs = lint(f, repo)
        if probs:
            fail += 1
            print(f"LINT FAIL  {os.path.basename(f)}")
            for p in probs:
                print("   -", p)
        else:
            print(f"LINT PASS  {os.path.basename(f)}  (slug · svg · no-dump · doors · grounding · balance)")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
