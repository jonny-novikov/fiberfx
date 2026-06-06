# Dockerfile for the Node.js BullMQ producer container used by the
# compat_docker-tagged Go integration test.
#
# Pinned to node:20-alpine + bullmq ^5.62.0 (matches BullMQ protocol pin
# at dev/mcp/features/FTR-009-echomq-go-parity/spec.yaml meta.protocol_pin).

FROM node:20-alpine

WORKDIR /app

# Copy package manifest first for Docker-layer caching of npm install.
COPY package.json ./

# Skip lockfile to keep the fixture portable; bullmq ^5.62.0 resolves
# deterministically from package.json range. Matches v5.62.0 pinned
# version; ioredis is bullmq's transport.
RUN npm install --omit=dev --no-audit --no-fund

COPY producer.js ./

CMD ["node", "producer.js"]
