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
    #
    # F6.3 inserts Portal.Repo as the FIRST child, so the start order is
    # data → compute: Repo → Store → adapter → Engine. The Postgres event-store
    # adapter and the engine's init/1 read THROUGH the Repo, so it must be up first
    # (F6.3-D1, INV-order). BOOT NOTE: Repo as a child means the tree does NOT boot
    # if Postgres is unreachable or the configured DB is missing — every `iex -S mix`,
    # `mix run`, and the `:portal_web` app (which depends on `:portal`) now require a
    # reachable DB. Run `mix ecto.create` (and `MIX_ENV=test mix ecto.create`) before
    # first boot.
    #
    # F6.7 adds {Phoenix.PubSub, name: Portal.PubSub} as the LAST child (F6.7-D1) — the
    # real-time transport the `Portal.subscribe/1`/`Portal.broadcast/2` facade wrappers
    # name. It lives in THIS (`:portal`) tree, not `:portal_web`, so it is up before the
    # web tier (the `:portal_web` → `:portal` app dependency boots this tree first), which
    # is why PortalWeb.Presence (a web-tier child, pubsub_server: Portal.PubSub) can rely
    # on it. config.exs already declares `pubsub_server: Portal.PubSub` for the Endpoint,
    # so this STARTS the process that key already names — no config change (F6.7-INV5: the
    # only new `:portal` child is Phoenix.PubSub; everything below the facade is unchanged).
    children = [
      Portal.Repo,
      Portal.Store,
      Portal.EventStore.adapter(),
      Portal.Engine,
      {Phoenix.PubSub, name: Portal.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end
end
