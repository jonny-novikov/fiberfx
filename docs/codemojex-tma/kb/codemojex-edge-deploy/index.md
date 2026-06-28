# codemojex-edge-deploy — publish the React game from an ephemeral Fly machine

> **Provenance & method.** A new spec rung, authored to
> [`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (Rationale → 5W → surfaced
> seams; Voice / NO-INVENT). It consolidates the Director's rationale, the 5W frame, and the
> Given/When/Then acceptance for **moving the edge-bundle publish off the Operator's laptop onto a
> one-shot Fly machine**. Every surface it names is verified at its source or written forward-tense for
> surface not yet built (the `fly.toml` + `Dockerfile` it specifies are now built under
> [`echo/apps/codemojex/edge-deliver/`](../../../../echo/apps/edge-deliver/)); it **links** the
> contracts it cites rather than restating them.
>
> **Grounding note (drift).** The parent roadmap
> ([`codemojex-tma.roadmap.md`](../../codemojex-tma.roadmap.md)) and
> [`codemoji.static-edge.md`](../../codemoji.static-edge.md) predate a rename and still say
> `static.codemoji.games` / `Codemojex.Edge.board_url/0` / `board-<hash>.js`. The **as-built code is
> authoritative** and is what this rung grounds in: the host is `edge.codemoji.games`, the resolver is
> [`Codemojex.Edge.game_url/0`](../../../../echo/apps/codemojex/lib/codemojex/edge.ex), the bundle is
> `game-<hash>.js`, and the pointer is `{"game": url}`.
>
> **Boundary — the Operator runs this, not the agent.** A `fly deploy` / `fly machine run` **publishes
> bytes to a live origin** and provisioning **creates infra on the Fly/Tigris account**; both are the
> Operator's to run, per the standing rule and the same boundary
> [`edge-bucket-setup.md`](../../../../echo/docs/edge-deliver/edge-bucket-setup.md) already draws. The agent
> authors the `fly.toml` + `Dockerfile`, wires the existing script, and verifies afterward with a public
> `curl`; it does not provision or deploy.

---

## 1. Rationale (Director-consolidated)

The publish path exists and works: [`scripts/edge-deploy.sh`](../../../../echo/apps/codemojex/scripts/edge-deploy.sh)
builds the content-hashed game bundle (`assets/` → `vite build` → `priv/static/game/game-<hash>.js`),
uploads every hashed file to the dedicated Tigris bucket under a one-year immutable cache, then flips the
short-cached `manifest.json` pointer that `Codemojex.Edge.game_url/0` reads. The bundle is uploaded
**before** the pointer is flipped, so the pointer never names a file that is not there.

What it couples is **who can run it**. The script needs `aws`, `node`, `npm`, and `curl` on the host and
the `TIGRIS_EDGE_*` keypair in the environment
([`edge-bucket-setup.md` §3a](../../../../echo/docs/edge-deliver/edge-bucket-setup.md)). Today that host is
the Operator's laptop after `source echo/.env`. A UI iteration — the most frequent change in the system —
is therefore gated on one provisioned local toolchain and a secret file on disk.

**The chosen approach: run the exact same publish on a one-shot Fly machine.** A small image carries
`node` + the AWS CLI + the script; the `TIGRIS_EDGE_*` creds arrive as Fly secrets; the machine runs
`edge-deploy.sh` (build → upload-immutable → flip the pointer → verify) in `fra` beside the bucket and
**exits**. It is credible because it relocates the publish without reinventing it — the script, the
immutable-then-pointer ordering, the host (`edge.codemoji.games`), and the runtime resolver are all
unchanged. Nothing is baked into the image: the script owns the build, so the image is a pure environment
and the bundle is built on each run.

What this explicitly **does not** change: the always-on app machine. The `codemojex` Fly app keeps
`min_machines_running = 1` / `auto_stop_machines = false` ([`fly.toml`](../../../../echo/fly.toml)) so live
`/socket` sessions are never reaped; the edge publish touches **only** the bucket. Crucially, the deliver
machine never reaches into the `codemojex` app at all:
[`Codemojex.Edge.game_url/0`](../../../../echo/apps/codemojex/lib/codemojex/edge.ex) already re-resolves
the pointer on the render path (~10s TTL), so flipping `manifest.json` is the whole job — **the app picks
up the new bundle by polling**. The two surfaces communicate only through the bucket pointer (a message
about a name), which is why this needs no Fly token and no app-side secret write — §5 records how that was
ruled.

## 2. The 5W

- **Why** — decouple a UI publish from a provisioned laptop. The edge split already decoupled the bundle
  from the engine *release*; this decouples the *publish act* from one operator's machine, so any
  authorized trigger ships a board change reproducibly.
- **What** — a `fly.toml` + `Dockerfile` for a one-shot Fly machine, `codemojex-edge-deliver`, that runs
  `edge-deploy.sh` (build → upload immutable → flip the `manifest.json` pointer → verify) and exits. No
  service, no always-on machine, no open port, no app-side write.
- **Who** — the **Operator** triggers and owns it (it deploys to a live origin). It consumes **only** the
  Tigris **edge bucket** keypair (write side, least privilege) — no Fly token, no access to the `codemojex`
  app. The running app (`Codemojex.Edge`, the read side) is unchanged and needs no new grant; it simply
  keeps polling the pointer.
- **When** — after the edge bucket + custom domain are stood up
  ([`edge-bucket-setup.md`](../../../../echo/docs/edge-deliver/edge-bucket-setup.md), already documented). It
  is the operational successor to "run the script locally", invoked on every board iteration and on
  rollback.
- **Where** — a new sibling under the codemojex app, e.g. `echo/apps/codemojex/edge-deliver/`
  (`Dockerfile` + `fly.toml`), reusing the existing `assets/` build and `scripts/edge-deploy.sh`. The Fly
  **app** is `codemojex-edge-deliver`, distinct from the `codemojex` app it never restarts. Canon for the
  rung lives here in `docs/codemojex-tma/kb/codemojex-edge-deploy/`.

## 3. The shape (as built)

The pieces, now built under
[`echo/apps/codemojex/edge-deliver/`](../../../../echo/apps/edge-deliver/), grounded against the
umbrella [`Dockerfile`](../../../../echo/Dockerfile) / [`fly.toml`](../../../../echo/fly.toml) as the
deploy-config precedent and against the script as the behavior of record:

**`Dockerfile`** — base `node:22-bookworm-slim` (the same Node major the app image pins) `+` the AWS CLI
`+` `curl`. The build context is the **umbrella root `echo/`**, because `assets/package.json` declares its
phoenix packages as `file:../../../deps/phoenix*` and `npm ci` needs those dep dirs present — so the image
`COPY`s `deps/phoenix*` alongside `apps/codemojex/{assets,scripts}`. The image is a **pure environment**:
it does **not** bake the bundle, because `edge-deploy.sh` already owns build → upload → flip as one unit
and forking it to skip the build would break the single source of truth (do-no-harm). The **entrypoint is
the script itself** — no wrapper, no flyctl, no Fly token. It is a job, not a server.

**`fly.toml`** — `app = "codemojex-edge-deliver"`, `primary_region = "fra"` (beside the bucket). **No
`[[services]]`, no `[http_service]`, no `min_machines_running`** — this is a task, not a server; the
machine runs to completion and stops. Only the `TIGRIS_EDGE_*` keypair is a **Fly secret** (write side,
least privilege) — never `[env]`, never committed, and **no Fly token**.

**The runtime sequence** the machine executes is `edge-deploy.sh`'s contract, unchanged:

0. `npm ci && npm run build` → `priv/static/game/game-<hash>.js` (+ the vite manifest);
1. upload every `game-*` file with `Cache-Control: public,max-age=31536000,immutable`;
2. **then** write `manifest.json` = `{"game":"https://edge.codemoji.games/game-<hash>.js"}` (short cache);
3. verify the pointer + bundle over HTTPS;
4. exit (non-zero on any failure, leaving the pointer un-flipped — see the failure scenario in §4).

That is the whole job — no app-side step follows. `Codemojex.Edge.game_url/0` re-resolves the flipped
pointer on its next render (~10s TTL), so the new bundle goes live with no restart, no secret, no token.

`--dry-run` and `--rollback game-<hash>.js` carry through from the script unchanged.

## 4. Given / When / Then

**Happy path — a board iteration goes live with no app restart.**
- *Given* the edge bucket + `edge.codemoji.games` are live, the `TIGRIS_EDGE_*` secrets are set on
  `codemojex-edge-deliver`, and the machine image carries a freshly built `game-<hash>.js`,
- *When* the Operator runs the one-shot machine,
- *Then* every `game-*` file is uploaded immutably, the `manifest.json` pointer is flipped to the new
  hash, the HTTPS verify of pointer + bundle returns 200, the machine exits 0 — and within ~10s (the
  `Codemojex.Edge` cache TTL) the next game mount imports the new bundle **with no `fly deploy` and no
  `/socket` drop on the `codemojex` app**.

**The app picks up the new bundle by polling — no app-side change.**
- *Given* a successful upload + pointer flip,
- *When* the next game mount calls `Codemojex.Edge.game_url/0` after its ~10s cache expires,
- *Then* it re-resolves `manifest.json`, imports the new `game-<hash>.js`, and the `codemojex` machine is
  **never touched** — no `fly secrets set`, no Fly token, no `/socket` drop.

**Dry run — nothing is published.**
- *Given* the machine is invoked with `--dry-run`,
- *When* it runs,
- *Then* it prints what it *would* upload and flip, writes **nothing** to the bucket, does **not** touch
  `GAME_ASSET_URL`, and exits 0.

**Rollback — a pointer flip, no rebuild.**
- *Given* a previous immutable `game-<previous-hash>.js` still in the bucket,
- *When* the machine is invoked with `--rollback game-<previous-hash>.js`,
- *Then* only `manifest.json` is re-pointed (no build, no re-upload), the verify passes, and the app
  serves the previous bundle within the cache TTL.

**Failure is safe — the pointer never names a missing file.**
- *Given* the build or any upload fails (a Tigris blip, a bad credential),
- *When* the machine runs,
- *Then* it exits **non-zero before the pointer flip**, so `manifest.json` keeps naming the last-good
  hash, the running app is wholly unaffected, and no `GAME_ASSET_URL` change is staged.

**Least privilege holds.**
- *Given* the machine's **one** credential — the Tigris edge-bucket keypair,
- *When* it runs,
- *Then* that keypair is scoped to the **edge bucket only** (it never sees the account `AWS_*`), and the
  job holds **no** Fly token and **no** access to the `codemojex` app — it can only write the bucket.

## 5. Seams & open decisions (surfaced — the Operator rules)

> Per the approach, an agent surfaces forks; it never decides them. The first is load-bearing and is
> argued as arms; the rest are surfaced as a table.

### S-1 — Whether `GAME_ASSET_URL` is refreshed per publish (the load-bearing fork)

> **RULED (Operator, this rung) → Arm B, poll-only: the deliver machine updates no app config.** The
> realization that supersedes an earlier Arm C ruling: `Codemojex.Edge.game_url/0` already re-resolves
> `manifest.json` on the render path (~10s TTL), so the deliver machine's job ends at the pointer flip and
> the app picks up the new bundle by **polling**. No `GAME_ASSET_URL` write per publish, **no Fly token,
> no `flyctl` in the image, no cross-app reach** — the two surfaces communicate only through the bucket
> pointer (a message about a name). `GAME_ASSET_URL` remains a coarse, **setup-time-only** fallback for a
> pointer outage, pinned once per
> [`edge-bucket-setup.md` §3b](../../../../echo/docs/edge-deliver/edge-bucket-setup.md), outside this job.
> **CHOSEN-AGAINST — Arm C (staged secret):** real (it refreshes the fallback without a restart) but
> needless once the poll is the live mechanism — it buys a marginally-fresher fallback at the cost of a
> deploy-capable Fly token on the live app. **CHOSEN-AGAINST — Arm A (unstaged `fly secrets set`):**
> rejected outright — a rolling restart per UI iteration inverts the architecture's reason for being.

The crux. `Codemojex.Edge.game_url/0` reads the bucket pointer at runtime and consults `GAME_ASSET_URL`
**only when the pointer fetch fails** ([`edge.ex`](../../../../echo/apps/codemojex/lib/codemojex/edge.ex) —
`fetch_pointer() || fallback()`). So the live swap does **not** need this env at all; `GAME_ASSET_URL` is
purely the degraded-path fallback. The tension: the natural way to update it, `fly secrets set` on the
`codemojex` app, **rolling-restarts the always-on machine** — the precise socket-drop the edge split
exists to prevent ([`static-edge.md`](../../codemoji.static-edge.md): "the machine whose entire reason for
staying up is to not drop sockets").

- **Arm A — set it every deploy (`fly secrets set`, unstaged).** *Steelman:* the fallback always names the
  current bundle, so a pointer blip right after a deploy degrades to the *new* bundle, not a stale one;
  it is the literal task ask and the simplest to write. *Steward:* every routine UI iteration now triggers
  a rolling restart of the live game machine and drops sockets — it inverts the architecture's reason for
  being and makes the cheap, frequent act carry the most expensive cost. A poor multi-year liability.
- **Arm B — pin it once, never per deploy.** *Steelman:* zero restarts; the runtime pointer is the only
  live mechanism, exactly as designed; the fallback stays a coarse "last known good" set at first deploy.
  *Steward:* if the bucket is unreachable *and* the app cold-reads, it serves whatever old hash was pinned
  — but old hashes are immutable and retained, so this is the "degrade to a last-known bundle" the design
  already accepts. Cheapest to keep; the fallback simply ages.
- **Arm C — staged secret (`fly secrets set --stage`), applied on the next engine deploy.** *Steelman:*
  refreshes the fallback toward the current bundle **without** a restart; the staged value lands on the
  next genuine `codemojex` release. Honors no-socket-drop *and* keeps the fallback fresh-ish. *Steward:*
  the fallback lags by up to one engine deploy (acceptable — it is only ever read when the pointer is
  already down), and it depends on flyctl's staged-secret mode (`fly secrets set --stage`, confirm against
  `fly secrets --help`; flyctl `v0.4.6` is on the box).

*Architect's note (superseded):* the initial advice was **Arm C** (a fresh fallback without a restart).
The Operator's observation that `Codemojex.Edge` already **polls** the pointer removed Arm C's premise —
the fallback need not track the bundle at all, because the poll is the live mechanism — so the ruling is
**Arm B** above. The record keeps Arm C's case for inspection.

### S-2…S-5 — surfaced seams

| # | Seam | Arms | Note |
|---|---|---|---|
| **S-2** | Trigger model | (a) deployable one-shot Fly **app** (`fly.toml` + `fly deploy`, machine runs to completion); (b) `fly machine run <image> --rm` on demand (no app); (c) a Fly Machines API call | The task says "fly.toml and Dockerfile" → **(a)**. (b) is lighter but has no committed config to review. |
| **S-3** | Fly token privilege | — | **Dissolved by the S-1 ruling (Arm B).** No Fly token exists in this design; the deliver machine holds only the edge-bucket keypair and never reaches the `codemojex` app. |
| **S-4** | Naming | Fly app `codemojex-edge-deliver` vs the Tigris **bucket** name (`codemojex-edge-deliver` in the setup doc; `codemojex-edge-prod` in `.env.example`) | Different namespaces, so it works, but the string collision is confusing — confirm the intended app/bucket names. |
| **S-5** | When the bundle is built | (a) at image build; (b) at **machine runtime via the script** | **Resolved → (b).** `edge-deploy.sh` owns build→upload→flip as one unit; baking the build would fork the script (do-no-harm). The image is a pure environment + cached deps; the bundle is built on each run, exactly as it is locally. |

## 6. Boundary (restated — load-bearing here)

The agent authors `Dockerfile` + `fly.toml`, wires the existing `scripts/edge-deploy.sh`, and verifies the
result with a public `curl` of `manifest.json` + the bundle. The **Operator** provisions the bucket/domain,
sets the secrets, creates the `codemojex-edge-deliver` app, and runs the deploy. This mirrors the boundary
already stated in [`edge-bucket-setup.md`](../../../../echo/docs/edge-deliver/edge-bucket-setup.md) and the
[`fly.toml`](../../../../echo/fly.toml) header ("The Operator creates the app + machines and pushes to
deploy — never `fly deploy` locally").

## 7. Map

The behavior of record: [`scripts/edge-deploy.sh`](../../../../echo/apps/codemojex/scripts/edge-deploy.sh) ·
the runtime resolver: [`Codemojex.Edge`](../../../../echo/apps/codemojex/lib/codemojex/edge.ex) · the
bucket + secrets setup: [`edge-bucket-setup.md`](../../../../echo/docs/edge-deliver/edge-bucket-setup.md) ·
the deploy-config precedent: [`echo/Dockerfile`](../../../../echo/Dockerfile) +
[`echo/fly.toml`](../../../../echo/fly.toml) · the design rationale for the edge split:
[`codemoji.static-edge.md`](../../codemoji.static-edge.md) · the parent program:
[`codemojex-tma.roadmap.md`](../../codemojex-tma.roadmap.md) · the method:
[`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) · sibling KB:
[`figma-livesync`](../figma-livesync/index.md).
