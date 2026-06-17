defmodule Mix.Tasks.Investex.GenProto do
  @shortdoc "Regenerate the committed Tinkoff Invest proto modules (protoc-gen-elixir)"

  @moduledoc """
  Regenerates the committed generated message + service-stub modules under
  `apps/investex/lib/investex/proto/` from the 8 committed Tinkoff Invest
  contracts (rung TRD.9.1, `docs/exchange/trd.9.1.specs.md` §"committed
  codegen", D-1).

  The generated tree is **committed** and protoc stays off the compile path
  (the spec's binding Mars note); this task exists so the codegen is
  reproducible and documented — run it only when the upstream contracts change,
  then commit the regenerated output.

  ## Prerequisites

    * `protoc` on `PATH` (libprotoc 33.x — it bundles `google/protobuf/*` the
      well-known types the contracts import).
    * `protoc-gen-elixir`, the plugin shipped by the `:protobuf` hex package, at
      the version matching the `:protobuf` runtime dep. Install once with
      `mix escript.install hex protobuf <version> --force`; it lands in the
      asdf-managed mix escripts dir, NOT on `PATH`, so this task resolves it via
      `mix escript` and passes `--plugin=` explicitly.

  ## What it does

  Runs protoc with `-I <proto-dir>` (so the bare `import "common.proto"` and
  `import "google/protobuf/timestamp.proto"` resolve) over all 8 contracts WITH
  the gRPC plugin (`--elixir_out=plugins=grpc:<out>`), so each service's `.Stub`
  module is emitted alongside the message structs. The namespace protoc-gen-elixir
  derives from the proto `package tinkoff.public.invest.api.contract.v1` is
  `Tinkoff.Public.Invest.Api.Contract.V1.*` (R-1) — the generated files are not
  hand-edited.

  ## Usage

      mix investex.gen_proto
      mix investex.gen_proto --proto-dir /path/to/contracts/proto

  The default `--proto-dir` is the gitignored vendored SDK at
  `github.local/invest-api-go-sdk/proto` relative to the umbrella root.
  """

  use Mix.Task

  # The 8 committed contracts (trd.9.1.specs.md §"committed Tinkoff Invest
  # contracts"). All 8 are generated — not only the 3 the 9.1 trio needs —
  # because sandbox.proto imports orders/operations (transitively instruments)
  # and the later rungs (9.2-9.5) inherit the full generated tree + every Stub.
  @contracts ~w(
    common.proto instruments.proto marketdata.proto operations.proto
    orders.proto sandbox.proto stoporders.proto users.proto
  )

  @out_dir "lib/investex/proto"

  # This task file lives at apps/investex/lib/mix/tasks/, so the investex app
  # root is 3 levels up (tasks → mix → lib). The vendored SDK proto dir sits
  # under the REPO root (apps/investex → apps → echo → jonnify, 3 more), under
  # `github.local`. Anchoring on `__DIR__` keeps the task build-dir-agnostic
  # (Application.app_dir/1 points into `_build`, the wrong tree for source).
  @app_root Path.expand("../../..", __DIR__)
  @default_proto_dir Path.expand("../../../github.local/invest-api-go-sdk/proto", @app_root)

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [proto_dir: :string])
    app_dir = @app_root

    proto_dir =
      opts
      |> Keyword.get(:proto_dir, @default_proto_dir)
      |> Path.expand()

    unless File.dir?(proto_dir) do
      Mix.raise("proto dir not found: #{proto_dir} (pass --proto-dir)")
    end

    plugin = resolve_plugin()
    out = Path.join(app_dir, @out_dir)
    File.mkdir_p!(out)

    args =
      [
        "-I",
        proto_dir,
        "--plugin=protoc-gen-elixir=#{plugin}",
        "--elixir_out=plugins=grpc:#{out}"
      ] ++ @contracts

    Mix.shell().info("protoc -I #{proto_dir} --elixir_out=plugins=grpc:#{out} (8 contracts)")

    case System.cmd("protoc", args, cd: proto_dir, stderr_to_stdout: true) do
      {_, 0} ->
        Mix.shell().info("regenerated #{length(@contracts)} contracts into #{@out_dir}")

      {output, code} ->
        Mix.raise("protoc failed (exit #{code}):\n#{output}")
    end
  end

  # protoc-gen-elixir is installed as a mix escript, not on PATH. Locate it in
  # the mix escripts dir; fail loudly with the install hint if absent.
  defp resolve_plugin do
    escripts = Path.join(Mix.Utils.mix_home(), "escripts")
    plugin = Path.join(escripts, "protoc-gen-elixir")

    if File.exists?(plugin) do
      plugin
    else
      Mix.raise(
        "protoc-gen-elixir not found at #{plugin}. " <>
          "Install it: mix escript.install hex protobuf --force"
      )
    end
  end
end
