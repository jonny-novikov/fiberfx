defmodule Codemojex.Edge do
  @moduledoc """
  The seam that lets the React board ship independently of this machine.

  The board bundle lives at edge.codemoji.games (a dedicated Tigris public bucket,
  separate from the static welcome bucket) under a content-hashed name; a small
  `manifest.json` pointer at the bucket root names the current hash. `board_url/0`
  reads that pointer at runtime — cached for a few seconds — and returns the URL
  `GameLive` renders into the board mount point. The browser dynamic-imports it.
  `BOARD_EDGE_HOST` overrides the host (dev/staging point elsewhere).

  Promotion is therefore an edge operation: `scripts/edge-deploy.sh` uploads a new
  hashed bundle and rewrites `manifest.json`; within the cache TTL this machine
  serves the new URL. No `mix release`, no `fly deploy`, no socket drop. The Engine
  contract (the props shape `GameLive` sends and the events it accepts) is the only
  thing that must stay compatible across a swap — see the board props in `GameLive`.
  Bucket + domain setup: `echo/docs/codemojex/edge-bucket-setup.md`.

  Failure is non-fatal: an unreachable pointer falls back to `BOARD_ASSET_URL`
  (a per-deploy env default), so the board still loads if the bucket blips. The
  cache is `:persistent_term` — no process, a global read on the render path.
  """
  @pt_key {__MODULE__, :board_url}
  @ttl_ms 10_000
  @default_edge_host "edge.codemoji.games"

  @doc "The current board bundle URL, pointer-resolved and briefly cached."
  def board_url do
    case cached() do
      url when is_binary(url) -> url
      _ -> resolve_and_cache()
    end
  end

  defp cached do
    case :persistent_term.get(@pt_key, nil) do
      {url, exp} when is_binary(url) -> if now() < exp, do: url, else: nil
      _ -> nil
    end
  end

  defp resolve_and_cache do
    url = fetch_pointer() || fallback()
    if is_binary(url), do: :persistent_term.put(@pt_key, {url, now() + @ttl_ms})
    url
  end

  # The app already carries :inets + :ssl (Codemojex.Telegram uses httpc); reuse it
  # for one small GET of the pointer rather than adding an HTTP client dependency.
  # The board bundle's public host; BOARD_EDGE_HOST overrides the default so dev or
  # staging can point at another bucket. The deploy script writes manifest.json
  # against the same host.
  defp pointer do
    host = System.get_env("BOARD_EDGE_HOST") || @default_edge_host
    "https://" <> host <> "/manifest.json"
  end

  defp fetch_pointer do
    request = {String.to_charlist(pointer()), []}
    http_opts = [timeout: 1_500, connect_timeout: 1_000]

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_v, 200, _r}, _headers, body}} -> parse(body)
      _ -> nil
    end
  end

  defp parse(body) do
    case Jason.decode(body) do
      {:ok, %{"board" => url}} when is_binary(url) -> url
      _ -> nil
    end
  end

  defp fallback, do: System.get_env("BOARD_ASSET_URL")
  defp now, do: System.monotonic_time(:millisecond)
end
