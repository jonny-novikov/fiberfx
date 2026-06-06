package echomq

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq/scripts"
	"github.com/redis/go-redis/v9"
)

// moveToActiveScript is the cached Redis script for atomic job pickup.
var moveToActiveScript = redis.NewScript(scripts.MoveToActive)

// moveToFinishedScript is the cached Redis script for atomic job completion/failure.
var moveToFinishedScript = redis.NewScript(scripts.MoveToFinished)

// retryJobScript is the cached Redis script for atomic job retry.
var retryJobScript = redis.NewScript(scripts.RetryJob)

// Start begins job consumption from the queue
func (w *Worker) Start(ctx context.Context) error {
	if w.processor == nil {
		return fmt.Errorf("job processor not registered, call Process() first")
	}

	// Validate Redis Cluster compatibility (optional warning)
	w.validateClusterCompatibility()

	// Start background services
	w.startHeartbeatManager(ctx)
	w.startStalledChecker(ctx)

	// Main job consumption loop
	for {
		select {
		case <-ctx.Done():
			return w.gracefulShutdown()
		case <-w.shutdownChan:
			return w.gracefulShutdown()
		default:
			// Check if we have capacity for more jobs
			select {
			case w.activeSemaphore <- struct{}{}:
				// Capacity available, pick up a job
				if err := w.pickupJob(ctx); err != nil {
					// Release semaphore if pickup failed
					<-w.activeSemaphore

					// Handle rate limiting with precise sleep
					var rlErr *RateLimitedError
					if errors.As(err, &rlErr) {
						time.Sleep(rlErr.RetryAfter)
						continue
					}

					// If no jobs available, wait before retrying
					if err == redis.Nil {
						time.Sleep(100 * time.Millisecond)
						continue
					}

					// Log other errors but continue
					time.Sleep(time.Second)
				}
			default:
				// No capacity, wait
				time.Sleep(100 * time.Millisecond)
			}
		}
	}
}

// pickupJob attempts to pick up a job from the queue using the atomic MoveToActive Lua script.
// This replaces the previous non-atomic approach (ZPopMin/RPop + SetEx + LPush).
// The Lua script atomically handles: delayed job promotion, rate limiting, paused queue check,
// lock acquisition, event emission, and marker updates.
func (w *Worker) pickupJob(ctx context.Context) error {
	w.mu.RLock()
	if !w.isConnected {
		w.mu.RUnlock()
		return fmt.Errorf("redis disconnected")
	}
	w.mu.RUnlock()

	kb := w.keyBuilder
	lockToken := NewLockToken()
	timestamp := time.Now().UnixMilli()

	// Pack opts for the Lua script: {token, lockDuration, limiter, name}
	optsPacked, err := packMoveToActiveOpts(
		lockToken.String(),
		w.opts.LockDuration.Milliseconds(),
		w.opts.WorkerID,
		w.opts.Limiter,
	)
	if err != nil {
		return fmt.Errorf("failed to pack moveToActive opts: %w", err)
	}

	// Build KEYS and ARGV
	keys := buildMoveToActiveKeys(kb)
	args := []interface{}{
		kb.Prefix(), // ARGV[1] - key prefix
		timestamp,   // ARGV[2] - timestamp
		string(optsPacked), // ARGV[3] - msgpacked opts
	}

	// Execute the atomic MoveToActive Lua script
	cmd := moveToActiveScript.Run(ctx, w.redisClient, keys, args...)

	// Parse result
	result, err := parseMoveToActiveResult(cmd, w.queueName, w.redisClient, w.eventEmitter, lockToken)
	if err != nil {
		return err
	}

	// Process job in goroutine (job data already loaded by the Lua script)
	job := result.Job
	job.WorkerID = w.opts.WorkerID

	w.wg.Add(1)
	go w.processJobDirect(ctx, job, lockToken)

	return nil
}

// processJobDirect processes a job whose data was already loaded by MoveToActive.
// Unlike the old processJob, this does NOT call getJobData since the Lua script
// returns the full HGETALL data atomically.
func (w *Worker) processJobDirect(ctx context.Context, job *Job, lockToken LockToken) {
	defer w.wg.Done()
	defer func() { <-w.activeSemaphore }() // Release semaphore

	// Note: Active event is already emitted by the MoveToActive Lua script

	// Start heartbeat for this job
	if w.heartbeatManager != nil {
		w.heartbeatManager.StartHeartbeat(ctx, job.ID, lockToken)
		defer w.heartbeatManager.StopHeartbeat(job.ID)
	}

	// Track processing time for results queue metadata
	startTime := time.Now()

	// Execute job processor
	result, err := w.processor(job)

	duration := time.Since(startTime)

	// Handle result
	if err != nil {
		w.handleJobFailure(ctx, job, lockToken, err)
	} else {
		// Send to results queue if configured (only on success)
		if w.resultsQueue != nil {
			w.sendToResultsQueue(job, result, duration)
		}

		w.handleJobSuccess(ctx, job, lockToken, result)
	}
}

// getJobData retrieves job data from Redis.
// This is kept for backward compatibility and for cases where job data needs
// to be refreshed. The primary path now uses MoveToActive which returns job data directly.
func (w *Worker) getJobData(ctx context.Context, jobID string) (*Job, error) {
	kb := w.keyBuilder
	jobKey := kb.Job(jobID)

	// Get job hash from Redis
	data, err := w.redisClient.HGetAll(ctx, jobKey).Result()
	if err != nil {
		return nil, err
	}

	if len(data) == 0 {
		return nil, fmt.Errorf("job not found: %s", jobID)
	}

	// Parse job data
	job := &Job{
		ID:          jobID,
		Data:        make(map[string]interface{}),
		queueName:   w.queueName,
		redisClient: w.redisClient,
		emitter:     w.eventEmitter,
	}

	// Parse string fields
	if name, ok := data["name"]; ok {
		job.Name = name
	}

	// Parse JSON data field
	if dataJSON, ok := data["data"]; ok && dataJSON != "" {
		if err := json.Unmarshal([]byte(dataJSON), &job.Data); err != nil {
			return nil, fmt.Errorf("failed to unmarshal job data: %w", err)
		}
	}

	// Parse JSON opts field
	if optsJSON, ok := data["opts"]; ok && optsJSON != "" {
		if err := json.Unmarshal([]byte(optsJSON), &job.Opts); err != nil {
			return nil, fmt.Errorf("failed to unmarshal job opts: %w", err)
		}
	}

	// Parse numeric fields
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

	// Parse optional fields
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

// handleJobSuccess handles successful job completion using the atomic MoveToFinished Lua script
func (w *Worker) handleJobSuccess(ctx context.Context, job *Job, lockToken LockToken, returnValue interface{}) {
	completer := NewCompleter(w)
	completer.Complete(ctx, job, lockToken, returnValue)
}

// handleJobFailure handles job failure
func (w *Worker) handleJobFailure(ctx context.Context, job *Job, lockToken LockToken, err error) {
	// Categorize error
	category := CategorizeError(err)

	// If permanent error or max attempts reached, move to failed
	if category == ErrorCategoryPermanent || job.AttemptsMade >= job.Opts.Attempts {
		w.moveToFailed(ctx, job, lockToken, err)
		return
	}

	// Retry using the atomic RetryJob Lua script (GAP-002 fix)
	w.retryJob(ctx, job, lockToken)
}

// moveToFailed moves job to failed queue using the atomic MoveToFinished Lua script.
// This replaces the previous non-atomic approach (LRem + Del + ZAdd + HSet).
func (w *Worker) moveToFailed(ctx context.Context, job *Job, lockToken LockToken, jobErr error) {
	kb := w.keyBuilder
	timestamp := time.Now().UnixMilli()

	keepJobs := keepJobsFromRemoveOnSetting(job.Opts.RemoveOnFail)
	optsPacked, err := packMoveToFinishedOpts(
		lockToken.String(),
		keepJobs,
		w.opts.LockDuration.Milliseconds(),
		w.opts.MaxAttempts,
		"", // maxMetricsSize (empty = disabled)
		w.opts.WorkerID,
		w.opts.Limiter,
	)
	if err != nil {
		fmt.Printf("[echomq-go] ERROR: failed to pack moveToFinished opts for %s: %v\n", job.ID, err)
		// Fallback: try basic cleanup
		w.redisClient.LRem(ctx, kb.Active(), 1, job.ID)
		w.redisClient.Del(ctx, kb.Lock(job.ID))
		return
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

	resultCode, err := moveToFinishedScript.Run(ctx, w.redisClient, keys, args...).Int()
	if err != nil {
		fmt.Printf("[echomq-go] ERROR: moveToFinished(failed) script error for %s: %v\n", job.ID, err)
		return
	}

	if resultCode < 0 {
		fmt.Printf("[echomq-go] WARN: moveToFinished(failed) returned %d (%s) for %s\n",
			resultCode, scriptErrorMessage(resultCode), job.ID)
	}
	// Note: The Lua script emits the failed event atomically, so we don't call EmitFailed here
}

// retryJob retries a failed job using the atomic RetryJob Lua script (GAP-002 fix).
//
// The script atomically handles: lock verification and release, stalled set cleanup,
// active list removal, priority-aware re-insertion (wait or prioritized), delayed job
// promotion, atm increment, event emission ("waiting"), and marker updates.
//
// Return codes: 0=OK, -1=missing key, -2=missing lock, -3=not in active, -6=lock not owned.
func (w *Worker) retryJob(ctx context.Context, job *Job, lockToken LockToken) {
	kb := w.keyBuilder
	timestamp := time.Now().UnixMilli()

	keys := buildRetryJobKeys(kb, job.ID)
	args := []interface{}{
		kb.Prefix(),        // ARGV[1] - key prefix
		timestamp,          // ARGV[2] - timestamp (used for delayed job promotion)
		"RPUSH",            // ARGV[3] - pushCmd (RPUSH = FIFO, LPUSH = LIFO)
		job.ID,             // ARGV[4] - jobId
		lockToken.String(), // ARGV[5] - token (for lock ownership verification)
		"",                 // ARGV[6] - optional job fields to update (msgpacked, empty = none)
	}

	resultCode, err := retryJobScript.Run(ctx, w.redisClient, keys, args...).Int()
	if err != nil {
		fmt.Printf("[echomq-go] ERROR: retryJob script error for %s: %v\n", job.ID, err)
		return
	}

	if resultCode < 0 {
		fmt.Printf("[echomq-go] WARN: retryJob returned %d (%s) for %s\n",
			resultCode, scriptErrorMessage(resultCode), job.ID)
	}
	// Note: The Lua script atomically increments atm via HINCRBY and emits
	// the "waiting" event, so no separate Redis calls are needed.
}

// extendLockPeriodically extends job lock via the official ExtendLock Lua script.
// NOTE: This is legacy code; the HeartbeatManager.heartbeatLoop is the active path.
// Kept for API compatibility.
func (w *Worker) extendLockPeriodically(ctx context.Context, jobID string, lockToken LockToken) {
	ticker := time.NewTicker(w.opts.HeartbeatInterval)
	defer ticker.Stop()

	kb := w.keyBuilder
	lockKey := kb.Lock(jobID)
	stalledKey := kb.Stalled()
	lockDurationMs := w.opts.LockDuration.Milliseconds()

	extendLockScript := redis.NewScript(scripts.ExtendLock)

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Official ExtendLock: KEYS[1]=lock, KEYS[2]=stalled
			// ARGV[1]=token, ARGV[2]=duration_ms, ARGV[3]=jobId
			result, err := extendLockScript.Run(ctx, w.redisClient,
				[]string{lockKey, stalledKey},
				lockToken.String(),
				lockDurationMs,
				jobID,
			).Int64()
			if err != nil {
				fmt.Printf("[echomq-go] WARN: heartbeat extend failed for job %s: %v\n", jobID, err)
				continue
			}
			if result == 0 {
				// Lock was stolen — stop extending
				fmt.Printf("[echomq-go] WARN: lock stolen for job %s, stopping heartbeat\n", jobID)
				return
			}
		}
	}
}

// startHeartbeatManager starts the heartbeat manager
func (w *Worker) startHeartbeatManager(ctx context.Context) {
	w.heartbeatManager = NewHeartbeatManager(w)
}

// startStalledChecker starts the stalled job checker
func (w *Worker) startStalledChecker(ctx context.Context) {
	w.stalledChecker = NewStalledChecker(w)
	go w.stalledChecker.Start(ctx)
}

// gracefulShutdown waits for active jobs to complete
func (w *Worker) gracefulShutdown() error {
	// Wait for all jobs to finish with timeout
	done := make(chan struct{})
	go func() {
		w.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return nil
	case <-time.After(w.opts.ShutdownTimeout):
		return fmt.Errorf("shutdown timeout exceeded")
	}
}

// validateClusterCompatibility validates that all keys use proper hash tags for Redis Cluster
// This is an optional warning - the worker will function in both single-instance and cluster modes
func (w *Worker) validateClusterCompatibility() {
	// Generate sample keys for validation
	kb := w.keyBuilder
	keys := []string{
		kb.Wait(),
		kb.Active(),
		kb.Prioritized(),
		kb.Meta(),
		kb.Job("sample-id"),
		kb.Lock("sample-id"),
	}

	// Validate all keys hash to same slot
	allSame, slot, _ := ValidateHashTags(keys)
	if !allSame {
		// This should never happen if KeyBuilder is implemented correctly
		fmt.Printf("[echomq-go] WARNING: Queue '%s' keys do NOT all hash to the same Redis Cluster slot. "+
			"Multi-key Lua scripts may fail with CROSSSLOT errors in cluster mode.\n", w.queueName)
		return
	}

	// Check if we're connected to a cluster
	isCluster := IsRedisCluster(w.redisClient)
	if isCluster {
		fmt.Printf("[echomq-go] Redis Cluster detected: Queue '%s' keys validated (slot %d)\n", w.queueName, slot)
	}
	// If not cluster, no need to log anything (most common case)
}

// Helper to convert WorkerOptions to JobOptions
func (opts WorkerOptions) toJobOptions() JobOptions {
	return JobOptions{
		Attempts: opts.MaxAttempts,
		Backoff: BackoffConfig{
			Type:  "exponential",
			Delay: opts.BackoffDelay.Milliseconds(),
		},
	}
}
