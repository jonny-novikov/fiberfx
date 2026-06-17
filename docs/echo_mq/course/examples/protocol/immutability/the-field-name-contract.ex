# EchoMQ.Job.from_redis/4 — the real reader (echo/apps/echomq/lib/echomq/job.ex)
  attempts_made:    parse_int(Map.get(data, "attemptsMade") || Map.get(data, "atm", "0")),
  attempts_started: parse_int(Map.get(data, "ats",  "0")),
  stalled_counter:  parse_int(Map.get(data, "stc",  "0")),
  repeat_job_key:   Map.get(data, "rjk"),
  deduplication_id: Map.get(data, "deid"),
  deferred_failure: Map.get(data, "defa"),
  # the contract field is "atm"; the || absorbs one historical "attemptsMade" divergence
