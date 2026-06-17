def execute_raw(conn, script, keys, args) do
  sha = sha1(script)
  encoded_args = Enum.map(args, &encode_arg/1)
  num_keys = length(keys)

  # Try EVALSHA first (cached script)
  case RedisConnection.command(conn, ["EVALSHA", sha, num_keys | keys ++ encoded_args]) do
    {:ok, result} ->
      {:ok, decode_result(result)}

    {:error, %Redix.Error{message: "NOSCRIPT" <> _}} ->
      # Script not cached, use EVAL which will also cache it
      case RedisConnection.command(conn, ["EVAL", script, num_keys | keys ++ encoded_args]) do
        {:ok, result} -> {:ok, decode_result(result)}
        {:error, reason} -> {:error, reason}
      end

    {:error, reason} ->
      {:error, reason}
  end
end
