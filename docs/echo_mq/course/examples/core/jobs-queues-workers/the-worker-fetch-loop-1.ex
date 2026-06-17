# EchoMQ.Worker fetch loop (lib/echomq/worker.ex, verified)
def handle_info(:fetch_jobs, state) do
  available_slots = state.concurrency - map_size(state.active_jobs)

  if available_slots > 0 do
    new_state = fetch_and_process_jobs(state, available_slots)   # fill the free slots
    {:noreply, new_state}
  else
    {:noreply, state}                                     # full — wait for a completion
  end
end

# each free slot fetches one job, atomically, via the pickup script:
Scripts.move_to_active(conn, keys, token, opts)   # → moveToActive-11.lua
