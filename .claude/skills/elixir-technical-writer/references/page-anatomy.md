# Page anatomy

The skeleton of a course page. An author writes the **body fragment** — everything between `<body>` and the bootstrap script. The builder prepends `<!doctype html>` + `<html lang="en">` + the shared `<head>`, opens `<body>`, and appends the bootstrap `<script>`. This file lists the head block the builder supplies, the containers a fragment must use, the build-stamp footer, and the exact pager HTML. Markup below is copied from the built pages.

## What the builder supplies (do not author these)

The shared `<head>` carries the meta, the Google Fonts link, and the full `<style>` with the design tokens and base CSS. Its open is:

```html
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{TITLE}}</title>
<meta name="description" content="{{DESC}}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,500;1,600&family=PT+Serif:ital,wght@0,400;0,700;1,400&family=Manrope:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<style> /* :root tokens + base CSS — see design-tokens.md */ </style>
</head>
```

The builder also appends the progressive-enhancement bootstrap: it adds `html.js`, then reveals `.reveal` elements via `IntersectionObserver`, short-circuiting to "show all" under reduced motion or when `IntersectionObserver` is absent. The author writes neither the head nor the bootstrap — only the body fragment between them.

## The body fragment, top to bottom

### 1. Skip link + sticky site header

```html
<a class="skip" href="#main">Skip to the lesson</a>

<header class="site">
  <div class="wrap">
    <a class="brand" href="/elixir">jonnify<span class="dot"></span><span class="sub">knowledge map</span></a>
    <nav>
      <a href="/elixir/course">Contents</a>
      <span class="route-tag">/elixir/algebra/functions</span>
    </nav>
  </div>
</header>
```

The `.route-tag` mirrors this page's own clean route.

### 2. Main wrap

```html
<main id="main" class="wrap">
  ... sections ...
</main>
```

`main#main.wrap` is the single content column (`max-width:1080px`, centred). Every `section` is a direct child; adjacent sections get a top hairline automatically (`section + section`).

### 3. Hero section (the Lead)

```html
<section class="hero">
  <div class="crumbs">
    <a href="/elixir/algebra">F1 &middot; Algebra</a>
    <span class="sep">/</span>
    <span class="here">F1.01</span>
  </div>
  <p class="eyebrow">F1 &middot; Algebra</p>
  <h1>What a function <span class="ex">really</span> is</h1>
  <p class="lede">Before any syntax: a function is a rule that assigns to every input exactly one output...</p>
  <p class="kicker">The word is overloaded in everyday programming... Get this right and composition, purity, and higher-order code all follow.</p>
  <div class="toc-mini" aria-label="On this page">
    <a href="#mapping">A mapping</a>
    <a href="#one-output">Exactly one output</a>
    <a href="#first-class">Functions are values</a>
  </div>
</section>
```

The `.crumbs` show the chapter path to this page; `.here` is the current id (non-link). One `<h1>` per page; `<span class="ex">` highlights a word in elixir-bright italic. `.toc-mini` anchors to the on-page section ids.

### 4. Content sections (the body of the lesson)

Each concept is one `<section id="...">` containing:

- an `<h2>` heading;
- a `.prose` block (`max-width: var(--measure)`);
- a `.deflist` (`<dl>`) defining terms on first use;
- a `.fig` figure (see `visualization-master.md`) with its `<svg>`, a `pre.code` block, and a `.geo-readout`;
- a `.bridge` pairing the idea with its Elixir form;
- a closing `.take` one-sentence takeaway.

```html
<section id="mapping">
  <h2>A function is a mapping</h2>
  <div class="prose"> <p>...</p> </div>
  <dl class="deflist"> <dt>domain</dt><dd>...</dd> </dl>

  <figure class="fig" aria-labelledby="mapTitle">
    <h4 id="mapTitle" style="...">The mapping &middot; choose a function</h4>
    <div class="controls"> <div class="solid-select" id="mapSel" role="group"> ... </div> </div>
    <svg viewBox="0 0 720 340" role="img" aria-label="..."> ... </svg>
    <pre class="code" id="mapCode" aria-live="polite"> ... # =&gt; [4, 1, 0, 1, 4] </pre>
    <div class="geo-readout" id="mapOut" aria-live="polite"> ... </div>
  </figure>

  <div class="bridge">
    <div class="cell idea"><p class="lbl">Algebra</p><p>...</p></div>
    <div class="arrow" aria-hidden="true">&rarr;</div>
    <div class="cell elix"><p class="lbl">Elixir</p><p>...</p></div>
  </div>

  <p class="take">Two inputs can share an output, but no input has two...</p>
</section>
```

Every `.fig`, `.bridge`, and block-level `<div>` must be balanced — the Apollo `containers` gate stacks block-level container tags and fails on the first unbalanced close or any unclosed open. A common failure is an unclosed `.wrap` inside a section; close it before `</section>`.

### 5. Synthesis section (the Recap)

```html
<section>
  <h2>What this lands</h2>
  <div class="prose"> <p>One definition did the work...</p> </div>
  <p class="note">Next: <strong><a href="/elixir/algebra/substitution">F1.02 &mdash; The substitution model</a></strong> &mdash; equals for equals...</p>
</section>
```

`.note` (blue left border) points at the next module. Three-to-five-bullet recaps may use a `<ul>` instead of the prose paragraph.

### 6. Pager section (Prev / Next) — exact HTML

A ghost prev button, a flex `.spacer`, and a solid next button. Both `href`s point at real, built routes (the `links` and `pager` gates check this).

```html
<section>
  <nav class="pager" aria-label="Lesson navigation">
    <a class="btn ghost" href="/elixir/algebra"><span aria-hidden="true">&larr;</span>&nbsp; F1 &middot; Algebra</a>
    <span class="spacer"></span>
    <a class="btn" href="/elixir/algebra/substitution">Next &nbsp;&middot;&nbsp; F1.02 substitution <span aria-hidden="true">&rarr;</span></a>
  </nav>
</section>
```

On a hub page the next button starts the dive sequence, e.g.:

```html
<a class="btn" href="/elixir/functional/folds/map">Start &middot; map <span aria-hidden="true">&rarr;</span></a>
```

### 7. Footer with the build stamp — exact HTML

The fragment closes `</main>` then carries the footer. The `{{BUILD_ID}}` placeholder is filled with a freshly minted branded Snowflake id and `{{BUILD_TS}}` with its decoded timestamp; the bootstrap-adjacent decoder in the page script expands the panel on click.

```html
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
```

The page script (an IIFE with `"use strict"`, before the builder's bootstrap) holds all widget logic plus the branded-Snowflake decoder that fills the stamp panel. The decoder uses the base62 alphabet `0-9 A-Z a-z`, the epoch `1704067200000`, and the layout `timestamp(41) << 22 | node(10) << 12 | seq(12)`.

## Container inventory (the names a fragment uses)

`.wrap`, `main#main.wrap`, `section` (`.hero`, synthesis, pager), `.prose`, `.fig`, `.bridge` (`.cell.idea` / `.cell.elix` / `.arrow`), `.take`, `.pager` (`.btn` / `.btn.ghost` / `.spacer`), plus support: `.crumbs`, `.eyebrow`, `.lede`, `.kicker`, `.toc-mini`, `.deflist`, `.geo-readout`, `.controls`, `.solid-select`, `.fold-ctrl`, `pre.code`, `code.inl`, `.note`, `.site`, `.site-foot`, `.stamp`. Hub pages additionally use `.dive` / `.dive-head` / `.dive-tag` for subpage sections and a card grid for the dive directory.
