# the shipped enqueue the fleet probe rides — EchoMQ.Queue.add/4 (v1 line)
# @spec add(atom | pid | String.t, job_name, job_data, keyword) ::
#         {:ok, Job.t} | {:error, term}
# the binary-queue clause: no process — Redis holds the state
def add(queue, name, data, opts) when is_binary(queue) do
  conn = Keyword.fetch!(opts, :connection)
  ctx  = Keys.new(queue, prefix: prefix)        # v1: builds emq:queue:… verbatim
  job  = Job.new(queue, name, data, opts)
  add_job(conn, ctx, job)                       # emq.1 ships the v2 form: emq:{payments}:wait
end
