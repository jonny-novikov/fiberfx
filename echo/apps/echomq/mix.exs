defmodule EchoMQ.MixProject do
  use Mix.Project

  @version "1.3.0"
  @source_url "https://github.com/codemoji/echomq"
  @description "EchoMQ: Unified Polyglot Message Queue - BEAM-native job processing with OTP supervision"

  def project do
    [
      app: :echomq,
      version: @version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      package: package(),
      description: @description,

      # Docs
      name: "EchoMQ",
      source_url: @source_url,
      homepage_url: "https://echomq.codemoji.io",
      docs: docs(),

      # Dialyzer
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit],
        flags: [
          :error_handling,
          :missing_return,
          :underspecs,
          :unknown
        ]
      ],

      # Test coverage
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # EchoData - Branded IDs and CHAMP data structures (in umbrella)
      {:echo_data, in_umbrella: true},

      # Redis client
      {:redix, "~> 1.3"},

      # Connection pooling
      {:nimble_pool, "~> 1.0"},

      # Configuration validation
      {:nimble_options, "~> 1.0"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # Cron expression parsing
      {:crontab, "~> 1.1"},

      # MessagePack encoding for Lua scripts
      {:msgpax, "~> 2.4"},

      # UUID generation
      {:elixir_uuid, "~> 1.2"},

      # Telemetry for instrumentation
      {:telemetry, "~> 1.2"},

      # OpenTelemetry for distributed tracing (optional)
      {:opentelemetry_api, "~> 1.0", optional: true},

      # Development and test dependencies
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.1", only: :test},
      {:stream_data, "~> 1.0", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      name: "echomq",
      # Note: Lua scripts must be included in priv/scripts for the package to work.
      # They are copied from ../rawScripts via `yarn copy:lua:elixir` before release.
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "Documentation" => "https://echomq.codemoji.io"
      },
      maintainers: ["Codemoji Team"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md": [title: "Overview"],
        "CHANGELOG.md": [title: "Changelog"],
        "guides/introduction.md": [title: "Introduction"],
        "guides/getting_started.md": [title: "Getting Started"],
        "guides/job_options.md": [title: "Job Options"],
        "guides/workers.md": [title: "Workers"],
        "guides/manual_processing.md": [title: "Manual Job Processing"],
        "guides/job_cancellation.md": [title: "Job Cancellation"],
        "guides/deduplication.md": [title: "Deduplication"],
        "guides/queue_events.md": [title: "Queue Events"],
        "guides/job_schedulers.md": [title: "Job Schedulers"],
        "guides/rate_limiting.md": [title: "Rate Limiting"],
        "guides/flows.md": [title: "Flows & Parent-Child Jobs"],
        "guides/telemetry.md": [title: "Telemetry"],
        "guides/scaling.md": [title: "Scaling"],
        "guides/benchmarks.md": [title: "Benchmarks"]
      ],
      groups_for_extras: [
        Guides: ~r/guides\/.*/
      ],
      groups_for_modules: [
        Core: [
          EchoMQ,
          EchoMQ.Queue,
          EchoMQ.Worker,
          EchoMQ.Job
        ],
        Configuration: [
          EchoMQ.Config,
          EchoMQ.Types
        ],
        Events: [
          EchoMQ.QueueEvents,
          EchoMQ.Telemetry
        ],
        Scheduling: [
          EchoMQ.JobScheduler,
          EchoMQ.Backoff
        ],
        Advanced: [
          EchoMQ.FlowProducer,
          EchoMQ.RateLimiter,
          EchoMQ.StalledChecker
        ],
        Internal: [
          EchoMQ.Scripts,
          EchoMQ.Keys,
          EchoMQ.RedisConnection
        ]
      ],
      nest_modules_by_prefix: [EchoMQ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install"],
      test: ["test"],
      "test.watch": ["test.watch"],
      lint: ["format --check-formatted", "credo --strict", "dialyzer"],
      "scripts.copy": &copy_lua_scripts/1
    ]
  end

  # Copy Lua scripts from rawScripts to priv/scripts
  # This ensures scripts are available at compile time
  defp copy_lua_scripts(_args) do
    source_dir = Path.expand("../rawScripts", __DIR__)
    target_dir = Path.expand("priv/scripts", __DIR__)

    File.mkdir_p!(target_dir)

    case File.ls(source_dir) do
      {:ok, files} ->
        lua_files = Enum.filter(files, &String.ends_with?(&1, ".lua"))

        Enum.each(lua_files, fn file ->
          source = Path.join(source_dir, file)
          target = Path.join(target_dir, file)
          File.cp!(source, target)
        end)

        Mix.shell().info("Copied #{length(lua_files)} Lua scripts to priv/scripts/")

      {:error, reason} ->
        Mix.raise("Failed to read rawScripts directory: #{inspect(reason)}")
    end
  end
end
