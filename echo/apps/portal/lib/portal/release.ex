defmodule Portal.Release do
  @moduledoc """
  Release-native database tasks (F6.8.2-D5, INV1).

  A built release carries no `mix`, so migrations cannot run via `mix ecto.migrate`.
  This module is the ops entry point invoked on the deploy machine via
  `bin/portal eval "Portal.Release.migrate()"` — it loads the app, starts the repo
  in isolation through `Ecto.Migrator.with_repo/2`, runs the migrations, and stops.
  The deploy sequence runs `migrate/0` BEFORE `bin/portal start`, so the schema is
  current before the endpoint accepts traffic.

  It names `Portal.Repo` (the F6.3 repo) — a release/ops task that lives OUTSIDE the
  web boundary, so the master invariant (a web/facade concern) is not in scope for
  it: this is not web code and does not reach the engine.
  """

  @app :portal

  @doc """
  Migrates `Portal.Repo` up to the latest version.

  Loads the `:portal` application (so the repo config and the bundled migrations are
  available without booting the full supervision tree) and runs every pending
  migration. Invoked release-native via `bin/portal eval "Portal.Release.migrate()"`.
  """
  @spec migrate() :: :ok
  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    :ok
  end

  @doc """
  Rolls `repo` back to (and including) `version`.

  Invoked release-native via
  `bin/portal eval "Portal.Release.rollback(Portal.Repo, <version>)"`.
  """
  @spec rollback(Ecto.Repo.t(), integer()) :: {:ok, term(), term()}
  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
