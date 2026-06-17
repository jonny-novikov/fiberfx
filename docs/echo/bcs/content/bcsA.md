# BCS · Appendix A — The connector: EchoMQ 2.0 on Valkey

<show-structure depth="2"/>

Decision D-1 ([`bcs.progress.md`](bcs.progress.md)) says Valkey backs EchoMQ 2.0 through a custom optimized Elixir connector; this appendix is that sentence made flesh. The connector is authored here as the reference implementation for adoption into the umbrella — the production-drop pattern with the roles reversed, Author producing the drop the Operator integrates — and it is documented the series' way: source committed, behavior gated, every figure verbatim from the committed output. Four modules, four hundred fifty lines, zero dependencies beyond the identity canon, and a gate record that ends `PASS 8/8`.

## Scope and method

Built and proven in this repository against the same Valkey 9.1.0 the storage chapter measured [2], listening on `:6390`. The gate script (`runtimes/elixir/emq_connector_check.exs`) exercises the connector end to end — boot fence positive and negative, binary safety, slot locality, the script path, pipeline ordering, throughput, supervised restart, and the prefix budget — and its output is committed as `emq_connector_check.out`. Localhost numbers, one engine, one box: the figures are for shape and ratio, not for capacity planning.

## The design

**RESP2, one pass, iodata out.** Commands encode as arrays of bulk strings into iodata with no intermediate concatenation — the protocol's request form exactly [1] — and replies parse in a single pass over the accumulated buffer, with `:incomplete` as the continuation signal and server errors surfaced as values (`{:error_reply, msg}`) rather than crashes, so the connector decides severity.

**Pipelining is the primitive.** `pipeline/3` writes N commands in one send and pairs the caller with a pending-FIFO entry `{from, want, acc}`; replies route in arrival order off an `active: :once` socket, partial pipelines re-queue at the head, and `command/3` is a pipeline of one, unwrapped. Ordering is load-bearing and gated, not assumed.

**Scripts obey the declared-keys law.** `eval/5` takes an `EchoMQ.Script` (SHA1 precomputed at construction) and runs EVALSHA-first; on `NOSCRIPT` it loads the source once, asserts the returned SHA matches the precomputed one, and retries. Every key a script touches rides in `KEYS` — the v2 law — and the gate proves the load happens exactly once per cache lifetime.

**The fence is typed and fatal.** On every connect — first boot and every reconnect — the connector reads `{emq}:version`, claims it with `SET NX` when absent, verifies the read-back, and refuses to start on any other value: `start_link` returns `{:error, {:version_fence, got}}` and a reconnect that meets a changed fence stops the process for the supervisor to see. A connector that would talk v2 at a non-v2 keyspace is a bug the fence converts into a loud boot failure.

**The keyspace composes with the canon.** `queue_key/2` produces `emq:{q}:<type>` with the hashtag applied transparently; `job_key/2` refuses any payload `EchoData.BrandedId.valid?/1` rejects; `reserve/1` guards the `{emq}:` base; and `slot/1` computes the cluster slot client-side — CRC16-XMODEM over the hashtag, modulo 16384, the cluster specification's algorithm with its known vector asserted — so routing and partitioning decisions need no server round trip.

**Counted, not guessed.** Eight lock-free `:counters` slots (commands, pipelines, replies, reconnects, script loads, EVALSHA calls, bytes out, wire errors) back `stats/1`; reconnect uses capped, jittered backoff and fails pending callers with `{:error, :disconnected}` rather than leaving them hanging.

## The source

| Module | Path | Surface |
| --- | --- | --- |
| `EchoMQ.RESP` | `runtimes/elixir/lib/echo_mq/resp.ex` | `encode/1`, `parse/1` |
| `EchoMQ.Script` | `runtimes/elixir/lib/echo_mq/script.ex` | `new/2` (SHA1 at construction) |
| `EchoMQ.Keyspace` | `runtimes/elixir/lib/echo_mq/keyspace.ex` | `queue_key/2`, `job_key/2`, `reserve/1`, `version_key/0`, `prefix_bytes/2`, `slot/1`, `hashtag/1` |
| `EchoMQ.Connector` | `runtimes/elixir/lib/echo_mq/connector.ex` | `start_link/1`, `command/3`, `pipeline/3`, `eval/5`, `stats/1`, `wire_version/0` |

The complete listings ride in the repository and beside this appendix; the table is the map, not the territory.

## Measured

The committed gate record, figure by figure. The fence claimed `echomq:2.0.0` on a fresh keyspace and refused the planted mismatch with a typed `{:version_fence` error. A six-byte binary value containing CRLF round-tripped intact, and the composed job key `emq:{orders}:job:ORD0NsVQMCRgHI` carried a freshly minted identity while the malformed one was refused at the gate. The slot law held client-side — `emq:{orders}:*` mapped to `slot 105 == 105` against `8507` for the payments queue, with the specification vector answering `12739`. The script path recorded `script_loads=1` — exactly one NOSCRIPT load — before EVALSHA served from cache. The ordering gate's `10000-command pipeline returned 1..10000 in order`. Throughput: sequential request-response INCR at `29456` ops/s; pipelined SET at `454483` ops/s — fifteen times the sequential figure on the same socket; pipelined EVALSHA at `161192` ops/s, the declared-keys law at speed. The killed connector was supervisor-restarted, re-fenced, and served. And the envelope's `prefix = 17 bytes` before the 14-byte payload — the budget INV-K2 demands stated, sitting inside the 26-byte class the storage chapter priced.

## Boundaries

RESP2, deliberately: no `HELLO` negotiation and no RESP3 push types — the v2 surface needs neither, and the upgrade is a contained follow-up. One connection per process: a pool is a supervisor of N of these, not a different module, and is carried as a follow-up rather than smuggled in. The `:incomplete` continuation re-parses from the buffer's start on each arrival — linear in frame size, which EchoMQ's frames keep small; a streaming parser earns its complexity only past that envelope. The restart gate kills the connector process, not the server; the server-loss drill belongs to the operations story (Part VII) where its blast radius can be measured properly. And the throughput rows are localhost ratios on one box.

## Companion files

The four modules above; `runtimes/elixir/emq_connector_check.exs`; the committed record `runtimes/elixir/emq_connector_check.out`; the engine recipe and keyspace economics in [`bcs1.3.md`](bcs1.3.md) and its triad.

## References

1. Valkey documentation — Serialization protocol specification (clients send commands as arrays of bulk strings; CRLF-terminated, first byte identifies the type, bulk strings binary-safe by prefixed length): [valkey.io/topics/protocol](https://valkey.io/topics/protocol/)
2. Valkey 8.1.0 GA announcement — the engine release this connector targets and the storage chapter measured: [valkey.io/blog/valkey-8-1-0-ga](https://valkey.io/blog/valkey-8-1-0-ga/)
