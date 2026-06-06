package echomq

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/vmihailenco/msgpack/v5"
)

// RateLimitedError indicates the worker is rate limited
type RateLimitedError struct {
	RetryAfter time.Duration
}

func (e *RateLimitedError) Error() string {
	return fmt.Sprintf("rate limited, retry after %v", e.RetryAfter)
}

// ScriptError represents an error code returned by a Lua script
type ScriptError struct {
	Code    int
	Message string
}

func (e *ScriptError) Error() string {
	return fmt.Sprintf("script error %d: %s", e.Code, e.Message)
}

// moveToFinished error codes
const (
	scriptErrMissingKey      = -1
	scriptErrMissingLock     = -2
	scriptErrNotInActive     = -3
	scriptErrPendingChildren = -4
	scriptErrLockNotOwned    = -6
	scriptErrFailedChildren  = -9
)

func scriptErrorMessage(code int) string {
	switch code {
	case scriptErrMissingKey:
		return "job key does not exist"
	case scriptErrMissingLock:
		return "lock is missing"
	case scriptErrNotInActive:
		return "job not in active set"
	case scriptErrPendingChildren:
		return "job has pending children"
	case scriptErrLockNotOwned:
		return "lock is not owned by this client"
	case scriptErrFailedChildren:
		return "job has failed children"
	default:
		return "unknown error"
	}
}

// packMoveToActiveOpts builds the msgpack-encoded opts for the MoveToActive Lua script.
// The Lua script accesses: opts.token, opts.lockDuration, opts.limiter, opts.name
func packMoveToActiveOpts(token string, lockDurationMs int64, workerName string, limiter *LimiterConfig) ([]byte, error) {
	opts := map[string]interface{}{
		"token":        token,
		"lockDuration": lockDurationMs,
		"name":         workerName,
	}
	if limiter != nil {
		opts["limiter"] = map[string]interface{}{
			"max":      limiter.Max,
			"duration": limiter.Duration.Milliseconds(),
		}
	}
	return msgpack.Marshal(opts)
}

// packMoveToFinishedOpts builds the msgpack-encoded opts for the MoveToFinished Lua script.
// The Lua script accesses: opts.token, opts.keepJobs, opts.lockDuration, opts.attempts,
// opts.maxMetricsSize, opts.name, opts.limiter
func packMoveToFinishedOpts(token string, keepJobs map[string]interface{}, lockDurationMs int64, attempts int, maxMetricsSize string, workerName string, limiter *LimiterConfig) ([]byte, error) {
	opts := map[string]interface{}{
		"token":          token,
		"keepJobs":       keepJobs,
		"lockDuration":   lockDurationMs,
		"attempts":       attempts,
		"maxMetricsSize": maxMetricsSize,
		"name":           workerName,
	}
	if limiter != nil {
		opts["limiter"] = map[string]interface{}{
			"max":      limiter.Max,
			"duration": limiter.Duration.Milliseconds(),
		}
	}
	return msgpack.Marshal(opts)
}

// keepJobsFromRemoveOnSetting converts a RemoveOnSetting to the keepJobs map
// expected by the MoveToFinished Lua script.
func keepJobsFromRemoveOnSetting(setting RemoveOnSetting) map[string]interface{} {
	// Remove immediately: keepJobs.count = 0
	if setting.Remove && setting.Age == 0 && setting.Count == 0 {
		return map[string]interface{}{"count": 0, "age": nil}
	}
	result := map[string]interface{}{"count": nil, "age": nil}
	if setting.Count > 0 {
		result["count"] = setting.Count
	}
	if setting.Age > 0 {
		result["age"] = setting.Age
	}
	return result
}

// parseFlatHGetAll converts a flat HGETALL result [field, value, field, value, ...]
// into a map[string]string.
func parseFlatHGetAll(data []interface{}) map[string]string {
	result := make(map[string]string, len(data)/2)
	for i := 0; i+1 < len(data); i += 2 {
		key := fmt.Sprintf("%v", data[i])
		value := fmt.Sprintf("%v", data[i+1])
		result[key] = value
	}
	return result
}

// jobFromHGetAllMap builds a Job from a Redis HGETALL map.
// This is used to parse the job data returned by the MoveToActive Lua script.
func jobFromHGetAllMap(data map[string]string, jobID, queueName string, redisClient redis.Cmdable, emitter *EventEmitter) (*Job, error) {
	job := &Job{
		ID:          jobID,
		Data:        make(map[string]interface{}),
		queueName:   queueName,
		redisClient: redisClient,
		emitter:     emitter,
	}

	if name, ok := data["name"]; ok {
		job.Name = name
	}

	if dataJSON, ok := data["data"]; ok && dataJSON != "" {
		if err := json.Unmarshal([]byte(dataJSON), &job.Data); err != nil {
			return nil, fmt.Errorf("failed to unmarshal job data: %w", err)
		}
	}

	if optsJSON, ok := data["opts"]; ok && optsJSON != "" {
		if err := json.Unmarshal([]byte(optsJSON), &job.Opts); err != nil {
			return nil, fmt.Errorf("failed to unmarshal job opts: %w", err)
		}
	}

	if progress, ok := data["progress"]; ok {
		fmt.Sscanf(progress, "%d", &job.Progress)
	}
	if timestamp, ok := data["timestamp"]; ok {
		fmt.Sscanf(timestamp, "%d", &job.Timestamp)
	}
	if attemptsMade, ok := data["atm"]; ok {
		fmt.Sscanf(attemptsMade, "%d", &job.AttemptsMade)
	}
	if delay, ok := data["delay"]; ok {
		fmt.Sscanf(delay, "%d", &job.Delay)
	}
	if failedReason, ok := data["failedReason"]; ok {
		job.FailedReason = failedReason
	}
	if processedOn, ok := data["processedOn"]; ok {
		fmt.Sscanf(processedOn, "%d", &job.ProcessedOn)
	}
	if finishedOn, ok := data["finishedOn"]; ok {
		fmt.Sscanf(finishedOn, "%d", &job.FinishedOn)
	}

	return job, nil
}

// MoveToActiveResult holds the parsed result of a MoveToActive Lua script call
type MoveToActiveResult struct {
	Job        *Job
	LockToken  LockToken
	RateLimitDelay time.Duration // > 0 means rate limited
}

// buildMoveToActiveKeys builds the 11 KEYS for the MoveToActive Lua script
func buildMoveToActiveKeys(kb *KeyBuilder) []string {
	return []string{
		kb.Wait(),            // KEYS[1]
		kb.Active(),          // KEYS[2]
		kb.Prioritized(),     // KEYS[3]
		kb.Events(),          // KEYS[4]
		kb.Stalled(),         // KEYS[5]
		kb.RateLimiter(),     // KEYS[6]
		kb.Delayed(),         // KEYS[7]
		kb.Paused(),          // KEYS[8]
		kb.Meta(),            // KEYS[9]
		kb.PriorityCounter(), // KEYS[10]
		kb.Marker(),          // KEYS[11]
	}
}

// buildMoveToFinishedKeys builds the 14 KEYS for the MoveToFinished Lua script
func buildMoveToFinishedKeys(kb *KeyBuilder, jobID, target string) []string {
	return []string{
		kb.Wait(),            // KEYS[1]
		kb.Active(),          // KEYS[2]
		kb.Prioritized(),     // KEYS[3]
		kb.Events(),          // KEYS[4]
		kb.Stalled(),         // KEYS[5]
		kb.RateLimiter(),     // KEYS[6]
		kb.Delayed(),         // KEYS[7]
		kb.Paused(),          // KEYS[8]
		kb.Meta(),            // KEYS[9]
		kb.PriorityCounter(), // KEYS[10]
		targetSetKey(kb, target), // KEYS[11]
		kb.Job(jobID),        // KEYS[12]
		kb.Metrics(target),   // KEYS[13]
		kb.Marker(),          // KEYS[14]
	}
}

// targetSetKey returns the completed or failed ZSET key
func targetSetKey(kb *KeyBuilder, target string) string {
	if target == "completed" {
		return kb.Completed()
	}
	return kb.Failed()
}

// buildRetryJobKeys builds the 11 KEYS for the RetryJob Lua script.
// See scripts.RetryJob header (scripts.go line 1103-1130) for the key mapping.
func buildRetryJobKeys(kb *KeyBuilder, jobID string) []string {
	return []string{
		kb.Active(),          // KEYS[1]
		kb.Wait(),            // KEYS[2]
		kb.Paused(),          // KEYS[3]
		kb.Job(jobID),        // KEYS[4]
		kb.Meta(),            // KEYS[5]
		kb.Events(),          // KEYS[6]
		kb.Delayed(),         // KEYS[7]
		kb.Prioritized(),     // KEYS[8]
		kb.PriorityCounter(), // KEYS[9]
		kb.Marker(),          // KEYS[10]
		kb.Stalled(),         // KEYS[11]
	}
}

// parseMoveToActiveResult parses the 4-element return value from MoveToActive.
// Returns:
//   - (result, nil) if a job was found
//   - (nil, redis.Nil) if no job is available
//   - (nil, *RateLimitedError) if rate limited
//   - (nil, error) on other errors
func parseMoveToActiveResult(cmd *redis.Cmd, queueName string, redisClient redis.Cmdable, emitter *EventEmitter, lockToken LockToken) (*MoveToActiveResult, error) {
	resultSlice, err := cmd.Slice()
	if err != nil {
		return nil, fmt.Errorf("moveToActive script failed: %w", err)
	}

	if len(resultSlice) != 4 {
		return nil, fmt.Errorf("moveToActive returned %d elements, expected 4", len(resultSlice))
	}

	// Check if first element is job data ([]interface{}) or a scalar (int64/string "0")
	switch jobData := resultSlice[0].(type) {
	case []interface{}:
		// Job found — parse the HGETALL flat array
		if len(jobData) == 0 {
			return nil, redis.Nil
		}
		hashMap := parseFlatHGetAll(jobData)

		// Extract jobId from result[1]
		jobID := fmt.Sprintf("%v", resultSlice[1])
		if jobID == "" || jobID == "0" {
			return nil, redis.Nil
		}

		job, err := jobFromHGetAllMap(hashMap, jobID, queueName, redisClient, emitter)
		if err != nil {
			return nil, err
		}
		job.lockToken = lockToken

		return &MoveToActiveResult{
			Job:       job,
			LockToken: lockToken,
		}, nil

	default:
		// No job found — check for rate limiting
		rateLimitTTL := toInt64(resultSlice[2])
		if rateLimitTTL > 0 {
			return nil, &RateLimitedError{RetryAfter: time.Duration(rateLimitTTL) * time.Millisecond}
		}
		return nil, redis.Nil
	}
}

// toInt64 safely converts an interface{} to int64.
// Handles all Go numeric types since msgpack may deserialize integers
// as various widths (int8, uint64, etc.) depending on value range.
func toInt64(v interface{}) int64 {
	switch val := v.(type) {
	case int64:
		return val
	case int:
		return int64(val)
	case int8:
		return int64(val)
	case int16:
		return int64(val)
	case int32:
		return int64(val)
	case uint:
		return int64(val)
	case uint8:
		return int64(val)
	case uint16:
		return int64(val)
	case uint32:
		return int64(val)
	case uint64:
		return int64(val)
	case float32:
		return int64(val)
	case float64:
		return int64(val)
	case string:
		var n int64
		fmt.Sscanf(val, "%d", &n)
		return n
	default:
		return 0
	}
}
