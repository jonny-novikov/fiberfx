defmodule Codemojex.Application do
  @moduledoc """
  The supervision tree. The relational system of record (`Repo`) and `PubSub` come
  up first, then the EchoMQ bus (the shared Valkey connector that backs the
  leaderboard, locks, and live counters) and the two consumers (the single scoring
  authority and the settlement worker), then the Phoenix endpoint. BCS identity
  comes from `echo_data` (started ahead of this app as a dependency); EchoStore, if
  present, layers its L1 cache over the Repo on its own.
  """
  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:codemojex, :valkey_port, 6390)

    children = [
      Codemojex.Repo,
      {Phoenix.PubSub, name: Codemojex.PubSub},
      {Codemojex.Bus, port: port},
      Supervisor.child_spec({EchoMQ.Consumer, score_opts(port)}, id: :cm_score),
      Supervisor.child_spec({EchoMQ.Consumer, settle_opts(port)}, id: :cm_settle),
      CodemojexWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Codemojex.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CodemojexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

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
end
