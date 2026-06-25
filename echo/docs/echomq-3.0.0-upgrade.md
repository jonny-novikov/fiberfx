# EchoMQ Wire `echomq:3.0.0` Cutover — Step-by-Step Runbook

A point-in-time runbook for the wire-version bump from `echomq:2.4.2` → **`echomq:3.0.0`**.
For the reusable mechanics (how the fence works, the connection tooling, how to do the *next*
cutover), see the companion **[Developer Guide: the wire-version fence](wire-version-fence.dev-guide.md)**.

> **One-line summary.** The wire version is a single constant *and* a distributed boot fence.
> Bumping it is two acts: change the code, then retire the old fence claim on every Valkey the
> stack connects to. Skipping the second act makes every boot fail the fence.

---

## 0. What changed and why

`EchoMQ.Connector.@wire_version` is the protocol-compatibility tag a connector claims/verifies
against the shared key `{emq}:version` at **every** boot (`connector.ex` `fence/2`). A **major**
bump (`2.x` → `3.0`) is an intentional hard lockout: once the fence reads `echomq:3.0.0`, any
node still running a `2.x` wire is refused with `{:version_fence, "echomq:3.0.0"}`. This enacts
the program's planned terminal version (the `echomq:3.0.0` era; the Stream Tier is "EchoMQ 3.0").

### Blast radius — exactly three things

| # | Thing | Where | This run |
|---|---|---|---|
| 1 | The code constant | `apps/echo_wire/lib/echo_mq/connector.ex:35` | ✅ done |
| 2 | The **local** fence key | `valkey-cli -p 6390` db-0 `{emq}:version` | ✅ done |
| 3 | The **production** fence key | Fly app `echo-valkey` `{emq}:version` | ⏳ Operator step (§6) |

Everything else that references the version reads `Connector.wire_version/0` **dynamically**
(the conformance version scenario, the connector tests), so nothing else needed editing.

---

## 1. Bump the constant  ✅

```elixir
# apps/echo_wire/lib/echo_mq/connector.ex:35
@wire_version "echomq:3.0.0"   # was "echomq:2.4.2"
```

This is the *only* source change. `wire_version/0` (`connector.ex:138`) and `fence/2`
(`connector.ex:467-488`) both read the attribute, so the whole fence tracks it automatically.

A follow-up `@wire_version` sweep (`grep` across `apps/`) found one stale historical reference in
`apps/echo_mq/lib/echo_mq/stream_consumer.ex` (an emq3.3 rung-note that quoted `echomq:2.4.2`);
it has been corrected so it no longer states a stale "current" wire version.

---

## 2. Verify the code (no shared-state writes)  ✅

```bash
# Per-app compile gate — run from each app dir, never umbrella-wide.
for app in echo_wire echo_data echo_mq echo_store; do
  ( cd apps/$app && TMPDIR=/tmp mix compile --warnings-as-errors )
done
```

- `echo_wire`, `echo_mq`, `echo_store` → **clean** under `-Werror`.
- `echo_data` → fails `-Werror` on `lib/echo_data/champ_view.ex:48,82` (`EchoStore.Graft.*`
  undefined). This is **pre-existing inverted-layering debt** (echo_data is the pure base;
  `EchoStore.Graft` lives one layer up in echo_store) and is **unrelated** to the wire bump —
  `champ_view.ex` never mentions `@wire_version`. Left untouched (a third app, outside the rung
  boundary). Plain `mix compile` and `mix test` are unaffected (they don't use `-Werror`).

The fence logic itself is provable **without** touching the shared db-0 key, because the connector
tests isolate the fence on logical **db-15** (`connector_test.exs` `@fence_db 15`):

```bash
cd apps/echo_mq
TMPDIR=/tmp mix test test/connector_test.exs:46 test/connector_test.exs:89 \
  test/connector_test.exs:96 test/connector_test.exs:106 --include valkey
# → claims on an empty fence, verifies a match, refuses a mismatch — all green.
```

---

## 3. Cut over the LOCAL fence  ✅

The broad `--include valkey` suites and a local codemojex boot connect on db-0, whose
`{emq}:version` still held the old value. Cut it over:

```bash
valkey-cli -p 6390 GET '{emq}:version'                 # echomq:2.4.2  (stale)
valkey-cli -p 6390 SET '{emq}:version' echomq:3.0.0    # OK
valkey-cli -p 6390 GET '{emq}:version'                 # echomq:3.0.0
```

> A bare `DEL` works too (the first 3.0.0 connector then *claims* it via `SET NX`). `SET` is
> chosen here because it is deterministic and matches the cutover intent.

---

## 4. Full umbrella verification  ✅

```bash
( cd apps/echo_wire  && TMPDIR=/tmp mix test --include valkey )
( cd apps/echo_data  && TMPDIR=/tmp mix test )
( cd apps/echo_mq    && TMPDIR=/tmp mix test --include valkey )   # includes conformance pinning
( cd apps/echo_store && TMPDIR=/tmp mix test --include valkey )
```

| App | Result |
|---|---|
| echo_wire | 109 tests, **0 failures** |
| echo_data | 65 tests + 3 properties, **0 failures** |
| echo_mq | 541 tests, **0 failures** · `CONFORMANCE 79/79` |
| echo_store | 99 tests, **0 failures** (the `[live_round_trip] EXCLUDED` notes are the opt-in Graft real-backend leg, gated on `ECHO_GRAFT_BACKEND_TEST=1` — not failures) |

Expected log noise in the echo_mq run: `GenServer … killed` (crash-recovery tests deliberately
kill connectors) and one `XGROUP CREATE refused … WRONGTYPE` (a *negative* test asserting the
stream consumer fails loudly on a key collision). Both are part of a green suite.

**Determinism posture.** A wire-version bump changes a constant, not id-mint / process / lease
logic, so the `≥100×` determinism loop is not required; a clean full run (plus the standard
multi-seed default) is sufficient.

---

## 5. Boot codemojex Phoenix (end-to-end handshake proof)  ✅

codemojex's supervision tree boots `Repo → Bus (the shared Valkey connector) → EchoStore.Tables
→ consumers → Endpoint` (`apps/codemojex/lib/codemojex/application.ex`). The `Bus` connector
fences against db-0 at boot, so a successful serve **is** the handshake proof — a failed fence
would crash-loop the `Bus` child and take the Endpoint down with it.

```bash
cd apps/codemojex
TMPDIR=/tmp mix ecto.create && TMPDIR=/tmp mix ecto.migrate     # dev DB (postgres/postgres@localhost/codemojex_dev)
TMPDIR=/tmp MIX_ENV=dev mix phx.server &                        # boots the tree on :4000
curl -s -w '\n%{http_code}\n' http://127.0.0.1:4000/api/health  # → {"status":"ok"}  200
```

Observed: `Running CodemojexWeb.Endpoint with Bandit 1.11.1 at 127.0.0.1:4000`, **0 errors /
0 `version_fence`** in the boot log, `/api/health → 200 {"status":"ok"}`.

> Note: the health route is `GET /api/health` (it lives under `scope "/api"`). The production
> `fly.toml` health check points at `/health` — a separate prod-config observation, not part of
> this cutover.

---

## 6. Cut over the PRODUCTION fence on `echo-valkey`  ⏳ Operator step

This is the only step not performed here. It is a **gated production-state write** and must be
**coordinated with the codemojex redeploy** (only the Operator deploys — see memory
`operator-runs-deploys`).

### Readiness already confirmed (read-only)

`echo-valkey` was probed via `scripts/fly-valkey.sh` (a temporary `fly proxy` + authenticated
`valkey-cli`, password from `infra/valkey/.env.production`). Both paths are at the **`jonnify`
repo root**, the parent of this `echo/` umbrella (`../scripts/`, `../infra/` from `echo/`):

- **Valkey 9.1.0**, port 6390, `requirepass` via the `VALKEY_EXTRA_FLAGS` secret, persistent
  `/data` mount.
- `DBSIZE 0`, `{emq}:version` **absent**, **no clients connected**.

A pristine, empty instance is the cleanest cutover state: the first 3.0.0 client will *claim*
`echomq:3.0.0` on connect; there is no stale `2.x` value to lock it out, and nothing to disrupt.

### The coordinated cutover (Operator runs)

```bash
# 1. (optional but deterministic) pre-claim the fence as 3.0.0:
scripts/fly-valkey.sh SET '{emq}:version' echomq:3.0.0
scripts/fly-valkey.sh GET '{emq}:version'        # → echomq:3.0.0

# 2. deploy codemojex built on the echomq:3.0.0 wire (Operator's normal deploy).
#    The new instance's Bus connector fences green (verify branch) and boots.
```

> **Sequencing matters.** Pre-claiming `3.0.0` arms a lockout for any *live* `2.x` client that
> reconnects (it would crash-loop on the fence). It is safe **now** because no client is on
> echo-valkey, but in general do the pre-claim **as part of** the deploy window, not long before
> it. (The current live `codemoji-phoenix` v74 is *not* on echo-valkey — confirmed by the empty
> keyspace — so there is no client to disrupt today.)

### Verify after deploy

```bash
scripts/fly-valkey.sh GET '{emq}:version'        # → echomq:3.0.0
fly status -a codemoji-phoenix                   # new version, checks passing
```

---

## 7. Rollback

| To undo… | Do |
|---|---|
| The code | revert `connector.ex:35` to `@wire_version "echomq:2.4.2"` |
| The local fence | `valkey-cli -p 6390 SET '{emq}:version' echomq:2.4.2` (or `DEL`) |
| The production fence | `scripts/fly-valkey.sh SET '{emq}:version' echomq:2.4.2` (or `DEL`) **+** redeploy the `2.x` client |

A major bump is a one-way door by design: rolling back the fence without also rolling back the
client (or vice-versa) reintroduces the `{:version_fence, …}` refusal. Roll both together.

---

## Appendix — known pre-existing item (not part of this cutover)

`apps/echo_data/lib/echo_data/champ_view.ex` calls `EchoStore.Graft.*`, which is undefined when
echo_data compiles alone → `mix compile --warnings-as-errors` fails *in echo_data's dir only*.
This is an inverted layering (base app referencing a higher layer) that predates this work and is
out of the echo_mq/echo_wire boundary. Tracked here for visibility; fix it as its own change.
