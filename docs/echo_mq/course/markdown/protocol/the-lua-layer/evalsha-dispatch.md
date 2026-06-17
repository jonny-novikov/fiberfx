# EVALSHA dispatch

**Route:** `/echomq/protocol/the-lua-layer/evalsha-dispatch` · **Surface:** dive · **Pillar:** The Protocol

> Source-of-record. As-shipped voice, no version labels. All grounding is real code in `echo/apps/echo_wire` —
> **no `[RECONCILE]` markers**. Code shown extract-and-annotate, no `file:line`.

## The fact

A script's source crosses the wire **at most once per connection**. `EchoMQ.Script.new/2` precomputes each script's
SHA1 when the module loads; `EchoMQ.Connector.eval/5` runs the script with `EVALSHA` — sending only the 40-character
digest, the key count, the keys, and the values. If the server has not seen the script (a cold cache answers
`NOSCRIPT`), the connector loads the source once with `SCRIPT LOAD`, confirms the returned SHA matches the precomputed
one, and re-runs by SHA. After that, every call is a digest. This is the dispatch half of the Lua layer: the scripts
are the protocol; EVALSHA is how they run without re-sending the source each time.

## The worked example — precompute the SHA, then run by it

### The script struct — SHA1 precomputed at definition

`EchoMQ.Script.new/2` is called once per script at module load. It hashes the source to a lowercase SHA1 and keeps the
name, the source, and the digest together. The source is retained only for the cold-cache load; the digest is what the
hot path sends.

```elixir
# echo_wire — EchoMQ.Script
# A server-side script with its SHA1 precomputed, so the connector can run
# EVALSHA-first with a load-on-NOSCRIPT fallback. Every key a script touches
# is declared in KEYS — the law; ARGV carries values only.
def new(name, source) when is_atom(name) and is_binary(source) do
  # the SHA1 of the source is what EVALSHA addresses; lowercase hex matches
  # the digest SCRIPT LOAD returns, so the two can be compared byte for byte.
  sha = :crypto.hash(:sha, source) |> Base.encode16(case: :lower)
  %__MODULE__{name: name, source: source, sha: sha}
end
```

So `@enqueue = Script.new(:enqueue, "...")` is computed once. Every later `enqueue/4` reuses the same struct — the SHA
is never recomputed on the hot path.

### The dispatch — EVALSHA first, load on NOSCRIPT

`EchoMQ.Connector.eval/5` builds the `EVALSHA` command from the precomputed SHA, the key count, the keys, and the
values. On a `NOSCRIPT` reply it loads the source once, verifies the SHA, and re-runs; any other server error is mapped
to a typed failure.

```elixir
# echo_wire — EchoMQ.Connector
# EVALSHA-first execution of a declared-keys script. The wire carries the
# 40-char digest, the key count, then KEYS then ARGV — never the source on the
# hot path.
def eval(conn, %Script{} = s, keys, argv, timeout \\ 5_000) do
  parts = ["EVALSHA", s.sha, Integer.to_string(length(keys))] ++ keys ++ argv

  case command(conn, parts, timeout) do
    # cold cache: the server has never seen this script. Load it ONCE, confirm
    # the returned digest equals the precomputed one, then re-run by SHA.
    {:ok, {:error_reply, "NOSCRIPT" <> _}} ->
      GenServer.call(conn, {:bump, 5})   # count the script_load (counter slot 5)

      case command(conn, ["SCRIPT", "LOAD", s.source], timeout) do
        {:ok, sha} when sha == s.sha -> command(conn, parts, timeout) |> map_script_reply()
        {:ok, other} -> {:error, {:sha_mismatch, other}}
        {:error, _} = err -> err
      end

    # any other server error is a verdict — mapped to a typed {:server, msg}.
    {:ok, {:error_reply, msg}} ->
      {:error, {:server, msg}}

    other ->
      other
  end
end
```

Two details carry the dispatch's correctness:

- **The SHA is verified, not trusted.** `SCRIPT LOAD` returns the server's digest of the source; the connector accepts
  the re-run only when that digest equals the precomputed `s.sha`. A mismatch (`{:sha_mismatch, other}`) means the
  source the server hashed is not the source the struct holds — a hard fault, not a silent retry.
- **A load-and-retry error maps exactly as the first attempt.** A script can fail on either attempt; `map_script_reply`
  ensures the error reply from the re-run is turned into the same `{:server, msg}` shape as a first-attempt error, so a
  caller cannot tell a cold cache from a warm one. (The connector found this on a cold script cache during
  conformance.)

The connector keeps counters — slot 5 `script_loads`, slot 6 `evalsha_calls` — so a healthy connection shows one load
per script and many EVALSHA calls after it.

## The pairing — the pattern → the implementation

- **The pattern (Redis Patterns Applied):** load a script once and run it by SHA with EVALSHA, reloading on a NOSCRIPT
  miss — `/redis-patterns` teaches scripting as the way a pattern becomes a protocol.
- **The implementation (echo_wire):** `EchoMQ.Script.new/2` precomputes the SHA; `EchoMQ.Connector.eval/5` runs it
  EVALSHA-first and loads on NOSCRIPT once per script per connection.

## Recap

EVALSHA dispatch sends a digest, not source. `EchoMQ.Script.new/2` precomputes the SHA1; `EchoMQ.Connector.eval/5` runs
the script by SHA, loads the source once on a NOSCRIPT miss, verifies the returned digest, and maps a re-run error
exactly as a first-attempt error. The scripts are the protocol; this is how they run.

## References

### Sources
- Redis — *EVALSHA* — `https://redis.io/commands/evalsha/` — run a cached script by its SHA1 digest.
- Valkey — *EVALSHA* — `https://valkey.io/commands/evalsha/` — the substrate-of-record form of the same dispatch.
- Valkey — *SCRIPT LOAD* — `https://valkey.io/commands/script-load/` — cache the source and return its digest, the
  cold-cache path.
- Valkey — *Documentation* — `https://valkey.io/docs/` — the store the connector speaks to over RESP.

### Related in this course
- `/echomq/protocol/the-lua-layer` — the module this dive belongs to.
- `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` — the script this dispatch runs.
- `/echomq/protocol/the-lua-layer/declared-keys` — the keys the dispatch passes after the SHA.
- `/redis-patterns/overview/patterns-become-protocol` — scripting as protocol, the near side of the door.
- `/redis-patterns/coordination` — atomic updates and one-slot Lua.
