defmodule EchoCache.Shadow.Copy do
  @moduledoc """
  The laptop shadow: periodic `VACUUM INTO` snapshots of a SQLite journal
  into a plain directory, and a restore that copies the snapshot back when
  the live file is missing. Pure Elixir over Exqlite -- no sidecar binary,
  no credentials, no network -- so the journal-under-a-shadow posture from
  Appendix D runs unchanged on a development machine.

  `VACUUM INTO` writes a consistent, compacted snapshot from a live database
  without blocking writers beyond the copy itself, which is the property a
  snapshot shadow needs and a bare file copy of a WAL database does not have.

      {:ok, sh} = EchoCache.Shadow.Copy.start_link(db: db, dir: replica_dir, every_ms: 5_000)
      :ok = EchoCache.Shadow.Copy.sync(sh)        # force one snapshot now
      {:ok, :restored} = EchoCache.Shadow.Copy.restore(db: db, dir: replica_dir)
  """

  @behaviour EchoCache.Shadow
  use GenServer

  @impl EchoCache.Shadow
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))

  @doc "Force one snapshot now; returns :ok or {:error, term}."
  def sync(server), do: GenServer.call(server, :sync, 15_000)

  @impl EchoCache.Shadow
  def status(server), do: GenServer.call(server, :status)

  @impl EchoCache.Shadow
  def stop(server), do: GenServer.stop(server)

  @impl EchoCache.Shadow
  def restore(opts) do
    db = Keyword.fetch!(opts, :db)
    replica = replica_path(db, Keyword.fetch!(opts, :dir))

    cond do
      File.exists?(db) -> {:ok, :no_replica}
      not File.exists?(replica) -> {:ok, :no_replica}
      true ->
        File.mkdir_p!(Path.dirname(db))

        case File.cp(replica, db) do
          :ok -> {:ok, :restored}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc "Where a database's snapshot lives inside the replica directory."
  def replica_path(db, dir), do: Path.join(dir, Path.basename(db))

  @impl GenServer
  def init(opts) do
    db = Keyword.fetch!(opts, :db)
    dir = Keyword.fetch!(opts, :dir)
    every = Keyword.get(opts, :every_ms, 5_000)
    File.mkdir_p!(dir)
    state = %{db: db, dir: dir, every_ms: every, syncs: 0, last_error: nil, timer: nil}
    {:ok, arm(state)}
  end

  @impl GenServer
  def handle_call(:sync, _from, s), do: snapshot(s) |> then(fn {reply, s2} -> {:reply, reply, s2} end)

  def handle_call(:status, _from, s) do
    {:reply, %{db: s.db, dir: s.dir, every_ms: s.every_ms, syncs: s.syncs, last_error: s.last_error}, s}
  end

  @impl GenServer
  def handle_info(:tick, s) do
    {_reply, s2} = snapshot(s)
    {:noreply, arm(s2)}
  end

  defp arm(s) do
    if s.timer, do: Process.cancel_timer(s.timer)
    %{s | timer: Process.send_after(self(), :tick, s.every_ms)}
  end

  defp snapshot(%{db: db} = s) do
    if File.exists?(db) do
      tmp = replica_path(db, s.dir) <> ".tmp"
      final = replica_path(db, s.dir)
      File.rm(tmp)

      with {:ok, conn} <- Exqlite.Sqlite3.open(db),
           :ok <- Exqlite.Sqlite3.execute(conn, "VACUUM INTO '" <> tmp <> "'"),
           :ok <- Exqlite.Sqlite3.close(conn),
           :ok <- File.rename(tmp, final) do
        {:ok, %{s | syncs: s.syncs + 1, last_error: nil}}
      else
        err ->
          File.rm(tmp)
          {{:error, err}, %{s | last_error: err}}
      end
    else
      {:ok, s}
    end
  end
end
