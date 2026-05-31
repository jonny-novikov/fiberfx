# References section — authoring convention

Every module content page carries one **References** block at its foot: authoritative
external sources for the lesson's topic, plus convenient cross-links to related course
modules. It is additive — it never alters existing lesson content.

## Placement

A single new `<section class="reveal">` placed **after** the recap / "What this lands"
section and **before** the pager `<section>`. One per page.

## Markup

```html
<section class="reveal" aria-labelledby="refsTitle">
  <h2 id="refsTitle">References</h2>
  <p class="prose">Primary sources for this lesson, and where it connects in the course.</p>
  <div class="refs">
    <h3>Sources</h3>
    <ul>
      <li><a href="https://hexdocs.pm/elixir/Enum.html"><code>Enum</code> — Elixir documentation</a></li>
      <li>Hutton, G. (1999). <em>A tutorial on the universality and expressiveness of fold.</em></li>
    </ul>
    <h3>Related in this course</h3>
    <ul>
      <li><a href="/elixir/functional/recursion">F2.04 · Recursion patterns &amp; tail calls</a></li>
    </ul>
  </div>
</section>
```

If the page lacks a `.refs` rule, add a small scoped block to the page's `<style>`
(style blocks are gate-exempt), using the design tokens — `--line` for the divider,
`--cream-dim` for meta, `--elixir`/`--gold` for link accents, `--mono` for `code`.

## Content rules

**Sources (2–4).** Authoritative, external, canonical. Use only stable URLs:
- Official docs — `https://hexdocs.pm/elixir/<Module>.html`, `https://elixir-lang.org/…`, `https://www.erlang.org/…`
- Reference encyclopaedia — `https://en.wikipedia.org/wiki/<Topic>`
- Books / papers — cite by author, year, and title (no fragile deep links).

Accuracy is non-negotiable: cite real sources. When a precise URL is uncertain, cite by
author and title **without** a link rather than fabricate one.

**Related in this course (1–3).** Cross-links to related modules. Internal links MUST
point only to **live / built** routes — the same allow-list the `links` gate enforces.
Never link a `planned` route.

## Gate safety (the block must keep the page at A+)

- External `https://` links are exempt from the `links` gate; internal links must be allowed routes.
- No `/future` substring anywhere (the `no-future` gate).
- Keep every container balanced; the section carries `reveal`, already JS-gated by the shared head.
- No `localStorage` / `sessionStorage`.

Validate with `cms check <file>` after editing; the page must still report `STATUS: PASS`, `grade: A+`.
