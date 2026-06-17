defp schedule_renewal(lock_renew_time) do
  interval = div(lock_renew_time, 2)            -- 7500 ms by default
  Process.send_after(self(), :extend_locks, interval)
end
