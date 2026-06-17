export const meta = {
  name: 'elixir-author',
  description: 'Fan out writer subagents to author planned Elixir course modules using the elixir-technical-writer skill, then gate each page through the nine Apollo A+ checks (cms check). Drafts land in apps/jonnify-cms/drafts/ — they are NOT written into the live /elixir tree.',
  phases: [
    { title: 'Author', detail: 'one writer subagent per module produces a complete A+ page' },
    { title: 'Gate', detail: 'cms check runs the nine gates; failures trigger a bounded remediate loop' },
  ],
}

// ---------------------------------------------------------------------------
// Worklist. Each entry carries the metadata an author needs and, crucially, a
// prevRoute that is already a live/built (allowed) route so the page can pass
// the manifest-driven `links` and `pager` gates without depending on sibling
// planned pages. Extend this table as chapters open up.
// ---------------------------------------------------------------------------
const WORKLIST = {
  'F2.09': { route: '/elixir/functional/pipeline-lab', slug: 'pipeline-lab', chapter: 'F2 · Functional Programming',
    title: 'The data-pipeline lab', one: 'Compose map/filter/reduce over a dataset and watch each stage transform the value.',
    lab: true, prevRoute: '/elixir/functional/folds', prevLabel: 'F2.05 · folds' },
  'F3.01': { route: '/elixir/language/values', slug: 'values', chapter: 'F3 · The Elixir Language',
    title: 'Values, types & IEx', one: 'The data Elixir programs are built from, and the IEx shell as the primary tool for exploring them.',
    lab: false, prevRoute: '/elixir/functional', prevLabel: 'F2 · Functional Programming' },
  'F3.02': { route: '/elixir/language/match', slug: 'match', chapter: 'F3 · The Elixir Language',
    title: 'Pattern matching & the match operator', one: 'The match operator: = binds by matching structure rather than assigning.',
    lab: false, prevRoute: '/elixir/functional', prevLabel: 'F2 · Functional Programming' },
  'F3.03': { route: '/elixir/language/modules', slug: 'modules', chapter: 'F3 · The Elixir Language',
    title: 'Functions, modules & the pipe', one: 'Defining functions inside modules and composing them with the pipe.',
    lab: false, prevRoute: '/elixir/functional', prevLabel: 'F2 · Functional Programming' },
}

const DRAFTS = 'apps/jonnify-cms/drafts'
const CMS = 'apps/jonnify-cms/bin/cms'

// Which modules to author this run. args may be an array of F-ids; default to a
// single tractable proof (F3.01) so an unparameterised run stays cheap.
const ids = (Array.isArray(args) && args.length ? args : ['F3.01']).filter((id) => WORKLIST[id])
log(`authoring ${ids.length} module(s): ${ids.join(', ')} -> ${DRAFTS}/`)

const GATE_SCHEMA = {
  type: 'object',
  required: ['pass', 'failedGates', 'detail'],
  properties: {
    pass: { type: 'boolean', description: 'true only when STATUS: PASS (all nine gates pass)' },
    failedGates: { type: 'array', items: { type: 'string' }, description: 'names of any failing gates' },
    attempts: { type: 'number' },
    detail: { type: 'string', description: 'the final cms check STATUS line and any remaining failures' },
  },
}

function authorPrompt(id, m) {
  return `Author one complete, standalone HTML lesson page for the Elixir course module ${id} — "${m.title}" (${m.chapter}), served at the clean route ${m.route}.

First read the skill that governs this work and apply it in full:
- /Users/jonny/dev/jonnify/.claude/skills/elixir-technical-writer/SKILL.md
- every file under /Users/jonny/dev/jonnify/.claude/skills/elixir-technical-writer/references/ (technical-writer, visualization-master, design-tokens, page-anatomy, apollo-gates, course-map, lesson-template)

Module abstract: ${m.one}
${m.lab ? 'This is the chapter LAB (capstone): the interactive component is the centrepiece.' : 'This is a standard lesson: one focused interactive component supports the prose.'}

Write a COMPLETE document (\`<!doctype html>\` through \`</html>\`) — do not rely on an external build step. It must clear all nine Apollo A+ gates, so it MUST:
1. containers — every <div>/<section>/<main>/<header>/<footer>/<nav>/<figure> balanced.
2. svg — at least one well-formed inline <svg> ... </svg> (the teaching visual).
3. no-future — contain no "/future" substring anywhere.
4. voice — no hype/dismissive words: revolutionary, blazing-fast, magical, simply, just, obviously, effortless.
5. storage — no localStorage or sessionStorage.
6. motion — the CSS must include a "prefers-reduced-motion" rule.
7. degrade — if any element uses class "reveal", gate it with a "html.js .reveal" selector so content is visible without JS.
8. links — every internal href MUST be one of these allowed routes ONLY: ${m.prevRoute}, /elixir, /elixir/functional, /elixir/algebra, /elixir/course. Do NOT link to any planned/sibling route.
9. pager — include <nav class="pager"> whose previous link is <a ... href="${m.prevRoute}">${m.prevLabel}</a>; the forward link, if any, must also be an allowed route (use /elixir for "back to the map").

Use the jonnify dark-editorial design tokens from design-tokens.md (inline <style> with the full :root palette), the page skeleton from page-anatomy.md (.wrap, main#main.wrap, section, .hero, .prose, .fig, pager), one interactive inline-JS + inline-SVG widget that computes the real result (no libraries, no storage), a "prefers-reduced-motion" media query, and a footer build stamp.

Write the finished file to /Users/jonny/dev/jonnify/${DRAFTS}/${m.slug}.html (create the directory if needed). Return only the absolute path you wrote.

Prose discipline (apply to the page AND your output): no gendered pronouns for tools/agents, no perceptual verbs with tool/agent subjects, no first-person narration, none of the forbidden words above. Enforce the same in anything you emit.`
}

function gatePrompt(id, m, path) {
  return `Validate the authored page for ${id} at ${path} against the nine Apollo A+ gates by running (${path} is an ABSOLUTE path; the cms binary is built by \`make build\`):
    cd /Users/jonny/dev/jonnify/apps/jonnify-cms && GOWORK=off ./bin/cms check ${path}

If STATUS is PASS, report pass=true. If STATUS is FAIL, edit ${path} in place to fix ONLY the named failing gates (keep the lesson intact), then re-run cms check. Repeat at most twice. Report the final verdict.

Allowed internal routes for the links/pager gates are exactly: ${m.prevRoute}, /elixir, /elixir/functional, /elixir/algebra, /elixir/course. Never introduce a link outside that set.

Prose discipline: impersonal, precise; no first-person narration, no perceptual verbs with tool subjects, none of the hype/dismissive words. Return the structured verdict.`
}

const results = await pipeline(
  ids.map((id) => ({ id, m: WORKLIST[id] })),
  // Stage 1 — author (one writer subagent per module).
  async ({ id, m }) => {
    const path = await agent(authorPrompt(id, m), { label: `author:${id}`, phase: 'Author' })
    return { id, m, path: (path || '').trim() }
  },
  // Stage 2 — gate + bounded remediate.
  async (authored, { id, m }) => {
    const path = authored && authored.path ? authored.path : `/Users/jonny/dev/jonnify/${DRAFTS}/${m.slug}.html`
    const verdict = await agent(gatePrompt(id, m, path), { label: `gate:${id}`, phase: 'Gate', schema: GATE_SCHEMA })
    return { id, title: m.title, route: m.route, path, verdict }
  },
)

const ok = results.filter((r) => r && r.verdict && r.verdict.pass)
log(`done: ${ok.length}/${results.length} pages reached A+`)
return { authored: results.length, passed: ok.length, results }
