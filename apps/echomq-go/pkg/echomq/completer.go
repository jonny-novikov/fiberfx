package echomq

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
)

// Completer handles job completion and failure using atomic Lua scripts
type Completer struct {
	worker *Worker
}

// NewCompleter creates a new completer
func NewCompleter(worker *Worker) *Completer {
	return &Completer{worker: worker}
}

// Complete marks a job as completed using the atomic MoveToFinished Lua script.
// This replaces the previous non-atomic approach (LRem + HSet + ZAdd/Del + Del lock).
// The Lua script atomically handles: lock verification, active removal, parent dependency
// updates, metrics collection, event emission, event trimming, and retention policies.
func (c *Completer) Complete(ctx context.Context, job *Job, lockToken LockToken, returnValue interface{}) error {
	kb := c.worker.keyBuilder
	timestamp := time.Now().UnixMilli()

	// Serialize return value as JSON
	var returnValueStr string
	if returnValue != nil {
		returnValueJSON, err := json.Marshal(returnValue)
		if err != nil {
			returnValueStr = fmt.Sprintf(`{"error":"failed to marshal return value: %v"}`, err)
		} else {
			returnValueStr = string(returnValueJSON)
		}
	}

	// Update local job state
	job.ReturnValue = returnValue
	job.FinishedOn = timestamp

	// Build keepJobs from RemoveOnComplete setting
	keepJobs := keepJobsFromRemoveOnSetting(job.Opts.RemoveOnComplete)

	optsPacked, err := packMoveToFinishedOpts(
		lockToken.String(),
		keepJobs,
		c.worker.opts.LockDuration.Milliseconds(),
		c.worker.opts.MaxAttempts,
		"", // maxMetricsSize (empty = disabled)
		c.worker.opts.WorkerID,
		c.worker.opts.Limiter,
	)
	if err != nil {
		return fmt.Errorf("failed to pack moveToFinished opts: %w", err)
	}

	keys := buildMoveToFinishedKeys(kb, job.ID, "completed")
	args := []interface{}{
		job.ID,             // ARGV[1] - jobId
		timestamp,          // ARGV[2] - timestamp
		"returnvalue",      // ARGV[3] - msg property
		returnValueStr,     // ARGV[4] - return value
		"completed",        // ARGV[5] - target
		0,                  // ARGV[6] - fetch next? (0=no)
		kb.Prefix(),        // ARGV[7] - keys prefix
		string(optsPacked), // ARGV[8] - opts
		"",                 // ARGV[9] - job fields to update
	}

	resultCode, err := moveToFinishedScript.Run(ctx, c.worker.redisClient, keys, args...).Int()
	if err != nil {
		return fmt.Errorf("moveToFinished(completed) script error for %s: %w", job.ID, err)
	}

	if resultCode < 0 {
		return &ScriptError{
			Code:    resultCode,
			Message: fmt.Sprintf("moveToFinished(completed) for %s: %s", job.ID, scriptErrorMessage(resultCode)),
		}
	}

	// Note: The Lua script emits the completed event atomically, so we don't call EmitCompleted here
	return nil
}

// Fail marks a job as failed using the atomic MoveToFinished Lua script.
func (c *Completer) Fail(ctx context.Context, job *Job, lockToken LockToken, jobErr error) error {
	kb := c.worker.keyBuilder
	timestamp := time.Now().UnixMilli()

	// Update local job state
	job.FailedReason = jobErr.Error()
	job.FinishedOn = timestamp

	keepJobs := keepJobsFromRemoveOnSetting(job.Opts.RemoveOnFail)

	optsPacked, err := packMoveToFinishedOpts(
		lockToken.String(),
		keepJobs,
		c.worker.opts.LockDuration.Milliseconds(),
		c.worker.opts.MaxAttempts,
		"", // maxMetricsSize (empty = disabled)
		c.worker.opts.WorkerID,
		c.worker.opts.Limiter,
	)
	if err != nil {
		return fmt.Errorf("failed to pack moveToFinished opts: %w", err)
	}

	keys := buildMoveToFinishedKeys(kb, job.ID, "failed")
	args := []interface{}{
		job.ID,             // ARGV[1] - jobId
		timestamp,          // ARGV[2] - timestamp
		"failedReason",     // ARGV[3] - msg property
		jobErr.Error(),     // ARGV[4] - failed reason
		"failed",           // ARGV[5] - target
		0,                  // ARGV[6] - fetch next? (0=no)
		kb.Prefix(),        // ARGV[7] - keys prefix
		string(optsPacked), // ARGV[8] - opts
		"",                 // ARGV[9] - job fields to update
	}

	resultCode, err := moveToFinishedScript.Run(ctx, c.worker.redisClient, keys, args...).Int()
	if err != nil {
		return fmt.Errorf("moveToFinished(failed) script error for %s: %w", job.ID, err)
	}

	if resultCode < 0 {
		return &ScriptError{
			Code:    resultCode,
			Message: fmt.Sprintf("moveToFinished(failed) for %s: %s", job.ID, scriptErrorMessage(resultCode)),
		}
	}

	// Note: The Lua script emits the failed event atomically, so we don't call EmitFailed here
	return nil
}
