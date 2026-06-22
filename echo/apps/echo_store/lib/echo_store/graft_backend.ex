defmodule EchoStore.GraftBackend do
  @moduledoc """
  The BEAM client for the Rust page-engine backend (`echo_graft_backend`), eg.4.

  `EchoStore.GraftBackend` drives the **Rust** `echo_graft` engine over the EchoMQ bus: it
  performs the version handshake, sends request/response verbs (open/commit/push/pull/read/
  snapshot/get_commit) on a per-Volume command lane, and subscribes to the change-feed lane
  to observe durable advances without polling. It is a coexisting **peer** beside the native
  `EchoStore.Graft.*` engine (D-1 = COEXIST): it neither touches nor wraps the native engine,
  and its lanes are distinct by construction —
  `egraft:cmd:{vol}` / `egraft:feed:{vol}` vs the native `graft:{vol}:commits`.

  ## Transport

  Only the verified `EchoMQ.Connector` surface is used: `command/3` for `PUBLISH`,
  `subscribe/2` for the reply + feed lanes (whose out-of-band pushes arrive as
  `{:emq_push, ["message", channel, payload]}` — the same envelope `EchoStore.Graft.Sync`
  consumes). The connector owns supervised reconnect and **re-issues every recorded
  subscription on reconnect** (`connector.ex` `resubscribe/1`); this client owns the feed
  cursor (the last-seen LSN) and replays from it (S-3).

  ## Wire

  The wire is `echo_graft_proto`, encoded/decoded by `EchoStore.GraftBackend.Proto` —
  byte-frozen and cross-runtime-conformant with the Rust crate. The eg.3 `FeedEvent` rides as
  an opaque bilrost blob; this client never inspects its fields beyond what the feed callback
  needs (it carries the raw blob to the subscriber).

  ## Status

  The request/response RPC and the live feed run against a real `echo_graft_backend` over a
  live bus — exercised by the env-gated leg (`ECHO_GRAFT_BACKEND_TEST`). The offline path
  (encode → publish bytes; decode ← reply bytes) is always exercised by the conformance test.
  """

  use GenServer

  require Logger

  alias EchoStore.GraftBackend.Proto

  @typedoc "A connected client."
  @type t :: GenServer.server()

  @typedoc "A native Volume id string (base58)."
  @type vid :: binary()

  @typedoc "A 14-char branded id string."
  @type branded :: binary()

  # The reply lane a client listens on for its correlated responses. One lane per client
  # instance keeps a client's replies off every other client's wire.
  @reply_lane_prefix "egraft:reply:"

  # ---- lane builders (the only bus keys this client adds; distinct from the native engine) ----

  @doc "The per-Volume command lane a request is published on."
  @spec cmd_lane(vid()) :: binary()
  def cmd_lane(vid), do: "egraft:cmd:" <> vid

  @doc "The per-Volume change-feed lane (mirrors `echo_graft::feed::lane_for`)."
  @spec feed_lane(branded()) :: binary()
  def feed_lane(branded), do: "egraft:feed:" <> branded

  # ---- public API ----

  @doc """
  Start a client.

  Provide EITHER a ready connector or the options for one this client owns:
    * `:connector_opts` — a keyword list for `EchoMQ.Connector.start_link/1` (e.g.
      `[port: 6390, protocol: 3]`); the client starts the connector with `push_to: self()`
      so replies + feed pushes route here. This is the production-shaped path.
    * `:conn` — an already-started `EchoMQ.Connector` whose `:push_to` is (or will be) this
      client. Use when the supervising process owns the connector; it must be started with
      `push_to:` the client's pid for replies to route.

  Other options:
    * `:client_id` — a tag for the reply lane (defaults to a generated unique suffix).
    * `:feed_to` — a pid notified of feed events as `{:graft_feed, branded, lsn, blob}`.
    * `:timeout` — per-request timeout (default 5_000 ms).
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Perform the version handshake. Sends `Hello{proto_min, proto_max}` on the Volume-agnostic
  control lane and awaits `Welcome{proto}` (or `Incompatible{...}`). Returns `{:ok, proto}`
  on agreement, `{:error, {:version_mismatch, detail}}` on refusal.
  """
  @spec hello(t(), timeout()) :: {:ok, pos_integer()} | {:error, term()}
  def hello(client, timeout \\ 5_000), do: GenServer.call(client, :hello, timeout)

  @doc "Open (or resolve-and-open) a branded Volume; acks the head LSN."
  @spec open_volume(t(), branded(), keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def open_volume(client, branded, opts \\ []),
    do: GenServer.call(client, {:request, {:open_volume, branded, opts}}, req_timeout(opts))

  @doc "Resolve a branded id to its native Volume id."
  @spec resolve_branded(t(), branded(), keyword()) :: {:ok, vid()} | {:error, term()}
  def resolve_branded(client, branded, opts \\ []),
    do: GenServer.call(client, {:request, {:resolve_branded, branded}}, req_timeout(opts))

  @doc """
  Commit pages from `base` to a Volume with a per-call durability mode; acks the resulting head LSN.

  The `:mode` option (`:async` | `:sync`) chooses when the commit acks (eg.5):
    * `:sync` (the DEFAULT) — ack only after the remote conditional-write commit acks (durable +
      replicated before the ack returns);
    * `:async` — ack on the local fsync of the open batch; the remote push rolls the batch up
      asynchronously (the loss window is the open batch).

  The mode is always encoded on the wire (v2); the `:sync` default is this client-API default, not
  a wire/version default.
  """
  @spec commit(t(), vid(), non_neg_integer(), [{non_neg_integer(), binary()}], keyword()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def commit(client, vid, base, pages, opts \\ []) do
    mode = Keyword.get(opts, :mode, :sync)
    GenServer.call(client, {:request, {:commit, vid, base, mode, pages}}, req_timeout(opts))
  end

  @doc "Push local commits to the remote (the fence + feed publish); acks the remote head LSN."
  @spec push(t(), vid(), keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def push(client, vid, opts \\ []),
    do: GenServer.call(client, {:request, {:push, vid}}, req_timeout(opts))

  @doc "Pull remote commits into a Volume; acks the remote head LSN."
  @spec pull(t(), vid(), keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  def pull(client, vid, opts \\ []),
    do: GenServer.call(client, {:request, {:pull, vid}}, req_timeout(opts))

  @doc "Read one page at the Volume head; returns the raw page bytes."
  @spec read(t(), vid(), non_neg_integer(), keyword()) :: {:ok, binary()} | {:error, term()}
  def read(client, vid, pageidx, opts \\ []),
    do: GenServer.call(client, {:request, {:read, vid, pageidx}}, req_timeout(opts))

  @doc "Fetch a Volume's snapshot head; returns `{:ok, {lsn, pages}}`."
  @spec snapshot(t(), vid(), keyword()) :: {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, term()}
  def snapshot(client, vid, opts \\ []),
    do: GenServer.call(client, {:request, {:snapshot, vid}}, req_timeout(opts))

  @doc """
  Subscribe to a Volume's change-feed lane (keyed by its branded id). Feed events thereafter
  reach `:feed_to` as `{:graft_feed, branded, lsn, blob}`; the client tracks the last-seen LSN
  so a reconnect replays only later events (S-3).
  """
  @spec subscribe_feed(t(), branded(), keyword()) :: :ok | {:error, term()}
  def subscribe_feed(client, branded, opts \\ []),
    do: GenServer.call(client, {:subscribe_feed, branded}, req_timeout(opts))

  @doc "The last-seen LSN for a branded Volume's feed (the replay cursor); 0 if none seen."
  @spec last_seen(t(), branded()) :: non_neg_integer()
  def last_seen(client, branded), do: GenServer.call(client, {:last_seen, branded})

  # ---- GenServer ----

  @impl true
  def init(opts) do
    client_id = Keyword.get(opts, :client_id, gen_client_id())

    case resolve_conn(opts) do
      {:ok, conn} ->
        state = %{
          conn: conn,
          client_id: client_id,
          reply_lane: @reply_lane_prefix <> client_id,
          feed_to: Keyword.get(opts, :feed_to),
          timeout: Keyword.get(opts, :timeout, 5_000),
          corr: 0,
          # corr -> {from, decode_fn} for the in-flight request awaiting its reply
          inflight: %{},
          # branded -> last-seen LSN (the replay cursor)
          cursors: %{}
        }

        # Listen on this client's reply lane so correlated responses route back here.
        case EchoMQ.Connector.subscribe(conn, state.reply_lane) do
          :ok -> {:ok, state}
          {:error, reason} -> {:stop, reason}
        end

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # Either own a connector (started with push_to: self/0 so replies route here) or adopt one.
  defp resolve_conn(opts) do
    case {Keyword.get(opts, :connector_opts), Keyword.get(opts, :conn)} do
      {nil, nil} ->
        {:error, :no_connector}

      {nil, conn} ->
        {:ok, conn}

      {connector_opts, _} ->
        EchoMQ.Connector.start_link(Keyword.put(connector_opts, :push_to, self()))
    end
  end

  @impl true
  def handle_call(:hello, from, state) do
    # The handshake is correlation-less in the proto; it pairs on the reply lane like any
    # request, using corr 0 (Hello carries no corr — Welcome/Incompatible reply on this lane).
    msg = {:hello, Proto.proto_min(), Proto.proto_max(), state.client_id}

    case publish(state, control_lane(), msg) do
      :ok ->
        decode = fn
          {:welcome, proto} -> {:ok, proto}
          {:incompatible, _min, _max, reason} -> {:error, {:version_mismatch, reason}}
          other -> {:error, {:unexpected, other}}
        end

        {:noreply, await(state, 0, from, decode)}

      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  def handle_call({:request, req}, from, state) do
    {corr, state} = next_corr(state)
    {lane, msg, decode} = build(req, corr)

    case publish(state, lane, msg) do
      :ok -> {:noreply, await(state, corr, from, decode)}
      {:error, _} = err -> {:reply, err, state}
    end
  end

  def handle_call({:subscribe_feed, branded}, _from, state) do
    case EchoMQ.Connector.subscribe(state.conn, feed_lane(branded)) do
      :ok -> {:reply, :ok, ensure_cursor(state, branded)}
      {:error, _} = err -> {:reply, err, state}
    end
  end

  def handle_call({:last_seen, branded}, _from, state),
    do: {:reply, Map.get(state.cursors, branded, 0), state}

  @impl true
  def handle_info({:emq_push, ["message", channel, payload]}, state) do
    {:noreply, route_push(state, channel, payload)}
  end

  # subscribe/unsubscribe confirmations and other push shapes are ignored.
  def handle_info({:emq_push, _other}, state), do: {:noreply, state}
  def handle_info(_msg, state), do: {:noreply, state}

  # ---- push routing ----

  defp route_push(state, channel, payload) do
    cond do
      channel == state.reply_lane -> deliver_reply(state, payload)
      feed_channel?(channel) -> deliver_feed(state, channel, payload)
      true -> state
    end
  end

  # A reply on the client's lane: parse, decode to the message tuple, match it to the waiting
  # caller by corr, and reply with the caller's decode function.
  defp deliver_reply(state, payload) do
    with {:ok, parts, ""} <- EchoMQ.RESP.parse(payload),
         {:ok, msg} <- Proto.decode(parts) do
      corr = corr_of(msg)

      case Map.pop(state.inflight, corr) do
        {{from, decode}, rest} ->
          GenServer.reply(from, decode.(msg))
          %{state | inflight: rest}

        {nil, _} ->
          state
      end
    else
      _ -> state
    end
  end

  # A feed event: parse, decode to {:feed, blob}, decode the OPAQUE bilrost blob's LSN +
  # branded id, advance the cursor monotonically, and notify the subscriber.
  defp deliver_feed(state, channel, payload) do
    with {:ok, parts, ""} <- EchoMQ.RESP.parse(payload),
         {:ok, {:feed, blob}} <- Proto.decode(parts),
         {:ok, branded, lsn} <- decode_feed_blob(blob) do
      _ = channel
      last = Map.get(state.cursors, branded, 0)

      if lsn > last do
        if state.feed_to, do: send(state.feed_to, {:graft_feed, branded, lsn, blob})
        %{state | cursors: Map.put(state.cursors, branded, lsn)}
      else
        state
      end
    else
      _ -> state
    end
  end

  # ---- request building ----

  defp build({:open_volume, branded, opts}, corr) do
    msg = {:open_volume, corr, branded, opts[:local], opts[:remote]}
    {control_lane(), msg, &ack_lsn/1}
  end

  defp build({:resolve_branded, branded}, corr) do
    msg = {:resolve_branded, corr, branded}
    decode = fn
      {:pages, ^corr, data} -> {:ok, data}
      other -> err_or_unexpected(other)
    end

    {control_lane(), msg, decode}
  end

  defp build({:commit, vid, base, mode, pages}, corr) do
    {cmd_lane(vid), {:commit, corr, vid, base, mode, pages}, &ack_lsn/1}
  end

  defp build({:push, vid}, corr), do: {cmd_lane(vid), {:push, corr, vid}, &ack_lsn/1}
  defp build({:pull, vid}, corr), do: {cmd_lane(vid), {:pull, corr, vid}, &ack_lsn/1}

  defp build({:read, vid, pageidx}, corr) do
    decode = fn
      {:pages, ^corr, data} -> {:ok, data}
      other -> err_or_unexpected(other)
    end

    {cmd_lane(vid), {:read, corr, vid, pageidx}, decode}
  end

  defp build({:snapshot, vid}, corr) do
    decode = fn
      {:snapshot_resp, ^corr, lsn, pages} -> {:ok, {lsn, pages}}
      other -> err_or_unexpected(other)
    end

    {cmd_lane(vid), {:snapshot, corr, vid}, decode}
  end

  # Standard ack decoder: an Ack yields the LSN; an Err maps to its kind.
  defp ack_lsn({:ack, _corr, lsn}), do: {:ok, lsn}
  defp ack_lsn(other), do: err_or_unexpected(other)

  defp err_or_unexpected({:err, _corr, kind, detail}), do: {:error, {kind, detail}}
  defp err_or_unexpected(other), do: {:error, {:unexpected, other}}

  # ---- helpers ----

  defp publish(state, lane, msg) do
    bytes = IO.iodata_to_binary(Proto.encode(msg))

    case EchoMQ.Connector.command(state.conn, ["PUBLISH", lane, bytes], state.timeout) do
      {:ok, _} -> :ok
      {:error, _} = err -> err
      other -> {:error, other}
    end
  end

  defp await(state, corr, from, decode) do
    %{state | inflight: Map.put(state.inflight, corr, {from, decode})}
  end

  defp next_corr(%{corr: c} = state) do
    next = c + 1
    {next, %{state | corr: next}}
  end

  defp ensure_cursor(state, branded) do
    if Map.has_key?(state.cursors, branded),
      do: state,
      else: %{state | cursors: Map.put(state.cursors, branded, 0)}
  end

  # The branded id + LSN inside the eg.3 bilrost FeedEvent, read for the cursor. The blob is
  # OPAQUE by contract, so rather than carry a full bilrost decoder, `FeedBlob` peeks only the
  # two fixed fields it needs — field 1 (branded id, length-delimited) and field 3 (lsn,
  # varint). Those two are parsed minimally; everything else stays opaque, forwarded as `blob`.
  defp decode_feed_blob(blob), do: EchoStore.GraftBackend.FeedBlob.branded_and_lsn(blob)

  # The shared control lane carries the vid-less requests — the handshake and the open-time
  # verbs (open_volume / resolve_branded, which carry a branded id but no native vid yet). It is
  # INTENTIONALLY a single shared lane EXEMPT from the backend's per-Volume backpressure
  # isolation (which keys on egraft:cmd:{vol}): the control lane has no {vol} to cap on, and its
  # traffic is infrequent and bounded by construction (one handshake per session, one open per
  # Volume lifecycle) — not a sustained write path a producer can flood. The per-Volume cap
  # guards only the hot egraft:cmd:{vol} lanes. See echo_graft_backend `backpressure` moduledoc.
  defp control_lane, do: "egraft:cmd:_control"

  defp feed_channel?(channel), do: String.starts_with?(channel, "egraft:feed:")

  defp corr_of(msg) when is_tuple(msg) do
    case msg do
      {:welcome, _} -> 0
      {:incompatible, _, _, _} -> 0
      {:feed, _} -> 0
      _ -> elem(msg, 1)
    end
  end

  defp req_timeout(opts), do: Keyword.get(opts, :timeout, 5_000)

  defp gen_client_id do
    Base.url_encode64(:crypto.strong_rand_bytes(9), padding: false)
  end
end
