defmodule Codemojex.GameBundleTest do
  @moduledoc """
  Arm B (frontend-delivery gate G9): the in-memory pull cache that serves the React
  game island same-origin. These assert the **atomic safe-swap** and the serve
  contract WITHOUT the network — `put/2` seeds the cache with a fresh TTL, so `src/0`'s
  lazy refresh is a no-op and the held bytes are exactly what `fetch/1` (the
  controller's read) returns. No edge is contacted.
  """
  use ExUnit.Case, async: false

  alias Codemojex.GameBundle

  # mirrors GameBundle's private @pt_key {__MODULE__, :bundle}
  @pt_key {Codemojex.GameBundle, :bundle}

  setup do
    # the cache is a global :persistent_term — start cold and erase after each test so
    # one test's bundle never leaks into another (or into a GameLive test calling src/0)
    :persistent_term.erase(@pt_key)
    on_exit(fn -> :persistent_term.erase(@pt_key) end)
    :ok
  end

  test "cold cache: fetch/1 refuses every name (nothing pulled yet, no network)" do
    assert GameBundle.fetch("game-anything.js") == :error
  end

  test "src/0 returns the same-origin path for the currently-held bundle" do
    GameBundle.put("game-abc123.js", "export function mount(){}")
    # fresh TTL → refresh is a no-op → no edge pull
    assert GameBundle.src() == "/game-bundle/game-abc123.js"
  end

  test "fetch/1 serves the held bytes as text/javascript and refuses any other name" do
    GameBundle.put("game-abc123.js", "BYTES_A")
    assert {:ok, "BYTES_A", "text/javascript"} = GameBundle.fetch("game-abc123.js")
    # a stale/unknown hash is never served — the pointer never names a missing file
    assert :error = GameBundle.fetch("game-other.js")
  end

  test "put/2 is an atomic swap: only the current hash serves; the prior hash 404s" do
    GameBundle.put("game-v1.js", "V1")
    assert {:ok, "V1", _ct} = GameBundle.fetch("game-v1.js")

    # the safe hot replace — a reader sees the whole new bundle or the whole old one,
    # never a torn value, and the superseded hash stops serving immediately
    GameBundle.put("game-v2.js", "V2")
    assert {:ok, "V2", "text/javascript"} = GameBundle.fetch("game-v2.js")
    assert :error = GameBundle.fetch("game-v1.js")
  end
end
