defmodule EchoStore.StreamArchive.Driver do
  @moduledoc """
  THE FOLD CONSUMER (emq3.5, S3 the memory part 1): the supervised, opt-in,
  store-side process that owns the **fold-THEN-trim** cycle for a declared
  archived stream. A `:transient` GenServer shell over the pure decision core
  `EchoStore.StreamArchive.Core` (the `EchoMQ.StreamRetention` cadence precedent,
  mirrored) -- but where `EchoMQ.StreamRetention` trims with NO fold, THIS driver
  FOLDS a slice durably into the native `EchoStore.Graft` engine BEFORE it trims
  the slice from the live stream.

  ## Fold-BEFORE-trim is the whole rung (INV1, the no-loss invariant)

  `XTRIM` returns only a removed-COUNT, never the deleted entries (F-2) -- so
  there is no recovery after a trim. The no-loss invariant is the ONE ordering
  the count-only trim makes the sole defense: a record is removed from the live
  stream ONLY AFTER it is committed to the engine and the watermark `W` has
  advanced past it. This driver enforces that ordering in ONE process by OWNING
  BOTH calls, on each tick, per archived stream:

    1. read the about-to-trim slice `(W, floor]` from the live stream via
       `EchoMQ.Stream.read/6` (mint order, the branded id recovered from the
       stored `id` field) -- the records the upcoming trim WOULD remove, above
       the current frontier;
    2. `EchoStore.StreamArchive.fold/3` it into the engine at `@archive_base`
       (`VolumeServer.commit/3`) and advance `W` to the highest-folded id;
    3. cache `W` to the bus seam `emq:{q}:stream:<name>:archived` (a polyglot
       reader's seam, never the source of truth) via `EchoMQ.Stream.put_archived/4`;
    4. ONLY THEN `EchoMQ.Stream.trim/4` the now-archived span.

  If the fold fails (a wire fault on the read, an engine conflict/error), the
  cycle ABORTS BEFORE the trim -- the slice stays on the live stream (over-
  retention, never loss; the safe direction), the next tick retries. No injected
  bus callback (EBV3-3): the invariant lives where the store can verify it.

  ## For an archived stream THIS driver IS the retention path (Arm 2)

  The bare emq3.4 `EchoMQ.StreamRetention` trim-only driver MUST NOT also run on
  an archived stream -- it would trim before the fold and lose the slice. THIS
  driver is the archived stream's retention path: it trims (after folding) to the
  SAME declared windows `EchoMQ.StreamRetention` would, so bounded memory and
  deep history coexist with no loss.

  ## Opt-in, owner-started (the library law)

  Like `EchoMQ.StreamRetention` / `EchoMQ.Pump`, this driver is opt-in: a
  deployment that wants a stream bounded-in-RAM-but-deep-in-history declares it
  here and starts the driver; a stream not declared is never folded or trimmed by
  it. A MANUAL `cycle/2` call is the equally-supported cadence (the driver is
  sugar over the cycle). The engine Volume must already be open
  (`EchoStore.Graft.open_volume/2`, under `EchoStore.Graft.Supervisor`); this
  driver folds into it, it does not own the Volume's lifecycle.

  ## Restart semantics

  A `:transient` child: a normal stop is final, a crash restarts the cadence
  whole. The fold is idempotent over `W` (a restart re-reads `(W, floor]`; an
  already-folded record is below `W` and not re-read), and the trim is idempotent
  over the stream, so a restart loses no history and over-deletes nothing.
  """

  use GenServer
  require Logger

  alias EchoMQ.{Connector, Stream}
  alias EchoStore.StreamArchive
  alias EchoStore.StreamArchive.Core

  @doc """
  A transient child: a normal stop is final, a crash restarts the cadence whole.
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      shutdown: 5_000
    }
  end

  @doc """
  Start the fold-then-trim driver. Options:

    * `:conn` (a connector this driver drives) or `:connector` (options to start
      one, linked);
    * `:policy` (a list of `{queue, name, volume_id, window}` declared archive
      policies -- `EchoStore.StreamArchive.Core` window forms; default `[]`, an
      empty policy ticks but folds/trims nothing);
    * `:tick_ms` (the beat, default 1_000);
    * `:name` (an optional registered name);
    * `:clock` (a 0-arity fn returning the `DateTime` for the tick instant,
      default `&DateTime.utc_now/0` -- injected so the decision core is a pure
      function of the clock in test).
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc "Stop the driver; the current tick settles, no further tick is scheduled."
  def stop(driver, timeout \\ 5_000), do: GenServer.stop(driver, :normal, timeout)

  @impl true
  def init(opts) do
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
      policy: Keyword.get(opts, :policy, []),
      tick_ms: tick_ms(opts),
      clock: Keyword.get(opts, :clock, &DateTime.utc_now/0)
    }

    {:ok, arm(state)}
  end

  @impl true
  def handle_info(:tick, s) do
    _ = sweep(s)
    {:noreply, arm(s)}
  end

  @doc """
  One sweep, exposed for a direct-drive test (no cadence): for each declared
  policy at the injected clock instant, run the fold-then-trim `cycle/2`. Answers
  `{:ok, %{folded: total_records, trimmed: total_removed, cycles: n}}`. An empty
  policy answers `{:ok, %{folded: 0, trimmed: 0, cycles: 0}}`.

  Each cycle is SOFT-matched -- a fold/wire fault on one stream is logged and the
  trim is SKIPPED for that stream this tick (the slice stays on the stream, the
  safe direction), never crash-looping the whole cadence; the next tick retries.
  """
  def sweep(%{conn: conn, policy: policy, clock: clock}) do
    case Core.decide(policy, clock.()) do
      :noop ->
        {:ok, %{folded: 0, trimmed: 0, cycles: 0}}

      plans when is_list(plans) ->
        acc0 = %{folded: 0, trimmed: 0, cycles: 0}

        result =
          Enum.reduce(plans, acc0, fn {queue, name, volume_id, window}, acc ->
            case cycle(conn, {queue, name, volume_id, window}) do
              {:ok, %{folded: f, trimmed: t}} ->
                %{acc | folded: acc.folded + f, trimmed: acc.trimmed + t, cycles: acc.cycles + 1}

              {:error, reason} ->
                Logger.warning(
                  "EchoStore.StreamArchive.Driver: cycle of #{inspect(queue)}/#{inspect(name)} " <>
                    "skipped this tick (no trim, slice kept): #{inspect(reason)}"
                )

                %{acc | cycles: acc.cycles + 1}
            end
          end)

        {:ok, result}
    end
  end

  @doc """
  ONE fold-then-trim cycle for one archived stream (INV1). The plan is
  `{queue, name, volume_id, resolved_window}` (a `EchoMQ.Stream.trim/4` window).
  Steps, in order, the trim LAST:

    1. compute the about-to-trim slice `(W, floor]` and read it via
       `EchoMQ.Stream.read/6` (mint order);
    2. fold it into the engine + advance `W` (`EchoStore.StreamArchive.fold/3`);
    3. cache `W` to the bus seam (`EchoMQ.Stream.put_archived/4`);
    4. `EchoMQ.Stream.trim/4` the now-archived span.

  Returns `{:ok, %{folded: n_records, trimmed: removed_count}}`, or
  `{:error, reason}` if ANY step before the trim fails (the trim is then NOT
  issued -- the slice stays, the safe direction). When the slice is empty
  (nothing new to fold), the trim still runs (to honor the declared window over
  already-folded entries) and `folded` is 0.

  `db` defaults to the Volume's live CubDB store, resolved from the engine's
  published `{:ctx, volume_id}` read context (`EchoStore.StreamArchive.store_for/1`).
  """
  @spec cycle(GenServer.server(), Core.plan(), GenServer.server() | nil) ::
          {:ok, %{folded: non_neg_integer(), trimmed: non_neg_integer()}} | {:error, term()}
  def cycle(conn, plan, db \\ nil)

  def cycle(conn, {queue, name, volume_id, window}, db) do
    db = db || StreamArchive.store_for(volume_id)

    with {:ok, slice} <- about_to_trim_slice(conn, queue, name, window, db),
         {:ok, folded} <- fold_slice(volume_id, slice, db),
         :ok <- cache_seam(conn, queue, name, db),
         {:ok, removed} <- Stream.trim(conn, queue, name, window) do
      {:ok, %{folded: folded, trimmed: removed}}
    else
      {:error, _} = err -> err
    end
  end

  # --- the slice the upcoming trim would remove, above the current frontier W ---

  # Read the records the declared `window`'s trim WOULD remove, that are ABOVE
  # the current frontier `W` -- exactly the slice to fold before the trim. Two
  # forms, mirroring `EchoMQ.Stream.trim/4`:
  #
  #   * `{:minid, dt, _}` -> the trim removes every entry minted strictly before
  #     `dt` (floor `"<ms>-0"`, `Stream.minid_floor/1`). The slice to fold is
  #     `(W, floor)` -- records above `W`, strictly below the MINID floor.
  #   * `{:maxlen, count, _}` -> the trim keeps the newest `count`. The slice to
  #     fold is everything ABOVE `W` that is NOT among the newest `count`
  #     (i.e. the older records the trim drops). Read full, drop the newest
  #     `count`, keep those above `W`.
  #
  # `from` is `(W` (exclusive of the frontier) when a seam exists, else `-`.
  defp about_to_trim_slice(conn, queue, name, {:minid, %DateTime{} = dt, _approx?}, db) do
    from = from_bound(db)
    # MINID floor "<ms>-0"; the trim drops strictly below it, so the fold slice
    # is `[from, floor)` -- read `[from, (floor-exclusive]` then drop the floor
    # row if present. XRANGE's end is inclusive; use an exclusive upper bound.
    floor = Stream.minid_floor(dt)
    to = "(" <> floor

    case Stream.read(conn, queue, name, from, to) do
      {:ok, slice} -> {:ok, slice}
      {:error, _} = err -> err
    end
  end

  defp about_to_trim_slice(conn, queue, name, {:maxlen, count, _approx?}, db)
       when is_integer(count) and count >= 0 do
    from = from_bound(db)

    case Stream.read(conn, queue, name, from, "+") do
      {:ok, above_w} ->
        # Of the records above W, the trim drops all but the newest `count` of
        # the WHOLE stream. The newest `count` are the tail; everything above W
        # except the last `count` is folded. Since `above_w` is mint-ordered and
        # the trim keeps the global newest `count`, dropping the last `count`
        # of `above_w` yields exactly the records both above W and below the
        # MAXLEN keep-window.
        n_drop = max(length(above_w) - count, 0)
        {:ok, Enum.take(above_w, n_drop)}

      {:error, _} = err ->
        err
    end
  end

  # The XRANGE `from` bound: strictly above the cached frontier `W` (the bus
  # seam, the store-side frontier's cache) when one exists, else `-` (the whole
  # stream). `(<xadd_id>` is XRANGE's exclusive lower bound.
  defp from_bound(db) do
    case StreamArchive.archive_frontier(db) do
      {:ok, w} ->
        {:ok, xadd_id} = EchoMQ.Stream.Id.xadd_id(w)
        "(" <> xadd_id

      :empty ->
        "-"
    end
  end

  # Fold the slice; an empty slice is a no-op (0 folded, W unchanged). A fold
  # error surfaces so the cycle aborts before the trim.
  defp fold_slice(volume_id, slice, db) do
    case StreamArchive.fold(volume_id, slice, db) do
      {:ok, _w} -> {:ok, length(slice)}
      :noop -> {:ok, 0}
      {:error, _} = err -> err
    end
  end

  # Cache the (now-advanced) frontier W to the bus seam for polyglot readers.
  # A cache miss/fault is non-fatal to the no-loss invariant (the engine frontier
  # is the source of truth) but DOES abort the cycle before the trim -- if the
  # bus is unreachable the trim should not run either (the same wire is down).
  defp cache_seam(conn, queue, name, db) do
    case StreamArchive.archive_frontier(db) do
      {:ok, w} ->
        case Stream.put_archived(conn, queue, name, w) do
          {:ok, _} -> :ok
          {:error, _} = err -> err
        end

      :empty ->
        # Nothing folded yet (an empty slice on a fresh stream); no seam to cache.
        :ok
    end
  end

  # The tick interval: a positive integer, or the default beat. A non-positive
  # tick is refused (the `EchoMQ.StreamRetention` rule).
  defp tick_ms(opts) do
    case Keyword.get(opts, :tick_ms, 1_000) do
      ms when is_integer(ms) and ms > 0 -> ms
      bad -> raise ArgumentError, "tick_ms must be a positive integer, got: #{inspect(bad)}"
    end
  end

  defp arm(s) do
    Process.send_after(self(), :tick, s.tick_ms)
    s
  end
end
