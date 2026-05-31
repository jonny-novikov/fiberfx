// elixir-refs-rollout — the "update" half of the progress.md-triggered course pipeline.
//
// Bibliography-driven References rollout: for a list of pages that lack the gated
// References block, fan out one insert agent per page (sources taken VERBATIM from the
// already-generated bibliography docs/elixir/kb/elixir-references.md, keyed by module),
// then an INDEPENDENT adversarial verify that re-reads from disk and re-runs `cms check`.
//
// This is the scalable successor to the curated elixir-references.js (which hand-authored
// F0/F2 + created the F0 landing). Here the bibliography is the source of truth, so the
// same script handles any chapter.
//
// USAGE (hybrid — scout the worklist inline, then pipeline over it):
//   1. Pause the watcher:  bash docs/elixir/references/watch_refs.sh stop
//   2. Reconcile + nav-sync are DETERMINISTIC and done inline BEFORE this workflow:
//        cd docs/elixir/kb && python3 promote.py --rebuild      # manifest <-> fs <-> gates
//        (then surgically sync any stale contents-page cards to the manifest)
//   3. Scout the pages lacking a block, e.g.:
//        for f in $(find elixir/<chapter> -name '*.html' | grep -v fragments); do
//          grep -q 'id="refsTitle"' "$f" || echo "$f"; done
//   4. Run:  Workflow({ name: 'elixir-refs-rollout', args: [{p:'elixir/.../x.html', m:'F3.05'}, ...] })
//   5. After it lands: cms audit + batch cms check, then re-baseline + restart the watcher.
//
// args: an array of { p: <repo-relative page path>, m: <module id, e.g. "F3.05"> }.
//       If omitted, falls back to the F3 set below (already rolled out — kept as a worked example).

export const meta = {
  name: 'elixir-refs-rollout',
  description: 'Insert gated References blocks into the given course pages from the existing bibliography; each page adversarially re-verified to stay A+.',
  phases: [
    { title: 'References', detail: 'one agent per page inserts its References block + self-checks cms A+' },
    { title: 'Verify', detail: 'an independent agent re-reads from disk and adversarially re-checks each page' },
  ],
}

const ROOT = '/Users/jonny/dev/jonnify'

// Worked-example fallback: the F3 (The Elixir Language) chapter.
const DEFAULT_PAGES = [
  { p: 'elixir/language/values.html', m: 'F3.01' },
  { p: 'elixir/language/match/index.html', m: 'F3.02' },
  { p: 'elixir/language/match/operator.html', m: 'F3.02' },
  { p: 'elixir/language/match/branching.html', m: 'F3.02' },
  { p: 'elixir/language/match/destructuring.html', m: 'F3.02' },
  { p: 'elixir/language/structs/index.html', m: 'F3.05' },
  { p: 'elixir/language/structs/define.html', m: 'F3.05' },
  { p: 'elixir/language/structs/defaults.html', m: 'F3.05' },
  { p: 'elixir/language/structs/matching.html', m: 'F3.05' },
  { p: 'elixir/language/protocols/index.html', m: 'F3.06' },
  { p: 'elixir/language/protocols/define.html', m: 'F3.06' },
  { p: 'elixir/language/protocols/defimpl.html', m: 'F3.06' },
  { p: 'elixir/language/protocols/behaviours.html', m: 'F3.06' },
  { p: 'elixir/language/processes/index.html', m: 'F3.07' },
  { p: 'elixir/language/processes/spawn.html', m: 'F3.07' },
  { p: 'elixir/language/processes/messages.html', m: 'F3.07' },
  { p: 'elixir/language/processes/state.html', m: 'F3.07' },
  { p: 'elixir/language/otp/index.html', m: 'F3.08' },
  { p: 'elixir/language/otp/genserver.html', m: 'F3.08' },
  { p: 'elixir/language/otp/call-cast.html', m: 'F3.08' },
  { p: 'elixir/language/otp/supervisors.html', m: 'F3.08' },
  { p: 'elixir/language/playground.html', m: 'F3.09' },
]

const PAGES = (Array.isArray(args) && args.length) ? args : DEFAULT_PAGES
const short = (pg) => pg.p.replace(/^elixir\//, '')

const INSERT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['path', 'module', 'inserted', 'grade', 'sources_count', 'related_routes'],
  properties: {
    path: { type: 'string' },
    module: { type: 'string' },
    inserted: { type: 'boolean' },
    grade: { type: 'string' },
    sources_count: { type: 'integer' },
    related_routes: { type: 'array', items: { type: 'string' } },
    note: { type: 'string' },
  },
}

const VERDICT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['path', 'pass', 'grade', 'single_block', 'placement_ok', 'links_ok', 'issues'],
  properties: {
    path: { type: 'string' },
    pass: { type: 'boolean' },
    grade: { type: 'string' },
    single_block: { type: 'boolean' },
    placement_ok: { type: 'boolean' },
    links_ok: { type: 'boolean' },
    issues: { type: 'array', items: { type: 'string' } },
  },
}

const insertPrompt = (pg) => `A gated "References" block must be added to ONE Elixir course page. Edit ONLY this file:
  ${ROOT}/${pg.p}        (course module ${pg.m})

Read first (do NOT edit these):
  - Spec:         ${ROOT}/.claude/skills/elixir-technical-writer/references/references-section.md
  - Bibliography: ${ROOT}/docs/elixir/kb/elixir-references.md  — locate the "${pg.m}" section; ITS bullet entries are the approved sources (each is a real URL + description, or an author+title citation).
  - Exemplar:     ${ROOT}/elixir/language/enum-streams/enum.html  — reproduce the <section ... id="refsTitle"> shape and its scoped .refs <style> rule.

Do, in order:
  1. Insert exactly ONE <section class="reveal" aria-labelledby="refsTitle"> … </section> block, placed AFTER the page's recap / "what this lands" section and immediately BEFORE the <nav class="pager"> section. One such block per page — if one already exists, correct it in place, never add a second.
  2. Sources (2–4): take them verbatim from the "${pg.m}" bibliography entry. Use only its stable URLs (hexdocs.pm / elixir-lang.org / erlang.org / wikipedia.org) or author+year+title with NO link. Never invent or guess a URL.
  3. "Related in this course" (1–3): internal links to LIVE / built routes ONLY. Obtain the allow-list with:  cd ${ROOT}/apps/jonnify-cms && GOWORK=off ./bin/cms routes . Never link a planned route — specifically NOT /elixir/language/modules (F3.03 has no page) and nothing under a planned chapter.
  4. If the page has no .refs style rule, add a small scoped one to its <style> using the design tokens (--line, --cream-dim, --elixir, --gold, --mono). Style blocks are gate-exempt.
  5. Validate:  cd ${ROOT}/apps/jonnify-cms && GOWORK=off ./bin/cms check ${ROOT}/${pg.p}  — it MUST print "grade: A+" and "STATUS: PASS". Repair until it does.

Register of every word added: impersonal — no first-person ("we" / "our" / "I"), no perceptual verbs taking a tool or code subject, no hype or dismissive adjectives. Apply these same constraints to anything you generate.

Return the structured result only.`

const verifyPrompt = (pg) => `Adversarially verify the References block on ONE page. Treat it as wrong until each check proves otherwise. Re-read the file from disk; do NOT edit it.
  File: ${ROOT}/${pg.p}   (module ${pg.m})

Run every check:
  1. Gate:  cd ${ROOT}/apps/jonnify-cms && GOWORK=off ./bin/cms check ${ROOT}/${pg.p}  — must print "grade: A+" and "STATUS: PASS"; else pass=false.
  2. Exactly ONE occurrence of id="refsTitle" on the page (grep -c). 0 or >1 ⇒ single_block=false.
  3. Placement: the block sits AFTER the lesson recap and BEFORE <nav class="pager">, not nested inside another <section>, all containers balanced ⇒ placement_ok.
  4. Links: every internal href inside the block resolves to a LIVE / built route — cross-check against  GOWORK=off ./bin/cms routes . Any link to a planned route or any "/future" substring ⇒ links_ok=false.
  5. Sources: 2–4 entries, each a stable URL or an unlinked author+title; any fabricated/guessed deep link ⇒ fail.

pass=true only if ALL checks hold. Otherwise list each concrete issue in "issues". Keep output impersonal; apply the same constraints to anything you generate.`

log(`refs rollout: ${PAGES.length} pages, insert -> adversarial verify`)

const results = await pipeline(
  PAGES,
  (pg) => agent(insertPrompt(pg), { label: `refs:${short(pg)}`, phase: 'References', schema: INSERT_SCHEMA }),
  (ins, pg) => agent(verifyPrompt(pg), { label: `verify:${short(pg)}`, phase: 'Verify', schema: VERDICT_SCHEMA, model: 'sonnet' })
    .then((v) => ({ ...v, module: pg.m, insert: ins }))
)

const done = results.filter(Boolean)
const passed = done.filter((r) => r.pass)
const failed = done.filter((r) => !r.pass)
const dropped = PAGES.filter((_, i) => !results[i])

log(`done: ${passed.length}/${PAGES.length} verified A+ · ${failed.length} flagged · ${dropped.length} dropped`)

return {
  total: PAGES.length,
  verified_A_plus: passed.length,
  flagged: failed.map((r) => ({ path: r.path, grade: r.grade, single_block: r.single_block, placement_ok: r.placement_ok, links_ok: r.links_ok, issues: r.issues })),
  dropped: dropped.map((pg) => pg.p),
}
