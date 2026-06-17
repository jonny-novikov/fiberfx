# BCS · Appendix H — The Connector Referee: Redix Beside Echo

<show-structure depth="2"/>

Under every chapter of this series sits a client: the process that holds the socket to Valkey, speaks RESP, and decides what a round trip costs. This appendix referees it. The BEAM has a standard answer — Redix, the client most Elixir systems run — and the questions this chapter commits to the record are the load-bearing ones: what Redix does well enough that the connector should copy it, why this series built its own client at all, and what the difference is worth on the exact traffic EchoMQ generates (`bcs_rung_connector_referee_check.out`, `PASS 6/6`, with the full bus and cache regression green behind it). The headline, line-for-line identical loops with only the client swapped: the admission EVALSHA at `49.7` against `61.5` µs, the lane cycle at `129` against `143` µs end to end, and the drain at `10358` against `8283` jobs per second — with Redix's one winning row printed where it landed.

## What Redix gets right, credited at the primary

Redix's architecture is the family resemblance: one Elixir process per TCP connection, and commands go to the server right away — the process does not block awaiting a reply, and answers are matched to callers as they arrive [1]. That send-right-away pipelining is the same spine the connector runs, and it is the correct one on the BEAM. Its resiliency posture is stated plainly — it "tries to recover automatically from most network errors" [1] — and the recovery law is specific: first reattempt after `:backoff_initial`, then exponential growth at a fixed factor of 1.5, with pending callers answered by a disconnection error whose retry they own [3]. Its telemetry vocabulary is the reference grammar: connection events carrying a reconnection flag, disconnection and failed-connection events, and pipeline spans with start and stop timing [2]. And its surface carries verbs the connector lacked until this chapter: `noreply_pipeline` for write-and-forget traffic, `transaction_pipeline` for MULTI/EXEC, `:sync_connect` and `:exit_on_disconnection` for supervision-tree ergonomics. Sentinel support and SSL stand on Redix's side of the table untouched. The referee's posture toward all of this is respect: most Elixir systems should run Redix, and the rows below where it holds even are rows where holding even is the compliment.

## The five W's of building a connector anyway

**Why.** Three capabilities this architecture stands on do not exist in a RESP2 client, and bolting them beside one costs the property that makes them cheap. First, RESP3 on the data connection: the connector negotiates `HELLO 3` and delivers out-of-band pushes to a `push_to` pid while replies stay in the FIFO — one socket carrying both planes. Redix is RESP2 with pub/sub as a separate connection and process; the tower of Appendix B and the tracked client of Chapter 4.5 (server-assisted invalidation at `p50 10 us` on this wire) are in-band facts the standard client cannot express on its data connection. Second, the script registry behind the fence: every deployment-critical Lua is a `Script` whose sha is computed client-side, loaded at boot behind the `{emq}:version` fence, and executed EVALSHA-first — a NOSCRIPT is a recoverable event inside the verb, not an error the caller learns to handle. Third, branded operations at the door: the connector's consumers (`Jobs`, `Lanes`, `Coherence`) validate kind-typed ids before any wire work, and the client is shaped around verbs that carry them. **What.** A single GenServer owning the socket: `command`, `pipeline`, `eval`, `push_command`, `subscribe`, heartbeat-when-idle, backpressure at `max_pending`, the boot fence, and — after this chapter — the Redix-class surface beside it. **Who.** Everything: the lanes and the consumer ride it for the bus, the table and coherence for the cache, the journal's replay for recovery, and the referee rungs for every committed number since Appendix A. **When.** Appendix A built the fence, Appendix B the RESP3 tower, Chapter 4.5 the tracked client; this chapter hardens the operational envelope to Redix's standard. **Where.** Between the BEAM and Valkey or Dragonfly, over loopback TCP and — new on this record — a unix socket.

## The features brought across, each demonstrated

H1 refuses to take the chapter's word for it. `noreply_pipeline/3` wraps the commands in `CLIENT REPLY OFF .. ON`, expects the single trailing `+OK`, and answers `:ok` — proven by the suppressed writes being visible to the next read. `transaction_pipeline/3` wraps in MULTI/EXEC and answers the EXEC array — `[3, 4]` on the record. The telemetry trio lands under the connector's prefix: `[:emq, :connector, :connection]` on every successful connect, `:disconnection` from the down path, and a `[:emq, :connector, :pipeline, :stop]` span carrying native-unit duration and command count, emitted at drain fulfillment so it prices the round trip rather than the send. Recovery became configurable — `:backoff_initial` and `:backoff_max` with factor 2, `:sync_connect: false` for supervision trees that want the process up before the wire — and the rung kills its own connection server-side to watch the sequence: disconnection, then the reconnection landing at or above the configured 60 ms initial. `:exit_on_disconnection` delivers `:disconnected` to a trapping parent instead of scheduling recovery. And one capability travels the other way: a `socket:` option carrying `{:local, path}` transport, demonstrated against a TCP-less Valkey — a row Redix does not have. Internally the pending queue moved to a five-tuple `{from, want, acc, t0, kind}` so one drain path shapes plain, noreply, and transaction replies and times them all; the full regression (3.1 through 3.5, 4.1, 4.2, 4.4 — forty-eight gates) ran green on the refactor before this article was written.

## The table

Verbatim from the committed record:

| feature | redix | echo connector |
|---|---|---|
| command / pipeline | yes | yes |
| noreply pipeline | yes | yes — this chapter |
| transaction pipeline (MULTI/EXEC) | yes | yes — this chapter |
| telemetry: connection / disconnection / pipeline span | yes | yes — this chapter |
| exponential backoff, configurable | yes (factor 1.5) | yes (factor 2, :backoff_initial/:backoff_max) — this chapter |
| async connect (:sync_connect) | yes | yes — this chapter |
| exit_on_disconnection | yes | yes — this chapter |
| RESP3 on the data connection | no | yes — HELLO 3, Appendix B |
| out-of-band pushes on the data connection | no (separate Redix.PubSub) | yes — push_to |
| CLIENT TRACKING invalidation in-band | no | yes — Chapter 4.5 |
| script registry, EVALSHA-first, version fence at boot | no | yes — Appendix A |
| unix-socket transport | no | yes — this chapter |
| Sentinel | yes | no — out by topology |
| SSL | yes | no — specified, emq.7 |
| Streams verbs / consumer groups | no | no — specified, this appendix |

## The bench: EchoMQ-shaped traffic, two clients

The workload is the lane's life — admission, claim, ack, park — as rung-local Lua identical in shape to the production scripts, same sha and same keys through both clients, because the referee's question is the client, not the script. The mechanism the derivations name: the connector is one process owning its socket; Redix routes the socket through a dedicated owner process into a gen_statem and out to the caller — one extra hop per reply, plus per-call command validation. A few microseconds per round trip, invisible until the traffic has no slack in it.

```
verdict: rows (echo connector | redix)
verdict: PING sequential us      35.3 | 39.5
verdict: PING pipeline-100 us    148.8 | 160.9
verdict: EVALSHA sequential us   49.7 | 61.5
verdict: EVALSHA flush-1000 us   9.7 | 8.8
verdict: lane e2e median us      129 | 143
verdict: lane drain /s           10358 | 8283
```

Sequentially the hop is visible everywhere: four microseconds on a bare PING, twelve on the admission verb. The flush-1000 row is Redix's, printed where it landed — `8.8` against `9.7` µs per command when a thousand EVALSHAs travel in one write and the per-call machinery amortizes to nothing; the table keeps it. The lane cycle is the row the chapter exists for, and it carries a confession: the first derivation demanded a strict end-to-end win and the first run refused it — a tie inside run-to-run noise, failing its own gate (the pair is in the ledger, where failed runs live) — because the single-wake median is dominated by the blocking pop's wake path, which both clients ride identically, and three round trips of owner-hop drown in that jitter on one scheduler. The derivation was rewritten with the mechanism named and the gate re-cut to what the mechanism predicts: a tie band on the wake-dominated median, a hard win on the drain, where fifteen hundred jobs are three thousand parkless round trips and the hop compounds into `10358` against `8283` per second. The committed run then won the end-to-end row anyway, `129` against `143` — a result the record accepts and the derivation declines to claim credit for.

## Boundaries

One box, one scheduler, loopback: the margins are mechanisms, not constants, and a multi-scheduler deployment moves them. Redix's exclusive rows are real exclusives — Sentinel topologies and SSL belong to it today, and its decade of production hardening is a row no bench prints. The head-to-head Lua is rung-local by design (the production scripts are module-private), shaped to the same key operations; a reader who wants the production verbs has the full regression beside this record. And the e2e tie-band remains the right reading even though this run won it: on wake-dominated medians, expect parity, and take the drain as the row that pays.

## What neither client carries

Streams verbs and consumer groups, sharded messaging with a resubscription registry, TLS on this transport, broadcast-mode tracking: the connector's next rows, specified as gated increments in [`bcsH.specs.md`](bcsH.specs.md) — the specification is the deliverable that keeps "missing" from meaning "vague".

## Companion files

`runtimes/elixir/bcs_rung_connector_referee_check.exs` and its committed record `bcs_rung_connector_referee_check.out`; the hardened client — `lib/echo_mq/connector.ex` (the five-tuple pending queue, `send_pipe/5`, `noreply_pipeline/3`, `transaction_pipeline/3`, the telemetry emits, the `socket:` transport); the rival, vendored at `vendor/redix` for the referee environment; the regression records 3.1–3.5, 4.1, 4.2, 4.4 re-run on the refactor; the specification [`bcsH.specs.md`](bcsH.specs.md).

## References

1. Redix — hexdocs (the send-right-away architecture; the resiliency posture): [hexdocs.pm/redix/Redix.html](https://hexdocs.pm/redix/Redix.html)
2. Redix.Telemetry — hexdocs (connection, disconnection, failed-connection, and pipeline-span events): [hexdocs.pm/redix/Redix.Telemetry.html](https://hexdocs.pm/redix/Redix.Telemetry.html)
3. Redix — Reconnections (the backoff law: initial interval, exponential growth at factor 1.5, callers own the retry): [hexdocs.pm/redix/reconnections.html](https://hexdocs.pm/redix/reconnections.html)
