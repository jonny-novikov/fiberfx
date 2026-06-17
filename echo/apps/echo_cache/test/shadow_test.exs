defmodule EchoCache.ShadowTest do
  @moduledoc """
  The EchoCache.Shadow extension row (the agent brief, Stage-1c): the pure
  dispatcher — `:none` starts nothing and always answers `:no_replica`;
  `child_spec/1` carries both arms; `{mod, opts}` dispatches `start_link/1`
  and `restore/1` to the chosen implementation, proven through a stub that
  implements the behaviour.
  """
  use ExUnit.Case, async: true

  alias EchoCache.Shadow

  defmodule Stub do
    @behaviour EchoCache.Shadow

    @impl true
    def start_link(opts), do: Agent.start_link(fn -> opts end)

    @impl true
    def restore(opts), do: {:ok, Keyword.fetch!(opts, :answer)}

    @impl true
    def status(server), do: %{opts: Agent.get(server, & &1)}

    @impl true
    def stop(server), do: Agent.stop(server)
  end

  test "start_link(:none) starts nothing" do
    assert Shadow.start_link(:none) == :ignore
  end

  test "restore(:none) always answers :no_replica" do
    assert Shadow.restore(:none) == {:ok, :no_replica}
  end

  test "child_spec(:none) is the transient self-start arm" do
    assert Shadow.child_spec(:none) == %{
             id: EchoCache.Shadow,
             start: {EchoCache.Shadow, :start_link, [:none]},
             restart: :transient
           }
  end

  test "child_spec({mod, opts}) is the permanent worker arm" do
    opts = [db: "/tmp/j.db", dir: "/tmp/rep"]

    assert Shadow.child_spec({EchoCache.Shadow.Copy, opts}) == %{
             id: {EchoCache.Shadow, EchoCache.Shadow.Copy},
             start: {EchoCache.Shadow.Copy, :start_link, [opts]},
             type: :worker,
             restart: :permanent
           }
  end

  test "start_link/1 dispatches to the chosen implementation with its options" do
    assert {:ok, pid} = Shadow.start_link({Stub, [flavor: :laptop]})
    assert Stub.status(pid) == %{opts: [flavor: :laptop]}
    assert :ok = Stub.stop(pid)
  end

  test "restore/1 dispatches to the chosen implementation" do
    assert Shadow.restore({Stub, [answer: :restored]}) == {:ok, :restored}
    assert Shadow.restore({Stub, [answer: :no_replica]}) == {:ok, :no_replica}
  end
end
