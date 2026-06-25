# Codemojex Auth Flow — Design-Ahead · Lens A: Consumer / Cross-Edge / Forward-Vision

> **Lens A — the CONSUMER / CROSS-EDGE view.** This design argues every fork from EVERY consumer of the shared
> session: the Telegram Mini App client (holds a credential, presents it on HTTP + the socket), the **Go
> lightweight edges** (the bitmapist analytics edge and any future marker — they read shared branded state from
> the shared store through a ported branded codec), **Phoenix LiveView** (the admin/live surfaces, forward-vision),
> and the dev/operator. The priorities, in order: the cross-language SES contract from the consumer side (what a
> Go edge reads, how it decodes the SES value, how it trusts it); minimal client friction; the bitmapist
> analytics integration (which events mark which cohorts, keyed by branded id); LiveView's session integration;
> the forward-vision phasing + DX. This doc CHAMPIONS thin-but-robust + DX-simplicity FOR THE CONSUMER, and
> honors the Steward part of each arm honestly. Each fork pre-empts the spec-steward lens's strongest objection.
>
> **This is the REVISED Lens A (v2).** The Operator added a STRUCTURAL requirement (G6–G9 below) that **RE-RULES
> FA**: the prior v1 recommendation — **A1, a stateless `Phoenix.Token`** — is **SUPERSEDED**. A Go edge cannot
> verify a Phoenix-internal stateless token, so the bearer must be a `SES` id resolvable from a SHARED store by
> ANY service. FA is no longer "stateless vs stateful"; it is the DESIGN of a stateful `SES` session in Valkey.
> Authored independently of VenusPG's revised `auth.design.B-steward-lens.md` (not read). Forks are SURFACED,
> never decided. NO-INVENT holds: every named surface is verified at its source (cited) or written forward-tense.
> Corpus voice: no first person, no perceptual / interior-state verbs applied to software; third person for any
> agent reference.

---

## §0 · Context

**What the auth floor is.** Codemojex's web surface (`CodemojexWeb`) trusts a client-supplied player id today:
`GameController.require_player/1` (`game_controller.ex:77`) returns `params["player"]` verbatim across five
player-acting endpoints, and `UserSocket.connect/3` (`user_socket.ex:7`) accepts any connection. The named
pre-launch gap is that any caller can act as any player.

**The Operator-ruled model (GIVEN — carried, not re-litigated).** Dual-auth, token-centric, platform-pluggable,
**and now cross-edge shared-session**:

- **G1 — the bearer credential is a session credential.** `initData` is a ONE-TIME bootstrap exchanged at an
  HTTP handshake (the first screens, BEFORE the socket connects) for a session; the session authenticates all
  later HTTP and the socket. *"If a session is present — auth by it; when it is missed and `initData` is present
  (NOT socket, handshake on the first screens before socket connect) — issue one."*
- **G2 — platform-pluggable.** Telegram is ONE platform; the session is platform-agnostic; `initData` is the
  Telegram adapter's bootstrap.
- **G3 — `POST /api/players` is RETIRED.** Identity creation is a side effect of first authentication.
- **G4 — the verifier survives, at the handshake.** `Codemojex.InitData` HMAC verify (excludes `hash` AND
  `signature`; secret `HMAC-SHA256("WebAppData", token)`; `:crypto.hash_equals`; token via `Codemojex.Bot.token/0`,
  `bot.ex:39`). Venus-Postgres's resolve-or-create `PLR` path survives at the handshake.
- **G5 — the 8 story suites stay byte-unchanged (41/0); the boundary is `echo/apps/codemojex/**`** (the Go edges
  in `infra/codemojex-bitmapist/` are a forward-vision consumer, NOT in the cm.4 floor boundary).
- **G6 — SHARED SESSION (the re-rule).** The session is shared across Phoenix + Go LIGHTWEIGHT EDGES + LiveView.
  A Go edge cannot verify a Phoenix-internal stateless token, so the bearer is a **`SES` branded id resolved from
  a SHARED STORE by ANY service**. **FA is re-ruled: the converged A1 (stateless `Phoenix.Token`) is OVERRULED
  → a stateful `SES` session, stored in VALKEY** (not Postgres, not a stateless token).
- **G7 — `SES` in Valkey via EchoStore + echo-persistence.** The `SES` lives in Valkey (shared L2), fronted by
  the EchoStore ETS-L1 near-cache, durable via echo-persistence (`EchoStore.Graft`, CubDB → Tigris). Apply the
  Redis session-management patterns (`docs/redis-patterns/markdown/caching/session-management/{auth-session,
  encodings,ttl-expiry}.md`). The **SES value must be LANGUAGE-NEUTRAL** (a Go edge decodes it) — **NEVER an
  Erlang term**.
- **G8 — bitmapist.** `infra/codemojex-bitmapist/` is a Go cohort-analytics edge, **branded-id-native** (the Go
  codec ports the BCS Snowflake/Base62 contract EXACTLY — `branded.Offset("USR0KHTOWnGLuC") == 234878118`, the
  same vector the BEAM derives). It runs as a SEPARATE minimal-store Fly app on `codemojex-bitmapist.internal:6400`
  (RESP2, redigo), keyed by branded id (`Mark`/`Count`/`AndCount`/`RetentionRow` over active/registered/played/paid
  cohorts). It is BOTH the analytics consumer AND the concrete Go lightweight edge reading shared branded state.
- **G9 — LiveView.** The session design must serve Phoenix LiveView (the admin/live surfaces) in the
  forward-vision.

**The as-built substrate this design stands on (verified):**

- `EchoStore.Table` — the L1-ETS-over-L2-Valkey near-cache. **Three coherence modes** (`table.ex:22-24`): `:none`,
  `:broadcast` (the versioned app-level lane — "a message about a name", the BCS law literal), `:tracking` (RESP3
  `CLIENT TRACKING`). `put/3` mints the version (`table.ex:90`); `put/4` takes a caller-supplied version
  (`table.ex:97`); `fetch/3` (`table.ex:63`) is an L1 `:ets` lookup → a coalesced L2 fill → the loader;
  `invalidate/3` (`table.ex:174`) is `DEL` L2 + `:ets.delete` (the logout). The **kind gate** refuses a
  wrong-namespace id with ZERO keys on the wire (`gate/2`, per `docs/redis-patterns/.../auth-session.md`). The L2
  row is a **framed String**: `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms` (`table.ex:290`), a read splits
  `<<version::binary-14, value::binary>>` (`table.ex:429`).
- `Codemojex.Tables` (`tables.ex`) — declares the two near-caches `:cm_games` (GAM) + `:cm_emojisets` (EMS), both
  `coherence: :none` **because each entity is immutable for its life** (the moduledoc says so). The loaders frame
  with `:erlang.term_to_binary` (`tables.ex:92,100`) — the BEAM-only encoding a Go edge cannot read.
- `EchoStore.Graft` (echo-persistence) — `open_volume/2` (`graft.ex:31`), `read/2` (`graft.ex:47`), `read_at/3`
  (`graft.ex:54`), `commit/3` (`graft.ex:41`), `push/1` (`graft.ex:44`); the CubDB → Tigris durable page tier.
- `Codemojex.Wire` (`wire.ex`) + `Codemojex.Bus` (`store.ex:108`, `EchoWire.start_link(port: 6390, protocol: 3)`)
  — the Valkey `:6390` connector.
- The Go edge `infra/codemojex-bitmapist/`: a CLIENT LIBRARY (no `main.go`) over Doist's `bitmapist-server`
  (roaring bitmaps) on `:6400`; `branded.Offset(id) = Hash32(Decode(id))`; `bitmapist.Client.{Mark,Count,AndCount,
  RetentionRow,...}`. It does NOT mint ids (decode/derive only). Cohorts in code/tests/README: active, registered,
  played, paid. **Wiring is planned (the roadmap P1–P3), not built** — the design is a Go marker fed by the
  events the game already emits + a Go dashboard reader.

**The one question the WHOLE auth flow must answer well, from this lens:**

> A Mini App client hands over its platform bootstrap ONCE, receives a `SES` branded id, and presents that one
> id on every HTTP call and the socket — while a Go lightweight edge, holding only that `SES` id (or a `PLR` it
> resolves), reads the SAME session state from the SAME shared store, decodes its LANGUAGE-NEUTRAL value with a
> stock Redis client and the ported branded codec, and trusts it by the namespace of the brand — with revocation
> and expiry visible to every consumer (BEAM and Go), and a forward path by which LiveView and the bitmapist
> cohorts read the same shared identity. Does the flow deliver one shared session that crosses the
> language boundary as cleanly as the branded id already does?

Every fork below is ranked by how cleanly its winning arm answers that question for the cross-edge consumer — a
shared `SES` any service resolves, a language-neutral value any client decodes, trust by the brand's namespace,
and revocation/expiry visible to all.

---

## §FA · The SES-in-Valkey design (RE-RULED — the headline)

**The re-rule.** v1 converged (and the synthesis ratified) **A1, a stateless `Phoenix.Token`**. G6 OVERRULES it:
a Go edge cannot verify a Phoenix-internal token (the signing is BEAM-internal; `Phoenix.Token` is not a
cross-language format), so the bearer MUST be a `SES` branded id resolvable from a shared store by any service.
The v1 FA Steward already flagged exactly this — *"a stateless token cannot be revoked... a `SES` session is the
BCS-idiomatic, revocable, auditable credential"* — and the cross-edge requirement now forces that family. So FA
is no longer stateless-vs-stateful; it is the DESIGN of a stateful `SES` session in Valkey. The settled core
(GIVEN by G6/G7): the bearer is a `SES`-branded id; the session lives in Valkey (L2) fronted by EchoStore L1; the
value is language-neutral. The open sub-forks are the consumer-facing contract.

### FA-1 — the SES VALUE encoding a Go edge decodes (a Valkey HASH of fields vs JSON vs msgpack)

**The fork.** The Go edge reads the session value from L2. WHAT encoding — a Valkey HASH of named fields, a JSON
string, or msgpack? (G7 forbids an Erlang term.) Grounded by the redis-patterns `encodings.md` Hash-vs-String-vs-JSON
trade.

**Arm A1 — JSON (a UTF-8 JSON object as the value).** The session is a small JSON object —
`{"plr":"PLR…","platform":"telegram","tg_user_id":…,"issued":…,"seen":…}` — written as the value; a Go edge
`GET`s and `json.Unmarshal`s it.

- *Rationale.* JSON is the universal language-neutral structured format; every language (Go, Elixir via `Jason`)
  encodes and decodes it with a stdlib call, so the cross-edge contract is "parse JSON," the lowest-friction
  shared shape.
- *5W.* **Why** — the value must be decoded by a Go edge AND the BEAM; JSON is the format both already speak.
  **What** — a flat JSON session object (forward-tense; `Jason` is a codemojex dep, `mix.exs:58`; Go's
  `encoding/json` is stdlib). **Who** — the BEAM writer (the handshake), every BEAM reader, the Go edge. **When** —
  written at the handshake, read on every resolve. **Where** — the SES value in L2 (the inner value of EchoStore's
  framed String, or a plain `SET` if not via `Table` — see FA-2).
- *Steelman.* JSON is the most consumer-friendly value for a polyglot reader: a Go edge does
  `json.Unmarshal(bytes, &sess)` into a struct with no schema negotiation, and the BEAM does `Jason.decode/1` — the
  same record, two stdlib calls. It is self-describing (the field names are in the bytes), so a new field is
  additive and an old reader ignores it (forward-compatible across edges that may deploy at different times — the
  exact cross-edge versioning the Go-marker-deploys-separately reality needs). The session is flat and few-field
  (the redis-patterns `encodings.md` "flat and few-field — a `SES` id, a user id, an opaque token — the shape a
  Hash backs cleanly"), so JSON's whole-value read is cheap. It composes with EchoStore: the framed-String value
  (`version <> value`, `table.ex:290`) carries JSON as its inner `value`, and a Go edge strips the 14-byte version
  prefix then parses JSON.
- *Steward.* The keep-cost: a single-field update (a `last_seen` bump) rewrites the whole value (read-parse-edit-write),
  where a HASH updates one field in place (`encodings.md` "the difference shows when one field changes"). For a
  session bumped on every request, that is a re-serialize per touch — but the sliding-TTL move is already a
  whole-value re-`put` (the version changes, `table.ex:90`), so the re-write is not extra under EchoStore's model.
  The 14-byte version-prefix-strip is a cross-edge contract detail the Go side MUST implement (a documented offset,
  not a guess) — the spec must state it, or a Go edge mis-parses the framed value.

**Arm A2 — a Valkey HASH of named fields.** The session is a Valkey HASH —
`HSET ecc:{sessions}:SES… plr "PLR…" platform "telegram" seen "…"`; a Go edge `HGETALL`s it (or `HGET`s one
field), the BEAM the same.

- *Rationale.* A HASH gives field-level reads and writes — a `last_seen` bump is one `HSET` field, a `plr` read is
  one `HGET`, with no whole-value re-serialize (`encodings.md` "a Hash updates that field in place").
- *5W.* **Why** — a frequently-bumped field (last-seen) is cheaper as a HASH field than a whole-value rewrite.
  **What** — a Valkey HASH per session (forward-tense). **Who** — the BEAM + the Go edge (both speak `HGETALL`).
  **When** — read/bumped per request. **Where** — L2 directly.
- *Steelman.* Field-level access is the HASH win: a Go edge that needs ONLY the `plr` does `HGET ecc:{sessions}:…
  plr` (one field, no full decode), and a `last_seen` bump is `HSET … seen …` with no read-modify-write. It is
  language-neutral by construction (a HASH is a Redis-native type every client reads field-wise), so there is no
  encoding to agree on beyond field names. Memory is lean (`encodings.md` "short field names, fetch full details
  from the source").
- *Steward.* The keep-cost is the BIG one for THIS architecture: a Valkey HASH does **not** fit EchoStore's
  `Table` model — `EchoStore.Table.put/3` writes a **framed String** (`SET … (version<>value)`, `table.ex:290`),
  not an `HSET`, and the L1 ETS row holds one framed binary, not a field map. So a HASH session means BYPASSING
  `EchoStore.Table` (writing raw `HSET`/`HGETALL` via `Codemojex.Wire`), which forfeits the L1 near-cache, the
  versioned coherence, the kind gate, and the sliding-TTL machinery (FD) — the entire EchoStore session
  infrastructure G7 calls for. It trades a cheaper field-bump for losing the L1 tier and the coherence lane the
  BEAM consumers want. The field-level win is also marginal for a flat few-field session that is read whole on
  almost every resolve.

**Arm A3 — msgpack (a binary language-neutral packed value).** The session is msgpack-encoded as the value.

- *Rationale.* msgpack is a compact binary cross-language format — smaller on the wire than JSON, decoded by Go
  and Elixir libraries.
- *5W / Steelman (brief).* Smaller payloads; binary efficiency; language-neutral with a library on each side.
  **Where** — the SES value in L2.
- *Steward.* The keep-cost is a NEW dependency on BOTH sides (a msgpack lib for Elixir — NOT a current codemojex
  dep, a `mix.lock` add the cm.4 boundary forbids — and one for Go) for a session payload measured in tens of
  bytes, where the size win is negligible and JSON is already universal. It is not self-describing in the
  human-readable way JSON is (harder to inspect a session in `valkey-cli`). It buys binary compactness no session
  workload needs at the cost of a dep on each edge.

**Ranked recommendation (FA-1, Lens A): A1 (JSON), as the inner value of EchoStore's framed String — with the
14-byte version-prefix-strip named as the Go-edge contract.** JSON is the universal language-neutral format both
the Go edge and the BEAM decode with a stdlib call (no new dep — `Jason` is already a codemojex dep, Go's
`encoding/json` is stdlib), it is self-describing and forward-compatible across edges that deploy separately
(the Go-marker reality), and it carries cleanly as the inner `value` of EchoStore's framed String so the full L1
+ coherence + kind-gate + sliding-TTL infrastructure (G7) applies. A2 (HASH) wins field-level updates but FORFEITS
the entire `EchoStore.Table` tier (a HASH is not a framed String — it bypasses L1, coherence, and the kind gate),
which is the infrastructure G7 explicitly calls for. A3 (msgpack) adds a dep on both edges for a size win a
flat session does not need. The one cross-edge contract detail the spec MUST pin: a Go edge reading L2 strips the
14-byte version prefix (`table.ex:429`) before `json.Unmarshal`.

> **Pre-empted spec-steward objection:** *"JSON re-serializes the whole value on every `last_seen` bump — a HASH
> updates one field in place and is the leaner, more idiomatic session store; and embedding JSON inside
> EchoStore's framed String couples a cross-language value to a BEAM-specific frame a Go edge must reverse-engineer."*
> Answer: the whole-value rewrite is not extra cost here — EchoStore's sliding-TTL move is ALREADY a whole-value
> re-`put` (the version changes, `table.ex:90`), so a `last_seen` bump rides the re-`put` that the TTL slide
> performs anyway; a HASH's in-place field win is real only if the session is bumped WITHOUT sliding the TTL,
> which the sliding-session model (FD) does not do. The framed-String coupling is a DOCUMENTED 14-byte offset
> (`table.ex:429`), not reverse-engineering — the spec states "a Go edge strips the leading 14 bytes, then parses
> JSON," a one-line contract. The decisive point: A2's HASH cannot use `EchoStore.Table` at all (it is not a
> framed String), so choosing it discards the L1 near-cache, the versioned coherence lane, the kind gate, and the
> sliding-TTL sweeper — the whole G7 infrastructure — to save a re-serialize the TTL slide already pays. JSON
> keeps the infrastructure AND the cross-language contract.

### FA-2 — the GO-EDGE TRUST MODEL (read-only verify vs mint/mutate)

**The fork.** A Go edge holds a `SES` id (or a `PLR`). What can it DO — only READ-verify the session (and trust
the brand's namespace), or also MINT/MUTATE it?

**Arm A1 — READ-ONLY verify (a Go edge resolves + trusts by the kind gate; only the BEAM mints/mutates).** A Go
edge `GET`s the L2 session row, strips the version, parses JSON, and trusts it because the key's namespace is
`SES` (the kind gate's discipline — a wrong-namespace key is refused with zero keys on the wire, `auth-session.md`).
It NEVER writes the session; minting (the handshake) and mutation (slide, revoke) are the BEAM's alone.

- *Rationale.* A session's authority is the BEAM's (it owns the handshake, the verifier, resolve-or-create); a Go
  edge is a READER of shared state, so giving it read-only verify keeps one writer and a simple trust model — the
  edge trusts the brand and the shared store, mints nothing.
- *5W.* **Why** — one writer (the BEAM) avoids cross-language write races and a duplicated mint/verify path in Go.
  **What** — a Go edge does `GET` + version-strip + JSON-parse + namespace-check; no write (forward-tense). **Who** —
  the bitmapist marker/dashboard + any future Go edge. **When** — whenever an edge needs the player behind a SES.
  **Where** — `infra/codemojex-bitmapist/` (and future edges), reading L2 over redigo.
- *Steelman.* This is the cleanest cross-edge trust model: the BEAM is the SINGLE writer of session state (it owns
  the handshake, `Codemojex.InitData`, and resolve-or-create), and every Go edge is a pure reader — so there is no
  cross-language write race, no duplicated HMAC-verify-and-mint logic to port to Go (the Go codec already does NOT
  mint — `branded.go` decodes/derives only, exactly matching this read-only posture), and the edge's trust reduces
  to two checks it can do with a stock client: the key namespace is `SES` (the kind gate, which it replicates by
  inspecting the branded id's first 3 bytes via `branded.Decode`) and the row exists + is unexpired (a `GET`
  returning non-nil). It mirrors the BCS law: the edge receives an IDENTITY (the brand) and reads a MESSAGE about
  it (the shared row), nothing more. For the consumer, "an edge reads, the BEAM writes" is the simplest possible
  contract.
- *Steward.* The keep-cost: a Go edge that needs to ACT on a session expiry (e.g. evict a derived view) must POLL
  the store (it cannot receive the BEAM coherence ring — see FD), so a revocation is visible to the edge only on
  its next read / at TTL, not pushed. That is the correct trade for a reader (an analytics edge does not need
  instant revocation), and the spec names it: a revoked/expired session becomes visible to a Go edge at its next `GET` or at the
  L2 `PX` expiry, never via a BEAM push. It also means any Go-side WRITE need (a future edge that must touch a
  session) reopens this fork — named, not foreclosed.

**Arm A2 — a Go edge may MINT/MUTATE the SES (a full cross-language session writer).** A Go edge can also mint a
session (port the verifier + resolve-or-create to Go) and mutate it (slide, revoke), so an edge is a first-class
session authority, not just a reader.

- *Rationale.* If an edge can write, a Go-only path (a future Go service that authenticates its own clients) needs
  no BEAM round-trip — full autonomy per edge.
- *5W / Steelman (brief).* Edge autonomy; no BEAM dependency for a Go-native auth path; symmetric capability.
  **Where** — every edge.
- *Steward.* The keep-cost is severe and cuts against the grounded reality: it requires PORTING the HMAC verifier,
  the resolve-or-create, AND the mint to Go (the Go codec deliberately does NOT mint today — `branded.go` is
  decode/derive only, so this is net-new Go surface contradicting the existing design), introduces cross-language
  WRITE races on the shared session (two writers, two languages), and duplicates the security-critical verify
  logic in a second language (two places to keep correct, the worst kind of duplication for an auth primitive). It
  makes every edge a session authority when the named edges (bitmapist marker/dashboard) are READERS. It is a far
  larger, riskier surface than any current consumer needs.

**Ranked recommendation (FA-2, Lens A): A1 (READ-ONLY verify), decisively.** The BEAM is the single session
writer (it owns the handshake, the verifier, resolve-or-create); every Go edge is a pure reader that trusts the
brand's namespace + the shared store — which is exactly what the grounded Go codec already supports (it decodes
and derives offsets, it does NOT mint, `branded.go`). This keeps one writer, no cross-language write race, and no
duplicated security-critical verify logic in Go. A2 (edge-mint) requires porting the verifier + mint to Go,
duplicates auth logic across languages, and introduces write races — a far larger surface than the reader edges
need. The spec names the consequence honestly: revocation/expiry becomes visible to a Go edge at its next read or at TTL (it
cannot receive the BEAM coherence push — FD), the correct trade for a reader.

> **Pre-empted spec-steward objection:** *"Read-only edges that cannot see an instant revocation are a security
> gap — a banned player's session stays trusted by a Go edge until that edge happens to re-read or the TTL
> elapses; a proper design pushes revocation to every consumer."* Answer: the asymmetry is real and named, and it
> is the correct trade for the edges that exist. The Go edges are ANALYTICS readers (bitmapist marking/counting
> cohorts) — they do not gate a player's game actions, so a marginally-stale revocation view marks a cohort bit a
> few seconds late, not a security breach (the player's ACTIONS are gated by the BEAM, which DOES see the
> revocation instantly via `invalidate/3` + coherence). Pushing revocation to a Go edge would require the edge to
> join the BEAM coherence ring (impossible — it is a stock Redis client, not a `Table` peer) or poll aggressively,
> both worse than reading-at-TTL for a reader. The short L2 `PX` TTL bounds the staleness window for any edge, and
> the spec states it: BEAM consumers get instant revocation (coherence + `invalidate`), Go readers get
> revocation-at-next-read / TTL — the CAP-segmented trade, each consumer taking the consistency it can reach.

### FA-3 — how the bearer (the SES branded id) flows on HTTP + socket + a Go edge

The bearer is the `SES` branded id (a 14-byte string). It flows: on **HTTP** via `Authorization: Bearer <SES>`
(FE); on the **socket** as a connect-params body field (FE), verified in `connect/3` by resolving the SES from
L2; to a **Go edge** as the `SES` id (or a `PLR` the edge resolves from it), read directly from L2 over a stock
Redis client. The session resolution on the BEAM is `EchoStore.Table.fetch(:cm_sessions, ses_id)` (L1 → L2 →
loader); on a Go edge it is a raw `GET ecc:{sessions}:<ses>` + version-strip + JSON-parse. The SES carries the
`PLR` (and the platform), so the player identity travels inside the shared session, and the `PLR` is the durable
cohort key the bitmapist edge marks against (NEW-1).

**FA whole-fork recommendation (Lens A):** a `SES`-branded session, minted by the BEAM at the handshake, stored
in Valkey (L2) fronted by EchoStore L1 (G7), value = JSON (FA-1/A1), Go edges read-only (FA-2/A1), bearer = the
SES id on HTTP + socket + the edge (FA-3). This SUPERSEDES the v1 A1-stateless-token recommendation under G6.

> **Pre-empted spec-steward objection (whole FA):** *"A stateful session in Valkey adds a per-request L2 resolve
> and a session store to operate — the very cost the v1 stateless token avoided; is the cross-edge requirement
> worth re-rendering the whole auth floor as a stateful store?"* Answer: the cross-edge requirement (G6) is not a
> preference to price against the stateless token — it is a hard constraint the stateless token CANNOT satisfy (a
> Go edge cannot verify a `Phoenix.Token`; the signing is BEAM-internal). Given a polyglot reader, the bearer
> MUST be resolvable from a shared store, which is a stateful session by definition. The cost is mitigated by the
> exact infrastructure G7 names: the per-request resolve is an L1 ETS hit in the BEAM (`fetch/3` — not an L2 round
> trip on a hit, `table.ex:63`), and the Go edge's resolve is a single `GET` it would make anyway. The session
> store is EchoStore, already operated for the games cache — the SES table is a third declared `Table`, not a new
> system. The stateless token was the right answer for a SINGLE-runtime consumer; a cross-runtime shared session
> is a different problem, and the SES-in-Valkey design is its grounded answer.

---

## §FB · Platform / identity binding — reconciled to the SES model

**The reconcile.** The v1 fork (B1 Telegram column / B2 identities table / B3 adapter seam) stands, now reconciled
to the split store: **the SES carries `platform` + `PLR` (in Valkey); the `PLR` stays in Postgres (the durable
identity); the platform→PLR binding is the handshake's resolve.** The fork is unchanged in shape; the SES is where
the resolved `(platform, PLR)` is CARRIED after the binding resolves.

- **Arm B3 (REC — the prior recommendation, reconciled).** `players.tg_user_id` (Venus-Postgres) behind a
  `Codemojex.Platform` adapter; the handshake's adapter resolves `(platform, external_id) → PLR`, then mints a SES
  carrying `{plr, platform}`. A second platform = a new adapter; the SES shape is unchanged (it always carries
  `{plr, platform}`). *Carry:* a second platform is additive (a new adapter) AND the SES contract does not change
  (the platform is already a SES field), so the shared-session value is platform-stable from day one.
- **Arm B2 (named generalization).** An `IDN`-branded `identities` table (UNIQUE `(platform, external_id) → PLR`);
  the adapter resolves through it. Named as the resolve-time generalization B3 routes to when a second platform is
  real. The SES still carries `{plr, platform}` — B2 changes only HOW the adapter resolves, not the SES.
- **Arm B1 (the floor).** The bare `tg_user_id` column, no seam. Reconciled: the SES still carries `{plr,
  platform: "telegram"}`, so even B1 keeps the SES platform-aware; B1 only lacks the resolve seam.

**Reconciled recommendation (Lens A): B3 (the adapter seam), SES carries `{plr, platform}`.** The key reconcile:
because the SES value carries `platform` (FA-1) regardless of the binding arm, the SHARED-SESSION contract is
platform-stable from the floor — a Go edge reads `platform` from the SES value the same way no matter which
binding arm ships. So FB's choice affects only the BEAM-side resolve (a column vs a seam vs a table), not the
cross-edge SES contract. B3 ships thin (Venus-Postgres's column) with the resolve polymorphic; B2 is the named
end-state. The relational shape is Venus-Postgres's.

> **Pre-empted spec-steward objection:** *"Putting `platform` in the SES value duplicates a fact the identity
> binding already holds — the SES should carry only the `PLR`, and the platform is derivable from the binding."*
> Answer: the SES carries `platform` precisely BECAUSE a Go edge reads the SES WITHOUT touching the Postgres
> binding — the edge has only the shared Valkey row, so a fact it needs (the platform) must be IN that row, not in
> a Postgres table it cannot reach. This is not duplication-as-drift (the binding is the source of truth at mint
> time; the SES is a derived read-snapshot for cross-edge consumers), it is the cross-edge contract requiring the
> shared row to be self-sufficient. The same reasoning the BCS law applies: the identity (the SES brand) carries
> the message (its fields) across the boundary, so a consumer on the far side needs no second lookup.

---

## §FC · The handshake shape — a dedicated auth endpoint that MINTS THE SES (reconciled)

**Reconciled to the SES model.** The v1 recommendation (C1, a dedicated `POST /api/auth/:platform`) stands; it now
MINTS THE SES in Valkey: verify `initData` → resolve `(platform, external_id) → PLR` → `EchoStore.Table.put(:cm_sessions,
ses_id, json)` → return the `SES` id. Every other route is SES-only (resolve the SES from L2). C2 (inline on every
endpoint) is rejected for the same reasons as v1, plus a new one: inline minting would scatter the SES-WRITE
(the single-writer authority FA-2/A1 depends on) across every endpoint.

**Recommendation (Lens A): C1 (a dedicated `POST /api/auth/:platform` that mints the SES).** It is G1's ordering as
a route (mint here, resolve everywhere else), it confines the SES-write to one action (preserving FA-2/A1's
single-writer model), and the `:platform` segment is FB/B3's adapter dispatch. EXPECT CONVERGENCE.

> **Pre-empted spec-steward objection:** *"A dedicated handshake adds a route + a startup round-trip."* Answer: the
> round-trip is G1's ruled shape, and confining the SES-MINT to one action is now load-bearing — it is what makes
> the BEAM the single session writer (FA-2/A1), which C2's inline minting would break by scattering writes across
> every endpoint.

---

## §FD · Token lifetime / renewal — SES TTL via EXPIRE + revocation via DEL (re-cascaded)

**Re-cascaded onto the SES model.** With the session in Valkey, lifetime and revocation are Valkey-native and
**visible to every consumer**: the SES TTL is the L2 `PX` (a sliding window via a re-`put`, `table.ex:290` +
`ttl-expiry.md`); revocation is `EchoStore.Table.invalidate/3` (`DEL` L2 + `:ets.delete`, `table.ex:174`) — and
because the row is in the shared store, a `DEL` is visible to a Go edge on its next read (FA-2/A1) and to every
BEAM peer via coherence.

- **Arm D1 (REC) — sliding TTL via re-`put` + revocation via `invalidate`.** The session slides on use (a re-`put`
  re-stamps the version + `PX`, the sliding move per `ttl-expiry.md`); a revoke is `invalidate/3` (`DEL`). *Carry:*
  this is FREE and SHARED — the TTL is the L2 `PX` every consumer honors, the revoke is a `DEL` reflected for every consumer
  at its next read; no refresh-token surface, no second credential. It is the redis-patterns sliding-session
  pattern (`ttl-expiry.md`) applied verbatim, and it bounds any cross-edge staleness (FA-2/A1) by the TTL.
- **Arm D2 (named) — a refresh token.** Named only for a platform with a one-time (non-re-readable) bootstrap; a
  Telegram `initData` is re-readable, so a silent re-handshake re-mints the SES with no refresh-token surface.
- **Arm D3 (collapses) — sliding-by-re-mint.** Under the SES model, "sliding" IS the re-`put` (D1), so D3
  collapses into D1; it is not a distinct arm here (the v1 D3 collision with statelessness is moot — the SES is
  already stateful, and EchoStore's re-`put` IS the slide).

**Re-cascaded recommendation (Lens A): D1 (sliding TTL via re-`put` + revocation via `invalidate`/`DEL`).** The
SES-in-Valkey model makes lifetime AND revocation Valkey-native and shared: the `PX` TTL every consumer honors,
the `DEL` revoke reflected for every consumer. This is the redis-patterns sliding-session pattern (`ttl-expiry.md`) and the
`invalidate/3` logout (`auth-session.md`) applied directly — zero new credential, and revocation that reaches the
Go edge (at its next read) and the BEAM (instantly, via coherence + `invalidate`). The TTL is the Operator's risk
dial; it also bounds the cross-edge revocation-staleness window (FA-2/A1).

> **Pre-empted spec-steward objection:** *"A `DEL`-based revocation reflected for a Go edge only at its next read is not
> immediate revocation."* Answer: for BEAM consumers it IS immediate (`invalidate/3` drops L1 + L2 and coherence
> propagates to peers); for a Go ANALYTICS reader, revocation-at-next-read bounded by the `PX` TTL is the correct
> trade (the edge marks cohorts, it does not gate actions — FA-2). The SES-in-Valkey model gives revocation that
> reaches EVERY consumer, BEAM-instant and edge-at-TTL, which the v1 stateless token could not do at all (no
> revocation before TTL, for any consumer).

---

## §FE · Token transport — the SES branded id as bearer (re-cascaded)

**Re-cascaded.** The bearer is the `SES` branded id (a 14-byte string). v1's E1 stands: `Authorization: Bearer
<SES>` on HTTP; the SES as a socket connect-params body field (not the query string); a Go edge holds the SES id
(or a PLR resolved from it). The SES id is a clean bearer — opaque, fixed-width, namespace-typed (the kind gate),
and language-neutral (a 14-byte ASCII string any client carries).

**Recommendation (Lens A): E1 (`Authorization: Bearer <SES>` + socket connect-params body field).** The SES
branded id is the bearer everywhere — HTTP, socket, and the Go edge — one fixed-width, namespace-typed, ASCII
string. EXPECT CONVERGENCE.

---

## §FG · Freshness / replay — auth_date max-age at the handshake + the SES TTL (re-cascaded)

**Re-cascaded.** v1's G1 stands, reconciled: the `initData` `auth_date` max-age bounds the bootstrap replay AT the
handshake (the SES mint), and the **SES TTL** (FD, the L2 `PX`) bounds the credential replay (a captured SES used
past its life). Two bounds, two replays — now the second bound is the SES `PX` rather than a token TTL.

**Recommendation (Lens A): G1 (auth_date max-age at the handshake + the SES TTL).** Two bounds for two replays;
the `auth_date` check is platform-recommended and already in the Stage-1 verifier; the SES `PX` TTL is the
credential-replay bound (FD). EXPECT CONVERGENCE.

---

## §NEW-1 · bitmapist marking — which events mark which cohorts, keyed by branded id

**The new fork (forward-vision).** The bitmapist edge marks cohort bits keyed by a branded id (`branded.Offset(id)`,
`Hash32(Decode(id))`). WHICH game events mark WHICH cohorts, and keyed by the `PLR` (durable) or the `SES`
(ephemeral)?

**The grounded reality (NO-INVENT):** bitmapist is a Go CLIENT over Doist's `bitmapist-server` on `:6400`;
`bitmapist.Client.Mark(ctx, event, brandedID, t)` marks a bit at `branded.Offset(brandedID)` across periods;
cohorts present in code/tests/README are **active, registered, played, paid**; the BEAM does NOT call it today —
the roadmap design is a Go MARKER fed by the events the game already emits + a Go dashboard reader (wiring planned
P1–P3, not built).

**Arm M1 (REC) — mark by the `PLR` (the durable identity), fire-and-forget from a Go marker fed by the existing
event stream.** The marker consumes the game's existing events and calls `Mark(ctx, cohort, plr, t)`: the handshake
(first auth) → `registered` + `active`; a guess → `played` + `active`; a buy → `paid`. Keyed by the `PLR` (the
durable cohort identity), NOT the SES (ephemeral).

- *Rationale.* A cohort is a DURABLE membership ("players who registered this week," "players who paid") — it must
  be keyed by the durable identity (`PLR`), not the ephemeral session (`SES`), or a player's cohort bit would
  fragment across sessions. The `PLR` is the branded id the Go codec offsets, so `branded.Offset(plr)` is the bit
  position, identical on the BEAM and the Go edge (the same vector).
- *5W.* **Why** — cohort analytics is per-player-over-time; the `PLR` is that identity. **What** — `Mark(ctx,
  cohort, plr, t)` per game event (forward-tense; the Go client + cohorts are grounded, the wiring is roadmap
  P1–P3). **Who** — the Go marker (writes), the Go dashboard (reads via `Count`/`AndCount`/`RetentionRow`). **When** —
  the forward-vision (NOT the cm.4 floor). **Where** — the Go marker in `infra/`, fed by the events the BEAM
  already emits.
- *Steelman.* Keying by the `PLR` is correct AND free: the `PLR` is already the branded id the game mints and the
  Go codec offsets identically (`branded.Offset(plr) == Hash32(Decode(plr))`, the same value the BEAM derives), so
  a cohort bit is stable across a player's sessions and a Go dashboard counts the real cohort. The marker is
  fire-and-forget (a `SETBIT` whose value is discarded, `store_redigo.go`), fed by the events the game ALREADY
  emits (the roadmap is explicit: "the Elixir game stays the source of events and needs no port of its own"), so
  the BEAM adds NOTHING — no port, no new emit, no coupling to `:6400`. The cohort→event map (registered/active at
  the handshake, played at a guess, paid at a buy) is the natural lifecycle the cohorts already name. The SES
  carries the `PLR`, so a future SES-aware path resolves the `PLR` for marking, but the mark itself is `PLR`-keyed.
- *Steward.* The keep-cost is entirely forward-vision: NOTHING in the cm.4 floor (the marker is unbuilt, roadmap
  P1–P3). When built, the cost is the Go marker's wiring (it consumes the existing event stream and calls `:6400`)
  + keeping the cohort→event map in one place. The cross-edge guarantee that `branded.Offset` matches the BEAM's
  hash is a CONTRACT to keep (the Go test vector `Offset("USR0KHTOWnGLuC") == 234878118` pins it; a BEAM-side
  change to the hash would break it) — but it is already pinned by the ported codec's contract test.

**Arm M2 (rejected) — mark by the `SES`.** Mark cohort bits keyed by the `SES` id.

- *Steward.* A `SES` is ephemeral (it expires, re-mints per login), so a cohort keyed by `SES` would COUNT
  SESSIONS, not players — "active this week" would inflate with every re-login, and "retention" would measure
  session-return, not player-return. It defeats the purpose of cohort analytics (per-player-over-time). Rejected:
  cohorts are `PLR`-keyed.

**Recommendation (NEW-1, Lens A): M1 (mark by the `PLR`, fire-and-forget from a Go marker fed by the existing
event stream) — FORWARD-VISION, not the cm.4 floor.** Cohorts are durable per-player memberships, so they key on
the `PLR` (the durable branded identity the Go codec offsets identically to the BEAM), not the ephemeral `SES`.
The marker consumes the events the game already emits (the BEAM adds nothing), marking registered/active at the
handshake, played at a guess, paid at a buy. This is roadmap P1–P3 (unbuilt) — surfaced here so the SES design
carries the `PLR` (it does, FA/FB) and the floor does not over-build the analytics edge.

> **Pre-empted spec-steward objection:** *"bitmapist marking is unbuilt and out of the cm.4 boundary — why design
> it at all?"* Answer: it is surfaced, not built — and the reason it belongs in THIS design is a single floor
> constraint it imposes: the SES must carry the `PLR` (so a future marker resolves the durable cohort key from a
> session), which FA/FB already provide. Designing the marking forward confirms the floor's SES shape is
> sufficient for the forward consumer WITHOUT building the consumer — exactly the design-ahead purpose. The
> marking itself is roadmap P1–P3 and explicitly OUT of the cm.4 floor (the phasing fork).

---

## §NEW-2 · LiveView — authenticating off the same shared SES (forward-vision)

**The new fork (forward-vision, G9).** A Phoenix LiveView (the admin/live surfaces) must authenticate off the SAME
shared SES.

**Arm L1 (REC) — LiveView resolves the SES from the shared store (the same `EchoStore.Table.fetch(:cm_sessions,
…)` the controllers use).** A LiveView mount reads the SES id (from the connect params / a signed session the
initial HTTP carried) and resolves it via the same `fetch(:cm_sessions, ses_id)` (L1 → L2), assigning the player —
the identical resolution the HTTP plug and the socket use.

- *Rationale.* LiveView is a BEAM consumer of the shared session; resolving the SES through the same
  `EchoStore.Table` path the controllers + the socket use means ONE session-resolution surface across HTTP,
  channel, and LiveView — no separate LiveView auth.
- *5W.* **Why** — one session, one resolution path, every BEAM surface. **What** — a `mount/3` that resolves the
  SES via `fetch(:cm_sessions, …)` and assigns the player (forward-tense; the SES table + `fetch/3` are the
  grounded surfaces). **Who** — the admin/live LiveView surfaces. **When** — the forward-vision (G9; not the cm.4
  floor). **Where** — the LiveView modules (forward-tense).
- *Steelman.* LiveView gets the session for free: it is a BEAM process, so it uses the SAME L1-ETS-fronted
  `fetch(:cm_sessions, ses_id)` the controllers use (an L1 hit, no L2 round trip), and it applies the SAME coherence
  (a revocation `invalidate`s the row and the LiveView's next resolve fails closed). The SES carries the `PLR` +
  platform, so a LiveView has the player identity from the shared session with no separate lookup. One session
  resolution surface across HTTP + socket + LiveView is the cleanest possible auth model for the BEAM consumers
  (the mirror of the Go edge's read-only L2 access — both resolve the same SES, each by its reachable tier).
- *Steward.* The keep-cost is forward-vision (G9; not the cm.4 floor). The one detail: LiveView's initial mount is
  over HTTP (the SES bearer arrives as the controllers receive it) and the live socket re-verifies on the
  LiveView socket connect — the same FE bearer flow, applied to the LiveView socket. Named, deferred.

**Recommendation (NEW-2, Lens A): L1 (LiveView resolves the SES via the same `fetch(:cm_sessions, …)`) —
FORWARD-VISION (G9), not the cm.4 floor.** LiveView is a BEAM consumer; resolving the shared SES through the same
EchoStore path gives one session-resolution surface across HTTP, channel, and LiveView, with the same L1 hit and
the same coherence. Surfaced to confirm the floor's SES design serves LiveView (it does — a BEAM `fetch` of the
shared table) without building the LiveView surfaces now.

> **Pre-empted spec-steward objection:** *"LiveView session auth has subtleties (the mount-over-HTTP-then-socket
> handshake, CSRF on the live socket) the floor cannot ignore."* Answer: those subtleties are real and they are
> WHY this is forward-vision, not floor — the cm.4 floor ships the SES, the HTTP plug, and the channel; the
> LiveView surfaces (G9) are a later rung. What the floor must guarantee is that the SES design CAN serve LiveView,
> which L1 confirms (a BEAM `fetch(:cm_sessions, …)` is exactly what a LiveView mount would call). The mount/socket
> handshake detail is the LiveView rung's, designed when those surfaces are built.

---

## §PHASING · what ships in the cm.4 FLOOR vs the forward rungs

A clean line, so the floor closes the security gap without over-building the cross-edge/analytics/LiveView vision:

**The cm.4 FLOOR rung ships:**

- The pure verifier `Codemojex.InitData.verify/3` (G4) — at the handshake.
- The dedicated handshake `POST /api/auth/:platform` (FC/C1) that verifies → resolves `(platform, external_id) →
  PLR` (Venus-Postgres) → MINTS the `SES` in Valkey via `EchoStore.Table.put(:cm_sessions, …)` with a **JSON**
  value (FA-1/A1) carrying `{plr, platform, …}`.
- The `:cm_sessions` EchoStore table (a third declared `Table`, kind `SES`, a JSON loader — NOT
  `:erlang.term_to_binary`; coherence per the mutable-session question, see the PHASING-note), and the SES-resolve
  plug (`fetch(:cm_sessions, …)` → assign the player) over the 5 player-acting routes + the socket connect (FE).
- The `require_player → conn.assigns.player` cutover; retire `POST /api/players` (G3); the dev/test posture (FF);
  sliding TTL + `invalidate` revocation (FD/D1); the `auth_date` freshness (FG).

**The FORWARD rungs (surfaced, NOT the floor):**

- The Go-edge READ contract (FA-2/A1): the documented L2 read shape (the 14-byte version-strip + JSON-parse +
  namespace-check) a Go edge uses — a CONTRACT the floor's SES shape must satisfy, but the edge consuming it is
  forward.
- bitmapist marking (NEW-1/M1): the Go marker fed by the existing event stream, `PLR`-keyed cohorts — roadmap
  P1–P3, unbuilt.
- LiveView auth (NEW-2/L1, G9): the admin/live surfaces resolving the shared SES.
- Graft durability of the SES (G7's echo-persistence): a SES is ephemeral + TTL'd, so folding it to
  `EchoStore.Graft` (CubDB → Tigris) for cross-region durability is a forward question, NOT the floor (the floor's
  SES lives in Valkey L2 + EchoStore L1; Graft-durability of an ephemeral session is deferred).

**PHASING-note — the mutable-session coherence decision the floor MUST make (a real fork for Venus-Postgres + the
Director):** the two existing EchoStore caches are `coherence: :none` ONLY because their entities are immutable
for life (`Codemojex.Tables` moduledoc). **A session is MUTABLE** (last-seen slide, revocation), so `:cm_sessions`
CANNOT be `:none`. The floor must declare a coherence mode: **`:broadcast`** (the versioned app-level lane — every
BEAM `Table` peer applies a revocation/slide as "a message about a name", the BCS law literal) is the
consumer-lens recommendation for the BEAM consumers (Phoenix peers + LiveView resolve a revoked session as a clean
miss instantly); a Go edge is NOT a `Table` peer (it reads L2 directly), so it reads revocation at its next read /
TTL regardless of the coherence mode (FA-2/A1). `:tracking` (RESP3 `CLIENT TRACKING`) is the alternative (the
store pushes invalidation). This is a floor decision — surfaced, the Director rules with Venus-Postgres (the
relational + coherence shape is theirs).

---

## §Summary — the ranked recommendations (Lens A, v2)

| Fork | Lens-A v2 REC | The one carrying reason |
|---|---|---|
| **FA** (RE-RULED) the SES-in-Valkey design | a `SES`-branded session in Valkey, EchoStore L1-fronted; **FA-1 JSON** value; **FA-2 read-only** Go edges; **FA-3** the SES id as bearer | A Go edge cannot verify a Phoenix-internal token (G6); a `SES` in the shared store, JSON-valued, is the bearer any service resolves — the v1 A1-stateless token is SUPERSEDED |
| **FB** identity binding | **B3** adapter seam, SES carries `{plr, platform}` | A 2nd platform is additive AND the shared-SES contract is platform-stable from the floor (platform is a SES field regardless of the binding arm) |
| **FC** handshake | **C1** a dedicated `POST /api/auth/:platform` that MINTS the SES | G1's ordering as a route; confines the SES-WRITE to one action (FA-2/A1's single-writer model) |
| **FD** lifetime / revocation | **D1** sliding TTL via re-`put` + revocation via `invalidate`/`DEL` | Valkey-native + SHARED — the `PX` TTL every consumer honors, the `DEL` revoke reflected for every consumer (BEAM-instant, edge-at-TTL) |
| **FE** transport | **E1** `Authorization: Bearer <SES>` + socket connect-params body | The SES id is one fixed-width, namespace-typed, ASCII bearer for HTTP + socket + the Go edge |
| **FG** freshness / replay | **G1** `auth_date` max-age at the handshake + the SES TTL | Two bounds for two replays (a stale bootstrap re-minting; a captured SES used past its `PX`) |
| **NEW-1** bitmapist marking | **M1** mark by the `PLR`, fire-and-forget from a Go marker fed by the existing event stream — FORWARD | Cohorts are durable per-player memberships → keyed by the `PLR` (the codec offsets it identically to the BEAM), not the ephemeral SES |
| **NEW-2** LiveView | **L1** resolve the SES via the same `fetch(:cm_sessions, …)` — FORWARD (G9) | LiveView is a BEAM consumer → one session-resolution surface across HTTP, channel, and LiveView |

## §Where this lens most expects to DIVERGE from the spec-steward lens (the highest-value signals)

1. **FA-1 (SES value encoding) — A1 JSON vs the steward's likely A2 Valkey HASH.** This lens weights the
   language-neutral, EchoStore-`Table`-compatible framed-String-of-JSON (keeps L1 + coherence + the kind gate); a
   steward may weight the HASH's in-place field updates + Redis-native idiom — but the HASH FORFEITS the entire
   `EchoStore.Table` tier (it is not a framed String). A divergence on whether field-level updates are worth
   leaving EchoStore.
2. **FA-2 (Go-edge trust) — A1 read-only vs a steward's possible concern about revocation-staleness at the edge.**
   This lens weights one-writer + no duplicated-verify-in-Go + the analytics-reader trade (revocation-at-TTL is
   fine for a cohort marker); a steward may weight pushing revocation to every consumer. A divergence on the
   CAP-segmented edge-staleness trade.
3. **The PHASING-note mutable-session coherence — `:broadcast` vs `:tracking` (or a steward's stricter posture).**
   This lens recommends `:broadcast` for the BEAM consumers (and names the Go edge as L2+TTL regardless); a steward
   may weight `:tracking` (server-pushed) or a different consistency posture for a mutable auth row. A real
   divergence on the coherence mode of the first MUTABLE EchoStore table.

(FC, FD, FE, FG converge — re-cascaded onto the SES model, the consumer and steward lenses point the same way.
NEW-1 and NEW-2 are forward-vision; their divergence, if any, is lower-stakes than the floor forks.)

## §What this lens deliberately did NOT decide (the discipline)

- **Every fork SURFACED, not ruled.** The ranked arm is a recommendation with its one carrying reason; the choice
  is the Operator's.
- **The mutable-session coherence mode** (`:broadcast` vs `:tracking`) and the relational shape (the SES table's
  loader, the `tg_user_id`/`identities` binding, resolve-or-create) are Venus-Postgres's + the Director's — this
  lens surfaces the cross-edge CONSTRAINTS (language-neutral value, the `PLR` in the SES, the L2-read contract),
  not the relational/coherence decision.
- **The exact TTLs** (the SES `PX`, the `auth_date` max-age) are the Operator's risk dial.
- **The bitmapist wiring** (NEW-1) and **the LiveView surfaces** (NEW-2) are forward-vision rungs (roadmap P1–P3 /
  G9), explicitly OUT of the cm.4 floor — surfaced to confirm the floor's SES shape serves them.
- **SES durability via Graft** (G7's echo-persistence) — deferred (an ephemeral TTL'd session does not need
  cross-region page durability at the floor).
- **The `SES`/`IDN` namespace registration** — named here as free (verified), registered at the build.
- **The cm.4 triad re-authoring** — the post-ruling step (the chosen arms flow into the triad), not this doc's.

## §Surface citations (NO-INVENT — every named surface grounded)

**Verified as-built (real `module/file`):**

- `CodemojexWeb.GameController.require_player/1` + the 5 actions — `echo/apps/codemojex/lib/codemojex_web/controllers/game_controller.ex:77` (join/guess/history/buy_keys/convert at 30/44/51/61/69); `create_player/2` at 14 (RETIRED by G3).
- `CodemojexWeb.UserSocket.connect/3` + `id/1` — `…/channels/user_socket.ex:7,10`; the socket mount `/socket` at `endpoint.ex:5`.
- `Codemojex.Bot.token/0` — `…/codemojex/bot.ex:39` (the HMAC key source, G4).
- `Codemojex` facade — `…/codemojex/game.ex:183`; `Wallet.create/2` (`wallet.ex:20`, mints `EchoData.BrandedId.generate!("PLR")`); `Codemojex.Schemas.Player` (`schemas/player.ex`).
- `EchoStore.Table` — `echo/apps/echo_store/lib/echo_store/table.ex`: coherence modes `:none`/`:broadcast`/`:tracking` (`table.ex:22-24`); `fetch/3` (`table.ex:63`); `put/3` mints the version (`table.ex:90`); `put/4` caller version (`table.ex:97`); `invalidate/3` `DEL` L2 + `:ets.delete` (`table.ex:174`); the framed-String write `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms` (`table.ex:290`) + the read split `<<version::binary-14, value::binary>>` (`table.ex:429`); the kind gate `gate/2` (refuses a wrong-namespace id with zero keys, per `auth-session.md`).
- `Codemojex.Tables` — `…/codemojex/tables.ex`: the two near-caches `:cm_games`/`:cm_emojisets`, both `coherence: :none` because immutable-for-life (the moduledoc); the loaders frame with `:erlang.term_to_binary` (`tables.ex:92,100`) — the BEAM-only encoding a Go edge cannot read (so the SES loader must be JSON).
- `EchoStore.Graft` (echo-persistence) — `echo/apps/echo_store/lib/echo_store/graft.ex`: `open_volume/2` (`:31`), `read/2` (`:47`), `read_at/3` (`:54`), `commit/3` (`:41`), `push/1` (`:44`).
- `Codemojex.Wire` (`…/codemojex/wire.ex`) + `Codemojex.Bus` (`…/codemojex/store.ex:108`, `EchoWire.start_link(port: 6390, protocol: 3)`); `valkey_port` (`application.ex:21`).
- `:crypto.mac/4` + `:crypto.hash_equals/2` — OTP `crypto`, confirmed OTP 28 (G4); pure OTP.
- `Phoenix.Token` — rides `phoenix ~> 1.7` (`mix.exs:55`); `secret_key_base` per-env (the v1 stateless arm's substrate — now SUPERSEDED by G6, cited only to record the supersession).
- `Jason` — `mix.exs:58` (the JSON codec for the SES value, FA-1/A1).
- The Go edge `infra/codemojex-bitmapist/`: a CLIENT library (no `main.go`) over Doist's `bitmapist-server` on `codemojex-bitmapist.internal:6400` (RESP2, redigo `gomodule/redigo v1.9.2`, a 6PN-private Fly app, `deploy/{fly.toml,Dockerfile}`). The branded codec `branded/branded.go`: `Encode/Decode/Hash32/UnixMs/Offset`; `Offset(id) = Hash32(Decode(id))`; contract vectors `Offset("USR0KHTOWnGLuC") == 234878118`, `Hash32(274557032793636864) == 234878118` (`branded_test.go`); it does NOT mint. The API `bitmapist/bitmapist.go`: `New(store, opts...)`, `Mark(ctx, event, brandedID, t)`, `MarkUnique`, `In`, `Count(ctx, event, t, period)`, `AndCount/OrCount/XorCount(ctx, keys...)`, `RetentionRow(ctx, cohortKey, followKeys)`, `Key(event, t, period)`. Cohorts in code/tests/README: active, registered, played, paid. The marker/dashboard wiring is roadmap P1–P3 (unbuilt) — `infra/codemojex/codemojex.bitmapist.roadmap.md`.

**Forward-tense (surface this design proposes — not yet on disk):**

- `Codemojex.InitData.verify/3` (the pure verifier, G4; at the handshake).
- `Codemojex.Wallet.resolve_or_create/2` + `players.tg_user_id` UNIQUE (Venus-Postgres) — the handshake's identity resolution.
- The `:cm_sessions` EchoStore table (kind `SES`; a JSON loader; the mutable-session coherence mode per the PHASING-note); the SES-resolve plug (`fetch(:cm_sessions, …)` → assign the player) + the socket-connect resolve.
- `AuthController.handshake/2` + `POST /api/auth/:platform` (FC/C1) — verify → resolve `(platform, external_id) → PLR` → `EchoStore.Table.put(:cm_sessions, ses_id, json)`.
- The `Codemojex.Platform` adapter behaviour + `Codemojex.Platform.Telegram` (FB/B3); the `IDN` `identities` table (FB/B2, the named generalization).
- The Go-edge READ contract (FA-2/A1): the L2 read shape (version-strip + JSON-parse + namespace-check) — forward.
- The Go marker (NEW-1/M1): `Mark(ctx, cohort, plr, t)` fed by the existing event stream — roadmap P1–P3.
- The LiveView SES resolve (NEW-2/L1, G9).

**Canon / design cited (NOT a code surface):** the Operator's GIVENs G1–G9 (this session); the v1 Lens A + the
synthesis (the A1-stateless recommendation this v2 SUPERSEDES under G6); the redis-patterns session-management
dives (`docs/redis-patterns/markdown/caching/session-management/{auth-session,encodings,ttl-expiry}.md` — the
SES-keyed EchoStore row + the kind gate, the Hash/String/JSON encoding trade, the sliding `PX` TTL + `invalidate`
logout); the Telegram WebApp spec (core.telegram.org/bots/webapps — the `auth_date` recommendation, the
`hash`+`signature` exclusion); the bitmapist roadmap (`infra/codemojex/codemojex.bitmapist.roadmap.md` — the
marker/dashboard wiring, P1–P3); the method of record
[`docs/aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md); the BCS law (`echo/CLAUDE.md` —
identities cross the boundary, a relation is a system; coherence is a message about a name).
