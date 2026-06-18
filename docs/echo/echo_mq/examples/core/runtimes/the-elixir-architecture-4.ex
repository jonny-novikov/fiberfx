# lock_manager.ex — one timer, one batched script call
def handle_info(:extend_locks, state) do
  # scan tracked_jobs, select those past the half-window threshold,
  # then renew them all at once:
  Scripts.extend_locks(state.connection, state.keys, job_ids, tokens, state.lock_duration)
  Process.send_after(self(), :extend_locks, interval)   # re-arm the one timer
end
