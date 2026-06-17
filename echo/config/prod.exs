import Config

# Prod config for the echo umbrella. The portal/portal_web prod settings (the
# Postgres event-store adapter, the endpoint URL, the libcluster topology, the SSR
# gate) moved out to their own repository with the apps.
# Nothing staying in echo needs a :prod override today; this file exists because
# config.exs does `import_config "#{config_env()}.exs"`.
