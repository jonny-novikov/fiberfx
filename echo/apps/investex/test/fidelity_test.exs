defmodule Investex.FidelityTest do
  @moduledoc """
  Tier 1 (pure): the pass-through-fidelity gate (G-FID — NEW, 9.2;
  trd.9.2.specs.md §"The pass-through-fidelity gate"). Network-free, structural.

  The parity scaffold (parity_test.exs) proves existence + arity + RPC-membership,
  but it does NOT prove each read function delegates to the RIGHT stub:
  `def shares(client, r), do: Caller.unary(client, &Stub.bonds/3, r)` COMPILES
  (`bonds` is a real `Stub` fun) AND PASSES the scaffold (the function `shares/2`
  exists, `:Shares` is a real RPC). That copy-paste wrong-stub class is exactly
  what G-FID kills.

  Realization (D-9): read each read module's **source** to AST via
  `Code.string_to_quoted!`, walk each public `def`, and pair its name to the
  `&Stub.<fun>/3` capture in its body. Then assert, for all 41 read functions:

    1. every `def <name>` captures `&Stub.<name>/3` — the def name EQUALS the
       captured stub-fun name (both `snake(RPC)`);
    2. every `def` delegates through the per-service `Stub` alias at arity 3 —
       no function bypasses the one `Caller.unary(client, &Stub.<fun>/3, …)` seam;
    3. the set of def names equals the parity scaffold's set of declared function
       names for that module — no read function is missing or extra.

  Liveness (the gate's teeth): a mutated pairing in any function (Edit `shares`
  → `&Stub.bonds/3`) makes assertion (1) fail (def name `:shares` ≠ capture
  `:bonds`). The Stage-4 mutation spot-check exercises exactly this and reverts
  net-zero; the scaffold alone does NOT turn red on it.
  """
  use ExUnit.Case, async: true

  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  # The 3 read modules and, per module, the parity scaffold's declared function
  # names (the source-of-truth set assertion (3) checks against). Kept here as
  # the snake(RPC) names the scaffold maps — a divergence between this set and
  # the source defs fails (3), so a read function dropped/renamed in EITHER place
  # is caught.
  @read_modules [
    {Investex.Instruments, Proto.InstrumentsService.Service},
    {Investex.MarketData, Proto.MarketDataService.Service},
    {Investex.Operations, Proto.OperationsService.Service}
  ]

  # snake(RPC) for every RPC the service declares — the expected public def-name
  # set for the module, derived from the generated Service (never hardcoded).
  defp expected_fun_names(service) do
    for {rpc_name, _req, _resp, _opts} <- service.__rpc_calls__(),
        into: MapSet.new(),
        do: rpc_name |> to_string() |> Macro.underscore() |> String.to_atom()
  end

  # Parse the module's source to AST and return, for each public `def`, a
  # {def_name, captured_stub_fun, capture_arity} triple. A def whose body has no
  # `&Stub.<fun>/N` capture yields :no_capture (which fails assertion (2)).
  defp def_capture_pairs(module) do
    source = module.module_info(:compile)[:source] |> to_string()
    ast = source |> File.read!() |> Code.string_to_quoted!()

    ast
    |> collect_defs()
    |> Enum.map(fn {name, body} -> {name, stub_capture(body)} end)
  end

  # Walk the module AST collecting {def_name, def_body} for every `def NAME(...)`.
  defp collect_defs(ast) do
    {_ast, defs} =
      Macro.prewalk(ast, [], fn
        {:def, _meta, [head, [do: body]]} = node, acc ->
          {node, [{def_name(head), body} | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(defs)
  end

  # The def name is the first element of the head call: `name(args)` → :name.
  # A guarded head `def name(args) when guard` parses to `{:when, _, [call,
  # guard]}` — recurse past the guard to the underlying call (L-3). The 9.2 read
  # modules are guard-free pass-throughs, so this clause is inert today; it keeps
  # the gate robust against a future guarded read (e.g. a 9.3 branded-ORD guard).
  defp def_name({:when, _meta, [call, _guard]}), do: def_name(call)
  defp def_name({name, _meta, _args}) when is_atom(name), do: name

  # Find a `&Stub.<fun>/N` capture anywhere in the body; return {fun, arity} or
  # :no_capture. The shape (probed): {:&, _, [{:/, _, [{{:., _, [{:__aliases__,
  # _, [:Stub]}, fun]}, _, []}, arity]}]}. Require the alias to be exactly
  # `Stub` (the per-service alias) so a capture of any other module fails (2).
  defp stub_capture(body) do
    {_body, found} =
      Macro.prewalk(body, :no_capture, fn
        {:&, _, [{:/, _, [{{:., _, [{:__aliases__, _, [:Stub]}, fun]}, _, []}, arity]}]} = node,
        :no_capture
        when is_atom(fun) and is_integer(arity) ->
          {node, {fun, arity}}

        node, acc ->
          {node, acc}
      end)

    found
  end

  test "every read function name-matches its &Stub.<fun>/3 capture (G-FID, all 41)" do
    total =
      for {module, _service} <- @read_modules, reduce: 0 do
        acc ->
          pairs = def_capture_pairs(module)

          for {def_name, capture} <- pairs do
            # (2) every def delegates through `&Stub.<fun>/3` — arity 3, the seam.
            assert match?({_fun, 3}, capture),
                   "#{inspect(module)}.#{def_name}/2 does not capture a &Stub.<fun>/3 — " <>
                     "it bypasses the Caller.unary seam (got #{inspect(capture)})"

            {stub_fun, 3} = capture

            # (1) the def name EQUALS the captured stub-fun name (the copy-paste
            # wrong-stub killer: `def shares` → `&Stub.bonds/3` fails here).
            assert def_name == stub_fun,
                   "#{inspect(module)}.#{def_name}/2 delegates to &Stub.#{stub_fun}/3 — " <>
                     "the def name and the stub fun name must match (both snake(RPC))"
          end

          acc + length(pairs)
      end

    # The 3 read modules carry exactly the 41 read functions in total.
    assert total == 41
  end

  test "each read module's def-name set equals the parity scaffold's declared RPC set (G-FID, set-equality)" do
    for {module, service} <- @read_modules do
      def_names =
        module |> def_capture_pairs() |> Enum.map(fn {name, _capture} -> name end) |> MapSet.new()

      expected = expected_fun_names(service)

      assert def_names == expected,
             "#{inspect(module)} read functions diverge from #{inspect(service)} RPCs — " <>
               "missing: #{inspect(MapSet.difference(expected, def_names) |> MapSet.to_list())}, " <>
               "extra: #{inspect(MapSet.difference(def_names, expected) |> MapSet.to_list())}"
    end
  end
end
