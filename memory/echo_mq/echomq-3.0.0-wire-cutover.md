---
name: echomq-3-0-0-wire-cutover
description: "echomq:3.0.0 wire bump — code + LOCAL fence DONE, PROD echo-valkey fence PENDING (Operator/gated); fly-valkey.sh tool + echo-valkey topology + the two docs"
metadata: 
  node_type: memory
  type: project
  originSessionId: dfc9537d-f90d-4421-9f93-ca7810fa2c6b
---

The EchoMQ wire bump `echomq:2.4.2` → **`echomq:3.0.0`** (2026-06-25).

- **Code (DONE):** `@wire_version` at `apps/echo_wire/lib/echo_mq/connector.ex:35` — the ONLY source change; everything else reads `Connector.wire_version/0` dynamically (conformance + tests assert the *shape* `echomq:\d+\.\d+\.\d+`, never a literal). Fence logic: `connector.ex:467-488` (`fence/2`), key `{emq}:version` (`keyspace.ex:11`).
- **The cutover is TWO-SIDED:** the code constant + the persisted `{emq}:version` on *every* Valkey. The persisted key out-votes the constant until cut over (`SET`/`DEL`), so bumping code alone makes every boot fail the *refuse* branch `{:version_fence, …}`.
- **LOCAL `:6390` db-0 (DONE):** `SET '{emq}:version' echomq:3.0.0`. Full umbrella GREEN — echo_wire 109 · echo_data 65+3 · echo_mq 541 (**conformance 79/79**) · echo_store 99, 0 failures. codemojex Phoenix boots clean: `GET /api/health` → 200 (route is under `scope "/api"`, **not** `/health`), 0 errors / 0 `version_fence` in the boot log.
- **PRODUCTION `echo-valkey` (PENDING — Operator):** gated write; coordinate with the codemojex redeploy. echo-valkey = **Valkey 9.1.0, `:6390`, `requirepass` via the `VALKEY_EXTRA_FLAGS` secret, persistent `/data`**; was **empty** (`DBSIZE 0`, no `{emq}:version`, no clients) so the first 3.0.0 client claims cleanly. The live `codemoji-phoenix` v74 is **not** on echo-valkey (empty keyspace proves it).
- **TOOL:** `scripts/fly-valkey.sh` at the **jonnify repo root** (parent of `echo/`) — `fly proxy` + authed `valkey-cli`, password from `infra/valkey/.env.production`; secret never printed. `scripts/fly-valkey.sh GET '{emq}:version'`.
- **DOCS:** `echo/docs/echomq-3.0.0-upgrade.md` (step runbook) + `echo/docs/wire-version-fence.dev-guide.md` (fence mechanics + tooling + gotchas).
- **Pre-existing unrelated debt:** `apps/echo_data/lib/echo_data/champ_view.ex:48,82` calls undefined `EchoStore.Graft.*` → fails `-Werror` in echo_data's dir only (inverted layering: pure base → higher layer). NOT from the bump.

**Why:** a major wire bump is a deliberate, coordination-free lockout of old-protocol nodes; the fence is `claim | verify | refuse` against `{emq}:version` at every connect/reconnect.

**How to apply:** finish prod by running `scripts/fly-valkey.sh SET '{emq}:version' echomq:3.0.0` **in the deploy window**, then redeploy codemojex; verify read-only via `GET`. NEVER pre-claim a *live* prod fence ahead of the deploy — an old client crash-loops on its next reconnect (the fence runs on reconnect too). A pristine/empty instance is the one safe time to pre-claim freely.

Related: [[echo-mq-three-movements]] [[operator-runs-deploys]]
