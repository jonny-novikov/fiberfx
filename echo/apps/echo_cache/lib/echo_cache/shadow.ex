defmodule EchoCache.Shadow do
  @moduledoc """
  The journal's shadow, made pluggable. A shadow is whatever stands behind a
  SQLite journal file ready to give it back after a box loss: Litestream
  replicating to object storage in production, a plain snapshot directory on a
  laptop, or nothing at all. One contract covers them so the supervisor and
  the restore path never know which one is wired.

  Implementations: `EchoCache.Litestream` (object-storage replica via the
  litestream sidecar; the committed Appendix D path) and
  `EchoCache.Shadow.Copy` (pure Elixir, `VACUUM INTO` snapshots to a local
  directory -- zero binaries, zero credentials, runs anywhere Exqlite runs,
  a development laptop included).

  Wire by tuple: `{EchoCache.Litestream, dir: ..., bucket: ...}` or
  `{EchoCache.Shadow.Copy, db: ..., dir: ...}` or `:none`.
  """

  @typedoc "A shadow choice: implementation module plus its options, or :none."
  @type choice :: {module(), keyword()} | :none

  @doc "Start the shadow's process, if it has one."
  @callback start_link(keyword()) :: GenServer.on_start()

  @doc """
  Rebuild a missing journal file from the replica. `{:ok, :restored}` when a
  file was written, `{:ok, :no_replica}` when the replica holds nothing,
  `{:error, term}` otherwise. Implementations must be restore-if-missing:
  an existing live file is never overwritten.
  """
  @callback restore(keyword()) :: {:ok, :restored | :no_replica} | {:error, term()}

  @doc "The shadow's health, as a map."
  @callback status(GenServer.server()) :: map()

  @doc "Stop the shadow's process."
  @callback stop(GenServer.server()) :: :ok

  @doc "Start a chosen shadow; :none starts nothing."
  @spec start_link(choice()) :: GenServer.on_start() | :ignore
  def start_link(:none), do: :ignore
  def start_link({mod, opts}), do: mod.start_link(opts)

  @doc "Restore through a chosen shadow; :none always answers :no_replica."
  @spec restore(choice()) :: {:ok, :restored | :no_replica} | {:error, term()}
  def restore(:none), do: {:ok, :no_replica}
  def restore({mod, opts}), do: mod.restore(opts)

  @doc "Child spec for supervision trees; :none yields no child."
  def child_spec(:none), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [:none]}, restart: :transient}

  def child_spec({mod, opts}) do
    %{id: {__MODULE__, mod}, start: {mod, :start_link, [opts]}, type: :worker, restart: :permanent}
  end
end
