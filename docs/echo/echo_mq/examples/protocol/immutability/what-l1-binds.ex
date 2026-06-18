# L1 in the real EchoMQ.Keys — the contract, as code (echo/apps/echomq/lib/echomq/keys.ex)
  @default_prefix "bull"                          # element 1 · the default prefix

  def base(%{prefix: prefix, name: name}), do: "#{prefix}:#{name}"
  def wait(ctx), do: "#{base(ctx)}:wait"      # -> emq:{queue}:wait
  def lock(ctx, job_id), do: "#{job(ctx, job_id)}:lock"
                                                # element 7 -> emq:{queue}:{jobId}:lock
