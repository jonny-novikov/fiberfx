defmodule Codemojex.Application do
  @moduledoc """
  The supervision tree, extended to wire EchoMQ end to end with the bot and the rate-limited
  notification job.

  Order: the relational system of record (`Repo`) and `PubSub` first; then the EchoMQ bus
  (`Bus`, the shared Valkey connector); then the EchoStore near-cache tier (`Tables`, the
  declared L1-over-L2 caches for games and emoji sets); then the rate limiter and the bot
  gateway, which the
  notification worker depends on; then the consumers — the scoring authority, the settlement
  worker, the **notification worker**, and the **bot-command worker** (inbound Telegram updates
  bridged onto the bus by `EchoBot.ingest/1`); then an in-memory CHAMP leaderboard view; then
  the Phoenix endpoint. The Graft `Committer` is started only when a volume is configured
  (`:graft_volume`) and EchoStore is loaded, so the app still boots without the replicated tier.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    conn = conn_opts()

    children =
      [
        Codemojex.Repo,
        {Phoenix.PubSub, name: Codemojex.PubSub},
        {Codemojex.Bus, conn},

        # the EchoStore near-cache tier (games + emoji sets) over the shared
        # Valkey, in front of Postgres on the scoring hot path
        {Codemojex.Tables, conn},

        # rate limiter + bot must precede the workers that use them
        Codemojex.RateLimiter,
        Codemojex.EchoBot,

        # the existing authorities
        Supervisor.child_spec({EchoMQ.Consumer, score_opts(conn)}, id: :cm_score),
        Supervisor.child_spec({EchoMQ.Consumer, settle_opts(conn)}, id: :cm_settle),

        # new: the rate-limited notification job, and inbound Telegram commands
        Supervisor.child_spec({EchoMQ.Consumer, notify_opts(conn)}, id: :cm_notify),
        Supervisor.child_spec({EchoMQ.Consumer, command_opts(conn)}, id: :cm_commands),

        # an in-memory CHAMP view of the leaderboard, rebuildable from Graft via EchoData.ChampView
        {EchoData.ChampServer, name: Codemojex.Leaderboard},

        # the periodic game sweep (cm.5): the timer-close for :open games, the
        # never-fills void for :gathering Golden Rooms, and the engagement nudges.
        Codemojex.Sweep,

        CodemojexWeb.Endpoint
      ]
      |> maybe_committer(conn)

    Supervisor.start_link(children, strategy: :one_for_one, name: Codemojex.Supervisor)
  end

  # The shared connector options for every Valkey lane (the Bus, the near-cache tables, and each
  # consumer's private lane). host/password come from prod config (runtime.exs reads the env);
  # unset locally → omitted, so the connector uses its 127.0.0.1:6390 no-auth default (dev/test).
  defp conn_opts do
    [protocol: 3, port: Application.get_env(:codemojex, :valkey_port, 6390)]
    |> maybe_put(:host, valkey_host())
    |> maybe_put(:password, Application.get_env(:codemojex, :valkey_password))
  end

  # Resolve the configured Valkey host to an IPv6 address tuple so the connector dials echo-valkey
  # over Fly's IPv6-only 6PN: gen_tcp infers inet6 from an 8-element address tuple, so this needs
  # no global :kernel/inet config (which a release cannot set at compile time) and no connector
  # change. Unset (local dev/test) → nil → the connector falls back to 127.0.0.1. A charlist
  # hostname is resolved to its AAAA; if resolution fails the charlist passes through (best effort).
  defp valkey_host do
    case Application.get_env(:codemojex, :valkey_host) do
      nil ->
        nil

      host ->
        case :inet.getaddr(host, :inet6) do
          {:ok, addr} -> addr
          {:error, _} -> host
        end
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  @impl true
  def config_change(changed, _new, removed) do
    CodemojexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # --- consumer specs --------------------------------------------------------

  defp score_opts(conn) do
    [
      queue: Codemojex.ScoreWorker.queue(),
      handler: &Codemojex.ScoreWorker.handle/1,
      connector: conn,
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  defp settle_opts(conn) do
    [
      queue: Codemojex.Settle.queue(),
      handler: &Codemojex.Settle.handle/1,
      connector: conn,
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  defp notify_opts(conn) do
    [
      queue: Codemojex.NotificationWorker.queue(),
      handler: &Codemojex.NotificationWorker.handle/1,
      connector: conn,
      beat_ms: 50,
      lease_ms: 15_000
    ]
  end

  defp command_opts(conn) do
    [
      queue: Codemojex.EchoBot.commands_queue(),
      handler: &Codemojex.CommandWorker.handle/1,
      connector: conn,
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  # --- optional Graft committer ---------------------------------------------

  defp maybe_committer(children, conn) do
    volume = Application.get_env(:codemojex, :graft_volume)

    if is_binary(volume) and Code.ensure_loaded?(EchoStore.Graft.Committer) do
      spec =
        Supervisor.child_spec(
          {EchoStore.Graft.Committer,
           volume_id: volume, conn: Codemojex.Bus, db: graft_db(volume), queue: "cm.graft.commits"},
          id: :cm_committer
        )

      # place the committer before the endpoint
      List.insert_at(children, -2, spec)
    else
      _ = conn
      children
    end
  end

  defp graft_db(volume), do: {:via, Registry, {EchoStore.Graft.Registry, {:store, volume}}}
end
