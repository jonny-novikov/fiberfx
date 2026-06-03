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

  config :portal_web, PortalWeb.Endpoint,
    http: [ip: {127, 0, 0, 1}, port: port],
    secret_key_base: secret_key_base,
    server: true
end
