-- extendLock-2.lua · KEYS[1] lock, KEYS[2] stalled · ARGV token, duration-ms, jobid
local rcall = redis.call
if rcall("GET", KEYS[1]) == ARGV[1] then
  if rcall("SET", KEYS[1], ARGV[1], "PX", ARGV[2]) then
    rcall("SREM", KEYS[2], ARGV[3])
    return 1
  end
end
return 0
