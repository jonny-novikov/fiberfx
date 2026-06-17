# echo/apps/echomq/lib/echomq/keys.ex — the job-level builders (verified)
ctx = EchoMQ.Keys.new("emails")        # %{prefix: "bull", name: "emails"}
id  = "42"

# the job HASH — the bare job key, no suffix
EchoMQ.Keys.job(ctx, id)        # => "emq:emails:42"

# the four suffixed keys, each off the job key
EchoMQ.Keys.lock(ctx, id)         # => "emq:emails:42:lock"          # STRING + PX
EchoMQ.Keys.logs(ctx, id)         # => "emq:emails:42:logs"          # LIST
EchoMQ.Keys.dependencies(ctx, id) # => "emq:emails:42:dependencies"  # SET
EchoMQ.Keys.processed(ctx, id)    # => "emq:emails:42:processed"     # HASH

# the job hash is decoded back into a struct by
EchoMQ.Job.from_redis(id, "emails", fields)   # => %EchoMQ.Job{...}
