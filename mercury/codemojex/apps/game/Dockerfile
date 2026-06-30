# =============================================================================
# codemojex-edge-deliver — the one-shot image that publishes the React game bundle.
#
# A PURE ENVIRONMENT, not a release: node + pnpm (build) + the AWS CLI (the script's
# `aws s3` calls) + curl (verify). It runs bin/edge-deploy.sh to completion
# (install -> build -> upload-immutable -> flip manifest.json -> verify) and exits.
#
# SELF-CONTAINED CONTEXT: the build context is this assets/ tree only — no umbrella,
# no echo/deps/, no file-dep links. The vendored Phoenix client lives under packages/
# (@echo/phoenix, @echo/phoenix_live_view) and resolves via the pnpm workspace, so
# nothing is copied from outside assets/.
#
# It NEVER touches the codemojex app. That app already re-resolves manifest.json
# on the render path (Codemojex.Edge.game_url/0, ~10s TTL), so once this job flips
# the pointer the new bundle goes live with NO app restart, NO secret write, and
# NO Fly token. The two surfaces talk ONLY through the bucket pointer.
#
# Boundary: the Operator creates the app + secrets and runs the deploy (never an agent).
# =============================================================================
FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates unzip bash \
    && rm -rf /var/lib/apt/lists/*

# pnpm via corepack (the image's package manager is pnpm, never npm).
RUN corepack enable && corepack prepare pnpm@10.17.1 --activate

# AWS CLI v2 from the edge bucket's PRE-STAGED installer. The public AWS origin
# is not reliably reachable from Fly's network; the edge bucket is the one origin
# this image already trusts. The Operator pre-stages dist/awscli-<awsarch>.zip
# (see the edge-bucket-setup doc under echo/docs/edge-deliver/).
RUN arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) awsarch=x86_64 ;; \
      arm64) awsarch=aarch64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://edge.codemoji.games/dist/awscli-${awsarch}.zip" -o /tmp/awscli.zip; \
    unzip -q /tmp/awscli.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/aws /tmp/awscli.zip

WORKDIR /app

# The whole self-contained assets/ tree: the workspace (package.json,
# pnpm-workspace.yaml, pnpm-lock.yaml), the vendored packages/, the bin/ publish
# script, the vite configs, js/, src/. Nothing outside assets/ is referenced.
# .dockerignore keeps the HOST node_modules out, so the script's
# `pnpm install --frozen-lockfile` resolves the linux-correct binaries from the lock.
COPY . .

RUN chmod +x bin/edge-deploy.sh

# A job: install -> build -> upload -> flip the pointer -> verify -> exit. The script
# (not the image) runs `pnpm install --frozen-lockfile && pnpm build`. Args pass
# straight through (e.g. `-- --dry-run`, `-- --rollback game-<hash>.js`).
ENTRYPOINT ["/app/bin/edge-deploy.sh"]
