# echo/apps/echomq/lib/echomq/keys.ex — the queue-level builders (verified)
ctx = EchoMQ.Keys.new("emails")        # %{prefix: "bull", name: "emails"}

# the base every key extends
EchoMQ.Keys.base(ctx)        # => "emq:emails"

# lifecycle LISTs
EchoMQ.Keys.wait(ctx)        # => "emq:emails:wait"
EchoMQ.Keys.active(ctx)      # => "emq:emails:active"
EchoMQ.Keys.paused(ctx)      # => "emq:emails:paused"

# sorted sets (ZSET)
EchoMQ.Keys.delayed(ctx)     # => "emq:emails:delayed"
EchoMQ.Keys.prioritized(ctx) # => "emq:emails:prioritized"
EchoMQ.Keys.completed(ctx)   # => "emq:emails:completed"
EchoMQ.Keys.failed(ctx)      # => "emq:emails:failed"
EchoMQ.Keys.marker(ctx)      # => "emq:emails:marker"
EchoMQ.Keys.waiting_children(ctx) # => "emq:emails:waiting-children"

# SET · STREAM · counters · HASH
EchoMQ.Keys.stalled(ctx)     # => "emq:emails:stalled"
EchoMQ.Keys.events(ctx)      # => "emq:emails:events"
EchoMQ.Keys.limiter(ctx)     # => "emq:emails:limiter"
EchoMQ.Keys.id(ctx)          # => "emq:emails:id"
EchoMQ.Keys.pc(ctx)          # => "emq:emails:pc"
EchoMQ.Keys.meta(ctx)        # => "emq:emails:meta"
