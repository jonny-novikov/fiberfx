defmodule Portal.Repo do
  @moduledoc """
  The Portal persistence Repo (F6.3) — the driven edge over PostgreSQL.

  The ONE Ecto.Repo of the engine app. Only the persistence layer names it: the
  Postgres event-store adapter (`Portal.EventStore.Postgres`) and, later, the F6.4
  Catalog context. The `Portal` facade and every module under `:portal_web` name
  it NEVER (F6.3-INV1, compiler-enforced — `:portal_web` does not depend on Ecto).

  Started as the FIRST supervision child (before the store, the event-store
  adapter, and the engine): the Postgres adapter and the engine's `init/1` read
  THROUGH the Repo, so it must be up first (F6.3-D1, INV-order).
  """
  use Ecto.Repo, otp_app: :portal, adapter: Ecto.Adapters.Postgres
end
