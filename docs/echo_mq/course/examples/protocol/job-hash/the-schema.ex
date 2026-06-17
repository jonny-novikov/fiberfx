# EchoMQ.Job.from_redis/4 (job.ex:200–229) — the decode, abridged to the schema
%EchoMQ.Job{
  name:             Map.get(data, "name", ""),
  data:             decode_json(Map.get(data, "data", "{}")),
  opts:             decode_opts(Map.get(data, "opts", "{}")),  # short-keyed
  timestamp:        parse_int(Map.get(data, "timestamp", "0")),
  return_value:     decode_json_or_nil(Map.get(data, "returnvalue")),  # lowercase
  attempts_made:    parse_int(Map.get(data, "attemptsMade") || Map.get(data, "atm", "0")),  # line 216
  attempts_started: parse_int(Map.get(data, "ats", "0")),
  stalled_counter:  parse_int(Map.get(data, "stc", "0")),
  processed_by:     Map.get(data, "processedBy"),  # the LONG name, not pb
  repeat_job_key:   Map.get(data, "rjk"),
  deduplication_id: Map.get(data, "deid"),
  deferred_failure: Map.get(data, "defa")
}
