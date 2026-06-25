# Developer Guide — the EchoMQ wire-version fence & production Valkey

How the `@wire_version` boot fence works, how to talk to the production `echo-valkey` node, and
how to perform a wire-version cutover without breaking the bus. For the concrete `echomq:3.0.0`
cutover that motivated this guide, see the **[step-by-step runbook](echomq-3.0.0-upgrade.md)**.

---

## 1. Three "versions" — don't confuse them

The word "version" is overloaded across this stack. They are independent:

| Identifier | Example | What it is | Lives in |
|---|---|---|---|
| **`@wire_version`** | `echomq:3.0.0` | The **protocol fence** — the compatibility tag every connector claims/verifies at boot. *This* is what a "wire bump" changes. | `apps/echo_wire/lib/echo_mq/connector.ex:35` |
| App (Mix) version | `echo_mq 2.6.5` | The OTP app's package version. Bumped on releases; **unrelated** to the wire. | each app's `mix.exs` |
| Product generation | "EchoMQ 3.0", "the Stream Tier" | A prose label for a feature era (used in moduledocs). | docs & `@moduledoc`s |

> The moduledoc that calls it "the EchoMQ 2.0 connector" is the *product generation* name; it is
> not the wire version and is intentionally not edited by a wire bump.

The wire version string is `echomq:MAJOR.MINOR.PATCH`. The conformance suite asserts the *shape*
(`~r/^echomq:\d+\.\d+\.\d+$/`, `connector_test.exs:46`), never a literal — so a per-rung bump
never requires a test edit.

---

## 2. What the fence is

`@wire_version` is not a label — it is a **distributed boot fence**. Every `Connector` runs it as
the last step of its connect handshake, against the cross-queue key `{emq}:version`
(`EchoMQ.Keyspace.version_key/0`, `keyspace.ex:11,30`).

The connect handshake (during `start_link`/reconnect):

```
HELLO (protocol negotiate) → boot_auth (AUTH, if a password is set)
                           → boot_rest (SELECT <db>, CLIENT SETNAME)
                           → fence  (GET {emq}:version, compare)
```

`fence/2` (`connector.ex:467-488`) has exactly three branches:

```elixir
case GET {emq}:version do
  ^@wire_version -> :ok                                  # VERIFY  — boot
  nil            -> SET {emq}:version @wire_version NX    # CLAIM   — first node wins, read-back, boot
                    + read-back == @wire_version ? :ok
  other          -> {:error, {:version_fence, other}}    # REFUSE  — fatal: the connection never lives
end
```

So the fence is **claim-or-verify-or-refuse**:

- **Empty key** → the first connector to boot *claims* the version (atomic `SET NX` + read-back).
- **Matching key** → *verify*, boot normally.
- **Mismatched key** → **fatal refusal** (`{:version_fence, got}`); `start_link` returns an error
  and the process does not stay up.

### Why a major bump locks out old nodes (on purpose)

Once any node claims `echomq:3.0.0`, every `2.x` node hits the *refuse* branch. That is the point
of a **major** bump: it is a hard, coordination-free interlock that prevents a stale-protocol node
from ever touching a bus that has moved on. (Contrast a **minor** bump: per the additive-minor
conformance law, *additive* script/scenario registration is a minor and does not break the wire;
only a wire-breaking change is a major.)

---

## 3. The cutover is always two-sided

A wire bump touches **code** and **every Valkey the stack connects to**:

1. **Code** — edit the one constant (`connector.ex:35`). Everything else reads it dynamically
   (`wire_version/0` at `:138`, the conformance version scenario, the connector tests).
2. **State** — the fence key already persisted on each Valkey still holds the *old* value. Until
   it is retired (`DEL`) or moved (`SET … <new>`), every boot fails the *refuse* branch.

Forgetting (2) is the classic failure: the code is correct, yet nothing boots, because the key in
Valkey out-votes the constant. **Local dev** (`:6390`) and **production** (`echo-valkey`) each have
their own `{emq}:version` and each must be cut over.

> **Test isolation detail.** `connector_test.exs` runs its fence tests on logical **db-15**
> (`@fence_db 15`) precisely because db-0's `{emq}:version` is shared. That lets the fence
> claim/verify/refuse paths be exercised (and the key poisoned + `FLUSHDB`-restored) without
> disturbing any db-0 connection. Use the same trick to test fence behavior without a real cutover.

---

## 4. Talking to production `echo-valkey`

`echo-valkey` is a **private-by-design 6PN Fly node**: no public address, and it requires a
password (`--requirepass`, shipped via the `VALKEY_EXTRA_FLAGS` secret). You reach it with a
temporary `fly proxy` tunnel + an authenticated `valkey-cli`.

### `scripts/fly-valkey.sh`

> **Location.** `scripts/` and `infra/` are at the **`jonnify` repo root** — the *parent* of this
> `echo/` umbrella (so `../scripts/fly-valkey.sh` and `../infra/valkey/` from `echo/`). The script
> self-locates its env file relative to its own path, so you can invoke it by full path from any
> directory. Commands below are written as if run from the repo root.

```bash
scripts/fly-valkey.sh                        # interactive valkey-cli
scripts/fly-valkey.sh PING                   # one-shot command
scripts/fly-valkey.sh GET '{emq}:version'    # read the wire fence
```

What it does: opens `fly proxy <local>:6390 -a echo-valkey`, reads the password from
`infra/valkey/.env.production` (`VALKEY_PASSWORD`, or `--requirepass` parsed out of
`VALKEY_EXTRA_FLAGS`), runs your `valkey-cli` command through the tunnel, and always tears the
tunnel back down. **The secret is read at runtime and never printed.** Env overrides:
`FLY_VALKEY_APP`, `FLY_VALKEY_REMOTE_PORT`, `FLY_VALKEY_LOCAL_PORT`, `FLY_VALKEY_ENV`.

> `infra/valkey/.env.production` is a **secret file** — keep it out of git and out of command
> output. Read-only inspection of `echo-valkey` (PING, GET, INFO) is fine; **writes** to its
> `{emq}:version` are a production-state change and are gated — coordinate them with a deploy and
> let the Operator run them (memory: `operator-runs-deploys`).

---

## 5. Recipe — how to do the next wire cutover

**Minor / additive bump** (no wire break — e.g. registering a new script or conformance scenario):

1. Bump `connector.ex:35` (e.g. `echomq:3.0.0` → `echomq:3.1.0`).
2. Re-pin the conformance count in both pinning tests; keep prior scenarios byte-unchanged.
3. Cut over each fence key (`SET '{emq}:version' echomq:3.1.0`) and redeploy. Old `3.0.x` nodes
   *will* be refused — even a minor bump moves the fence, so still a coordinated cutover.

**Major bump** (wire break — intentional lockout):

1. Bump the constant.
2. Per-app gates: `TMPDIR=/tmp mix compile --warnings-as-errors` + `TMPDIR=/tmp mix test
   --include valkey` from each app dir (never umbrella-wide); `EchoMQ.Conformance.run/2 →
   {:ok, n}`.
3. Cut over **local** db-0: `valkey-cli -p 6390 SET '{emq}:version' <new>`.
4. Re-run the broad `--include valkey` suites + boot a client (codemojex `mix phx.server` →
   `GET /api/health` = 200) to prove the end-to-end handshake.
5. Cut over **production** `echo-valkey` **in the deploy window** (see the crash-loop note below),
   then redeploy the client. Verify with `scripts/fly-valkey.sh GET '{emq}:version'`.

Always `TMPDIR=/tmp` for `mix` (the harness tmp overlay hits ENOSPC and surfaces as spurious
mid-suite I/O failures).

---

## 6. Gotchas (hard-won)

- **The crash-loop trap.** Setting a *live* Valkey's fence to a new version while an *old* client
  is still connected arms a lockout: the moment that client reconnects (a TCP blip, or a Fly
  machine restart), it hits the *refuse* branch, dies, and — if Fly restarts the same old image —
  **crash-loops** until the new image is deployed. ⇒ Pre-claim the production fence **as part of**
  the cutover deploy, not hours ahead. A pristine/empty instance with **no clients** is the one
  safe time to pre-claim freely.
- **An empty fence is the best cutover state.** `DBSIZE 0` / absent `{emq}:version` means the
  first new-version client simply *claims* it — no stale value to refuse it.
- **Reconnect re-fences.** The fence runs on initial connect *and* on reconnect. A connection that
  is already up is unaffected by a fence change until it next reconnects — which is why a change
  can look harmless for a while and then bite.
- **`echo-valkey` ≠ the codemojex sidecar.** A live `codemoji-phoenix` may connect to a *local*
  `localhost:6390` Valkey, not to `echo-valkey`. Verify what is actually fenced where (an empty
  `echo-valkey` keyspace means no client has ever fenced against it) before reasoning about
  lockouts.
- **Don't grep for the literal in tests.** Tests assert `Connector.wire_version/0` and the version
  *shape*, never the literal string — so the suite needs no edit on a bump. The only place the
  literal lives is `connector.ex:35`.

---

## 7. Quick reference

```bash
# read fences
valkey-cli -p 6390 GET '{emq}:version'                 # local dev
scripts/fly-valkey.sh GET '{emq}:version'              # production echo-valkey

# cut over a fence
valkey-cli -p 6390 SET '{emq}:version' echomq:3.0.0    # local
scripts/fly-valkey.sh SET '{emq}:version' echomq:3.0.0 # production (gated; deploy window)

# verify the code value
cd apps/echo_mq && TMPDIR=/tmp mix run -e 'IO.puts(EchoMQ.Connector.wire_version())'

# prove the handshake end-to-end
cd apps/codemojex && TMPDIR=/tmp MIX_ENV=dev mix phx.server &
curl -s -w '\n%{http_code}\n' http://127.0.0.1:4000/api/health   # {"status":"ok"} 200
```

| Fact | Value |
|---|---|
| Fence constant | `apps/echo_wire/lib/echo_mq/connector.ex:35` |
| Fence logic | `connector.ex:467-488` (`fence/2`) |
| Fence key | `{emq}:version` (`keyspace.ex:11`, `version_key/0` at `:30`) |
| Local engine | Valkey on `:6390`, db-0 |
| Production engine | Fly `echo-valkey`, Valkey 9.1.0, `:6390`, `requirepass`, persistent `/data` |
| Connection tool | `scripts/fly-valkey.sh` (+ `infra/valkey/.env.production`) |
