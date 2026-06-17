defp do_check(connection, ctx, max_stalled_count) do
  case RedisConnection.command(connection, ["LRANGE", Keys.active(ctx), 0, -1]) do
    {:ok, []}      -> {:ok, %{recovered: 0, failed: 0}}
    {:ok, job_ids} -> check_jobs_stalled(connection, ctx, job_ids, max_stalled_count)
  end
end

# one EXISTS per active id, run as a single pipeline; exists == 0 means no lock
stalled_jobs =
  Enum.zip(job_ids, results)
  |> Enum.filter(fn {_id, exists} -> exists == 0 end)
  |> Enum.map(fn {id, _} -> id end)
