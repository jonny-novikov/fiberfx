# emq.commands — the v1→v3 command registry

The migration record for EchoMQ's bus surface: every **legacy v1 Lua command**
mapped to its **v3 EchoMQ home**, sorted by the 12-feature taxonomy. This is the
single place to answer "what was this v1 command, where did it go, and is the v3
port shipped?" without loading the design canon.

**52 commands** — 50 vendored v1 Lua scripts + 2 with no standalone v1 source
(`add_bulk`, a flow-parity verb; `grandchildren-recursive-flow-tree`, a v3-native
recursive build). Status tally: **SHIPPED 30 · PARTIAL 12 · NOT YET 7 · PROPOSED 1
· RETIRED 2** (emq.3.5 shipped — none remain BUILDING; Movement I closed).

## Layout

| Path | What it is | Read it when… |
|---|---|---|
| [`emq.commands.md`](emq.commands.md) | **The catalogue** — one table per feature, each command's one-line description, status, and the rung after which its reference is safe to retire. | you want the whole map, or to plan reference cleanup. |
| [`llms.txt`](llms.txt) | Flat, token-minimal agent index — one line per command (`command → slice#anchor — STATUS · v3 home · raw v1`). | an agent needs one command's home/status/source **without** loading a file. |
| [`features/`](features/) | One `.md` per command (`features/<family>/<cmd>.md`), grouped into 12 family subdirs — the full v1→v3 side-by-side, the embedded v1 source, the decision + rationale. | you need the deep detail for one command. |
| [`features/FORMAT.md`](features/FORMAT.md) | The five-part per-command doc shape + the NO-INVENT rule. | authoring or auditing a slice. |
| [`features/README.md`](features/README.md) | The per-family `Command → Status → v3 home` index over the slices. | you want the v3-module map (vs. this dir's reference-retirement map). |
| [`registry/`](registry/) | The 50 raw v1 Lua sources + `includes/` helpers — the cold-store corpus, full original text. | you need the byte-exact original v1 script. |

## The 12-feature taxonomy

`admission · scheduling · repeat · claim · retry · flows · groups · batches ·
locks · metrics · data · lifecycle` — the fixed order used throughout. A command
lives in exactly one **primary** family (its `features/` subdir); a few are
cross-tagged (*also …*) where they serve a second feature.

## Reference retirement — the lifecycle this catalogue tracks

A command's **v1 reference** (its `registry/<cmd>.lua` source + its `features/`
slice) earns its keep only while it is the *spec* for behaviour that has not yet
shipped. [`emq.commands.md`](emq.commands.md) gives each command a **"safe to drop
ref"** verdict on that basis:

- a **SHIPPED** port, or a capability **deliberately folded** into a broader verb → the reference is historical; **safe to retire now** (parity lives in shipped code + the conformance suite).
- a **PARTIAL / NOT YET / PROPOSED** command with a pinned rung → **hold until that rung ships**.
- the same with no scheduled rung → **hold** (a Movement-II backlog verb, rung TBD).
- a **RETIRED** capability → a design-note, redundant once its `emq.4` replacement lands.

Headline: **33 of 52 references are safe to retire today**; 9 are pinned to a
future rung (emq.5/6/8); 8 are held unscheduled; 2 are retired.

## Resolving a command (agents)

1. **One fact** (home, status, raw source) → grep [`llms.txt`](llms.txt) for the command name.
2. **The migration detail** → open `features/<family>/<cmd>.md`.
3. **The byte-exact v1** → `registry/<cmd>.lua`.
4. **Retirement planning** → [`emq.commands.md`](emq.commands.md), the "safe to drop ref" column.

## NO-INVENT

v1 sources are embedded verbatim; v3 schematics are **never fabricated** —
proposed/unbuilt rungs carry the repo's own withholding
(`*(proposed)*` / `*(Schematic withheld per NO-INVENT)*`). Descriptions and
verdicts in the catalogue are compressed from each slice's own
`Covers → v3` line and `--@` header.

## Reconciliation notes (as of Movement I close · emq.3.5 shipped)

This tree was recently reorganized (the flat `features/<family>.md` files were
exploded into per-command `features/<family>/<cmd>.md` slices). This pass
reconciled two things:

1. **emq.3.5 flipped to SHIPPED.** The `grandchildren-recursive-flow-tree` slice
   read `BUILDING ([RECONCILE])`, but the canon shows it shipped — `emq.roadmap.md`
   ("Movement I CLOSED … conformance 52/52") and the per-rung ledger ("emq.3.5 is
   SHIPPED — BUILD-GRADE, Arm A, NORMAL-risk"), confirmed by the as-built
   `flows.ex` recursive `add_tree` and the registered `flow_grandchild` /
   `flow_grandchild_fail` conformance scenarios. Flipped in the slice, the
   catalogue, and this index.
2. **Fragile locators purged.** Commit short-hashes (7 distinct) and `file:line`
   citations were stripped from all 52 slices + `features/README.md`, keeping the
   durable identities (module/arity · `@token` · rung · filename). A short-hash
   rots on rebase — the once-cited `cd3c383a` no longer resolves in git — and a
   line number drifts on every edit. The 14 frozen `specs/progress/*.progress.md`
   ledgers keep theirs by the records-freeze law.

Still open — **`llms.txt` links are stale** (two classes): its 12 entry rows point
at the pre-reorg flat paths (`features/admission.md#…`) rather than
`features/admission/addStandardJob-9.md`, and its `../` up-links
(`../emq.commands.registry.md`, `../emq.epic.1.md`) dangle (the matrix + taxonomy
live under `epics/emq.epic.1/`, not `specs/`). The data is correct; only the link
targets need rebasing.
