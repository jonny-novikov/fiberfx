# A message about a name

> Route: `/echomq/cache/coherence/a-message-about-a-name` · Module 03, dive 01.
> Grounded in `EchoStore.Coherence` — `echo/apps/echo_store/lib/echo_store/coherence.ex`. All real code. No Lua.

## The message: two names, twenty-nine bytes

A coherence message is the smallest thing that can carry the truth and nothing more. `payload/2` is
`id <> ":" <> version` — the cached name, a colon, the writer's mint-time version. Two 14-byte branded ids and one
separator: **29 bytes, and not one byte more**. There is no value in the message (the reader will re-fill from the
store if it needs one), no timestamp (the version *is* the time), no node identity, no clock vector.

`parse/1` recovers the two names from the wire and refuses anything that is not two valid branded ids:

```elixir
# EchoStore.Coherence — payload/2 and parse/1
# A coherence message is two identities and a colon. Nothing else crosses.
def payload(<<_::binary-14>> = id, <<_::binary-14>> = version),
  do: id <> ":" <> version

# parse/1 only succeeds for two well-formed branded ids — a malformed
# message is :error, never a half-applied invalidation.
def parse(<<id::binary-14, ":", version::binary-14>>) do
  if BrandedId.valid?(id) and BrandedId.valid?(version),
    do: {:ok, id, version},
    else: :error
end

def parse(_), do: :error
```

The shape is the validation: the binary pattern `<<id::binary-14, ":", version::binary-14>>` only matches a 29-byte
message with a colon in exactly the right place, and the two `BrandedId.valid?` checks reject a string that has the
right length but a malformed name. A message that does not parse is dropped, never half-applied.

## Newer wins — across kinds, with no clock

The decision the whole module turns on is "is this version newer than the one I have?" — and the answer is a string
comparison, not a clock read. `newer?/2` compares the **11-byte snowflake payloads** of the two ids and ignores the
three-byte namespace:

```elixir
# EchoStore.Coherence — newer?/2
# True when `a` was minted after `b`. The branded id's eleven payload bytes
# sort lexicographically in mint order (the order theorem), so a plain byte
# comparison answers "newer" with no clock and no coordinator. The three-byte
# namespace is dropped, so the comparison holds ACROSS kinds.
def newer?(<<_::binary-3, pa::binary-11>>, <<_::binary-3, pb::binary-11>>),
  do: pa > pb
```

Two facts make this work:

1. **Lexicographic equals chronological.** The 11 Base62 payload characters encode a 63-bit snowflake
   `ts(41) | node(10) | seq(12)`, and Base62 is monotonic — so comparing the strings byte-for-byte gives the same
   order as comparing the mint instants. No `TIME` call, no monotonic counter, no lock: the order is *in the id*.
2. **It holds across namespaces.** Because `newer?/2` drops the leading three namespace bytes, a `GAM` version and a
   `PLR` version are still comparable. A board cached under one kind and invalidated by a write of another kind
   compare correctly — coherence does not need the two sides to agree on a type, only to be branded ids.

## Idempotent by construction

There is no "apply once" bookkeeping because the comparison *is* the deduplication. Apply the same version twice and
the second application is a `pa > pb` that answers *not newer* — the row is already at that version, so nothing
happens. A re-delivered broadcast, a replayed job, a duplicate from two lanes at once: all converge, because
"is this newer than what I have" is a question with a stable answer no matter how many times it is asked.

## Pattern & implementation

- **The pattern (last-writer-wins by a logical clock):** when two writers race, pick the later one — but "later"
  needs a clock the readers agree on without coordinating. A monotonic, embedded, globally-comparable id is exactly
  such a clock.
- **The implementation (`EchoStore.Coherence`):** the version *is* the branded id minted with the write. `newer?/2`
  reads the clock straight out of the name with a string comparison; `parse/1` guarantees both sides are well-formed.
  No coordinator, no lock, no `TIME`.

A write on one node carries its id outward as a 29-byte message; every other node decides *newer or not* by reading
the clock that was minted into that id. That is the whole of coherence's vocabulary — the next dive is how the
message travels, and the third is what the receiver does with it.

## References

- King — Announcing Snowflake — the time-ordered id whose byte order is the coherence comparison.
- Helland — Life Beyond Distributed Transactions — coherence as a message about a name, not a shared object.
- Erlang/OTP — the ets module — the L1 row a newer version will later evict.
- Lamport — Time, Clocks, and the Ordering of Events — the logical clock the embedded snowflake plays the role of.
- Related in this course: `/echomq/cache/coherence` (the hub), `/echomq/cache/coherence/the-two-lanes`,
  `/echomq/protocol/immutability-and-branded-ids` (the gate), `/bcs/store`.
