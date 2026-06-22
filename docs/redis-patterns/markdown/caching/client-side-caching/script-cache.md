# The SHA1 script-cache parallel

> Route: `/redis-patterns/caching/client-side-caching/script-cache` · Module R1.04 · dive 3 · Source:
> `content/fundamental/client-side-caching.md.txt` (the cache-then-invalidate shape) · Grounding: EchoMQ's real
> `EchoMQ.Script.new/2` (a script with its SHA1 precomputed, EVALSHA-first with a load-on-NOSCRIPT fallback,
> `echo/apps/echo_wire/lib/echo_mq/script.ex:13`) and the worked example `@drop = Script.new(:coherence_drop, …)`
> (`echo/apps/echo_cache/lib/echo_cache/coherence.ex:54`) — shown as a **parallel**, not a door into the queue
> protocol.

Run a Lua script by its hash, not its source — and on a cache-miss reply, send the source once. The same
cache-then-invalidate shape as a near cache, in real EchoMQ code. A near cache holds a value to skip a read; a script
cache holds a script's SHA1 to skip resending its body.

## Run by hash, resend on miss

Loading a script with `SCRIPT LOAD` registers its body in the server's script cache and returns its SHA1. From then on
a client runs it with `EVALSHA` — sending the 40-character hex hash, not the script text. The body travels the wire
once; every later run is a hash. The hit case is a pure win: less data sent, no parse.

The miss case is the half that makes the parallel exact. If the server has dropped the script — a restart, a
`SCRIPT FLUSH`, an unseen replica — `EVALSHA` returns a `NOSCRIPT` error. That error is the invalidation: the client's
assumption that the server holds the script is wrong, so the client falls back to `EVAL`, sending the full source,
which re-registers the hash. One miss, one resend, then hits again. A near cache drops a value on a broadcast push; a
script cache resends a body on a `NOSCRIPT`. The signal differs; the shape is the same.

- **EVALSHA** — run a server-cached script by its SHA1 hash; the body is not sent.
- **NOSCRIPT** — the reply when the server does not hold that hash; the cache-miss signal.
- **EVAL** — the fallback: send the full source, run it, and re-register the hash for next time.
- **SHA1** — the content hash that names a script; the cache key on both sides.

## In EchoMQ's Script

EchoMQ runs its state transitions as Lua, so the same scripts run constantly — which is exactly the case the SHA1
cache is for. The real type is `EchoMQ.Script` in `echo/apps/echo_wire/lib/echo_mq/script.ex`. It is a tiny struct that
**precomputes the SHA1 at definition time** — the cache key is derived once, not on every call — so the connector can
run EVALSHA-first with a load-on-`NOSCRIPT` fallback:

```elixir
# echo/apps/echo_wire/lib/echo_mq/script.ex — the SHA1 cached client-side
defmodule EchoMQ.Script do
  @moduledoc """
  A server-side script with its SHA1 precomputed, so the connector can run
  EVALSHA-first with a load-on-NOSCRIPT fallback. ...
  """
  defstruct [:name, :source, :sha]

  def new(name, source) when is_atom(name) and is_binary(source) do
    sha = :crypto.hash(:sha, source) |> Base.encode16(case: :lower)
    %__MODULE__{name: name, source: source, sha: sha}
  end
end
```

The worked example sits in EchoCache itself: the version-safe L2 drop is a module attribute, defined once with its SHA1
already computed, then dispatched by hash:

```elixir
# echo/apps/echo_cache/lib/echo_cache/coherence.ex — the cache key minted once
@drop Script.new(:coherence_drop, """
      local cur = redis.call('GET', KEYS[1])
      if not cur then return 0 end
      ...
      """)

def drop_l2(conn, table, id, version) do
  Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])   # EVALSHA-first
end
```

This is the whole parallel: cache a derived handle (the SHA1) near the work, run by the handle with `eval`, and let the
connector resend the source only when the server answers `NOSCRIPT`. The deeper EchoMQ story — the full Lua bundle, the
version fence, the protocol governance — is the subject of the dedicated EchoMQ course, not this dive. The cited code
is real and verified in `echo/apps/echo_wire` and `echo/apps/echo_cache`; it is shown as a parallel to client-side
caching, not as a queue feature.

## References

### Sources
- [Valkey — Scripting with Lua](https://valkey.io/topics/programmability/) — `EVALSHA`, the script cache, and the `NOSCRIPT` reply on a miss.
- [Redis — EVALSHA](https://redis.io/commands/evalsha) — running a cached script by hash, and the `NOSCRIPT` error on a miss.
- [Redis — Client-side caching](https://redis.io/docs/latest/develop/use/client-side-caching/) — the near-cache pattern the script cache mirrors, cache-then-invalidate.

### Related in this course
- [R1.04 · Client-side caching](/redis-patterns/caching/client-side-caching) — the module hub.
- [R1.04.2 · The invalidation push](/redis-patterns/caching/client-side-caching/invalidation-push) — the near-cache half of the parallel.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under the Exchange Platform, and the door to the EchoMQ course.
- [/echomq](/echomq) — the EVALSHA-first connector and the full script bundle, in depth.
