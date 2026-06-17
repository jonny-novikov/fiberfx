# The Namespace Discriminant — carried twice

> Route: `/bcs/ideas/identity-contract/the-namespace-discriminant` (dive 1 of 4, B1.2). Teaches the *typed*
> property of `content/bcs1.2.md`; evidence per `content/docs/One-Contract-Three-Runtimes.md` and
> `content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out`. Build stamp: `BCS0NtMmOIG1ce`.

## Hero

Kicker: `B1.2 · DIVE 1 OF 4 — the typed property`. Title: **A discriminant carried twice.** Lede — the
namespace lives in the value (the first three bytes) and in the type, wherever the runtime can hold one. What
systems may rely on: a wrong-kind identity cannot cross a declared boundary silently. Heronote — the evidence
stack runs the whole gauntlet: one compiler error, a 400 issued before any handler runs, and a store-side
`{:error, :namespace}` — the silent join retired at compile time, at the schema, and at the store, in that
order.

### The two carriages (interactive SVG)

The 14-byte id with its three namespace cells, plus the three enforcement layers stacked beneath: the type
(compile time), the schema (the HTTP edge), the store (the substrate gate). Select a layer to read its
mechanism and its committed evidence in the readout. Degrades to a static labelled diagram.

## §1 · The evidence stack (#evidence)

Frozen (content/docs/One-Contract-Three-Runtimes.md · the deliberate negative test):

    typecheck_negative.ts(13,13): error TS2345: Argument of type 'BrandedId<"USR">'
      is not assignable to parameter of type 'BrandedId<"CRS">'.

Frozen (content/docs/One-Contract-Three-Runtimes.md · the HTTP gate row, proven through inject):

    inject: valid/malformed/ns/miss : 200 / 400 / 400 / 404

The third column is the one to stare at: a structurally *valid* `USR` id on a route that requires `CRS` is a
400 issued by the schema compiler — the handler never runs. The fourth column is the only question a gated
route leaves to the handler: known or unknown, 200 or 404.

Frozen (content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out · the store gate, G3):

    G3 typed ok -- rejects 4/4 as :invalid; GRD id on BRL store -> {:error, :namespace}; raising twin -> NamespaceError

## §2 · The boundary gate, run by hand (#gate)

Interactive: a declared boundary that requires `CRS`. Fixed dataset, every input from a committed source —
`CRS0KHTOWnGLuC` (the article's seed literal) · `USR0KHTOWnGLuC` (the canonical vector — structurally valid,
wrong kind) · `usr0KHTOWnGLuC` (the namespace reject) · `USR0KHTOWnGLu` (the length reject). A pure function
replays the gate: parse, then namespace match; the readout names the verdict and the layer that issued it.

## §3 · Carriage in Elixir (#elixir)

The discriminant lives in binary pattern matching: a function head of
`<<ns::binary-size(3), _::binary-size(11)>>` with the `is_branded` guard makes the function-clause system do
the type system's work. The `~b` sigil moves literal validation to compile time — an invalid id in source
fails the build, not the request.

## §4 · Carriage in Go (#go)

Nominal where Go can hold it, constructor-enforced where it cannot: one defined type per registered namespace
— `type PrtID string`, `type AstID string` — minted only by parsing constructors, so a `PrtID` does not assign
where an `AstID` is required, and the conversion that would defeat it is explicit, greppable, and reviewable.
Weaker than a TS brand, and stated so; the load-bearing gate in Go remains the channel edge of the owner
goroutine, where every inbound id meets `Parse` before any map is touched.

## §5 · What it retires (#retires)

The silent join — the wrong-table id that survives until an analyst notices. With the discriminant carried
twice, it dies at compile time, at the schema, and at the store, in that order; each layer that misses it
leaves one more layer in front of the data.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · King — Announcing
Snowflake (`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake`).
Related: `/bcs/ideas/identity-contract` (the hub) · `/bcs/ideas` · `/bcs` · `/elixir`.

## Pager

Previous: the hub · `/bcs/ideas/identity-contract`. Next: dive 2 ·
`/bcs/ideas/identity-contract/the-order-theorem`.
