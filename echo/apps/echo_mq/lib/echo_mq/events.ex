defmodule EchoMQ.Events do
  @moduledoc """
  The per-queue event stream: a subscription surface over the bus's lifecycle
  events (completed/failed/scheduled/progress/stalled/…) so a consumer reacts
  to work as it happens without polling the sets (the v1 `EchoMQ.QueueEvents`
  capability re-derived). emq.2.3-D2.

  Rides the EXISTING connector pub/sub seam -- it subscribes ONCE to the
  per-queue events channel `emq:{q}:events` (`EchoMQ.Connector.subscribe/2`,
  the `{:emq_push, …}` push, the emq.1 resubscribe `MapSet` that keeps the feed
  live across a reconnect) and dispatches each message on the cjson payload's
  `event` field. **No new transport, no `SSUBSCRIBE`** (design §12.3 defers
  sharded pub/sub to the cache rung; the durable replayable stream is emq3.2).

  The channel + the cjson `{"event": …, "job": …, …}` payload shape are the
  emq.2.2 `update_progress` D-5 seam (jobs.ex `@update_progress` already
  PUBLISHes `progress` here). The OTHER lifecycle events are published
  HOST-SIDE by `publish/3` after a transition's verdict (the recommended D1
  placement -- the byte-frozen transition scripts stay byte-unchanged). The
  payload is read by substring on the raw cjson string (the as-built
  convention -- cjson key order is not guaranteed; the bus carries no JSON
  dependency, so the raw string is delivered and `event_name/1` extracts the
  name by scan, not by a parser).

  Delivery, two ways (the v1 parity surface):
  - **subscriber pids** -- `subscribe/2` registers a pid that receives
    `{:emq_event, event_name, raw_payload}` for every event (the v1
    `{:echomq_event, …}` re-rooted).
  - **a handler module** -- an optional `:handler` implementing the
    `handle_event/3` behaviour, invoked per event with the handler state.

  The push channel is fire-and-forget (at-most-once): a PUBLISH with no live
  subscriber, or one issued in the window between a socket drop and the
  resubscribe, is lost. The emq.1 resubscribe is the mitigation (a reconnect
  re-issues the SUBSCRIBE); the durable replayable receipt is emq3.2's
  `EchoMQ.Stream`, not this. Stated, not papered over (design §12.3).
  """

  use GenServer

  alias EchoMQ.{Connector, Keyspace}

  @doc """
  The `handle_event/3` behaviour a `:handler` module implements: invoked per
  lifecycle event with the event name (an atom -- e.g. `:completed`), the raw
  cjson payload string, and the handler's state; answers `{:ok, new_state}`.
  Mirrors the v1 `EchoMQ.QueueEvents` behaviour.
  """
  @callback handle_event(event :: atom(), payload :: binary(), state :: term()) ::
              {:ok, state :: term()}

  @doc """
  `use EchoMQ.Events` to derive a default `handle_event/3` (a no-op that keeps
  the state) -- override only the events of interest (the v1 `__using__`
  convenience).
  """
  defmacro __using__(_opts) do
    quote do
      @behaviour EchoMQ.Events

      @impl EchoMQ.Events
      def handle_event(_event, _payload, state), do: {:ok, state}

      defoverridable handle_event: 3
    end
  end

  @doc """
  Start the event listener for `queue`. Options: `:conn` (a RESP3 connector
  this listener subscribes on -- it MUST be `protocol: 3` and `push_to` this
  process) or `:connector` (options to start one, linked, RESP3 + `push_to`
  set); `:queue`; `:handler` (an optional `handle_event/3` module);
  `:handler_state` (the initial handler state); `:name` (an optional registered
  name). On start it subscribes once to `emq:{q}:events`. emq.2.3-D2.
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Register `pid` to receive every lifecycle event as
  `{:emq_event, event_name, raw_payload}` (the v1 `subscribe/2`, re-rooted).
  Idempotent. Defaults to the caller.
  """
  def subscribe(server, pid \\ self()) do
    GenServer.call(server, {:subscribe, pid})
  end

  @doc "Stop delivering events to `pid` (the v1 `unsubscribe/2`). Defaults to the caller."
  def unsubscribe(server, pid \\ self()) do
    GenServer.call(server, {:unsubscribe, pid})
  end

  @doc "Close the listener: unsubscribe the channel and stop (the v1 `close/1`)."
  def close(server, timeout \\ 5_000) do
    GenServer.stop(server, :normal, timeout)
  end

  @doc """
  The per-queue events channel `emq:{q}:events` -- the `queue_key` suffix the
  inherited `@update_progress` seam already PUBLISHes on (§6-spelled; a pub/sub
  channel, not a slot-routed key, so no new §6 key type). emq.2.3-D2.
  """
  def channel(queue), do: Keyspace.queue_key(queue, "events")

  @doc """
  Publish a lifecycle event HOST-SIDE after a transition's verdict: PUBLISH the
  cjson `{"event": "<name>", "job": "<id>", …}` object on `emq:{q}:events` (the
  recommended D1 placement -- the byte-frozen transition scripts stay
  byte-unchanged). `extra` is a keyword/map of additional flat string fields
  (e.g. `[progress: "50"]`). Best-effort (fire-and-forget); a publish with no
  live subscriber is a no-op. The id is gated at the key builder (INV5).
  emq.2.3-D2.
  """
  def publish(conn, queue, event, job_id, extra \\ []) do
    # gate the id (INV5) -- raises on an ill-formed id before the wire
    _ = Keyspace.job_key(queue, job_id)
    payload = encode_event(event, job_id, extra)

    case Connector.command(conn, ["PUBLISH", channel(queue), payload]) do
      {:ok, _n} -> :ok
      other -> other
    end
  end

  @doc """
  Extract the `event` field from a raw cjson payload string as an atom
  (existing atoms only -- an unknown event name answers `:unknown`, never minting
  an atom from the wire). The substring-scan read the as-built convention uses
  (cjson key order is not guaranteed; the bus carries no JSON parser).
  """
  def event_name(payload) when is_binary(payload) do
    case Regex.run(~r/"event"\s*:\s*"([^"]+)"/, payload) do
      [_, name] ->
        try do
          String.to_existing_atom(name)
        rescue
          ArgumentError -> :unknown
        end

      _ ->
        :unknown
    end
  end

  # -- owner ----------------------------------------------------------------

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    queue = Keyword.fetch!(opts, :queue)

    conn =
      case Keyword.fetch(opts, :conn) do
        {:ok, c} ->
          c

        :error ->
          conn_opts =
            opts
            |> Keyword.fetch!(:connector)
            |> Keyword.put_new(:protocol, 3)
            |> Keyword.put(:push_to, self())

          {:ok, c} = Connector.start_link(conn_opts)
          c
      end

    chan = channel(queue)

    case Connector.subscribe(conn, chan) do
      :ok ->
        state = %{
          conn: conn,
          queue: queue,
          channel: chan,
          handler: Keyword.get(opts, :handler),
          handler_state: Keyword.get(opts, :handler_state),
          subscribers: MapSet.new()
        }

        {:ok, state}

      {:error, reason} ->
        {:stop, {:subscribe_failed, reason}}
    end
  end

  @impl true
  def handle_call({:subscribe, pid}, _from, s) do
    {:reply, :ok, %{s | subscribers: MapSet.put(s.subscribers, pid)}}
  end

  def handle_call({:unsubscribe, pid}, _from, s) do
    {:reply, :ok, %{s | subscribers: MapSet.delete(s.subscribers, pid)}}
  end

  # A published message on the channel arrives as {:emq_push, ["message",
  # channel, payload]} (the connector push routing). The "subscribe"/
  # "unsubscribe" confirmation frames are ignored. Each "message" dispatches on
  # the event name to the registered subscriber pids and the handler module.
  @impl true
  def handle_info({:emq_push, ["message", chan, payload]}, %{channel: chan} = s)
      when is_binary(payload) do
    event = event_name(payload)
    Enum.each(s.subscribers, fn pid -> send(pid, {:emq_event, event, payload}) end)
    {:noreply, dispatch_handler(s, event, payload)}
  end

  def handle_info({:emq_push, _frame}, s), do: {:noreply, s}

  def handle_info({:EXIT, _from, _reason}, s), do: {:noreply, s}

  def handle_info(_msg, s), do: {:noreply, s}

  defp dispatch_handler(%{handler: nil} = s, _event, _payload), do: s

  defp dispatch_handler(%{handler: handler} = s, event, payload) do
    case handler.handle_event(event, payload, s.handler_state) do
      {:ok, new_state} -> %{s | handler_state: new_state}
      _ -> s
    end
  end

  defp encode_event(event, job_id, extra) do
    fields =
      [{"event", to_string(event)}, {"job", job_id}] ++
        Enum.map(extra, fn {k, v} -> {to_string(k), to_string(v)} end)

    body =
      fields
      |> Enum.map(fn {k, v} -> ~s("#{k}":"#{escape(v)}") end)
      |> Enum.join(",")

    "{" <> body <> "}"
  end

  defp escape(v) do
    v
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end
end
