defmodule EchoMQ.Dashboard do
  @moduledoc """
  A cat-able ANSI operator dashboard for the bus — read-only over the live
  Valkey-native queue. The sibling of `mix echo_mq.stories`: operator tooling,
  not a bus surface. Every read is grounded in the as-built `EchoMQ.Metrics`
  pure-read plane (`metrics.ex`) — this module reimplements no read, opens no
  new wire, and writes nothing.

  Two halves, split so the rendering is testable WITHOUT Valkey:

    * the PURE renderer (`render_depths/2`, `render_lanes/2`, `render_job/4`,
      `render_no_queues/1`, `frame/2`) — metrics maps → ANSI strings. A pure
      function of its arguments; the timestamp is passed IN (never read from the
      clock here), so a fixture map renders identically every run.
    * the live-fetch orchestration (`discover_queues/1`, `fetch_depths/2`,
      `groups_for/2`, `fetch_lanes/2`, `fetch_job/3`) — the `Connector` round
      trips that turn a live connection into those maps, each delegating to the
      grounded `Metrics`/`Keyspace`/`Connector` surface.

  The state palette matches the house trackers (`docs/echo_mq/emq.progress.md`,
  `docs/graft/graft.progress.md`): a boxed cyan header, magenta `▌` section
  markers, and a per-state colour (pending cyan · active yellow · schedule blue
  · dead/failed red · completed green · zero/labels grey).
  """

  alias EchoMQ.{Connector, Keyspace, Metrics}

  # The six state columns the depths panel reports, in display order. The four
  # set states + the two metric counters — EXACTLY the closed set
  # `EchoMQ.Metrics.get_counts/3` answers (metrics.ex @set_states/@metric_states,
  # `~w(pending active schedule dead completed failed)`). NB the wire name is
  # "schedule" (the set), distinct from the `:scheduled` atom `get_job_state/3`
  # returns — both honored as-built (metrics.ex:23/146), never "fixed".
  @states ~w(pending active schedule dead completed failed)

  # -- ANSI vocabulary ------------------------------------------------------

  @reset "\e[0m"
  @cyan_b "\e[1;36m"
  @magenta_b "\e[1;35m"
  @dim "\e[2m"
  @grey "\e[90m"
  @bold "\e[1m"

  # The per-state colour. Zero counts dim to @grey at render time regardless;
  # this table is the non-zero ink.
  @state_color %{
    "pending" => "\e[36m",
    "active" => "\e[33m",
    "schedule" => "\e[34m",
    "dead" => "\e[31m",
    "completed" => "\e[32m",
    "failed" => "\e[31m"
  }

  # The colour for each `get_job_state/3` atom (metrics.ex:146 closed set).
  @job_state_color %{
    pending: "\e[36m",
    active: "\e[33m",
    scheduled: "\e[34m",
    dead: "\e[31m",
    awaiting_children: "\e[35m",
    unknown: "\e[90m",
    absent: "\e[90m"
  }

  @col 9
  @payload_max 60

  @doc "The six state columns, in display order (the `get_counts/3` closed set)."
  @spec states() :: [binary()]
  def states, do: @states

  # ========================================================================
  # The PURE renderer — metrics maps → ANSI strings. No Valkey, no clock.
  # ========================================================================

  @doc """
  The boxed cyan header (the house `╔══╗`/`║`/`╚╝` frame), with a title line and
  a dim subtitle. Pure.
  """
  @spec frame(binary(), binary()) :: iodata()
  def frame(title, subtitle) do
    width = 70
    bar = String.duplicate("═", width)
    [
      @cyan_b,
      "╔",
      bar,
      "╗\n",
      "║  ",
      pad_visible(title, width - 4),
      "║\n",
      "║  ",
      @reset,
      @dim,
      pad_visible(subtitle, width - 4),
      @cyan_b,
      "║\n",
      "╚",
      bar,
      "╝",
      @reset,
      "\n"
    ]
  end

  @doc """
  The depths panel: the boxed header + one aligned row of the six state counts
  per queue. `per_queue` is a list of `{queue, result}` where `result` is the
  `{:ok, counts_map}` | `{:error, reason}` each `fetch_depths/2` produced — a
  `{:error, _}` queue is surfaced in red, NEVER rendered as a confident zero
  (the named-partial law). `stamp` is the timestamp string, passed in. Pure.
  """
  @spec render_depths([{binary(), term()}], binary()) :: iodata()
  def render_depths(per_queue, stamp) when is_list(per_queue) do
    [
      frame("EchoMQ · queue depths", "read-only · #{length(per_queue)} queue(s) · #{stamp}"),
      "\n",
      section("DEPTHS"),
      header_row(),
      Enum.map(per_queue, &depth_row/1),
      legend_line()
    ]
  end

  defp header_row do
    cells = Enum.map(@states, &cell(&1, @grey))
    ["  ", pad_visible("#{@grey}queue#{@reset}", 26), cells, "\n"]
  end

  defp depth_row({queue, {:ok, counts}}) when is_map(counts) do
    cells =
      Enum.map(@states, fn st ->
        n = Map.get(counts, st, 0)
        color = if n == 0, do: @grey, else: Map.fetch!(@state_color, st)
        cell(Integer.to_string(n), color)
      end)

    ["  ", pad_visible("#{@bold}#{queue}#{@reset}", 26), cells, "\n"]
  end

  defp depth_row({queue, {:error, reason}}) do
    [
      "  ",
      pad_visible("#{@bold}#{queue}#{@reset}", 26),
      "\e[31m! read error: ",
      inspect(reason),
      @reset,
      "\n"
    ]
  end

  @doc """
  An optional per-queue lane sub-panel: pending depth behind each group with
  in-flight work. `per_queue` is a list of `{queue, result}` where `result` is
  `{:ok, depths_map}` | `{:error, reason}` | `:none` (no groups discovered —
  named, not faked). Pure. Honest limit: lanes are discovered via the `gactive`
  hash (groups with ACTIVE claims), so a group with only PENDING work and no
  active lease is invisible to this panel.
  """
  @spec render_lanes([{binary(), term()}], binary()) :: iodata()
  def render_lanes(per_queue, _stamp) when is_list(per_queue) do
    rows =
      Enum.map(per_queue, fn
        {_queue, :none} ->
          []

        {queue, {:ok, depths}} when map_size(depths) == 0 ->
          ["  #{@bold}#{queue}#{@reset} #{@grey}— no active lanes#{@reset}\n"]

        {queue, {:ok, depths}} ->
          [
            "  #{@bold}#{queue}#{@reset}\n",
            Enum.map(Enum.sort(depths), fn {g, d} ->
              color = if d == 0, do: @grey, else: "\e[36m"
              ["    #{@grey}↳#{@reset} ", pad_visible(g, 18), cell(Integer.to_string(d), color), "\n"]
            end)
          ]

        {queue, {:error, reason}} ->
          ["  #{@bold}#{queue}#{@reset} \e[31m! lane read error: #{inspect(reason)}#{@reset}\n"]
      end)
      |> Enum.reject(&(&1 == []))

    case rows do
      [] -> []
      _ -> [section("LANES (active groups · pending depth)"), rows]
    end
  end

  @doc """
  The inspection panel for one job: the id, its `get_job_state/3` atom (colored),
  attempts, and a truncated payload. `state_result` is what `fetch_job/3`
  produced — `{:ok, %{state, atom, attempts, payload}}` | `:absent` |
  `{:error, reason}`; each NAMED, never faked. `stamp` passed in. Pure.
  """
  @spec render_job(binary(), binary(), term(), binary()) :: iodata()
  def render_job(queue, job_id, result, stamp) do
    head = frame("EchoMQ · job inspection", "read-only · queue #{queue} · #{stamp}")
    body = job_body(queue, job_id, result)
    [head, "\n", section("JOB"), body]
  end

  defp job_body(_queue, job_id, {:error, {:invalid_job_id, _}}) do
    "  \e[31m! #{job_id} is not a valid branded id (a job id is a 14-byte branded snowflake, e.g. JOB…)#{@reset}\n"
  end

  defp job_body(queue, job_id, :absent) do
    "  #{@grey}job #{job_id} not found in queue #{queue}#{@reset}\n"
  end

  defp job_body(_queue, job_id, {:error, reason}) do
    "  \e[31m! read error for #{job_id}: #{inspect(reason)}#{@reset}\n"
  end

  defp job_body(_queue, job_id, {:ok, info}) do
    state = Map.get(info, :state, :unknown)
    color = Map.get(@job_state_color, state, @grey)
    attempts = Map.get(info, :attempts, "0")
    payload = Map.get(info, :payload, "")

    [
      field("id", "#{@bold}#{job_id}#{@reset}"),
      field("state", "#{color}#{state}#{@reset}"),
      field("attempts", "#{attempts}"),
      field("payload", "#{truncate(payload, @payload_max)}")
    ]
  end

  @doc """
  The named empty case: no `emq:*` keys, so no queue is visible to SCAN. Printed
  instead of a confident-but-empty table. Pure.
  """
  @spec render_no_queues(binary()) :: iodata()
  def render_no_queues(stamp) do
    [
      frame("EchoMQ · queue depths", "read-only · #{stamp}"),
      "\n",
      section("DEPTHS"),
      "  #{@grey}no keyed queues found (the bus has no `emq:*` keys — ",
      "an empty queue is invisible to SCAN).#{@reset}\n"
    ]
  end

  # -- pure render helpers --------------------------------------------------

  defp section(label), do: "#{@magenta_b}▌ #{label}#{@reset}\n"

  defp field(label, value), do: ["  #{@grey}", pad_visible(label, 12), "#{@reset}", value, "\n"]

  defp cell(text, color), do: [pad_visible("#{color}#{text}#{@reset}", @col)]

  defp legend_line do
    [
      "\n  ",
      @dim,
      "legend: ",
      @reset,
      Enum.map(@states, fn st ->
        "#{Map.fetch!(@state_color, st)}#{st}#{@reset} "
      end),
      @grey,
      "· zero dimmed",
      @reset,
      "\n"
    ]
  end

  # Pad to a VISIBLE width, ignoring ANSI escape sequences (so colored cells
  # still align). Truncation of the visible text is left to the caller.
  defp pad_visible(str, width) do
    str = IO.iodata_to_binary(str)
    visible = visible_length(str)
    pad = max(width - visible, 0)
    [str, String.duplicate(" ", pad)]
  end

  defp visible_length(str) do
    str
    |> String.replace(~r/\e\[[0-9;]*m/, "")
    |> String.length()
  end

  defp truncate(str, max) when is_binary(str) do
    if String.length(str) > max, do: String.slice(str, 0, max) <> "…", else: str
  end

  defp truncate(other, _max), do: inspect(other)

  # ========================================================================
  # The live-fetch orchestration — Connector round trips → the maps above.
  # ========================================================================

  @doc """
  Best-effort queue discovery: there is no queue registry, so loop `SCAN
  emq:* COUNT 500` from cursor "0" until the cursor returns "0", collect the
  keys, map each through `Keyspace.hashtag/1` (the `{q}` slot), `uniq`, and
  EXCLUDE the reserved `"emq"` slot (`{emq}:version`, the fence — keyspace.ex).
  An empty queue (no keys) is invisible — acceptable, named by the caller.
  Returns `{:ok, [queue]}` | `{:error, reason}`.
  """
  @spec discover_queues(GenServer.server()) :: {:ok, [binary()]} | {:error, term()}
  def discover_queues(conn) do
    case scan_loop(conn, "0", []) do
      {:ok, keys} ->
        queues =
          keys
          |> Enum.map(&Keyspace.hashtag/1)
          |> Enum.reject(&(&1 == "emq"))
          |> Enum.uniq()
          |> Enum.sort()

        {:ok, queues}

      {:error, _} = err ->
        err
    end
  end

  # SCAN reply (probed live, RESP3): {:ok, [cursor_binary, [keys]]}. Loop until
  # the cursor returns to "0". A non-"0" cursor that never returns is bounded by
  # the keyspace size — this is operator tooling over a finite bus.
  defp scan_loop(conn, cursor, acc) do
    case Connector.command(conn, ["SCAN", cursor, "MATCH", "emq:*", "COUNT", "500"]) do
      {:ok, [next, keys]} when is_binary(next) and is_list(keys) ->
        acc = keys ++ acc
        if next == "0", do: {:ok, acc}, else: scan_loop(conn, next, acc)

      {:error, _} = err ->
        err

      other ->
        {:error, {:unexpected_scan_reply, other}}
    end
  end

  @doc """
  The six state counts for one queue, delegating to `Metrics.get_counts/3` over
  the closed `@states` set. Returns the `{:ok, counts_map}` | `{:error, reason}`
  the renderer surfaces verbatim.
  """
  @spec fetch_depths(GenServer.server(), binary()) ::
          {:ok, %{binary() => non_neg_integer()}} | {:error, term()}
  def fetch_depths(conn, queue), do: Metrics.get_counts(conn, queue, @states)

  @doc """
  The groups with in-flight work for one queue: `HKEYS emq:{q}:gactive`, then
  filter to valid branded ids (`EchoData.BrandedId.valid?/1` — `lane_depths/3`
  RAISES on an invalid one, metrics.ex:299, so the filter is mandatory). Returns
  `{:ok, [group]}` | `{:error, reason}`. Honest limit: `gactive` carries only
  groups with an ACTIVE claim (lanes.ex HINCRBY at claim), so a pending-only
  group is not discovered here.
  """
  @spec groups_for(GenServer.server(), binary()) :: {:ok, [binary()]} | {:error, term()}
  def groups_for(conn, queue) do
    case Connector.command(conn, ["HKEYS", Keyspace.queue_key(queue, "gactive")]) do
      {:ok, keys} when is_list(keys) ->
        {:ok, Enum.filter(keys, &EchoData.BrandedId.valid?/1)}

      {:error, _} = err ->
        err

      other ->
        {:error, {:unexpected_hkeys_reply, other}}
    end
  end

  @doc """
  The lane depths for one queue: discover the active groups, then
  `Metrics.lane_depths/3`. Returns `{:ok, depths_map}` | `{:error, reason}` |
  `:none` (no active groups — named, not an empty map masquerading).
  """
  @spec fetch_lanes(GenServer.server(), binary()) ::
          {:ok, %{binary() => non_neg_integer()}} | {:error, term()} | :none
  def fetch_lanes(conn, queue) do
    case groups_for(conn, queue) do
      {:ok, []} -> :none
      {:ok, groups} -> Metrics.lane_depths(conn, queue, groups)
      {:error, _} = err -> err
    end
  end

  @doc """
  The inspection payload for one job: `get_job/3` (state/attempts/payload row)
  reconciled with `get_job_state/3` (the authoritative set-membership atom).
  Returns `{:ok, %{state, attempts, payload}}` | `:absent` | `{:error, reason}`.
  The `state` atom comes from `get_job_state/3` (it knows `:scheduled`/
  `:awaiting_children`/`:unknown` the row's own string field does not), the
  attempts/payload from the row.
  """
  @spec fetch_job(GenServer.server(), binary(), binary()) ::
          {:ok, %{state: atom(), attempts: binary(), payload: binary()}}
          | :absent
          | {:error, term()}
  def fetch_job(conn, queue, job_id) do
    # an operator-typed --job can be malformed; the gated key builder
    # (Keyspace.job_key/2) RAISES on a non-branded id, so validate FIRST and
    # name the bad input as a typed error rather than let the read crash the
    # task (the named-partial law). A well-formed id flows through unchanged.
    if EchoData.BrandedId.valid?(job_id) do
      do_fetch_job(conn, queue, job_id)
    else
      {:error, {:invalid_job_id, job_id}}
    end
  end

  defp do_fetch_job(conn, queue, job_id) do
    case Metrics.get_job(conn, queue, job_id) do
      :absent ->
        :absent

      {:ok, row} when is_map(row) ->
        state =
          case Metrics.get_job_state(conn, queue, job_id) do
            {:ok, atom} -> atom
            _ -> :unknown
          end

        {:ok,
         %{
           state: state,
           attempts: Map.get(row, "attempts", "0"),
           payload: Map.get(row, "payload", "")
         }}

      {:error, _} = err ->
        err

      other ->
        {:error, {:unexpected_get_job_reply, other}}
    end
  end
end
