#!/usr/bin/env python3
"""
build_page.py - robust builder + validator + structure authority for jonnify
                "Functional Programming in Elixir" pages.

Why this exists
---------------
Page generation used to be ad-hoc heredocs. Small structure bugs slipped through
and were caught only by eye:

  * an unclosed `<div class="wrap">` inside a <section>;
  * a broken trailing <script>;
  * a stray /future link;
  * and - the worst class - a Python template that NEVER EXPANDED and shipped as
    literal text into the HTML, e.g. the hero SVG that contained:

        <g ...>""" + ''.join(f'<line ... y1="{y}" ...' for y in range(90,331,40)) + """</g>

    That artifact rendered as garbage and validated as "fine" because the div/svg
    counts still balanced.

This script makes the build a single command with fail-loud validation, owns the
canonical course structure (so the chapter map is single-sourced, not copy-pasted
into every page), and provides safe SVG emitters so authors never hand-write a
Python f-string into a heredoc again.

Pipeline
  extract-head SRC.html HEAD.html          pull the shared <head> (design system)
  build  --head H --body B --out O ...      assemble + VALIDATE + write + report
  validate FILE.html                        run validation on an already-built file
  manifest [--json]                         print + VALIDATE the course structure
  routes  [--status S]                      dump the canonical route table
  svg-grid  --y0 .. --y1 .. --step ..       emit <line> grid rows (no f-string leaks)
  svg-stations --n .. ...                    emit ascending station markers + labels

Validation (each reported individually)
  - template leak           <- catches un-expanded Python (the bug above)
  - <div> balance (global)
  - per-<section> div depth <- catches the classic leaked `<div class="wrap">`
  - <svg> balance
  - links to /future        <- course-internal integrity (0 unless --allow-future)
  - reveal-on-scroll JS present (IntersectionObserver)
  - stray antml tags
  - JS syntax of the trailing <script> via `node --check`

`build` always writes the file (so you can render/inspect) but prints
STATUS: OK or STATUS: FAIL <issues>. Treat any FAIL as a stop. Exit code is
non-zero on FAIL so it composes in a Makefile / CI.
"""
import argparse, json, os, re, subprocess, sys, tempfile

HEAD_END = "</head>"

# ──────────────────────────────────────────────────────────────────────────────
# Canonical course structure. The pages render FROM this idea; this is the
# single source of truth for "how many chapters / modules / labs" and for routes.
# 9 chapters (F0 orientation + F1..F8 learning). F1 carries 3 expert dives.
# status: live | built | soon
# ──────────────────────────────────────────────────────────────────────────────
BASE = "/elixir"
CHAPTERS = [
    {"id": "F0", "slug": "course", "name": "The Course", "tint": "--gold-bright",
     "tag": "orientation", "modules": [
        ("F0.0", "course", "Course contents & how to read it", "live", False, False),
     ]},
    {"id": "F1", "slug": "algebra", "name": "Algebra", "tint": "--gold-bright",
     "tag": "the on-ramp", "modules": [
        ("F1.01", "functions",    "What a function really is",            "built", False, False),
        ("F1.02", "substitution", "The substitution model",               "built", False, False),
        ("F1.03", "composition",  "Composition, f\u2218g",                "soon",  False, False),
        ("F1.04", "immutability", "Immutability & binding",               "soon",  False, False),
        ("F1.05", "mappings",     "Sets, sequences & mappings",           "soon",  False, False),
        ("F1.06", "recursion",    "Recursion & induction",                "soon",  False, False),
        ("F1.07", "operators",    "Higher-order operators (\u03a3, \u03a0)", "soon", False, False),
        ("F1.08", "equations",    "Equations & pattern matching",         "soon",  False, False),
        ("F1.09", "plotting-lab", "Functions on the plane \u2014 a plotting lab", "soon", True, False),
        # ── expert dives (F1.0.*) ──
        ("F1.0.1", "lambda-calculus", "Lambda calculus & \u03b2-reduction", "soon", False, True),
        ("F1.0.2", "monoids",         "Monoids, semigroups & identity",     "soon", False, True),
        ("F1.0.3", "functors",        "Functors & the shape of map",        "soon", False, True),
     ]},
    {"id": "F2", "slug": "functional", "name": "Functional Programming", "tint": "--sage-bright",
     "tag": "algebra, made executable", "modules": [
        ("F2.01", "pure-functions", "Pure functions & side effects",   "soon", False, False),
        ("F2.02", "immutability",   "Immutability & persistent data",  "soon", False, False),
        ("F2.03", "higher-order",   "Higher-order functions",          "soon", False, False),
        ("F2.04", "recursion",      "Recursion patterns & tail calls", "soon", False, False),
        ("F2.05", "folds",          "map / filter / reduce (folds)",   "soon", False, False),
        ("F2.06", "closures",       "Closures & partial application",  "soon", False, False),
        ("F2.07", "adts",           "Algebraic data types",            "soon", False, False),
        ("F2.08", "pipelines",      "Composition & pipelines",         "soon", False, False),
        ("F2.09", "pipeline-lab",   "The data-pipeline lab",           "soon", True,  False),
     ]},
    {"id": "F3", "slug": "language", "name": "The Elixir Language", "tint": "--blue-bright",
     "tag": "syntax on the BEAM", "modules": [
        ("F3.01", "values",    "Values, types & IEx",                    "soon", False, False),
        ("F3.02", "match",     "Pattern matching & the match operator",  "soon", False, False),
        ("F3.03", "modules",   "Functions, modules & the pipe |>",       "soon", False, False),
        ("F3.04", "enum",      "Enumerables & streams",                  "soon", False, False),
        ("F3.05", "structs",   "Structs, maps & keyword lists",          "soon", False, False),
        ("F3.06", "protocols", "Protocols & behaviours",                 "soon", False, False),
        ("F3.07", "processes", "Processes & the actor model",            "soon", False, False),
        ("F3.08", "otp",       "OTP: GenServer & supervisors",           "soon", False, False),
        ("F3.09", "process-playground", "The process playground \u2014 messages, live", "soon", True, False),
     ]},
    {"id": "F4", "slug": "algorithms", "name": "Algorithms & Data Structures", "tint": "--elixir",
     "tag": "computer science, immutably", "modules": [
        ("F4.01", "lists",        "Lists, recursion & complexity",          "soon", False, False),
        ("F4.02", "trees",        "Trees & traversals",                     "soon", False, False),
        ("F4.03", "sorting",      "Sorting & searching",                    "soon", False, False),
        ("F4.04", "hashing",      "Maps, sets & hashing",                   "soon", False, False),
        ("F4.05", "hamt",         "Hash Array Mapped Tries (HAMT)",         "soon", False, False),
        ("F4.06", "champ",        "CHAMP maps",                             "soon", False, False),
        ("F4.07", "branded-champ","Branded CHAMP maps",                     "soon", False, False),
        ("F4.08", "dynamic",      "Dynamic programming & advanced problems","soon", False, False),
        ("F4.09", "champ-lab",    "Watch a Branded CHAMP map grow",         "soon", True,  False),
     ]},
    {"id": "F5", "slug": "concurrency", "name": "Concurrency & the Actor Model", "tint": "--sage",
     "tag": "processes as design", "modules": [
        ("F5.01", "actor-model",     "The actor model & process isolation", "soon", False, False),
        ("F5.02", "message-passing", "spawn, send, receive",                "soon", False, False),
        ("F5.03", "genserver",       "GenServer in depth",                  "soon", False, False),
        ("F5.04", "supervisors",     "Supervisors & restart strategies",    "soon", False, False),
        ("F5.05", "registry",        "Registry & dynamic supervision",      "soon", False, False),
        ("F5.06", "tasks",           "Task, async & await",                 "soon", False, False),
        ("F5.07", "genstage",        "GenStage & Flow (back-pressure)",     "soon", False, False),
        ("F5.08", "scheduler",       "The scheduler & reductions",          "soon", False, False),
        ("F5.09", "mailbox-lab",     "Back-pressure, live \u2014 the mailbox under load", "soon", True, False),
     ]},
    {"id": "F6", "slug": "distributed", "name": "Distributed & Real-Time Systems", "tint": "--blue",
     "tag": "many nodes, one system", "modules": [
        ("F6.01", "distributed-erlang", "Distributed Erlang & the cluster",          "soon", False, False),
        ("F6.02", "process-groups",     "Global naming & process groups (:pg)",      "soon", False, False),
        ("F6.03", "pubsub",             "Phoenix.PubSub & broadcast",                "soon", False, False),
        ("F6.04", "queues",             "Message queues & back-pressure across services", "soon", False, False),
        ("F6.05", "failure-modes",      "Netsplits, partitions & the CAP trade-off", "soon", False, False),
        ("F6.06", "crdts",              "CRDTs & eventually-consistent state",       "soon", False, False),
        ("F6.07", "clustering",         "Clustering in production (libcluster)",     "soon", False, False),
        ("F6.08", "patterns",           "Designing real-time systems",               "soon", False, False),
        ("F6.09", "cluster-lab",        "A cluster, live \u2014 broadcast, partition, heal", "soon", True, False),
     ]},
    {"id": "F7", "slug": "pragmatic", "name": "Pragmatic Programming", "tint": "--burgundy-2",
     "tag": "shipping it", "modules": [
        ("F7.01", "mix",          "Project structure & Mix",                 "soon", False, False),
        ("F7.02", "exunit",       "Testing with ExUnit & doctests",          "soon", False, False),
        ("F7.03", "property",     "Property-based testing with StreamData",  "soon", False, False),
        ("F7.04", "typespecs",    "Documentation, typespecs & Dialyzer",     "soon", False, False),
        ("F7.05", "let-it-crash", "Error handling & \u201clet it crash\u201d","soon", False, False),
        ("F7.06", "telemetry",    "Telemetry, logging & observability",      "soon", False, False),
        ("F7.07", "releases",     "Dependencies, releases & runtime config", "soon", False, False),
        ("F7.08", "profiling",    "Performance, profiling & benchmarking",   "soon", False, False),
        ("F7.09", "supervision-lab", "Let it crash \u2014 a supervision tree that heals", "soon", True, False),
     ]},
    {"id": "F8", "slug": "phoenix", "name": "Phoenix Framework", "tint": "--gold",
     "tag": "the web, functionally", "modules": [
        ("F8.01", "lifecycle", "Architecture & the request lifecycle", "soon", False, False),
        ("F8.02", "plugs",     "Routing, controllers & plugs",         "soon", False, False),
        ("F8.03", "ecto",      "Ecto: schemas, changesets & queries",  "soon", False, False),
        ("F8.04", "contexts",  "Contexts & domain design",             "soon", False, False),
        ("F8.05", "heex",      "Templates, components & HEEx",          "soon", False, False),
        ("F8.06", "liveview",  "Phoenix LiveView fundamentals",         "soon", False, False),
        ("F8.07", "channels",  "PubSub, channels & real-time",          "soon", False, False),
        ("F8.08", "deploy",    "Auth, deployment & going live",         "soon", False, False),
        ("F8.09", "dashboard-lab", "The live dashboard \u2014 real-time over a socket", "soon", True, False),
     ]},
]


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def render_contents() -> str:
    """Emit the #chapters inner HTML (group labels + res-grids) from the manifest.
    Single-sources the course map so the page can never drift from the structure.
    live/built modules become <a> links; everything else is a non-linking <span>
    (so there are exactly zero /future links). F1's expert dives get their own row."""
    out = []
    for ch in CHAPTERS:
        landing = f"{BASE}/{ch['slug']}"
        landing_live = any(m[3] in ("live", "built") and not m[5] for m in ch["modules"]) and ch["id"] != "F0"
        out.append(f'<div class="group-label"><span class="dot" style="--c:var({ch["tint"]})"></span>'
                   f'<span class="gnum">{ch["id"]}</span> · {esc(ch["name"])}'
                   f'<span style="color:var(--muted);font-weight:400;letter-spacing:.04em"> — {esc(ch["tag"])}</span></div>')
        out.append('<div class="res-grid">')

        # chapter card (F0 has none; its only module IS the chapter)
        if ch["id"] != "F0":
            if landing_live:
                out.append(f'<a class="res-card" href="{landing}"><span class="smallcaps">chapter</span>'
                           f'<span class="title">Open {ch["id"]} · {esc(ch["name"])}</span><span class="arrow">→</span></a>')
            else:
                out.append(f'<span class="res-card soon"><span class="smallcaps">chapter</span>'
                           f'<span class="title">{ch["id"]} · {esc(ch["name"])}</span><span class="arrow">soon</span></span>')

        experts = []
        for mid, slug, title, status, lab, expert in ch["modules"]:
            route = f"{BASE}/course" if mid == "F0.0" else f"{BASE}/{ch['slug']}/{slug}"
            cls, arrow = [], "soon"
            if lab:
                cls.append("practical")
            if status == "live":
                cls.append("live"); arrow = "→"
            elif status == "built":
                arrow = "→"
            else:
                cls.append("soon")
            if expert:
                cls.append("expert")
                experts.append((mid, title, "".join(f' class="res-card {" ".join(cls)}"' for _ in [0])))
                continue
            chip = '<span class="lab">practical · viz</span>' if lab else ""
            you = '<span class="you">you are here</span>' if mid == "F0.0" else ""
            cl = (" " + " ".join(cls)) if cls else ""
            if status in ("live", "built"):
                out.append(f'<a class="res-card{cl}" href="{route}"><span class="smallcaps">{mid}</span>'
                           f'<span class="title">{esc(title)}</span>{you}{chip}<span class="arrow">{arrow}</span></a>')
            else:
                out.append(f'<span class="res-card{cl}"><span class="smallcaps">{mid}</span>'
                           f'<span class="title">{esc(title)}</span>{chip}<span class="arrow">{arrow}</span></span>')
        out.append('</div>')

        # expert dives row (F1)
        if experts:
            out.append('<div class="useful-label">F1 · expert dives — the formal roots, for the curious (soon)</div>')
            out.append('<div class="res-grid">')
            for mid, title, _ in experts:
                out.append(f'<span class="res-card soon expert"><span class="smallcaps">{mid}</span>'
                           f'<span class="title">{esc(title)}</span><span class="exp">expert · dive</span>'
                           f'<span class="arrow">soon</span></span>')
            out.append('</div>')
    return "\n".join(out)


def _module_dicts():
    """Normalise the terse module tuples into dicts with routes."""
    out = []
    for ch in CHAPTERS:
        for m in ch["modules"]:
            mid, slug, title, status, lab, expert = m
            if mid == "F0.0":
                route = f"{BASE}/course"
            else:
                route = f"{BASE}/{ch['slug']}/{slug}"
            out.append({"chapter": ch["id"], "id": mid, "slug": slug, "title": title,
                        "status": status, "lab": lab, "expert": expert, "route": route})
    return out


def check_manifest():
    """Validate the canonical structure. Returns (issues, stats)."""
    issues, mods = [], _module_dicts()
    ids = [m["id"] for m in mods]
    # F0 is a single-page chapter: its landing IS F0.0 (same /elixir/course route),
    # so it does not contribute a separate chapter-landing route.
    routes = [m["route"] for m in mods] + [f"{BASE}/{c['slug']}" for c in CHAPTERS if c["id"] != "F0"]

    # chapters present and ordered F0..F8
    want = [f"F{i}" for i in range(9)]
    got = [c["id"] for c in CHAPTERS]
    if got != want:
        issues.append(f"chapters must be {want}, got {got}")

    # F0 must contain F0.0
    if "F0.0" not in ids:
        issues.append("F0.0 (the course page) is missing")

    # F1 must contain .01-.09 and the three expert dives
    f1 = [m for m in mods if m["chapter"] == "F1"]
    f1_main = [m["id"] for m in f1 if not m["expert"]]
    if f1_main != [f"F1.0{i}" for i in range(1, 10)]:
        issues.append(f"F1 main modules must be F1.01..F1.09, got {f1_main}")
    experts = [m["id"] for m in f1 if m["expert"]]
    if experts != ["F1.0.1", "F1.0.2", "F1.0.3"]:
        issues.append(f"F1 must carry 3 expert dives F1.0.1..F1.0.3, got {experts}")

    # F2..F8: contiguous .01-.09, exactly one lab at .09
    for c in CHAPTERS:
        if c["id"] in ("F0", "F1"):
            continue
        cm = [m for m in mods if m["chapter"] == c["id"]]
        seq = [m["id"] for m in cm]
        want_seq = [f"{c['id']}.0{i}" for i in range(1, 10)]
        if seq != want_seq:
            issues.append(f"{c['id']} modules must be {want_seq[0]}..{want_seq[-1]}, got {seq}")
        labs = [m["id"] for m in cm if m["lab"]]
        if labs != [f"{c['id']}.09"]:
            issues.append(f"{c['id']} must have exactly one lab at .09, got labs={labs}")

    # unique ids and unique routes
    dup_ids = sorted({x for x in ids if ids.count(x) > 1})
    if dup_ids:
        issues.append(f"duplicate module ids: {dup_ids}")
    dup_routes = sorted({x for x in routes if routes.count(x) > 1})
    if dup_routes:
        issues.append(f"duplicate routes: {dup_routes}")

    # no /future anywhere
    bad = [r for r in routes if "/future" in r]
    if bad:
        issues.append(f"/future routes present: {bad}")

    labs = [m for m in mods if m["lab"]]
    experts_all = [m for m in mods if m["expert"]]
    stats = {"chapters": len(CHAPTERS), "modules": len(mods),
             "labs": len(labs), "experts": len(experts_all),
             "live": sum(1 for m in mods if m["status"] == "live"),
             "built": sum(1 for m in mods if m["status"] == "built"),
             "soon": sum(1 for m in mods if m["status"] == "soon")}
    return issues, stats


# ──────────────────────────────────────────────────────────────────────────────
# Safe SVG emitters - the antidote to hand-written f-strings inside heredocs.
# Author runs these once, pastes the OUTPUT (plain literal SVG) into the body.
# ──────────────────────────────────────────────────────────────────────────────
def svg_grid(x1, x2, y0, y1, step, stroke="#1c2340", width=1.0):
    rows = []
    y = y0
    while y <= y1:
        rows.append(f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}"/>')
        y += step
    return f'<g stroke="{stroke}" stroke-width="{width}">' + "".join(rows) + "</g>"


def svg_stations(n, x0, x1, y0, y1):
    """Ascending station markers (a 'bridge'): n equally spaced points climbing
    from (x0,y0) to (x1,y1). Returns coords as data + a polyline + circles."""
    pts = []
    for i in range(n):
        t = 0 if n == 1 else i / (n - 1)
        x = round(x0 + (x1 - x0) * t)
        y = round(y0 + (y1 - y0) * t)
        pts.append((x, y))
    path = "M " + " L ".join(f"{x} {y}" for x, y in pts)
    out = [f'<path d="{path}" fill="none" stroke="#7d745f" stroke-width="1.6"/>']
    for i, (x, y) in enumerate(pts, 1):
        out.append(f'<circle cx="{x}" cy="{y}" r="6.5"/>')
        out.append(f'<text x="{x}" y="{y+22}" text-anchor="middle" '
                   f'font-family="JetBrains Mono" font-size="8.5">F{i}</text>')
    return "\n".join(out) + "\n<!-- coords: " + json.dumps(pts) + " -->"


# ──────────────────────────────────────────────────────────────────────────────
# Head extraction + assembly
# ──────────────────────────────────────────────────────────────────────────────
def extract_head(src: str, out: str) -> None:
    html = open(src, encoding="utf-8").read()
    i = html.find(HEAD_END)
    if i < 0:
        sys.exit(f"! no </head> found in {src}")
    open(out, "w", encoding="utf-8").write(html[:i])   # everything BEFORE </head>
    print(f"head extracted: {i} chars -> {out}")


CONTENTS_TOKEN = "<!--CONTENTS-->"


def assemble(head_path, body_path, title, desc, css="", katex=True, contents=False) -> str:
    head = open(head_path, encoding="utf-8").read()
    head = re.sub(r"<title>.*?</title>", "<title>" + title + "</title>", head, count=1, flags=re.S)
    head = re.sub(r'<meta name="description"[^>]*>',
                  '<meta name="description" content="' + desc + '">', head, count=1)
    head = head + (css or "") + "\n" + HEAD_END
    body = open(body_path, encoding="utf-8").read()
    if contents:
        if CONTENTS_TOKEN not in body:
            sys.exit(f"! --contents given but {CONTENTS_TOKEN} not found in {body_path}")
        body = body.replace(CONTENTS_TOKEN, render_contents())
    html = head + "\n" + body
    if katex:
        html = html.replace("\\$", "$")           # KaTeX delimiters survived shell quoting
    return html


# ──────────────────────────────────────────────────────────────────────────────
# Validation
# ──────────────────────────────────────────────────────────────────────────────
# Un-ambiguous signatures of an un-expanded Python template that leaked into HTML.
# These never legitimately appear in our HTML/CSS or in Elixir code samples.
LEAK_PATTERNS = [
    (r'"""\s*\+',                       'unexpanded heredoc: `""" +`'),
    (r'\+\s*"""',                       'unexpanded heredoc: `+ """`'),
    (r"''\s*\.join\(",                  "python str.join leaked: `''.join(`"),
    (r'"\s*\.join\(',                   'python str.join leaked: `".join(`'),
    (r"\bf'<",                          "python f-string leaked: `f'<`"),
    (r'\bf"<',                          'python f-string leaked: `f"<`'),
    (r"for\s+\w+\s+in\s+range\(",       "python comprehension leaked: `for .. in range(`"),
]


def validate(html: str, allow_future=False) -> list:
    issues = []

    # 0) template leaks first - the highest-signal failure
    for pat, label in LEAK_PATTERNS:
        if re.search(pat, html):
            issues.append("template leak — " + label)

    od, cd = html.count("<div"), html.count("</div>")
    if od != cd:
        issues.append(f"div imbalance: {od} '<div' / {cd} '</div>'")

    body = html[html.find("<body"):]
    depth, cur, leaked = 0, None, []
    for m in re.finditer(r'<section\b[^>]*>|</section>|<div\b|</div>', body):
        t = m.group(0)
        if t.startswith("<section"):
            mid = re.search(r'id="([^"]*)"', t)
            cur = mid.group(1) if mid else "(unnamed)"
        elif t == "</section>":
            if depth != 0:
                leaked.append(f"#{cur} (+{depth})")
            depth = 0
        elif t.startswith("<div"):
            depth += 1
        elif t == "</div>":
            depth -= 1
    if leaked:
        issues.append("section div leak (probably an unclosed .wrap): " + ", ".join(leaked))

    os_, cs = html.count("<svg"), html.count("</svg>")
    if os_ != cs:
        issues.append(f"svg imbalance: {os_} '<svg' / {cs} '</svg>'")

    if not allow_future and html.count("/future/"):
        issues.append(f"{html.count('/future/')} link(s) to /future (course-internal integrity)")

    if "IntersectionObserver" not in html:
        issues.append("reveal-on-scroll JS missing (IntersectionObserver)")

    if "</antml" in html or "<antml" in html:
        issues.append("stray antml tag in output")

    # JS syntax of EVERY <script> ... </script> via node --check (not only trailing)
    for i, m in enumerate(re.finditer(r"<script\b[^>]*>(.*?)</script>", html, re.S)):
        js = m.group(1).strip()
        if not js or "src=" in m.group(0)[:m.group(0).find('>')]:
            continue
        fd, jp = tempfile.mkstemp(suffix=".js")
        with os.fdopen(fd, "w") as f:
            f.write(js)
        try:
            r = subprocess.run(["node", "--check", jp], capture_output=True, text=True)
            if r.returncode != 0:
                tail = r.stderr.strip().splitlines()[-1] if r.stderr.strip() else "unknown"
                issues.append(f"<script> #{i+1} JS syntax error: " + tail)
        except FileNotFoundError:
            pass
        finally:
            os.unlink(jp)
    return issues


def report(html: str, issues: list) -> bool:
    print(f"  div {html.count('<div')}/{html.count('</div>')}  "
          f"section {html.count('<section')}/{html.count('</section>')}  "
          f"svg {html.count('<svg')}/{html.count('</svg>')}  "
          f"/future {html.count('/future/')}  "
          f"reveal {'IntersectionObserver' in html}")
    if issues:
        print("  STATUS: FAIL")
        for i in issues:
            print("   x " + i)
        return False
    print("  STATUS: OK")
    return True


# ──────────────────────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────────────────────
def cmd_manifest(a):
    issues, stats = check_manifest()
    if a.json:
        print(json.dumps({"chapters": CHAPTERS, "modules": _module_dicts(),
                           "stats": stats, "issues": issues}, ensure_ascii=False, indent=2))
    else:
        print("Functional Programming in Elixir — course manifest")
        for c in CHAPTERS:
            ms = c["modules"]
            print(f"  {c['id']} · {c['name']:34s} {c['slug']:<13} {len(ms):>2} modules"
                  + (f"  ({sum(1 for m in ms if m[5])} expert)" if any(m[5] for m in ms) else ""))
        print(f"  {'-'*64}")
        print(f"  chapters {stats['chapters']}  modules {stats['modules']}  "
              f"labs {stats['labs']}  experts {stats['experts']}  "
              f"| live {stats['live']}  built {stats['built']}  soon {stats['soon']}")
    ok = report_struct(issues)
    sys.exit(0 if ok else 1)


def report_struct(issues):
    if issues:
        print("  STATUS: FAIL")
        for i in issues:
            print("   x " + i)
        return False
    print("  STATUS: OK")
    return True


def cmd_routes(a):
    for m in _module_dicts():
        if a.status and m["status"] != a.status:
            continue
        flag = "lab" if m["lab"] else ("exp" if m["expert"] else "   ")
        print(f"  {m['id']:<7} {m['status']:<6} {flag}  {m['route']:<34} {m['title']}")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)

    e = sub.add_parser("extract-head"); e.add_argument("src"); e.add_argument("out")

    b = sub.add_parser("build")
    b.add_argument("--head", required=True); b.add_argument("--body", required=True)
    b.add_argument("--out", required=True)
    b.add_argument("--title", required=True); b.add_argument("--desc", required=True)
    b.add_argument("--css", default=None)
    b.add_argument("--no-katex", action="store_true")
    b.add_argument("--allow-future", action="store_true")
    b.add_argument("--contents", action="store_true",
                   help="replace the <!--CONTENTS--> token in the body with the manifest-rendered course map")

    v = sub.add_parser("validate"); v.add_argument("file")
    v.add_argument("--allow-future", action="store_true")

    sub.add_parser("contents")  # print the rendered #chapters inner HTML (for inspection)

    m = sub.add_parser("manifest"); m.add_argument("--json", action="store_true")
    r = sub.add_parser("routes"); r.add_argument("--status", default=None)

    g = sub.add_parser("svg-grid")
    g.add_argument("--x1", type=int, required=True); g.add_argument("--x2", type=int, required=True)
    g.add_argument("--y0", type=int, required=True); g.add_argument("--y1", type=int, required=True)
    g.add_argument("--step", type=int, required=True)
    g.add_argument("--stroke", default="#1c2340"); g.add_argument("--width", type=float, default=1.0)

    s = sub.add_parser("svg-stations")
    s.add_argument("--n", type=int, required=True)
    s.add_argument("--x0", type=int, required=True); s.add_argument("--x1", type=int, required=True)
    s.add_argument("--y0", type=int, required=True); s.add_argument("--y1", type=int, required=True)

    a = ap.parse_args()

    if a.cmd == "extract-head":
        extract_head(a.src, a.out); return
    if a.cmd == "manifest":
        cmd_manifest(a); return
    if a.cmd == "routes":
        cmd_routes(a); return
    if a.cmd == "svg-grid":
        print(svg_grid(a.x1, a.x2, a.y0, a.y1, a.step, a.stroke, a.width)); return
    if a.cmd == "svg-stations":
        print(svg_stations(a.n, a.x0, a.x1, a.y0, a.y1)); return
    if a.cmd == "contents":
        print(render_contents()); return
    if a.cmd == "validate":
        html = open(a.file, encoding="utf-8").read()
        issues = validate(html, allow_future=a.allow_future)
        ok = report(html, issues)
        sys.exit(0 if ok else 1)

    # build
    css = open(a.css, encoding="utf-8").read() if a.css else ""
    html = assemble(a.head, a.body, a.title, a.desc, css=css, katex=not a.no_katex, contents=a.contents)
    issues = validate(html, allow_future=a.allow_future)
    open(a.out, "w", encoding="utf-8").write(html)     # always write so you can render/inspect
    print(f"  wrote {a.out} ({len(html)} bytes)")
    ok = report(html, issues)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
