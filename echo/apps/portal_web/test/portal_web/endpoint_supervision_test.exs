defmodule PortalWeb.EndpointSupervisionTest do
  @moduledoc """
  Self-heal of the web front door (F6.1-US4, F6.1-INV2).

  Kills `PortalWeb.Endpoint` with a brutal `:kill` and asserts the `:one_for_one`
  `PortalWeb.Supervisor` restarts it under a fresh pid, leaving the supervisor and
  sibling telemetry up — a transient endpoint crash must not take the platform down.
  `async: false` because it terminates a shared, named process.

  ## Test isolation after a brutal kill (RK-5 determinism)

  The endpoint is a `shutdown: :infinity` supervisor over a deep linked child tree (its
  config server and the 16-way `Phoenix.Socket.PoolSupervisor` the declared LiveView
  socket starts). A brutal `Process.exit(ep, :kill)` — the only signal that terminates
  a trap-exit supervisor; a non-`:kill` reason is merely trapped and does NOT kill it —
  tears that whole tree down at once and the supervisor's rebuild is a short restart
  BURST: the endpoint pid churns and its config ETS table (named after the endpoint
  module, holding e.g. `:secret_key_base`) is mid-repopulation. The endpoint is shared
  application state, so a later (sequential — `async: false`) test dispatching through a
  still-rebuilding endpoint would hit `:ets.lookup(PortalWeb.Endpoint, :secret_key_base)`
  on a torn/incomplete table → an `ArgumentError` → a 500: a cross-test flake, not a
  product bug.

  This test therefore does not return until the burst has SETTLED and the endpoint is
  ready for the next test: it waits for the precise operation a later dispatch performs
  — reading `:secret_key_base` from the config ETS table — to succeed across several
  CONSECUTIVE samples under one STABLE pid (a single clean sample is not enough: the
  burst can briefly look settled and then re-kill the endpoint). Polling that resource
  directly avoids dispatching through the still-settling socket pool.
  """
  use ExUnit.Case, async: false

  test "killing PortalWeb.Endpoint restarts it under the supervisor (F6.1-INV2)" do
    sup = Process.whereis(PortalWeb.Supervisor)
    assert is_pid(sup)

    ep1 = Process.whereis(PortalWeb.Endpoint)
    assert is_pid(ep1)

    ref = Process.monitor(ep1)
    Process.exit(ep1, :kill)
    assert_receive {:DOWN, ^ref, :process, ^ep1, :killed}, 1_000

    # The self-heal: the supervisor restarts the endpoint under a fresh pid (the actual
    # F6.1-US4 requirement).
    ep2 = wait_for_restart(ep1)
    assert is_pid(ep2) and ep2 != ep1

    # The supervisor and the sibling telemetry survived the one-child restart.
    assert Process.whereis(PortalWeb.Supervisor) == sup
    assert is_pid(Process.whereis(PortalWeb.Telemetry))

    # A request SUCCEEDS again after the restart (F6.1-US4): the restored endpoint's
    # config table is readable — the exact operation a later dispatch performs — across
    # a sustained run of samples, so the next sequential test inherits a ready endpoint
    # (RK-5).
    assert wait_for_ready()
  end

  defp wait_for_restart(old_pid, tries \\ 100)
  defp wait_for_restart(_old_pid, 0), do: flunk("PortalWeb.Endpoint did not restart")

  defp wait_for_restart(old_pid, tries) do
    case Process.whereis(PortalWeb.Endpoint) do
      nil -> retry(old_pid, tries)
      ^old_pid -> retry(old_pid, tries)
      new_pid -> new_pid
    end
  end

  defp retry(old_pid, tries) do
    Process.sleep(20)
    wait_for_restart(old_pid, tries - 1)
  end

  @ready_tries 500
  @ready_sleep_ms 20
  # The burst can briefly look settled (one clean sample) then re-kill the endpoint, so
  # require this many CONSECUTIVE ready samples — same pid + a readable config table —
  # to prove it has truly settled before returning.
  @ready_streak 15

  # Ready = the precise operation a later dispatch performs — reading `:secret_key_base`
  # from the endpoint's config ETS table — succeeds for `@ready_streak` CONSECUTIVE
  # samples under one STABLE pid. A read raises (or the pid changes) while the burst is
  # in flight, which resets the streak; only a sustained clean run proves the endpoint
  # has settled, so the next sequential dispatch cannot hit a torn-down table (RK-5).
  defp wait_for_ready(tries \\ @ready_tries, last \\ :none, streak \\ 0)

  defp wait_for_ready(0, _last, _streak),
    do: flunk("PortalWeb.Endpoint did not become ready after restart")

  defp wait_for_ready(_tries, _last, streak) when streak >= @ready_streak, do: true

  defp wait_for_ready(tries, last, streak) do
    pid = Process.whereis(PortalWeb.Endpoint)
    next_streak = if is_pid(pid) and pid == last and config_readable?(), do: streak + 1, else: 0

    Process.sleep(@ready_sleep_ms)
    wait_for_ready(tries - 1, pid, next_streak)
  end

  defp config_readable? do
    :ets.lookup(PortalWeb.Endpoint, :secret_key_base) != []
  rescue
    ArgumentError -> false
  end
end
