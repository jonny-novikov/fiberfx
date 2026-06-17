# B3.1.2 · The Fence, Live

> Dive 2 of B3.1 · route `/bcs/bus/fence-and-keyspace/the-fence-live` · teaches F3 + F4 of `content/bcs3.1.md`
> (`bcs_rung_3_1_check.out`, `PASS 5/5`).

The fence answers through itself.

F3 performs the part's second law on a running wire and lets the proof be self-referential: the read that
confirms the fence travels through a connection that could not exist had the fence not held. F4 proves the
wire's binary discipline through the queue's own keys.

## §1 The transcript

This dive reads F3 and F4 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_1_check.out`, verbatim):

```
F1 map ok -- the part's map: emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload
F2 gate ok -- the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script
F3 fence ok -- the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself
F4 binary ok -- binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines
F5 slot ok -- co-location law: pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165 -- multi-key scripts stay legal on the clustered day (vector 12739 holds)
PASS 5/5
```

## §2 F3 — the fence on a live wire

F3 performs the part's second law on a running wire and lets the proof be self-referential: `GET {emq}:version
answers echomq:2.0.0 through the fenced connector itself` — the read that confirms the fence travels through a
connection that could not exist had the fence not held.

The negative path is inherited, not re-run: the appendix's frozen record holds the typed refusal of a bogus
version and the re-fence after supervised restart, and the part's evidence policy reads records rather than
repeating them. The appendix's prose (source: `content/bcsA.md`): the fence claimed `echomq:2.0.0` on a fresh
keyspace and refused the planted mismatch with a typed `{:version_fence` error; the killed connector was
supervisor-restarted, re-fenced, and served. The connector gate ran against live Valkey 9.1.0.

## §3 F4 — binary discipline through the queue's own keys

Payloads will be serialized terms, and serialized terms carry exactly the bytes a line-oriented protocol
breaks on. F4
writes five hundred jobs whose bodies embed CRLF and NUL through real job keys and reads them back: `binary
payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines` — the
length-prefixed bulk strings of the protocol doing exactly the work they were designed for, exercised in the
very shapes this part will use.

A length-prefixed writer declares the byte count first, then ships the raw bytes; the reader takes the declared
length and reads exactly that many bytes, so a CRLF or a NUL inside the value is payload, not protocol. A
line-oriented reader cuts the same value at its first CRLF and loses the rest to framing. The protocol's bulk
strings are the first kind.

## References

Sources:

- Valkey — Protocol specification — https://valkey.io/topics/protocol/ (length-prefixed bulk strings; the
  binary safety F4 exercises)
- Valkey 8.1.0 GA announcement — https://valkey.io/blog/valkey-8-1-0-ga/ (the stable line the appendix's
  connector gate ran against — live Valkey 9.1.0)
- Valkey — Cluster specification — https://valkey.io/topics/cluster-spec/ (the slot law the next dive proves)

Related:

- /bcs/bus/fence-and-keyspace — B3.1, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/ideas — B1 · Ideas Behind, the identity canon
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/fence-and-keyspace/the-key-grammar` · next
`/bcs/bus/fence-and-keyspace/the-co-location-law`.
