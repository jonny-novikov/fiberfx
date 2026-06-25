# Codemojex Auth Flow (the cm.4 re-scope) · Director synthesis — v2 (the shared-`SES` reframe)

> **The Director STAGES the disagreement, not averages it**
> ([`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) §The multi-architect
> debate). **This is the v2 synthesis.** The Operator's shared-session requirement (G6–G9 — sessions shared
> across Go lightweight edges + Phoenix + LiveView) **SUPERSEDED the v1 stateless-token result**: a stateless
> `Phoenix.Token` is not *carriable* to a non-BEAM edge. Both architects rewrote their lens docs to the shared
> `SES`-in-Valkey model, independently (neither read the other). The three judgments stay separate; no fork is
> decided.

---

## §0 · The result in one line

The shared-session requirement **overruled** the v1 convergence (a stateless `Phoenix.Token`). Re-designed to a
**stateful `SES`-in-Valkey**, the two lenses again **CONVERGED on the model** — the `SES` as an `EchoStore`
entity, a **JSON-in-framed-String** value, **read-only edges**, the **BEAM the sole authority** — and **DIVERGED
on the store-coherence questions a *mutable* session newly raises**: the coherence **MODE** (`:broadcast` vs
`:tracking`), the **TTL** (sliding vs fixed), and the **durability tier** (ephemeral / AOF / Graft). The
encoding "crux" resolved by convergence: **both lenses rejected a raw Valkey HASH** because it forfeits the
EchoStore tier.

---

## §1 · Cross-lens fork ledger (v2 diff)

| Fork | Lens A (consumer / cross-edge) | Lens B (store / steward) | Verdict |
|---|---|---|---|
| **FA-key** | `EchoStore.Table` kind `SES` (`:cm_sessions`) | `ecc:{sessions}:<SES>`, kind `SES` | **CONVERGED** (kind-gate ⇒ one-SES-per-key structural) |
| **FA-encoding** | JSON in framed-String (strip 14B → `Unmarshal`); **reject HASH** | framed-String + JSON inner; **reject HASH** | **CONVERGED** — the cross-language crux, resolved |
| **FA-coherence** | **`:broadcast`** (app-level lane, the BCS law) | **`:tracking`** (RESP3 server-push) + edge L1-less | **DIVERGED** — headline (first mutable EchoStore table; §3.1) |
| **FA-edge trust** | read-only verify (edge L2+TTL) | read-only verify (edge L1-less, ACL `GET`-only) | **CONVERGED** (read-only; sub-nuance: edge-L1, §3.1) |
| **FA-durability** | ephemeral floor (Graft → forward) | ephemeral REC; AOF/Graft surfaced | **CONVERGED on ephemeral floor**; the tier → Operator (§3.3) |
| **FB** binding | B3 seam; `SES` carries `{plr, platform}` | B3 seam; PLR in Postgres, `SES` references it | **CONVERGED** (the SES contract is platform-STABLE) |
| **FC** handshake | C1 dedicated = the SOLE `SES` mint | C1 dedicated = sole mint | **CONVERGED** (now load-bearing — the single writer) |
| **FD** lifetime | **D1 sliding** TTL via re-`put` + `DEL` revoke | **fixed** PX TTL + `DEL` revoke | **DIVERGED** (sliding vs fixed; §3.2) |
| **FE** transport | E1 `Bearer <SES>` + socket connect-param | E1 `Bearer` + connect-param | **CONVERGED** |
| **FG** freshness | G1 `auth_date` + the `SES` TTL | G1 `auth_date` + `SES` TTL | **CONVERGED** |
| **FF** dev/test | (carried; F1 in v1) | **F2** no prod bypass (firmly) | **DIVERGED** (minor; §3.4 — lean F2) |
| **NEW** bitmapist | M1 mark by **PLR**, `:6400`, fire-and-forget | by PLR, `:6400`, off the auth hot path | **CONVERGED** (forward-vision) |
| **NEW** LiveView | L1 same `fetch(:cm_sessions,…)` surface | forward, same SES surface | **CONVERGED** (forward-vision) |

---

## §2 · The convergences — the build-ready `SES` model

- **The `SES` is an `EchoStore.Table` entity**, kind `"SES"`, keyed `ecc:{sessions}:<SES>` (the kind-gate makes
  one-SES-per-key structural — a wrong-namespace id is refused with zero keys on the wire).
- **The value is a framed-String with a JSON inner value:** a Go edge strips the 14-byte version prefix
  (`table.ex:429`) then `json.Unmarshal`. **ZERO new dep** (Go `encoding/json` + Elixir `Jason`). **Both lenses
  rejected a raw Valkey HASH** — a HASH writes `HSET`, bypassing `EchoStore.Table`'s `SET version<>value`
  (`table.ex:290`) and forfeiting the near-cache, the coherence ring, the kind-gate, and the version frame. (The
  existing caches' `:erlang.term_to_binary` loaders are BEAM-only — a Go edge cannot read them — which is exactly
  why the SES loader must be JSON.)
- **Read-only edges, the BEAM the sole writer.** Minting a session *confers identity*, so the `SES`-write lives
  behind the one path that *verifies* identity (the handshake). A Go edge `GET`s L2, version-strips, JSON-parses,
  trusts by the `SES` namespace (the kind-gate) — **read-only, Valkey-ACL-enforced** (`GET`-only on
  `ecc:{sessions}:`, denied `SET`/`DEL`). A compromised edge cannot forge a session (no bot token, no write
  authority).
- **The dedicated handshake (C1, `POST /api/auth/:platform`) is the SOLE `SES` mint** — now load-bearing (it is
  the single writer the read-only-edge model depends on). G3's retirement of `POST /api/players` is automatic.
- **FB B3 adapter-seam; the `SES` value carries `{plr, platform}`** → the cross-edge SES contract is
  **platform-STABLE from the floor** (FB affects only the BEAM-side resolve, not the wire/edge contract). The PLR
  stays in Postgres (durable identity); the `SES` (Valkey) references it; re-handshake re-resolves the *same* PLR
  idempotently (the Stage-1 contract).
- **FE `Bearer <SES>` + socket connect-param** (one fixed-width, namespace-typed bearer for HTTP + socket + the
  Go edge). **FG `auth_date` at the handshake + the `SES` TTL.**
- **bitmapist (forward):** mark by the **durable PLR** (a SES-keyed cohort would count *sessions*, not players),
  on the separate `:6400` store, fire-and-forget, off the auth hot path, never fails auth. The Go codec offsets
  the PLR identically to the BEAM (`branded.Offset`).
- **LiveView (forward):** one `fetch(:cm_sessions,…)` resolution surface across HTTP + channel + LiveView.

---

## §3 · The divergences (staged, not averaged)

### §3.1 — The coherence MODE for the first MUTABLE EchoStore table (the headline)

The existing caches are `:none` **only** because GAM/EMS are *immutable for life*; a `SES` is **mutable +
revocable**, so `:none` is a **security defect** (a `DEL`'d/revoked SES surviving in a holder's L1 keeps
authenticating). **Both lenses reject `:none`.** They diverge on the mode:

| | **Lens A — `:broadcast`** | **Lens B — `:tracking`** |
|---|---|---|
| **The arm** | the versioned app-level pub/sub lane (`PUBLISH ecc:{sessions}:coh`) — "a message about a name" (the BCS law literal); every BEAM Table peer + LiveView applies a revoke as a clean miss instantly | RESP3 `CLIENT TRACKING` — Valkey itself pushes invalidation on any write incl `DEL`; each tracking client evicts its L1 |
| **Load-bearing reason** | BCS-idiomatic, app-level, simple (no RESP3 tracking-client to manage) | **not writer-dependent** — fires on the `DEL` itself; server-pushed → reaches every L1 without an app message; the version frame is defense-in-depth |
| **The cost it accepts** | writer-dependent (the BEAM must publish on every revoke) + **at-most-once** pub/sub (a lost message = one TTL of a revoked session still valid — a named staleness bound) | the cross-language cost: `:tracking` evicts the **BEAM's** L1, but a Go edge with its OWN L1 is not auto-tracked → the edge runs **L1-less** (one `GET`/verify, zero stale), or registers as a tracking client later (additive) |

Both agree the Go edge reads L2 regardless (an edge L1 is an additive upgrade with a **named** staleness bound).
**The genuine fork:** for a *security* revocation, is the BCS app-level `:broadcast` (writer-published,
one-TTL-staleness-on-loss) enough, or does a mutable auth row warrant `:tracking`'s server-pushed, fires-on-`DEL`
invalidation? **Director's note (advice):** the steward's security argument is strong (server-pushed beats
best-effort-published *for a revoke*); Venus's `:broadcast` is the BCS-idiomatic, simpler default. This is the
relational+coherence shape — the Operator (with VenusPG) rules.

### §3.2 — TTL: sliding (A) vs fixed (B)

Venus: **D1 sliding** TTL via re-`put` (the session slides on use — the redis-patterns sliding-session pattern;
an active player never re-handshakes mid-play). VenusPG: a **fixed** PX TTL at mint (an *absolute* theft bound —
a stolen `SES` dies at a fixed time regardless of use). With revocation now available (`DEL`), sliding is less
dangerous than in v1 (a stolen session can be revoked) — but a fixed bound is the steward's absolute-window
discipline. The Operator's DX-vs-absolute-bound call.

### §3.3 — Durability: ephemeral / AOF / Graft (a pushback on G7)

**Both lenses put the floor at EPHEMERAL** (Valkey-TTL, re-handshake on loss; Graft-durability deferred to
forward). VenusPG explicitly surfaces that **Graft-backing a session is over-durable** — a session is the one
record where *re-handshake < persistence* — and reads the Operator's "backed by echo-persistence" (G7) as the
*store tier* (EchoStore, which *has* the Graft floor available), not "every session Graft-replicated." The
Operator rules the durability tier: **ephemeral** (REC, both) / **AOF** (the middle — survive a Valkey restart) /
**Graft** (if G7's clause is hard — built, the cost recorded).

### §3.4 — FF dev/test (minor; carried from v1, stakes raised)

VenusPG is firmly **F2** (a `test/support` `SES`-minting helper, **no prod bypass**) — the bar is *higher* for a
shared store: a leaked bypass minting `SES`s into shared Valkey fools **every** service. Lens A carried the
dev/test posture (F1 in v1). The shared-store stakes strengthen the F2 case. **Lean F2.**

---

## §4 · Consensus findings

1. **The encoding resolved by convergence** — both rejected the raw HASH (it forfeits the `EchoStore.Table`
   tier); the `SES` stays a first-class EchoStore entity, and the Go contract is "strip 14 bytes, `json.Unmarshal`."
2. **Read-only edges + the BEAM as sole `SES` authority** (Valkey-ACL-enforced) — the sharing is read-only, the
   mint/revoke authority singular; a compromised edge cannot forge a session.
3. **`:none` is wrong for a mutable session** — the coherence mode is a *security* property (the L1 staleness
   window IS the revocation-bypass window). Both lenses reject `:none`; the mode is the open fork (§3.1).
4. **The `SES` contract is platform-STABLE regardless of FB** — the value carries `{plr, platform}`, so a Go
   edge's read contract does not change with the binding arm (B1/B2/B3).
5. **bitmapist by the durable PLR, off the auth hot path, never fails auth** — outside the auth trust boundary;
   its wiring is forward-vision (UNBUILT today).

---

## §5 · The phasing (a clean floor line)

**The cm.4 FLOOR:** the `Codemojex.InitData` verifier + the handshake (`POST /api/auth/:platform`) minting the
`SES`-in-Valkey (JSON) + the `:cm_sessions` `EchoStore.Table` (the ruled coherence mode) + the `SES`-resolve plug
over the 5 routes + the socket `SES`-verify + the `require_player → conn.assigns.player` cutover + **retire
`POST /api/players`** + the dev/test posture + the `SES` TTL + `invalidate`/`DEL` revocation + `auth_date`
freshness + Stage-1's PLR migration.

**FORWARD rungs** (shaped, not in the floor; the floor forecloses nothing — all read the *same* documented `SES`
shape): the documented **Go-edge read contract**, **bitmapist** (`:6400`) marking, **LiveView** auth, **`SES`
Graft-durability**.

---

## §6 · Consolidated next actions (for Operator ratification)

1. **Rule §3** (the coherence mode, the TTL, the durability tier, FF) — the `AskUserQuestion` the Director brings.
   The converged `SES` model (§2) is **build-ready** on ratification.
2. On the rulings, **Venus re-authors the cm.4 triad** to the floor (§5). Stage-1's `cm.4.postgres.design.md`
   (the PLR / `tg_user_id`) **stands**; the `SES` is a NEW `EchoStore` surface (Valkey, not Postgres).
3. **The build is a HIGH-risk Squad** (auth + the **first mutable EchoStore table** + a wire cutover + the
   shared-store contract) → Apollo mandatory; the verify deepens (the ≥100 mint loop at the handshake, **the
   revocation invariant** — a `DEL` purges every holder's L1, or the staleness bound is named — and the mutation
   battery on the verifier + the `SES`-resolve + the ACL).
4. **The floor ships thin**; the Go-edge contract / bitmapist / LiveView / Graft are forward rungs.

---

## §7 · What stays open (the Operator's, surfaced not decided)

- **§3.1** the coherence mode (`:broadcast` vs `:tracking`) — the headline.
- **§3.2** the TTL (sliding vs fixed).
- **§3.3** the durability tier (ephemeral / AOF / Graft).
- **§3.4** FF the dev/test posture (lean F2).
- The **converged `SES` model (§2)** is build-ready on the Operator's ratification.

---

*Director synthesis, v2. The architects argued the shared-`SES` model (Lens A consumer/cross-edge, Lens B
store/steward); this doc staged the agreement and the three coherence-shaped disagreements; the Operator rules.
Convergence is confidence; the divergence is the signal. The v1 stateless-token synthesis is superseded by G6.*
