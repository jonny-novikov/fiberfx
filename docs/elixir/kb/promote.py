#!/usr/bin/env python3
"""promote.py — auto-promote built-but-planned Elixir course modules.

Detects modules whose page exists on disk but are still status="planned" in the
manifest, then:
  * flips them to "built" in build_page.py AND the Go cms manifest,
  * registers their deep-dive subpages discovered on disk (slug from the filename,
    title from each page's <title>, one-liner from its <meta description>),
  * re-syncs the contents page (sync_contents.py).

This is the deterministic half of "process new pages as they arrive": no AI, no
guessing — the filesystem and the page <title>s are the source of truth. The Go
manifest still needs `go build` afterwards (use --rebuild, or `make promote`).

    python3 promote.py            # promote all drift
    python3 promote.py --dry-run  # report only
    python3 promote.py --rebuild  # promote, then rebuild the cms binary
"""
import html
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_page as bp  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
ELIXIR = os.path.join(ROOT, "elixir")
BUILD_PY = os.path.join(HERE, "build_page.py")
MANIFEST_GO = os.path.join(ROOT, "apps", "jonnify-cms", "internal", "manifest", "manifest.go")
CMS_DIR = os.path.join(ROOT, "apps", "jonnify-cms")
DRY = "--dry-run" in sys.argv
REBUILD = "--rebuild" in sys.argv


def rel_dir(route):
    return route[len("/elixir"):].strip("/")


def route_resolves(route):
    d = os.path.join(ELIXIR, rel_dir(route))
    if os.path.isdir(d):
        return os.path.isfile(os.path.join(d, "index.html"))
    return os.path.isfile(d + ".html")


def page_field(path, pattern, group=1):
    try:
        t = open(path, encoding="utf-8").read()
    except OSError:
        return ""
    m = re.search(pattern, t, re.S)
    return html.unescape(m.group(group)).strip() if m else ""


def subpage_title(path):
    t = page_field(path, r"<title>(.*?)</title>")
    return re.split(r"\s*[—·]\s*", t)[0].strip() if t else ""


def subpage_one(path):
    d = page_field(path, r'<meta name="description" content="([^"]*)"')
    return re.split(r"(?<=[.;])\s", d)[0][:96] if d else ""


def discover_subpages(route, slug):
    """A hub's subpages = the non-index .html files in its directory."""
    d = os.path.join(ELIXIR, rel_dir(route), slug)
    if not os.path.isdir(d):
        return []
    out = []
    for name in sorted(os.listdir(d)):
        if name.endswith(".html") and name != "index.html":
            p = os.path.join(d, name)
            out.append((name[:-5], subpage_title(p) or name[:-5], subpage_one(p)))
    return out


def merged_subpages(ch, m):
    """Subpages as a filesystem projection that does NOT churn order: keep the DECLARED
    order and hand-written titles/one-liners, drop any whose file vanished, and append
    newly-discovered subpages at the end."""
    fs = discover_subpages(ch["route"], m["slug"])
    on_disk = {slug for (slug, _, _) in fs}
    declared = [(s["slug"], s["title"], s["one"]) for s in bp.SUBPAGES.get(m["n"], [])]
    declared_slugs = {d[0] for d in declared}
    result = [d for d in declared if d[0] in on_disk]
    result += [(s, t, o) for (s, t, o) in fs if s not in declared_slugs]
    return result


def detect_drift():
    """Returns (module_promotions, subpage_updates).
    module_promotions: planned modules whose page now exists -> flip to built.
    subpage_updates: built hubs whose on-disk subpages differ from the manifest."""
    promotions, sub_updates = [], []
    for ch in bp.CHAPTERS:
        for m in bp.MODULES[ch["id"]]:
            route = f'{ch["route"]}/{m["slug"]}'
            if m["status"] == "planned":
                if route_resolves(route):
                    promotions.append((ch, m, merged_subpages(ch, m)))
            elif m["status"] in ("built", "live"):
                merged = merged_subpages(ch, m)
                declared = [(s["slug"], s["title"], s["one"]) for s in bp.SUBPAGES.get(m["n"], [])]
                if merged and merged != declared:
                    sub_updates.append((ch, m, merged))
    return promotions, sub_updates


def insert_before_matching_close(text, open_marker, entry):
    """Insert `entry` just before the brace that closes the block opened at open_marker."""
    i = text.index(open_marker)
    j = text.index("{", i)
    depth = 0
    for k in range(j, len(text)):
        if text[k] == "{":
            depth += 1
        elif text[k] == "}":
            depth -= 1
            if depth == 0:
                return text[:k] + entry + text[k:]
    raise ValueError("unbalanced braces after " + open_marker)


def py_subpages_entry(mid, subs):
    lines = [f'    "{mid}": [']
    for s, t, o in subs:
        lines.append(f'        dict(slug={s!r}, title={t!r}, one={o!r}),')
    lines.append("    ],\n")
    return "\n".join(lines)


def go_subpages_entry(mid, subs):
    lines = [f'\t"{mid}": {{']
    for s, t, o in subs:
        lines.append(f'\t\t{{{go_str(s)}, {go_str(t)}, {go_str(o)}}},')
    lines.append("\t},\n")
    return "\n".join(lines)


def go_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def upsert_subpages(py, go, mid, subs):
    """Replace an existing SUBPAGES["mid"] block, or insert it if absent."""
    py_entry, go_entry = py_subpages_entry(mid, subs), go_subpages_entry(mid, subs)
    py_pat = re.compile(r'    "' + re.escape(mid) + r'": \[.*?\],\n', re.S)
    py = py_pat.sub(lambda _: py_entry, py, count=1) if py_pat.search(py) \
        else insert_before_matching_close(py, "SUBPAGES = {", py_entry)
    go_pat = re.compile(r'\t"' + re.escape(mid) + r'": \{.*?\t\},\n', re.S)
    go = go_pat.sub(lambda _: go_entry, go, count=1) if go_pat.search(go) \
        else insert_before_matching_close(go, "var Subpages = map[string][]Subpage{", go_entry)
    return py, go


def main():
    promotions, sub_updates = detect_drift()
    if not promotions and not sub_updates:
        print("no drift: every built module + subpage is declared")
        return 0

    for ch, m, subs in promotions:
        extra = f"  +{len(subs)} subpages: {', '.join(s[0] for s in subs)}" if subs else ""
        print(f"  promote   {m['n']} {ch['route']}/{m['slug']}{extra}")
    for ch, m, subs in sub_updates:
        print(f"  subpages  {m['n']} {ch['route']}/{m['slug']} -> {', '.join(s[0] for s in subs)}")
    if DRY:
        return 0

    py = open(BUILD_PY, encoding="utf-8").read()
    go = open(MANIFEST_GO, encoding="utf-8").read()
    for ch, m, subs in promotions:
        slug = m["slug"]
        py = py.replace(f'slug="{slug}", status="planned"', f'slug="{slug}", status="built"')
        go = go.replace(f'Slug: "{slug}", Status: "planned"', f'Slug: "{slug}", Status: "built"')
        if subs:
            py, go = upsert_subpages(py, go, m["n"], subs)
    for ch, m, subs in sub_updates:
        py, go = upsert_subpages(py, go, m["n"], subs)
    open(BUILD_PY, "w", encoding="utf-8").write(py)
    open(MANIFEST_GO, "w", encoding="utf-8").write(go)
    print(f"applied: {len(promotions)} promotion(s), {len(sub_updates)} subpage-sync(s)")

    subprocess.run([sys.executable, os.path.join(HERE, "sync_contents.py")], check=False)

    if REBUILD:
        r = subprocess.run(["go", "build", "-o", "bin/cms", "."], cwd=CMS_DIR,
                           env={**os.environ, "GOWORK": "off"})
        print("cms rebuilt" if r.returncode == 0 else "cms rebuild FAILED")
    else:
        print("next: rebuild cms  (cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
