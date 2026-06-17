defmodule EchoCache.Graft.Supervisor do
  @moduledoc """
  Supervises the Graft engine: a `Registry` keying VolumeServers by their `VOL`
  GID, and a `DynamicSupervisor` under which Volumes are started on demand.

  Add to the host application's tree:

      children = [
        EchoCache.Graft.Supervisor
        # ...
      ]
  """
  use Supervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      {Registry, keys: :unique, name: EchoCache.Graft.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: EchoCache.Graft.VolumeSup}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
