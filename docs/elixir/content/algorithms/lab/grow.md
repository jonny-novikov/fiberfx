# F4.12.1 — Watch a branded CHAMP grow (dive)

- **Route (served):** `/elixir/algorithms/lab/grow`
- **File:** `elixir/algorithms/lab/grow.html`
- **Place in the chapter:** the first of three dives under the `F4.12` lab (`/elixir/algorithms/lab`). It builds the
  store's write path: how a `put` routes a branded key to its partition by namespace and grows the store one
  partition at a time. It belongs to the lab's build arc — grow (`put` & partition) → registry (`get` & resolve)
  → range (`range` by time) — and is the entry point of that arc.
- **Accent:** sage (the F4 chapter accent; accent word `grow`, rendered `<span class="ex">grow</span>`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.12 · part 1 of 3 · put & partition`

Hero `<h1>`: `Watch a branded CHAMP grow`

Hero lede (`.lede`, verbatim): "The store starts empty. Each `put` takes a branded id, reads its three-letter
namespace, and drops the entry into that namespace's partition — creating the partition the first time a namespace
appears, and adding to its CHAMP every time after. No entry ever lands in the wrong partition, because the
namespace that decides where it goes is part of the key itself."

Kicker line (`.kicker`, verbatim): "Ten entities, inserted in order. Step through the inserts and watch the
partitions appear and fill as each key routes itself by namespace."

## Sections

The dive runs as one teaching section then one advanced section, each ending in the shared shell. The hero is the
single-column lesson layout (crumbs → eyebrow → h1 → lede → kicker → toc-mini); there is no hero-art figure on this
dive.

1. **`#insert` · "Insert and route"** (teaching) — steps through ten real branded keys, each prefix
   (`USR`, `SES`, `LSN`, `PGE`) picking its partition; carries the `#grSel` checkpoint figure.
2. **`#advanced` · "Advanced: put, and the 33rd entry"** — explains `put/2` as route-on-prefix +
   `update_in` over one partition (sharing the rest), and the CHAMP restructure: 32 entries per root, the 33rd
   forces a second level, depth `ceil(log₃₂ n)`. Carries the `pre.code` for the assembled `handle_call({:put, …})`
   and the idea→elixir bridge.

**Running example:** ten real branded keys inserted in a fixed order: `USR0NbAb1xcFCy`, `SES0NbAb29FnXc`,
`LSN0NbCMKoAopE`, `USR0NXh7MFjxT6`, `LSN0NbCiUI0Sg4`, `PGE0NbWMtkolM0`, `LSN0NbD94T0Qtu`, `USR0NbWMtkosp8`,
`LSN0NbDmwjVOEa`, `LSN0NbAb2Lk9GS` — routed across four partitions: `USR` (users), `SES` (sessions),
`LSN` (lessons), `PGE` (pages).

**Real Elixir shown (`#advanced`, verbatim):**
```
# put/2 — route on the prefix, update one partition's CHAMP
def handle_call({:put, id, value}, _from, store) do
  ns = binary_part(id, 0, 3)                    # "USR0Nb..." -> "USR"
  store =
    update_in(store[ns], fn
      nil   -> Champ.new() |> Champ.put(id, value)  # first key of a namespace
      champ -> Champ.put(champ, id, value)             # add to the partition
    end)
  {:reply, :ok, store}                          # new store shares untouched partitions
end
```

## The interactives

### `#insert` figure — "Keys inserted · select a checkpoint" (`#grSel` selector + four partition rows)

- **Figure:** `<figure class="fig" aria-labelledby="grTitle">`, heading `Keys inserted · select a checkpoint`
  (`#grTitle`).
- **Control ids / buttons (`#grSel`, role="group"):** four `<button>`s, all `data-c="sage"` —
  `data-n="0"` (label "start"), `data-n="3"` (label "3 keys"), `data-n="6"` (label "6 keys"),
  `data-n="10"` (label "all 10", starts `active`).
- **SVG element ids:** `#grTotal` (entry/partition tally), `#grRows` (the built rows group); per partition the
  script builds `#grNs_<NS>`, `#grNm_<NS>`, `#grCnt_<NS>`, five dots `#grDot_<NS>_<d>`, and `#grLvl_<NS>`. Below
  the SVG: `#grCode` (`pre.code`), `#grOut` (`.geo-readout`), `#grRole` (inserted), `#grResult` (partitions).
- **SVG static defaults (verbatim):** `%{namespace => CHAMP}`; `#grTotal` "10 entries · 4 partitions";
  `#grRole` "10"; `#grResult` "4".
- **Pure functions:** `tally(k)` counts the first `k` of `SEQ` by three-char prefix (the real routing);
  `pick(k)` recolours the rows, fills the dots, and rewrites the code + readout. Partitions
  `PARTS = [{ns:'USR',name:'users',max:5}, {ns:'SES',name:'sessions',max:5}, {ns:'LSN',name:'lessons',max:5},
  {ns:'PGE',name:'pages',max:5}]`. Initial call `pick(10)`.
- **Readout strings (`#grOut`, verbatim):**
  - At `k === 0`: "The store is empty: **0** entries, **0** partitions. Each partition is created the first time a
    key of its namespace is inserted."
  - Otherwise: "After **{total}** inserts the store holds **{parts}** partitions — {name n, …}. The last key routed
    itself to **{lns}** on its prefix."
- **Code strings (`#grCode`, verbatim):**
  - At `k === 0`: `# empty store` / `store = %{}` / `# no partitions yet — each is created on its namespace's first key`.
  - Otherwise: `# after {k} inserts — last key routed by its prefix` / `Portal.Store.put("{last}", v)   # {lns} -> :{name}` /
    `# store now holds {total} entries across {parts} partitions`.
- **Takeaway (`.take`, verbatim):** "The store grows by partition. A key never has to be told where it belongs;
  its namespace routes it, and a partition springs into being the first time its namespace is seen."
- **Degrades:** the SVG rows are built by JS, but the figure carries static SVG defaults and the page content is
  visible without JS (`html.js` gates only the reveal animation). `prefers-reduced-motion: reduce` collapses the
  reveal to no transition. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NchNx4NTk0`. The static `#st-ts` reads `2026-06-01 11:41:46 UTC`.
- **Decoded:** namespace `TSK`, snowflake `319802704526311424`, node `0`, seq `0`, timestamp
  `2026-06-01 11:41:46 UTC` — matching the static value.
- **Pure functions:** `b62decode(s)` over `"0123…XYZabc…xyz"` → BigInt; `pad2(x)`; `decodeBranded(id)` splits
  `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`,
  `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Toggle on click / Enter / Space sets `.open`.

## References (`#refs`, verbatim)

Intro prose: "Primary sources for this lab, and the lessons it assembles."

**Sources**
- Elixir — `update_in/3` → `https://hexdocs.pm/elixir/Kernel.html#update_in/3` — updating one partition, creating it on first use.
- Elixir — `binary_part/3` → `https://hexdocs.pm/elixir/Kernel.html#binary_part/3` — reading the three-letter prefix.
- Elixir — `handle_call/3` → `https://hexdocs.pm/elixir/GenServer.html#c:handle_call/3` — serialising the write.

**Related in this course**
- F4.12 · Lab: build a branded CHAMP store → `/elixir/algorithms/lab` — the lab hub.
- F4.06 · CHAMP → `/elixir/algorithms/champ` — the node inside each partition and its bitmap.
- F4.09 · Branded CHAMP maps & GenServer → `/elixir/algorithms/branded-champ` — the partitioned store.
- F4 · Algorithms & Data Structures → `/elixir/algorithms`

## Wiring

- **route-tag (verbatim, segmented):** `/` `elixir` `/` `algorithms` `/` `lab` `/` `grow` — `elixir`, `algorithms`,
  and `lab` are links (`/elixir`, `/elixir/algorithms`, `/elixir/algorithms/lab`); current `grow` is `<span class="rcur">`.
- **crumbs:** `F4` → `/elixir/algorithms` · sep `/` · `F4.12` → `/elixir/algorithms/lab` · sep `/` · here `grow`.
- **toc-mini:** `#insert` ("Insert and route") · `#advanced` ("Advanced: put, and the 33rd entry").
- **pager:** prev → `/elixir/algorithms/lab` ("← F4.12 · lab"); next → `/elixir/algorithms/lab/registry`
  ("Next · a Snowflake registry →").
- **footer (3-column "foot-nav"):** identical to the lab hub — brand `.foot-logo` → `/elixir`; Chapters column
  `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`,
  `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; build stamp
  `TSK0NchNx4NTk0`. Header brand → `/elixir`; nav `Contents` → `/elixir/course`.
- **Page meta:** `<title>` "Watch a branded CHAMP grow — F4.12.1 · jonnify"; `<meta description>` "Each put reads
  a branded id's three-letter namespace and drops the entry into that namespace's partition, creating the
  partition on first use. Stepping through ten real keys, the store grows by partition — users, sessions, lessons,
  pages appear and fill as each key routes itself by prefix. Inside a partition the CHAMP root holds 32 entries
  before the 33rd forces a second level, keeping depth at ceil(log32 n); the write rebuilds only one partition and
  shares the rest."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the
two trailing `<script>` blocks verbatim from a recent built sibling on the F4 sage accent — the model is the
sibling dive `elixir/algorithms/lab/registry.html` (same lab, same accent, same single-column lesson hero, same
`solid-select` figure pattern), changing only `<title>`/`<meta description>`, the `.route-tag` segments, the
crumbs, and the `<main>` body (eyebrow/h1/lede/kicker, the `#insert` figure, the `#advanced` prose + `pre.code`,
the bridge, the references, and the pager). Use only the real Portal surfaces as written — `Portal.Store.put/2`
over a `%{namespace => CHAMP}` map, `binary_part(id, 0, 3)` to read the prefix, `update_in` to grow one
partition's immutable `Champ`; do not invent module names or arities, and cite the companion F4 lessons
(`F4.06` CHAMP, `F4.09` branded-CHAMP) for the data-structure internals rather than re-teaching them. Voice: no
first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from:
`elixir/algorithms/lab/registry.html`.
