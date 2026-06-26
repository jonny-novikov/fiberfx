import Config

# Prod config for the echo umbrella. No compile-time :prod overrides are needed today
# (codemojex's production settings are resolved at boot in runtime.exs); this file exists
# because config.exs does `import_config "#{config_env()}.exs"`.
#
# NOTE: IPv6 for the Valkey connector (Fly 6PN is IPv6-only) is handled PER-CLIENT in
# Codemojex.Application — the host is resolved to an inet6 address tuple, which gen_tcp dials
# over inet6 automatically. A global `config :kernel, inet_default_connect_options: [:inet6]`
# does NOT work here: :kernel is a base app already started before compile-time config loads
# (a release errors with "Cannot configure base applications"), and a global family default
# also collides with clients that pick their own family.
