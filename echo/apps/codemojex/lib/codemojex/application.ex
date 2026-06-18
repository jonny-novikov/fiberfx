defmodule Codemojex.Application do
  @moduledoc """
  The supervision tree, extended to wire EchoMQ end to end with the bot and the rate-limited
  notification job.

  Order: the relational system of record (`Repo`) and `PubSub` first; then the EchoMQ bus
  (`Bus`, the shared Valkey connector); then the rate limiter and the bot gateway, which the
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
    port = Application.get_env(:codemojex, :valkey_port, 6390)

    children =
      [
        Codemojex.Repo,
        {Phoenix.PubSub, name: Codemojex.PubSub},
        {Codemojex.Bus, port: port},

        # rate limiter + bot must precede the workers that use them
        Codemojex.RateLimiter,
        Codemojex.EchoBot,

        # the existing authorities
        Supervisor.child_spec({EchoMQ.Consumer, score_opts(port)}, id: :cm_score),
        Supervisor.child_spec({EchoMQ.Consumer, settle_opts(port)}, id: :cm_settle),

        # new: the rate-limited notification job, and inbound Telegram commands
        Supervisor.child_spec({EchoMQ.Consumer, notify_opts(port)}, id: :cm_notify),
        Supervisor.child_spec({EchoMQ.Consumer, command_opts(port)}, id: :cm_commands),

        # an in-memory CHAMP view of the leaderboard, rebuildable from Graft via EchoData.ChampView
        {EchoData.ChampServer, name: Codemojex.Leaderboard},

        CodemojexWeb.Endpoint
      ]
      |> maybe_committer(port)

    Supervisor.start_link(children, strategy: :one_for_one, name: Codemojex.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CodemojexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # --- consumer specs --------------------------------------------------------

  defp score_opts(port) do
    [
      queue: Codemojex.ScoreWorker.queue(),
      handler: &Codemojex.ScoreWorker.handle/1,
      connector: [port: port, protocol: 3],
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  defp settle_opts(port) do
    [
      queue: Codemojex.Settle.queue(),
      handler: &Codemojex.Settle.handle/1,
      connector: [port: port, protocol: 3],
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  defp notify_opts(port) do
    [
      queue: Codemojex.NotificationWorker.queue(),
      handler: &Codemojex.NotificationWorker.handle/1,
      connector: [port: port, protocol: 3],
      beat_ms: 50,
      lease_ms: 15_000
    ]
  end

  defp command_opts(port) do
    [
      queue: Codemojex.EchoBot.commands_queue(),
      handler: &Codemojex.CommandWorker.handle/1,
      connector: [port: port, protocol: 3],
      beat_ms: 100,
      lease_ms: 10_000
    ]
  end

  # --- optional Graft committer ---------------------------------------------

  defp maybe_committer(children, port) do
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
      _ = port
      children
    end
  end

  defp graft_db(volume), do: {:via, Registry, {EchoStore.Graft.Registry, {:store, volume}}}
end
