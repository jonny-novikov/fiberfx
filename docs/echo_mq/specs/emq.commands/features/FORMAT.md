# The v1→v3 command format

Every command doc under this tree follows one shape, established for
`addStandardJob-9` → `EchoMQ.Jobs.enqueue/4`. Each is self-contained and has
five parts, in order:

1. **Header** — a parseable `--@` block (agent-readable). Fields:
   `--@command`, `--@feature`, `--@status`, `--@rung`, `--@v1` (raw source +
   KEYS arity), `--@v3` (module · token · `file:line`). An MCP tool can lift the
   whole contract without parsing prose.
2. **v1 source** — the original Lua, verbatim from `registry/<cmd>.lua`
   (human-readable). Parity commands with no standalone script say so.
3. **v1 → v3 change ledger** — the repo's authoritative side-by-side reflowed
   into a rendered markdown table (`v1 act | v3 act`), row-aligned.
4. **Aligned flow** — the same side-by-side, verbatim ASCII (copy-faithful, the
   source of truth the ledger is derived from).
5. **Decision & rationale** — `covers → v3`, the `decision`, and the
   `BCS · EchoMesh · [when]` line, carried from the registry unchanged.

## NO-INVENT

The repo withholds v3 schematics for unbuilt rungs (`NOT YET`, `*(proposed)*`,
`*(Schematic withheld per NO-INVENT)*`). This conversion does the same: it adds
structure and embeds the **v1** source, but **never fabricates v3 Lua**. Where
v3 is Elixir-native or proposed, the v3 side is represented only by the repo's
own authoritative mapping, ledger column, and rationale.

## Status vocabulary

`SHIPPED` (ported) · `PARTIAL` (shipped in part) · `NOT YET` (proposed) ·
`RETIRED` (dropped by design) · `BUILDING` (`[RECONCILE]`, ahead of code) ·
`PROPOSED` (forward-only).

## Deep-dive tier

`addStandardJob-9` was taken one tier further last turn: two clean, compilable
Lua sources (`enqueue_v1.lua` / `enqueue_v3.lua`), a real `diff -u`, and a
semantic ledger with a *Why* column. That tier is reserved for SHIPPED commands
where both sides are concrete Lua; ask for any command by name to take it there.
