defmodule EchoMQ do
  @moduledoc """
  EchoMQ - A powerful, fast, and robust job queue for Elixir backed by Redis.

  EchoMQ is a message queue and job scheduler that uses Redis as its backend.
  It provides a simple and reliable way to process background jobs with support
  for job priorities, retries, rate limiting, and distributed processing.

  ## Features

  * **Reliable job processing** - Jobs are persisted in Redis and survive crashes
  * **Concurrency control** - Process multiple jobs in parallel with configurable limits
  * **Rate limiting** - Control job processing rate per queue
  * **Job priorities** - Process high-priority jobs first
  * **Delayed jobs** - Schedule jobs to run at a specific time
  * **Job scheduling** - Create recurring jobs with cron expressions
  * **Retries with backoff** - Automatic retries with configurable backoff strategies
  * **Parent-child jobs** - Create job flows with dependencies
  * **Events** - Subscribe to job lifecycle events
  * **Stalled job recovery** - Automatic detection and recovery of stalled jobs
  * **Distributed processing** - Run workers across multiple nodes
  * **OpenTelemetry support** - Distributed tracing across services (compatible with Node.js)

  ## Quick Start

  Add EchoMQ to your supervision tree:

      defmodule MyApp.Application do
        use Application

        def start(_type, _args) do
          children = [
            # Start the Redis connection pool
            {EchoMQ.RedisConnection, name: :echomq_redis, url: "redis://localhost:6379"},

            # Start a worker
            {EchoMQ.Worker,
              name: :my_worker,
              queue: "my_queue",
              connection: :echomq_redis,
              processor: &MyApp.JobProcessor.process/1,
              concurrency: 10}
          ]

          opts = [strategy: :one_for_one, name: MyApp.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

  Add jobs to the queue:

      # Add a simple job
      {:ok, job} = EchoMQ.Queue.add("my_queue", "email", %{to: "user@example.com"})

      # Add a delayed job
      {:ok, job} = EchoMQ.Queue.add("my_queue", "email", %{to: "user@example.com"},
        delay: :timer.minutes(5))

      # Add a job with retries
      {:ok, job} = EchoMQ.Queue.add("my_queue", "email", %{to: "user@example.com"},
        attempts: 3,
        backoff: %{type: :exponential, delay: 1000})

  ## Architecture

  EchoMQ uses Redis Lua scripts for atomic operations on job state transitions.
  This ensures reliability and consistency even in distributed environments.

  The main components are:

  * `EchoMQ.Queue` - For adding jobs and managing queue state
  * `EchoMQ.Worker` - For processing jobs with configurable concurrency
  * `EchoMQ.Job` - Represents a job with its data and state
  * `EchoMQ.QueueEvents` - For subscribing to job lifecycle events
  * `EchoMQ.JobScheduler` - For creating recurring jobs

  ## Job States

  Jobs transition through the following states:

  * `:waiting` - Job is waiting to be processed
  * `:active` - Job is currently being processed
  * `:delayed` - Job is delayed and will be processed later
  * `:prioritized` - Job is in the priority queue
  * `:completed` - Job completed successfully
  * `:failed` - Job failed after all retries
  * `:waiting_children` - Parent job waiting for children to complete

  ## Compatibility

  This Elixir implementation is fully compatible with the Node.js EchoMQ library.
  Jobs can be added from Node.js and processed in Elixir, or vice versa.
  """

  @doc """
  Returns the current EchoMQ version.
  """
  @spec version() :: String.t()
  def version, do: "1.3.0"

  @doc """
  Returns the library identifier used in queue metadata.

  Note: This returns "echomq" for Redis key compatibility with Node.js BullMQ.
  The Elixir module is EchoMQ but shares Redis storage format with Node.js.
  """
  @spec library_name() :: String.t()
  def library_name, do: "echomq"
end
