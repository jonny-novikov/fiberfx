#!/usr/bin/env python3
"""
build_page.py — shell-assembler for the "EchoMQ, In Depth" course (/echomq).

A DEV-TIME generator (like cmd/sitemap): it emits committed static HTML; the
served site stays byte-for-byte. Its purpose is token economy — the ~14 KB
byte-identical design-system shell (the <head> CSS, the <header>, the
<footer>, the stamp+reveal scripts) is stored ONCE as fragments, so a page
author writes only the per-page <main> and the per-page interactive <script>,
not the shell, on every page.

The shell fragments were extracted ONCE from two gated donor pages:
  - dive donor : html/echomq/queue/the-lifecycle/claim-and-the-lease.html
  - hub  donor : html/echomq/queue/the-lifecycle/index.html
(hub and dive share every fragment; only <main> differs.)

Fragments (this dir):
  _head.html           <!doctype> … </style></head><body> + skip link.
                       Placeholders: {{title}} (leaf label), {{meta}} (description).
  _header.html         <header class="site">…</header>. Placeholder: {{route_tag}}
                       (generated from the page route — every segment linked but the leaf).
  _foot_queue.html     <footer class="site-foot">…</footer>. Placeholder: {{module_nav}}
                       (the "This module" links; identical within a module).
  _scripts_common.html the stamp-decoder IIFE + the reveal IntersectionObserver
                       (IDENTICAL on every page; stamp id TSK0Nb1VTbfnu4).

Emit order:  _head(title,meta) + _header(route_tag) + <main>…</main>
             + _foot(module_nav) + <script>interactive_js</script> + _scripts_common

Per-page spec (JSON):
  {
    "out":   "html/echomq/queue/<module>/<slug>.html",
    "title": "The operator plane",
    "meta":  "…the <meta description>… (HTML-ready text)",
    "route": "/echomq/queue/<module>/<slug>",
    "module_nav": [ {"label": "Lifecycle controls", "href": "/echomq/queue/lifecycle-controls"},
                    {"label": "Scheduling & recurrence", "href": "/echomq/queue/lifecycle-controls/scheduling-and-recurrence"} ],
    "page_css": "/* OPTIONAL — page-specific interactive CSS injected before </style>. */",
    "main": "docs/echo_mq/course/tool/.work/<slug>.main.html",
    "interactive_js": "docs/echo_mq/course/tool/.work/<slug>.interactive.js"
  }

The shared <head> base carries every common shell class; a page adds only its
interactive-specific rules (e.g. .rng / .viz / .handle) via "page_css" (the
base's unused rules are harmless). Omit page_css when the base suffices.

Commands:
  build  SPEC.json [--gate]   assemble the page → out; --gate runs cms check
  routetag ROUTE              print the generated route-tag span (debug)

Stdlib only. Never runs git. Paths in the spec resolve relative to the repo root.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent                 # …/docs/echo_mq/course/tool
REPO = ROOT.parents[3]                                 # repo root (tool→course→echo_mq→docs→repo)

HEAD = ROOT / "_head.html"
HEADER = ROOT / "_header.html"
FOOT = ROOT / "_foot_queue.html"
SCRIPTS_COMMON = ROOT / "_scripts_common.html"

GATE_FLAGS = [
    "--routes-from", "/echomq=html/echomq",
    "--routes-from", "/redis-patterns=html/redis-patterns",
    "--routes-from", "/elixir=elixir",
    "--routes-from", "/bcs=html/bcs",
    "--require-refs",
]


def _read(p: Path) -> str:
    return p.read_text(encoding="utf-8")


def _resolve(rel: str) -> Path:
    p = Path(rel)
    return p if p.is_absolute() else (REPO / p)


def route_tag(route: str) -> str:
    """Build the segmented clickable route-tag from a served route.

    Every path segment is a link to its cumulative path, except the leaf, which
    is the current marker (<span class="rcur">). Mirrors the donor exactly:
      /echomq/queue/m/leaf  ->  / echomq / queue / m / leaf(rcur)
    """
    segs = [s for s in route.strip("/").split("/") if s]
    out, cum = [], ""
    for i, seg in enumerate(segs):
        cum += "/" + seg
        out.append('<span class="rsep">/</span>')
        if i == len(segs) - 1:
            out.append('<span class="rcur">%s</span>' % seg)
        else:
            out.append('<a href="%s">%s</a>' % (cum, seg))
    return "".join(out)


def module_nav(entries) -> str:
    """The "This module" footer links, 8-space indented to match the donor."""
    return "\n".join('        <a href="%s">%s</a>' % (e["href"], e["label"]) for e in entries)


def assemble(spec: dict) -> str:
    if spec.get("page_css_file"):
        page_css = _read(_resolve(spec["page_css_file"]))
    else:
        page_css = spec.get("page_css", "")
    head = (
        _read(HEAD)
        .replace("{{title}}", spec["title"])
        .replace("{{meta}}", spec["meta"])
        .replace("{{page_css}}", page_css)
    )
    header = _read(HEADER).replace("{{route_tag}}", route_tag(spec["route"]))
    foot = _read(FOOT).replace("{{module_nav}}", module_nav(spec["module_nav"]))
    main_inner = _read(_resolve(spec["main"]))
    interactive = _read(_resolve(spec["interactive_js"]))
    common = _read(SCRIPTS_COMMON)

    parts = [
        head.rstrip("\n"),
        header.rstrip("\n"),
        '<main id="main" class="wrap">',
        main_inner.strip("\n"),
        "</main>",
        foot.rstrip("\n"),
        "<script>",
        interactive.strip("\n"),
        "</script>",
        common.rstrip("\n"),
        "</body>",
        "</html>",
        "",
    ]
    return "\n".join(parts)


def cmd_build(args: argparse.Namespace) -> int:
    spec = json.loads(_read(_resolve(args.spec)))
    out = _resolve(spec["out"])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(assemble(spec), encoding="utf-8")
    print("wrote %s (%d bytes)" % (out, out.stat().st_size))
    if args.gate:
        cmd = ["apps/jonnify-cms/bin/cms", "check"] + GATE_FLAGS + [str(out.relative_to(REPO))]
        print("gate: " + " ".join(cmd))
        r = subprocess.run(cmd, cwd=str(REPO))
        return r.returncode
    return 0


def cmd_routetag(args: argparse.Namespace) -> int:
    print(route_tag(args.route))
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="EchoMQ course shell-assembler")
    sub = ap.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("build", help="assemble a page from a JSON spec")
    b.add_argument("spec", help="path to the per-page JSON spec")
    b.add_argument("--gate", action="store_true", help="run cms check on the output")
    b.set_defaults(func=cmd_build)

    r = sub.add_parser("routetag", help="print the route-tag for a route (debug)")
    r.add_argument("route")
    r.set_defaults(func=cmd_routetag)

    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
