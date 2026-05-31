#!/usr/bin/env python3
"""Download every reference in ../kb/elixir-references.md for offline use.

De-duplicates by page (the URL with its #fragment stripped), mirrors each page
into ./files/, and writes manifest.json (machine) + INDEX.md (human, grouped by
module). Re-runnable: an already-downloaded, non-empty file is skipped. The HTTP
status of each fetch doubles as a liveness check on the bibliography.

Usage:  python3 fetch_refs.py            # fetch all
        python3 fetch_refs.py --force    # re-fetch even if present
"""
import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, "..", "kb", "elixir-references.md"))
FILES = os.path.join(HERE, "files")
FORCE = "--force" in sys.argv
UA = "Mozilla/5.0 (jonnify offline-mirror; +https://jonnify.fly.dev)"

os.makedirs(FILES, exist_ok=True)

LINK = re.compile(r"\[([^\]]+)\]\((https?://[^)\s]+)\)")
H2 = re.compile(r"^##\s+(.*)$")
H3 = re.compile(r"^###\s+(.*)$")


def page_of(url):
    """The download URL: fragment stripped. Returns (dlurl, fragment)."""
    if "#" in url:
        base, frag = url.split("#", 1)
        return base, frag
    return url, ""


def slug(dlurl):
    u = re.sub(r"^https?://", "", dlurl)
    u = re.sub(r"[^A-Za-z0-9._-]+", "_", u).strip("._-")
    return u[:120] or "ref"


# ---- parse the bibliography into ordered entries + unique pages ----
entries = []          # {group, title, url, dlurl, fragment}
pages = {}            # dlurl -> {slug}
group = "Core references"
with open(SRC, encoding="utf-8") as f:
    for line in f:
        m3, m2 = H3.match(line), H2.match(line)
        if m3:
            group = m3.group(1).strip()
            continue
        if m2:
            group = m2.group(1).strip()
            continue
        for m in LINK.finditer(line):
            title, url = m.group(1).strip(), m.group(2).strip()
            dlurl, frag = page_of(url)
            entries.append({"group": group, "title": title, "url": url, "dlurl": dlurl, "fragment": frag})
            pages.setdefault(dlurl, {"slug": slug(dlurl)})


def fetch(dlurl):
    rec = pages[dlurl]
    base = rec["slug"]
    # Resume: if a finished file for this page already exists, reuse it.
    if not FORCE:
        for ext in (".pdf", ".html", ".bin"):
            existing = os.path.join(FILES, base + ext)
            if os.path.exists(existing) and os.path.getsize(existing) > 0:
                rec.update(file=f"files/{base}{ext}", status="cached", http_code="(cached)",
                           content_type="", bytes=os.path.getsize(existing), effective_url=dlurl)
                return
    tmp = os.path.join(FILES, base + ".part")
    cmd = ["curl", "-sSL", "--compressed", "-A", UA,
           "--max-time", "45", "--retry", "1", "--retry-delay", "1",
           "-w", "%{http_code}\t%{content_type}\t%{size_download}\t%{url_effective}",
           "-o", tmp, dlurl]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
        parts = (p.stdout or "").strip().split("\t")
    except Exception as e:
        if os.path.exists(tmp):
            os.remove(tmp)
        rec.update(file=None, status="error", http_code=None, content_type="", bytes=0,
                   effective_url=dlurl, error=str(e)[:200])
        return
    code = parts[0] if parts else "000"
    ctype = parts[1] if len(parts) > 1 else ""
    size = int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0
    eff = parts[3] if len(parts) > 3 else dlurl
    is_pdf = "pdf" in ctype.lower() or dlurl.lower().split("?")[0].endswith(".pdf")
    ext = ".pdf" if is_pdf else (".html" if "html" in ctype.lower() else ".bin")
    ok = code.startswith("2") and size > 0
    final = None
    if ok and os.path.exists(tmp):
        final = base + ext
        os.replace(tmp, os.path.join(FILES, final))
    elif os.path.exists(tmp):
        os.remove(tmp)
    rec.update(file=(f"files/{final}" if final else None),
               status=("ok" if ok else "failed"), http_code=code,
               content_type=ctype, bytes=size, effective_url=eff)


order = list(pages.keys())
with ThreadPoolExecutor(max_workers=8) as ex:
    list(ex.map(fetch, order))
for u in order:
    r = pages[u]
    print(f"{r['status']:>7} {str(r.get('http_code')):>8} {r.get('bytes', 0):>9}  {u}")

# ---- manifest.json ----
ok = sum(1 for r in pages.values() if r["status"] in ("ok", "cached"))
failed = [u for u, r in pages.items() if r["status"] not in ("ok", "cached")]
manifest = {
    "source": "docs/elixir/kb/elixir-references.md",
    "pages_total": len(pages), "pages_ok": ok, "pages_failed": len(failed),
    "failed_urls": failed,
    "pages": {u: pages[u] for u in order},
    "entries": entries,
}
with open(os.path.join(HERE, "manifest.json"), "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2, ensure_ascii=False)

# ---- INDEX.md (grouped, with local links + original URL + status) ----
idx = ["# Elixir references — offline mirror", "",
       f"Local copies of the sources in [`../kb/elixir-references.md`](../kb/elixir-references.md). "
       f"{ok}/{len(pages)} pages mirrored into `files/`. Regenerate with `python3 fetch_refs.py`.", ""]
seen_group = None
for e in entries:
    if e["group"] != seen_group:
        seen_group = e["group"]
        idx.append(f"## {seen_group}\n")
    r = pages[e["dlurl"]]
    if r.get("file"):
        local = r["file"] + ("#" + e["fragment"] if e["fragment"] else "")
        idx.append(f"- {e['title']} — [offline]({local}) · [source]({e['url']})")
    else:
        idx.append(f"- {e['title']} — _offline copy unavailable_ ({r.get('http_code')}) · [source]({e['url']})")
idx.append("")
with open(os.path.join(HERE, "INDEX.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(idx))

print(f"\n{ok}/{len(pages)} pages mirrored; {len(failed)} failed. wrote manifest.json + INDEX.md")
if failed:
    print("failed:")
    for u in failed:
        print("  ", pages[u].get("http_code"), u)
