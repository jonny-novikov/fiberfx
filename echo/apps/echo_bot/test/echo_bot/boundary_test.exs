defmodule EchoBot.BoundaryTest do
  @moduledoc """
  The boundary invariants as EXECUTED checks (F10.1-INV1, INV3, INV4; US2, US3, US5, US6).

  Several acceptance criteria in `f10.1.stories.md` are stated as a *static search*, a *directory
  check*, or a *behaviour-implementation check* — verifiable by inspection, but inert until a test
  runs them. This module turns each into a check the suite executes, so the no-touch boundary, the
  single vendored-namer rule, the platform-abstraction of the engine core, and the
  Portal-independence of the supervision tree cannot silently regress under a green gate.

  These are source/structure assertions (no live platform, no Portal process required) — they read
  the `apps/echo_bot/lib/` tree and the running supervision tree, never the network.
  """

  use ExUnit.Case, async: true

  alias EchoBot.Bot
  alias EchoBot.Config

  @lib_root Path.expand("../../lib", __DIR__)
  @adapter_rel "echo_bot/platform/telegram.ex"
  @vendor_root Path.expand("../../vendor/ex_gram", __DIR__)

  defp lib_files do
    Path.wildcard(Path.join(@lib_root, "**/*.ex"))
  end

  defp relative_to_lib(path) do
    Path.relative_to(path, @lib_root)
  end

  describe "F10.1-INV1 / US6 — the Portal no-touch boundary (executed static search)" do
    test "no module under apps/echo_bot/lib/ references Portal or PortalWeb" do
      # The story's `grep -rE "Portal|PortalWeb" apps/echo_bot/lib/` must be empty — run it.
      offenders =
        for path <- lib_files(),
            source = File.read!(path),
            String.match?(source, ~r/\bPortal(Web)?\b/),
            do: relative_to_lib(path)

      assert offenders == [],
             "engine code names Portal/PortalWeb (F10.1-INV1 forbids it): #{inspect(offenders)}"
    end

    test "apps/echo_bot/mix.exs does not depend on portal or portal_web" do
      # The dependency-graph criterion: neither Portal app is listed, and `{:portal, in_umbrella:
      # true}` does not appear. Verified through the loaded application spec (deps are resolved).
      {:ok, deps} = :application.get_key(:echo_bot, :applications)
      refute :portal in deps
      refute :portal_web in deps

      # And the source itself declares no portal dependency tuple — scanned over CODE lines only
      # (comment lines are stripped, since the deps/0 docstring documents the deliberate absence
      # with the literal `{:portal, in_umbrella: true}` it forbids).
      code =
        Path.expand("../../mix.exs", __DIR__)
        |> File.read!()
        |> String.split("\n")
        |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
        |> Enum.join("\n")

      refute code =~ ~r/\{:portal(_web)?\s*,/
    end
  end

  describe "F10.1-INV4 / US3 / US5 — the vendored copy is named only by the adapter" do
    test "only EchoBot.Platform.Telegram names a vendored ExGram module" do
      # The single-vendored-namer rule, run: every ExGram mention across lib/ must sit in the one
      # adapter file. (Doc-comment mentions count — INV4 is "no module outside the adapter NAMES a
      # vendored module"; the adapter is the only file with any ExGram token at all, code or doc.)
      namers =
        for path <- lib_files(),
            File.read!(path) =~ ~r/\bExGram\b/,
            do: relative_to_lib(path)

      assert namers == [@adapter_rel],
             "a vendored module is named outside the adapter (F10.1-INV4): #{inspect(namers)}"
    end

    test "the vendored tree carries its README.md and CLAUDE.md governance docs" do
      # US3 first criterion / F10.1-D2: the owned-fork copy ships with provenance + ownership docs.
      assert File.exists?(Path.join(@vendor_root, "README.md"))
      assert File.exists?(Path.join(@vendor_root, "CLAUDE.md"))

      claude = File.read!(Path.join(@vendor_root, "CLAUDE.md"))

      # The owned-fork directive: reachable ONLY through the adapter (the one surviving constraint).
      assert claude =~ "EchoBot.Platform.Telegram"
    end
  end

  describe "F10.1-INV3 / US5 — the engine speaks the platform-adapter behaviour" do
    test "EchoBot.Platform.Telegram implements every EchoBot.Platform callback" do
      # US5 behaviour-implementation check: the adapter declares @behaviour EchoBot.Platform and
      # exports each callback at its declared arity, so the YAML's `platform` field can select it.
      assert EchoBot.Platform in (EchoBot.Platform.Telegram.module_info(:attributes)[:behaviour] ||
                                    [])

      callbacks = EchoBot.Platform.behaviour_info(:callbacks)
      assert {:child_spec, 1} in callbacks
      assert {:send_reply, 3} in callbacks
      assert {:command, 1} in callbacks
      assert {:chat_ref, 1} in callbacks

      for {fun, arity} <- callbacks do
        assert function_exported?(EchoBot.Platform.Telegram, fun, arity),
               "EchoBot.Platform.Telegram is missing the #{fun}/#{arity} callback"
      end
    end
  end

  describe "F10.1-INV1, INV2 / US2 — Portal-independence of the supervision tree" do
    test "EchoBot.Supervisor is alive without requiring Portal's supervision tree" do
      # US2 third criterion, strengthened: the engine's own supervisor is up, and it does NOT
      # require Portal.Supervisor — whether or not Portal happens to be loaded in this node, the
      # engine app stands on its own (F10.1-INV1). The check holds independently of Portal's state.
      assert is_pid(Process.whereis(EchoBot.Supervisor)),
             "EchoBot.Supervisor must be alive on its own"

      # The engine supervises only what it loaded from its own YAML — its child is the bot's own
      # derived id, never a Portal-owned process; no Portal child rides under EchoBot.Supervisor.
      definition = Config.load!(Config.bot_config_path())
      own_child_id = Bot.process_name(definition)

      child_ids =
        EchoBot.Supervisor
        |> Supervisor.which_children()
        |> Enum.map(fn {id, _pid, _type, _mods} -> id end)

      assert own_child_id in child_ids

      assert Enum.all?(child_ids, fn id ->
               id |> to_string() |> String.starts_with?("Elixir.EchoBot.")
             end),
             "a non-EchoBot child is supervised under EchoBot.Supervisor: #{inspect(child_ids)}"
    end
  end
end
