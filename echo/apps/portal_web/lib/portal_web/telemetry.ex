defmodule PortalWeb.Telemetry do
  @moduledoc """
  Telemetry supervisor for the `:portal_web` app (F6.1-R2).

  A `Supervisor` that owns the periodic measurement poller and exposes the metric
  definitions the endpoint emits through `Plug.Telemetry`. The first child of
  `PortalWeb.Application`, started before the endpoint so endpoint-level telemetry
  events have a home from the first request.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  The metric definitions the endpoint emits. Phoenix and Plug instrument the request
  lifecycle; these definitions name the events a reporter would attach to.
  """
  def metrics do
    [
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    # Empty at F6.1; app-specific measurements arrive with the dashboard rung (F6.9).
    []
  end
end
