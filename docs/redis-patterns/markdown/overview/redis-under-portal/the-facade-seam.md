# The facade seam

> Route: `/redis-patterns/overview/redis-under-portal/the-facade-seam` · Module R0.2 · dive 1 · Source:
> ORIENTATION — the placement module, no single pattern source · Grounding: the master invariant — every
> surface calls only the echo data layer and reads a typed result from a closed set (the connector is taught by
> `/echomq`) · `echo/apps/echo_wire` · `docs/echo/bcs/content/bcs3.1.md` · `bcs4.1.md` — every figure verbatim
> from a committed record. Reframed under [`specs/reframe-echomq/`](../../../specs/reframe-echomq/reframe-echomq.md).

One seam holds the whole system together: every surface calls the same boundary — the echo data layer — and Valkey
lives below it, never on a surface's path. The order API, a consumer, and a background worker each call one thing —
the echo data layer — and read only a typed result from a closed set. Below the seam sits the one owned Valkey
client, EchoWire; EchoCache and the EchoMQ bus ride it, both over Valkey. The connector behind the boundary is
taught by the [`/echomq`](/echomq) course; this dive states the rule and shows it holding.

## §1 · One boundary, one return set

The Exchange Platform reaches Valkey through one boundary, the echo data layer. The master invariant is a rule
about every surface above it: a surface calls **only** that boundary and reads **only** a typed result from a
closed set. A surface never opens a socket, never holds a key, never branches on a raw store error. EchoWire — the
one owned Valkey client — is below it.

The closed return set is the other half of the seam. Every call returns either a success or one of a fixed, small
set of typed errors — `:disconnected` when the socket is gone, `:overloaded` when in-flight is full,
`{:version_fence, got}` when the boot fence fails — never a raw exception. Because the set of outcomes is closed,
the surface's handling is finite. How the connector resolves a call, pipelines, and reconnects is the subject of
the [`/echomq`](/echomq) course, not repeated here.

## §2 · Every outcome is one of a closed set

A condition *below* the boundary — an EchoCache L1 hit, a cold read that runs the loader once, a dropped socket, a
full in-flight queue — never escapes as a raw store condition. The data layer folds each one into the closed
return set, and the surface reads the typed result. The committed EchoCache walk from `bcs4.1` shows the read path
the seam hides: `a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1
drop falls back to L2 -- the loader still ran once`. None of those sources is visible above the seam — each one
resolves to the same success shape, and a wire failure folds to a typed error.

## §3 · The seam at the edge — and at the wire

Take one call: the order API admits an order. It calls the gateway to parse it; the gateway mints a branded id,
returns a typed command or one of a closed set of errors, and the API handles the result — never a raw exception:

```elixir
# A surface (the order API) calls ONLY the gateway and matches ONLY the closed error set.
case Exchange.Gateway.parse_place(raw_order) do
  {:ok, command}   -> submit(command)
  # one of six closed errors: :unknown_instrument | :bad_direction | :bad_order_type
  # | :nonpositive_quantity | :bad_price | :malformed
  {:error, reason} -> reject(reason)
end
```

Nowhere in the order API is there a socket, a key, or a parse branch on a raw field. And the discipline reaches
all the way down: even the wire's *boot* is typed at its own seam. At every connect EchoWire's connector reads
`{emq}:version` and refuses any other value with a typed error — the committed line from `bcs3.1` reads
`GET {emq}:version answers echomq:2.0.0 through the fenced connector itself`. Typed outcomes at the edge, typed
refusals at the wire: the same shape, twice.

> Notes on Valkey · The EchoCache L2 row is written with `SET … PX`, so the second layer expires itself on the
> server's own clock even when no node sweeps it — `PTTL 300 ms of 300` in the committed record
> ([valkey.io/commands/set](https://valkey.io/commands/set/)).

**The invariant → its BCS application.** A caller depends on one stable interface and a closed set of outcomes;
the store behind it is an implementation detail that can change without the caller noticing. In the BCS build,
every surface calls only the echo data layer and reads a typed result; EchoWire is the one owned Valkey client
below it — and its connector applies the same law to the wire with the version fence.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — the `PX` option: the L2 row written with its expiry in one command.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution below the seam; a transition either happened or did not.
- [Redis — Documentation](https://redis.io/docs/) — the command and data-type reference behind the catalog.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [R0.2 · Valkey under the Exchange Platform](/redis-patterns/overview/redis-under-portal) — the module hub.
- [R0.2.2 · The two roles](/redis-patterns/overview/redis-under-portal/two-roles) — the next dive.
- [R0.2.3 · The reserved tier](/redis-patterns/overview/redis-under-portal/reserved-tier) — the tier, shipped.
- [/echomq](/echomq) — the connector and the protocol in depth.
- [/bcs](/bcs) — the architecture below the seam, with the frozen transcripts.
- [/elixir](/elixir) — the functional-Elixir and OTP craft behind the echo umbrella.
