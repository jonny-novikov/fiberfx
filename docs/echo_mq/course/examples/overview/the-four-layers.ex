# One operation — pick up the next job — through the four layers.
# L4 · the API differs per runtime
  Node    worker.run()              # a class method
  Elixir  EchoMQ.Worker.start_link()    # a supervised GenServer
  Go      worker.Start()             # a struct method
# L3 · the executor differs per runtime
  load once, then EVALSHA <sha>     # NOSCRIPT -> reload (all three)
— — — — — — — — — immutable below the line — — — — — — — — —
# L2 · ONE script, identical in every runtime
  moveToActive-11                 # wait/prioritized -> active + lock
# L1 · ONE data layout, identical in every runtime (the v1 keyspace, frozen at 1.3.0)
  emq:{queue}:wait  ->  emq:{queue}:active  +  emq:{queue}:{jobId}:lock
  field atm (attemptsMade) read and written the same everywhere
