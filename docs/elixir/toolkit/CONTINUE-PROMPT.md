# Continue the jonnify "Functional Programming in Elixir" course — paste this into a new chat

> Attach `jonnify-elixir-toolkit.zip` to the new conversation, then paste everything below.

---

I'm continuing my **"Functional Programming in Elixir"** course, built on the **jonnify dark-editorial design
system** (live at https://jonnify.fly.dev/elixir). The complete authoring toolkit is in the attached
`jonnify-elixir-toolkit.zip`. This is a static-HTML course graded **A+ across nine Apollo quality gates**, authored
through a Python build system — never a hand-rolled page and never a rebuild of the system.

## First, set up the workspace (do this before anything else)

1. Extract the attached zip so the tree lives at `/home/claude/elixir-course/`:
   ```bash
   mkdir -p /home/claude && cd /home/claude
   unzip -o /mnt/user-data/uploads/jonnify-elixir-toolkit.zip -d /home/claude
   cd /home/claude/elixir-course && python3 build_page.py routes | tail -3
   ```
2. **Read these three files, in order, before authoring anything:**
   - `elixir-course/SKILL.md` — the operational guide (page anatomy, the nine gates, ID tooling, workflow).
   - `elixir-course/course-authoring-playbook.md` — the full reference (design tokens, char-escaping rules,
     navigation conventions, validator semantics).
   - `elixir-course/elixir-progress.md` — the tracker. Its **"Resume point and next actions"** section is the
     source of truth for what to build next and how.

## Current state (May 2026)

`build_page.py` is the single source of truth (manifest + assembler + 9 gates + branded-Snowflake ID tools).
Built and A+: all of F3, the F4 landing, and **F4.01–F4.04 + F4.06**. **F4.05 (HAMT) was deliberately skipped and
is still `planned`** — so its route `/elixir/algorithms/hamt` is unlinkable, which is why F4.06's hub pager points
back to the chapter overview and its predecessor/next notes (F4.05, F4.07) are unlinked.

**Resume point: author F4.05 — Hash Array Mapped Tries (HAMT)** (`slug` "hamt", three dives: bitmap / index /
sharing), the remaining gap in the persistent-maps spine. After F4.05, **F4.07 — Branded CHAMP maps**
(`slug` "branded-champ") closes the spine. Follow the tracker's step list exactly; it includes the relinking work
(F4.04→F4.05 forward pointers, F4.06's predecessor notes, the F4 landing F4.05 card).

## House rules (do not drift from these)

- **Every page must grade A+ on all nine Apollo gates.** Build with `python3 build_page.py build --page <key>`.
- **Voice gate trap:** the forbidden words (`revolutionary|blazing|magical|simply|just|obviously|effortless`) are
  checked against *visible* text — and a `<pre class="code">` block **is visible** (only `<script>`/`<style>`/`<svg>`
  are stripped). A stray "just"/"simply" in a *static code comment* fails the gate. Sweep with
  `grep -onE '\b(revolutionary|blazing|blazingly|magical|simply|just|obviously|effortless)\b'` over each fragment.
- **Branded Snowflake IDs everywhere:** integer Snowflake + base62-encoded branded form with a 3-char namespace
  prefix (e.g. `TSK0KHTOWnGLuC`). Mint/decode with `python3 build_page.py id mint` and `… id decode <ID>`. The
  course's worked examples use a `PGE` (page) namespace, e.g. `PGE0NbWMtkolM0`.
- **Links gate:** every internal `href` must resolve to a real `live`/`built` route. Don't link a module that
  isn't built yet — name it in a note as "(in production)" instead.
- **Real-world framing:** ground each module's worked example in the course's own practical project — the Phoenix
  LiveView data layer (page registry map keyed by branded ids, route sets behind the links gate) and, for the
  spine, the stack's **BrandedChamp trie**.
- Each F4 dive = one teaching section + one advanced section. Match the existing pages' structure and the **sage**
  F4 accent (`.ex`/`code.inl` stay the global Elixir purple). `node --check` every page's `<script>`.
- Output must be **Writerside-markdown-friendly** for publishing.

## The per-module loop (from the playbook)

1. Author hub + dive fragments into `content/` (copy an existing F4 module's fragment as the structural template).
2. Promote the module in `build_page.py`: `status` → `built`, add `SUBPAGES[...]`, register `PAGES` with unique
   output filenames; verify routes with `python3 build_page.py routes`.
3. Build to A+, voice-sweep (incl. static code comments), `node --check` each script.
4. Relink predecessor forward-pointers and the F4 landing card (see the tracker for the exact targets).
5. Append a tagged block to `validator/suite.elixir.js` (desktop assertions + a mobile-sweep loop entry), then run
   `BASE_URL="file:///home/claude/elixir-course" ONLY="<module>" node validator/suite.elixir.js` → expect
   **0 FAIL, 0 images**.
6. Regenerate both docs: `python3 _gen_course_md.py` and `python3 _gen_refs_md.py` (both must report a clean voice
   gate).
7. Update `elixir-progress.md` (table rows, narrative, validation evidence, headline counts, resume point), then
   `present_files` the built pages + the chapter overview + the tracker.

Start by extracting the zip, reading the three files above, and then authoring **F4.05 — HAMT** per the tracker.
