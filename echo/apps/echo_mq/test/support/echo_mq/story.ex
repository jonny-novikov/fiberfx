defmodule EchoMQ.Story do
  @moduledoc """
  A tiny BDD layer over `ExUnit` so an echo_mq acceptance test is **self-documenting**:
  the same `feature` / `scenario` / `given_` / `when_` / `then_` source is BOTH a
  runnable ExUnit test driving the real EchoMQ surface AND the source of a generated
  story. `mix echo_mq.stories` reads each story module's `__stories__/0` and writes the
  Given/When/Then acceptance criteria to `docs/echo_mq/stories/<feature>.stories.md`.

  A story line exists in the catalogue **only because** a test that exercises the real
  code compiled and registered — documentation that lies would fail to compile.

      defmodule EchoMQ.Stories.FlowsStoryTest do
        use EchoMQ.Story, feature: "Flows", async: false
        @moduletag :valkey

        # ... ExUnit `setup` providing %{conn: conn, q: q} ...

        scenario "a parent runs on the results its children produced", %{conn: conn, q: q} do
          given_ "a single-queue flow of a parent and two children" do
            {:ok, {parent, [c1, c2]}} = Flows.add(conn, q, flow_of(2))
          end

          when_ "both children complete carrying distinct results" do
            [r1, r2] = complete_each(conn, q)
          end

          then_ "children_values reads the results back keyed by child id" do
            assert {:ok, %{^c1 => ^r1, ^c2 => ^r2}} = Flows.children_values(conn, q, parent)
          end
        end
      end

  ## How it works

  - `scenario/2,3` emits a real `ExUnit` test (so the acceptance criteria are *proven*,
    against Valkey, every `mix test --include valkey` run) AND registers the scenario's
    step descriptions, harvested from the scenario block's **AST at compile time**.
  - `given_` / `when_` / `then_` / `and_` / `but_` expand to their body **inline**, so a
    variable bound in `given_` is visible in `then_` (one shared test scope) — the steps
    read as prose but execute as ordinary sequential code.
  - The description strings are doc-only (harvested separately); the generator never has
    to *run* the suite — it reads `__stories__/0` from the compiled module.
  """

  # the recognised step keywords, in the order they read
  @steps [:given_, :when_, :then_, :and_, :but_]

  defmacro __using__(opts) do
    {feature, ex_opts} = Keyword.pop(opts, :feature)

    feature ||
      raise ArgumentError,
            ~s(use EchoMQ.Story requires a :feature, e.g. `use EchoMQ.Story, feature: "Flows"`)

    slug =
      feature
      |> to_string()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    quote do
      use ExUnit.Case, unquote(ex_opts)
      import EchoMQ.Story, only: [scenario: 2, scenario: 3, given_: 2, when_: 2, then_: 2, and_: 2, but_: 2]
      Module.register_attribute(__MODULE__, :story_scenarios, accumulate: true)
      @story_feature unquote(feature)
      @story_slug unquote(slug)
      @before_compile EchoMQ.Story
    end
  end

  @doc "A scenario with no ExUnit context bound."
  defmacro scenario(title, do: block), do: build_scenario(title, quote(do: _), block)

  @doc "A scenario binding the ExUnit context (e.g. `%{conn: conn, q: q}`)."
  defmacro scenario(title, context, do: block), do: build_scenario(title, context, block)

  # `given_`/`when_`/`then_`/`and_`/`but_` run their body inline; the description is
  # doc-only (harvested from the scenario AST by `build_scenario/3`).
  defmacro given_(_text, do: block), do: block
  defmacro when_(_text, do: block), do: block
  defmacro then_(_text, do: block), do: block
  defmacro and_(_text, do: block), do: block
  defmacro but_(_text, do: block), do: block

  defmacro __before_compile__(env) do
    feature = Module.get_attribute(env.module, :story_feature)
    slug = Module.get_attribute(env.module, :story_slug)
    scenarios = env.module |> Module.get_attribute(:story_scenarios) |> Enum.reverse()

    quote do
      @doc false
      def __stories__ do
        %{
          feature: unquote(feature),
          slug: unquote(slug),
          scenarios: unquote(Macro.escape(scenarios))
        }
      end
    end
  end

  # -- internals -------------------------------------------------------------

  # Emit a real ExUnit test (qualified so it resolves in the caller's context,
  # not this module's) AND register the harvested steps.
  defp build_scenario(title, context, block) do
    steps = harvest_steps(block)

    quote do
      @story_scenarios %{title: unquote(title), steps: unquote(Macro.escape(steps))}

      ExUnit.Case.test unquote(title), unquote(context) do
        unquote(block)
      end
    end
  end

  # Walk the scenario block's AST and collect each step keyword's leading string
  # literal, in source order — `[{:given_, "..."}, {:when_, "..."}, ...]`.
  defp harvest_steps(block) do
    {_ast, acc} =
      Macro.prewalk(block, [], fn
        {step, _meta, [text | _]} = node, acc when step in @steps and is_binary(text) ->
          {node, [{step, text} | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(acc)
  end
end
