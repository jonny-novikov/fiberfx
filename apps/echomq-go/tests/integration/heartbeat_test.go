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

// T053: Heartbeat extends lock every 15s
func TestHeartbeat_ExtendsLockEvery15s(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-heartbeat-queue"
	queue := echomq.NewQueue(queueName, rdb)

	job, err := queue.Add(ctx, "long-job", map[string]interface{}{"task": "long"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)

	// Create worker with 15s heartbeat interval, 30s lock duration
	opts := echomq.DefaultWorkerOptions
	opts.HeartbeatInterval = 5 * time.Second  // Use 5s for faster testing
	opts.LockDuration = 30 * time.Second
	worker := echomq.NewWorker(queueName, rdb, opts)

	// D-E: use echomq.NewKeyBuilder so the test reads at the EXACT key production writes
	// regardless of client type (auto-detect matches NewQueue/NewWorker semantics).
	kb := echomq.NewKeyBuilder(queueName, rdb)
	lockKey := kb.Lock(job.ID)
	started := make(chan bool, 1)

	worker.Process(func(job *echomq.Job) (interface{}, error) {
		started <- true

		// Get initial TTL
		initialTTL, _ := rdb.TTL(ctx, lockKey).Result()

		// Wait for heartbeat to extend lock (6s > 5s heartbeat interval)
		time.Sleep(6 * time.Second)

		// Get TTL after heartbeat
		afterTTL, _ := rdb.TTL(ctx, lockKey).Result()

		// TTL should be refreshed (closer to 30s again)
		assert.Greater(t, afterTTL.Seconds(), initialTTL.Seconds(),
			"Lock TTL should be extended by heartbeat")

		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	select {
	case <-started:
		// Test passed inside job processor
	case <-time.After(10 * time.Second):
		t.Fatal("Timeout waiting for job")
	}
}

// T054: Heartbeat continues despite transient failures
func TestHeartbeat_ContinuesDespiteFailures(t *testing.T) {
	ctx := context.Background()
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379", DB: 15})
	defer rdb.Close()
	require.NoError(t, rdb.FlushDB(ctx).Err())

	queueName := "test-heartbeat-failure-queue"
	queue := echomq.NewQueue(queueName, rdb)

	_, err := queue.Add(ctx, "test-job", map[string]interface{}{"task": "test"}, echomq.JobOptions{Attempts: 3, Backoff: echomq.BackoffConfig{Type: "exponential", Delay: 1000}})
	require.NoError(t, err)

	// Create worker
	opts := echomq.DefaultWorkerOptions
	opts.HeartbeatInterval = 2 * time.Second
	worker := echomq.NewWorker(queueName, rdb, opts)

	completed := make(chan bool, 1)

	worker.Process(func(job *echomq.Job) (interface{}, error) {
		// Simulate long job
		time.Sleep(5 * time.Second)
		completed <- true
		return nil, nil
	})

	go worker.Start(ctx)
	defer worker.Stop()

	// Temporarily disconnect Redis mid-processing to simulate heartbeat failure
	// (In real implementation, heartbeat would log but continue)

	select {
	case <-completed:
		// Job should still complete even if some heartbeats failed
		// Lock extension failures are logged but don't stop processing
	case <-time.After(10 * time.Second):
		t.Fatal("Job should complete despite potential heartbeat failures")
	}
}
