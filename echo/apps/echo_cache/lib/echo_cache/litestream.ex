defmodule EchoCache.Litestream do
  @moduledoc """
  The journal's shadow: Litestream supervised as a sidecar, streaming every
  per-group journal in a directory to S3-compatible object storage, with
  restore as the recovery verb the node-death drill runs before the journal
  reopens. The division of labor is the one Chapter 4.4 named and this
  appendix completes: the journal is the synchronous truth beside the bus,
  and the shadow is an asynchronous copy of that truth beside the box —
  a separate process by design, owned here only as a supervised child.

  One server covers one journal directory. On boot it discovers (or is
  given) the group journals, refuses any file whose group is not a branded
  id — the kind law holds at the shadow's door as it does everywhere else —
  renders a Litestream config naming each database and its replica URL,
  and spawns the binary under a monitored Port. Credentials travel in the
  environment, never in the config. The sidecar is restarted with bounded
  backoff if it exits, and on terminate it receives SIGTERM by exact OS
  pid — this module never signals by name.

  `restore/1` is a module function, not a server call, because restore
  runs when nothing else does: given the same shape of options, it asks
  Litestream to rebuild a group's database file from its replica, and
  reports `:restored`, `:no_replica`, or the error. `prepare/1` runs the
  restore-if-missing pass across every group — the first line of the
  node-death runbook.
  """

  @behaviour EchoCache.Shadow
  use GenServer
  require Logger

  alias EchoData.BrandedId

  @default_endpoint "fly.storage.tigris.dev"
  @default_region "auto"
  @default_prefix "shadow"
  @max_restarts 3

  # -- surface -----------------------------------------------------------------

  @impl EchoCache.Shadow
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "The sidecar's health: OS pid, restart count, config path, covered groups."
  @impl EchoCache.Shadow
  def status(server), do: GenServer.call(server, :status)

  @impl EchoCache.Shadow
  def stop(server), do: GenServer.stop(server)

  @doc """
  Rebuild one group's journal file from its replica. Returns
  `{:ok, :restored}` when a file was written, `{:ok, :no_replica}` when the
  replica holds nothing for this group, `{:error, output}` otherwise.
  """
  @impl EchoCache.Shadow
  def restore(opts) do
    dir = Keyword.fetch!(opts, :dir)
    group = Keyword.fetch!(opts, :group)
    binary = binary!(opts)
    out = Keyword.get(opts, :output, db_path(dir, group))

    {output, code} =
      System.cmd(binary, ["restore", "-if-replica-exists", "-o", out, replica_url(group, opts)],
        stderr_to_stdout: true
      )

    cond do
      code == 0 and File.exists?(out) -> {:ok, :restored}
      code == 0 -> {:ok, :no_replica}
      true -> {:error, String.trim(output)}
    end
  end

  @doc """
  The node-death runbook's first line: for every group, restore the journal
  file if it is missing. Returns `[{group, :restored | :no_replica | :present}]`.
  """
  def prepare(opts) do
    dir = Keyword.fetch!(opts, :dir)

    for group <- groups!(opts) do
      if File.exists?(db_path(dir, group)) do
        {group, :present}
      else
        {:ok, verdict} = restore(Keyword.put(opts, :group, group))
        {group, verdict}
      end
    end
  end

  @doc "The replica URL for a group, exactly as the config and restore use it."
  def replica_url(group, opts) do
    bucket = Keyword.fetch!(opts, :bucket)
    prefix = Keyword.get(opts, :prefix, @default_prefix)
    endpoint = Keyword.get(opts, :endpoint, @default_endpoint)
    region = Keyword.get(opts, :region, @default_region)
    "s3://#{bucket}/#{prefix}/#{group}?endpoint=#{endpoint}&region=#{region}"
  end

  # -- owner -------------------------------------------------------------------

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    dir = Keyword.fetch!(opts, :dir)
    binary = binary!(opts)
    groups = groups!(opts)
    if groups == [], do: raise(ArgumentError, "no group journals to shadow under #{dir}")

    config_path = Path.join(dir, "litestream.yml")
    File.write!(config_path, render_config(dir, groups, opts))

    state = %{
      dir: dir,
      binary: binary,
      config: config_path,
      groups: groups,
      opts: opts,
      restarts: 0,
      port: nil,
      os_pid: nil
    }

    {:ok, spawn_sidecar(state)}
  end

  @impl true
  def handle_call(:status, _from, s) do
    {:reply, %{os_pid: s.os_pid, restarts: s.restarts, config: s.config, groups: s.groups}, s}
  end

  @impl true
  def handle_info({port, {:data, line}}, %{port: port} = s) do
    Logger.info("litestream: " <> String.trim_trailing(line))
    {:noreply, s}
  end

  def handle_info({port, {:exit_status, code}}, %{port: port} = s) do
    if s.restarts < @max_restarts do
      backoff = 200 * (s.restarts + 1)
      Logger.warning("litestream exited (#{code}); restart #{s.restarts + 1} in #{backoff}ms")
      Process.sleep(backoff)
      {:noreply, spawn_sidecar(%{s | restarts: s.restarts + 1})}
    else
      {:stop, {:litestream_exited, code}, s}
    end
  end

  def handle_info({:EXIT, port, _reason}, %{port: port} = s), do: {:noreply, s}
  def handle_info(_msg, s), do: {:noreply, s}

  @impl true
  def terminate(_reason, %{os_pid: os_pid, port: port}) do
    if is_integer(os_pid), do: System.cmd("kill", ["-TERM", Integer.to_string(os_pid)])
    if is_port(port) and port in Port.list(), do: Port.close(port)
    :ok
  end

  # -- internals -----------------------------------------------------------------

  defp spawn_sidecar(s) do
    port =
      Port.open({:spawn_executable, s.binary}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: ["replicate", "-config", s.config]
      ])

    os_pid =
      case Port.info(port, :os_pid) do
        {:os_pid, pid} -> pid
        _ -> nil
      end

    %{s | port: port, os_pid: os_pid}
  end

  defp render_config(dir, groups, opts) do
    sync = Keyword.get(opts, :sync_interval)

    dbs =
      Enum.map_join(groups, "", fn group ->
        """
          - path: #{db_path(dir, group)}
            replicas:
              - url: #{replica_url(group, opts)}
        """ <> if(sync, do: "        sync-interval: #{sync}\n", else: "")
      end)

    "dbs:\n" <> dbs
  end

  defp groups!(opts) do
    case Keyword.get(opts, :groups, :auto) do
      :auto ->
        opts
        |> Keyword.fetch!(:dir)
        |> File.ls!()
        |> Enum.flat_map(fn
          "journal-" <> rest ->
            case String.split(rest, ".db") do
              [group, ""] -> [validate_group!(group)]
              _ -> []
            end

          _ ->
            []
        end)
        |> Enum.sort()

      groups when is_list(groups) ->
        Enum.map(groups, &validate_group!/1)
    end
  end

  defp validate_group!(group) do
    unless BrandedId.valid?(group) do
      raise(ArgumentError, "the shadow refuses a non-branded group: #{inspect(group)}")
    end

    group
  end

  defp db_path(dir, group), do: Path.join(dir, "journal-" <> group <> ".db")

  defp binary!(opts) do
    binary = Keyword.get(opts, :binary) || System.find_executable("litestream")

    unless is_binary(binary) and File.exists?(binary) do
      raise(ArgumentError, "litestream binary not found; pass binary: /path/to/litestream")
    end

    binary
  end
end
