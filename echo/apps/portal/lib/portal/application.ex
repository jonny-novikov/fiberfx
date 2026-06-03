defmodule Portal.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Start order is data → compute: Portal.Store (state), the configured
    # Portal.EventStore.adapter() (the source-of-truth event stream), and
    # Portal.Engine. The adapter is started BEFORE Engine and is a separate,
    # longer-lived process: a supervisor evaluates a child's args once, so Engine
    # reads the CURRENT stream through the port in its own init/1 (started plain, not
    # `{Portal.Engine, events}`) — a static event-list arg would re-fold a stale
    # stream on restart (F5.6-INV3). :one_for_one — a crashed Engine restarts on its
    # own and re-folds the live (un-killed) stream; the system stays up (F5.1-INV3).
    #
    # At F6.1 the F5 Bandit front door is DROPPED from this tree (four → three): the
    # web layer moves to the new `:portal_web` app, whose PortalWeb.Application owns
    # [PortalWeb.Telemetry, PortalWeb.Endpoint]. The `:portal_web` → `:portal` app
    # dependency boots this tree first, so the store/adapter/engine are ready before
    # the endpoint accepts traffic (F6.1-INV2). Portal.Store is RETAINED — it is the
    # dual-write %Enrollment{} read model `Portal.courses_of/1` reads, so omitting it
    # would crash every course render (F6.1-D2, RK-1).
    children = [
      Portal.Store,
      Portal.EventStore.adapter(),
      Portal.Engine
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end
end
