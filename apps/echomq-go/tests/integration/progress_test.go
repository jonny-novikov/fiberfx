package integration

import (
	"context"
	"testing"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// T087: UpdateProgress stores progress in job hash
func TestProgress_StoresInJobHash(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-progress-queue"
	queue := echomq.NewQueue(queueName, rdb)

	job, err := queue.Add(ctx, "test-job", map[string]interface{}{"task": "test"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)
	jobID := job.ID

	// Create worker
	worker := echomq.NewWorker(queueName, rdb, echomq.DefaultWorkerOptions)

	progressUpdated := make(chan bool, 1)
	worker.Process(func(job *echomq.Job) (interface{}, error) {
		// Update progress to 50%
		job.UpdateProgress(50)
		progressUpdated <- true

		time.Sleep(200 * time.Millisecond)
		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	// Wait for progress update
	<-progressUpdated

	// Verify progress stored in job hash.
	// D-E: use echomq.NewKeyBuilder so the test reads at the EXACT key production writes
	// regardless of client type (auto-detect matches NewQueue/NewWorker semantics).
	kb := echomq.NewKeyBuilder(queueName, rdb)
	jobKey := kb.Job(jobID)
	progress, err := rdb.HGet(ctx, jobKey, "progress").Result()
	require.NoError(t, err)
	assert.Equal(t, "50", progress, "Progress should be stored in job hash")
}

// T088: UpdateProgress emits "progress" event
func TestProgress_EmitsProgressEvent(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-progress-event-queue"
	queue := echomq.NewQueue(queueName, rdb)

	_, err := queue.Add(ctx, "test-job", map[string]interface{}{"task": "test"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)

	// Create worker
	worker := echomq.NewWorker(queueName, rdb, echomq.DefaultWorkerOptions)

	worker.Process(func(job *echomq.Job) (interface{}, error) {
		job.UpdateProgress(75)
		time.Sleep(200 * time.Millisecond)
		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	// Wait for processing
	time.Sleep(2 * time.Second)

	// Check events stream for "progress" event (D-E: KeyBuilder-based read).
	kb := echomq.NewKeyBuilder(queueName, rdb)
	eventsKey := kb.Events()
	events, err := rdb.XRange(ctx, eventsKey, "-", "+").Result()
	require.NoError(t, err)

	// Look for progress event
	found := false
	for _, event := range events {
		if eventType, ok := event.Values["event"].(string); ok && eventType == "progress" {
			found = true
			break
		}
	}

	assert.True(t, found, "Progress event should be emitted to events stream")
}

// T089: Log() appends entry to job logs list
func TestProgress_AppendsLog(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-log-queue"
	queue := echomq.NewQueue(queueName, rdb)

	job, err := queue.Add(ctx, "test-job", map[string]interface{}{"task": "test"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)
	jobID := job.ID

	// Create worker
	worker := echomq.NewWorker(queueName, rdb, echomq.DefaultWorkerOptions)

	logAdded := make(chan bool, 1)
	worker.Process(func(job *echomq.Job) (interface{}, error) {
		job.Log("Processing started")
		job.Log("Step 1 complete")
		logAdded <- true

		time.Sleep(200 * time.Millisecond)
		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	// Wait for log
	<-logAdded

	// Verify logs stored (D-E: KeyBuilder-based read).
	kb := echomq.NewKeyBuilder(queueName, rdb)
	logsKey := kb.Logs(jobID)
	logs, err := rdb.LRange(ctx, logsKey, 0, -1).Result()
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(logs), 2, "At least 2 log entries should exist")

	// Verify log content
	assert.Contains(t, logs[0], "Processing started")
	assert.Contains(t, logs[1], "Step 1 complete")
}

// T090: Log list trimmed to max 1000 entries
func TestProgress_LogTrimmedTo1000(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-log-trim-queue"
	queue := echomq.NewQueue(queueName, rdb)

	job, err := queue.Add(ctx, "test-job", map[string]interface{}{"task": "test"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)
	jobID := job.ID

	// Create worker
	worker := echomq.NewWorker(queueName, rdb, echomq.DefaultWorkerOptions)

	worker.Process(func(job *echomq.Job) (interface{}, error) {
		// Add 1500 log entries
		for i := 0; i < 1500; i++ {
			job.Log("Log entry " + string(rune(i)))
		}
		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	// Wait for processing
	time.Sleep(3 * time.Second)

	// Verify logs trimmed to max 1000 (D-E: KeyBuilder-based read).
	kb := echomq.NewKeyBuilder(queueName, rdb)
	logsKey := kb.Logs(jobID)
	logCount, err := rdb.LLen(ctx, logsKey).Result()
	require.NoError(t, err)
	assert.LessOrEqual(t, logCount, int64(1000), "Log list should be trimmed to max 1000 entries")
}
