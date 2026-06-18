# in the HOST application's supervision tree
children = [
  {EchoMQ.RedisConnection, name: :redis, url: "redis://localhost:6379"},
  {EchoMQ.Worker,
    name: :my_worker, queue: "my_queue", connection: :redis,
    processor: &MyApp.Jobs.process/1, concurrency: 10}
]
