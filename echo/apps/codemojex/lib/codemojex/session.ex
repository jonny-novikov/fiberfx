defmodule Codemojex.Session do
  @moduledoc """
  The auth session surface — mint, resolve (+ slide), revoke — over the
  `:cm_sessions` `EchoStore.Table` (cm.4 §5).

  A session is a `SES`-branded entity in the shared Valkey: a JSON value carrying
  `{plr, platform, …}`, written under the table's sliding TTL with `:tracking`
  coherence. The `PLR` is the durable identity (in Postgres); the `SES` references
  it and is ephemeral (Valkey-TTL + re-handshake on loss).

  - `mint/3` is the SOLE writer — called only at the handshake
    (`POST /api/auth/:platform`), so the read-only-edge model holds: one writer,
    many readers.
  - `resolve/1` is the per-request read; on a hit it re-`put`s the row (the
    sliding-TTL move) and returns the claims, else `{:error, :unknown}` (an
    unknown / expired / revoked `SES` is a clean miss through the table's loader).
  - `revoke/1` drops both layers; the `:tracking` push evicts the row from every
    BEAM holder's L1 immediately, so the next `resolve/1` is `{:error, :unknown}`.

  The value is JSON (`Jason`) — the cross-language contract: `EchoStore.Table.put`
  frames it as `SET ecc:{sessions}:<SES> (version<>json) PX ttl_ms`, and a forward
  Go edge strips the leading 14-byte version, then `json.Unmarshal`s. NEVER
  `:erlang.term_to_binary` (a Go edge cannot decode it).
  """

  alias Codemojex.Tables

  @doc """
  Mint a session for `plr` on `platform`, return its `SES` id.

  The handshake is the only caller (the single-writer model). `attrs` are merged
  into the JSON claims (e.g. `%{"tg_user_id" => uid}`).
  """
  @spec mint(plr :: binary(), platform :: binary(), attrs :: map()) :: {:ok, binary()}
  def mint(plr, platform, attrs \\ %{}) when is_binary(plr) and is_binary(platform) do
    ses = EchoData.BrandedId.generate!("SES")

    json =
      %{"plr" => plr, "platform" => platform, "iat" => unix_now()}
      |> Map.merge(attrs)
      |> Jason.encode!()

    :ok = put_session(ses, json)
    {:ok, ses}
  end

  @doc """
  Resolve a `SES` to its claims and slide the TTL.

  On a hit, decode the JSON, re-`put` it (re-stamping the version + the `PX`
  deadline — the sliding-TTL move), and return `{:ok, %{plr:, platform:}}`. On a
  miss (unknown / expired / revoked), return `{:error, :unknown}`.
  """
  @spec resolve(ses :: binary() | nil) :: {:ok, %{plr: binary(), platform: binary()}} | {:error, :unknown}
  def resolve(ses) when is_binary(ses) do
    case EchoStore.Table.fetch(Tables.sessions_table(), ses) do
      {:ok, json, _source} ->
        claims = Jason.decode!(json)
        # Slide: re-put re-stamps the version + the PX TTL (D-2). The value is
        # written back unchanged, so the JSON contract round-trips byte-identical.
        _ = put_session(ses, json)
        {:ok, %{plr: claims["plr"], platform: claims["platform"]}}

      _other ->
        # {:error, :kind} (a non-SES id) | {:error, :not_found} (a clean miss) |
        # {:error, :no_such_cache} — any non-hit is an unauthenticated outcome.
        {:error, :unknown}
    end
  end

  def resolve(_ses), do: {:error, :unknown}

  @doc """
  Revoke a `SES` — drop it from both layers. `:tracking` pushes the invalidation
  to every L1 (D-2), so the next request with this `SES` 401s.
  """
  @spec revoke(ses :: binary()) :: :ok
  def revoke(ses) when is_binary(ses) do
    case EchoStore.Table.invalidate(Tables.sessions_table(), ses) do
      :ok -> :ok
      # A non-SES id never had a row; treat revocation as idempotent.
      {:error, _} -> :ok
    end
  end

  # -- internals -------------------------------------------------------------

  defp put_session(ses, json) do
    case EchoStore.Table.put(Tables.sessions_table(), ses, json) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp unix_now, do: System.system_time(:second)
end
