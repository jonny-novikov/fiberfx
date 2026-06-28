# =============================================================================
# codemojex-edge-deliver — the one-shot image that publishes the React game bundle.
#
# A PURE ENVIRONMENT, not a release: node (build) + the AWS CLI (the script's
# `aws s3` calls) + curl (verify). It runs edge-deploy.sh to completion
# (build -> upload-immutable -> flip manifest.json -> verify) and exits.
#
# It NEVER touches the codemojex app. That app already re-resolves manifest.json
# on the render path (Codemojex.Edge.game_url/0, ~10s TTL), so once this job flips
# the pointer the new bundle goes live with NO app restart, NO secret write, and
# NO Fly token. The two surfaces talk ONLY through the bucket pointer.
#
# Boundary: Auto deploy triggering Deploy in Fly dashboard
# =============================================================================
FROM node:22-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates unzip bash \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2 (arch-aware: Fly builders may be amd64 or arm64).
RUN arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) awsarch=x86_64 ;; \
      arm64) awsarch=aarch64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${awsarch}.zip" -o /tmp/awscli.zip; \
    unzip -q /tmp/awscli.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/aws /tmp/awscli.zip

WORKDIR /app

# Replicate the umbrella layout so assets/package.json's file:../../../deps/* resolve
# at `npm ci` time. Only the three declared phoenix file-deps are needed (the game
# bundle imports none of them, but `npm ci` validates every dependency).
COPY deps/phoenix            deps/phoenix
COPY deps/phoenix_html       deps/phoenix_html
COPY deps/phoenix_live_view  deps/phoenix_live_view

# The build inputs + the canonical publish script (the single source of truth).
COPY apps/codemojex/assets   apps/codemojex/assets
COPY apps/codemojex/scripts  apps/codemojex/scripts

RUN chmod +x apps/codemojex/scripts/edge-deploy.sh

# A job: build -> upload -> flip the pointer -> verify -> exit. Args pass straight
# through (e.g. `-- --dry-run`, `-- --rollback game-<hash>.js`).
ENTRYPOINT ["/app/apps/codemojex/scripts/edge-deploy.sh"]
