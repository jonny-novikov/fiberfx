# Newer wins: the conditional drop

> Route: `/echomq/cache/coherence/newer-wins-the-conditional-drop` · Module 03, dive 03.
> Grounded in `EchoStore.Coherence` (the `@drop` / `:coherence_drop` script) + `EchoStore.Journal` —
> `echo/apps/echo_store/`. All real code. **This dive carries the pillar's one Lua, taught in two beats.**

## Why a script at all

Both lanes deliver the same 29-byte message; what the receiver does with it must be **atomic and conditional**. The
naïve move — read the stored version, compare, delete if newer — is a read-then-write race: between the read and the
delete, a newer write could land, and the late stale invalidation would erase it. The fix is to do the read, the
compare, and the delete in **one server-side transition**. That is the pillar's one inline Lua, `:coherence_drop`.

## Beat one — the named handle

`EchoStore.Coherence.drop_l2/4` is the Elixir verb. It hands the script exactly one key (the L2 row, built by the
keyspace, the single owner of where data lives) and one value (the incoming version):

```elixir
# EchoStore.Coherence — drop_l2/4 (beat one: the handle)
# @drop is the :coherence_drop script, registered inline at module load.
# The host builds KEYS through the keyspace; the script constructs no key.
# ARGV[1] is the incoming version — a VALUE the script compares, never a key.
@drop Script.new(:coherence_drop, """
      ... the script body — see beat two ...
      """)

def drop_l2(conn, table, id, version) do
  Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])
end
```

The handle returns `{:ok, 1}` when it dropped the row and `{:ok, 0}` when it left it alone — a one-bit verdict the
caller can count.

## Beat two — the `:coherence_drop` body

Here is the real script body, deeply commented. `KEYS[1]` is the L2 row; `ARGV[1]` is the incoming 14-byte version.
The stored value is the `version <> value` frame written by `put/3-4`, so the stored version's 11-byte payload is
`string.sub(cur, 4, 14)` and the incoming one is `string.sub(ARGV[1], 4, 14)`:

```lua
-- :coherence_drop — KEYS[1] = the L2 row (ecc:{table}:id), ARGV[1] = the
-- incoming 14-byte version. One transition: read, compare, conditionally
-- delete. A late stale invalidation can NEVER erase a newer row.

local cur = redis.call('GET', KEYS[1])

-- (1) the row is already gone: nothing to drop.
if not cur then return 0 end

-- (2) a malformed frame (shorter than one version): it cannot be trusted to
-- carry a comparable version, so drop it unconditionally and report a drop.
if #cur < 14 then
  redis.call('DEL', KEYS[1])
  return 1
end

-- (3) the comparison: the incoming version's 11-byte snowflake payload
-- (bytes 4..14 of ARGV[1]) against the stored frame's version payload
-- (bytes 4..14 of cur — the version is the frame's prefix). Lua's string
-- order on these Base62 bytes is mint order (the order theorem), so this is
-- exactly newer?/2 done server-side. Delete only when strictly newer.
if string.sub(ARGV[1], 4, 14) > string.sub(cur, 4, 14) then
  redis.call('DEL', KEYS[1])
  return 1
end

-- (4) the stored version is at least as new: leave the row untouched.
return 0
```

Four branches, one of which deletes conditionally. The properties fall straight out:

- **A late stale invalidation can never erase a newer row.** If a slow node finally delivers an old version after a
  newer write has landed, branch (3) compares the old payload against the newer stored payload, finds it *not
  greater*, and falls through to branch (4): the row stays.
- **Idempotent.** Replay the same version and branch (3) compares it against itself (if the row survived) or finds
  the row gone (branch 1) — either way nothing is erased twice.
- **The frame is self-describing.** The script never needs a side table of versions; the version is the prefix of the
  value it guards, so the comparison reads the truth straight out of the row it might delete.

This is the version-guarded counterpart to module 01's `invalidate/3`, which `DEL`s **unconditionally** — the admin
override, used when you mean "drop this now regardless." `drop_l2/4` is what a *coherence message* runs, and it is
safe to deliver more than once and out of order precisely because of branch (3).

## The receiving side keeps a count

The L1 half of the receiver lives in `EchoStore.Table.apply_coherence/3` — it evicts the local ETS row under the same
`Coherence.newer?/2` test and ticks `:coh_applied` when it drops and `:coh_stale` when it declines. So the cache's
`stats/1` reports, honestly, how many coherence messages were newer (applied) and how many were stale (ignored) —
the at-most-once and at-least-once lanes both fold into the same two counters.

## The journal remembers — the durable floor

The job lane's worker does not call `drop_l2/4` directly; it goes through `EchoStore.Journal`, whose `apply_and_remember/4`
checks the version against the lane's **memory** first:

```elixir
# EchoStore.Journal — apply_and_remember/4 (the memory in front of the apply)
# The `applied` table survives the node, the cache, and the bus. A replayed
# old intent answers stale from the journal even when L1 has forgotten the
# row — durability for the obligation, not just the optimization.
def handle_call({:apply_and_remember, table, name_id, version}, _from, s) do
  reply =
    case fetch_applied(s, name_id) do
      remembered when is_binary(remembered) ->
        if Coherence.newer?(version, remembered),
          do: apply_and_record(s, table, name_id, version),
          else: {:ok, :remembered_stale}

      nil ->
        apply_and_record(s, table, name_id, version)
    end

  {:reply, reply, s}
end
```

`intend_and_enqueue/4` is the outbox in one verb — mint a JOB id, record the intent, enqueue, mark enqueued — and the
crash windows between those steps are covered by `replay/2` plus the bus's job-id dedup plus newer-wins. The `applied`
table is the lane's **memory of the last version per name**, so even after L1 has dropped the row and the bus has
forgotten the job, a replayed old intent is answered *stale from the journal* — the row is never resurrected by a
late delivery. That durable substrate beneath the volatile cache and bus is **Echo Persistence**: the outbox is a
small, mostly-idle table beside the bus, and the deep durability dial (a bounded window, a checkpoint per K, a
commit-per-record replicated off-box) lives there.

## Pattern & implementation

- **The pattern (conditional, idempotent invalidation):** an invalidation that may arrive late, twice, or out of
  order must be safe anyway — so it is applied as an atomic compare-and-delete keyed on a logical version, not a
  blind delete.
- **The implementation (`:coherence_drop` + the journal's memory):** one inline Lua does read-compare-delete
  server-side; `string.sub(_, 4, 14)` reads the version straight out of the `version <> value` frame; the journal's
  `applied` table keeps the verdict durable so a replayed old intent answers stale even after the row is gone.

One script, one transition: the cache that serves a hot read from local memory is also the cache that *cannot* be
corrupted by a stale message, no matter how the message arrived.

## References

- Valkey — EVAL — the atomic server-side transition the conditional drop runs in.
- Valkey — GET / DEL — the read and the conditional delete inside the script.
- King — Announcing Snowflake — the version whose byte order the `string.sub` comparison reads as mint order.
- Helland — Life Beyond Distributed Transactions — the durable outbox beside the bus, an entity addressed by a name.
- Related in this course: `/echomq/cache/coherence` (the hub), `/echomq/cache/coherence/the-two-lanes`,
  `/echomq/cache/cache-aside-two-layers` (the unconditional `invalidate/3` contrast), `/echo-persistence`,
  `/bcs/store`.
