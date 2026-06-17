# scripts.ex — EVALSHA, then reload + EVAL on NOSCRIPT
def execute_raw(conn, script, keys, args) do
  # num_keys = length(keys); encoded_args = pack(args)
  case RedisConnection.command(conn, ["EVALSHA", sha, num_keys | keys ++ encoded_args]) do
    {:error, %Redix.Error{message: "NOSCRIPT" <> _}} -> # reload, then EVAL
    result -> result
  end
end
