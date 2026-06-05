# F4.12.2 — A Snowflake registry (dive)

- **Route (served):** `/elixir/algorithms/lab/registry`
- **File:** `elixir/algorithms/lab/registry.html`
- **Place in the chapter:** the second of three dives under the `F4.12` lab (`/elixir/algorithms/lab`). With entries
  in their partitions (built in `grow`), it builds the read path: `get/1` resolves any branded id in one call —
  route by prefix, look up in `O(log₃₂ n)` hops, decode the creation time from the Snowflake — and rejects an id
  from a namespace the store does not hold. It is the middle of the lab arc (grow → registry → range).
- **Accent:** sage (the F4 chapter accent; accent word `registry`, rendered `<span class="ex">registry</span>`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.12 · part 2 of 3 · get & resolve`

Hero `<h1>`: `A Snowflake registry`

Hero lede (`.lede`, verbatim): "With entries in their partitions, the store becomes a registry: hand it any branded
id and it resolves the whole picture in one call. The three-letter prefix names the partition, the lookup inside
that partition takes `O(log₃₂ n)` hops, and the Snowflake packed into the id is its creation time — no timestamp
column to join. An id from a namespace the store does not keep is rejected before any lookup, the same edge check
as the persistence lesson."

Kicker line (`.kicker`, verbatim): "Resolve an id. Two are registered; one is from a namespace the store does not
hold. Watch what comes back."

## Sections

One teaching section then one advanced section, in the single-column lesson layout (no hero-art figure).

1. **`#resolve` · "Resolve an id"** (teaching) — each lookup reads the prefix, finds the partition, searches its
   CHAMP, and decodes the Snowflake for the creation time; a prefix with no partition (`TSK`) returns not-found
   without searching. Carries the `#rgSel` resolution-card figure.
2. **`#advanced` · "Advanced: get, reject, and free timestamps"** — `get/1` reads the prefix and rejects an
   unknown namespace at the edge (`:error`) before any search; otherwise an `O(log₃₂ n)` descent over the
   partition's CHAMP, with the timestamp decoded for free from the Snowflake. Carries the `pre.code` for
   `handle_call({:get, …})` and the idea→elixir bridge.

**Running example:** three branded ids resolved against a store holding `USR`/`SES`/`LSN`/`PGE` partitions —
`USR0NbAb1xcFCy` (users, present, 3 entries, `2026-05-31 13:35:19`), `LSN0NbD94T0Qtu` (lessons, present, 5 entries,
`2026-05-31 14:11:00`), and `TSK0KHTOWnGLuC` (an unknown namespace, rejected before any search, but still decodes
to `2026-01-27 15:11:37`).

**Real Elixir shown (`#advanced`, verbatim):**
```
# get/1 — route, reject unknown namespaces, resolve with a free timestamp
def handle_call({:get, id}, _from, store) do
  ns = binary_part(id, 0, 3)
  reply =
    case store do
      %{^ns => champ} ->
        case Champ.get(champ, id) do            # O(log₃₂ n) descent
          nil   -> {:error, :not_found}
          value -> {:ok, value, Snowflake.created_at(id)}  # time from the id
        end

      _ -> {:error, :unknown_namespace}        # no partition — reject, no search
    end
  {:reply, reply, store}
end
```

## The interactives

### `#resolve` figure — "Branded id · select one" (`#rgSel` selector + resolution card)

- **Figure:** `<figure class="fig" aria-labelledby="rgTitle">`, heading `Branded id · select one` (`#rgTitle`).
- **Control ids / buttons (`#rgSel`, role="group"):** three `<button>`s, labelled with the id strings —
  `data-k="usr" data-c="sage"` (label "USR0NbAb1xcFCy", starts `active`), `data-k="lsn" data-c="blue"`
  (label "LSN0NbD94T0Qtu"), `data-k="tsk" data-c="gold"` (label "TSK0KHTOWnGLuC").
- **SVG element ids (resolution card rows):** `#rgId` (the `resolve` line), `#rgNs` (namespace), `#rgPartition`
  (partition), `#rgPresent` (present), `#rgHops` (lookup cost), `#rgCreated` (created · Snowflake). Below the SVG:
  `#rgCode` (`pre.code`), `#rgOut` (`.geo-readout`), `#rgRole` (partition), `#rgResult` (resolved).
- **SVG static defaults (verbatim):** `#rgId` "resolve  USR0NbAb1xcFCy"; `#rgNs` "USR"; `#rgPartition` "users";
  `#rgPresent` "yes"; `#rgHops` "1 hop"; `#rgCreated` "2026-05-31 13:35:19 UTC". `#rgRole` "users"; `#rgResult`
  "2026-05-31 13:35:19".
- **Pure functions:** `hops(n) = max(1, ceil(log(n)/log(32)))`; `pick(k)` selects from
  `REC = { usr:{id:'USR0NbAb1xcFCy', ns:'USR', part:'users', size:3, present:true, ts:'2026-05-31 13:35:19'},
  lsn:{id:'LSN0NbD94T0Qtu', ns:'LSN', part:'lessons', size:5, present:true, ts:'2026-05-31 14:11:00'},
  tsk:{id:'TSK0KHTOWnGLuC', ns:'TSK', part:null, size:0, present:false, ts:'2026-01-27 15:11:37'} }`, recolours
  the card (the burgundy `#e08f8b` for the rejected namespace), and rewrites the code + readout. Initial call
  `pick('usr')`.
- **Readout strings (`#rgOut`, verbatim):**
  - Unknown namespace: "The prefix **TSK** matches no partition, so the registry returns
    `{:error, :unknown_namespace}` without a lookup. The id still decodes — created **{ts} UTC** — but the store
    has nowhere to look."
  - Known namespace: "The prefix **{ns}** routes to the **{part}** partition, where the id is found in **{h}**
    hop(s). Its creation time, **{ts} UTC**, is decoded from the Snowflake — no stored column."
- **Code strings (`#rgCode`, verbatim):**
  - Unknown: `# prefix TSK has no partition — rejected before any search` / `Portal.Store.get("{id}")` /
    `# => {:error, :unknown_namespace}   (decodes to {ts}, but nothing to search)`.
  - Known: `# route {ns}, search its CHAMP, read the time from the id` / `Portal.Store.get("{id}")` /
    `# => {:ok, value, ~U[{ts}Z]}  in {h} hop(s)`.
- **Takeaway (`.take`, verbatim):** "One call returns where an entry lives, whether it is there, what the lookup
  cost, and when it was made. The id is the index, the router, and the clock at once."
- **Degrades:** the card SVG carries static defaults; content is visible without JS (`html.js` gates only the
  reveal). `prefers-reduced-motion: reduce` collapses the reveal. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NchNxMpPCC`. The static `#st-ts` reads `2026-06-01 11:41:46 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319802704798941184`, node `0`, seq `0`, timestamp
  `2026-06-01 11:41:46 UTC` — matching the static value.
- **Pure functions:** `b62decode(s)` over `"0123…XYZabc…xyz"` → BigInt; `pad2(x)`; `decodeBranded(id)` splits
  `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`,
  `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Toggle on click / Enter / Space sets `.open`.

## References (`#refs`, verbatim)

Intro prose: "Primary sources for this lab, and the lessons it assembles."

**Sources**
- Elixir — `binary_part/3` → `https://hexdocs.pm/elixir/Kernel.html#binary_part/3` — reading the namespace prefix to route.
- Elixir — Patterns and guards → `https://hexdocs.pm/elixir/patterns-and-guards.html` — matching the partition or rejecting the namespace.
- Snowflake ID — Wikipedia → `https://en.wikipedia.org/wiki/Snowflake_ID` — the timestamp packed into the id.

**Related in this course**
- F4.12 · Lab: build a branded CHAMP store → `/elixir/algorithms/lab` — the lab hub.
- F4.07 · Identifiers, Snowflake & branded ids → `/elixir/algorithms/identifiers` — decoding the creation time.
- F4.08 · Branded ids & persistence → `/elixir/algorithms/persistence` — rejecting an id at the edge.
- F4 · Algorithms & Data Structures → `/elixir/algorithms`

## Wiring

- **route-tag (verbatim, segmented):** `/` `elixir` `/` `algorithms` `/` `lab` `/` `registry` — `elixir`,
  `algorithms`, `lab` are links; current `registry` is `<span class="rcur">`.
- **crumbs:** `F4` → `/elixir/algorithms` · sep `/` · `F4.12` → `/elixir/algorithms/lab` · sep `/` · here `registry`.
- **toc-mini:** `#resolve` ("Resolve an id") · `#advanced` ("Advanced: get, reject, and free timestamps").
- **pager:** prev → `/elixir/algorithms/lab/grow` ("← F4.12.1 · grow"); next → `/elixir/algorithms/lab/range`
  ("Next · query by time range →").
- **footer (3-column "foot-nav"):** identical to the lab hub — brand `.foot-logo` → `/elixir`; Chapters column
  `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`,
  `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; build stamp
  `TSK0NchNxMpPCC`. Header brand → `/elixir`; nav `Contents` → `/elixir/course`.
- **Page meta:** `<title>` "A Snowflake registry — F4.12.2 · jonnify"; `<meta description>` "Hand the store any
  branded id and get/1 resolves it in one call: the prefix names the partition, the lookup is an O(log32 n)
  descent, and the creation time is decoded from the Snowflake with no stored column. An id of a known namespace
  that is absent returns not-found after a real search; an id of an unknown namespace (here TSK) is rejected
  before any search, the same edge check as the persistence lesson, even though it still decodes to a timestamp."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the
two trailing `<script>` blocks verbatim from a recent built sibling on the F4 sage accent — the model is the
sibling dive `elixir/algorithms/lab/grow.html` (same lab, same accent, same single-column lesson hero, same
`solid-select` figure pattern), changing only `<title>`/`<meta description>`, the `.route-tag` segments, the
crumbs, and the `<main>` body (eyebrow/h1/lede/kicker, the `#resolve` figure, the `#advanced` prose + `pre.code`,
the bridge, the references, and the pager). Use only the real Portal surfaces as written — `Portal.Store.get/1`
over a `%{namespace => CHAMP}` map, `binary_part(id, 0, 3)` to route, a `case` over `%{^ns => champ}` that rejects
an unknown namespace at the edge, `Champ.get/2` for the `O(log₃₂ n)` descent, and `Snowflake.created_at/1` for the
free timestamp; do not invent module names or arities, and cite the companion F4 lessons (`F4.07` identifiers,
`F4.08` persistence) for the Snowflake and edge-rejection internals rather than re-teaching them. Voice: no first
person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from:
`elixir/algorithms/lab/grow.html`.
