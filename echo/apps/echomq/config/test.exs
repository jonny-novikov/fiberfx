import Config

config :echomq,
  prefix: "echomq_test",
  connections: [
    redis: [
      host: "localhost",
      port: 6379,
      pool_size: 3
    ]
  ]

config :logger, level: :warning
