defmodule EchoStore.StreamArchive do
  @moduledoc """
  THE ARCHIVE (emq3.5, S3 the memory part 1): deep stream history without
  resident memory. A store-side fold of trimmed `EchoMQ.Stream` segments into
  the native `EchoStore.Graft` engine's CubDB (and, with `remote_cfg`, on to
  Tigris), readable beside the live tail through a merge-read split on an
  engine-derived watermark `W`.

  This module is the page-range LANDING + the `W` frontier reader + the
  merge-read — the pure (no-process) half. The supervised tick driver that runs
  the fold-then-trim cycle is `EchoStore.StreamArchive.Driver`; the no-loss
  ordering it enforces is documented there. Both fold via the engine's PUBLIC
  `EchoStore.Graft.VolumeServer.commit/3` (`volume_server.ex:50`) — the engine
  internals are UNTOUCHED (a NEW consumer of the public commit surface).

  ## The reserved page range (`@archive_base`, disjoint from business pages)

  The native `EchoStore.Graft` engine multiplexes one page axis: a business
  write commits its pages at caller-supplied LOW indices (a page per table row,
  counting up from 0 — `EchoStore.Graft.commit/3` stages `%{0 => p0, 1 => p1}`,
  `graft.ex:24`). The archive must never overwrite one of those, so each folded
  record lands as one CubDB page in a reserved HIGH range, `@archive_base + n`:

      @archive_base = :erlang.bsl(1, 49)   # 2^49, far above any realistic
                                           # business page count

  `2^49` sits ~563 trillion indices above the business-page floor, so a forward
  `:arc_seq` allocator (which counts `n` up from 0) can never reach a business
  page: the archive range `[2^49, ∞)` is DISJOINT from where real commits land
  by construction — no archive page index can ever overwrite a data page (the
  page axis is multiplexed; GC is indifferent to which range). A per-Volume
  atomic allocator (`:arc_seq`) hands out contiguous `n`; the n-th folded record
  lands at `@archive_base + n`.

  ## The payload + the order theorem

  Each archive page payload is `:erlang.term_to_binary({branded, fields})` — the
  record's 14-byte branded `EVT` id (the canonical receipt a polyglot reader
  recovers without re-encoding) plus its claims-only fields, the same
  one-page-carries-its-branded-receipt shape the engine commits everywhere. Because
  records fold in MINT ORDER (the writer mints monotone `EVT` ids and
  `EchoMQ.Stream.read/6` returns the slice in mint order — the order theorem,
  `EchoMQ.Stream.Id`), the page axis `@archive_base + 0, +1, …` is
  branded-id-monotone: a forward scan reads the archive oldest-first, a reverse
  scan newest-first, NO second index.

  ## The watermark `W` (a branded `EVT` id, NEVER `head_lsn`)

  `W` is the branded `EVT` id of the highest-folded record — persisted by the
  fold under `:arc_frontier` and read by `archive_frontier/1`. It is NOT the
  engine's integer `head_lsn` (`EchoStore.Graft.Store.head_lsn/1`,
  `store.ex:35`): that is the engine's page cursor (it addresses pages), the
  WRONG type to compare against a live-tail `EVT` id. The merge-read splits on
  `W`: records with branded id ≤ `W` come from the engine's `@archive_base`
  range; records with branded id > `W` come from the live stream via
  `EchoMQ.Stream.read/6`, the live tail (`W`'s `EchoMQ.Stream.Id.xadd_id/1` maps
  to the `XRANGE` lower bound). No-gap/no-overlap is a CONSEQUENCE of
  fold-before-trim (`EchoStore.StreamArchive.Driver`) + the order theorem, never
  a per-read boundary check.
  """

  alias EchoStore.Graft.{Store, VolumeServer}
  alias EchoData.BrandedId
  alias EchoMQ.Stream, as: MqStream
  alias EchoMQ.Stream.Id, as: StreamId

  # Reserved page range for archived stream records — a reserved HIGH range
  # (2^49) far above any realistic business page count, so the archive owns
  # `[2^49, ∞)` and a forward `:arc_seq` allocator (counting up from 0) can
  # never reach a business page (a data write commits at LOW indices). Disjoint
  # by construction; no archive page can overwrite a data page.
  @archive_base :erlang.bsl(1, 49)

  # The CubDB frontier keys the archive owns: the atomic page-index allocator
  # (`:arc_seq`) and the persisted branded-id watermark `W` (`:arc_frontier`).
  # Both are archive-private keys, disjoint from any other Volume bookkeeping.
  @seq_key :arc_seq
  @frontier_key :arc_frontier

  @typedoc "An archive merge-read entry: the branded `EVT` id and its claims-only fields map."
  @type entry :: {binary(), map()}

  @doc "The reserved high page range for archived records (disjoint from business pages)."
  @spec archive_base() :: non_neg_integer()
  def archive_base, do: @archive_base

  @doc """
  Folds a mint-ordered slice of `{branded, fields}` records into the Volume at
  the `@archive_base` range — one CubDB page per record at `@archive_base + n` —
  through the PUBLIC `VolumeServer.commit/3`, and advances the persisted
  watermark `W` to the branded `EVT` id of the highest-folded record.

  Each record's branded id is asserted to be a well-formed `EVT` id before the
  fold (the kind discipline, mirroring the writer's door); the slice MUST be in
  mint order (the caller — the slice comes from `EchoMQ.Stream.read/6`, which
  returns mint order). Returns `{:ok, W}` (the new frontier, the highest folded
  id), `:noop` for an empty slice (nothing to fold, `W` unchanged), or the
  engine's `{:error, {:conflict, head}} | {:error, term}` verbatim (a conflict
  retries upstream, re-`begin/1`-ing for the new head — the `record/4`
  precedent; on any fold error the caller does NOT trim, the safe direction).

  Durability ordering (R-1): the page-index seq `:arc_seq` and the frontier `W`
  advance ONLY in the commit-success branch — `:arc_seq` is PEEKED (read, not
  advanced) before the commit and advanced after, so a commit error leaves both
  untouched. This keeps `folded_count == committed-record-count` (a failed fold
  never leaves the count ahead of the pages, which would make `read_archive/2`
  read an `:absent` index). The OCC commit serializes concurrent folds at the
  same base — only one lands, the other conflicts and retries.

  `db` is the Volume's live CubDB store (`store_for/1` resolves it from the
  engine's published `{:ctx, volume_id}` read context).
  """
  @spec fold(BrandedId.t(), [entry()], GenServer.server()) ::
          {:ok, binary()} | :noop | {:error, term()}
  def fold(volume_id, slice, db \\ nil)

  def fold(_volume_id, [], _db), do: :noop

  def fold(volume_id, [_ | _] = slice, db) when is_binary(volume_id) do
    db = db || store_for(volume_id)
    :ok = assert_evt_slice!(slice)

    # PEEK the seq (read, do NOT advance) to compute the page indices; the
    # advance is conditional-on-commit below. The folded_count invariant
    # (folded_count == committed-record-count) requires :arc_seq to move ONLY
    # when the pages actually land — else a commit error leaves :arc_seq ahead
    # of the committed pages and read_archive reads an :absent index (R-1).
    base_n = peek_seq(db)
    n = length(slice)

    {staged, last_branded} =
      slice
      |> Enum.with_index(base_n)
      |> Enum.reduce({%{}, nil}, fn {{branded, fields}, idx}, {pages, _prev} ->
        page = :erlang.term_to_binary({branded, fields})
        {Map.put(pages, @archive_base + idx, page), branded}
      end)

    {:ok, base} = VolumeServer.begin(volume_id)

    case VolumeServer.commit(volume_id, base, staged) do
      {:ok, _lsn} ->
        # The pages are durable: NOW advance :arc_seq (by the count just
        # committed, guarded against a concurrent fold that already advanced it)
        # and the frontier W, together. On a commit error this branch is skipped
        # so :arc_seq is untouched (the conflicting fold retries with a fresh
        # base; OCC guarantees only one fold's pages land at this base).
        commit_seq(db, base_n, n)
        advance_frontier(db, last_branded)
        {:ok, last_branded}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  The archive frontier `W` — the branded `EVT` id of the highest-folded record,
  or `:empty` for a Volume with nothing folded yet (the merge-read then reads
  the whole stream live — no archive seam). A 14-byte branded `EVT` id, NEVER
  the integer `head_lsn` (`store.ex:35`, the engine's page cursor — the WRONG
  type for the merge split).
  """
  @spec archive_frontier(GenServer.server()) :: {:ok, binary()} | :empty
  def archive_frontier(db) do
    case CubDB.get(db, @frontier_key, nil) do
      w when is_binary(w) -> {:ok, w}
      nil -> :empty
    end
  end

  @doc """
  Reads the folded records back from the engine's `@archive_base` range, in mint
  order (a forward scan — the order theorem). Returns `{:ok, [{branded, fields}]}`
  oldest-first. Enumerates `@archive_base + 0 .. @archive_base + (count - 1)`
  over the PUBLIC `read_at/3` against a populated `Store.index_at/3` snapshot
  (NOT `VolumeServer.snapshot/1`, whose index defaults to empty) — never an
  engine-internal edit (INV8). `count` is the number of records folded
  (`folded_count/1`).

  `commit_seq/3` keeps `:arc_seq` == the committed-page count (the R-1 fix), so
  every enumerated index is present; a missing index is nonetheless SKIPPED
  rather than crashing the read (belt-and-suspenders — a crash between commit and
  the seq advance can only leave the seq BEHIND the pages, an under-count that
  self-heals on the next fold; the archive never becomes unreadable).
  """
  @spec read_archive(BrandedId.t(), GenServer.server()) :: {:ok, [entry()]}
  def read_archive(volume_id, db) when is_binary(volume_id) do
    count = folded_count(db)
    head = Store.head_lsn(db)
    snap = Store.index_at(db, volume_id, head)

    entries =
      for n <- 0..(count - 1)//1,
          count > 0,
          {:ok, bin} <- [EchoStore.Graft.read_at(volume_id, snap, @archive_base + n)] do
        :erlang.binary_to_term(bin)
      end

    {:ok, entries}
  end

  @doc """
  THE MERGE-READ (INV3): archived ∪ live-tail for a stream, split on `W`. Records
  with branded id ≤ `W` come from the engine's `@archive_base` range; records
  with branded id > `W` come from the live stream via `EchoMQ.Stream.read/6`
  (the `XRANGE` lower bound = `W`'s `xadd_id`, exclusive via the `(` prefix). The
  union is in mint order (the archive is oldest-first, the live tail follows).

  When `W` is `:empty` (nothing folded), the whole stream is read live (no
  archive seam). No-gap/no-overlap is a CONSEQUENCE of fold-before-trim + the
  order theorem (the `Driver`'s invariant), not a per-read check.

  Returns `{:ok, [{branded, fields}]}` or surfaces a live-read `{:error, term}`
  verbatim.
  """
  @spec merge_read(GenServer.server(), binary(), binary(), BrandedId.t(), GenServer.server()) ::
          {:ok, [entry()]} | {:error, term()}
  def merge_read(conn, queue, name, volume_id, db)
      when is_binary(queue) and is_binary(name) and is_binary(volume_id) do
    case archive_frontier(db) do
      :empty ->
        # Nothing folded: the whole stream is the live tail.
        MqStream.read(conn, queue, name)

      {:ok, w} ->
        {:ok, archived} = read_archive(volume_id, db)
        from = "(" <> w_bound(w)

        case MqStream.read(conn, queue, name, from, "+") do
          {:ok, live} -> {:ok, archived ++ live}
          {:error, _} = err -> err
        end
    end
  end

  @doc """
  How many records have been COMMITTED to the Volume's archive (`:arc_seq`, the
  count `read_archive/2` enumerates). `:arc_seq` advances only after a successful
  commit (`commit_seq/3`), so this equals the number of durable archive pages —
  a failed fold never inflates it past the committed pages (R-1).
  """
  @spec folded_count(GenServer.server()) :: non_neg_integer()
  def folded_count(db), do: CubDB.get(db, @seq_key, 0)

  @doc """
  The live CubDB store handle for an open Volume — the `:db` pid the engine
  publishes in its lock-free read context under `{:ctx, volume_id}`
  (`EchoStore.Graft.VolumeServer` init, the same context `EchoStore.Graft.Reader`
  resolves). Raises if no Volume is open for `volume_id`.
  """
  @spec store_for(BrandedId.t()) :: GenServer.server()
  def store_for(volume_id) do
    case Registry.lookup(EchoStore.Graft.Registry, {:ctx, volume_id}) do
      [{_pid, %{db: db}}] -> db
      [] -> raise ArgumentError, "no open Volume #{inspect(volume_id)}"
    end
  end

  # -- internals --------------------------------------------------------------

  # The XRANGE lower bound for a branded `EVT` watermark `W`: its A1 xadd id
  # ("<ms>-<tail22>"), so a `(<bound>` exclusive XRANGE reads strictly above `W`.
  defp w_bound(w) do
    {:ok, xadd_id} = StreamId.xadd_id(w)
    xadd_id
  end

  # PEEK the next free page-index base — a READ, no advance. The n-th record of
  # this fold lands at `@archive_base + base_n + i`. The seq advances only AFTER
  # the commit succeeds (`commit_seq/3`), so a failed commit never leaves
  # `:arc_seq` ahead of the committed pages (the R-1 fix).
  defp peek_seq(db), do: CubDB.get(db, @seq_key, 0)

  # Advance `:arc_seq` to cover the just-committed batch — called ONLY in the
  # commit-success branch. Atomic + monotone: a concurrent fold that committed
  # first (winning the OCC race at the same `base_n`) may already have advanced
  # the seq past `base_n + n`, so never regress (`max`). Because the OCC commit
  # lets only ONE fold's pages land at a given base, the committed pages occupy a
  # contiguous prefix `0..arc_seq-1`, so `folded_count == committed-record-count`
  # holds — what `read_archive/2` enumerates.
  defp commit_seq(db, base_n, n) do
    target = base_n + n

    CubDB.transaction(db, fn tx ->
      cur = CubDB.Tx.get(tx, @seq_key, 0)
      {:commit, CubDB.Tx.put(tx, @seq_key, max(cur, target)), :ok}
    end)
  end

  # Advance the persisted watermark `W` to `branded` (the highest-folded id).
  # Monotone by construction (records fold in mint order, so a later fold's
  # last id always exceeds the prior); a defensive `max` keeps it monotone even
  # if a caller folds out of order (it must not, but the frontier never regresses).
  defp advance_frontier(db, branded) do
    case CubDB.get(db, @frontier_key, nil) do
      cur when is_binary(cur) ->
        if id_gt?(branded, cur), do: CubDB.put(db, @frontier_key, branded), else: :ok

      nil ->
        CubDB.put(db, @frontier_key, branded)
    end
  end

  # Branded-id comparison by snowflake (one namespace — `EVT` — so byte order ==
  # snowflake order; this compares the decoded snowflake for safety across the
  # 14-byte fixed-width form). a > b.
  defp id_gt?(a, b) do
    case {BrandedId.parse(a), BrandedId.parse(b)} do
      {{:ok, _ns_a, sa}, {:ok, _ns_b, sb}} -> sa > sb
      _ -> a > b
    end
  end

  # Every record in the slice must be a well-formed `EVT` branded id — the kind
  # discipline (the writer's door, `EchoMQ.Stream.Id.evt?/1`). A foreign brand
  # in the archive would break the order theorem's "one namespace" premise.
  defp assert_evt_slice!(slice) do
    Enum.each(slice, fn {branded, _fields} ->
      unless is_binary(branded) and StreamId.evt?(branded) do
        raise ArgumentError,
              "EchoStore.StreamArchive folds EVT records only; got: #{inspect(branded)}"
      end
    end)
  end
end
