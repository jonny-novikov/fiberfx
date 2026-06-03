defmodule PortalWeb.Application do
  @moduledoc false

  use Application

  # The web app supervisor (F6.1-R2, F6.1-INV2). Owns the two web children — telemetry
  # then the endpoint — under :one_for_one, so a killed endpoint restarts without
  # disturbing telemetry (F6.1-US4). The F5 domain children live in the separate
  # Portal.Application; the `:portal_web` → `:portal` app dependency boots that tree
  # first, so store, event-store adapter, and engine are ready before traffic.
  @impl true
  def start(_type, _args) do
    children = [
      PortalWeb.Telemetry,
      PortalWeb.Endpoint
    ]

    # A brutal endpoint kill churns its linked LiveView-socket subtree into a measured
    # ~200-restart storm within max_seconds; the OTP default (3) gives up and the app
    # exits. 300 absorbs the measured ceiling (~218) with margin, still bounded.
    opts = [strategy: :one_for_one, name: PortalWeb.Supervisor, max_restarts: 300, max_seconds: 5]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
