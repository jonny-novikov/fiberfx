import Config

# Runtime configuration (F6.1) — evaluated at boot in every environment. The HTTP
# port and the endpoint secret resolve from the environment so a release carries no
# baked-in secret. The test environment sets `server: false` + a dummy
# secret_key_base in config/test.exs, so this block keeps the suite from binding a
# port (RK-5, the :4000 TIME_WAIT race) and never demands a real secret under test.
if config_env() != :test do
  # A dev fallback keeps `mix phx.server` / `iex -S mix` runnable with no env set; a
  # production boot must supply SECRET_KEY_BASE (no insecure default leaks to prod).
  # `config_env/0` is bound to a var first — it is a macro that cannot be called from
  # inside a guard.
  env = config_env()

  secret_key_base =
    case {System.get_env("SECRET_KEY_BASE"), env} do
      {nil, :prod} ->
        raise """
        environment variable SECRET_KEY_BASE is missing.
        Generate one with: mix phx.gen.secret
        """

      {nil, _} ->
        # Dev/runtime fallback: a fixed 64-byte string, used only outside :prod.
        String.duplicate("0", 64)

      {value, _} ->
        value
    end

  port = String.to_integer(System.get_env("PORT", "4000"))

  # The deploy bind (F6.8.2-D3, INV3 — the F6.6 loopback finding). Under prod/release
  # the endpoint must bind {0,0,0,0} so the Fly edge proxy can reach it; under dev it
  # stays loopback (127.0.0.1) so a local boot is not exposed on all interfaces.
  bind_ip =
    if env == :prod do
      {0, 0, 0, 0}
    else
      {127, 0, 0, 1}
    end

  # The server toggle (F6.8.2-D4). Under prod/release the HTTP listener starts only
  # when PHX_SERVER is set (fly.toml sets `PHX_SERVER=true`), so a `bin/portal eval`
  # migration run does not bind a port; this gate is read at BOOT, not baked at
  # compile time. Under dev/non-test it stays `true` so a bare `iex -S mix` / `mix
  # phx.server` keeps the F6.1 behavior (an HTTP node on :4000).
  server? =
    if env == :prod do
      System.get_env("PHX_SERVER") in ~w(true 1)
    else
      true
    end

  config :portal_web, PortalWeb.Endpoint,
    http: [ip: bind_ip, port: port],
    secret_key_base: secret_key_base,
    server: server?

  # PHX_HOST (F6.8.2-D3, INV2) — the Portal's OWN host, read at runtime into the
  # endpoint `url` host for URL generation. OPERATOR-PINNED to `echo-portal.fly.dev`
  # (set in fly.toml). It is NOT `:deep_link_base_url` (the strangler-fig FALLBACK
  # origin, which STAYS `https://jonnify.fly.dev` at the config.exs:46 default below
  # — two hosts, two keys). The fixed url shape (`port: 443, scheme: "https"`) is set
  # compile-time in prod.exs (D4); this runtime block supplies only the host so the
  # two merge under :prod. Read ONLY under :prod: a missing PHX_HOST fails the boot
  # loudly (it joins the SECRET_KEY_BASE/DATABASE_URL raises); dev keeps the
  # config.exs `url: [host: "localhost"]` untouched (no http/https override leaks to
  # the dev endpoint).
  if env == :prod do
    host =
      System.get_env("PHX_HOST") ||
        raise """
        environment variable PHX_HOST is missing.
        For example: echo-portal.fly.dev
        """

    config :portal_web, PortalWeb.Endpoint, url: [host: host]
  end

  # Portal.Repo runtime config (F6.3). A production boot must supply DATABASE_URL
  # (mirrors the SECRET_KEY_BASE raise above — no insecure default leaks to prod);
  # under dev the static dev.exs creds apply, so DATABASE_URL is honoured only when
  # set and never forced. The :test env returns above this block (sandbox uses the
  # test.exs creds).
  case {System.get_env("DATABASE_URL"), env} do
    {nil, :prod} ->
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

    {nil, _} ->
      # Dev/runtime: keep the dev.exs static creds; do not force DATABASE_URL.
      :ok

    {url, _} ->
      config :portal, Portal.Repo,
        url: url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))
  end
end

# The deep-link base (F6.5.5-D9) is overridable per deploy via an env var, with the
# config.exs default as the fallback — so configurability holds in EVERY environment
# (incl. :test, where the e2e config-swap probe sets it). It carries a default and so
# never raises; it lives outside the :test-guarded block above for that reason.
if base = System.get_env("DEEP_LINK_BASE_URL") do
  config :portal_web, :deep_link_base_url, base
end
