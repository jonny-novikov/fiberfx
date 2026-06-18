def calculate_next_millis(%{immediately: true}, reference_time), do: reference_time

def calculate_next_millis(%{every: every}, reference_time) when is_integer(every) do
  # default: the next run is reference_time + every
  reference_time + every
end

def calculate_next_millis(%{pattern: pattern}, reference_time) do
  # parse the cron expression and ask for the next run date after reference_time
  ...
end
