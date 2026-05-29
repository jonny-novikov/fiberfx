#!/usr/bin/env python3
"""
build_page.py - robust builder + validator for jonnify course pages.

Why: page generation used to be ad-hoc heredocs; small structure bugs (an
unclosed `<div class="wrap">`, a broken trailing <script>, a stray /future
link) slipped through and were caught only by eye. This makes the build a
single command with fail-loud validation.

Pipeline
  1) extract-head : pull the shared <head> (design system) from an existing page.
  2) build        : assemble head + body, set <title>/<meta>, inject extra CSS,
                    unescape KaTeX `\\$` -> `$`, VALIDATE, then write + report.

Validation (each reported individually)
  - <div> balance (global)
  - per-<section> div depth   <- catches the classic leaked `<div class="wrap">`
  - <svg> balance
  - links to /future          <- course-internal integrity (0 unless --allow-future)
  - reveal-on-scroll JS present (IntersectionObserver)
  - stray antml tags
  - JS syntax of the trailing <script> via `node --check`

Usage
  python3 build_page.py extract-head SRC.html HEAD.html
  python3 build_page.py build --head HEAD.html --body BODY.html --out OUT.html \
          --title "..." --desc "..." [--css EXTRA.css] [--no-katex] [--allow-future]

The build always writes the file (so you can render/inspect) but prints
STATUS: OK or STATUS: FAIL <issues>. Treat any FAIL as a stop.
"""
import argparse, os, re, subprocess, sys, tempfile

HEAD_END = "</head>"


def extract_head(src: str, out: str) -> None:
    html = open(src, encoding="utf-8").read()
    i = html.find(HEAD_END)
    if i < 0:
        sys.exit(f"! no </head> found in {src}")
    open(out, "w", encoding="utf-8").write(html[:i])   # everything BEFORE </head>
    print(f"head extracted: {i} chars -> {out}")


def assemble(head_path, body_path, title, desc, css="", katex=True) -> str:
    head = open(head_path, encoding="utf-8").read()
    head = re.sub(r"<title>.*?</title>", "<title>" + title + "</title>", head, count=1, flags=re.S)
    head = re.sub(r'<meta name="description"[^>]*>', '<meta name="description" content="' + desc + '">', head, count=1)
    head = head + (css or "") + "\n" + HEAD_END
    body = open(body_path, encoding="utf-8").read()
    html = head + "\n" + body
    if katex:
        html = html.replace("\\$", "$")           # KaTeX delimiters survived shell quoting
    return html


def validate(html: str, allow_future=False) -> list:
    issues = []

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

    m = re.search(r"<script>(.*?)</script>\s*</body>", html, re.S)
    if m:
        fd, jp = tempfile.mkstemp(suffix=".js")
        with os.fdopen(fd, "w") as f:
            f.write(m.group(1))
        try:
            r = subprocess.run(["node", "--check", jp], capture_output=True, text=True)
            if r.returncode != 0:
                tail = r.stderr.strip().splitlines()[-1] if r.stderr.strip() else "unknown"
                issues.append("trailing <script> JS syntax error: " + tail)
        except FileNotFoundError:
            pass
        finally:
            os.unlink(jp)
    return issues


def report(html: str, issues: list) -> None:
    print(f"  div {html.count('<div')}/{html.count('</div>')}  "
          f"section {html.count('<section')}/{html.count('</section>')}  "
          f"svg {html.count('<svg')}/{html.count('</svg>')}  "
          f"/future {html.count('/future/')}  "
          f"reveal {'IntersectionObserver' in html}")
    if issues:
        print("  STATUS: FAIL")
        for i in issues:
            print("   x " + i)
    else:
        print("  STATUS: OK")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("extract-head"); e.add_argument("src"); e.add_argument("out")
    b = sub.add_parser("build")
    b.add_argument("--head", required=True); b.add_argument("--body", required=True); b.add_argument("--out", required=True)
    b.add_argument("--title", required=True); b.add_argument("--desc", required=True)
    b.add_argument("--css", default=None)
    b.add_argument("--no-katex", action="store_true")
    b.add_argument("--allow-future", action="store_true")
    a = ap.parse_args()

    if a.cmd == "extract-head":
        extract_head(a.src, a.out)
        return
    css = open(a.css, encoding="utf-8").read() if a.css else ""
    html = assemble(a.head, a.body, a.title, a.desc, css=css, katex=not a.no_katex)
    issues = validate(html, allow_future=a.allow_future)
    open(a.out, "w", encoding="utf-8").write(html)     # always write so you can render/inspect
    print(f"  wrote {a.out} ({len(html)} bytes)")
    report(html, issues)


if __name__ == "__main__":
    main()
