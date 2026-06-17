# EchoMQ.Job.new/4 — the loud fields (lib/echomq/job.ex, verified)
def new(queue_name, name, data, opts \\ []) do
  opts = opts_to_map(opts)
  %EchoMQ.Job{
    id:               Map.get(opts, :job_id) || generate_id(),  # custom or auto
    name:             name,
    data:             data,
    queue_name:       queue_name,
    opts:             opts,
    prefix:           Map.get(opts, :prefix, "bull"),
    timestamp:        Map.get(opts, :timestamp, ...),
    delay:            Map.get(opts, :delay, 0),
    priority:         Map.get(opts, :priority, 0),    # 0 = highest
    parent:           Map.get(opts, :parent),
    parent_key:       build_parent_key(Map.get(opts, :parent)),
    deduplication_id: get_in(opts, [:deduplication, :id])
  }
end
