# the opts that route a job → target state → add* Lua script
  delay > 0      →  delayed      addDelayedJob-6
  priority > 0   →  prioritized  addPrioritizedJob-9   # 0 = highest priority
  neither        →  wait         addStandardJob-9

# other opts (the full job_opts map)
  :job_id        custom id            :prefix      default "bull"
  :timestamp     enqueue time         :parent      → parent_key (flows)
  :deduplication → deduplication_id   :lifo        LIFO ordering
  :attempts      max retries          :backoff     %{type: :fixed | :exponential, delay: ms}
