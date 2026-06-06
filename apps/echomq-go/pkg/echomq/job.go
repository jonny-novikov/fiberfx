package echomq

import (
	"context"
	"encoding/json"
	"time"

	"github.com/redis/go-redis/v9"
)

// Job represents a unit of work in the queue
type Job struct {
	ID            string                 `json:"id"`
	Name          string                 `json:"name"`
	Data          map[string]interface{} `json:"data"`
	Opts          JobOptions             `json:"opts"`
	Progress      int                    `json:"progress"`
	ReturnValue   interface{}            `json:"returnvalue,omitempty"`
	FailedReason  string                 `json:"failedReason,omitempty"`
	StackTrace    []string               `json:"stacktrace,omitempty"`
	Timestamp     int64                  `json:"timestamp"`
	AttemptsMade  int                    `json:"attemptsMade"`
	ProcessedOn   int64                  `json:"processedOn,omitempty"`
	FinishedOn    int64                  `json:"finishedOn,omitempty"`
	WorkerID      string                 `json:"-"` // Not persisted to Redis
	Delay         int64                  `json:"delay"`

	// Internal fields for operations (not serialized)
	queueName   string         `json:"-"`
	redisClient redis.Cmdable  `json:"-"`
	emitter     *EventEmitter  `json:"-"`
	lockToken   LockToken      `json:"-"` // Set by worker during job pickup
}

// JobOptions configures job behavior
type JobOptions struct {
	Priority         int             `json:"priority"`
	Delay            time.Duration   `json:"delay"`
	Attempts         int             `json:"attempts"`
	Backoff          BackoffConfig   `json:"backoff"`
	RemoveOnComplete RemoveOnSetting `json:"removeOnComplete"`
	RemoveOnFail     RemoveOnSetting `json:"removeOnFail"`
}

// RemoveOnSetting represents EchoMQ's flexible removeOnComplete/removeOnFail options.
// EchoMQ supports three variants:
//   - bool: true (remove immediately) or false (keep forever)
//   - int: keep only the last N jobs
//   - object: {age: seconds, count?: maxJobs} for time/count-based cleanup
type RemoveOnSetting struct {
	// Remove indicates if jobs should be removed (true = remove, false = keep)
	Remove bool
	// Age is the maximum age in seconds before removal (0 = no age limit)
	Age int
	// Count is the maximum number of jobs to keep (0 = no count limit)
	Count int
}

// ShouldRemove returns true if jobs should be removed on completion/failure
func (r RemoveOnSetting) ShouldRemove() bool {
	return r.Remove || r.Age > 0 || r.Count > 0
}

// UnmarshalJSON handles the three EchoMQ variants for removeOnComplete/removeOnFail:
// - boolean: true/false
// - number: max count to keep
// - object: {age: number, count?: number}
func (r *RemoveOnSetting) UnmarshalJSON(data []byte) error {
	// Try boolean first
	var boolVal bool
	if err := json.Unmarshal(data, &boolVal); err == nil {
		r.Remove = boolVal
		r.Age = 0
		r.Count = 0
		return nil
	}

	// Try number (count)
	var countVal int
	if err := json.Unmarshal(data, &countVal); err == nil {
		r.Remove = true
		r.Age = 0
		r.Count = countVal
		return nil
	}

	// Try object {age: number, count?: number}
	var objVal struct {
		Age   int `json:"age"`
		Count int `json:"count"`
	}
	if err := json.Unmarshal(data, &objVal); err == nil {
		r.Remove = true
		r.Age = objVal.Age
		r.Count = objVal.Count
		return nil
	}

	// Default to false (don't remove)
	r.Remove = false
	r.Age = 0
	r.Count = 0
	return nil
}

// MarshalJSON serializes RemoveOnSetting back to JSON
func (r RemoveOnSetting) MarshalJSON() ([]byte, error) {
	// If age or count is set, use object format
	if r.Age > 0 || r.Count > 0 {
		return json.Marshal(struct {
			Age   int `json:"age,omitempty"`
			Count int `json:"count,omitempty"`
		}{Age: r.Age, Count: r.Count})
	}
	// Otherwise use boolean
	return json.Marshal(r.Remove)
}

// BackoffConfig defines retry backoff strategy
type BackoffConfig struct {
	Type  string `json:"type"`  // "fixed" or "exponential"
	Delay int64  `json:"delay"` // Base delay in milliseconds
}

// DefaultJobOptions provides sensible defaults
var DefaultJobOptions = JobOptions{
	Priority:         0,
	Delay:            0,
	Attempts:         3,
	Backoff:          BackoffConfig{Type: "exponential", Delay: 1000},
	RemoveOnComplete: RemoveOnSetting{Remove: false},
	RemoveOnFail:     RemoveOnSetting{Remove: false},
}

// UpdateProgress atomically updates job progress (0-100) using Lua script
// The Lua script ensures atomicity and automatically emits a progress event
func (j *Job) UpdateProgress(progress int) error {
	if progress < 0 || progress > 100 {
		return &ValidationError{Field: "progress", Message: "must be between 0 and 100"}
	}

	// Update local state
	j.Progress = progress

	// Update in Redis atomically if client available
	if j.redisClient != nil && j.queueName != "" {
		ctx := context.Background()
		updater := NewProgressUpdater(j.queueName, j.redisClient)

		_, err := updater.UpdateProgress(ctx, j.ID, progress)
		if err != nil {
			return err
		}
	}

	return nil
}

// Log atomically appends a log entry to the job using Lua script
// The Lua script automatically trims logs to max 1000 entries (LIFO)
func (j *Job) Log(message string) error {
	if j.redisClient == nil || j.queueName == "" {
		return nil // Silently skip if not connected
	}

	ctx := context.Background()
	logManager := NewLogManager(j.queueName, j.redisClient, DefaultMaxLogs)

	_, err := logManager.AddLog(ctx, j.ID, message)
	return err
}
