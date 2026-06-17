import Config

# Runtime configuration for the echo umbrella, evaluated at boot in every environment.
# The portal/portal_web runtime settings (SECRET_KEY_BASE, PORT, PHX_HOST/PHX_SERVER,
# the Postgres DATABASE_URL + IPv6 socket options, the deep-link base) moved out to
# their own repository with the apps. Nothing staying in
# echo reads runtime env today; this file is retained as the umbrella's runtime hook.
