# CLAUDE.md — echo_mq · spec-driven · the Branded Component System stack

> **Go work? → [`go/CLAUDE.md`](go/CLAUDE.md).** This file + `echo/CLAUDE.md` govern the echo_mq / BCS Elixir stack. The `go/` agent-OS modules (`aaw` task-management · `msh` memory · `mcpd` · `mcp-go`) have their own guide — read it **only when working those Go projects**, unless the Operator directs otherwise.

Guidance for Claude agents working the **echo_mq bus program** and the **Branded Component System (BCS)** stack it lives in. Tuned for the spec-driven lead-team (Venus / Mars / Apollo via the `echo-mq-*` skills). The **specs are the source of truth**; this file is *how to work against them*, not a second copy of them.

## Scope

**In scope:** the `echo_mq` program (the Valkey-native bus) + the BCS stack it sits in (`echo_wire` · `echo_data` · `echo_store`) + the spec-driven workflow that ships it. One Mix umbrella under `echo/`.

**Out of scope** (pointers — do not work these from here): the static-HTML courses (`/elixir` `/bcs` `/redis-patterns` `/echomq` `/art` `/mesh` `/fsharp` agile) → their `*-course-writer` skills; `exchange`, `investex` → Operator out-of-band, **never touched by an echo_mq rung**.

## The architecture — one mental model

**Branded Component System (BCS)** is the successor to **ECS** (Adam Martin's Entity-Component-System: *entity* = a bare id, *component* = data with no logic, *system* = logic over a component array) adapted to the BEAM. Classic ECS packs components into shared contiguous arrays for cache locality; BCS gives up the shared array for **distribution + fault-tolerance** — a system is a *process* that owns its data privately and shares nothing. Three moves:

1. **Entity = a *branded* identity.** A 14-byte branded snowflake: a 3-letter uppercase namespace + 11-char Base62 over a `ts(41) | node(10) | seq(12)` snowflake — **time-ordered** (sorts by creation) and **coordination-free** (mint on any node, no registry). `EchoData.BrandedId` / `Snowflake` / `Base62` (+ an optional Rust NIF codec, `EchoData.Native`). The brand is the type: it is what is checked at every boundary.
2. **Component = data, not behaviour.** Properties are plain bundles; archetypes compose by fold (`EchoData.Bcs.Archetypes` — an `:extends` chain, right-most wins, **no class hierarchy, no behaviour modules**).
3. **System = the encapsulation unit.** A system is an OTP process owning a `:private` table that **gates every ingress on a single branded namespace** (`EchoData.Bcs.gate/2`) and exports its store to nobody. `EchoData.Bcs.PropertyStore` (entity → props), `EchoData.Bcs.EdgeStore` (a *relation* as a system — keyed by `{subject, object}` of names, both ends gated, **never an embedded id list**).

> **The law** (mesh.8.1, "the whole picture"): *encapsulation boundaries are drawn around **systems**, not objects. The only values that cross a boundary are **identities**, and **messages about identities**.* No object graphs, no shared mutable state, no embedded id lists. Surfaces are **peers joined by the thread** (the branded id), not layers stacked to hold each other up.

`echo_mq` and `echo_store` are *systems* built to this discipline over the wire; `echo/apps/echo_data/lib/echo_data/bcs/` is its reference implementation; the id contract is the `/bcs` course (`docs/echo/bcs`). The in-code `Rung bcs1.1` / `Chapter 2.x` citations are spec-driven too.

### The whole picture (mesh.8.1, embedded)

The stack is *one* system not because its surfaces coordinate but because they share **one branded identity** — minted at the consistent core, carried unchanged to the available periphery. Each surface is a **peer that makes its own CAP trade** (a fine-grained, per-operation choice, never a global one):

- **Consistency-first — the ledger:** one writer per book (a Registry-addressed `GenServer`), all-or-nothing (`Ecto.Multi`); under conflict it blocks or aborts rather than let two histories diverge.
- **Availability-first — the cache + the log:** the near-cache writes the hot value and lets the store push invalidation (RESP3 `CLIENT TRACKING`, → `echo_store`); the streams append to an ordered, replayable log (`XADD`, → the bus's retained log). Under partition both serve what they have.
- **Elastic — the worker:** dispatched onto an ephemeral machine via FLAME; the identity travels as the **claim check** the worker redeems for the payload.

The weave is one entity's life: **recorded once** at the ledger (which mints the id), then **carried** outward to cache, log, and worker — no surface sits beneath another. So the whole guarantees **neither global consistency nor global availability, by design** — each surface has the guarantee it needs and the system's guarantee is the sum of the local ones (a single global guarantee is exactly what CAP denies). This is a **PROPOSED composition** over shipped substrate (the BEAM · a Valkey-class store · Postgres via `Ecto.Multi` · Tigris · the FLAME pattern) — EchoMesh is the weave, taught forward-tense, not a shipped product. The code sketches: `docs/echo/mesh/mesh.8.1.md`.

## The stack (one umbrella under `echo/`; real dependency arrows, base → top)

Engine: **Valkey 9 on `:6390`** (RESP3; gate with `valkey-cli -p 6390 ping` → `PONG`).

| App | Role | In-umbrella deps |
|---|---|---|
| `echo_wire` | The **owned wire**: RESP framing, the single-owner socket connector, the script registry behind the version fence. Names `EchoMQ.Connector` / `RESP` / `Script` are **frozen** by committed records; `EchoWire` is the facade. | — (base) |
| `echo_data` | **Identity + structure + BCS** — pure, no in-umbrella deps. The branded-id contract, the persistent structures (`BrandedChamp` / `BrandedMap` / `BrandedTree`, `Edges`, `Timeline`), the BCS systems (`Bcs.{PropertyStore,EdgeStore,Archetypes,Supervisor}` + the `Bcs.gate`), the NIF codec. | — (pure) |
| `echo_mq` | **The bus** — the Valkey-native job/queue/stream system; a *system* over the wire keyed by branded `JOB` ids. Keyspace `emq:{q}:`, inline Lua, server-clock leases. | `echo_data` + `echo_wire` |
| `echo_store` | **The store** — L1 ETS over L2 Valkey (cache-aside), a per-group SQLite journal + a native Graft replication engine (CubDB → Tigris S3; in progress). Keyspace `ecc:{table}:{id}`; coherence = *a message about a name* (the BCS law, literally). | `echo_data` + `echo_mq` + `echo_wire` + `exqlite` |

`apps/echomq` is the **FROZEN v1** bus deffered to delete — a *feature reference only, never an edit target*; explicit Operator allowance to search in a folder. It shares the `EchoMQ.*` namespace at **zero module overlap** with the new `echo_mq`. Its full suite hangs on untagged concurrency — stay on per-app pure slices.

## Spec-driven development — the program

**The specs are the source of truth, and the `<rung>.md` *body* is authoritative** — the `.llms.md` brief and `.stories.md` can *lag* the body; verify shapes against the body. **Never invent surface**: ground every public call in a real module or a design §; forward-tense ("emq.N builds…") for anything unshipped. Canon under `docs/echo_mq/`:

- `emq.design.md` — S-1..S-7, the ADRs, the seams (the v2 protocol canon). `emq.roadmap.md` — the single rung ladder (**Movement I, emq.0–3, CLOSED; Movement II, emq.4–8, open**). `emq.progress.md` = rollup; `emq.features.md`, `emq.testing.md`, `emq.references.md`.
- `emq.command-registry.md` — the v1→v3 command matrix sorted by the **12-feature taxonomy** (admission · scheduling · repeat · claim · retry · flows · groups · batches · locks · metrics · data · lifecycle).
- `program/emq.program.md` — the operating manual; `program/emq.{venus,mars,apollo}.md` — the agent calibrations.
- `specs/<rung>.{md,stories.md,llms.md}` + `<rung>.prompt.md` (the run's authoritative scope) + `specs/progress/<scope>.progress.md` (the per-rung audit ledger). `epics/` = the decomposition layer.

**Ship a rung with `/echo-mq-ship <rung>`** — `/x-mode` with the echo_mq context pre-loaded. The **Flat-L2 lead-team** (`CLAUDE_LAWS 1/1a/2/3/4`, `.claude/commands/x.md`): **Venus** (reconcile/author the triad — loads `echo-mq-architect`) → **Mars-1** (build to the brief — `echo-mq-implementor`) → **Director** solo review (independent gate re-run on Valkey 6390 + an adversarial probe + a **net-zero** mutation spot-check) → **Mars-2** (remediate + harden) → **Director** ship (one **LAW-4 pathspec commit**). **Apollo** (`echo-mq-evaluator`) is **mandatory only on a high-risk rung** (a new process/lease surface, a destructive at-rest op, a frozen-line touch); on a normal rung it is an optional fast-finisher (closure + stories). Every peer is a real self-registered `general-purpose` agent that loads its `echo-mq-*` skill + role charter — no narrated spawns. Shared law: `.claude/skills/echo-mq-program.md`; the as-built map: `echo-mq-surface.md`.

## Invariants & gotchas (load-bearing — violating these breaks the wire or the gate)

- **The v2 master invariant** (the wire broke once, so it is hard-pinned): braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder · **every Lua key in `KEYS[]`, or derived from a *declared* `KEYS[n]` root** — an `ARGV`-passed base is **not** a declared root (the emq.2.1 F-1 finding, gate-invisible on single-node Valkey) · **server clock** (`TIME`) wherever a lease is touched · **inline `Script.new/2`, never `priv/`**. Additive registration is a protocol **minor**; a wire break is a **major**.
- **Byte-freeze Lua on a re-use / host-orchestration rung.** When a rung re-drives a shipped script, the `Script.new` bodies stay **byte-identical to HEAD** — `grep redis.call` on the lib diff must be `0`.
- **Boundary = `echo/apps/echo_mq`** (+ the one named `echo_wire` seam a rung touches). No third app; `mix.lock` excluded unless a real dep moved; `apps/echomq` untouched. A change reaching a third app is a diff no one can review.
- **The gate ladder is per-app, NEVER umbrella-wide.** Re-probe `asdf current` / `.tool-versions` **from the app dir** (do not hardcode the toolchain) · `valkey-cli -p 6390 ping` · `TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test` **inside the app's dir** (add `--include valkey` for a wire rung) · `EchoMQ.Conformance.run/2` → `{:ok, n}` under the **additive-minor law** (prior scenarios byte-unchanged + git-verified, each new one probe-registered, re-pin the count in both pinning tests) · the **≥100 determinism loop** only for an id-mint / process / lease suite (the same-ms branded-id mint hazard), else a multi-seed sweep + an honest determinism-posture statement.
- **`TMPDIR=/tmp` for all `mix`** — the harness tmp overlay hits ENOSPC and surfaces as spurious mid-suite I/O failures unrelated to any logic error.
- **Records freeze:** never rewrite a frozen `{scope}.progress.md` ledger's history. **Commit only when asked; pathspec only, never `git add -A`** — the Operator pre-stages out-of-band, so re-verify `git diff --cached --name-only` is purely the rung before any commit, and split an entangled tree into separate scoped commits per concern. Do not push unless asked.

## Map

Canon `docs/echo_mq/` · BCS code `echo/apps/echo_data/lib/echo_data/bcs/` (+ `test/bcs`) · the whole-picture frame `docs/echo/mesh/mesh.8.1.md` · the umbrella build guide `echo/CLAUDE.md` · the laws `.claude/commands/x.md` + the `/x-mode` skill · the ship loop `/echo-mq-ship`.
