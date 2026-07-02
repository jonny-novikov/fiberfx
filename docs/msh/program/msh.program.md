# msh — the operating manual (the program law)

> How an msh2 rung ships. This manual binds the shared Go-side program law by reference —
> [go.program.md](../../go/program/go.program.md) and the role charters
> [go.venus / go.mars / go.apollo](../../go/program/go.venus.md) — and adds only what is msh-specific. The
> canon is [../msh.design.md](../msh.design.md); the ladder [../msh.roadmap.md](../msh.roadmap.md); the
> voice + fences law [aaw.rules](../../aaw/aaw.rules.md).

## §1 · The floor

- **NO-INVENT.** Every public call cites the design § or a verified `file:line`; unbuilt surface is
  forward-tense. The grounding census lives in
  [kb/genesis/genesis.grounding.md](../kb/genesis/genesis.grounding.md) §2.
- **The island.** A build rung edits `go/msh` only. The named exceptions, each Operator-fenced in the
  roadmap: msh2.2's staged `memory/` backfill (S-4), msh2.6's `docs/msh` exemplar edits, M4's
  `go/aaw` / `docs/aaw` + `.claude` sweep (S-5). Anything else is out of scope by charter.
- **Cost discipline.** Right-size the formation; a triad + one Mars is the default; never over-staff a
  small rung.

## §2 · The formation (per build rung)

Ledgered on an aaw scope (`aaw_init` → `aaw_spawn` → `agent_register`; real agents only, LAW-1; peers on
the fable model, LAW-2):

1. **Venus** authors the rung triad from the ruled design (never the reverse) —
   `specs/msh2.N.{md,stories.md,llms.md}` per [specs/README](../specs/README.md).
2. **Mars** builds to the brief, write-ready dispatched, inside the island; runs the §3 gate ladder before
   reporting.
3. **The Director** re-runs the gates independently, runs the rung's adversarial probe, stages findings;
   Mars remediates; the Director records `tool_x_complete` (Z requires a locked D) and makes the ONE LAW-4
   commit.
4. **Apollo** is mandatory only on a high-risk rung — the msh2.2 mass backfill, msh2.7's loader change, the
   msh2.9 aaw-server rung; elsewhere the Director absorbs the evaluator duty (the D-3 exception, per
   [x-mode D-7](../../aaw/mcp/x-mode.design.md)).

## §3 · The gate ladders (by rung type; all Go gates `GOWORK=off`)

**go-code** (msh2.1, 2.3–2.5, 2.7, 2.8):

```bash
cd go/msh
GOWORK=off go build -o "$TMPDIR/msh-gate" ./cmd   # NEVER bare ./... — cmd output collision
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l . | grep -v vendor   # expect silence
# tools added? the tool-count pin test moves in the SAME change (8→9→10)
make mcp                      # repo root: mcpd hot-swap :8899 — NEVER pkill a live server
# client /mcp reconnect → one live smoke call (memory_project, or the rung's new tool)
```

**memory-data** (the msh2.2 backfill sub-rung): backup the tree → the staged script → byte-diff review →
`msh memory audit` = 0 errors before AND after → `git diff memory/` reviewed by the Operator → MEMORY.md
untouched by tooling.

**docs** (genesis, msh2.6, msh2.10): `msh specs <area>` clean at error severity over the touched area +
the cross-area link sweep + the header/status conventions spot-check. Pre-existing findings in an untouched
area are recorded, never repaired in-rung (do no harm).

**aaw-server** (msh2.9): additive-only schema · the selftest tool-count pin bumped in the same change ·
`make mcp` (:8905) · `/mcp` reconnect · live smoke · the aaw suite green.

**Determinism gates** (msh2.3+): golden-rank / golden-pack fixtures byte-stable; ties break by path; a
weight change is a visible fixture diff, never a silent drift.

## §4 · The ledger channels (the run's tool_x record)

| Moment | Tool | Channel |
|---|---|---|
| the rung opens (mission + scope) | `tool_x_trace` | T |
| a surfaced fork's arms | `tool_x_alternative` | V (`STEELMAN:` / `CHOSEN-AGAINST:`) |
| an Operator ruling | `tool_x_decision` | D (`RULED:`) |
| a captured craft lesson | `tool_x_learning` | L |
| a blocking condition | `tool_x_escalation` | E |
| the rung closes | `tool_x_complete` | Z (refused while no D exists — LAW-4's trigger) |

## §5 · The commit law (LAW-4)

Exactly one Director-only pathspec commit per concern; `git diff --cached --name-only` verified pure before
each (the jonnify tree is entangled — the Operator pre-stages out-of-band); never `git add -A`; never push
unasked. A rung's commit carries its code + its triad + its progress/roadmap rows in one commit; a second
concern (e.g. a supersede banner outside the island) is its own commit.

## §6 · The dogfood law

The program's product gates the program's process: every docs rung (this manual included) passes
`msh specs msh`; every memory rung passes `msh memory audit`; once msh2.6 ships, the shape rules gate
`docs/msh` itself — the pattern's first exemplar stays its first conformer.
