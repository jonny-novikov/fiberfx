defmodule EchoStore.Tigris do
  @moduledoc """
  A native-BEAM S3 client for Tigris (Fly.io's globally distributed,
  S3-compatible object storage). No external binary — this replaces the
  Litestream sidecar with in-BEAM HTTP: SigV4 signing on `:crypto`, transport on
  stdlib `:httpc`. No new hex dependency.

  Tigris speaks the S3 API with AWS Signature Version 4. The single global
  endpoint is `https://t3.storage.dev` from outside Fly and
  `https://fly.storage.tigris.dev` from within Fly; the SigV4 region is `auto`.
  Conditional writes are supported through request headers: `If-None-Match: "*"`
  is create-only (a PUT fails with HTTP 412 if the key exists), and
  `X-Tigris-Consistent: true` forces the conditional — and consistent reads — to
  the leader. That conditional create is the primitive the Graft commit log uses
  to serialize commits across writers at the object store.

  Configuration is read from the Fly-injected secrets by default:

      AWS_ENDPOINT_URL_S3  (endpoint, default https://t3.storage.dev)
      AWS_REGION           (region, default "auto")
      AWS_ACCESS_KEY_ID    (tid_...)
      AWS_SECRET_ACCESS_KEY (tsec_...)
      BUCKET_NAME          (bucket)
  """
  @service "s3"
  @algorithm "AWS4-HMAC-SHA256"

  @type config :: %{
          endpoint: binary(),
          region: binary(),
          access_key_id: binary(),
          secret_access_key: binary(),
          bucket: binary()
        }

  @type response :: {:ok, status :: pos_integer(), headers :: list(), body :: binary()} | {:error, term()}

  @doc "Builds a config from options, falling back to the Fly-injected env."
  @spec config(keyword()) :: config()
  def config(opts \\ []) do
    %{
      endpoint: opt(opts, :endpoint, "AWS_ENDPOINT_URL_S3", "https://t3.storage.dev"),
      region: opt(opts, :region, "AWS_REGION", "auto"),
      access_key_id: opt(opts, :access_key_id, "AWS_ACCESS_KEY_ID", nil),
      secret_access_key: opt(opts, :secret_access_key, "AWS_SECRET_ACCESS_KEY", nil),
      bucket: opt(opts, :bucket, "BUCKET_NAME", nil)
    }
  end

  @doc """
  PUT an object. Options:

    * `:create_only` — when true, sends `If-None-Match: "*"` (PUT fails 412 if it exists)
    * `:consistent`  — when true, sends `X-Tigris-Consistent: true`
    * `:content_type` — defaults to `application/octet-stream`
  """
  @spec put_object(config(), binary(), binary(), keyword()) :: response()
  def put_object(cfg, key, body, opts \\ []) when is_binary(body) do
    headers =
      []
      |> maybe([{"if-none-match", "*"}], opts[:create_only])
      |> maybe([{"x-tigris-consistent", "true"}], opts[:consistent])

    request(cfg, "PUT", key, %{}, body, headers, opts[:content_type] || "application/octet-stream")
  end

  @doc "GET an object. `:consistent` adds `X-Tigris-Consistent: true` (leader read)."
  @spec get_object(config(), binary(), keyword()) :: response()
  def get_object(cfg, key, opts \\ []) do
    headers = maybe([], [{"x-tigris-consistent", "true"}], opts[:consistent])
    request(cfg, "GET", key, %{}, "", headers, nil)
  end

  @doc "DELETE an object."
  @spec delete_object(config(), binary()) :: response()
  def delete_object(cfg, key), do: request(cfg, "DELETE", key, %{}, "", [], nil)

  @doc "ListObjectsV2 under `prefix` (returns the raw S3 XML body)."
  @spec list_objects_v2(config(), binary()) :: response()
  def list_objects_v2(cfg, prefix) do
    request(cfg, "GET", "", %{"list-type" => "2", "prefix" => prefix}, "", [], nil)
  end

  # --- request assembly + SigV4 ------------------------------------------

  @spec request(config(), binary(), binary(), map(), binary(), list(), binary() | nil) :: response()
  def request(cfg, method, key, query, body, extra_headers, content_type) do
    {{y, mo, d}, {h, mi, s}} = :calendar.universal_time()
    amz_date = :io_lib.format("~4..0B~2..0B~2..0BT~2..0B~2..0B~2..0BZ", [y, mo, d, h, mi, s]) |> to_string()
    date_stamp = binary_part(amz_date, 0, 8)

    host = host_of(cfg.endpoint)
    payload_hash = hex(:crypto.hash(:sha256, body))
    canonical_uri = canonical_path(cfg.bucket, key)
    canonical_query = canonical_query(query)

    base = [
      {"host", host},
      {"x-amz-content-sha256", payload_hash},
      {"x-amz-date", amz_date}
      | extra_headers
    ]

    sorted = base |> Enum.map(fn {k, v} -> {String.downcase(k), String.trim("#{v}")} end) |> Enum.sort()
    signed_headers = sorted |> Enum.map(&elem(&1, 0)) |> Enum.join(";")
    canonical_headers = sorted |> Enum.map_join(fn {k, v} -> k <> ":" <> v <> "\n" end)

    canonical_request =
      Enum.join([method, canonical_uri, canonical_query, canonical_headers, signed_headers, payload_hash], "\n")

    scope = Enum.join([date_stamp, cfg.region, @service, "aws4_request"], "/")

    string_to_sign =
      Enum.join([@algorithm, amz_date, scope, hex(:crypto.hash(:sha256, canonical_request))], "\n")

    signature = hex(:crypto.mac(:hmac, :sha256, signing_key(cfg.secret_access_key, date_stamp, cfg.region), string_to_sign))

    authorization =
      "#{@algorithm} Credential=#{cfg.access_key_id}/#{scope}, SignedHeaders=#{signed_headers}, Signature=#{signature}"

    url = cfg.endpoint <> canonical_uri <> if(canonical_query == "", do: "", else: "?" <> canonical_query)
    headers = [{"authorization", authorization} | base]
    http(method, url, headers, content_type, body)
  end

  defp signing_key(secret, date_stamp, region) do
    ["AWS4" <> secret, date_stamp, region, @service, "aws4_request"]
    |> Enum.reduce(fn step, key -> :crypto.mac(:hmac, :sha256, key, step) end)
  end

  # --- HTTP (:httpc) ------------------------------------------------------
  defp http(method, url, headers, content_type, body) do
    verb = method |> String.downcase() |> String.to_atom()
    hdrs = Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist("#{v}")} end)

    request =
      if verb in [:put, :post] do
        {to_charlist(url), hdrs, to_charlist(content_type || "application/octet-stream"), body}
      else
        {to_charlist(url), hdrs}
      end

    http_opts = [timeout: 30_000, connect_timeout: 10_000, ssl: tls_opts()]

    case :httpc.request(verb, request, http_opts, body_format: :binary) do
      {:ok, {{_v, status, _r}, resp_headers, resp_body}} -> {:ok, status, resp_headers, resp_body}
      {:error, reason} -> {:error, reason}
    end
  end

  # System trust store (OTP 25+), verified peer.
  defp tls_opts do
    [verify: :verify_peer, cacerts: :public_key.cacerts_get(), depth: 3,
     customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)]]
  end

  # --- canonicalization helpers ------------------------------------------
  defp host_of(endpoint), do: endpoint |> URI.parse() |> Map.fetch!(:host)

  # path-style: /{bucket}/{key}, each segment RFC3986-unreserved-encoded, "/" kept
  defp canonical_path(bucket, ""), do: "/" <> uri_seg(bucket)
  defp canonical_path(bucket, key) do
    segs = key |> String.split("/") |> Enum.map(&uri_seg/1) |> Enum.join("/")
    "/" <> uri_seg(bucket) <> "/" <> segs
  end

  defp uri_seg(s), do: URI.encode(s, &URI.char_unreserved?/1)

  defp canonical_query(query) when map_size(query) == 0, do: ""
  defp canonical_query(query) do
    query
    |> Enum.map(fn {k, v} -> {uri_seg("#{k}"), uri_seg("#{v}")} end)
    |> Enum.sort()
    |> Enum.map_join("&", fn {k, v} -> k <> "=" <> v end)
  end

  defp hex(bin), do: Base.encode16(bin, case: :lower)

  defp maybe(headers, _add, falsy) when falsy in [nil, false], do: headers
  defp maybe(headers, add, _truthy), do: headers ++ add

  defp opt(opts, key, env, default), do: opts[key] || System.get_env(env) || default
end
