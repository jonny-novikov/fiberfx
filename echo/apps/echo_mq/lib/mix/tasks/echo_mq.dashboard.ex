defmodule Mix.Tasks.EchoMq.Dashboard do
  @shortdoc "Render a cat-able ANSI operator dashboard for the live EchoMQ bus"

  @moduledoc """
  A read-only ANSI operator dashboard for the bus — the live-introspection
  sibling of `mix echo_mq.stories`. It connects to a running Valkey (the bus
  engine on `:6390`), reads through the as-built `EchoMQ.Metrics` pure-read
  plane, and renders the boxed house-style panels (see `EchoMQ.Dashboard`). It
  writes nothing and opens no new wire — every read is grounded.

      mix echo_mq.dashboard                       # discover queues, render each queue's depths
      mix echo_mq.dashboard orders payments       # those queues explicitly (skip discovery)
      mix echo_mq.dashboard --job JOB… --queue q   # the inspection panel for one job
      mix echo_mq.dashboard --lanes               # add the per-queue active-lane sub-panel
      mix echo_mq.dashboard --host 127.0.0.1 --port 6390   # defaults shown

  The empty bus renders the NAMED empty case (no `emq:*` keys → an empty queue
  is invisible to SCAN); a missing job and a per-queue read error are likewise
  named, never faked into a confident zero.
  """

  use Mix.Task

  alias EchoMQ.Dashboard

  @switches [host: :string, port: :integer, job: :string, queue: :string, lanes: :boolean]

  @impl Mix.Task
  def run(argv) do
    {opts, queues, _invalid} = OptionParser.parse(argv, strict: @switches)

    # compile the app so EchoMQ.Dashboard / Metrics / Connector are loadable
    # (the echo_mq.stories pattern, stories task:39).
    Mix.Task.run("compile")

    host = opts[:host] || "127.0.0.1"
    port = opts[:port] || 6390
    stamp = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_string()

    case connect(host, port) do
      {:ok, conn} ->
        out = build(conn, opts, queues, stamp)
        GenServer.stop(conn)
        IO.write([out, "\n"])

      {:error, reason} ->
        Mix.shell().error("could not connect to the bus at #{host}:#{port} — #{inspect(reason)}")
        Mix.shell().error("is Valkey up? `valkey-cli -p #{port} ping` should answer PONG.")
        exit({:shutdown, 1})
    end
  end

  # The Connector host default is {127,0,0,1}; a "1.2.3.4" string is parsed to
  # the tuple it expects. A bare hostname falls through as a charlist (gen_tcp
  # resolves it).
  defp connect(host, port) do
    EchoMQ.Connector.start_link(host: host_arg(host), port: port)
  rescue
    e -> {:error, e}
  catch
    :exit, reason -> {:error, reason}
  end

  defp host_arg(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, tuple} -> tuple
      {:error, _} -> String.to_charlist(host)
    end
  end

  # -- the two modes --------------------------------------------------------

  # job inspection takes precedence when --job is present (--queue defaults to
  # "default"); otherwise the depths panel over explicit-or-discovered queues.
  defp build(conn, opts, queues, stamp) do
    case opts[:job] do
      job_id when is_binary(job_id) ->
        queue = opts[:queue] || "default"
        result = Dashboard.fetch_job(conn, queue, job_id)
        Dashboard.render_job(queue, job_id, result, stamp)

      _ ->
        depths_mode(conn, opts, queues, stamp)
    end
  end

  # depths: explicit queues, else discover. The empty/error cases are named.
  defp depths_mode(conn, opts, explicit_queues, stamp) do
    case resolve_queues(conn, explicit_queues) do
      {:error, reason} ->
        Dashboard.frame("EchoMQ · queue depths", "read-only · #{stamp}")
        |> then(fn head ->
          [head, "\n  \e[31m! discovery failed: #{inspect(reason)}\e[0m\n"]
        end)

      {:ok, []} ->
        Dashboard.render_no_queues(stamp)

      {:ok, queues} ->
        per_queue = Enum.map(queues, fn q -> {q, Dashboard.fetch_depths(conn, q)} end)
        depths = Dashboard.render_depths(per_queue, stamp)

        lanes =
          if opts[:lanes] do
            lane_results = Enum.map(queues, fn q -> {q, Dashboard.fetch_lanes(conn, q)} end)
            ["\n", Dashboard.render_lanes(lane_results, stamp)]
          else
            []
          end

        [depths, lanes]
    end
  end

  defp resolve_queues(_conn, [_ | _] = explicit), do: {:ok, Enum.sort(explicit)}
  defp resolve_queues(conn, []), do: Dashboard.discover_queues(conn)
end
