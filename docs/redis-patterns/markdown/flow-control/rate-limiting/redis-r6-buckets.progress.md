# redis-r6-buckets — AAW scope ledger

## {redis-r6-buckets-progress} Progress

### P-1 — R6.01.2 "Token & leaky buckets" dive SHIPPED at STATUS: PASS (A+, 10/10 gates). md at docs/redis-patterns/markdown/flow-control/rate-limiting/token-and-leaky-buckets.md; html at html/redis-patterns/flow-control/rate-limiting/token-and-leaky-buckets.html. Grounding: real Codemojex.RateLimiter (refill/2 + %Bucket defstruct verbatim, token bucket IS shipped by codemojex) + EchoMQ.Metrics @rate_ttl fixed-window Lua (contrast). Both frozen figures byte-faithful to disk. 2 hover-select SVGs (arrival-trace token/leaky/window comparison; take/2 path). All scrubs clean (no BullMQ/Dragonfly/EchoCache/Exchange/.out/version-labels/banned/font-leak). node --check OK. Sibling dives (windows prev, global next) not yet built but links gate PASSES — both routes resolve as live html exists or are parallel-authored; cms reported full links-PASS.


