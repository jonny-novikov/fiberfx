# Continue the jonnify "Functional Programming in Elixir" course — paste this into a new chat

---

I'm continuing my **"Functional Programming in Elixir"** course, built on the **jonnify dark-editorial design
system** (live at https://jonnify.fly.dev/elixir). The complete authoring toolkit is in the attached
`jonnify-elixir-toolkit.zip`. This is a static-HTML course graded **A+ across nine Apollo quality gates**, authored
through a Python build system — never a hand-rolled page and never a rebuild of the system.

## First, set up the workspace (do this before anything else)

1. Extract the attached zip so the tree lives at `/home/claude/elixir-course/`:
   ```bash
   mkdir -p /home/claude/elixir-course && cd /home/claude/elixir-course
   unzip -o /mnt/user-data/uploads/jonnify-elixir-toolkit.zip
   # the toolkit extracts into ./jonnify-elixir-toolkit/ — lift its contents up one level:
   [ -d jonnify-elixir-toolkit ] && cp -r jonnify-elixir-toolkit/* . && rm -rf jonnify-elixir-toolkit
   python3 build_page.py routes | tail -3
   ```
2. **Read these files, in order, before authoring anything:**
   - `SKILL.md` — the operational guide (page anatomy, the nine gates, ID tooling, workflow).
   - `course-authoring-playbook.md` — the full reference (design tokens, char-escaping rules, navigation
     conventions, validator semantics).
   - `elixir-progress.md` — the tracker. Its **"Resume point and next actions"** section is the source of truth
     for what to build next and how.
   - `build-guide/pragmatic.md` — the Portal build-spec TOC (conventions, branded-id contract, build prompts).

## Current state (June 2026)

`build_page.py` is the single source of truth (manifest + assembler + 9 gates + branded-Snowflake ID tools). The
**F5 chapter "Pragmatic Programming"** (slug `pragmatic`, accent **burgundy**) is live. Built and A+: the F5 landing,
the **three design subpages** (architecture / domain-model / flow), and modules **F5.01–F5.05** — each a hub plus
three dives:

- **F5.01** `/foundations` — Start thin: a running Portal from day one.
- **F5.02** `/domain` — Modeling the Portal domain (structs, contexts, public APIs).
- **F5.03** `/tracer-bullets` — Tracer bullets: a walking skeleton (enroll a learner end to end).
- **F5.04** `/contracts` — Design by contract (pre/post/invariant, assertions, fail-fast).
- **F5.05** `/cqrs` — Commands, queries & events (CQS, domain events, the engine as a reducer).

`allowed_routes()` returns **148** routes; **PAGES 147**; module tally **46 built / 13 planned**. The F5 validator
suite passes **272 (224 desktop + 48 mobile), 0 FAIL, 0 images**. Modules **F5.06–F5.09 are still `planned`** (their
routes are unlinkable, so prose references to them stay plain text).

**Resume point: author F5.06 — "Where engine state lives"** (`slug` "state", route `/elixir/pragmatic/state`),
three dives already in the manifest: **F5.06.1 Choosing where state lives** (`choosing`), **F5.06.2 The engine
GenServer** (`genserver`), **F5.06.3 Supervision** (`supervision`). It picks the process that holds the folded
state from F5.05 — GenServer / Agent / ETS — and the supervision boundary around it. After F5.06 come **F5.07
Pragmatic testing** (`testing`), **F5.08 Assembling the engine** (`engine`), and **F5.09** (the lab). REFS and
`A`-map abstracts are already keyed by each module `n`.

There is also a **`build-guide/`** folder of Writerside-markdown Portal build specs (`pragmatic.md` + one per
F5.01–F5.04, each with content, specs, actionables, and copy-paste build prompts). The toolkit norm is **markdown
first, presentation second**; an **F5.05 build guide** (`build-guide/f5-05-cqrs.md`) is the natural next markdown
addition, mirroring the existing four.

## House rules (do not drift from these)

- **Every page must grade A+ on all nine Apollo gates.** Build with `python3 build_page.py build --page <key>`,
  grade with `python3 build_page.py check <output>.html`.
- **Voice gate trap:** the forbidden words (`revolutionary|blazing|blazingly|magical|simply|just|obviously|effortless`)
  are checked against *visible* text — and a `<pre class="code">` block **is visible** (only
  `<script>`/`<style>`/`<svg>` are stripped). A stray "just"/"simply" in a *static code comment* fails the gate.
  Sweep each fragment with
  `grep -onE '\b(revolutionary|blazing|blazingly|magical|simply|just|obviously|effortless)\b'`. ("just" recurs —
  catch it every module.)
- **Branded Snowflake IDs everywhere:** integer Snowflake + Base62-encoded branded form with a 3-char namespace
  prefix (e.g. `TSK0KHTOWnGLuC`). Mint/decode with `python3 build_page.py id mint` / `… id decode <ID>`. The Portal
  uses `USR/SES/CRS/LSN/PGE/ENR/PRG`, plus `EVT` for domain events (introduced in F5.05).
- **Links gate:** every internal `href` must resolve to a real `live`/`built` route. Don't link a module that
  isn't built yet — name it in prose as plain text instead.
- **F5 accent is burgundy** (`--burgundy:#c4504c`, bright literal `#e08f8b`; there is no `--burgundy-bright` var).
  The burgundy code-token class is **`burg`** (not `burgundy`). **Dive-accent convention:** the hub's three dive
  cards take left-borders burgundy / blue / gold for dives 1 / 2 / 3; each dive PAGE is themed to its card
  (dive 1 burgundy, dive 2 blue `#5a87c4`/`#9fc0ea`, dive 3 gold `#d4a85a`/`#f0cd7f`). The **References** section
  lives on the **hub only**.
- Copy the **branded Snowflake decoder** verbatim into every fragment footer; give interactive element ids a unique
  2-letter prefix per page that does **not** start with `st`. `node --check` every page's longest `<script>`.
- Real-world framing: every F5 module advances the one running example — the **Portal** learning-platform engine
  (thin Plug/Bandit server → contexts/structs → contract-checked commands → events folded into state).
- Output must be **Writerside-markdown-friendly** for publishing.

## The per-module loop (10 steps, from the playbook)

1. Read the manifest entry + dives + `A`-map abstract + REFS for the module (titles/slugs/abstracts are already
   correct — keep them, only promote).
2. In `build_page.py`: flip the module + its 3 dives `status` → `built`, add `SUBPAGES["F5.0X"]` (3 dives), add 4
   `PAGES` entries (hub + 3 dives) with unique output filenames; parse-check and verify routes.
3. Author 4 fragments (hub + 3 dives) into `content/`, copying an existing F5 module as the structural template:
   burgundy hub, dive accents burgundy/blue/gold, decoder verbatim, unique id prefixes, References on the hub only.
4. Voice-sweep (incl. static code comments — fix any "just"); check no stray prose exclamation marks.
5. Build to A+ (`build --page <key>`), grade (`check`), `node --check` each script, confirm References on the hub
   only.
6. Promote the module's card on `content/f5-00-landing.html` (planned `<div class="mod is-quiet">` → linkable
   `<a class="mod">` + `pill built`); rebuild `pragmatic.html`.
7. Append a tagged `F5` block to `validator/suite.elixir.js` (hub + 3 dive desktop assertions) and add the 4 pages
   to the 390px mobile sweep; run `BASE_URL="file:///home/claude/elixir-course" ONLY="F5" node
   validator/suite.elixir.js` → expect **0 FAIL, 0 images**.
8. Regenerate both docs: `python3 _gen_course_md.py` and `python3 _gen_refs_md.py` (both must report a clean voice
   gate and **59/59** module references).
9. Update `elixir-progress.md` (build record, headline counts, resume point).
10. `present_files` the built hub + 3 dives + `pragmatic.html` + `elixir-progress.md` + the two regenerated docs.

## Standing deploy gap (not authoring)

The site-wide `/elixir` home and `/elixir/course` Contents live outside this tree; when deploying, push
`pragmatic.html` + all F5 `*.html` and surface the F5 chapter (bump the live module count).

Start by extracting the zip, reading the files above, then authoring **F5.06 — Where engine state lives** per the
tracker's resume point. Optionally, write the **F5.05 build guide** markdown first to keep the `build-guide/` set in
step.
