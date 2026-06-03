defmodule Portal.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start order is data → compute → web: Portal.Store (state), the configured
    # Portal.EventStore.adapter() (the source-of-truth event stream), and
    # Portal.Engine are ready before Bandit (the front door) accepts traffic. The
    # adapter is started BEFORE Engine and is a separate, longer-lived process: a
    # supervisor evaluates a child's args once, so Engine reads the CURRENT stream
    # through the port in its own init/1 (started plain, not `{Portal.Engine,
    # events}`) — a static event-list arg would re-fold a stale stream on restart
    # (F5.6-INV3). :one_for_one — a crashed Engine restarts on its own and re-folds
    # the live (un-killed) stream; the system stays up (F5.1-INV3). The
    # Portal.EventLog → Portal.EventStore.adapter() swap is the only change from the
    # as-built F5.6 tree (F5.8 wires the adapter the engine reads through;
    # F5.9 confirms it). PortalWeb.Endpoint replaces Bandit at F6.
    children = [
      Portal.Store,
      Portal.EventStore.adapter(),
      Portal.Engine,
      {Bandit, plug: Portal.Web.Router, port: port()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end

  defp port, do: String.to_integer(System.get_env("PORT", "4000"))
end
