-- extendLocks-1.lua · KEYS[1] stalled · ARGV baseKey, tokens, jobIds, lockDuration
local currentToken = rcall("GET", baseKey .. jobIds[i] .. ':lock')
if currentToken == token then
  rcall("SET", lockKey, token, "PX", lockDuration)   -- re-set the TTL
  rcall("SREM", stalledKey, jobId)                   -- clear from stalled set
else
  table.insert(failedJobs, jobId)                    -- record a lost lock
end
return failedJobs   -- the FAILED ids; empty means all renewed
