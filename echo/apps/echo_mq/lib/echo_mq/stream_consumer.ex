defmodule EchoMQ.StreamConsumer do
  @moduledoc """
  The reader LAW of EchoMQ 3.0's Stream Tier (emq3.3, S2 the readers part 1):
  a BEAM consumer group over a per-key event stream, at-least-once with
  idempotent handlers, crash -> re-delivery. A supervised `spawn_link` loop
  holding a PRIVATE connector lane -- the `EchoMQ.Consumer` / `EchoMQ.BatchConsumer`
  shape (`consumer.ex:1-12` "blocking verbs get their own lane (Appendix B)")
  -- so the blocking `XREADGROUP ... BLOCK` parks on its OWN lane and the
  single-owner socket of the rest of the system is never stalled
  (`consumer.ex:170`, the `BLPOP`-on-its-own-lane precedent). A SIBLING of the
  job `Consumer`, not a mode on it: a different claim path (`XREADGROUP` group
  read, not `Lanes.claim`) + a different settle (`XACK` / leave-un-acked, not
  `Jobs.complete` / `Jobs.retry`) earns a sibling (the `EchoMQ.BatchConsumer`
  precedent, `batch_consumer.ex:10-16`, emq.5.2-D1).

  ## The group door (lazy ensure-on-start, D-3 / INV4)

  On `start_link` the consumer issues `XGROUP CREATE <key> <group> <start>
  MKSTREAM` (the `stream_verbs_test.exs:93` round-trip wired into the loop) and
  swallows ONLY the `BUSYGROUP` reply (the group already exists -- an idempotent
  no-op start; restart-storms never error). A `WRONGTYPE` (a non-stream key
  collision) or any other error is LOUD -- the consumer fails to start (the
  gate-liveness discipline). The start position is the DECLARED `:group_start`
  option (`:new` -> `$` / `:head` -> `0`), NO default -- a missing/malformed
  `:group_start` RAISES at start, so the replay-vs-tail correctness decision is
  forced into the open WITHOUT a second verb. There is NO destructive
  group-tear-down verb at this rung (the at-rest group-removal surface stays
  UNFROZEN for the retention/archive family -- the emq.4.1 `drain/3` precedent);
  the door creates and swallows-on-exists, never destroys.

  ## The loop (drain-PEL-first -> `>` -> `XAUTOCLAIM`, D-4 / INV1 / INV2)

  Recovery is TWO complementary mechanisms, both NAMED (§2 of the body):

    * **PEL-drain-on-(re)start recovers SELF.** On the first pass the consumer
      reads its OWN PEL (`XREADGROUP GROUP g <self> ... 0`, the un-acked backlog
      keyed to its OWN consumer name) to exhaustion, settling each, THEN switches
      to `>`. A crashed consumer that restarts with the same name recovers its
      own held work the INSTANT it restarts. A clean cold start has an empty PEL
      (`0` returns nothing) -> straight to `>` (one code path covers both).

    * **The `XAUTOCLAIM` beat recovers dead PEERS.** On each beat the consumer
      reclaims entries idle past `:min_idle_ms` via `XAUTOCLAIM <key> <group>
      <self> <min_idle_ms> <cursor>` -- the entries held by OTHER consumers that
      died and NEVER restarted (so their PEL is never self-drained). The
      min-idle threshold (evaluated SERVER-side against `XPENDING` idle, no host
      clock) is the single tunable for "how long before a dead peer's work is
      re-delivered."

  Then the blocking `XREADGROUP GROUP g <self> BLOCK <beat_ms> COUNT <n> STREAMS
  key >` parks on the PRIVATE lane for new entries. `check_control` honors a
  stop/shutdown at the settle points (between entries, never inside one,
  `consumer.ex:127-135`). A raising handler converts to a typed
  `{:error, reason}` and the loop survives (the `consumer.ex:148-153`
  rescue/catch discipline); `stop/2` drains the entry in hand and stops.

  ## The handler (the exact mirror, D-4 / INV3)

  `fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}` --
  byte-identical in SHAPE to the job `Consumer`'s handler (`consumer.ex:147`):
  ONE portable handler across job + stream. `id` is the stored branded record id
  (the `EchoMQ.Stream.append/4` receipt, recovered from the entry's `id` FIELD);
  `payload` the entry's remaining fields as a map; `group` the consumer-group
  name; and `attempts` carries the `XPENDING` per-entry DELIVERY-COUNT (how many
  times THIS entry has been delivered to a consumer), NOT a handler-failure count
  -- SPECCED, not assumed, so a poison-threshold (`attempts >= N`) calibrates
  correctly. On `:ok` the entry is `XACK`ed; on `{:error, reason}` (or a raise)
  it is LEFT un-acked (it survives in the PEL -> re-delivered by the
  `XAUTOCLAIM` beat or the next PEL-drain -- the at-least-once posture).

  ## The order theorem under a group (the PEL exception, D-6 / INV6)

  The stream stays id-ordered (`XRANGE` / `XREADGROUP ... >` hand NEW entries in
  mint order -- the writer's theorem is untouched). But a RE-CLAIMED entry
  (recovered via `XAUTOCLAIM` or a PEL-drain after newer entries were already
  delivered) returns to a consumer OUT of real-time delivery order -- its branded
  id is OLDER (lower) than entries already handled. This is the irreducible cost
  of at-least-once (exactly-once is NOT claimed). The consequence: the handler
  MUST be idempotent -- handling the same entry twice, or an older entry after a
  newer one, must be safe (the branded id is the dedup key, the BCS newer-wins
  discipline).

  ## What this rung is NOT

  No retention (`MAXLEN` / `MINID` -- emq3.4; the consumer does not trim). No
  archive fold (a fold-mode consumer committing to `EchoStore.Graft` -- emq3.5;
  emq3.3 freezes the handler shape the fold rides, but folds nothing). No new
  `Script.new/2` (the group verbs `XGROUP` / `XREADGROUP` / `XACK` /
  `XAUTOCLAIM` / `XPENDING` are issued DIRECT through `EchoMQ.Connector.command/3`
  -- a no-new-Lua rung).
  """

  alias EchoMQ.Connector

  # the verbatim XGROUP CREATE reply when the group already exists -- the ONE
  # swallowed reply (an idempotent no-op start). Surfaced as an :error_reply
  # VALUE by the connector (the resp.ex convention); any OTHER error_reply
  # (e.g. WRONGTYPE) is LOUD. valkey.io/commands/xgroup.
  @busygroup_prefix "BUSYGROUP"

  @doc "A permanent child: the loop restarts whole, and its self-started connector lane dies and returns with it."
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @doc """
  Start the consumer-group loop. Options:

    * `:queue` (required) -- the queue whose stream this reads.
    * `:stream` (required) -- the stream name; the braced key is
      `EchoMQ.Stream.stream_key(queue, stream)` = `emq:{queue}:stream:<stream>`.
    * `:group` (required) -- the consumer-group name.
    * `:consumer` (required) -- THIS consumer's name within the group (the PEL
      is keyed to it; a restart with the SAME name recovers its own backlog).
    * `:group_start` (required, DECLARED -- NO default, D-3) -- `:new` -> `$`
      (only entries appended AFTER group creation) or `:head` -> `0` (from the
      stream head). A missing/malformed `:group_start` RAISES at start.
    * `:handler` (required) -- a fun taking `%{id, payload, attempts, group}`
      and answering `:ok` (XACK) or `{:error, reason}` (leave un-acked). A raise
      converts to `{:error, reason}` and the loop survives.
    * either `:conn` (a connector this consumer treats as its own exclusive
      lane) or `:connector` (options to start one, linked to the loop -- the
      `consumer.ex:66` idiom). The blocking `XREADGROUP ... BLOCK` parks on this
      PRIVATE lane.
    * `:min_idle_ms` (default 30_000) -- the `XAUTOCLAIM` min-idle threshold (a
      dead peer's entries idle past this are reclaimed; server-side clock).
    * `:beat_ms` (default 1_000) -- the `XREADGROUP ... BLOCK` block time (the
      beat cadence; the loop reclaims dead peers on each beat).
    * `:count` (default 100) -- the per-read `COUNT` (the batch size of one
      `XREADGROUP` / `XAUTOCLAIM` pull).
  """
  def start_link(opts) do
    queue = Keyword.fetch!(opts, :queue)
    stream = Keyword.fetch!(opts, :stream)
    group = Keyword.fetch!(opts, :group)
    consumer = Keyword.fetch!(opts, :consumer)
    handler = Keyword.fetch!(opts, :handler)
    # the start position is DECLARED, never defaulted (D-3) -- raises here, on
    # the caller's process, before the loop spawns, if missing/malformed.
    start = start_position!(Keyword.fetch!(opts, :group_start))

    key = EchoMQ.Stream.stream_key(queue, stream)

    pid =
      spawn_link(fn ->
        Process.flag(:trap_exit, true)

        conn =
          case Keyword.fetch(opts, :conn) do
            {:ok, c} ->
              c

            :error ->
              {:ok, c} = Connector.start_link(Keyword.fetch!(opts, :connector))
              c
          end

        state = %{
          conn: conn,
          key: key,
          group: group,
          consumer: consumer,
          handler: handler,
          min_idle_ms: Keyword.get(opts, :min_idle_ms, 30_000),
          beat_ms: Keyword.get(opts, :beat_ms, 1_000),
          count: Keyword.get(opts, :count, 100)
        }

        # the lazy-ensure group door (INV4): create the group + the stream
        # (MKSTREAM), swallow ONLY BUSYGROUP, a WRONGTYPE/other error is LOUD.
        ensure_group!(state, start)
        # the first pass drains the consumer's OWN PEL (recover SELF, INV2),
        # then the steady loop reads `>` and reclaims dead peers on each beat.
        drain_pel(state)
        loop(state)
      end)

    {:ok, pid}
  end

  @doc """
  Drain and stop: the loop settles the entry in hand, claims nothing more, and
  exits `:normal` -- a self-started connector lane closes quietly with it.
  Synchronous; the reply arrives when the loop is down. A parked consumer
  notices the request when its `XREADGROUP ... BLOCK` returns, so stop latency
  is bounded by the beat plus the entry in hand. The same drain runs under a
  supervisor (`Supervisor.terminate_child/2`) because the loop traps exits and
  honors `:shutdown` at the same settle points. The `consumer.ex:101` shape.
  """
  def stop(pid, timeout \\ 5_000) when is_pid(pid) do
    ref = Process.monitor(pid)
    send(pid, {:emq_stop, self(), ref})

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        {:error, :timeout}
    end
  end

  # The declared start position (D-3): :new -> "$" (only NEW entries), :head ->
  # "0" (from the stream head). Any other value RAISES (never defaulted).
  defp start_position!(:new), do: "$"
  defp start_position!(:head), do: "0"

  defp start_position!(other) do
    raise ArgumentError,
          "EchoMQ.StreamConsumer requires a declared :group_start of :new (-> $) or :head (-> 0); got: #{inspect(other)}"
  end

  # The lazy-ensure group door (INV4): XGROUP CREATE <key> <group> <start>
  # MKSTREAM creates the group (and the stream, if absent). The ONLY swallowed
  # reply is BUSYGROUP (the group already exists -- an idempotent start). A
  # WRONGTYPE (a non-stream key collision) or ANY other error_reply is LOUD: the
  # consumer fails to start (the gate-liveness discipline). The OK reply and the
  # swallowed BUSYGROUP both pass; everything else raises. valkey.io/commands/xgroup.
  defp ensure_group!(s, start) do
    case Connector.command(s.conn, ["XGROUP", "CREATE", s.key, s.group, start, "MKSTREAM"]) do
      {:ok, "OK"} ->
        :ok

      {:ok, {:error_reply, <<@busygroup_prefix, _::binary>>}} ->
        :ok

      {:ok, {:error_reply, msg}} ->
        raise RuntimeError, "EchoMQ.StreamConsumer: XGROUP CREATE refused (not BUSYGROUP): #{msg}"

      {:error, reason} ->
        raise RuntimeError, "EchoMQ.StreamConsumer: XGROUP CREATE failed: #{inspect(reason)}"
    end
  end

  # Drain the consumer's OWN PEL to exhaustion (recover SELF on (re)start, INV2):
  # XREADGROUP ... 0 reads the un-acked backlog keyed to THIS consumer name; each
  # entry is settled by the handler verdict, then the read repeats until the PEL
  # returns empty. A clean cold start has an empty PEL -> the first read returns
  # nothing -> a single round-trip, then the steady loop. The `0` read is
  # NON-blocking (the PEL is already in hand server-side), so no BLOCK arg here.
  defp drain_pel(s) do
    check_control()

    case read_group(s, "0") do
      [] ->
        :ok

      entries ->
        settle_each(s, entries)
        drain_pel(s)
    end
  end

  # The steady loop (INV1, INV2): on each beat reclaim dead PEERS' idle entries
  # (XAUTOCLAIM), then park on the blocking `>` read for new entries. Control is
  # honored at the settle points (between entries, never inside one). The lane
  # dying takes the loop with it, for the supervisor to restart.
  defp loop(s) do
    check_control()
    reclaim_peers(s)
    case read_group_block(s) do
      [] -> :ok
      entries -> settle_each(s, entries)
    end
    loop(s)
  end

  # The loop traps exits, so control arrives as messages and is honored at the
  # settle points -- between entries, never inside one. A stop request drains to
  # :normal; the supervisor's :shutdown drains to :shutdown; the dedicated lane
  # dying takes the loop with it, for the tree to restart. (consumer.ex:127-135.)
  defp check_control do
    receive do
      {:emq_stop, _from, _ref} -> exit(:normal)
      {:EXIT, _from, :shutdown} -> exit(:shutdown)
      {:EXIT, _from, reason} -> exit(reason)
    after
      0 -> :ok
    end
  end

  # Reclaim a dead PEER's idle entries (INV2): XAUTOCLAIM <key> <group> <self>
  # <min_idle_ms> 0 re-assigns to THIS consumer every entry idle past the
  # threshold (server-side idle, no host clock). The reply is the
  # [next-cursor, claimed-entries, deleted-ids] triple; the claimed entries are
  # settled like any other delivery. One pass per beat (cursor 0); a deep peer
  # backlog drains over successive beats. valkey.io/commands/xautoclaim.
  defp reclaim_peers(s) do
    case Connector.command(s.conn, [
           "XAUTOCLAIM",
           s.key,
           s.group,
           s.consumer,
           Integer.to_string(s.min_idle_ms),
           "0",
           "COUNT",
           Integer.to_string(s.count)
         ]) do
      {:ok, [_cursor, claimed, _deleted]} when is_list(claimed) ->
        settle_each(s, claimed)

      {:ok, [_cursor, claimed]} when is_list(claimed) ->
        # some server builds answer a two-element [cursor, claimed] reply
        settle_each(s, claimed)

      _other ->
        :ok
    end
  end

  # A blocking read of NEW entries on the PRIVATE lane (INV1): XREADGROUP GROUP
  # g <self> BLOCK <beat_ms> COUNT <n> STREAMS key > parks for up to beat_ms.
  # This is the only blocking verb, and it rides the consumer's OWN lane (the
  # `consumer.ex:170` BLPOP precedent) -- the single-owner socket is never
  # stalled. A timeout returns nil/empty (no new entries this beat); the
  # command timeout is beat_ms + a buffer so the BLOCK returns first.
  # valkey.io/commands/xreadgroup.
  defp read_group_block(s) do
    parts =
      ["XREADGROUP", "GROUP", s.group, s.consumer, "BLOCK", Integer.to_string(s.beat_ms), "COUNT", Integer.to_string(s.count), "STREAMS", s.key, ">"]

    case Connector.command(s.conn, parts, s.beat_ms + 5_000) do
      {:ok, reply} -> group_entries(reply, s.key)
      {:error, _} -> []
    end
  end

  # A NON-blocking group read with cursor `pos` ("0" for the PEL replay): the
  # consumer's OWN pending/unseen entries depending on the cursor. Returns the
  # entry list (parsed off the stream->entries reply shape) or [].
  defp read_group(s, pos) do
    parts =
      ["XREADGROUP", "GROUP", s.group, s.consumer, "COUNT", Integer.to_string(s.count), "STREAMS", s.key, pos]

    case Connector.command(s.conn, parts) do
      {:ok, reply} -> group_entries(reply, s.key)
      {:error, _} -> []
    end
  end

  # Settle a list of [xadd_id, [field, value, ...]] entries: for each, read the
  # XPENDING delivery-count (the `attempts` mapping, INV3), invoke the handler
  # with the exact-mirror map, and XACK on :ok / leave un-acked on {:error, _}.
  # Control is honored BETWEEN entries (never inside a settle), so a stop drains
  # the entry in hand and stops (the consumer.ex discipline).
  defp settle_each(s, entries) do
    Enum.each(entries, fn entry ->
      check_control()
      settle(s, entry)
    end)
  end

  # Settle ONE entry (INV3): the branded id is the stored "id" field (the
  # EchoMQ.Stream.append/4 receipt); the payload is the remaining fields as a
  # map; `attempts` is the XPENDING per-entry delivery-count (NOT a
  # handler-failure count). A raising handler converts to {:error, reason} and
  # the loop SURVIVES (consumer.ex:148-153). On :ok -> XACK; on {:error, _} ->
  # LEAVE un-acked (it survives in the PEL, re-deliverable -- the at-least-once
  # posture).
  defp settle(s, [xadd_id, kv]) when is_list(kv) do
    {branded, payload} = parse_fields(kv)
    attempts = delivery_count(s, xadd_id)

    verdict =
      try do
        s.handler.(%{id: branded, payload: payload, attempts: attempts, group: s.group})
      rescue
        e -> {:error, Exception.message(e)}
      catch
        :exit, reason -> {:error, "exit: " <> inspect(reason)}
        :throw, value -> {:error, "throw: " <> inspect(value)}
      end

    case verdict do
      :ok ->
        # the genuinely-pending entry retires from the PEL (valkey.io/commands/xack).
        _ = Connector.command(s.conn, ["XACK", s.key, s.group, xadd_id])
        :ok

      {:error, _reason} ->
        # left un-acked: it survives in the PEL, re-delivered by the
        # XAUTOCLAIM beat or the next PEL-drain (the at-least-once posture).
        :ok
    end
  end

  # A malformed entry (no [id, fields] pair) is skipped -- never crashes the loop.
  defp settle(_s, _entry), do: :ok

  # The XPENDING per-entry delivery-count (INV3): XPENDING <key> <group>
  # <xadd_id> <xadd_id> 1 answers [[xadd_id, consumer, idle, delivery_count]];
  # the 4th field is the number of times THIS entry has been delivered. A fresh
  # `>` delivery is 1; a re-claim (XAUTOCLAIM / a PEL-drain after another
  # delivery) increments it. Defaults to 1 if the row is absent (a race -- the
  # entry just acked by a peer), never minting on nil.
  # valkey.io/commands/xpending.
  defp delivery_count(s, xadd_id) do
    case Connector.command(s.conn, ["XPENDING", s.key, s.group, xadd_id, xadd_id, "1"]) do
      {:ok, [[^xadd_id, _consumer, _idle, count] | _]} -> to_int(count)
      _ -> 1
    end
  end

  # Parse one [xadd_id, [field, value, ...]] entry's field list into
  # {branded, payload_map}: the branded record id is the stored "id" field (the
  # EchoMQ.Stream claims-only contract, mirrored from stream.ex:180-183), the
  # remaining pairs are the payload map.
  defp parse_fields(kv) do
    map = pairs(kv)
    {Map.get(map, "id"), Map.delete(map, "id")}
  end

  defp pairs([k, v | rest]), do: Map.put(pairs(rest), k, v)
  defp pairs(_), do: %{}

  # Pull the [xadd_id, [field, value, ...]] entry list off an XREADGROUP reply
  # for `key`, tolerant of the RESP3 map shape (%{key => entries}) and the RESP2
  # nested-array shape ([[key, entries]]) -- the connection-dependent
  # stream->entries form (mirrored from stream_verbs_test.exs:237-251). Returns
  # [] when the stream is absent/empty (a BLOCK timeout, or a drained PEL).
  defp group_entries(reply, key) when is_map(reply) do
    case Map.get(reply, key) do
      entries when is_list(entries) -> entries
      _ -> []
    end
  end

  defp group_entries(reply, key) when is_list(reply) do
    case List.keyfind(reply, key, 0) do
      {^key, entries} when is_list(entries) -> entries
      _ -> []
    end
  end

  defp group_entries(_reply, _key), do: []

  defp to_int(n) when is_integer(n), do: n
  defp to_int(n) when is_binary(n), do: String.to_integer(n)
end
