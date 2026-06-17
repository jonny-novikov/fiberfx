# EchoMQ.Scripts.execute_raw/4 — the dispatch each script call runs
sha = sha1(script)
num_keys = length(keys)

# for moveToActive-11: length(keys) == 11
RedisConnection.command(conn, ["EVALSHA", sha, num_keys | keys ++ encoded_args])
# → ["EVALSHA", <sha>, 11, …11 keys…, …argv…]
