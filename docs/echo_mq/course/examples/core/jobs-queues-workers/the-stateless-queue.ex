# EchoMQ.Queue.add/4 — two clauses (lib/echomq/queue.ex, verified)

# convenience: a named or pid Queue process
def add(queue, name, data, opts) when is_atom(queue) or is_pid(queue) do
  GenServer.call(queue, {:add, name, data, opts})
end

# the stateless path: a string name + a connection is the whole queue
def add(queue, name, data, opts) when is_binary(queue) do
  conn   = Keyword.fetch!(opts, :connection)
  prefix = opts[:prefix] || "bull"
  ctx    = Keys.new(queue, prefix: prefix)
  job    = Job.new(queue, name, data, opts)
  add_job(conn, ctx, job)
end
