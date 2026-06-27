# EVALSHA and NOSCRIPT

> Route: `/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript` · Dive R3.04.3.
> Grounding: `EchoMQ.Script.new/2` precomputes the SHA1 (`echo/apps/echo_wire/lib/echo_mq/script.ex`);
> `EchoMQ.Connector.eval/5` (`echo/apps/echo_wire/lib/echo_mq/connector.ex`) tries `EVALSHA` first and, on a
> `NOSCRIPT` reply, runs `SCRIPT LOAD` and re-runs the same `EVALSHA` — one load per script per connection.
> Engine: Valkey.

The transition script runs by its SHA, not by its body. `EchoMQ.Script.new/2` precomputes the SHA; the
connector calls `EVALSHA`; a flushed cache returns `NOSCRIPT`, and the connector runs `SCRIPT LOAD` once and
re-runs the `EVALSHA`.

## Load once, call by SHA

A Lua script can be sent on every call with `EVAL script numkeys …`, but that puts the whole body on the wire
each time. Valkey offers a cheaper path. `EchoMQ.Script.new(name, lua)` precomputes the SHA-1 of the body at
compile time:

```
def new(name, source) when is_atom(name) and is_binary(source) do
  sha = :crypto.hash(:sha, source) |> Base.encode16(case: :lower)
  %__MODULE__{name: name, source: source, sha: sha}
end
```

So the connector already holds the SHA before it ever talks to the server. It calls `EVALSHA sha numkeys …` —
the forty-character digest stands in for the body, and Valkey runs the cached script. The transition is
identical; only the bytes on the wire change.

## The NOSCRIPT fallback

The server's script cache is not permanent. A restart clears it; `SCRIPT FLUSH` clears it. After that, an
`EVALSHA` for a SHA the server no longer holds returns a `NOSCRIPT` error — the SHA is unknown, the body is
needed. `EchoMQ.Connector.eval/5` handles this without giving up the transition: on the `NOSCRIPT` reply it
runs `SCRIPT LOAD` with the body once and re-runs the same `EVALSHA`:

```
# EchoMQ.Connector.eval/5 (connector.ex), trimmed — EVALSHA-first, load once on NOSCRIPT
parts = ["EVALSHA", s.sha, Integer.to_string(length(keys))] ++ keys ++ argv

case command(conn, parts, timeout) do
  {:ok, {:error_reply, "NOSCRIPT" <> _}} ->
    case command(conn, ["SCRIPT", "LOAD", s.source], timeout) do
      {:ok, sha} when sha == s.sha -> command(conn, parts, timeout)   # re-run the same EVALSHA
      {:ok, other} -> {:error, {:sha_mismatch, other}}
    end
  ...
end
```

The load returns a SHA that must equal the precomputed `s.sha` — a mismatch is refused as `:sha_mismatch`,
proof the loaded body is the one the connector expected. The transition succeeds either way; the only cost of a
flushed cache is one load-and-retry round trip, taken once per script per connection.

## The wire cost

The contrast is concrete. `EVAL` every time sends the whole body on every call: N transitions cost N script
bodies on the wire. `EVALSHA` after one load sends the body once and a SHA thereafter: N transitions cost one
body plus N short SHAs. For the lifecycle scripts under a busy worker pool, that is the difference between
re-sending the protocol on every move and sending a digest. The fallback re-sends the body only when the cache
is actually gone — once per flush, not once per call.

## The pattern, applied

The atomic-updates pattern runs the read-modify-write as one server-side script; `EVALSHA` is how that script
reaches the server cheaply. In EchoMQ `EchoMQ.Script.new/2` precomputes the SHA and `EchoMQ.Connector.eval/5`
calls `EVALSHA` first, falling back to `SCRIPT LOAD` + a re-run `EVALSHA` on `NOSCRIPT` — so the transition is
both cheap on the wire and resilient to a flushed cache.

A door, not a depth: the full script registry behind the version fence, and how the SHAs are managed across the
worker pool, are the dedicated EchoMQ course's Queue pillar.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA; the `NOSCRIPT` error
  when the SHA is unknown.
- [Redis — SCRIPT LOAD](https://redis.io/commands/script-load/) — cache the body once and get back the SHA the
  client calls by.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — the full-body call that backs the load step.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — the cached-script call and the `NOSCRIPT` reply on
  the engine the connector is gated against.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module hub.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the prior dive: the transition this dive runs by SHA.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — the
  locations the transition travels between.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the reaper whose script also runs by
  SHA.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write
  pattern.
- [EchoMQ · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the script dispatch and SHA cache.
