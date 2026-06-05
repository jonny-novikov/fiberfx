defmodule PortalWeb.EndpointSupervisionTest do
  @moduledoc """
  Self-heal of the web front door under `:one_for_one` (F6.1-US4, F6.1-INV2).

  Proves: a brutal-killed `PortalWeb.Endpoint` is restarted by `PortalWeb.Supervisor`
  under a fresh pid (the supervisor and sibling telemetry survive), and a request
  serves again. A brutal `Process.exit(ep, :kill)` is the only signal that terminates a
  trap-exit endpoint supervisor. `async: false` — it kills a shared, named process.

  ## Why the recovery barrier polls the config table, stably (the restart-storm race)

  `PortalWeb.Endpoint` is itself a `Supervisor`; on restart the new pid registers the
  INSTANT its supervisor process spawns, but the endpoint's config ETS table (named
  `PortalWeb.Endpoint`, holding `:secret_key_base`) is created and populated by a CHILD
  (`config_children`) AFTER that registration. A brutal kill does not restart once: it
  churns the endpoint's linked `socket "/live"` pool + config server into a measured
  ~200-restart storm. So neither a fresh pid (process up) NOR a single `/health` 200
  (config readable for ONE request, at ONE instant) proves the endpoint is restored —
  the storm can tear the config table down AGAIN after that instant, and a sibling
  endpoint-reader (`Plug.Conn` sets `secret_key_base` from `config(:secret_key_base)`)
  then reads a missing ETS table and raises `ArgumentError`. Process-up != state-ready,
  and ready-once != ready-stable.

  The barrier therefore waits until the EXACT resource the readers consume —
  `PortalWeb.Endpoint.config(:secret_key_base)` — reads non-nil for `@stable_reads`
  CONSECUTIVE polls spanning a window wider than the storm's restart cadence, so the
  test cannot complete on a transient gap-free instant mid-storm and release concurrent
  readers into a later gap (echo/CLAUDE.md §4; the endpoint-kill-restart-storm hazard).
  """
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  @endpoint PortalWeb.Endpoint

  # Consecutive non-nil config reads required to declare the storm settled. One read is
  # a transient edge mid-storm; @stable_reads in a row, @stable_gap apart, span past the
  # restart cadence so the table cannot have been torn down and rebuilt under the streak.
  @stable_reads 25
  @stable_gap 20

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

    # The structural barrier: block until the config table is STABLY readable (the storm
    # has settled), not until a process is up or one /health succeeds. Only then does the
    # endpoint serve a request without racing a sibling reader against a torn-down table.
    assert config_stable?()

    assert eventually(fn ->
             get(build_conn(), "/health").status == 200
           end)
  end

  # Poll until `PortalWeb.Endpoint.config(:secret_key_base)` reads non-nil for
  # @stable_reads consecutive attempts. A read against a not-yet-created config ETS table
  # raises (counted as not-ready by `safe_config_present?`), and a nil read (table present
  # but unpopulated) also resets the streak — so the streak completes only once the table
  # both EXISTS and is POPULATED across the full window, proving the restart storm settled.
  defp config_stable?(tries \\ 200), do: stable_streak(0, tries)

  defp stable_streak(streak, _tries) when streak >= @stable_reads, do: true
  defp stable_streak(_streak, 0), do: false

  defp stable_streak(streak, tries) do
    if safe_config_present?() do
      Process.sleep(@stable_gap)
      stable_streak(streak + 1, tries - 1)
    else
      Process.sleep(@stable_gap)
      stable_streak(0, tries - 1)
    end
  end

  # True only if `config(:secret_key_base)` returns a non-nil value. A raise (the ETS
  # table does not yet exist mid-restart) is the table-absent signal and counts as false.
  defp safe_config_present? do
    try do
      @endpoint.config(:secret_key_base) != nil
    rescue
      _ -> false
    end
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
