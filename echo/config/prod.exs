import Config

# Prod config for the echo umbrella. No compile-time :prod overrides are needed today
# (codemojex's production settings are resolved at boot in runtime.exs); this file exists
# because config.exs does `import_config "#{config_env()}.exs"`.
