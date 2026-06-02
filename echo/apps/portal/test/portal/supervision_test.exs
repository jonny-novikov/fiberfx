defmodule Portal.SupervisionTest do
  # Not async: it kills the shared, named Portal.Engine process.
  use ExUnit.Case, async: false

  test "killing Portal.Engine restarts it and the boundary still answers (F5.1-INV3)" do
    pid = Process.whereis(Portal.Engine)
    assert is_pid(pid)

    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1_000

    new_pid = wait_for_restart(pid)
    assert is_pid(new_pid) and new_pid != pid

    # The supervised boundary answers again after the restart (an incomplete
    # command is rejected with a tagged tuple — the point is that it replies).
    assert {:error, _} = Portal.Engine.dispatch(%{type: :enroll})
  end

  defp wait_for_restart(old_pid, tries \\ 50)
  defp wait_for_restart(_old_pid, 0), do: flunk("Portal.Engine did not restart")

  defp wait_for_restart(old_pid, tries) do
    case Process.whereis(Portal.Engine) do
      nil -> retry(old_pid, tries)
      ^old_pid -> retry(old_pid, tries)
      new_pid -> new_pid
    end
  end

  defp retry(old_pid, tries) do
    Process.sleep(20)
    wait_for_restart(old_pid, tries - 1)
  end
end
