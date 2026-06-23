#!/usr/bin/env python3
"""build_course.py — the BCS course toolkit.

Renders the served BCS course pages (chapter landings, module hubs, dives) on
the BCS contract sheet (references/sheet.css). It owns the design system, the
page shell, the mandatory interactive figure, the doors, and slug routing, so
page content lives in a small driver and the look never drifts.

Structure law (do not break): a CHAPTER (B[N], /bcs/<chapter>) holds 6 MODULES
(B[N].[M], /bcs/<chapter>/<module>); each MODULE holds 3 DIVES
(/bcs/<chapter>/<module>/<dive>). Links are slug routes, never bcs.N.M forms.

Grounding law: a number reaches a page only if it is verifiable in the committed
repo — a real .out file, or source that asserts it (e.g. branded_id.ex's
self_check! vectors). Use cite_guard() to enforce it; course_lint.py re-checks.
"""
import os, re, html as _html

HERE = os.path.dirname(os.path.abspath(__file__))
SHEET = open(os.path.join(HERE, "..", "references", "sheet.css"), encoding="utf-8").read()
EPOCH_MS = 1704067200000

# the only numbers a page may state without pointing at a committed .out: the
# contract vectors branded_id.ex asserts at boot, and the layout constants.
CONTRACT_VECTORS = {
    "234878118",            # placement(USR0KHTOWnGLuC) = hash32(274557032793636864)
    "274557032793636864",
    "320636799581945856",   # parse("USR0NgWEfAEJfs")
    "USR0KHTOWnGLuC", "USR0NgWEfAEJfs",
    "1704067200000",        # epoch (2024-01-01)
    "2093", "41", "10", "12", "63", "14", "11", "3", "62",  # layout
}

# figure styles (the dive/landing SVGs); the sheet's .anat focus/dim drives them
FIGCSS = """<style id="figcss">
.anat .cell{fill:var(--b-pay-tint);stroke:var(--b-ts);stroke-width:1}
.anat .cell.ns{fill:var(--b-ns-tint);stroke:var(--b-ns)}
.anat .ch{font:700 14px var(--mono);fill:var(--b-ink);text-anchor:middle}
.anat .fld.ts{fill:var(--b-pay-tint);stroke:var(--b-ts);stroke-width:1.5}
.anat .fld.node{fill:#dcebe2;stroke:var(--b-node);stroke-width:1.5}
.anat .fld.seq{fill:#ece1f1;stroke:var(--b-seq);stroke-width:1.5}
.anat .box{fill:var(--b-card);stroke:var(--b-ts);stroke-width:1.5}
.anat .lock{fill:var(--b-paper);stroke:var(--b-node);stroke-width:1.5}
.anat .tok{fill:var(--b-ns-tint);stroke:var(--b-ns);stroke-width:1.5}
.anat .arr{stroke:var(--b-ns);stroke-width:2;fill:none;marker-end:url(#ah)}
.anat .blbl{font:11px var(--mono);fill:var(--b-dim);text-anchor:middle}
.anat .bsub{font:700 12px var(--mono);fill:var(--b-ink);text-anchor:middle}
</style>"""

ARROW_DEF = ('<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" '
             'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
             '<path d="M0 0 L10 5 L0 10 z" fill="var(--b-ns)"></path></marker></defs>')

# ----- the doors (the /elixir door is retired; /echo-persistence stands in) -----
DOORS = """      <div class="doors">
        <a class="door" href="/echomq">
          <span class="dr">/echomq</span>
          <h3>EchoMQ — the protocol, in depth</h3>
          <p>The bus B3 narrates, taught rung by rung: the keyspace, the Lua inventory, and the 3.0 Stream Tier &#8212; <code>XADD</code>, <code>XREADGROUP</code>, <code>XACK</code> &#8212; with conformance on Valkey.</p>
        </a>
        <a class="door" href="/redis-patterns">
          <span class="dr">/redis-patterns</span>
          <h3>Redis Patterns Applied</h3>
          <p>The substrate patterns under the bus: sorted sets, atomic Lua moves, locks, and streams &#8212; the judgement layer.</p>
        </a>
        <a class="door" href="/echo-persistence">
          <span class="dr">/echo-persistence</span>
          <h3>Echo Persistence — the durable floor</h3>
          <p>Beneath the volatile bus: the durability dial, the page engine built twice, and the commit-LSN loop. Where Part I says state lives somewhere, this says where it lives durably.</p>
        </a>
      </div>"""

# the chapter map (B0–B9; persistence floor is B5). Routes are slugs.
CHAPTERS_FOOT = """        <a href="/bcs">B0 &#183; Orientation</a>
        <a href="/bcs/ideas">B1 &#183; Ideas Behind</a>
        <span>B2 &#183; The Elixir BCS Core<i>soon</i></span>
        <span>B3 &#183; The Bus<i>soon</i></span>
        <span>B4 &#183; EchoCache<i>soon</i></span>
        <span>B5 &#183; The Persistence Floor<i>soon</i></span>
        <span>B6 &#183; Go<i>soon</i></span>
        <span>B7 &#183; Node 22+<i>soon</i></span>
        <span>B8 &#183; Production on Fly<i>soon</i></span>
        <span>B9 &#183; The Trading System<i>soon</i></span>"""

COURSES_FOOT = """        <a href="/bcs">BCS — this course</a>
        <a href="/echomq">EchoMQ — the protocol</a>
        <a href="/redis-patterns">Redis Patterns Applied</a>
        <a href="/echo-persistence">Echo Persistence — the durable floor</a>"""


def route(chapter, module=None, dive=None):
    """Slug route. route('ideas','identity-contract') -> /bcs/ideas/identity-contract."""
    parts = ["/bcs", chapter]
    if module:
        parts.append(module)
    if dive:
        parts.append(dive)
    r = "/".join(parts)
    assert not re.search(r"/bcs\.\d|bcs\.\d+(\.\d+)*", r), f"non-slug route: {r}"
    return r


def route_tag(*segs):
    """The header breadcrumb. Each seg is (href_or_None, label, is_current)."""
    out = '<span class="rsep">/</span><a href="/bcs">bcs</a>'
    for href, label, cur in segs:
        out += '<span class="rsep">/</span>'
        out += f'<span class="rcur">{label}</span>' if cur else f'<a href="{href}">{label}</a>'
    return out


def sech(no, h, src):
    return (f'      <div class="sech"><span class="sno">&#167;{no}</span>'
            f'<h2>{h}</h2><span class="ssrc">{src}</span></div>')


def figure(caption, svg, buttons, default, fid="anat"):
    """The mandatory interactive figure: an .anat SVG + segbar + readout.
    buttons: list of (data_seg, label). default: the resting readout text."""
    bar = "\n".join(
        f'          <button type="button" data-seg="{s}" aria-pressed="false">{l}</button>'
        for s, l in buttons)
    return f"""      <figure class="anatomy">
        <figcaption>{caption}</figcaption>
{svg}
        <div class="segbar" id="segbar" role="group" aria-label="Select">
{bar}
        </div>
        <div class="readout" id="readout"><span class="rk">readout &#183;</span> {default}</div>
      </figure>"""


def card(bid, title, body, meta, href=None):
    cls = "a" if href else "div"
    open_t = f'<a class="pcard" href="{href}">' if href else '<div class="pcard">'
    close_t = "</a>" if href else "</div>"
    return (f'        {open_t}\n          <span class="bid">{bid}</span>'
            f'<h3>{title}</h3>\n          <p>{body}</p>\n'
            f'          <span class="meta">{meta}</span>\n        {close_t}')


def grid(cards):
    return '      <div class="pgrid">\n' + "\n".join(cards) + "\n      </div>"


def refs(no, sources, related=None):
    li = "\n".join(
        f'          <li><a href="{u}" rel="noopener">{t}</a><span class="rs">{s}</span></li>'
        for t, s, u in sources)
    if related is None:
        related = [
            ('/bcs', 'BCS — the course home', 'the law, the id anatomy, the chapter map'),
            ('/echo-persistence', 'Echo Persistence', 'the durable floor beneath the bus'),
        ]
    rli = "\n".join(
        f'          <li><a href="{u}">{t}</a><span class="rs">{s}</span></li>'
        for u, t, s in related)
    return f"""    <section id="refs">
{sech(no, 'References', 'sources &#183; related')}
      <div class="refs">
        <p class="refgrp">Sources</p>
        <ul>
{li}
        </ul>
        <p class="refgrp">Related</p>
        <ul>
{rli}
        </ul>
      </div>
    </section>"""


def pager(prev, nxt):
    p = (f'<a class="pgx" href="{prev[1]}"><span class="pk">previous</span>&#8592; {prev[0]}</a>'
         if prev else '<span class="pgx"></span>')
    n = (f'<a class="pgx" href="{nxt[1]}"><span class="pk">next</span>{nxt[0]} &#8594;</a>'
         if nxt else '<span class="pgx"></span>')
    return f'    <nav class="pager" aria-label="Course pager">\n      {p}\n      {n}\n    </nav>'


def cite_guard(numbers, repo_root):
    """Grounding enforcement. Each item is (number_str, source_path). The number
    passes if it is a known contract vector, or source_path exists under repo_root
    and contains the number verbatim. Raises on a thin (ungrounded) number."""
    bad = []
    for num, src in numbers:
        if str(num) in CONTRACT_VECTORS:
            continue
        p = os.path.join(repo_root, src) if repo_root else src
        if not os.path.exists(p):
            bad.append(f"{num}: source {src} does not exist (thin)")
            continue
        if str(num) not in open(p, encoding="utf-8", errors="ignore").read():
            bad.append(f"{num}: not found verbatim in {src}")
    if bad:
        raise AssertionError("ungrounded figures:\n  " + "\n  ".join(bad))


def page(*, fname, title, desc, route_tag_html, topnav, stamp, hero, fig, body,
         refs_html, pager_html, seg_js, doors_no="4", chapters=CHAPTERS_FOOT,
         courses=COURSES_FOOT, extracss=FIGCSS):
    """Render a full self-contained course page."""
    nav = "\n".join(f'      <a href="#{a}">{l}</a>' for a, l in topnav)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<meta name="description" content="{desc}">
<style>
{SHEET}</style>
{extracss}
</head>
<body>

<header class="top">
  <div class="wrap">
    <span class="brand">jonnify<span class="bdot">·</span>bcs</span>
    <span class="route-tag">{route_tag_html}</span>
    <nav class="topnav" aria-label="Page sections">
{nav}
    </nav>
  </div>
</header>

<main>
  <div class="wrap">

{hero}

{fig}
    </section>

    <div class="idrule" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i><i></i></div>

{body}

    <section id="doors">
{sech(doors_no, 'The doors', 'the sibling courses')}
{DOORS}
    </section>

{refs_html}

{pager_html}

  </div>
</main>

<footer class="site-foot">
  <div class="wrap">
    <nav class="foot-nav" aria-label="BCS — course navigation">
      <div class="foot-brand">
        <span class="foot-logo">jonnify<span class="bdot">·</span>bcs</span>
        <p class="foot-tag">The Branded Component System — boundaries around systems, identity as a contract, every figure traceable to a committed output.</p>
      </div>
      <div class="foot-links">
        <p class="foot-h">Chapters</p>
{chapters}
      </div>
      <div class="foot-links">
        <p class="foot-h">The courses</p>
{courses}
      </div>
    </nav>
    <div class="foot-bar">
      <p class="foot-cc">&copy; jonnify</p>
      <div class="stamp" id="stamp" role="button" tabindex="0" aria-expanded="false" aria-label="Build stamp — activate to decode">
        build <span class="id" id="stampId">{stamp}</span>
        <dl class="panel">
          <dt>namespace</dt><dd id="st-ns">&mdash;</dd>
          <dt>snowflake</dt><dd id="st-snow">&mdash;</dd>
          <dt>node</dt><dd id="st-node">&mdash;</dd>
          <dt>seq</dt><dd id="st-seq">&mdash;</dd>
          <dt>timestamp</dt><dd id="st-ts">&mdash;</dd>
        </dl>
      </div>
    </div>
  </div>
</footer>

<script>
(function () {{
  "use strict";
  document.documentElement.classList.add('js');
  var SEG = {seg_js};
  var anat = document.getElementById('anat');
  var readout = document.getElementById('readout');
  var buttons = document.querySelectorAll('#segbar button');
  function select(seg) {{
    buttons.forEach(function (b) {{ b.setAttribute('aria-pressed', b.getAttribute('data-seg') === seg ? 'true' : 'false'); }});
    if (anat) {{
      anat.classList.toggle('focus', !!seg);
      anat.querySelectorAll('g[data-seg]').forEach(function (g) {{ g.classList.toggle('on', g.getAttribute('data-seg') === seg); }});
    }}
    if (readout && seg && SEG[seg]) {{ readout.innerHTML = '<span class="rk">readout &#183;</span> ' + SEG[seg]; }}
  }}
  buttons.forEach(function (b) {{ b.addEventListener('click', function () {{ var s=b.getAttribute('data-seg'); select(b.getAttribute('aria-pressed')==='true'?null:s); }}); }});
  if (anat) {{ anat.querySelectorAll('g[data-seg]').forEach(function (g) {{ g.addEventListener('mouseenter', function(){{select(g.getAttribute('data-seg'));}}); g.addEventListener('mouseleave', function(){{select(null);}}); }}); }}
  var B62="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz", EPOCH={EPOCH_MS}n;
  function b62(s){{var n=0n;for(var i=0;i<s.length;i++){{var d=B62.indexOf(s.charAt(i));if(d<0)return null;n=n*62n+BigInt(d);}}return n;}}
  function p2(x){{return (x<10?'0':'')+x;}}
  function dec(id){{if(!id||id.length!==14)return null;var ns=id.slice(0,3),s=b62(id.slice(3));if(s===null)return null;var ts=s>>22n,nd=(s>>12n)&0x3FFn,sq=s&0xFFFn,d=new Date(Number(ts)+Number(EPOCH));return {{ns:ns,snow:s.toString(),node:nd.toString(),seq:sq.toString(),ts:d.getUTCFullYear()+'-'+p2(d.getUTCMonth()+1)+'-'+p2(d.getUTCDate())+' '+p2(d.getUTCHours())+':'+p2(d.getUTCMinutes())+':'+p2(d.getUTCSeconds())+' UTC'}};}}
  var stamp=document.getElementById('stamp'), idEl=document.getElementById('stampId');
  if(stamp&&idEl){{var info=dec(idEl.textContent.trim());if(info){{var put=function(s,t){{var e=document.getElementById(s);if(e)e.textContent=t;}};put('st-ns',info.ns);put('st-snow',info.snow);put('st-node',info.node);put('st-seq',info.seq);put('st-ts',info.ts);}}
    var tog=function(){{var o=stamp.classList.toggle('open');stamp.setAttribute('aria-expanded',o?'true':'false');}};
    stamp.addEventListener('click',tog);stamp.addEventListener('keydown',function(e){{if(e.key==='Enter'||e.key===' '||e.key==='Spacebar'){{e.preventDefault();tog();}}}});}}
}})();
</script>

</body>
</html>
"""
