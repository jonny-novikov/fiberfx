defmodule Portal.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start order is data → compute → web: Portal.Store (state), Portal.EventLog
    # (the source-of-truth log), and Portal.Engine are ready before Bandit (the
    # front door) accepts traffic. EventLog is started BEFORE Engine and is a
    # separate, longer-lived process: a supervisor evaluates a child's args once,
    # so Engine reads the CURRENT log in its own init/1 (started plain, not
    # `{Portal.Engine, events}`) — a static event-list arg would re-fold a stale
    # log on restart (F5.6-INV3). :one_for_one — a crashed Engine restarts on its
    # own and re-folds the live (un-killed) log; the system stays up (F5.1-INV3).
    # PortalWeb.Endpoint replaces Bandit at F6.
    children = [
      Portal.Store,
      Portal.EventLog,
      Portal.Engine,
      {Bandit, plug: Portal.Web.Router, port: port()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end

  defp port, do: String.to_integer(System.get_env("PORT", "4000"))
end
