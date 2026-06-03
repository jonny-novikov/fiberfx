defmodule PortalWeb.Application do
  @moduledoc false

  use Application

  # The web app supervisor (F6.1-R2, F6.1-INV2). Owns exactly the two web children —
  # telemetry then the endpoint — under :one_for_one, so a crashed endpoint restarts
  # on its own without disturbing telemetry (F6.1-US4). The three F5 domain children
  # live in the separate Portal.Application; the `:portal_web` → `:portal` app
  # dependency boots that tree first, so the store, event-store adapter, and engine
  # are ready before this endpoint accepts traffic. PubSub is declared in config for
  # a later rung but is NOT started here (F6.1 scope).
  @impl true
  def start(_type, _args) do
    children = [
      PortalWeb.Telemetry,
      PortalWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: PortalWeb.Supervisor, max_restarts: 1000, max_seconds: 5]
    Supervisor.start_link(children, opts)
  end

  # Phoenix calls this when the endpoint configuration changes at runtime (e.g. a
  # code reload), so the endpoint picks up the new config without a full restart.
  @impl true
  def config_change(changed, _new, removed) do
    PortalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
