export const meta = {
  name: 'elixir-references',
  description: 'Fan out subagents across the built F0 (History) and F2 (Functional) pages to add a consistent "References" section (authoritative external sources + cross-links to related modules) and create the missing F0 chapter landing, each gated to stay A+ via cms check.',
  phases: [
    { title: 'References', detail: 'one subagent per page adds/authors the References section' },
    { title: 'Gate', detail: 'cms check confirms the page is still A+; bounded remediate on failure' },
  ],
}

const E = '/Users/jonny/dev/jonnify/elixir'
const SKILL = '/Users/jonny/dev/jonnify/.claude/skills/elixir-technical-writer'

// Curated worklist. refs = authoritative external sources (canonical/stable);
// related = cross-links to LIVE/BUILT routes only (the links-gate allow-list).
const WORKLIST = [
  { id: 'F0', action: 'create', file: `${E}/course/index.html`, route: '/elixir/course',
    title: 'F0 · History — where this came from',
    note: 'The F0 chapter landing. List the two History modules with their abstracts and link them; this page makes /elixir/course resolve.',
    refs: [
      'https://en.wikipedia.org/wiki/Functional_programming — Functional programming (overview)',
      'https://en.wikipedia.org/wiki/History_of_programming_languages — History of programming languages',
    ],
    related: [
      { label: 'F0.1 · The evolution of functional languages & runtimes', route: '/elixir/course/fp-evolution' },
      { label: 'F0.2 · The evolution of Erlang, the BEAM & OTP', route: '/elixir/course/beam-evolution' },
    ],
    prevRoute: '/elixir', prevLabel: 'Back to the map' },

  { id: 'F0.1', action: 'edit', file: `${E}/course/fp-evolution.html`, route: '/elixir/course/fp-evolution',
    title: 'The evolution of functional languages & runtimes',
    refs: [
      'https://en.wikipedia.org/wiki/Lambda_calculus — Lambda calculus',
      'https://en.wikipedia.org/wiki/Lisp_(programming_language) — Lisp',
      'McCarthy, J. (1960). Recursive Functions of Symbolic Expressions and Their Computation by Machine.',
      'Hudak, P. et al. (2007). A History of Haskell: Being Lazy with Class.',
    ],
    related: [
      { label: 'F0.2 · Erlang, the BEAM & OTP', route: '/elixir/course/beam-evolution' },
      { label: 'F2.02 · Immutability & persistent data', route: '/elixir/functional/persistence' },
    ] },

  { id: 'F0.2', action: 'edit', file: `${E}/course/beam-evolution.html`, route: '/elixir/course/beam-evolution',
    title: 'The evolution of Erlang, the BEAM & OTP',
    refs: [
      'https://www.erlang.org/ — Erlang/OTP',
      'https://en.wikipedia.org/wiki/Erlang_(programming_language) — Erlang',
      'Armstrong, J. (2003). Making reliable distributed systems in the presence of software errors (PhD thesis).',
      'https://www.erlang.org/doc/design_principles/des_princ.html — OTP design principles',
    ],
    related: [
      { label: 'F0.1 · Functional languages & runtimes', route: '/elixir/course/fp-evolution' },
      { label: 'F2.01 · Pure functions & side effects', route: '/elixir/functional/pure' },
    ] },

  { id: 'F2.01', action: 'edit', file: `${E}/functional/pure.html`, route: '/elixir/functional/pure',
    title: 'Pure functions & side effects',
    refs: [
      'https://en.wikipedia.org/wiki/Pure_function — Pure function',
      'https://en.wikipedia.org/wiki/Referential_transparency — Referential transparency',
      'https://hexdocs.pm/elixir/Kernel.html — Elixir Kernel documentation',
    ],
    related: [
      { label: 'F1.02 · The substitution model', route: '/elixir/algebra/substitution' },
      { label: 'F2.02 · Immutability & persistent data', route: '/elixir/functional/persistence' },
    ] },

  { id: 'F2.02', action: 'edit', file: `${E}/functional/persistence.html`, route: '/elixir/functional/persistence',
    title: 'Immutability & persistent data',
    refs: [
      'https://en.wikipedia.org/wiki/Persistent_data_structure — Persistent data structure',
      'Okasaki, C. (1998). Purely Functional Data Structures.',
      'Bagwell, P. (2001). Ideal Hash Trees.',
    ],
    related: [
      { label: 'F1.04 · Immutability & binding', route: '/elixir/algebra/immutability' },
      { label: 'F2.01 · Pure functions & side effects', route: '/elixir/functional/pure' },
    ] },

  { id: 'F2.03', action: 'edit', file: `${E}/functional/higher-order.html`, route: '/elixir/functional/higher-order',
    title: 'Higher-order functions',
    refs: [
      'https://en.wikipedia.org/wiki/Higher-order_function — Higher-order function',
      'https://hexdocs.pm/elixir/Function.html — Elixir Function documentation',
      'https://hexdocs.pm/elixir/Enum.html — Elixir Enum documentation',
    ],
    related: [
      { label: 'F1.07 · Higher-order operators (Σ, Π)', route: '/elixir/algebra/higher-order' },
      { label: 'F2.05 · map / filter / reduce (folds)', route: '/elixir/functional/folds' },
    ] },

  { id: 'F2.04', action: 'edit', file: `${E}/functional/recursion/index.html`, route: '/elixir/functional/recursion',
    title: 'Recursion patterns & tail calls',
    refs: [
      'https://en.wikipedia.org/wiki/Recursion_(computer_science) — Recursion',
      'https://en.wikipedia.org/wiki/Tail_call — Tail call',
      'https://hexdocs.pm/elixir/Enum.html — Elixir Enum documentation',
    ],
    related: [
      { label: 'F1.06 · Recursion & induction', route: '/elixir/algebra/recursion' },
      { label: 'F2.05 · map / filter / reduce (folds)', route: '/elixir/functional/folds' },
    ] },

  { id: 'F2.04.1', action: 'edit', file: `${E}/functional/recursion/shape.html`, route: '/elixir/functional/recursion/shape',
    title: 'The shape of recursion',
    refs: [
      'https://en.wikipedia.org/wiki/Recursion_(computer_science) — Recursion',
      'https://en.wikipedia.org/wiki/Structural_induction — Structural induction',
    ],
    related: [
      { label: 'F2.04 · Recursion (hub)', route: '/elixir/functional/recursion' },
      { label: 'Tail calls & accumulators', route: '/elixir/functional/recursion/tail-calls' },
    ] },

  { id: 'F2.04.2', action: 'edit', file: `${E}/functional/recursion/tail-calls.html`, route: '/elixir/functional/recursion/tail-calls',
    title: 'Tail calls & accumulators',
    refs: [
      'https://en.wikipedia.org/wiki/Tail_call — Tail call',
      'https://hexdocs.pm/elixir/Enum.html — Elixir Enum documentation',
    ],
    related: [
      { label: 'F2.04 · Recursion (hub)', route: '/elixir/functional/recursion' },
      { label: 'Recursion patterns', route: '/elixir/functional/recursion/patterns' },
    ] },

  { id: 'F2.04.3', action: 'edit', file: `${E}/functional/recursion/patterns.html`, route: '/elixir/functional/recursion/patterns',
    title: 'Recursion patterns',
    refs: [
      'https://en.wikipedia.org/wiki/Fold_(higher-order_function) — Fold',
      'https://en.wikipedia.org/wiki/Recursion_(computer_science) — Recursion',
    ],
    related: [
      { label: 'F2.04 · Recursion (hub)', route: '/elixir/functional/recursion' },
      { label: 'F2.05 · folds', route: '/elixir/functional/folds' },
    ] },

  { id: 'F2.05', action: 'edit', file: `${E}/functional/folds/index.html`, route: '/elixir/functional/folds',
    title: 'map / filter / reduce (folds)',
    refs: [
      'https://en.wikipedia.org/wiki/Fold_(higher-order_function) — Fold',
      'Hutton, G. (1999). A tutorial on the universality and expressiveness of fold.',
      'https://hexdocs.pm/elixir/Enum.html — Elixir Enum documentation',
    ],
    related: [
      { label: 'F2.03 · Higher-order functions', route: '/elixir/functional/higher-order' },
      { label: 'F2.04 · Recursion patterns & tail calls', route: '/elixir/functional/recursion' },
    ] },

  { id: 'F2.05.1', action: 'edit', file: `${E}/functional/folds/map.html`, route: '/elixir/functional/folds/map',
    title: 'map',
    refs: [
      'https://hexdocs.pm/elixir/Enum.html#map/2 — Enum.map/2',
      'https://en.wikipedia.org/wiki/Map_(higher-order_function) — Map',
    ],
    related: [
      { label: 'F2.05 · folds (hub)', route: '/elixir/functional/folds' },
      { label: 'filter', route: '/elixir/functional/folds/filter' },
    ] },

  { id: 'F2.05.2', action: 'edit', file: `${E}/functional/folds/filter.html`, route: '/elixir/functional/folds/filter',
    title: 'filter',
    refs: [
      'https://hexdocs.pm/elixir/Enum.html#filter/2 — Enum.filter/2',
      'https://en.wikipedia.org/wiki/Filter_(higher-order_function) — Filter',
    ],
    related: [
      { label: 'F2.05 · folds (hub)', route: '/elixir/functional/folds' },
      { label: 'reduce', route: '/elixir/functional/folds/reduce' },
    ] },

  { id: 'F2.05.3', action: 'edit', file: `${E}/functional/folds/reduce.html`, route: '/elixir/functional/folds/reduce',
    title: 'reduce',
    refs: [
      'https://hexdocs.pm/elixir/Enum.html#reduce/3 — Enum.reduce/3',
      'https://en.wikipedia.org/wiki/Fold_(higher-order_function) — Fold (reduce)',
    ],
    related: [
      { label: 'F2.05 · folds (hub)', route: '/elixir/functional/folds' },
      { label: 'Advanced folds', route: '/elixir/functional/folds/advanced' },
    ] },

  { id: 'F2.05.4', action: 'edit', file: `${E}/functional/folds/advanced.html`, route: '/elixir/functional/folds/advanced',
    title: 'Advanced folds',
    refs: [
      'https://hexdocs.pm/elixir/Enum.html — Elixir Enum (scan, map_reduce, flat_map, group_by)',
      'Hutton, G. (1999). A tutorial on the universality and expressiveness of fold.',
    ],
    related: [
      { label: 'F2.05 · folds (hub)', route: '/elixir/functional/folds' },
      { label: 'reduce', route: '/elixir/functional/folds/reduce' },
    ] },
]

const ids = (Array.isArray(args) && args.length ? args : WORKLIST.map((w) => w.id))
const batch = WORKLIST.filter((w) => ids.includes(w.id))
log(`References pass over ${batch.length} page(s): ${batch.map((w) => w.id).join(', ')}`)

const GATE_SCHEMA = {
  type: 'object',
  required: ['pass', 'failedGates', 'detail'],
  properties: {
    pass: { type: 'boolean', description: 'true only when STATUS: PASS (all nine gates pass)' },
    failedGates: { type: 'array', items: { type: 'string' } },
    attempts: { type: 'number' },
    detail: { type: 'string' },
  },
}

function refsBlock(item) {
  const sources = item.refs.map((r) => `    - ${r}`).join('\n')
  const related = item.related.map((r) => `    - ${r.label}  ->  ${r.route}`).join('\n')
  return `Sources (external, authoritative):\n${sources}\n  Related in this course (internal links MUST be exactly these allowed routes):\n${related}`
}

function authorPrompt(item) {
  const common = `Read first and apply in full:
- ${SKILL}/references/references-section.md (the References-section convention — markup, placement, gate-safety)
- ${SKILL}/references/design-tokens.md and ${SKILL}/references/page-anatomy.md (house style)

The References content for ${item.id} — "${item.title}":
  ${refsBlock(item)}

Hard constraints (the page MUST end at Apollo A+ / cms check STATUS: PASS):
- Internal links may ONLY be the allowed routes listed above (plus /elixir). Never link a planned route, never use /future.
- External https links are fine. No localStorage/sessionStorage. Keep every container balanced. Include "prefers-reduced-motion". Any class="reveal" must be JS-gated by the shared head (it already is).`

  if (item.action === 'create') {
    return `Create the F0 chapter landing page at ${item.file}, served at ${item.route}. ${item.note}

Author a COMPLETE standalone A+ page (\`<!doctype html>\` … \`</html>\`) in the jonnify dark-editorial system: a hero titled "${item.title}", a short intro, a list/cards of the two History modules (link each to its route in the Related list, showing its abstract), at least one well-formed inline <svg> teaching visual (e.g. the F0 → F1 reading arc), a "References" section per the convention, and a pager whose link is <a class="btn ghost" href="${item.prevRoute}">${item.prevLabel}</a>. Include a footer build stamp.

${common}

Write the finished file to ${item.file}. Return only the absolute path written.`
  }

  return `Edit the existing built lesson page at ${item.file} (route ${item.route}). Read it first.

Insert ONE new "References" section immediately BEFORE the pager section (the <section> containing <nav class="pager">), inside <main>, following the references-section convention. Populate it with the Sources and Related links above. If the page's <style> has no .refs rule, add a small scoped one using the design tokens. Do NOT alter any existing lesson content — this edit is purely additive.

${common}

Save the edited file in place at ${item.file}. Return only the absolute path.

Prose discipline (apply to the section and your output): no first-person narration, no perceptual verbs with tool/agent subjects, no gendered pronouns, none of the forbidden hype/dismissive words. Enforce the same downstream.`
}

function gatePrompt(item, path) {
  return `Validate ${item.id} at ${path} against the nine Apollo A+ gates by running (${path} is ABSOLUTE; the binary is built by \`make build\`):
    cd /Users/jonny/dev/jonnify/apps/jonnify-cms && GOWORK=off ./bin/cms check ${path}

If STATUS is PASS, report pass=true. If FAIL, edit ${path} to fix ONLY the named failing gates while keeping the References section and all existing content intact, then re-run cms check. Repeat at most twice. Internal links may only be the allowed routes already in the page's Related list plus /elixir/course, /elixir, /elixir/functional, /elixir/algebra and their built modules. Return the structured verdict. Keep prose impersonal; no first-person narration or hype words.`
}

const results = await pipeline(
  batch,
  async (item) => {
    const path = await agent(authorPrompt(item), { label: `refs:${item.id}`, phase: 'References' })
    return { item, path: (path || '').trim() || item.file }
  },
  async (authored, item) => {
    const path = authored && authored.path ? authored.path : item.file
    const verdict = await agent(gatePrompt(item, path), { label: `gate:${item.id}`, phase: 'Gate', schema: GATE_SCHEMA })
    return { id: item.id, route: item.route, path, verdict }
  },
)

const ok = results.filter((r) => r && r.verdict && r.verdict.pass)
log(`done: ${ok.length}/${results.length} pages A+`)
return { processed: results.length, passed: ok.length, results }
