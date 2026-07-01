defmodule Codemojex.GameBundle do
  @moduledoc """
  Arm B of the frontend delivery: pull the React game island from the edge once and
  serve it **same-origin** from memory, so the browser imports the game without a
  cross-origin DNS/TLS hop on the player's critical path (the win on slow Telegram
  mobile). The game still ships independently of this release — only its serve layer
  moves on-machine.

  `Codemojex.Edge` stays the pointer resolver: it reads the `manifest.json` pointer
  and returns the current bundle URL (briefly cached). This module learns the current
  hash from `Edge`, pulls that hash's **bytes** once, and holds
  `{file, bytes, content_type, exp}` in `:persistent_term`. `CodemojexWeb.GameBundleController`
  serves those bytes; `GameLive` puts `src/0` in `data-bundle` and the `GameIsland` hook
  dynamic-imports it from this origin.

  Safe hot replace: the new bytes are `put` only after the full body is fetched, and
  `:persistent_term.put` is atomic — so the old bundle keeps serving until the new one
  is completely in hand, and a half-fetched bundle is never served.

  Like `Edge`, this is process-free: the cache is a global `:persistent_term` read and
  `src/0` refreshes lazily on the render path (TTL-gated). The `:httpc` GET reuses the
  `:inets`/`:ssl` the app already carries (`Edge`/`Telegram` use it) — no new dependency.
  Failure is non-fatal: an unreachable edge serves the last-good bytes; a cold cache
  yields `nil` from `src/0` (the shell renders, the game just does not mount yet — the
  existing deferred state).
  """
  alias Codemojex.Edge

  @pt_key {__MODULE__, :bundle}
  @ttl_ms 10_000
  @content_type "text/javascript"

  @doc """
  The same-origin path `GameLive` writes into `data-bundle`
  (e.g. `/game-bundle/game-<hash>.js`). Refreshes the cached bytes lazily (TTL-gated,
  mirroring `Edge`) before answering; `nil` until the first successful pull.
  """
  def src do
    refresh()

    case cached() do
      {file, _bytes, _ct, _exp} -> "/game-bundle/" <> file
      _ -> nil
    end
  end

  @doc """
  The controller's read: the cached bytes + content-type for `file`, or `:error` when
  `file` is not the currently-held hash — a stale or unknown name is never served.
  """
  def fetch(file) when is_binary(file) do
    case cached() do
      {^file, bytes, ct, _exp} -> {:ok, bytes, ct}
      _ -> :error
    end
  end

  @doc """
  The atomic safe-swap: replace the held bundle with `bytes` for `file`.
  `:persistent_term.put` is atomic and the internal pull calls this only after the full
  body is in hand, so readers see either the whole old bundle or the whole new one —
  never a torn value. Returns `file`.
  """
  def put(file, bytes) when is_binary(file) and is_binary(bytes) do
    :persistent_term.put(@pt_key, {file, bytes, @content_type, now() + @ttl_ms})
    file
  end

  defp cached, do: :persistent_term.get(@pt_key, nil)

  # TTL-gated lazy refresh (mirrors Edge): at most once per @ttl_ms, learn the current
  # hash from the Edge pointer and pull its bytes only when the hash changed.
  defp refresh do
    case cached() do
      {_file, _bytes, _ct, exp} when is_integer(exp) -> if now() >= exp, do: pull_current()
      _ -> pull_current()
    end

    :ok
  end

  defp pull_current do
    case Edge.game_url() do
      url when is_binary(url) ->
        file = Path.basename(url)

        case cached() do
          # same hash: extend the TTL window, no second download
          {^file, bytes, _ct, _exp} -> put(file, bytes)
          # new hash (or cold): fetch FULLY, then atomic put
          _ -> pull_bytes(url, file)
        end

      _ ->
        # pointer unreachable: keep serving last-good (or stay cold)
        :ok
    end
  end

  defp pull_bytes(url, file) do
    case http_get(url) do
      {:ok, bytes} -> put(file, bytes)
      :error -> :ok
    end
  end

  # Reuse the :inets/:ssl httpc already in the app — one GET of the hashed bundle.
  defp http_get(url) do
    request = {String.to_charlist(url), []}
    http_opts = [timeout: 5_000, connect_timeout: 2_000]

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_v, 200, _r}, _headers, body}} when is_binary(body) -> {:ok, body}
      _ -> :error
    end
  end

  defp now, do: System.monotonic_time(:millisecond)
end
