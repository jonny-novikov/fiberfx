defmodule EchoBot.BoundaryTest do
  @moduledoc """
  The boundary invariants as EXECUTED checks (F10.1-INV3, INV4; US3, US5).

  Several acceptance criteria in `f10.1.stories.md` are stated as a *static search*, a *directory
  check*, or a *behaviour-implementation check* — verifiable by inspection, but inert until a test
  runs them. This module turns each into a check the suite executes, so the single vendored-namer
  rule and the platform-abstraction of the engine core cannot silently regress under a green gate.

  These are source/structure assertions (no live platform required) — they read the
  `apps/echo_bot/lib/` tree, never the network.
  """

  use ExUnit.Case, async: true

  @lib_root Path.expand("../../lib", __DIR__)
  @adapter_rel "echo_bot/platform/telegram.ex"
  @vendor_root Path.expand("../../vendor/ex_gram", __DIR__)

  defp lib_files do
    Path.wildcard(Path.join(@lib_root, "**/*.ex"))
  end

  defp relative_to_lib(path) do
    Path.relative_to(path, @lib_root)
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
end
