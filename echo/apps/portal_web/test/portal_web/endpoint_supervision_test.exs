defmodule PortalWeb.EndpointSupervisionTest do
  @moduledoc """
  Self-heal of the web front door under `:one_for_one` (F6.1-US4, F6.1-INV2).

  Proves: a brutal-killed `PortalWeb.Endpoint` is restarted by `PortalWeb.Supervisor`
  under a fresh pid (the supervisor and sibling telemetry survive), and a request
  serves again. A brutal `Process.exit(ep, :kill)` is the only signal that terminates a
  trap-exit endpoint supervisor; `eventually/2` polls `/health` until `200`, which
  absorbs the restart's config-rebuild readiness window. `async: false` — it kills a
  shared, named process.
  """
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  @endpoint PortalWeb.Endpoint

  test "killing PortalWeb.Endpoint restarts it and serves again (F6.1-US4, F6.1-INV2)" do
    sup = Process.whereis(PortalWeb.Supervisor)
    ep1 = Process.whereis(PortalWeb.Endpoint)
    assert is_pid(sup) and is_pid(ep1)

    ref = Process.monitor(ep1)
    Process.exit(ep1, :kill)
    assert_receive {:DOWN, ^ref, :process, ^ep1, :killed}, 1_000

    assert eventually(fn ->
             ep2 = Process.whereis(PortalWeb.Endpoint)
             is_pid(ep2) and ep2 != ep1
           end)

    assert Process.whereis(PortalWeb.Supervisor) == sup
    assert is_pid(Process.whereis(PortalWeb.Telemetry))

    assert eventually(fn ->
             get(build_conn(), "/health").status == 200
           end)
  end

  # Poll a 0-arity boolean predicate until true or `tries` exhaust, sleeping between
  # attempts; an exception (a request against a mid-rebuild endpoint) counts as false.
  defp eventually(fun, tries \\ 100)
  defp eventually(_fun, 0), do: false

  defp eventually(fun, tries) do
    if (try do
          fun.()
        rescue
          _ -> false
        end) do
      true
    else
      Process.sleep(20)
      eventually(fun, tries - 1)
    end
  end
end
