# codemojex-edge-deliver — the ephemeral edge publisher

A one-shot Fly machine that builds the Codemoji React game bundle and publishes it to the
`edge.codemoji.games` Tigris bucket. It replaces "run `edge-deploy.sh` on the Operator's
laptop" with "run a machine in `fra` beside the bucket".

It talks to the live `codemojex` app **only through the bucket pointer**: the app's
`Codemojex.Edge.game_url/0` re-resolves `https://edge.codemoji.games/manifest.json` on the render path
(cached ~10s), so once this job flips the pointer the new bundle goes live within ~10s with **no app
restart, no secret write, and no Fly token**.

- **What it runs:** the canonical [`edge-deploy.sh`](../../../mercury/codemojex/apps/game/bin/edge-deploy.sh) — build →
  upload immutable → flip `manifest.json` → verify. Nothing else.
- **Design + the ruled decisions:**
  [`docs/codemojex-tma/kb/codemojex-edge-deploy/index.md`](../../../docs/codemojex-tma/kb/codemojex-edge-deploy/index.md).
- **Bucket + domain provisioning:**
  [`echo/docs/codemojex/edge-bucket-setup.md`](edge-bucket-setup.md).

> **Boundary — you (the Operator) run this, not the agent.** A deploy publishes bytes to a live origin
> and creates infra. The agent authored these files; the steps below are yours.

## One-time setup

```bash
# 1. Create the task app (no services; same Tigris bucket as edge-bucket-setup.md).
fly apps create codemojex-edge-deliver

# 2. Write-side secrets only — the EDGE bucket keypair (least privilege; from `fly storage create`).
#    No Fly token: the codemojex app picks up new bundles by polling the pointer.
fly secrets set -a codemojex-edge-deliver \
  TIGRIS_EDGE_BUCKET=codemojex-edge-prod \
  TIGRIS_EDGE_ENDPOINT_URL=https://fly.storage.tigris.dev \
  TIGRIS_EDGE_ACCESS_KEY_ID=tid_xxx \
  TIGRIS_EDGE_SECRET_ACCESS_KEY=tsec_xxx \
  TIGRIS_EDGE_REGION=auto
```

> The optional `GAME_ASSET_URL` fallback on the `codemojex` app (a coarse "last known good" for when the
> pointer is briefly unreachable) is a **one-time, setup-time** pin — see
> [`edge-bucket-setup.md` §3b](edge-bucket-setup.md). It is **not** this job's
> concern and is not updated per publish.

## Publish (every game iteration)

Two steps: build + push the image from the umbrella root (so `assets/package.json`'s
`file:../../../deps/phoenix*` resolve at `npm ci`), then run it once as a throwaway machine. The run
reads its `TIGRIS_EDGE_*` from the app secrets above and defaults `GAME_EDGE_HOST` in code.

```bash
cd /Users/jonny/dev/jonnify/echo

# 1. Build + push to registry.fly.io (no machine started). Note the printed image ref.
fly deploy --build-only --push \
  -c apps/codemojex/edge-deliver/fly.toml \
  --dockerfile apps/codemojex/edge-deliver/Dockerfile

# 2. Run it once on a throwaway machine in fra; --rm destroys it on exit.
fly machine run <printed-image-ref> -a codemojex-edge-deliver --region fra --rm
```

Pass script args through after a `--` terminator (exact behavior varies by flyctl version —
`fly machine run --help`):

```bash
fly machine run <image-ref> -a codemojex-edge-deliver --region fra --rm -- --dry-run
#   …  -- --rollback game-<hash>.js     # re-point only; the app then polls it up
```

## Verify (the agent may do this part — it is a public read)

```bash
curl -fsS  https://edge.codemoji.games/manifest.json ; echo            # names the new game-<hash>.js
curl -fsSI https://edge.codemoji.games/game-<hash>.js | head -1        # 200
```

Within ~10s the next game mount re-resolves the pointer and imports the new bundle — no `codemojex`
deploy, no socket drop.
