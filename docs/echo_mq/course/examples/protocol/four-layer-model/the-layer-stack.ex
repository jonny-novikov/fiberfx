# One operation — pick up the next job — through the four layers.
# L4 · the API differs per runtime
  Node    worker.run()                   # a class method
  Elixir  EchoMQ.Worker drives the pickup     # a supervised GenServer
  Go      worker.Start()                  # a struct method
# L3 · the executor differs per runtime — in Elixir:
  EchoMQ.Scripts.move_to_active/4   # assembles 11 keys + ARGV
  EchoMQ.Scripts.execute_raw/4     # SHA, then EVALSHA; NOSCRIPT -> EVAL
— — — — — — — — — immutable below the line — — — — — — — — —
# L2 · ONE script, identical in every runtime
  moveToActive-11                    # the -11 is the KEYS arity: 11 keys
# L1 · ONE data layout, identical in every runtime
  emq:{queue}:wait  ->  emq:{queue}:active  +  emq:{queue}:{jobId}:lock
