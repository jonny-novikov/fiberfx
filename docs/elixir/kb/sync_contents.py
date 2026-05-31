#!/usr/bin/env python3
"""sync_contents.py — refresh the chapter cards on elixir/index.html from the
build_page.py manifest, without a full page rebuild.

The contents page embeds render_contents() output (the {{CONTENTS}} region: one
<section class="chap reveal"> per chapter, with a linked card per built module and
a quiet non-link card per planned one). When modules are promoted planned->built in
build_page.py, those cards go stale. This re-renders the whole contents region from
the current manifest and splices it back in — so the page links every built module
and shows the rest as planned. Run it after any promotion:

    python3 sync_contents.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_page as bp  # noqa: E402

INDEX = os.path.normpath(os.path.join(HERE, "..", "..", "..", "elixir", "index.html"))


def main():
    html = open(INDEX, encoding="utf-8").read()
    fresh = bp.render_contents()
    start = html.index('<section class="chap reveal">')
    last = html.rindex('<section class="chap reveal">')
    end = html.index("</section>", last) + len("</section>")
    new = html[:start] + fresh + html[end:]
    chapters = fresh.count('class="chap reveal"')
    links = fresh.count('class="mod" href')
    if new == html:
        print(f"already in sync ({chapters} chapters, {links} built module links)")
        return 0
    open(INDEX, "w", encoding="utf-8").write(new)
    print(f"synced {os.path.relpath(INDEX)}: {chapters} chapters, {links} built module links")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
