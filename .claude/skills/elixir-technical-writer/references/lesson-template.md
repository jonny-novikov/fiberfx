# Lesson template — the content fragment

What an author actually writes: a **body fragment**, not a whole HTML document. The builder wraps the fragment with `<!doctype html>` + `<html lang="en">` + the shared `<head>` (tokens + base CSS), opens `<body>`, and appends the progressive-enhancement bootstrap script. The fragment is the content between those. The author never writes the doctype, the head, or the bootstrap.

## Build placeholders

The builder substitutes these tokens at assemble time. Put each one only where it belongs.

| Placeholder | Filled with | Where it appears in the fragment |
|---|---|---|
| `{{TITLE}}` | the page `<title>` (e.g. `What a function really is — F1.01 · jonnify`) | in the shared `<head>` only — the builder fills it there from the page's registry entry; **not** authored in the fragment. |
| `{{DESC}}` | the meta description | in the shared `<head>` only — likewise from the registry entry, not the fragment. |
| `{{CONTENTS}}` | the generated chapter/module contents directory (chapter heads + module cards, links for linkable, dimmed cards for the rest) | only on the **course contents page** (`/elixir/course`), inside a section that hosts the directory. A normal lesson fragment does not use it. |
| `{{CHAPTERS_JSON}}` | a JSON array of the F1–F6 chapters (id, name, route, live flag, module count, one-liner) for the interactive arc | only on a **landing page** that renders the interactive chapter arc, embedded in that page's script. A normal lesson fragment does not use it. |
| `{{BUILD_ID}}` | a freshly minted fourteen-character branded Snowflake id | in the footer build stamp, as the `#stampId` text. |
| `{{BUILD_TS}}` | the decoded UTC timestamp of `{{BUILD_ID}}` | in the footer build stamp, as the `#st-ts` `<dd>` default. |
| `{{MODULE_COUNT}}` | the spine module count (54 — the F1–F6 modules; F0 is excluded) | in landing/marketing copy that states the course size. A normal lesson fragment does not use it. |

A leaf lesson uses only `{{BUILD_ID}}` and `{{BUILD_TS}}` (both in the footer); `{{TITLE}}` and `{{DESC}}` are supplied to the head by the builder. The remaining three placeholders are for the contents and landing pages.

## Canonical leaf-lesson fragment

The structure to write, with the seven-part lesson order called out. Replace the bracketed guidance; keep the containers and the placeholders.

```html
<a class="skip" href="#main">Skip to the lesson</a>

<header class="site">
  <div class="wrap">
    <a class="brand" href="/elixir">jonnify<span class="dot"></span><span class="sub">knowledge map</span></a>
    <nav>
      <a href="/elixir/course">Contents</a>
      <span class="route-tag">/elixir/<chapter-slug>/<module-slug></span>
    </nav>
  </div>
</header>

<main id="main" class="wrap">

  <!-- 1 · LEAD -->
  <section class="hero">
    <div class="crumbs">
      <a href="/elixir/<chapter-slug>">F‹n› &middot; ‹Chapter›</a>
      <span class="sep">/</span>
      <span class="here">F‹n›.‹nn›</span>
    </div>
    <p class="eyebrow">F‹n› &middot; ‹Chapter›</p>
    <h1>‹Title, with one <span class="ex">word</span> highlighted›</h1>
    <p class="lede">‹The one thing this lesson nails, in two sentences.›</p>
    <p class="kicker">‹Frame the scope; why it matters; what later work depends on it.›</p>
    <div class="toc-mini" aria-label="On this page">
      <a href="#sec-1">‹Section 1›</a>
      <a href="#sec-2">‹Section 2›</a>
      <a href="#sec-3">‹Section 3›</a>
    </div>
  </section>

  <!-- 2–5 · IDEA, WORKED DETAIL, ELIXIR FORM, BRIDGE — repeat per concept -->
  <section id="sec-1">
    <h2>‹Concept heading›</h2>
    <div class="prose">
      <p>‹State the idea, then support it. One idea per section.›</p>
    </div>

    <dl class="deflist">
      <dt>‹term›</dt><dd>‹precise definition, on first use›</dd>
    </dl>

    <figure class="fig" aria-labelledby="figTitle1">
      <h4 id="figTitle1" style="font-family:var(--sans);font-size:.8rem;letter-spacing:.16em;text-transform:uppercase;color:var(--cream-dim);margin:0 0 1rem">‹figure caption · prompt›</h4>
      <div class="controls">
        <div class="solid-select" id="sel1" role="group" aria-label="‹what to choose›">
          <button type="button" data-k="a" data-c="gold" class="active">‹A›</button>
          <button type="button" data-k="b" data-c="blue">‹B›</button>
        </div>
      </div>

      <svg viewBox="0 0 760 200" role="img" aria-label="‹what the figure shows›">
        <!-- accurate line-art; literal hex on fill/stroke -->
      </svg>

      <pre class="code" id="code1" aria-live="polite"><span class="op">[</span>1, 2, 3<span class="op">]</span>
<span class="op">|&gt;</span> <span class="fn blue">Enum.map</span>(<span class="fn gold">&amp;(&amp;1 * 2)</span>)
<span class="cmt"># =&gt; [2, 4, 6]</span></pre>

      <div class="geo-readout" id="out1" aria-live="polite">‹input &rarr; computed value &middot; label›</div>
    </figure>

    <div class="bridge">
      <div class="cell idea"><p class="lbl">Algebra</p><p>‹the idea, stated as math›</p></div>
      <div class="arrow" aria-hidden="true">&rarr;</div>
      <div class="cell elix"><p class="lbl">Elixir</p><p>‹the same idea as code›</p></div>
    </div>

    <p class="take">‹One-sentence takeaway, after the widget.›</p>
  </section>

  <!-- ...further concept sections... -->

  <!-- 6 · RECAP -->
  <section>
    <h2>What this lands</h2>
    <div class="prose">
      <p>‹Tight synthesis: what the lesson established and what it feeds.›</p>
    </div>
    <p class="note">Next: <strong><a href="/elixir/<chapter-slug>/<next-module-slug>">F‹n›.‹nn› &mdash; ‹Next title›</a></strong> &mdash; ‹one line›.</p>
  </section>

  <!-- 7 · PAGER -->
  <section>
    <nav class="pager" aria-label="Lesson navigation">
      <a class="btn ghost" href="/elixir/<chapter-slug>/<prev-route>"><span aria-hidden="true">&larr;</span>&nbsp; F‹n›.‹nn› &middot; ‹prev›</a>
      <span class="spacer"></span>
      <a class="btn" href="/elixir/<chapter-slug>/<next-route>">Next &nbsp;&middot;&nbsp; F‹n›.‹nn› ‹next› <span aria-hidden="true">&rarr;</span></a>
    </nav>
  </section>

</main>

<footer class="site-foot">
  <div class="wrap">
    <p class="colophon">Built with the jonnify dark-editorial design system. Every page carries a branded
      <b>Snowflake</b> build stamp &mdash; a namespaced, base62-encoded id that decodes to a millisecond timestamp.
      It is the same id convention used as a cross-system pivot key throughout the course.</p>
    <div class="stamp" id="stamp" role="button" tabindex="0" aria-expanded="false" aria-label="Build stamp — activate to decode">
      build <span class="id" id="stampId">{{BUILD_ID}}</span>
      <dl class="panel">
        <dt>namespace</dt><dd id="st-ns">&mdash;</dd>
        <dt>snowflake</dt><dd id="st-snow">&mdash;</dd>
        <dt>node</dt><dd id="st-node">&mdash;</dd>
        <dt>seq</dt><dd id="st-seq">&mdash;</dd>
        <dt>timestamp</dt><dd id="st-ts">{{BUILD_TS}}</dd>
      </dl>
    </div>
  </div>
</footer>

<script>
(function () {
  "use strict";
  /* widget logic: read active control, recompute the real result,
     update SVG attrs + pre.code (with a true `# => ...` line) + .geo-readout,
     then render once at load. Plus the branded-Snowflake stamp decoder. */
})();
</script>
```

After the fragment's closing `</script>`, the builder appends its own bootstrap script (adds `html.js`, reveals `.reveal` on scroll, short-circuits under reduced motion). The author does not write that.

## Hub-page variation

A hub module (e.g. F2.05 folds) keeps parts 1–5, then in place of the recap renders a **card grid** of its deep-dive subpages — one linked card per dive — followed by a synthesis. Its pager's next button starts the dive sequence (`Start &middot; ‹first dive›`) rather than the next module. Each dive card is an `<a>` to the subpage route and carries the dive id, title, and one-liner:

```html
<section id="dives">
  <h2>‹N› deep dives</h2>
  <div class="prose"><p>‹This module continues across ‹N› pages — read them in order.›</p></div>
  <div style="display:flex;flex-direction:column;gap:1rem;margin-top:1.4rem">
    <a href="/elixir/<chapter-slug>/<module-slug>/<dive-slug>" style="display:block;text-decoration:none;border:1px solid var(--line);border-radius:16px;padding:1.3rem 1.5rem;background:var(--ink-2)">
      <div style="font-family:var(--mono);font-size:.78rem;letter-spacing:.1em;color:var(--gold-bright)">F‹n›.‹nn›.‹k›</div>
      <div style="font-family:var(--serif-display);font-size:1.35rem;color:var(--cream);margin:.2rem 0 .3rem">‹dive title› <span aria-hidden="true" style="color:var(--gold)">&rarr;</span></div>
      <div style="font-family:var(--serif);color:var(--cream-soft)">‹one-line abstract›</div>
    </a>
    <!-- one card per dive -->
  </div>
</section>
```

Only link dive cards whose parent module is linkable (live or built); see `course-map.md` and the `links` gate in `apollo-gates.md`.
