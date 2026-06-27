# Codemojex · Edge Bucket Setup (`edge.codemoji.games`)

How to stand up the **dedicated Tigris bucket** that serves the hot-swappable React game at
`edge.codemoji.games`, wire the env, and run the first deploy with
[`scripts/edge-deploy.sh`](../../apps/codemojex/scripts/edge-deploy.sh). This bucket is **separate** from
the `static.codemoji.games` bucket that serves the Tier-1 welcome — see
[livereact-hot-swap.md](livereact-hot-swap.md) for why the game lives at the edge.

> **TL;DR.** Create a **public** Tigris bucket → set `TIGRIS_EDGE_*` in `echo/.env` (for the deploy
> script) → point `edge.codemoji.games` at it (custom domain + CNAME) → `source echo/.env && bash
> apps/codemojex/scripts/edge-deploy.sh` → set `GAME_ASSET_URL` as the fly fallback. `Codemojex.Edge`
> then resolves `https://edge.codemoji.games/manifest.json` at runtime (cached 10s) and the game
> hot-swaps on every deploy.

> **Boundary — you run this, not the agent.** Creating a bucket and a custom domain is **infra
> provisioning on your Fly/Tigris account**, and a deploy **publishes bytes to a live origin**. Per the
> standing rule, those steps are the Operator's to run; this doc gives the exact commands. The agent
> authors the script + docs and can verify afterward (a public `curl`), but does not provision or deploy.

---

## 1. Why a dedicated bucket

| Bucket | Serves | Cache | Changes |
|---|---|---|---|
| `static.codemoji.games` (existing) | the Tier-1 welcome (`welcome/`, logo, css) | long | rarely |
| **`edge.codemoji.games` (new)** | the **Tier-3 React game** — `game-<hash>.js` + `manifest.json` | hashed files immutable; pointer short | **often** (every game iteration) |

Splitting them keeps the fast-moving, frequently-promoted game on its own origin with its own
keypair (least privilege) and its own cache policy, without touching the welcome bucket.

## 2. Step 1 — create the bucket (public)

The game + its pointer must be **publicly readable** (the browser `import()`s them, and
`Codemojex.Edge` GETs the pointer with no auth). With `flyctl`:

```bash
fly storage create --name codemojex-edge-deliver --public
# (exact flags vary by flyctl version — `fly storage create --help`; choose your org when prompted)
```

This provisions a Tigris bucket and prints a **keypair** (an access key id + secret) and the S3
**endpoint**. Capture all three — they go into `echo/.env` in Step 2. The S3 endpoint is the same
Tigris endpoint as your existing bucket (your current `AWS_ENDPOINT_URL_S3`).

> If your org policy makes buckets private by default, either pass `--public`, or keep it private and
> add `--acl public-read` to the `aws s3 cp` calls in `edge-deploy.sh`. A public bucket is simpler and
> is what the script assumes.

## 3. Step 2 — the env vars

There are **two homes**, because the read side (the app) and the write side (the deploy) have different
needs:

### a. `echo/.env` — for running `edge-deploy.sh` (local / CI; the write side)

```bash
# Tigris EDGE bucket (the hot-swap React game)
TIGRIS_EDGE_BUCKET=codemojex-edge-deliver
TIGRIS_EDGE_ENDPOINT_URL=https://fly.storage.tigris.dev   # = your AWS_ENDPOINT_URL_S3
TIGRIS_EDGE_ACCESS_KEY_ID=tid_xxx                          # from `fly storage create`
TIGRIS_EDGE_SECRET_ACCESS_KEY=tsec_xxx                     # from `fly storage create`
TIGRIS_EDGE_REGION=auto
GAME_EDGE_HOST=edge.codemoji.games
```

The script maps `TIGRIS_EDGE_*` onto `AWS_*` **for its own process only**, so it never clobbers the
account-level `AWS_*` creds used elsewhere. (`echo/.env` is gitignored — never commit it. The template
is [`echo/.env.example`](../../.env.example).)

### b. fly secrets — for the running app (the read side)

`Codemojex.Edge` does a **public GET** of the pointer, so it needs **no Tigris creds** — only the host
(and an optional fallback):

```bash
fly secrets set GAME_EDGE_HOST=edge.codemoji.games        # optional — the code defaults to it
# after the first deploy (Step 4), pin a per-deploy fallback in case the pointer is briefly unreachable:
fly secrets set GAME_ASSET_URL=https://edge.codemoji.games/game-<hash>.js
```

## 4. Step 3 — the custom domain `edge.codemoji.games`

1. In the **Tigris dashboard** (`fly storage dashboard`, or the Tigris console), add the custom domain
   `edge.codemoji.games` to the `codemojex-edge-deliver` bucket. Tigris provisions TLS and gives you a
   **CNAME target**.
2. At your DNS provider for `codemoji.games`, add:
   ```
   edge   CNAME   <the-tigris-cname-target>
   ```
3. Wait for propagation + the TLS cert, then confirm:
   ```bash
   curl -fsSI https://edge.codemoji.games/   # 200/403 (bucket reachable over the custom domain + TLS)
   ```

`Codemojex.Edge` and `edge-deploy.sh` both use `GAME_EDGE_HOST` (default `edge.codemoji.games`), so
they agree on the host with no further wiring.

## 5. Step 4 — the first deploy

```bash
cd /Users/jonny/dev/jonnify/echo
set -a && source .env && set +a            # the script does NOT auto-load .env
bash apps/codemojex/scripts/edge-deploy.sh --dry-run   # build + show what would upload/flip
bash apps/codemojex/scripts/edge-deploy.sh             # build → upload immutable → flip pointer → verify
```

The script (full contract in its header and in [livereact-hot-swap.md §6](livereact-hot-swap.md)):

1. `npm ci && npm run build` → `priv/static/game/game-<hash>.js` (+ vite manifest).
2. uploads every `game-*` file with `Cache-Control: public,max-age=31536000,immutable`.
3. **then** writes `manifest.json` = `{"game":"https://edge.codemoji.games/game-<hash>.js"}` with a
   short cache.
4. verifies the pointer + bundle over HTTPS and prints the `GAME_ASSET_URL` to pin (Step 3b).

Within ~10s (the `Codemojex.Edge` cache TTL) the next game mount imports the new bundle — **no
`fly deploy`, no socket drop**.

## 6. Rollback

Old hashes are immutable and never deleted, so rollback is a pointer flip — no rebuild:

```bash
set -a && source .env && set +a
bash apps/codemojex/scripts/edge-deploy.sh --rollback game-<previous-hash>.js
```

(List previous hashes with `aws s3 ls s3://$TIGRIS_EDGE_BUCKET/ --endpoint-url $TIGRIS_EDGE_ENDPOINT_URL`.)

## 7. How it fits `Codemojex.Edge`

[`lib/codemojex/edge.ex`](../../apps/codemojex/lib/codemojex/edge.ex) resolves the game URL on the
render path:

- **Pointer:** `https://${GAME_EDGE_HOST}/manifest.json` (default host `edge.codemoji.games`),
  expecting `%{"game" => url}` — exactly what the script writes.
- **Cache:** `:persistent_term`, 10s TTL — a pointer flip is visible within ~10s.
- **Fallback:** if the pointer is unreachable, `GAME_ASSET_URL` (Step 3b). If both are empty,
  `game_url/0` returns `nil` and the game simply does not mount (the shell still renders).

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `edge-deploy.sh: set TIGRIS_EDGE_BUCKET …` | env not sourced | `set -a && source echo/.env && set +a` first |
| `curl https://edge.codemoji.games/manifest.json` → 403 | bucket/objects not public | create the bucket `--public`, or upload with `--acl public-read` |
| domain doesn't resolve / TLS error | CNAME or cert not ready | re-check the Tigris custom-domain target + DNS; wait for propagation |
| game still old after deploy | within the 10s pointer cache | wait ~10s; confirm `manifest.json` names the new hash |
| `aws: command not found` | AWS CLI missing | `brew install awscli` |
| app loads no game, pointer is fine | `GAME_EDGE_HOST` mismatch | ensure the app's `GAME_EDGE_HOST` matches the deployed host |

## 9. Map

[livereact-hot-swap.md](livereact-hot-swap.md) · [render-stack.md](render-stack.md) ·
[dev-and-testing.md](dev-and-testing.md) · the script:
[`apps/codemojex/scripts/edge-deploy.sh`](../../apps/codemojex/scripts/edge-deploy.sh) · the resolver:
[`apps/codemojex/lib/codemojex/edge.ex`](../../apps/codemojex/lib/codemojex/edge.ex) · env template:
[`echo/.env.example`](../../.env.example).
