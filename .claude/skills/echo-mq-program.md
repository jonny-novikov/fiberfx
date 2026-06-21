# echo_mq — the program law (shared reference)

The common law every echo_mq dev skill cites. The role-specific craft lives in the three skills
(`echo-mq-architect`, `echo-mq-implementor`, `echo-mq-evaluator`); this file is the program-wide floor all
three stand on. Read it once per `emq.*` rung; the role skill points back here. It is an operational digest —
the binding authority is the design canon, which this file only points at, never overrides.

**Framing.** Third person for any agent reference; no gendered pronouns for agents; no perceptual or
interior-state verbs for agents or software — components read, compute, refuse, return.

**Markdown-link hygiene for Lua/`KEYS[n]` prose.** `msh specs` parses any `[text](word)` adjacency in markdown
as a link — so `KEYS[1](ring)` / any `KEYS[n](x)` Lua array-index notation in a ledger or spec is flagged a
false `DEAD-TARGET "x"` at `error` severity (it bit the architect spec, the implementor ledger, AND the verify
on emq.5.3). When authoring Lua / `KEYS[n]` / `redis.call` prose in markdown, break the bracket-then-paren
adjacency: write `KEYS[n]=x`, insert a space, or wrap in backticks — never `KEYS[n](x)`.

## The canon (read-first, NO-INVENT)

- **The design canon** — `docs/echo_mq/emq.design.md`: Operator-approved, reconcile-only, never redesigned.
  The S-1..S-7 locks; the ADRs (§2 branded-id, §3 fence merge, §5 wire-class registry); the grammar restated
  total for braces (§6); the seams (§10); the founding decisions (§11); the engine-feature ADRs on Valkey 8+
  (§12).
- **The engineering roadmap** — `docs/echo_mq/emq.roadmap.md`: the three movements, the rung ladder
  emq.0–emq.8, the master invariant, the seams. The progress dashboard is `docs/echo_mq/emq.progress.md`.
- **The program front door** — `docs/echo_mq/echo_mq.md`: the program frame and the named consumer.
- **The bibliography** — `docs/echo_mq/emq.references.md`.
- **The as-built surface map** (the real module / Lua / key names to cite) — `.claude/skills/echo-mq-surface.md`.

## The v2 laws (the protocol's load-bearing properties — S-1..S-7)

A surface a rung builds must satisfy every one; an invariant that asserts one is a runnable check, not prose.

| Law | What it binds | Source |
|---|---|---|
| **Braced keyspace** | Keys are `emq:{q}:<type>` (per-queue, closed registry) or `{emq}:<unit>` (the deployment reserve — `version`/`locks`/`bundle`/`migration:<q>`); first byte disjoint (`emq:{` vs `{emq}:`); the queue name is the span between the first `{` and `}`, charset `^[A-Za-z0-9._-]{1,128}$`, and `q ≠ "emq"`. The grammar is total (§6). | S-1; §6 |
| **Branded JOB ids** | The job position is `emq:{q}:job:<branded-id>`; the key builder gates `EchoData.BrandedId.valid?/1` and raises before any wire (wellformedness only); the kind law (`JOB`-only) is the enqueue script's FIRST act, a typed `EMQKIND` wire refusal. The 14-byte branded form is the wire form; byte order IS mint order (the order theorem — REV BYLEX browse, no second index). Custom ids retire from the job position (idempotency rides `emq:{q}:de:<dedupId>`). | S-2; §2 |
| **Declared keys** | Every Lua key is in `KEYS[]`, or derived in-script only from a declared `KEYS[n]` root by the registered grammar (the A-1 rule). Slot-sound under braces (every derivable key shares the declared root's slot). | S-6 |
| **Server clock where leases are touched** | A lease/fence transition reads `TIME` inside the script (sound under effects replication); the no-clock lint applies once the corpus moves to server-time — one corpus, one direction. | §4; §10 DQ-2c; §12.6 |
| **Honest-row reporting** | Claims are phrased against **Valkey, current stable line**, enforced as a gate; a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row. | S-4 |
| **One-time fork / additive minor** | The wire broke exactly once (at the founding); after it, additive registration is a protocol minor (registered WITH its conformance probe in the same change); a wire break or a computed-floor raise is a major. The closed wire-class registry (`EMQKIND`, `EMQSTALE`) grows by additive minor; the five-code fence union stands unextended. | S-3; §5; §6 |

## The roadmap awareness (where the rung sits)

- **The ladder (confirmed).** emq.0 (Movement 0 — land + prove the BCS drop; **shipped** 2026-06-13) · emq.1
  (Movement I — the scheduler + retry vocabulary; **shipped**) · **emq.2** (Movement I — the full
  echomq→echo_mq feature-parity rewrite, decomposed emq.2.1 / emq.2.2 / emq.2.3) · emq.3 (parent/flow family)
  · emq.4–emq.8 (Movement II — groups deepened, batches, lifecycle controls, the cache deepened, the proof
  stack). The exact carve of the emq.2.x parity cluster — and how it re-sequences the later ladder — is fixed
  in the emq.2 design (`docs/echo_mq/specs/emq.2.design.md`); read it on an emq.2.* rung.
- **The master invariant.** The fork happened once — the v2 key universe is grammar-total (braced
  `emq:{q}:`, the first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
  declared-or-rooted, the version record (`{emq}:version` = `echomq:2.0.0`) monotone behind the five-code
  fence — and **no later rung re-breaks the wire**.
- **The single source of truth.** `echo/apps/echo_mq` (above `echo/apps/echo_wire`) is the bus; it is the
  ONLY EchoMQ of record. `echo/apps/echomq` is a **feature reference** — a capability list to port, never a
  thing migrated-FROM, never edited. **Zero "legacy" / "old" / version-suffix / "migrate-from" framing** in the
  new documentation: echo_mq is brand-new, no compatibility layer, single source of truth.

## The gate ladder (run before reporting — the craft emq.1 earned)

- **Toolchain re-probe.** `asdf current erlang` (do not hardcode a version); a switch implies a full rebuild
  before gates. `redis-cli -p 6390 ping` → `PONG` (the live engine is **Valkey on port 6390**, not the
  default 6379).
- **Per-app compile, warnings-as-errors.** `TMPDIR=/tmp mix compile --warnings-as-errors` per touched app —
  never an umbrella-wide build.
- **Per-app suites only.** `TMPDIR=/tmp mix test` inside the touched app's dir. **Umbrella-wide `mix test` is
  BANNED** (the master invariant — the umbrella has apps with heavy or env-gated suites). The `:valkey`-tagged
  wire suites are excluded by default; include them explicitly for a wire rung (`--include valkey`).
- **The conformance run.** `EchoMQ.Conformance.run/2` over a live connection prints one line per scenario and
  returns `{:ok, n}`. The pure registry test (`conformance_scenarios_test.exs`) and the wire run test
  (`conformance_run_test.exs`) both pin the count.
- **The ≥100 determinism loop** (for Store / engine / process / id-minting suites):
  `for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done`. One green run is NOT proof and 20 is too
  few — a same-millisecond branded-id mint collision flakes only across runs (the emq.0/emq.1 arc hit it). The
  loop must OWN the machine (no concurrent liveness server, no sibling heavy I/O — a load-gated pre-existing
  test forges a failure the rung did not cause).

## The conformance additive-minor law (S-3 / §5, the mechanism)

The conformance scenario set grows ONLY by additive minor: extend `EchoMQ.Conformance.scenarios/0` with the
new scenario, **register its probe in the same change**, and keep **every prior scenario byte-unchanged**
(name + contract + verdict-body identical, git-verified). The count is the live total; the prior set is the
unchanged contract. As-built today the set is **18** (`echo/apps/echo_mq/lib/echo_mq/conformance.ex`): the 14
founding scenarios (fence, mint, duplicate, kind, order, claim, stale, complete, retry, dead, reap, rotate,
pause, limit) byte-unchanged + emq.1's four (schedule, repeat, backoff, resubscribe). Re-probe the live count
at the rung's reconcile; a rung that adds a capability adds its scenario(s) here and re-pins the count in both
pinning tests.

## NO-INVENT grounding — cite the real surface

Every EchoMQ reference is a real module or file; every architecture requirement cites its source; every engine
capability cites the official docs (`valkey.io`), never memory. A surface a rung BUILDS (not yet on disk) is
written forward-tense — "emq.N builds …" — never asserted-as-shipped. The as-built surface map (the real
module / Lua / key names to cite) is `.claude/skills/echo-mq-surface.md`; re-probe it at the rung's reconcile
(line numbers drift — treat them as hints, grep/Read the tree to confirm).

## Process locks (every rung, this repo)

- **Agents run NO git.** The Director commits once, at the rung's close, by pathspec (`git commit -F <msg> --
  <paths>`; never `git add -A`, never a bare `git commit`). The Operator commits out-of-band mid-flight —
  watch for `AM`-status files and exclude them.
- **The boundary.** The diff stays inside the architecture's facade — for the bus, `echo/apps/echo_mq` (+ the
  one named `echo/apps/echo_wire` connector seam where a rung touches it). A change that reaches a third app
  is a diff no one can review.
- **Escalate, do not invent.** A spec⇄design / spec⇄spec / spec⇄as-built contradiction STOPS and escalates to
  the Director; the design is the authority; hygiene (a deterministic re-grep/probe) closes every escalation.
