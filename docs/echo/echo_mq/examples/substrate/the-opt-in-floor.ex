# queue "payments" — v1 line (frozen at 1.3.0) → emq.1 ships (2.0).
# v1: EchoMQ.Keys interpolates the name verbatim under emq: (keys.ex:85-86) — flat, unplaced
  emq:payments:wait   emq:payments:active   emq:payments:meta
  emq:payments:<jobId>:lock   # EchoMQ.Keys.lock/2 — no hashtag
# emq.1 ships: emq: prefix, the {q} hashtag applied transparently by the core
  emq:{payments}:wait   emq:{payments}:active   emq:{payments}:meta
  emq:{payments}:<jobId>:lock   # one hashtag {payments} — slot-local by construction
  {emq}:version  {emq}:nodes   # the core's own keys, the reserved {emq}: base
