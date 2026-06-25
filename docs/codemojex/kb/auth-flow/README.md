# Codemojex Auth Flow (the cm.4 re-scope) — design-ahead KB

A two-architect design-ahead of the re-scoped cm.4 auth flow, authored for **independent Operator review** before
the auth surface freezes. Method of record:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms; the
multi-architect debate). Pattern: [`../../../echo_mq/kb/streams-tier/`](../../../echo_mq/kb/streams-tier/).

**The model (v2 — the Operator-ruled shared-session reframe, G6–G9):** **dual-auth, token-centric,
platform-pluggable**, with the session **SHARED across services** — Phoenix + Go lightweight edges (bitmapist) +
LiveView — so the bearer is a stateful **`SES` branded id in Valkey** (an `EchoStore` entity), resolvable from the
shared store by any service. The v1 stateless-`Phoenix.Token` model is **superseded** (a stateless token is not
carriable to a non-BEAM edge).

| Doc | Author | What it is |
|---|---|---|
| [`auth.design.A-consumer-lens.md`](./auth.design.A-consumer-lens.md) | Architect A (Venus) | Every fork from the **consumer / cross-edge** lens (the Mini App client, the Go edges + bitmapist, LiveView, the cross-language read contract, the forward-vision phasing). |
| [`auth.design.B-steward-lens.md`](./auth.design.B-steward-lens.md) | Architect B (VenusPG) | Every fork from the **store / steward / security** lens (the `SES`-in-Valkey schema + language-neutral encoding, EchoStore coherence for a *mutable* session, echo-persistence durability, the Redis session patterns, the threat model). |
| [`auth.synthesis.md`](./auth.synthesis.md) | Director | The v2 cross-lens diff: the two lenses **CONVERGED on the shared-`SES` model** (an EchoStore entity, JSON-in-framed-String, read-only edges, the BEAM the sole authority) and **DIVERGED on the coherence questions a mutable session raises** — the coherence mode (`:broadcast` vs `:tracking`), the TTL (sliding vs fixed), the durability tier (ephemeral / AOF / Graft). |

**Read order for review:** the synthesis first (the convergent model + the three coherence-shaped divergences),
then either lens doc for the full four-part argument behind any fork.

**The GIVENs (Operator-ruled, carried by both):** G1 dual-auth token model · G2 platform-pluggable · G3
`POST /api/players` retired (a **free-money** gap — synthesis §4) · G4 the `InitData` verifier + the Stage-1
resolve-or-create survive at the handshake · G5 the 8 suites byte-unchanged, boundary `echo/apps/codemojex/**` ·
**G6 shared session across Go edges + Phoenix + LiveView** · **G7 `SES` in Valkey via EchoStore + echo-persistence,
the Redis session patterns** · **G8 bitmapist analytics (`infra/codemojex-bitmapist/`, `:6400`)** · **G9 LiveView
forward-vision**.

**Status:** design-ahead, uncommitted, for review. **No code, no canon edit** — the cm.4 triad re-authoring is the
post-ruling step; the Stage-1 relational design ([`../../specs/cm.4.postgres.design.md`](../../specs/cm.4.postgres.design.md))
stands. The auth **floor** (the verifier + the handshake + the `SES`-in-Valkey + the cutover + retiring
`/api/players`) is the cm.4 rung; the **Go-edge read contract, bitmapist, LiveView, and `SES` Graft-durability**
are shaped as forward rungs (the floor forecloses nothing).
