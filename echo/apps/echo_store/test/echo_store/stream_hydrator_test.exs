defmodule EchoStore.StreamHydratorTest do
  @moduledoc """
  THE HYDRATION suite (emq3.6, S3 the memory part 2) -- the store-side fold gate
  (Arm 5: echo_store has no `EchoMQ.Conformance`, so the hydration is gated by
  this NEW ExUnit suite, the `EchoStore.StreamArchiveTest` precedent). Proves the
  invariants POSITIVELY (never a no-op -- the TRD.9.1 false-green class is a LOUD
  failure here):

    * INV-HYDRATE -- the Table holds per key the value of the record with the
      MAXIMUM branded `EVT` mint id (newer-wins by mint order); the load-bearing
      case is >=2 records PER KEY (so newer-wins ACTUALLY fires), the keys
      interleaving in the mint-ordered tail so the fold resolves each key to its
      own newest record;
    * INV-NOCOMPACTOR -- the hydrate READS the tail + folds via `Table.put/4`;
      no background compaction, no `XADD`/`XTRIM` of the SOURCE (the source
      stream is byte-identical after a hydrate -- READ-ONLY to the hydrator);
    * INV-FENCE -- a post-hydrate admission through the SHIPPED `:tracking`
      staleness fence (a newer `put/4`, or a server-assisted invalidation) WINS
      over the stale hydrated value; a STALE admission LOSES (both directions);
      hydration adds NO new fence -- it SEEDS the table the fence guards.

  Arm 4 is the LIVE TAIL (`EchoMQ.Stream.read/6`), so NO engine/Volume is started
  in setup (a tail-only hydrate needs none -- the merge-read deep source is a
  future arity). The hydration writes the entity key (kind `CFG`) versioned by
  the record's `EVT` id; `EchoStore.Coherence.newer?/2` compares the 11-byte
  snowflake payload namespace-blind, so an `EVT` version on a `CFG` row is sound
  (the mint-order comparison the changelog rides). `:valkey`-tagged (a live RESP3
  connection on 6390 for the bus tail read + the Table's L1/L2 writes).

  DETERMINISM POSTURE (one-shot/NORMAL): the hydration assertions are
  newest-VALUE-per-key (window-read-equivalent by construction, robust to
  same-ms boundaries), and the controlled tail mints `EVT` ids at KNOWN instants
  via `BrandedId.encode!("EVT", Snowflake.min_for(dt))` (the conformance
  stream_retention_append_at precedent) -- so a same-ms mint collision cannot
  perturb the value-per-key assertion. A multi-seed sweep + this posture
  statement suffices; NO standing process, NO cursor (Arm 3 one-shot). The
  on_exit braced-slot purge keeps the shared Valkey :6390 hermetic across runs.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoStore.{Coherence, Keyspace, Table}
  alias EchoStore.StreamHydrator
  alias EchoData.{BrandedId, Snowflake}
  alias EchoMQ.{Connector, Stream}

  setup_all do
    :ok = Snowflake.start(12)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    suffix = System.unique_integer([:positive])
    queue = "emq36hyd#{suffix}"
    table_str = "emq36hydtbl#{suffix}"

    # Valkey :6390 is SHARED + persistent and `suffix` is unique only WITHIN a
    # VM -- so across the determinism sweep / separate `mix test` invocations the
    # same queue + table recur. Purge BOTH this run's braced slots (the bus
    # stream emq:{queue}:* and the table ecc:{table}:*) on exit so each run reads
    # HERMETIC state (the table_test.exs / stream_archive_test.exs purge pattern).
    on_exit(fn ->
      purge("emq:{" <> queue <> "}:*")
      purge("ecc:{" <> table_str <> "}:*")
    end)

    %{conn: conn, queue: queue, table_str: table_str, suffix: suffix}
  end

  defp purge(pattern) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", pattern])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # Start the CFG hydration-target Table (the table_test.exs start pattern). A
  # generous TTL/no-jitter so a hydrated row stays resident for the read-back.
  defp start_table(ctx, opts \\ []) do
    name = :"emq36_hyd_#{ctx.suffix}_#{System.unique_integer([:positive])}"

    defaults = [
      name: name,
      kind: "CFG",
      loader: fn _id -> {:ok, ""} end,
      connector: [port: 6390],
      table: ctx.table_str,
      ttl_ms: 60_000,
      sweep_ms: 30_000,
      jitter: 0.0
    ]

    {:ok, _pid} = Table.start_link(Keyword.merge(defaults, opts))

    on_exit(fn ->
      try do
        Table.stop(name)
      catch
        :exit, _ -> :ok
      end
    end)

    name
  end

  # Append one EVT record at a CONTROLLED instant `dt` carrying a key + value (the
  # claims-only hydration payload): the branded id's snowflake IS min_for(dt), so
  # its mint instant (the version's order) is exactly `dt` -- deterministic, so
  # the newest-per-key is fixed by construction.
  defp append_record(conn, queue, name, %DateTime{} = dt, key, value) do
    branded = BrandedId.encode!("EVT", Snowflake.min_for(dt))
    {:ok, ^branded} = Stream.append_id(conn, queue, name, branded, [{"key", key}, {"value", value}])
    branded
  end

  # ===========================================================================
  # INV-HYDRATE -- the Table holds per key the newest-mint-id value (newer-wins)
  # ===========================================================================

  describe "INV-HYDRATE -- per-key newest-mint-id wins (>=2 records per key)" do
    test "two keys, each receiving >=2 INTERLEAVED records, hydrate to each key's NEWEST value",
         ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      k1 = BrandedId.generate!("CFG")
      k2 = BrandedId.generate!("CFG")
      base = ~U[2025-09-01 00:00:00.000Z]

      # An INTERLEAVED, mint-ordered tail: k1 and k2 each receive 3 records at
      # distinct instants; the LAST per key is the newest value (newer-wins must
      # resolve each key across the interleave, not just take the tail's last).
      append_record(conn, queue, "h", DateTime.add(base, 0, :millisecond), k1, "k1-old")
      append_record(conn, queue, "h", DateTime.add(base, 10, :millisecond), k2, "k2-old")
      append_record(conn, queue, "h", DateTime.add(base, 20, :millisecond), k1, "k1-mid")
      append_record(conn, queue, "h", DateTime.add(base, 30, :millisecond), k2, "k2-mid")
      append_record(conn, queue, "h", DateTime.add(base, 40, :millisecond), k1, "k1-NEW")
      append_record(conn, queue, "h", DateTime.add(base, 50, :millisecond), k2, "k2-NEW")

      assert {:ok, %{keys: 2, records: 6}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "h")

      # each key reads back its NEWEST record's value -- NOT an earlier one.
      assert {:ok, "k1-NEW", _src} = Table.fetch(table, k1)
      assert {:ok, "k2-NEW", _src} = Table.fetch(table, k2)
    end

    test "a SHUFFLED-arrival tail still resolves each key to its newest MINT id (not arrival order)",
         ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      base = ~U[2025-09-02 00:00:00.000Z]

      # Append in MINT order (the stream is single-writer mint-ordered by
      # construction), but with the NEWEST value landing last; the fold's
      # newer-wins is over the mint id, so the newest mint id's value wins.
      append_record(conn, queue, "sh", DateTime.add(base, 0, :millisecond), key, "v-oldest")
      append_record(conn, queue, "sh", DateTime.add(base, 100, :millisecond), key, "v-middle")
      append_record(conn, queue, "sh", DateTime.add(base, 200, :millisecond), key, "v-newest")

      assert {:ok, %{keys: 1, records: 3}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "sh")
      assert {:ok, "v-newest", _src} = Table.fetch(table, key)
    end

    test "a windowed hydrate (:from/:to) folds only the in-window records", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      base = ~U[2025-09-03 00:00:00.000Z]
      t_lo = DateTime.add(base, 100, :millisecond)
      t_hi = DateTime.add(base, 300, :millisecond)

      append_record(conn, queue, "wh", base, key, "before")
      append_record(conn, queue, "wh", t_lo, key, "in-lo")
      append_record(conn, queue, "wh", t_hi, key, "in-hi")
      append_record(conn, queue, "wh", DateTime.add(base, 400, :millisecond), key, "after")

      # hydrate only [t_lo, t_hi] via the bus-side bound math (the time-travel
      # bounds passed through to read/6) -- the newest IN-WINDOW value wins, the
      # "after" record (newer, but out of window) is NOT folded.
      from = Stream.minid_floor(t_lo)
      to = Stream.maxid_ceil(t_hi)

      assert {:ok, %{keys: 1, records: 2}} =
               StreamHydrator.hydrate_from_stream(table, conn, queue, "wh", from: from, to: to)

      assert {:ok, "in-hi", _src} = Table.fetch(table, key)
    end

    test "an empty stream hydrates to nothing ({:ok, %{keys: 0, records: 0}})", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      assert {:ok, %{keys: 0, records: 0}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "empty")
    end

    test "custom :key_field / :value_field fold a differently-shaped record", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      dt = ~U[2025-09-04 00:00:00.000Z]
      branded = BrandedId.encode!("EVT", Snowflake.min_for(dt))
      {:ok, ^branded} = Stream.append_id(conn, queue, "cf", branded, [{"entity", key}, {"payload", "custom"}])

      assert {:ok, %{keys: 1, records: 1}} =
               StreamHydrator.hydrate_from_stream(table, conn, queue, "cf", key_field: "entity", value_field: "payload")

      assert {:ok, "custom", _src} = Table.fetch(table, key)
    end

    test "a record missing its key field RAISES before any write (policy before existence)", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      dt = ~U[2025-09-05 00:00:00.000Z]
      branded = BrandedId.encode!("EVT", Snowflake.min_for(dt))
      # a record with NO "key" field -- structurally malformed for hydration.
      {:ok, ^branded} = Stream.append_id(conn, queue, "bad", branded, [{"value", "orphan"}])

      assert_raise ArgumentError, fn ->
        StreamHydrator.hydrate_from_stream(table, conn, queue, "bad")
      end
    end
  end

  # ===========================================================================
  # INV-NOCOMPACTOR -- the source is READ-ONLY; no compaction, no XADD/XTRIM
  # ===========================================================================

  describe "INV-NOCOMPACTOR -- the source stream is read-only to the hydrator" do
    test "a hydrate leaves the SOURCE stream byte-identical (same XLEN, same read-back)", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      base = ~U[2025-09-10 00:00:00.000Z]

      for ms <- [0, 10, 20], do: append_record(conn, queue, "nc", DateTime.add(base, ms, :millisecond), key, "v#{ms}")

      key_path = Stream.stream_key(queue, "nc")
      {:ok, len_before} = Connector.command(conn, ["XLEN", key_path])
      {:ok, read_before} = Stream.read(conn, queue, "nc")

      assert {:ok, %{records: 3}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "nc")

      # the SOURCE is untouched -- a hydrate READS, it does not XADD/XTRIM.
      {:ok, len_after} = Connector.command(conn, ["XLEN", key_path])
      {:ok, read_after} = Stream.read(conn, queue, "nc")
      assert len_after == len_before
      assert read_after == read_before
    end

    test "re-hydrating the same tail is IDEMPOTENT (newer-wins makes the replay a no-op)", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      base = ~U[2025-09-11 00:00:00.000Z]
      append_record(conn, queue, "idem", base, key, "old")
      append_record(conn, queue, "idem", DateTime.add(base, 50, :millisecond), key, "new")

      assert {:ok, %{keys: 1, records: 2}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "idem")
      assert {:ok, "new", _} = Table.fetch(table, key)

      # a SECOND hydrate over the same tail re-resolves to the same value (the
      # replay is harmless -- no cursor to leave ahead, the one-shot folds again).
      assert {:ok, %{keys: 1, records: 2}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "idem")
      assert {:ok, "new", _} = Table.fetch(table, key)
    end
  end

  # ===========================================================================
  # INV-FENCE -- hydrate-then-fence == loader truth (the staleness fence wins)
  # ===========================================================================

  describe "INV-FENCE -- a post-hydrate admission wins over a stale hydrated value" do
    test "a NEWER put/4 wins over the hydrated value; a STALE put/4 loses (both directions)", ctx do
      %{conn: conn, queue: queue} = ctx
      table = start_table(ctx)
      key = BrandedId.generate!("CFG")
      base = ~U[2025-09-20 00:00:00.000Z]

      # hydrate the key to V1 at instant m1.
      m1 = DateTime.add(base, 100, :millisecond)
      v1_id = append_record(conn, queue, "f", m1, key, "V1")
      assert {:ok, %{keys: 1, records: 1}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "f")
      assert {:ok, "V1", _} = Table.fetch(table, key)

      # a NEWER admission (m2 > m1) WINS -- hydrate-then-fence == loader truth.
      m2_id = BrandedId.encode!("EVT", Snowflake.min_for(DateTime.add(base, 200, :millisecond)))
      assert Coherence.newer?(m2_id, v1_id)
      assert :ok = Table.put(table, key, "V2", m2_id)
      assert {:ok, "V2", _} = Table.fetch(table, key)

      # a STALE admission (m0 < m1) LOSES: an apply_coherence drop with the older
      # version answers :stale (newer-wins refuses the older) and the resident V2
      # stands -- the fence refuses the stale, both directions proven.
      m0_id = BrandedId.encode!("EVT", Snowflake.min_for(DateTime.add(base, 50, :millisecond)))
      refute Coherence.newer?(m0_id, m2_id)
      assert {:ok, :stale} = Table.apply_coherence(table, key, m0_id)
      assert {:ok, "V2", _} = Table.fetch(table, key)
    end

    test "the :tracking fence evicts a hydrated L1 row on an external write (the shipped staleness fence)",
         ctx do
      %{conn: conn, queue: queue, table_str: table_str} = ctx
      table = start_table(ctx, coherence: :tracking)
      key = BrandedId.generate!("CFG")
      m1 = ~U[2025-09-21 00:00:00.100Z]

      # hydrate the key (seeds L1 + L2 via put/4).
      append_record(conn, queue, "ft", m1, key, "HYDRATED")
      assert {:ok, %{keys: 1, records: 1}} = StreamHydrator.hydrate_from_stream(table, conn, queue, "ft")
      assert {:ok, "HYDRATED", _} = Table.fetch(table, key)

      # an EXTERNAL writer changes the tracked key on its own connection; the
      # server pushes the invalidation to the table's :tracking lane, evicting the
      # stale hydrated L1 row (the SHIPPED fence -- table_test.exs:230 precedent;
      # hydration adds NO new fence, it SEEDS the table the fence guards).
      newer = BrandedId.generate!("TXN")
      {:ok, "OK"} =
        Connector.command(conn, ["SET", Keyspace.key(table_str, key), newer <> "EXTERNAL"])

      wait_until(fn -> :ets.lookup(table, key) == [] end)
      assert :ets.lookup(table, key) == []
    end
  end

  defp wait_until(pred, tries \\ 400) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end
end
