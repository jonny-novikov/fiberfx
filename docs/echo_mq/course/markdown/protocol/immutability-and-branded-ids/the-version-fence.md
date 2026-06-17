# The version fence — dive

> Route: `/echomq/protocol/immutability-and-branded-ids/the-version-fence` · surface: **dive**.
> Grounding: **real code** in `echo/apps/echo_wire` + `echo/apps/echo_mq`. **No `[RECONCILE]` markers.**
> Discipline note: the wire constant `echomq:2.0.0` appears ONLY as a quoted code value in the fence extract — never
> as a course-version label, never as a release name.

## The fact

The immutable line and the branded-id gate protect the data and the scripts. One thing is left: the **connection**. A
connector that does not speak this wire must not run against this store, because it could write rows the wire's readers
cannot understand. The fence is one reserved key — `{emq}:version` — that carries the wire's identity string, and a
**check the connector runs before its first command.**

The check is a claim-or-verify. On connect the connector reads `{emq}:version`. If the value already matches the wire
it speaks, it proceeds. If the key is absent, it claims it — `SET … NX` then a confirming read, so two connectors racing
to claim an empty store cannot both win. If the value is present and disagrees, the connection is refused: the connector
returns a `version_fence` error and, on a reconnect, that error is fatal — the connection is not retried against a store
it does not match. The fence lives in the **reserve** `{emq}:`, the core's own cross-queue space, first-byte-disjoint
from any queue's `emq:{q}:` keys, so it is never confused with queue data.

## The worked example (real grounding)

The key is built by the keyspace; the check is run by the connector.

The reserved key:

```elixir
# echo_mq — EchoMQ.Keyspace
# {emq}: is the core's reserved space — cross-queue keys live here, disjoint
# from any queue's emq:{q}: keys. The version key is one of them.
@reserve "{emq}:"
@version_key @reserve <> "version"

def version_key, do: @version_key
```

The fence, run at connect (the wire constant is a quoted code value):

```elixir
# echo_wire — EchoMQ.Connector
# @wire_version is the identity string this connector speaks; it is a code
# constant, not a label. The fence reads {emq}:version once: a match runs,
# an absent key is claimed with SET NX then re-read to confirm the claim,
# and a present-but-different value refuses the connection.
@wire_version "echomq:2.0.0"

defp fence(sock, buf) do
  vkey = Keyspace.version_key()

  with {:ok, current, buf2} <- sync(sock, ["GET", vkey], buf) do
    case current do
      @wire_version ->
        :ok

      nil ->
        with {:ok, _, buf3} <- sync(sock, ["SET", vkey, @wire_version, "NX"], buf2),
             {:ok, @wire_version, _} <- sync(sock, ["GET", vkey], buf3) do
          :ok
        else
          {:ok, got, _} -> {:error, {:version_fence, got}}
          err -> err
        end

      got ->
        {:error, {:version_fence, got}}
    end
  end
end
```

The `SET … NX` is the race guard: `NX` writes only if the key is absent, so of two connectors claiming an empty store
exactly one succeeds, and the confirming `GET` makes the loser read the winner's value — which either matches (it runs)
or does not (it is refused). The fence is checked inside the connect sequence, before the connection answers its first
caller; on a dropped-and-reconnected socket, a `version_fence` mismatch is treated as fatal rather than retried.

## The interactives

1. **Hero — the fence-check simulator.** Pick the store's current `{emq}:version` state (absent, a matching value, a
   different value) and read the connector's verdict: absent → claim with `SET NX` and run; match → run; different →
   refused with `{:version_fence, got}`. Pure function over the three cases, live `.geo-readout`, an `<svg>` of the
   connect → fence → run/refuse path.
2. **Main — the reserve map.** Pick a key and read whether it lands in a queue's `emq:{q}:` space or the core reserve
   `{emq}:`, and why the version key belongs in the reserve (first-byte-disjoint from queue data). Pure classification
   over a fixed set of keys, with a live readout.

## The bridge (pattern → implementation)

- **The pattern (Redis Patterns Applied):** a single reserved key, claimed atomically, can guard a whole connection —
  `SET … NX` is the atomic claim, and an atomic check-then-act is what makes the guard safe under a race.
  `/redis-patterns/coordination` teaches that atomic claim.
- **The implementation (echo_wire):** `EchoMQ.Connector.fence/2` reads `Keyspace.version_key/0` → `{emq}:version` at
  connect; absent → `SET … NX` + confirm, match → run, mismatch → `{:error, {:version_fence, got}}` (fatal on
  reconnect).

## Recap + take

The fence is one reserved key, `{emq}:version`, and a claim-or-verify the connector runs before its first command:
match runs, absent is claimed atomically with `SET … NX`, mismatch is refused. **Take:** the connection is checked
against the wire before it can touch it, so a connector that does not match the wire never writes to it.

## References

### Sources
- Valkey — SET (`https://valkey.io/commands/set/`) — the `NX` atomic claim the fence uses to win a race uncontested.
- Valkey — GET (`https://valkey.io/commands/get/`) — the read the fence opens and confirms with.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.

### Related in this course
- `/echomq/protocol/the-owned-keyspace` — the keyspace and the `{emq}:` reserve in depth.
- `/echomq/protocol/immutability-and-branded-ids/the-branded-id-gate` — the previous dive: identity gated in Lua.
- `/echomq/protocol` — the chapter landing.
- `/redis-patterns/coordination` — the atomic claim, the near side of the door.
