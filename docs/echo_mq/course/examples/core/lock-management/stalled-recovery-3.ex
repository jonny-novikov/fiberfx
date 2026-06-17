def move_stalled_jobs_to_wait(conn, ctx, max_stalled_count, opts \\ []) do
  keys = [
    Keys.stalled(ctx), Keys.wait(ctx), Keys.active(ctx), Keys.failed(ctx),
    Keys.stalled_check(ctx), Keys.meta(ctx), Keys.paused(ctx), Keys.marker(ctx)
  ]                                          -- eight keys → moveStalledJobsToWait-8.lua
  ...
end
