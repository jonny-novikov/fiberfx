defmodule PortalWeb.Application do
  @moduledoc false

  use Application

  # The web app supervisor (F6.1-R2, F6.1-INV2). Owns the web children — telemetry, the
  # endpoint, then (F6.7-D5) PortalWeb.Presence — under :one_for_one, so a killed endpoint
  # restarts without disturbing telemetry (F6.1-US4). The F5 domain children live in the
  # separate Portal.Application; the `:portal_web` → `:portal` app dependency boots that
  # tree first, so store, event-store adapter, engine, AND Portal.PubSub are ready before
  # traffic. PortalWeb.Presence (pubsub_server: Portal.PubSub) is a web-tier process placed
  # here, not in :portal, and relies on that boot order so its PubSub server is up first
  # (F6.7-INV5: the only new :portal_web child is Presence).
  @impl true
  def start(_type, _args) do
    children = [
      PortalWeb.Telemetry,
      PortalWeb.Endpoint,
      PortalWeb.Presence
    ]

    # A brutal endpoint kill churns its linked LiveView-socket subtree into a restart
    # storm within max_seconds; the OTP default (3) gives up and the app exits. The storm
    # peak is LOAD-GATED: ~200-218 on a quiet box, but under CPU contention (the full
    # async umbrella saturating all schedulers) the socket-pool drainer churn densifies
    # and a single-kill storm was MEASURED at ~310 restart units — over the prior `300`
    # ceiling, which surfaced as a probabilistic `Application portal_web exited: shutdown`
    # in the ≥100 determinism loop (the supervisor gave up mid-storm, taking the endpoint's
    # config ETS table down for the rest of the run and failing every sibling test). 1000
    # clears the measured ~310 worst case with a 3.2x margin so a LEGITIMATE transient
    # endpoint-crash storm self-heals, yet stays bounded: a GENUINE restart loop (a child
    # that cannot stay up) restarts continuously and still trips 1000 well inside
    # max_seconds: 5 (~40ms per transient storm ⇒ a real loop blows past 1000 in <1s), so
    # the supervisor still gives up on an unrecoverable child. The storm settles in ~40ms,
    # far inside the 5s window — max_restarts, not max_seconds, is the lever.
    opts = [strategy: :one_for_one, name: PortalWeb.Supervisor, max_restarts: 1000, max_seconds: 5]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
