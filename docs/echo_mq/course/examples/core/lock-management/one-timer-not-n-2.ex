def extend_locks(conn, ctx, job_ids, tokens, duration) do
  keys = [Keys.stalled(ctx)]               -- exactly ONE key
  args = [
    Keys.key(ctx),                         -- the baseKey
    Msgpax.pack!(tokens, iodata: false),   -- all tokens in one ARGV
    Msgpax.pack!(job_ids, iodata: false),  -- all ids in one ARGV
    duration
  ]
  execute(conn, :extend_locks, keys, args)
end
