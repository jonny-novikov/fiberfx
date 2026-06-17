# EchoMQ.Scripts.execute_raw/4 — the shipped dispatch (priv/scripts), EVALSHA-first.
# @spec execute_raw(atom(), String.t(), [String.t()], [any()]) :: script_result()
sha = sha1(script)
case RedisConnection.command(conn, ["EVALSHA", sha, num_keys | keys ++ encoded_args]) do
  {:ok, result} -> {:ok, decode_result(result)}     # cache HIT
  {:error, %Redix.Error{message: "NOSCRIPT" <> _}} ->
    RedisConnection.command(conn, ["EVAL", script, num_keys | keys ++ encoded_args]) # runs + caches
end

# emq.1 ships the v2 set dispatched the SAME way — every key declared in KEYS[] (D2).
# the dispatch is unchanged; what changes is meta.version + the fence:
  "bullmq:5.65.1"  # v1 line, frozen at 1.3.0 (EchoMQ.Version, version.ex:54)
  "echomq:2.0.0"   # emq.1 ships — a v2 worker fences a emq:* keyspace, and vice versa (INV1)
