---
name: mesh-writer
description: Author and revise the "EchoMesh, In Depth" course manuscript — markdown chapters, dives, landing, and TOC taught from the CAP theorem — to the A+ quality gates. Use whenever the user asks to write, continue, extend, relink, review, fix, or validate an EchoMesh course page (mesh.landing.md, mesh.toc.md, a chapter landing mesh.[N].md, or a dive mesh.[N].[D].md), or asks for the overview, a chapter, or a dive on CAP, segmentation, the stack, or transparent infrastructure here — even when the word EchoMesh is absent. Also for chapter restructures, supersession amendments, and figure or voice audits of existing pages. Enforces the voice gates, NO-INVENT grounding, the PROPOSED-EchoMesh discipline, references verified against the CAP canon, the landing-plus-three-dives structure, and the ship loop (sweep, TOC update, archive refresh, present). Do NOT use for the measured BCS article series (bcsN.md — that is bcs-writer), the jonnify Elixir HTML course, or unrelated Elixir/Word/PDF work.
---

# Mesh Writer

Authors the EchoMesh, In Depth course manuscript at the established bar: grounded, voice-gated, taught from the CAP literature, candid about what is shipped versus proposed, and shipped through the same loop every time. The deliverable is always Writerside-friendly markdown — never a rebuild of the course system.

## Step 0 — Orient before writing a word

1. Read `mesh.toc.md` in the corpus root (default `/home/claude/mesh/`, which is also the output folder). Two things live there: the chapter's scope entry and abstract, and the **Conventions** and **Status** sections. Read all three. Conventions and any inline TOC amendment supersede everything, including examples in this skill (precedent for the sibling series: the storage target changed mid-series and the TOC amendment was the record).
2. Read `mesh.landing.md` once per session for the course thesis and the voice register, and `mesh.0.md` for the overview every later page stands on.
3. If the page touches the identity seam, ground it as the `/bcs` course's contract — the 14-byte branded identity is described and pointed at `/bcs` and the M5.3 build, never restated from memory as if this course specified it.

## The structure (fixed)

- Two file levels: a chapter landing `mesh.[N].md` (page `M[N]`) and dive articles `mesh.[N].[D].md` (pages `M[N].[D]`). The standard chapter has **three dives**, each a comprehensive article in its own right, framed by its landing.
- **M0 is the overview chapter.** It states the whole argument once on its landing and opens into three dives — the impossible result (`mesh.0.1.md`), the menu (`mesh.0.2.md`), and the mesh (`mesh.0.3.md`).
- The four CAP coping strategies are one chapter each, **M2–M5**, with **M5 — segmentation — the heart of the course**. **M8** is the synthesis and the bridge to the sibling courses.
- Every page carries a branded **`MSH…`** Snowflake build stamp in its own namespace, and the course opens onto four doors: `/art`, `/bcs`, `/echomq`, `/elixir`.

## The authoring loop

1. **Ground (NO-INVENT).** Every chapter, dive, file, module, and figure named must exist in the corpus, an upload, or a committed output. Surfaces a later chapter will build are written as plain prose in inline code (`mesh.5.md`), never as markdown links. EchoMesh is taught as a **PROPOSED** composition of shipped pieces until it ships; the shipped substrate (the BEAM, Postgres with `Ecto.Multi`, Tigris, Fly Machines, the FLAME pattern, EchoMQ, EchoCache) is named as real. Read `references/conventions.md` for the full grounding and linking rules.
2. **Verify externals.** Every claim about software, history, or distributed-systems theory that did not originate in this project gets a web_search or web_fetch hit in the current session before it is written, and a numbered reference. The CAP reference canon in `references/conventions.md` is the reusable source list — reuse the entries, but re-verify each URL this session. Primary sources over aggregators. No verified URL, no claim.
3. **Author.** Start from `references/article-template.md`. Writerside markdown; first line `# EchoMesh, In Depth · {chapter/dive title}`; second line `<show-structure depth="2"/>`; prose-led, bullets only for the navigational map and the doors. A dive opens with a one-paragraph blockquote lede and a `## Scope and method` that names what is cited versus stated as design and what is out of frame. Most orientation dives carry no measurement and say so; a chapter that quotes figures commits its `.out` files first and traces every number to them.
4. **Mark real versus proposed.** Every chapter landing and the mesh dives carry a candid line separating the shipped pieces from the proposed composition, and defer the full separation to the synthesis (M8.2). Losses are named beside wins.
5. **Gate.** Run the sweep and do not ship a failure:

   ```bash
   python3 scripts/sweep.py path/to/mesh.N.D.md
   ```

   It checks the forbidden-voice list, exclamation marks, reference bijection (every `[n]` cited has a listed `n.` and vice versa, per file — so dives renumber references locally `1..k`), relative-link resolution (every non-http link must resolve on disk from the page's directory), and quote length. Pass `--figures "a,b" --outs x.out,y.out` only on a chapter that quotes measured numbers.
6. **Integrate and ship.** Update `mesh.toc.md`: flip the page's status, link the file, and adjust the dive tally; record any supersession as an inline TOC amendment naming what it replaces. Refresh the production archive, copy deliverables to `/mnt/user-data/outputs/`, and `present_files` with the new page first. When the user asks for the article, include the page's markdown in the response as well as the file.

## Hard gates (memorize; the sweep enforces)

No: revolutionary, blazing, magical, simply, just, obviously, effortless, actually, genuinely, honestly, easy, seamless, powerful, honest/honesty. Use "candid" for that last sense. No exclamation marks. EchoMesh written as PROPOSED, its pieces as real. A real-versus-proposed line on every chapter landing and mesh dive. References verified this session and bijective per file. Links resolve or are inline-code prose. The doors and the `MSH…` stamp present where the page is a landing.

## Bundled resources

- `references/conventions.md` — the complete gate set, the CAP reference canon, the structure rules, the PROPOSED-EchoMesh and identity-seam discipline, and the ship-loop tail with the archive command.
- `references/article-template.md` — the landing and dive skeletons with inline guidance.
- `scripts/sweep.py` — the executable gate; exit 0 is the only shippable state.
