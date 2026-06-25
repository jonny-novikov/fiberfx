# Codemojex Auth Flow (the cm.4 re-scope) — Design-ahead, Lens B (store / steward / security / persistence)

> **Lens B — the store-and-threat-model maintainer's lens.** Every fork below is argued from the view of the
> maintainer who **freezes the SHARED session surface for years** AND the **threat model of a shared store**.
> The weights are fixed: the **SES key schema + a LANGUAGE-NEUTRAL encoding** a Go edge can decode; the
> **EchoStore coherence mode for a MUTABLE session** (a revoked SES must not survive in any edge's L1 — the
> staleness window IS a security property); the **durability tier** (is a session worth Graft-backed
> replication, or is re-handshake cheaper than persistence?); **TTL/EXPIRE + revocation-by-DEL**; the
> **threat model of a shared store** (a bigger breach target; the **Go-edge trust boundary** — read-only
> verify vs mint/mutate; can a compromised edge forge a SES?); the invariants (one-PLR-per-verified-identity
> intact; the SES carries the `PLR`, the `PLR` stays in Postgres). Where a fork trades consumer-ease for
> invariant-soundness or a smaller secure surface, **soundness wins** — but the Steelman honors the consumer's
> real need, and each Arm pre-empts the strongest objection the **consumer / client-platform lens (Lens A)**
> will raise.
>
> **This revision supersedes the prior draft on FA/FD.** The Operator's structural GIVENs (G6–G9 below) RE-RULE
> FA: a stateless Phoenix.Token is OVERRULED — a Go lightweight edge cannot verify a BEAM-internal token, so the
> bearer is a **SES id resolved from a SHARED VALKEY STORE by any service.** The prior recommendation
> (A1-stateless) is marked **SUPERSEDED-BY-G6** where it appears, its record kept. Authored **independently** —
> the sibling revised Lens A was **not read**. Forks are **SURFACED, never decided.** The Director synthesizes;
> the Operator rules.

---

## §0 Context

**The reshape.** The session is no longer a Phoenix-internal credential. It is a **shared session** read by
**Phoenix + Go lightweight edges + LiveView**, so the bearer must be resolvable by **any** service from a
**shared store** — Valkey. The auth flow is unchanged in shape (a one-time `initData` handshake mints the
session; the session authenticates later HTTP + the socket) but the session's **substance** moves from "a
signed string only the BEAM can read" to "**a SES record in Valkey any runtime can read.**"

**The as-built floor (verified at source — `file:line` for as-built; forward-tense for unbuilt).**

- **The trust points the flow replaces.** `CodemojexWeb.GameController.require_player/1`
  ([`game_controller.ex:77`](../../../../echo/apps/codemojex/lib/codemojex_web/controllers/game_controller.ex))
  reads `params["player"]` verbatim (5 player-acting endpoints). `CodemojexWeb.UserSocket.connect/3`
  ([`user_socket.ex:7`](../../../../echo/apps/codemojex/lib/codemojex_web/channels/user_socket.ex)) is
  `{:ok, socket}`, `id/1 → nil`. **The worst gap:** `create_player/2`
  ([`game_controller.ex:14`](../../../../echo/apps/codemojex/lib/codemojex_web/controllers/game_controller.ex),
  `POST /api/players`, [`router.ex:12`](../../../../echo/apps/codemojex/lib/codemojex_web/router.ex)) — an
  **unauthenticated** PLR mint with **attacker-supplied opening balances** (anonymous identity + free
  currency). G3's retirement is **security** work.
- **The SES store substrate (re-probed — this is the lens's center).** `EchoStore.Table` is the declared
  L1-ETS-over-L2-Valkey near-cache
  ([`table.ex`](../../../../echo/apps/echo_store/lib/echo_store/table.ex)). Its real surface for a session:
  - `put/3` mints a branded version (`BrandedId.generate!(spec.kind)`, `table.ex:93`) and writes **both
    layers**: `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms` (`table.ex:290`). `put/4` carries a
    caller-supplied version.
  - The value is a **framed String** — `<<version::binary-14, value::binary>>` (`table.ex:429`); the 14-byte
    version prefix is **the coherence mechanism** (newer-wins). **NOT a Valkey HASH.**
  - `invalidate/3` (`table.ex:174`, "the admin verb") drops both layers unconditionally (`DEL` L2 +
    `:ets.delete`) — **the logout/revoke primitive.**
  - The **kind gate** `gate/2` (`table.ex:495`) refuses a wrong-namespace id (`byte_size==14 and
    binary_part(id,0,3)==kind and BrandedId.valid?`) with **zero keys on the wire** — a `USR` id can never be a
    `SES` key (the one-SES-per-key kind law, already in the store).
  - **The three coherence modes are declared on `start_link` (`coherence:` opt, default `:none`,
    `table.ex:204`):** `:none` · `:broadcast` (the versioned app-level pub/sub lane, 29-byte `id:version`,
    `table.ex:224,235`; `Coherence.broadcast/4` → `PUBLISH ecc:{table}:coh`, `coherence.ex:82`) · `:tracking`
    (server-assisted CLIENT TRACKING — Valkey pushes an invalidation for **any write** to this table's
    `ecc:{table}:` prefix, `table.ex:256,558`).
  - L1 expiry is a **jittered** per-row clock `expires_at/1 = ttl ± ttl·jitter` (`table.ex:484`) + a `:sweep`
    reclaimer (`table.ex:350`) — **each layer is sovereign over its own staleness.**
- **codemojex's existing tables use `coherence: :none`** (`tables.ex:61,72`) — **but they hold GAM/EMS, which
  are IMMUTABLE for their life** (`tables.ex` moduledoc: "the cache never goes stale and the coherence mode is
  `:none`"). **A mutable, revocable SES is the opposite case** — `:none` is **wrong** for it (see FA-coherence
  + FD).
- **The durability tier (re-probed).** `EchoStore.Graft` — `open_volume/2` (`graft.ex:31`), `read/2`
  (`graft.ex:48`), `read_at/3` (`graft.ex:56`) — the CubDB → Tigris page engine ("echo-persistence"). Grounds
  the durable-SES question.
- **The HMAC key source (survives).** `Codemojex.Bot.token/0`
  ([`bot.ex:39`](../../../../echo/apps/codemojex/lib/codemojex/bot.ex)) resolves the bot token — the WebApp
  secret `HMAC-SHA256("WebAppData", token)`; **no new secret, no new dep** (`:crypto` is OTP).
- **What Stage-1 established (carried).** `players.tg_user_id` (nullable `bigint`, partial unique index
  `players_tg_user_id_index`) + `Codemojex.resolve_player_by_tg/2` (resolve-or-create, idempotent, the index
  the sole enforcer). Full spec: [`../../specs/cm.4.postgres.design.md`](../../specs/cm.4.postgres.design.md).
  **The PLR stays in Postgres (durable); the SES lives in Valkey (ephemeral) and REFERENCES the PLR.** The
  handshake mints **both** — the PLR (Postgres, durable identity) and the SES (Valkey, the bearer).
- **Forward-tense (do NOT exist — named for the design only).** `Codemojex.InitData` (the verifier), the SES
  module / table declaration, the handshake route, the `:auth` plug, the Go-edge read contract — all unbuilt.

**The GIVENs (Operator-ruled — carried by BOTH lenses, designed-to, never re-litigated).**

- **G1** — dual-auth: `initData` is a one-time bootstrap exchanged at an HTTP handshake (the first screens,
  before the socket) for a session; the session authenticates all later HTTP + the socket.
- **G2** — platform-pluggable: Telegram is one platform; the session is platform-agnostic; `initData` is the
  Telegram adapter's bootstrap.
- **G3** — `POST /api/players` RETIRED; identity creation is a side effect of first authentication.
- **G4** — the verifier survives at the handshake (`Codemojex.InitData` HMAC: data-check-string excludes
  `hash` AND `signature`; secret = `HMAC-SHA256("WebAppData", token)`; `:crypto.hash_equals`; token via
  `Bot.token/0`); the Stage-1 resolve-or-create PLR path runs at the handshake.
- **G5** — the 8 story suites stay byte-unchanged + 41/0; boundary `echo/apps/codemojex/**`.
- **G6 — SHARED SESSION (RE-RULES FA).** The session is shared across Phoenix + Go lightweight edges +
  LiveView. A Go edge cannot verify a BEAM-internal stateless token → the bearer is a **SES id resolved from a
  SHARED STORE by ANY service.** A1 (stateless Phoenix.Token) is **OVERRULED** → a **stateful SES, stored in
  Valkey.**
- **G7 — SES IN VALKEY via EchoStore + echo-persistence.** The SES lives in Valkey (shared L2), fronted by
  EchoStore's ETS-L1 near-cache, durable via echo-persistence (`EchoStore.Graft`, CubDB → Tigris); applying
  the Redis session-management patterns (`auth-session.md`, `encodings.md`, `ttl-expiry.md`). **The SES VALUE
  must be LANGUAGE-NEUTRAL** (a Go edge decodes it) — **NEVER an Erlang term.**
- **G8 — bitmapist** (`infra/codemojex-bitmapist/`): a Go cohort-analytics edge (Doist bitmapist4 port),
  **branded-id-native** (`branded/branded.go` ports the BCS codec; `placement("USR0KHTOWnGLuC") = 234878118`),
  a **separate** minimal-Redis Fly app on **:6400** (RESP2/redigo), keyed by **branded id**. Both an analytics
  consumer AND a Go edge that reads shared branded state.
- **G9 — LiveView**: the session design serves Phoenix LiveView in the forward vision.

**The one question the WHOLE auth flow must answer well, from this lens.**

> Does the **shared-SES-in-Valkey** model give every runtime (Phoenix, a Go edge, LiveView) a session it can
> **read and trust** from one store, with a **language-neutral** value, a **mutable-session coherence** that
> makes a revoke (`DEL`) reach **every** holder's L1 (or a NAMED staleness bound), and a **durability tier**
> sized to a session's worth — while keeping **one-verified-identity-per-PLR** intact (the PLR durable in
> Postgres, the SES referencing it) and growing the **smallest shared attack surface**, with the **BEAM the
> sole SES-minting authority** and the edges constrained to what they may safely do?

The reshape changes the central risk. The prior (stateless) model had **no shared bearer state to breach**; the
shared-SES model puts the **session in one Valkey store every runtime touches** — a **bigger breach target**,
a **cross-language encoding contract**, and a **multi-runtime coherence problem** (a revoke must purge every
edge's L1). The gain (G6's whole point) is that a Go edge can **verify** a session at all — impossible against a
BEAM-internal token. The flow is sound iff: the SES value is **language-neutral** (FA-encoding), the **coherence
mode reaches every edge's L1 on revoke** (FA-coherence + FD), the **durability tier** matches a session's worth
(FA-durability), the **mint authority is the BEAM alone** (the Go-edge trust fork), and the **identity invariant
is unbroken** (the PLR stays in Postgres; the SES references it).

---

## §1 — FA · The SES-in-Valkey schema (the HEADLINE fork — RE-RULED by G6; deepest Arms)

> **G6 re-rules the prior FA.** The prior draft recommended **A1 (stateless Phoenix.Token)** for the smallest
> surface. **SUPERSEDED-BY-G6:** a Go lightweight edge **cannot** verify a BEAM-internal signed token (it has
> no access to the BEAM's signing internals / `secret_key_base` semantics), so a stateless token **cannot be
> the shared bearer.** The session **must** be a **stateful SES record in a shared store any runtime reads**
> (G6/G7). FA is therefore no longer "stateless vs stateful" — that is **decided** (stateful, in Valkey). FA is
> now the **SES schema**: the **key**, the **value encoding**, the **coherence mode**, and the **durability
> tier**. The prior A2 (stateful sessions) is the **ruled** direction; this section designs it.

The four sub-questions of the SES schema, each argued as its own Arm set, because each freezes a distinct
contract a Go edge depends on.

### FA-key — the SES key

**Arm K1 — `ecc:{sessions}:<SES>`, the EchoStore-native key** *(RECOMMENDED)*. The SES is an `EchoStore.Table`
of kind `"SES"`; the key is the store's own `ecc:{<table>}:<id>` shape (`auth-session.md` grounds it:
`SET ecc:{sessions}:SES0KH… …`). The braced `{sessions}` is the hashtag slot; the `<SES>` is the 14-byte
branded id.

- **Rationale.** The SES rides EchoStore's existing keyspace + kind gate + near-cache **unchanged** — the
  store already mints, frames, TTLs, and gates this shape. A Go edge reads `ecc:{sessions}:<SES>` directly.
- **5W.** *Why* — reuse the store's proven key + gate for the session. *What* — an `EchoStore.Table` kind
  `"SES"`, key `ecc:{sessions}:<SES>`. *Who* — the handshake (BEAM) writes via `put`; Phoenix/LiveView read via
  `fetch`; a Go edge reads the raw Valkey key. *When* — the cm.4 floor. *Where* — a new `Codemojex.Sessions`
  table declaration in `tables.ex` (forward-tense) + the `SES` kind in the branded codec.
- **Steelman.** Zero new keyspace invention — the SES is a first-class EchoStore table beside GAM/EMS, so the
  kind gate (`gate/2`, `table.ex:495`) makes "a non-`SES` id used as a session key" **unrepresentable** at the
  door (zero keys on the wire), and the L1/L2/TTL/coherence machinery is the store's, already tested. The Go
  edge's read contract is "a `GET ecc:{sessions}:<SES>`, strip the 14-byte version frame, decode the value" —
  one documented shape. The branded `SES` id is the bearer (FE), and it **sorts and gates** like every other
  branded id (the BCS thread).
- **Steward.** The cost: the SES key is now in the **shared `ecc:` keyspace** a Go edge reads — so the
  **version-frame stripping** (the 14-byte prefix) becomes a **cross-language contract** (FA-encoding handles
  it). And the kind `"SES"` must be added to the branded codec's known kinds (a one-line additive registration).
  Both small, named.

**Arm K2 — a bespoke `cm:ses:<SES>` key outside `ecc:`** (bypassing EchoStore's keyspace). *Steward* — a
bespoke key forfeits the kind gate, the near-cache, and the coherence lane (all keyed to `ecc:{table}:`), so
the SES would need its **own** L1, its **own** invalidation, and its **own** gate re-implemented — duplicating
what EchoStore gives for free, and putting a second session-storage discipline in the tree. The steward refuses
to fork the store's keyspace for the session when the SES is exactly what EchoStore is built to hold.

**Ranked (FA-key): K1 (`ecc:{sessions}:<SES>`), strongly** — the SES is an EchoStore table; the kind gate makes
the one-SES-per-key law structural; the Go edge gets one documented key shape.

### FA-encoding — the language-neutral SES value (the cross-language crux)

**The G7 requirement: the value is decodable by a Go edge — NEVER an Erlang term.** This is the fork the
reshape most sharpens, because EchoStore's native value is a **framed String** (`<<version::14, value>>`,
`table.ex:429`), and the framing is **inside** the contract a Go edge must parse.

**Arm E1 — EchoStore framed-String with a JSON inner value** *(RECOMMENDED)*. The stored bytes are
`<<version::binary-14, json::binary>>` where `json` is a flat JSON object of named fields:
`{"player":"PLR…","platform":"telegram","tg_user_id":123,"issued_ms":…,"expires_ms":…}`. The BEAM writes via
`EchoStore.Table.put/4` (carrying the version); a reader (BEAM or Go) **strips the leading 14 bytes** and parses
the JSON.

- **Rationale.** JSON is the **lingua franca** every runtime decodes (Go's `encoding/json`, Elixir's `Jason`);
  it satisfies G7 ("never an Erlang term") directly, and it rides EchoStore's framed-String unchanged (the
  version prefix stays the coherence mechanism). The fields are flat and few (`auth-session.md`'s "lean
  record": a `SES`, a player id, the platform, the timestamps).
- **5W.** *Why* — a value any runtime decodes, inside the store's framed-String. *What* —
  `<<version::14, json::binary>>`; flat JSON of named string/int fields. *Who* — the BEAM encodes (Jason +
  `put/4`); Phoenix/LiveView/Go decode (strip 14, parse JSON). *When* — cm.4 floor. *Where* — the
  `Codemojex.Sessions` encode/decode helpers (forward-tense) + the **documented Go read contract** (strip-14
  + JSON).
- **Steelman.** JSON is **self-describing, debuggable** (`GET` the key and read it by eye), and **universally
  decodable** — the steward's "language-neutral" requirement met with the least-surprise format. It keeps the
  **version frame** (so the SES participates in EchoStore coherence newer-wins like every other row — a revoke
  or a re-auth is a versioned event), while the **inner** JSON is what crosses the language boundary. The Go
  edge's contract is two well-known operations (a fixed-width strip + a JSON parse), both trivially correct in
  Go. The record is lean (G7's memory-optimization guidance), so the JSON is small.
- **Steward.** Two named costs. (1) The **strip-14 contract is load-bearing and cross-language** — a Go edge
  that forgets the version prefix parses garbage; the steward makes "strip the 14-byte version, then parse
  JSON" a **documented, tested** read contract (a Go-side fixture asserting it). (2) JSON is **bytes-heavier**
  than msgpack/a HASH for the same fields — but a SES is small and read-mostly, so the bytes are negligible
  against the clarity. Ages well; the format is stable and the Go contract is one paragraph.

**Arm E2 — a raw Valkey HASH of named fields (`HSET cm:ses:<SES> player … platform …`)**, bypassing the
EchoStore frame. *Rationale* — a HASH is the **most Go-trivial** read (`HGETALL` → a map, no strip, no parse);
`encodings.md` floats it as "the obvious candidate when the store is bare Valkey." *Steward* — but a raw HASH
**bypasses EchoStore entirely** (it is not a framed-String row): it forfeits the **version frame** (so no
newer-wins coherence — a late stale write cannot be bounced), the **near-cache** (no L1 for Phoenix/LiveView),
and the **kind gate** — re-introducing FA-key's K2 problem (a second session-storage discipline). It also splits
the model: the SES would be a HASH while every other shared row is a framed-String, so the Go edges learn **two**
shared-state shapes. The steward's verdict: a HASH is Go-trivial but **forfeits the store** — pay the one-time
strip-14 contract (E1) to keep the SES inside EchoStore's coherence + near-cache + gate, which is exactly what a
**mutable, revocable, multi-runtime** session needs.

**Arm E3 — msgpack inner value** (E1's shape with msgpack instead of JSON). *Steward* — msgpack is
language-neutral (Go + Elixir both have libraries) and leaner than JSON, but it adds a **dependency** on both
sides (a msgpack lib — and G5's boundary + "no new dep" caution bites: the BEAM side would need a msgpack dep)
and is **not human-readable** (harder to debug a live SES). For a small, read-mostly session record the byte
saving does not pay for the dep + the opacity. JSON (E1) is the steward's choice; msgpack is the option if a
measured size/throughput need ever justifies the dep.

**Ranked (FA-encoding): E1 (framed-String + flat JSON inner), strongly** — language-neutral (G7) with the
least-surprise format, keeps the version frame (coherence) while the inner JSON crosses the language boundary;
the strip-14 + JSON read contract is documented + Go-fixture-tested. *One carrying reason: E1 satisfies "a Go
edge decodes it" without leaving EchoStore's frame, so the SES keeps coherence + near-cache + the kind gate that
a mutable revocable session needs.*

### FA-coherence — the mode for a MUTABLE session (`:none` is WRONG)

**The crux: a revoked or expired SES must not keep authenticating from an edge's L1.** codemojex's existing
tables are `:none` because GAM/EMS are **immutable** (`tables.ex`); a SES is **mutable and revocable**, so the
staleness window of `:none` is a **security defect** — a `DEL`'d (revoked) SES would survive in a holder's L1
until that L1's TTL elapses, letting a revoked session **keep authenticating**.

**Arm C-trk — `:tracking` (server-assisted CLIENT TRACKING)** *(RECOMMENDED)*. The `Codemojex.Sessions` table
declares `coherence: :tracking` (`table.ex:256,558`): Valkey itself pushes an invalidation for **any write**
(incl. `DEL`) to the `ecc:{sessions}:` prefix, and each tracking client evicts its L1 row.

- **Rationale.** Revocation is a `DEL` (FD); with `:tracking`, the **server** pushes the invalidation to
  **every** tracking client the instant the SES changes — so a revoke reaches every holder's L1 **without an
  app-level publish**, bounding the post-revoke staleness to the push latency, not the L1 TTL.
- **Steelman.** This is the **soundest mutable-session coherence**: the invalidation is the **server's** (any
  write to the prefix triggers it — a `DEL`, a re-`put`, an expiry), so the BEAM does not have to remember to
  broadcast; a revoke is **structurally** propagated. It is the mode the store **already implements**
  (`table.ex:558`) for exactly this "a write must reach holders" need. The 14-byte version frame still bounces a
  late stale write newer-wins, so `:tracking` + the frame is **defense in depth** (the push evicts; the version
  refuses a stale re-fill).
- **Steward.** The **cross-language cost the reshape forces** (named honestly): `:tracking` evicts the **BEAM's**
  L1 (the EchoStore owner is the tracking client). **A Go edge with its OWN L1 is NOT automatically a tracking
  client** — so **either** the Go edge holds **no L1** (reads `ecc:{sessions}:<SES>` from Valkey **every** verify
  — simplest, and a session read is one `GET`), **or** the Go edge must **itself** register CLIENT TRACKING on
  the prefix to get the push. The steward's recommendation: **the Go edge is L1-less for the SES** (verify = one
  `GET` per request against shared L2) — a session `GET` is cheap, and an L1-less edge has **no stale-SES
  window at all** (it always reads the live L2, where a revoke `DEL` is immediate). This makes the Go-edge
  staleness bound **zero** and removes the "an edge must be a tracking client" complexity. If a Go edge later
  needs an L1 for throughput, registering it as a tracking client is the additive upgrade (and its staleness
  bound is then named = the push latency). **This Go-edge-L1 decision is a NAMED part of the coherence fork**,
  not a silent default.

**Arm C-bcast — `:broadcast` (the versioned app-level pub/sub lane).** *Rationale* — the 29-byte `id:version`
publish (`coherence.ex:82`) is the store's app-level coherence, 72µs median; an edge can subscribe to
`ecc:{sessions}:coh`. *Steward* — `:broadcast` requires the **writer** to publish (the BEAM must remember to
broadcast on every revoke), and it is **at-most-once** pub/sub (a lost message = one TTL of staleness,
`invalidation-push.md`) — for **revocation**, a *lost* invalidation means a **revoked SES keeps authenticating
for a TTL**, which is the security hole the steward is closing. `:tracking`'s server-pushed invalidation is
**not** writer-dependent and fires on the `DEL` itself. The steward prefers `:tracking` for a **security**
invalidation; `:broadcast` is acceptable only with the staleness bound (one TTL) **named and accepted** as the
revocation latency, which for a security revoke is weaker than `:tracking`.

**Arm C-none — `:none` (REJECTED for the SES).** *Steward* — `:none` is correct **only** for an immutable row
(GAM/EMS); for a mutable, revocable SES it means a revoke **never** reaches an L1 holder until TTL — a **standing
security defect**. **Rejected.** (Named explicitly because it is the existing-table default and the trap.)

**Ranked (FA-coherence): C-trk (`:tracking`) for the BEAM's L1 + the Go edge L1-less (one `GET` per verify),
strongly** — a revoke (`DEL`) is server-pushed to every tracking holder, and an L1-less Go edge has **zero**
stale-SES window (always reads live L2). `:broadcast` is the writer-dependent, one-TTL-staleness fallback;
`:none` is **rejected** (the immutable-table default is a security defect for a mutable session). *One carrying
reason: a security revoke must not depend on the writer remembering to publish or on a lost pub/sub message —
`:tracking` fires on the `DEL` itself, and an L1-less edge reads the live revoke immediately.*

### FA-durability — is a SES worth Graft-backed replication?

**Arm D-eph — ephemeral SES (Valkey TTL only; re-handshake on loss)** *(RECOMMENDED)*. The SES lives in Valkey
under a TTL; it is **not** folded to Graft/Tigris. If Valkey loses the SES (a flush, a cold start, an eviction),
the client **re-handshakes** (the `initData` bootstrap is always re-derivable inside the Mini App) and gets a
fresh SES.

- **Rationale.** A session is **cheap to re-mint** — the bootstrap (`initData`) is always available, so a lost
  SES costs **one handshake**, not lost state. Durable replication (Graft → Tigris) is for data that is
  **expensive or impossible to reconstruct** (the durable PLR, the ledger); a SES is neither.
- **Steelman.** This is **"re-handshake is cheaper than persistence"** — the steward's YAGNI applied to
  durability: folding a short-lived, trivially-reconstructable SES into the Graft engine (CubDB → Tigris) would
  spend the durability tier's write path + storage on a record whose loss is a **one-`GET`-miss → re-handshake**.
  It keeps the SES **ephemeral by design** (a TTL'd Valkey row), which also **bounds** its exposure (FD) and
  keeps the durable tier focused on what must survive (the PLR, in Postgres). The **identity** is durable (the
  PLR in Postgres, the Stage-1 invariant); the **session** is ephemeral — the right split.
- **Steward.** The cost: a Valkey-level loss (cold start / failover without AOF) logs out **every** active
  session at once (they all re-handshake). For a game this is a **brief mass re-handshake**, not data loss —
  acceptable. If the Operator wants sessions to **survive** a Valkey restart, **Valkey AOF persistence** (not
  Graft) is the lighter tier (AOF replays the SES `SET`s on restart) — the steward surfaces AOF as the middle
  option, but the **recommendation is ephemeral** (re-handshake is cheap, and an ephemeral session is a smaller,
  self-bounding surface). **Graft-backing a SES is over-durable** for a re-derivable credential.

**Arm D-graft — Graft-backed durable SES (fold to `EchoStore.Graft`, CubDB → Tigris).** *Rationale* — G7 names
echo-persistence (Graft) as the SES's durable tier; a Graft-backed SES survives any Valkey loss. *Steward* — but
this spends the **highest-cost durability tier** (the replication engine, Tigris storage, `commit/3`) on a
record that is **trivially re-mintable** — the steward's "is a session worth durable replication?" answers **no**
for a re-derivable bootstrap. Graft is the right home for the **archive** (trimmed streams, the durable page
tier), not for an ephemeral session whose loss is a re-handshake. **Over-built** unless a session is somehow
expensive to re-establish (it is not — `initData` is always there).

**Ranked (FA-durability): D-eph (ephemeral Valkey-TTL SES; re-handshake on loss), strongly — with Valkey AOF
the middle option if sessions must survive a restart; Graft-backing REJECTED as over-durable.** Re-handshake is
cheaper than persistence for a re-derivable credential; the durable tier stays focused on the PLR (Postgres) and
the archive (Graft). *One carrying reason: a SES is reconstructable from the always-available bootstrap in one
handshake, so durable replication spends the heaviest tier on the cheapest-to-replace record.*

> **G7 reconciliation (named honestly).** G7 lists the SES as "durable via echo-persistence (EchoStore.Graft)."
> The steward's FA-durability ranking **diverges** from a literal reading of that clause: a session is the one
> record where **re-handshake < persistence**, so the steward recommends **ephemeral** (Valkey TTL), surfaces
> **AOF** as the survive-a-restart middle, and flags **Graft-backing as over-durable**. This is a **surfaced
> divergence for the Operator** — if G7's Graft-backing is a hard requirement (not a default), the steward
> builds it, but records that a re-derivable SES does not earn the heaviest durability tier. **The Operator
> rules whether the SES is ephemeral, AOF-durable, or Graft-durable.**

**FA overall recommendation.** The SES is an **`EchoStore.Table` kind `"SES"`, key `ecc:{sessions}:<SES>`
(K1)**, value a **framed-String + flat JSON inner (E1, language-neutral, strip-14 + JSON Go contract)**,
coherence **`:tracking` with the Go edge L1-less (C-trk)**, durability **ephemeral Valkey-TTL (D-eph), AOF the
middle, Graft over-durable**. This rides EchoStore's proven keyspace + kind gate + near-cache, gives every
runtime one documented read shape, makes a revoke server-pushed and immediate for an L1-less edge, and keeps the
durable tier on the PLR (Postgres), not the ephemeral session.

**Pre-empted Lens-A objection.** *"A SES-in-EchoStore with a strip-14-then-JSON contract and a tracking lane is
heavy ceremony for a Go edge — a bare `HSET cm:ses:<id>` HASH the edge reads with one `HGETALL` is far simpler,
and an L1-less edge doing a `GET` per request is a latency cost a near-cache would avoid."* Answer: the
strip-14 + JSON contract is **one documented, fixture-tested paragraph** the Go edge implements once, and in
exchange the SES keeps the **version frame** (so a late stale write is bounced newer-wins — a HASH cannot do
this), the **near-cache** (Phoenix/LiveView get L1), and the **kind gate** (a non-`SES` id is refused on the
wire). A bare HASH forfeits all three and splits the shared-state model into "HASH for sessions, framed-String
for everything else," which is **more** for the edges to learn, not less. On the L1-less `GET`-per-request: a
session lookup is a **single `GET`** on the hot Valkey the edge already connects to (microseconds), and being
L1-less is the steward's **deliberate** choice precisely because it gives the edge a **zero** stale-SES window
(the security property that matters for a revocable session) — a near-cache on the edge would **re-introduce**
the staleness the `:tracking` lane exists to close. The edge can adopt an L1 + tracking later (an additive
upgrade with a named staleness bound) if throughput ever demands it; the floor is correct, breach-bounded, and
revoke-immediate.

---

## §2 — FB · The binding (PLR in Postgres, SES references it)

**The question is settled in shape by Stage-1 + G6; this section states how it composes with the SES.** The
**PLR stays in Postgres** (the durable identity, the Stage-1 `tg_user_id` + partial unique index +
`resolve_player_by_tg/2`); the **SES (Valkey) references the PLR** (the SES JSON's `"player"` field). The
handshake's resolve-or-create mints the **PLR (Postgres)** and then mints the **SES (Valkey)** referencing it.

**Arm B3 — the Stage-1 `tg_user_id` column behind a platform-adapter seam** *(RECOMMENDED, carried from the
prior draft, unchanged by the reshape)*. `Codemojex.Identity.resolve(platform, external_id, opts)` → today
`:telegram → Wallet.resolve_by_tg/2` → a PLR; the handshake then mints the SES with `"player" => plr`,
`"platform" => platform`.

- **Steelman.** B3 keeps the **identity** invariant exactly where it belongs — the PLR durable in Postgres,
  one-per-verified-identity by the partial unique index — and makes the **SES** a thin reference to it. The
  platform-adapter seam keeps the **flow + the SES schema** platform-agnostic (the SES JSON carries
  `platform` + the external reference generically), so a second platform adds an adapter clause + a `platform`
  value, never a SES-schema change. The durable/ephemeral split is clean: lose the SES → re-handshake → the
  **same** PLR resolves (idempotent), because the PLR is durable and the resolve is keyed on the verified
  identity.
- **Steward.** One thin indirection (the seam); the SES references the PLR by id (a string field), no embedded
  object — the BCS law (identities cross boundaries, not object graphs) held literally: the SES carries the
  **PLR id**, and the PLR's durable state stays in Postgres. The bitmapist edge (G8) keys on the **durable PLR**
  (not the ephemeral SES), so analytics survives a session's expiry — the right key choice (FB-bitmapist below).

**Ranked (FB): B3 (Stage-1 `tg_user_id` behind the seam; the SES references the PLR), with B1/B2 the same
column-vs-identities-table sub-fork as the prior draft** — the reshape does not change the binding, only adds
that the SES (Valkey) references the durable PLR (Postgres). *One carrying reason: the PLR is the durable
identity (Postgres, one-per-verified-identity); the SES is an ephemeral reference to it — the durable/ephemeral
split keeps re-handshake idempotent (the same PLR re-resolves).*

**Pre-empted Lens-A objection.** *"Why keep the PLR in Postgres at all — put the whole player in the SES so the
edge has everything in one read?"* Answer: the PLR is the **durable identity + the money** (balances, the
ledger — the Stage-1 + wallet invariants, the non-negative CHECK, the row-locked transactions); it **must** be
durable and transactional, which Valkey-as-session-store is not. The SES carries the **PLR id** (a reference),
and an edge that needs balances reads them through the authoritative path — the BCS law (a boundary crosses an
**identity**, not an object graph). Putting the money in an ephemeral session would lose the durability and the
transactional integrity the wallet exists to provide.

---

## §3 — FD · SES TTL (EXPIRE) + revocation (DEL) + the L1-invalidation invariant

**The question.** Fixed vs sliding TTL; revocation via `DEL`; and the invariant that a `DEL` purges **every**
holder's L1 (or a named staleness bound). Applies `ttl-expiry.md`.

**Arm FD1 — a fixed (absolute) TTL via `PX` at mint + revocation via `invalidate/3` (`DEL`), with `:tracking`
purging every L1** *(RECOMMENDED)*. The SES is written `SET ecc:{sessions}:<SES> (version<>value) PX ttl_ms`
(`table.ex:290`) with a **fixed** TTL; revocation is `EchoStore.Table.invalidate/3` (`table.ex:174`, `DEL` L2 +
L1 evict). The `:tracking` lane (FA-coherence) pushes the `DEL` to every tracking holder; an L1-less Go edge
sees the `DEL` on its next `GET`.

- **Rationale.** A **fixed** TTL bounds a leaked SES's life absolutely (a stolen SES dies at its deadline no
  matter how used); revocation is the store's **existing** `invalidate/3` (`DEL`); `:tracking` makes the `DEL`
  reach every L1. **The exposure window is named (the TTL) AND a revoke is immediate (the `DEL` + the push).**
- **Steelman.** This pairs the prior draft's "bounded exposure" (a named TTL) with the reshape's **revocability**
  (a `DEL` the shared store propagates) — the **best of both** the prior fork could not have, because a shared
  SES **can** be revoked where a stateless token could not. The invariant the steward names: **a revoke
  (`DEL`) must purge every holder's L1, or the staleness bound is named** — under FA-coherence's
  `:tracking` + L1-less-edge, the bound is **zero for the edge** (live L2 read) and **the push latency for the
  BEAM's L1** (the server-pushed eviction). So "a revoked SES keeps authenticating" is **closed** (edge:
  immediately; BEAM L1: within the push). The `auth_date` freshness (FG) + the fixed TTL are two named replay
  bounds.
- **Steward.** Fixed over sliding (the `ttl-expiry.md` sliding default is for **keeping active users in**; for a
  **security** bearer, the steward wants an **absolute** bound — a sliding TTL means a **used** stolen SES never
  expires, the FA-prior-D3 trap). The cost of fixed: an active user re-handshakes at the deadline (silent, the
  bootstrap is always there — the same re-handshake D-eph relies on). **HEXPIRE** (per-field TTL) is **not
  applicable** here — the SES is a framed-String row (E1), not a HASH, so the TTL is the **row** `PX`, not a
  per-field `HEXPIRE`; (HEXPIRE would only enter under the rejected HASH arm E2). The L1-invalidation invariant
  is the **load-bearing security invariant** of the whole fork — named and gated (a test: revoke a SES, assert
  a holder's next read fails closed).

**Arm FD2 — a sliding TTL (re-`put`/`EXPIRE` on each request).** *Steward* — sliding keeps an active user in
without re-handshake, but a **used** stolen SES **never expires** (each attacker request slides the deadline) —
it defeats the absolute theft bound. **Rejected** for a security bearer (the same reasoning that rejected sliding
in the prior draft's FD).

**Ranked (FD): FD1 (fixed TTL + `invalidate/3` revoke + `:tracking` L1-purge), strongly** — an absolute theft
bound AND an immediate revoke the shared store propagates; the L1-invalidation invariant is named + gated (a
revoke fails the next read closed); HEXPIRE N/A (framed-String, not HASH). *One carrying reason: a shared SES
gains what a stateless token never had — revocation — and a fixed TTL + a server-pushed `DEL` make the exposure
both bounded and immediately revocable.*

**Pre-empted Lens-A objection.** *"A fixed TTL forces re-handshakes mid-session — a sliding TTL keeps active
users in with no interruption."* Answer: the re-handshake is **silent** (the Mini App re-derives `initData`
without user action — the same mechanism D-eph and the prior draft's D1 rely on), so a fixed TTL costs the user
**nothing perceptible** while giving the **absolute** theft bound a sliding TTL destroys (a sliding window lets a
**used** stolen SES live forever). For a **security** bearer the bound must be absolute; the silent re-handshake
makes "fixed" free. And the shared-SES model adds the capability the prior model lacked — an **immediate revoke**
(`DEL` + `:tracking`) — so even within the fixed window, a noticed theft is killable now, not at the deadline.

---

## §4 — The NEW store/security forks (the reshape's own)

### FG-edge · the Go-edge TRUST model (threat-model the shared store)

**The question.** What may a Go edge **do** with the shared store — **verify-only** (read the SES) or **write**
(mint/mutate a SES)? Can a compromised edge **forge** a SES? Where is the security boundary between the BEAM
(the SES authority) and the edges (consumers)?

**Arm T1 — the BEAM is the SOLE SES-minting authority; edges are READ-ONLY verifiers** *(RECOMMENDED)*. Only
the BEAM handshake (`POST /api/auth/:platform`) verifies `initData`, resolves the PLR, and **mints** the SES
(`put`). A Go edge **only reads** `ecc:{sessions}:<SES>` to **verify** a presented SES (does it exist, is it
unexpired, what PLR does it carry?). An edge **never** writes a SES, **never** mints one, **never** has the bot
token (so it **cannot** forge an `initData` verify).

- **Rationale.** The dangerous operation — **minting** a session (which confers identity) — must live behind the
  **one** code path that **verifies** identity (the HMAC + the resolve). An edge that could mint a SES could
  **fabricate** an identity; an edge that can only **read** one can at most **observe** a session it was given.
  Confining mint to the BEAM means a **compromised edge cannot forge a session** — it has no secret to sign
  with and no write authority to plant one.
- **5W.** *Why* — keep session **creation** (identity conferral) behind the single verifying authority; edges
  observe, never create. *What* — the BEAM mints (`put` after HMAC + resolve); edges `GET`-and-verify only.
  *Who* — the BEAM handshake is the authority; Go edges + LiveView are read-only consumers. *When* — cm.4 floor.
  *Where* — the handshake controller (BEAM) holds the only `put`; the Go edge read contract is read-only.
- **Steelman.** This is the **least-privilege** boundary applied to the shared store: the **blast radius of a
  compromised edge is bounded to read** (it can read sessions it can name, but cannot **create** identity or
  **mutate** another's session). Forgery is **structurally** impossible for an edge — it lacks the bot token
  (so it cannot pass the HMAC verify) and lacks write authority (so it cannot plant a SES). The mint authority
  is **one** auditable path (the handshake), so the most security-sensitive operation has the smallest, most-
  reviewed surface. A revoke is also BEAM-only (`invalidate/3`), so the **lifecycle** authority is centralized.
- **Steward.** The cost: an edge that needs to **act** on a session (e.g. extend it) cannot — it must ask the
  BEAM. For the cm.4 floor (edges **verify**; bitmapist **marks** on a **separate** store), this is exactly
  right — no edge needs SES-write. The steward names the boundary as an **invariant**: *the BEAM is the sole
  SES mint+revoke authority; an edge's Valkey credential to the session store is READ-ONLY* (and, ideally,
  Valkey ACLs enforce read-only on the edge's connection — a named hardening: the edge's `:6390` user is
  granted `GET`/read on `ecc:{sessions}:` and **denied** `SET`/`DEL`, so even a compromised edge **cannot**
  write a SES). This ACL is the steward's belt-and-suspenders; the architecture (no edge write path) is the
  belt.

**Arm T2 — edges may write (e.g. slide/extend a SES, or mint on their own verify).** *Steward* — letting an
edge **write** a SES means an edge can **extend** a session (re-introducing the sliding-TTL theft trap from a
**less-trusted** runtime) or, worse, **mint** one (an edge that mints confers identity — a compromised edge
**forges** sessions). The steward **rejects** edge-write for the floor: session **creation and lifecycle** are
identity operations that belong to the **single verifying authority** (the BEAM). An edge that needs to influence
a session asks the BEAM. **Rejected** (edge-mint is a forgery vector; edge-extend is a theft-bound weakener from a
broader-attack-surface runtime).

**Ranked (FG-edge): T1 (BEAM sole mint+revoke authority; edges READ-ONLY verifiers, ACL-enforced), strongly** —
a compromised edge bounded to read cannot forge identity; mint + revoke are one auditable BEAM path. *One
carrying reason: minting a session confers identity, so it must live behind the one path that verifies
identity — an edge that can only read cannot fabricate a session.*

**Pre-empted Lens-A objection.** *"Read-only edges can't refresh or extend a session, forcing a BEAM round-trip
for something the edge could do locally — that's a bottleneck and couples the edges to the BEAM."* Answer: an
edge **verifying** a session needs **no** write (it reads the SES, checks expiry, reads the PLR — all reads), and
the **only** lifecycle operations (mint, extend, revoke) are **identity** operations that **must** be
centralized for soundness — an edge that could mint forges identity, an edge that could extend weakens the theft
bound from a broader attack surface. The "bottleneck" is illusory: mint happens **once per session** at the
handshake (a cold path), and verify (the hot path) is **read-only and edge-local** (one `GET`), so the edges are
**not** coupled to the BEAM on the hot path — only the rare lifecycle events touch the BEAM, which is correct
because those are the identity-conferring operations. Least privilege here costs nothing on the hot path and
closes the forgery vector entirely.

### FG-bitmapist · the analytics edge (keyed by the durable PLR, off the auth hot path)

**The question.** How does the bitmapist edge (G8) relate to the auth flow? **It does not gate auth.** bitmapist
keys cohort marks by the **durable PLR** (not the ephemeral SES), on a **separate** `:6400` Redis (RESP2/redigo),
so a mark is a **fire-and-forget analytics write off the auth hot path.**

- **Steward.** This is the **right separation**: analytics keyed on the **durable** identity (the PLR survives a
  session's expiry, so cohort membership is stable across sessions — a SES key would lose a player from a cohort
  when their session expired, which is wrong), on a **separate store** (`:6400`, not the `:6390` session store),
  so a bitmapist outage or latency **cannot** affect auth (the auth flow never reads `:6400`). The flow: a Go
  edge **reads the SES on `:6390`** (verify) **and** **marks bitmapist on `:6400`** (analytics) — two stores,
  two purposes, the analytics one non-blocking. The branded-id-native codec (`branded/branded.go`,
  `placement("USR0KHTOWnGLuC")=234878118`) means the mark is keyed by the branded PLR exactly as the BEAM would
  compute it (the BCS codec ported). **bitmapist is NOT in the auth trust boundary** — it is a downstream
  analytics consumer of the verified PLR, fire-and-forget.
- **Invariant named:** *a bitmapist mark is keyed by the durable PLR, on `:6400`, off the auth hot path; a
  bitmapist failure never fails auth.* (The auth flow reads only the SES store on `:6390`.)

**Ranked (FG-bitmapist): keyed by the durable PLR, separate `:6400` store, fire-and-forget off the auth path** —
analytics on the stable durable identity, isolated from the session store so it never gates auth. *One carrying
reason: cohort membership must be stable across sessions (the durable PLR), and analytics must never be able to
fail authentication (a separate store, off the hot path).*

---

## §5 — FC / FE / FG-freshness · the re-cascade (carried, lightly re-stated for the SES)

The prior draft's recommendations on these hold under the reshape, re-cast for the SES bearer:

- **FC handshake shape — C1 (a dedicated `POST /api/auth/<platform>` → a SES; all else SES-bearer-only)**
  *(RECOMMENDED, unchanged)*. The handshake is the **single SES-minting authority** (FG-edge T1): the one path
  that verifies `initData`, resolves the PLR, and `put`s the SES. Every other route requires a valid SES bearer.
  *Reason:* the verifier (highest-risk code) + the SES mint live at **one** auditable endpoint; FG-edge T1 makes
  this the **sole** mint authority.
- **FE transport — E1 (`Authorization: Bearer <SES>` + the socket connect param)** *(RECOMMENDED, unchanged)*.
  The **SES branded id** is the bearer; it travels as a `Bearer` header (HTTP) + a socket connect param,
  CSRF-immune by construction (never browser-auto-sent), symmetric across HTTP/socket/edge. A Go edge reads the
  `Bearer` SES id and `GET`s `ecc:{sessions}:<SES>`. *Reason:* a `Bearer` SES id is the smallest attack surface
  (no ambient auto-send) and a uniform contract every runtime + the socket shares.
- **FG-freshness — G1 (`initData` `auth_date` max-age at the handshake + the SES TTL)** *(RECOMMENDED,
  unchanged)*. Two named replay bounds: the `auth_date` window bounds **bootstrap** replay (a captured
  `initData` cannot mint a fresh SES after the window); the SES TTL (FD) bounds **bearer** replay. *Reason:*
  without the `auth_date` check a captured `initData` is a permanent SES-minting skeleton key.
- **FF dev/test posture — F2 (a `test/support` SES-minting helper, NO prod bypass) + a test-signed `initData`
  fixture** *(RECOMMENDED, re-cast)*. A `test/support` helper mints a **real SES** (via the real `put` path) for
  a test PLR — compiled only in `:test`, so **no bypass ships**; the fixture exercises the real HMAC handshake.
  F1 (a `trust_supplied_player` config bypass that mints a SES for a supplied player) **only** under the three
  guards (prod-absent by construction + a prod-default-rejects test + same-`put`-path mint). *Reason:* F2 ships
  **zero** bypass surface in the shared store — a leaked bypass that minted SESs into the **shared** Valkey would
  let any service be fooled, so the steward's bar is higher than ever: **no SES-minting bypass in prod.**

---

## §6 — Forward-vision phasing (the smallest secure floor vs the horizon)

**The cm.4 FLOOR (the smallest secure increment to ship):**
1. The pure `initData` verifier (`Codemojex.InitData`, G4) — fail-closed if `Bot.token/0` is nil.
2. The handshake `POST /api/auth/:platform` (FC-C1) — the **sole** SES-minting authority (FG-edge T1): verify →
   resolve PLR (Stage-1) → `put` the SES.
3. The SES schema: `ecc:{sessions}:<SES>` (K1), framed-String + JSON (E1), `:tracking` coherence (C-trk),
   ephemeral Valkey-TTL (D-eph) — an `EchoStore.Table` kind `"SES"` declared in `tables.ex`.
4. The `require_player → conn.assigns.player`-from-SES cutover (the 5 endpoints) + the socket `connect/3`
   SES-verify; the `Bearer` transport (FE-E1); the fixed TTL + `invalidate/3` revoke (FD1) + the `auth_date`
   window (FG-G1).
5. Retire `POST /api/players` (G3).
6. The dev/test posture (FF-F2) + the migration (Stage-1's 2nd migration).

**Forward rungs (shaped, NOT in the floor):**
- The **documented Go-edge read contract** (`GET ecc:{sessions}:<SES>` → strip-14 → JSON; read-only;
  ACL-enforced) — named now (FA-encoding + FG-edge), **built** when a real Go edge consumes the SES.
- **bitmapist** integration (G8) — the durable-PLR-keyed `:6400` analytics edge, off the auth path (FG-bitmapist)
  — a forward rung; the floor does not depend on it.
- **LiveView** (G9) — the SES authenticates a LiveView mount/socket the same as the channel socket (FE-E1); the
  forward-vision consumer, no floor change (LiveView reads the same shared SES).
- A Go-edge **L1 + tracking-client** upgrade (if throughput demands) — additive over the L1-less floor, with a
  **named** staleness bound (the push latency).

**The smallest secure floor is items 1–6** — it closes every named gap (anonymous mint, trusted-param, no-auth
socket) with the SES shared-store substrate, and **forecloses nothing** for the forward edges (they read the
same documented SES shape).

---

## §7 — Fork ledger (Lens B ranked arm + one-line reason)

| Fork | Ranked arm (Lens B) | One-line reason |
|---|---|---|
| **FA-key** | **K1** `ecc:{sessions}:<SES>` (EchoStore table) | The kind gate makes one-SES-per-key structural; the Go edge gets one documented key shape. |
| **FA-encoding** | **E1** framed-String + flat JSON inner (strip-14 + JSON Go contract) | Language-neutral (G7) while keeping the version frame (coherence) + near-cache + kind gate; a HASH forfeits all three. |
| **FA-coherence** | **C-trk** `:tracking`, Go edge L1-less | A revoke (`DEL`) is server-pushed to every holder; an L1-less edge reads the live revoke immediately — `:none` is a security defect for a mutable session. |
| **FA-durability** | **D-eph** ephemeral Valkey-TTL (AOF middle; Graft over-durable) | Re-handshake < persistence for a re-derivable credential; the durable tier stays on the PLR (Postgres). **(Diverges from a literal G7; surfaced.)** |
| **FB** binding | **B3** Stage-1 `tg_user_id` behind the seam; SES references the PLR | The PLR is durable identity (Postgres); the SES is an ephemeral reference — re-handshake re-resolves the same PLR. |
| **FD** TTL + revoke | **FD1** fixed TTL + `invalidate/3` (`DEL`) + `:tracking` L1-purge | An absolute theft bound AND an immediate revoke the shared store propagates; the L1-invalidation invariant named + gated. |
| **FG-edge** trust model | **T1** BEAM sole mint+revoke authority; edges READ-ONLY (ACL-enforced) | Minting confers identity → it lives behind the one verifying path; a compromised read-only edge cannot forge a session. **(NEW; HEADLINE security fork.)** |
| **FG-bitmapist** | durable-PLR-keyed, separate `:6400`, fire-and-forget | Cohort membership is stable across sessions (the durable PLR); analytics never gates auth (a separate store, off the hot path). |
| **FC** handshake | **C1** dedicated `POST /api/auth/<platform>` (the sole SES mint) | The verifier + the SES mint at one auditable endpoint (FG-edge T1). |
| **FE** transport | **E1** `Authorization: Bearer <SES>` + socket connect param | A `Bearer` SES id is CSRF-immune by construction; one contract across HTTP/socket/edge. |
| **FG-freshness** | **G1** `auth_date` max-age + SES TTL | Two named replay bounds; without `auth_date` a captured `initData` is a permanent SES-minting skeleton key. |
| **FF** dev/test | **F2** `test/support` SES helper (no prod bypass) + signed fixture | Ships ZERO SES-minting bypass into the shared store; the bar is higher for a shared bearer. |

---

## §8 — What I deliberately did NOT decide (the discipline) + where I expect to diverge from Lens A

- **Every fork is the Operator's.** Each §7 row is a recommendation with one reason; the choice is the
  Operator's after the Director synthesizes Lens A against Lens B.
- **The forks I most expect to DIVERGE from Lens A** — flagged: **FA-encoding** (the steward's framed-String +
  JSON, keeping the store's coherence/near-cache, vs Lens A's likely **raw HASH** for Go-edge ergonomics),
  **FA-durability** (the steward's **ephemeral** SES — re-handshake < persistence — vs a literal-G7 **Graft-
  backed** durable SES, OR Lens A's possible **AOF** middle for survive-a-restart UX), and **FA-coherence /
  the Go-edge L1** (the steward's **L1-less edge** for a zero stale-SES window vs Lens A's likely **edge L1 +
  tracking-client** for read throughput). These are the "soundness/smallest-secure-surface vs consumer-
  ergonomics/throughput" axis the two lenses weight oppositely.
- **The FA re-ruling is recorded, not hidden.** The prior A1-stateless recommendation is marked
  **SUPERSEDED-BY-G6** (a Go edge cannot verify a BEAM-internal token); the ruled direction is a **stateful SES
  in Valkey**, and this doc designs its schema. The prior draft's record stands; this revision supersedes it on
  FA/FD only — FB/FC/FE/FG-freshness/FF carry forward.
- **The G7 durability divergence is surfaced AS one** — the steward recommends an **ephemeral** SES (a session
  is the one record where re-handshake < persistence) and flags Graft-backing as **over-durable**; if G7's
  Graft-clause is a hard requirement, the steward builds it but records the cost. **The Operator rules ephemeral
  / AOF / Graft.**
- **No code, no migration, no git, no build/test.** Design-ahead. The Stage-1 relational design stands as
  authored (referenced, not re-opened). The verifier, the SES table, the handshake, the plug, the Go-edge
  contract are **forward-tense**. Every `EchoStore` / `EchoStore.Graft` surface cited is **read-only** to this
  design. This doc touches exactly one file (itself).

---

## §9 — Surface citations (every named surface grounded)

**As-built (verified at source this session):**

- `CodemojexWeb.GameController` — `require_player/1` (`game_controller.ex:77`), `create_player/2`
  (`game_controller.ex:14`, the unauthenticated free-money mint) —
  [`game_controller.ex`](../../../../echo/apps/codemojex/lib/codemojex_web/controllers/game_controller.ex);
  `UserSocket.connect/3` (`user_socket.ex:7`) —
  [`user_socket.ex`](../../../../echo/apps/codemojex/lib/codemojex_web/channels/user_socket.ex);
  `Router` `:api` pipeline + `POST /api/players` (`router.ex:4,12`) —
  [`router.ex`](../../../../echo/apps/codemojex/lib/codemojex_web/router.ex).
- `EchoStore.Table` — `put/3` (mints the version, `table.ex:93`) / `put/4` (carries a version, `table.ex:97`);
  the L2 write `SET ecc:{<table>}:<id> (version<>value) PX ttl_ms` (`table.ex:290`); the framed value
  `<<version::binary-14, value::binary>>` (`table.ex:429`); `invalidate/3` (the admin/logout verb, `table.ex:174`);
  `fetch/3` (`table.ex:63`); the kind gate `gate/2` (`table.ex:495`); the coherence modes `:none` (default,
  `table.ex:204`) / `:broadcast` (`table.ex:224,235`) / `:tracking` (`table.ex:256,558`); the jittered L1 expiry
  `expires_at/1` (`table.ex:484`) + the `:sweep` reclaimer (`table.ex:350`) —
  [`table.ex`](../../../../echo/apps/echo_store/lib/echo_store/table.ex).
- `EchoStore.Coherence` — `channel/1` (`ecc:{table}:coh`), `payload/2` (the 29-byte `id:version`),
  `broadcast/4` (`coherence.ex:35,82`) — [`coherence.ex`](../../../../echo/apps/echo_store/lib/echo_store/coherence.ex).
- `Codemojex.Tables` — the EchoStore near-cache declarations; GAM/EMS at `coherence: :none` because immutable
  (`tables.ex:61,72` + moduledoc) — [`tables.ex`](../../../../echo/apps/codemojex/lib/codemojex/tables.ex).
- `EchoStore.Graft` — `open_volume/2` (`graft.ex:31`), `read/2` (`graft.ex:48`), `read_at/3` (`graft.ex:56`),
  the CubDB → Tigris durable page tier — [`graft.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft.ex).
- `Codemojex.Bot.token/0` (`bot.ex:39`, the WebApp-secret HMAC key source) —
  [`bot.ex`](../../../../echo/apps/codemojex/lib/codemojex/bot.ex).
- The Stage-1 relational design — `players.tg_user_id`, the partial unique index, `Wallet.resolve_by_tg/2` +
  `Codemojex.resolve_player_by_tg/2`, the 2nd migration —
  [`cm.4.postgres.design.md`](../../specs/cm.4.postgres.design.md).

**Applied pattern docs (the SES-store craft, grounded in real `table.ex`/`coherence.ex` citations):**

- [`auth-session.md`](../../../redis-patterns/markdown/caching/session-management/auth-session.md) — SES as an
  EchoStore row (`put/3` mint, `SET … PX`, `invalidate/3` logout, the kind gate; the "sign out everywhere"
  roster).
- [`encodings.md`](../../../redis-patterns/markdown/caching/session-management/encodings.md) — Hash vs
  String vs JSON; EchoStore stores the **framed-String** (`<<version::14, value>>`), a HASH only for bare Valkey.
- [`ttl-expiry.md`](../../../redis-patterns/markdown/caching/session-management/ttl-expiry.md) — absolute vs
  sliding; `SET … PX`, the jittered L1 clock, the `:sweep` reclaimer.
- [`invalidation-push.md`](../../../redis-patterns/markdown/caching/client-side-caching/invalidation-push.md) —
  CLIENT TRACKING + the `:broadcast` lane (the 29-byte versioned push; 72µs vs 148µs).

**Forward-tense (surface the auth-flow rung(s) BUILD — not yet on disk; named here for the design only):**

- `Codemojex.InitData` (the pure HMAC verifier; fail-closed on a nil token) — `lib/codemojex/init_data.ex`.
- `Codemojex.Sessions` (the SES `EchoStore.Table` kind `"SES"` declaration + the encode/decode helpers:
  framed-String + JSON) — forward-tense in `tables.ex` + a helper module.
- `CodemojexWeb.Auth` (the SES plug — verify a `Bearer` SES on each request + socket connect) and
  `CodemojexWeb.AuthController` (the `POST /api/auth/:platform` handshake — the sole SES mint) — forward-tense.
- `Codemojex.Identity.resolve/3` (the FB-B3 platform-adapter seam: `:telegram → Wallet.resolve_by_tg/2`) —
  forward-tense.
- The **Go-edge read contract** (`GET ecc:{sessions}:<SES>` → strip-14 → JSON; read-only; Valkey-ACL-enforced)
  and the **bitmapist** `:6400` durable-PLR-keyed analytics mark — forward-tense (the forward rungs).

**Given / external (Operator-ruled or platform/infra-documented — re-verified at the build, not from memory):**

- The Telegram WebApp `initData` verification (data-check-string excluding `hash` AND `signature`; secret =
  `HMAC-SHA256("WebAppData", bot_token)`; the `auth_date` field) — **G4**; ground the exact key/msg order +
  excluded-fields list against the **current** Telegram WebApp docs at the build (the runbook FOOTGUN).
- The shared-SES model, the Go edges + LiveView consumers, the language-neutral value, bitmapist (`:6400`,
  branded-id-native), the retired `POST /api/players`, the byte-unchanged 8 suites + the `echo/apps/codemojex/**`
  boundary — **G1–G9** (Operator-ruled, carried).

---

*Lens B — the store / steward / security / persistence lens. Authored independently; the sibling revised Lens A
(`auth.design.A-consumer-lens.md`) was not read. This revision supersedes the prior draft on FA/FD under the
shared-SES reshape (G6–G9). Convergence is confidence; divergence is the signal. The Director synthesizes; the
Operator rules.*
