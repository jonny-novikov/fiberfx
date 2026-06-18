# EchoMQ.Job.from_redis/4 — the dual read (job.ex:216)
attempts_made: parse_int(Map.get(data, "attemptsMade") || Map.get(data, "atm", "0"))

# reads the long name first; falls back to the compressed name;
# defaults to "0" only when NEITHER is present (a brand-new job).
# contrast — a single-name read would MISS the other form:
attempts_made: parse_int(Map.get(data, "atm", "0"))  # would read 0 for an attemptsMade-only hash
