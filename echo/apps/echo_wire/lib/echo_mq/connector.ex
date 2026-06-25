defmodule EchoMQ.Connector do
  @moduledoc """
  The EchoMQ 2.0 connector, production grade: a purpose-built Valkey client
  on raw `:gen_tcp` and the RESP2 codec, zero dependencies beyond the
  identity canon.

  Design pillars: pipelining as the primitive (`command/2` is a pipeline of
  one); a pending FIFO pairing each in-flight pipeline with its caller, so
  replies route in order off an `active: :once` socket; EVALSHA-first script
  execution with one load-on-NOSCRIPT per script per connection; the
  `@wire_version` boot fence (the current rung's wire version) claimed or
  verified before the first command and treated as fatal on mismatch; the
  fence climbs per rung, the connector logic version-agnostic; supervised
  reconnect with capped jittered
  backoff, re-fencing on every reconnect.

  Production properties: an authenticated boot sequence (AUTH, SELECT,
  CLIENT SETNAME) ahead of the fence, with refusals typed and fatal;
  bounded in-flight depth (`max_pending`) answering `:overloaded` instead of
  buffering without bound; an idle heartbeat that PINGs a quiet wire so dead
  peers are noticed before the next caller pays for the discovery; in-flight
  callers failed with `:disconnected` on socket loss -- never replayed,
  because the connector cannot know what is idempotent; graceful shutdown
  answering every waiter `:closed`; and optional telemetry emission when
  `:telemetry` happens to be loaded, at zero cost when it is not.

  Counter slots: 1 commands · 2 pipelines · 3 replies · 4 reconnects ·
  5 script_loads · 6 evalsha_calls · 7 bytes_out · 8 wire_errors.
  """

  use GenServer

  alias EchoMQ.{Keyspace, RESP, Script}

  @wire_version "echomq:3.0.0"
  @backoff_min 100
  @backoff_max 2_000

  # -- public surface ------------------------------------------------------

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @spec command(GenServer.server(), [binary() | integer() | atom()], timeout()) ::
          {:ok, RESP.reply()} | {:error, term()}
  def command(conn, parts, timeout \\ 5_000) do
    case pipeline(conn, [parts], timeout) do
      {:ok, [reply]} -> {:ok, reply}
      {:error, _} = err -> err
    end
  end

  @spec pipeline(GenServer.server(), [[binary() | integer() | atom()]], timeout()) ::
          {:ok, [RESP.reply()]} | {:error, term()}
  def pipeline(conn, cmds, timeout \\ 5_000) when is_list(cmds) and cmds != [] do
    GenServer.call(conn, {:pipeline, cmds}, timeout)
  end

  @doc "EVALSHA-first execution of a declared-keys script."
  @spec eval(GenServer.server(), Script.t(), [binary()], [binary()], timeout()) ::
          {:ok, RESP.reply()} | {:error, term()}
  def eval(conn, %Script{} = s, keys, argv, timeout \\ 5_000) do
    parts = ["EVALSHA", s.sha, Integer.to_string(length(keys))] ++ keys ++ argv

    case command(conn, parts, timeout) do
      {:ok, {:error_reply, "NOSCRIPT" <> _}} ->
        GenServer.call(conn, {:bump, 5})

        case command(conn, ["SCRIPT", "LOAD", s.source], timeout) do
          {:ok, sha} when sha == s.sha -> command(conn, parts, timeout) |> map_script_reply()
          {:ok, other} -> {:error, {:sha_mismatch, other}}
          {:error, _} = err -> err
        end

      {:ok, {:error_reply, msg}} ->
        {:error, {:server, msg}}

      other ->
        other
    end
  end

  # A script's error reply is a server verdict on either attempt: the
  # load-and-retry path must map it exactly as the first attempt does.
  # Found by the conformance harness on a cold script cache (Chapter 3.6).
  defp map_script_reply({:ok, {:error_reply, msg}}), do: {:error, {:server, msg}}
  defp map_script_reply(other), do: other

  @doc """
  Send a command whose replies arrive out of band — the SUBSCRIBE family.
  Nothing is enqueued on the FIFO: the confirmation and all channel traffic
  reach `push_to` as pushes, so the reply queue stays aligned. Requires a
  RESP3 connection, where pushes and in-band replies share a wire without
  ambiguity. Chapter 4.2.
  """
  @spec push_command(GenServer.server(), [binary()], timeout()) :: :ok | {:error, term()}
  def push_command(conn, parts, timeout \\ 5_000) do
    GenServer.call(conn, {:push_command, parts}, timeout)
  end

  @doc """
  Subscribe this RESP3 connection to a channel; messages arrive at `push_to`.
  The channel is recorded in the connector's subscription set, so a reconnect
  re-issues it -- a dropped socket does not silently end the feed (Chapter
  3.7). The set is the connector's own state; it survives the disconnect.
  """
  @spec subscribe(GenServer.server(), binary()) :: :ok | {:error, term()}
  def subscribe(conn, channel) when is_binary(channel) do
    GenServer.call(conn, {:subscribe, channel})
  end

  @doc """
  Unsubscribe this RESP3 connection from a channel and drop it from the
  recorded set, so a later reconnect does not re-issue it. The companion to
  `subscribe/2` that keeps the recorded set truthful. Chapter 3.7.
  """
  @spec unsubscribe(GenServer.server(), binary()) :: :ok | {:error, term()}
  def unsubscribe(conn, channel) when is_binary(channel) do
    GenServer.call(conn, {:unsubscribe, channel})
  end

  @spec stats(GenServer.server()) :: map()
  @doc "Pipeline whose replies are suppressed wire-side (CLIENT REPLY OFF .. ON); answers :ok."
  def noreply_pipeline(conn, cmds, timeout \\ 5_000) when is_list(cmds) and cmds != [] do
    GenServer.call(conn, {:noreply_pipeline, cmds}, timeout)
  end

  @doc "MULTI/EXEC-wrapped pipeline; answers {:ok, exec_replies}."
  def transaction_pipeline(conn, cmds, timeout \\ 5_000) when is_list(cmds) and cmds != [] do
    GenServer.call(conn, {:transaction_pipeline, cmds}, timeout)
  end

  def stats(conn), do: GenServer.call(conn, :stats)

  def wire_version, do: @wire_version

  # -- owner ---------------------------------------------------------------

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    state = %{
      host:
        case Keyword.get(opts, :socket) do
          nil -> Keyword.get(opts, :host, {127, 0, 0, 1})
          path -> {:local, path}
        end,
      port: if(Keyword.get(opts, :socket), do: 0, else: Keyword.fetch!(opts, :port)),
      password: Keyword.get(opts, :password),
      database: Keyword.get(opts, :database, 0),
      client_name: Keyword.get(opts, :client_name),
      protocol: Keyword.get(opts, :protocol, :auto),
      protocol_live: 2,
      push_to: Keyword.get(opts, :push_to),
      pushes: 0,
      subscriptions: MapSet.new(),
      heartbeat_ms: Keyword.get(opts, :heartbeat_ms, 30_000),
      max_pending: Keyword.get(opts, :max_pending, 10_000),
      connect_timeout: Keyword.get(opts, :connect_timeout, 3_000),
      label: Keyword.get(opts, :label, :emq),
      sock: nil,
      buf: <<>>,
      pending: :queue.new(),
      pending_n: 0,
      overloads: 0,
      hb_ref: nil,
      backoff_initial: Keyword.get(opts, :backoff_initial, @backoff_min),
      backoff_max: Keyword.get(opts, :backoff_max, @backoff_max),
      backoff: Keyword.get(opts, :backoff_initial, @backoff_min),
      exit_on_disconnection: Keyword.get(opts, :exit_on_disconnection, false),
      counters: :counters.new(8, [:write_concurrency])
    }

    if Keyword.get(opts, :sync_connect, true) do
      case do_connect(state) do
        {:ok, state2} -> {:ok, state2}
        {:error, reason} -> {:stop, reason}
      end
    else
      {:ok, schedule(state)}
    end
  end

  @impl true
  def handle_call({call, _}, _from, %{sock: nil} = s)
      when call in [:noreply_pipeline, :transaction_pipeline],
      do: {:reply, {:error, :disconnected}, s}

  def handle_call({call, _}, _from, %{pending_n: n, max_pending: max} = s)
      when call in [:noreply_pipeline, :transaction_pipeline] and n >= max do
    emit([:emq, :connector, :overload], %{pending: n}, %{label: s.label})
    {:reply, {:error, :overloaded}, %{s | overloads: s.overloads + 1}}
  end

  def handle_call({:pipeline, _}, _from, %{sock: nil} = s),
    do: {:reply, {:error, :disconnected}, s}

  def handle_call({:push_command, _}, _from, %{sock: nil} = s),
    do: {:reply, {:error, :disconnected}, s}

  def handle_call({:push_command, _}, _from, %{protocol_live: p} = s) when p != 3,
    do: {:reply, {:error, :requires_resp3}, s}

  def handle_call({:push_command, parts}, _from, s) do
    case send_push(s, parts) do
      {:ok, s2} -> {:reply, :ok, s2}
      {:error, reason, s2} -> {:reply, {:error, reason}, s2}
    end
  end

  def handle_call({sub, _channel}, _from, %{sock: nil} = s) when sub in [:subscribe, :unsubscribe],
    do: {:reply, {:error, :disconnected}, s}

  def handle_call({sub, _channel}, _from, %{protocol_live: p} = s)
      when sub in [:subscribe, :unsubscribe] and p != 3,
      do: {:reply, {:error, :requires_resp3}, s}

  def handle_call({:subscribe, channel}, _from, s) do
    case send_push(s, ["SUBSCRIBE", channel]) do
      {:ok, s2} -> {:reply, :ok, %{s2 | subscriptions: MapSet.put(s2.subscriptions, channel)}}
      {:error, reason, s2} -> {:reply, {:error, reason}, s2}
    end
  end

  def handle_call({:unsubscribe, channel}, _from, s) do
    case send_push(s, ["UNSUBSCRIBE", channel]) do
      {:ok, s2} -> {:reply, :ok, %{s2 | subscriptions: MapSet.delete(s2.subscriptions, channel)}}
      {:error, reason, s2} -> {:reply, {:error, reason}, s2}
    end
  end

  def handle_call({:pipeline, _}, _from, %{pending_n: n, max_pending: max} = s) when n >= max do
    emit([:emq, :connector, :overload], %{pending: n}, %{label: s.label})
    {:reply, {:error, :overloaded}, %{s | overloads: s.overloads + 1}}
  end

  def handle_call({:pipeline, cmds}, from, s), do: send_pipe(s, from, cmds, length(cmds), :plain)

  def handle_call({:noreply_pipeline, cmds}, from, s) do
    wrapped = [["CLIENT", "REPLY", "OFF"]] ++ cmds ++ [["CLIENT", "REPLY", "ON"]]
    send_pipe(s, from, wrapped, 1, :noreply)
  end

  def handle_call({:transaction_pipeline, cmds}, from, s) do
    wrapped = [["MULTI"]] ++ cmds ++ [["EXEC"]]
    send_pipe(s, from, wrapped, length(cmds) + 2, {:txn, length(cmds)})
  end

  def handle_call(:stats, _from, s) do
    c = s.counters

    {:reply,
     %{
       label: s.label,
       status: if(s.sock, do: :connected, else: :reconnecting),
       protocol: s.protocol_live,
       pushes: s.pushes,
       pending: s.pending_n,
       overloads: s.overloads,
       commands: :counters.get(c, 1),
       pipelines: :counters.get(c, 2),
       replies: :counters.get(c, 3),
       reconnects: :counters.get(c, 4),
       script_loads: :counters.get(c, 5),
       evalsha_calls: :counters.get(c, 6),
       bytes_out: :counters.get(c, 7),
       wire_errors: :counters.get(c, 8)
     }, s}
  end

  def handle_call({:bump, slot}, _from, s) do
    :counters.add(s.counters, slot, 1)
    {:reply, :ok, s}
  end

  # Send an out-of-band push command (the SUBSCRIBE family) on the live
  # socket, counting it like any command. Shared by the push_command,
  # subscribe, and unsubscribe calls and by the reconnect re-issue; the caller
  # threads the (possibly down) state on through.
  defp send_push(s, parts) do
    data = RESP.encode(parts)

    case :gen_tcp.send(s.sock, data) do
      :ok ->
        :counters.add(s.counters, 1, 1)
        :counters.add(s.counters, 7, IO.iodata_length(data))
        {:ok, s}

      {:error, reason} ->
        {:error, reason, schedule(down(s))}
    end
  end

  defp send_pipe(s, from, cmds, want, kind) do
    data = Enum.map(cmds, &RESP.encode/1)

    case :gen_tcp.send(s.sock, data) do
      :ok ->
        :counters.add(s.counters, 1, length(cmds))
        :counters.add(s.counters, 2, 1)
        :counters.add(s.counters, 7, IO.iodata_length(data))
        t0 = System.monotonic_time()
        {:noreply, %{s | pending: :queue.in({from, want, [], t0, kind}, s.pending), pending_n: s.pending_n + 1}}

      {:error, reason} ->
        {:reply, {:error, reason}, schedule(down(s))}
    end
  end

  @impl true
  def handle_info({:tcp, sock, data}, %{sock: sock} = s) do
    s2 = drain(%{s | buf: s.buf <> data})
    if s2.sock, do: :inet.setopts(s2.sock, active: :once)
    {:noreply, s2}
  end

  def handle_info({:tcp_closed, sock}, %{sock: sock} = s) do
    if s.exit_on_disconnection, do: {:stop, :disconnected, down(s)}, else: {:noreply, schedule(down(s))}
  end

  def handle_info({:tcp_error, sock, _}, %{sock: sock} = s) do
    if s.exit_on_disconnection, do: {:stop, :disconnected, down(s)}, else: {:noreply, schedule(down(s))}
  end
  def handle_info({:tcp, _old, _}, s), do: {:noreply, s}
  def handle_info({:tcp_closed, _old}, s), do: {:noreply, s}
  def handle_info({:tcp_error, _old, _}, s), do: {:noreply, s}

  def handle_info(:reconnect, %{sock: nil} = s) do
    case do_connect(s) do
      {:ok, s2} ->
        :counters.add(s2.counters, 4, 1)
        s3 = resubscribe(s2)
        emit([:emq, :connector, :reconnect], %{}, %{label: s3.label})
        {:noreply, s3}

      {:error, fatal} when elem(fatal, 0) in [:version_fence, :auth_refused, :boot_refused] ->
        {:stop, fatal, s}

      {:error, _} ->
        {:noreply, schedule(s)}
    end
  end

  def handle_info(:reconnect, s), do: {:noreply, s}

  def handle_info(:heartbeat, %{sock: nil} = s), do: {:noreply, s}

  def handle_info(:heartbeat, s) do
    s2 =
      if s.pending_n == 0 do
        case :gen_tcp.send(s.sock, RESP.encode(["PING"])) do
          :ok ->
            %{s | pending: :queue.in({:internal, 1, [], 0, :internal}, s.pending), pending_n: s.pending_n + 1}

          {:error, _} ->
            schedule(down(s))
        end
      else
        s
      end

    {:noreply, arm_heartbeat(s2)}
  end

  def handle_info({:EXIT, _, _}, s), do: {:noreply, s}

  @impl true
  def terminate(_reason, s) do
    Enum.each(:queue.to_list(s.pending), fn
      {:internal, _, _, _, _} -> :ok
      {from, _, _, _, _} -> GenServer.reply(from, {:error, :closed})
    end)

    if s.sock, do: :gen_tcp.close(s.sock)
    :ok
  end

  # -- wire ----------------------------------------------------------------

  defp do_connect(s) do
    opts = [:binary, active: false, nodelay: true, keepalive: true, send_timeout: 5_000, send_timeout_close: true]

    with {:ok, sock} <- :gen_tcp.connect(s.host, s.port, opts, s.connect_timeout),
         {:ok, buf, proto} <- boot(sock, s),
         :ok <- fence(sock, buf) do
      :inet.setopts(sock, active: :once)
      emit([:emq, :connector, :connection], %{}, %{label: s.label, protocol: proto})
      {:ok, arm_heartbeat(%{s | sock: sock, buf: <<>>, backoff: s.backoff_initial, protocol_live: proto})}
    end
  end

  defp boot(sock, s) do
    case hello(sock, s) do
      {:ok, buf, proto} -> boot_rest(sock, buf, s, proto)
      {:error, _} = err -> err
    end
  end

  defp hello(sock, %{protocol: 2} = s) do
    with {:ok, buf} <- boot_auth(sock, <<>>, s.password),
         {:ok, "PONG", buf2} <- sync(sock, ["PING"], buf) do
      {:ok, buf2, 2}
    else
      {:ok, {:error_reply, "NOAUTH" <> _ = msg}, _} -> {:error, {:auth_refused, msg}}
      {:ok, other, _} -> {:error, {:unexpected_hello, other}}
      {:error, _} = err -> err
    end
  end

  defp hello(sock, s) do
    cmd = if s.password, do: ["HELLO", "3", "AUTH", "default", s.password], else: ["HELLO", "3"]

    case sync(sock, cmd, <<>>) do
      {:ok, %{"proto" => 3}, buf} ->
        {:ok, buf, 3}

      {:ok, {:error_reply, "NOAUTH" <> _ = msg}, _} ->
        {:error, {:auth_refused, msg}}

      {:ok, {:error_reply, "WRONGPASS" <> _ = msg}, _} ->
        {:error, {:auth_refused, msg}}

      {:ok, {:error_reply, _msg}, _} when s.protocol == :auto ->
        hello(sock, %{s | protocol: 2})

      {:ok, other, _} ->
        {:error, {:unexpected_hello, other}}

      {:error, _} = err ->
        err
    end
  end

  defp boot_rest(sock, buf, s, proto) do
    with {:ok, buf} <- boot_step(sock, buf, s.database > 0, ["SELECT", Integer.to_string(s.database)], :select),
         {:ok, buf} <- boot_step(sock, buf, s.client_name != nil, ["CLIENT", "SETNAME", s.client_name || ""], :setname) do
      {:ok, buf, proto}
    end
  end

  defp boot_auth(_sock, buf, nil), do: {:ok, buf}

  defp boot_auth(sock, buf, password) do
    case sync(sock, ["AUTH", password], buf) do
      {:ok, "OK", buf2} -> {:ok, buf2}
      {:ok, {:error_reply, msg}, _} -> {:error, {:auth_refused, msg}}
      {:ok, other, _} -> {:error, {:auth_refused, inspect(other)}}
      {:error, _} = err -> err
    end
  end

  defp boot_step(_sock, buf, false, _cmd, _step), do: {:ok, buf}

  defp boot_step(sock, buf, true, cmd, step) do
    case sync(sock, cmd, buf) do
      {:ok, "OK", buf2} -> {:ok, buf2}
      {:ok, {:error_reply, msg}, _} -> {:error, {:boot_refused, step, msg}}
      {:ok, other, _} -> {:error, {:boot_refused, step, inspect(other)}}
      {:error, _} = err -> err
    end
  end

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

  defp sync(sock, parts, buf) do
    with :ok <- :gen_tcp.send(sock, RESP.encode(parts)) do
      recv_one(sock, buf)
    end
  end

  defp recv_one(sock, buf) do
    case RESP.parse(buf) do
      {:ok, v, rest} ->
        {:ok, v, rest}

      :incomplete ->
        case :gen_tcp.recv(sock, 0, 3_000) do
          {:ok, data} -> recv_one(sock, buf <> data)
          {:error, _} = err -> err
        end

      {:error, _} = err ->
        err
    end
  end

  defp drain(%{pending: pending, buf: buf} = s) do
    case :queue.out(pending) do
      {:empty, _} ->
        drain_idle(s)

      {{:value, {from, want, acc, t0, kind}}, rest_q} ->
        case fill(buf, want - length(acc), acc, s.counters) do
          {:done, replies, buf2, pushes} ->
            unless kind == :internal do
              emit(
                [:emq, :connector, :pipeline, :stop],
                %{duration: System.monotonic_time() - t0, commands: want},
                %{label: s.label, kind: pipe_kind(kind)}
              )

              GenServer.reply(from, pipe_reply(kind, replies))
            end

            drain(route_pushes(%{s | pending: rest_q, pending_n: s.pending_n - 1, buf: buf2}, pushes))

          {:partial, acc2, buf2, pushes} ->
            route_pushes(%{s | pending: :queue.in_r({from, want, acc2, t0, kind}, rest_q), buf: buf2}, pushes)
        end
    end
  end

  defp drain_idle(%{buf: buf} = s) do
    case RESP.parse(buf) do
      {:ok, {:push, payload}, rest} ->
        drain_idle(route_pushes(%{s | buf: rest}, [payload]))

      {:ok, _orphan, rest} ->
        :counters.add(s.counters, 8, 1)
        drain_idle(%{s | buf: rest})

      _ ->
        s
    end
  end

  defp route_pushes(s, []), do: s

  defp route_pushes(s, pushes) do
    if s.push_to, do: Enum.each(pushes, &send(s.push_to, {:emq_push, &1}))
    %{s | pushes: s.pushes + length(pushes)}
  end

  defp pipe_kind({:txn, _}), do: :transaction
  defp pipe_kind(kind), do: kind

  defp pipe_reply(:plain, replies), do: {:ok, replies}
  defp pipe_reply(:noreply, _replies), do: :ok
  defp pipe_reply({:txn, _}, replies), do: {:ok, List.last(replies)}

  defp fill(buf, n, acc, c), do: fill(buf, n, acc, c, [])

  defp fill(buf, 0, acc, _c, pushes), do: {:done, Enum.reverse(acc), buf, Enum.reverse(pushes)}

  defp fill(buf, n, acc, c, pushes) do
    case RESP.parse(buf) do
      {:ok, {:push, payload}, rest} ->
        fill(rest, n, acc, c, [payload | pushes])

      {:ok, v, rest} ->
        :counters.add(c, 3, 1)
        fill(rest, n - 1, [v | acc], c, pushes)

      :incomplete ->
        {:partial, acc, buf, Enum.reverse(pushes)}

      {:error, _} ->
        :counters.add(c, 8, 1)
        {:partial, acc, buf, Enum.reverse(pushes)}
    end
  end

  defp down(%{sock: sock} = s) do
    if sock, do: :gen_tcp.close(sock)
    if sock, do: emit([:emq, :connector, :disconnection], %{}, %{label: s.label})

    Enum.each(:queue.to_list(s.pending), fn
      {:internal, _, _, _, _} -> :ok
      {from, _, _, _, _} -> GenServer.reply(from, {:error, :disconnected})
    end)

    # the in-flight FIFO is cleared (in-flight callers were failed
    # :disconnected) but the subscription set is NOT -- it is the recovery
    # record the reconnect re-issues.
    %{s | sock: nil, buf: <<>>, pending: :queue.new(), pending_n: 0}
  end

  # Re-issue each recorded subscription on the freshly reconnected socket,
  # after do_connect has re-negotiated the protocol. The push channel needs
  # RESP3; a reconnect re-negotiates the same protocol the connection booted
  # with, so this re-issues when it is live. A send failure tears the new
  # socket down and reschedules -- the next reconnect retries the whole set.
  defp resubscribe(%{subscriptions: subs} = s) do
    if MapSet.size(subs) == 0 or s.protocol_live != 3 do
      s
    else
      Enum.reduce_while(MapSet.to_list(subs), s, fn channel, acc ->
        case send_push(acc, ["SUBSCRIBE", channel]) do
          {:ok, acc2} -> {:cont, acc2}
          {:error, _reason, acc2} -> {:halt, acc2}
        end
      end)
    end
  end

  defp schedule(%{sock: nil} = s) do
    jitter = :rand.uniform(div(s.backoff, 2) + 1)
    Process.send_after(self(), :reconnect, s.backoff + jitter)
    %{s | backoff: min(s.backoff * 2, s.backoff_max)}
  end

  defp schedule(s), do: s

  defp arm_heartbeat(%{heartbeat_ms: 0} = s), do: s

  defp arm_heartbeat(s) do
    if s.hb_ref, do: Process.cancel_timer(s.hb_ref)
    %{s | hb_ref: Process.send_after(self(), :heartbeat, s.heartbeat_ms)}
  end

  defp emit(event, measurements, metadata) do
    if :erlang.function_exported(:telemetry, :execute, 3) do
      apply(:telemetry, :execute, [event, measurements, metadata])
    end

    :ok
  end
end
