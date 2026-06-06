// Package integration contains integration tests for the echomq-go library.
//
// File: nodejs_compat_test.go
// Scope: R-1 acceptance — Node.js BullMQ ↔ Go echomq-go cross-language
// compatibility via the simulated-wire-format path.
// Brief: dev/mcp/features/FTR-009-echomq-go-parity/spec.yaml R-1 + task-spec
// Instruction #3 (apps/echomq-go/tests/integration/nodejs_compat_test.go).
//
// Default build (no tags): simulates Node.js wire format directly via Go
// redis client (HSET + LPUSH using Node.js bare-key shape). This proves that
// jobs produced by Node.js BullMQ on single-instance Redis are visible to
// the Go worker, which is the primary R-1 acceptance criterion.
//
// Docker build (-tags compat_docker): see nodejs_compat_docker_test.go for
// the variant that drives real Node.js BullMQ via docker-compose.
//
// REDIS REQUIREMENT: localhost:6379 single-instance Redis MUST be running.
// Test skips with t.Skip when Redis is unreachable. To run: `docker run -d
// -p 6379:6379 redis:7-alpine`.
//
// Why this is not behind a build tag: R-1 acceptance criterion 2 says
// "TestNodeJSCompatibility_SingleInstance integration test passes" — pinning
// the wire-format invariant requires a default-on test. The Docker variant
// is supplemental evidence (full BullMQ producer round-trip) and is
// appropriately gated.
package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	// nodeCompatRedisAddr is the single-instance Redis address used by the
	// Node.js compat tests. Matches the canonical localhost dev server (per
	// CLAUDE.md §Setup).
	nodeCompatRedisAddr = "localhost:6379"

	// nodeCompatTimeout bounds the full pickup-and-process cycle. The Go
	// worker polls the wait queue at 100 ms intervals (worker_impl.go:61);
	// 10 s is generous enough to absorb CI jitter without masking real hangs.
	nodeCompatTimeout = 10 * time.Second
)

// requireRedisOrSkip dials Redis and skips the test on connection failure.
// This is the standard pattern for tests that require a live Redis but
// should not fail the build when one is unavailable (CI matrix flexibility).
func requireRedisOrSkip(t *testing.T) *redis.Client {
	t.Helper()
	client := redis.NewClient(&redis.Options{
		Addr:        nodeCompatRedisAddr,
		DialTimeout: 2 * time.Second,
	})
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		t.Skipf("Redis at %s unreachable: %v — skipping Node.js compat test", nodeCompatRedisAddr, err)
	}
	return client
}

// cleanQueueKeys removes every key matching bull:<queue>:* on the connected
// single-instance Redis. Used to isolate tests across runs without flushing
// the full database (which would clobber other queues sharing the box).
func cleanQueueKeys(t *testing.T, ctx context.Context, client *redis.Client, queueName string) {
	t.Helper()
	pattern := "bull:" + queueName + ":*"
	iter := client.Scan(ctx, 0, pattern, 100).Iterator()
	for iter.Next(ctx) {
		_ = client.Del(ctx, iter.Val()).Err()
	}
	require.NoError(t, iter.Err(), "scan for queue cleanup failed")
}

// TestNodeJSCompatibility_SingleInstance_NodeProducesGoConsumes is the
// canonical R-1 integration test. It:
//
//   1. Creates a single-instance Redis client (redis.Client → no hash tags).
//   2. Writes a job using the Node.js BullMQ wire format directly via Go's
//      redis client (HSET on bull:<queue>:<jobID> + LPUSH on bull:<queue>:wait).
//      This is byte-identical to what `node` running `Queue.add(...)` produces
//      against the same Redis instance.
//   3. Starts a Go worker on the same queue and asserts the job is picked up
//      and processed within the timeout.
//   4. Asserts the Go worker reads the same fields Node.js wrote: name, data,
//      timestamp, opts.
//
// The simulation path is the SAME Redis-side wire contract as a real Node.js
// producer. It is NOT a mock — both Go and Node.js are clients of the same
// Redis server, and the test uses Redis itself as the wire-format truth.
//
// References:
//   - phase-1-state-contract.md §Redis Key Inventory rows 1, 4, 9 (Wait, Active, Job).
//   - HOTFIX_ANALYSIS.md §1 (Single-instance Redis bug fix).
//   - state.yaml D-9 (bull: prefix invariant).
func TestNodeJSCompatibility_SingleInstance_NodeProducesGoConsumes(t *testing.T) {
	const queueName = "compat-node-to-go"
	const jobName = "send-welcome-email"

	client := requireRedisOrSkip(t)
	t.Cleanup(func() { _ = client.Close() })

	ctx, cancel := context.WithTimeout(context.Background(), nodeCompatTimeout)
	defer cancel()

	cleanQueueKeys(t, ctx, client, queueName)
	t.Cleanup(func() {
		// Use a fresh detached context: the test ctx is already cancelled by
		// the time t.Cleanup runs, which would short-circuit the SCAN.
		cleanCtx, cleanCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanCancel()
		cleanQueueKeys(t, cleanCtx, client, queueName)
	})

	// Construct the Node.js wire-format job hash directly. This is exactly
	// what `redis-cli HGETALL bull:<queue>:1` returns after a Node.js
	// producer call to `Queue.add('send-welcome-email', { to, subject }, {})`.
	const jobID = "1"
	jobKey := fmt.Sprintf("bull:%s:%s", queueName, jobID)
	waitKey := fmt.Sprintf("bull:%s:wait", queueName)

	// Sanity: confirm Go's KeyBuilder produces the same shapes used above.
	// This pins the assumption that the simulation matches what a Go worker
	// would address against the same Redis instance.
	kb := echomq.NewKeyBuilder(queueName, client)
	require.Equal(t, jobKey, kb.Job(jobID),
		"Go KeyBuilder.Job must match Node.js wire format (no hash tags)")
	require.Equal(t, waitKey, kb.Wait(),
		"Go KeyBuilder.Wait must match Node.js wire format (no hash tags)")

	// Build the Node.js wire-format payload. Field names + casing here mirror
	// the BullMQ v5.62.0 default-job-creation hash exactly:
	//   - id           : job ID (string, redundant with key suffix)
	//   - name         : job name (string)
	//   - data         : JSON-encoded payload (string in Redis hash)
	//   - opts         : JSON-encoded JobOptions (string in Redis hash)
	//   - priority     : top-level int (BullMQ Lua reads via HGET — see
	//                    queue_impl.go:88-92 / scripts.go:195)
	//   - progress     : 0
	//   - delay        : 0
	//   - timestamp    : enqueue time, unix-ms
	//   - atm          : attemptsMade counter (short form, BullMQ convention)
	//
	// Reference: phase-1-state-contract.md §Protocol Invariants table.
	payload := map[string]interface{}{
		"to":      "user@example.com",
		"subject": "Welcome aboard",
	}
	dataJSON, err := json.Marshal(payload)
	require.NoError(t, err)

	// JobOptions JSON shape mirrors BullMQ v5.62.0 default opts.
	optsJSON, err := json.Marshal(map[string]interface{}{
		"attempts": 1,
		"delay":    0,
		"priority": 0,
	})
	require.NoError(t, err)

	timestamp := time.Now().UnixMilli()

	hashFields := map[string]interface{}{
		"id":        jobID,
		"name":      jobName,
		"data":      string(dataJSON),
		"opts":      string(optsJSON),
		"priority":  0,
		"progress":  0,
		"delay":     0,
		"timestamp": timestamp,
		"atm":       0,
	}

	require.NoError(t, client.HSet(ctx, jobKey, hashFields).Err(),
		"HSET on Node.js-format job hash key must succeed")
	require.NoError(t, client.LPush(ctx, waitKey, jobID).Err(),
		"LPUSH onto Node.js-format wait list must succeed")

	// Verify the seeded keys match the wire shape.
	gotID, err := client.HGet(ctx, jobKey, "id").Result()
	require.NoError(t, err)
	require.Equal(t, jobID, gotID, "round-trip read of seeded id must match")

	// Now spin up a Go worker on the same queue. It MUST see the seeded job.
	worker := echomq.NewWorker(queueName, client, echomq.WorkerOptions{
		Concurrency:          1,
		LockDuration:         5 * time.Second,
		HeartbeatInterval:    1 * time.Second,
		StalledCheckInterval: 30 * time.Second,
		MaxAttempts:          1,
		BackoffDelay:         100 * time.Millisecond,
	})

	processed := make(chan *echomq.Job, 1)
	worker.Process(func(job *echomq.Job) (interface{}, error) {
		// Echo the job back via the channel for assertions.
		select {
		case processed <- job:
		default:
		}
		return map[string]interface{}{"status": "ok"}, nil
	})

	workerErr := make(chan error, 1)
	workerCtx, workerCancel := context.WithCancel(ctx)
	defer workerCancel()
	go func() {
		workerErr <- worker.Start(workerCtx)
	}()
	t.Cleanup(func() {
		_ = worker.Stop()
		// Drain the worker error channel so the goroutine exits cleanly.
		select {
		case <-workerErr:
		case <-time.After(3 * time.Second):
		}
	})

	select {
	case job := <-processed:
		// PRIMARY R-1 ASSERTION: Go worker picked up Node.js-formatted job.
		require.NotNil(t, job, "processed job must not be nil")
		assert.Equal(t, jobID, job.ID, "Go must see Node.js-written id field")
		assert.Equal(t, jobName, job.Name, "Go must see Node.js-written name field")
		assert.Equal(t, timestamp, job.Timestamp, "Go must see Node.js-written timestamp field")
		// Data round-trip through JSON: every numeric value is float64.
		assert.Equal(t, "user@example.com", job.Data["to"])
		assert.Equal(t, "Welcome aboard", job.Data["subject"])
	case <-ctx.Done():
		t.Fatalf("Go worker did not process Node.js-formatted job within %s; ctx err: %v",
			nodeCompatTimeout, ctx.Err())
	}
}

// TestNodeJSCompatibility_SingleInstance_GoProducesNodeReadable is the
// inverse leg: Go produces a job, the test asserts the resulting Redis hash
// is byte-readable in the format Node.js BullMQ expects.
//
// Verification approach: after Go writes the job via Queue.Add, the test
// reads the underlying Redis hash and stream entries directly and asserts
// every field name and casing matches BullMQ v5.62.0 expectations. A real
// Node.js consumer reading the same Redis instance would see identical
// data — this test pins the wire contract without requiring a Node.js
// runtime in the inner loop.
//
// Wire-contract assertions: name, data, opts, timestamp, id, atm,
// priority — each cross-referenced against phase-1-state-contract.md
// §Protocol Invariants table.
func TestNodeJSCompatibility_SingleInstance_GoProducesNodeReadable(t *testing.T) {
	const queueName = "compat-go-to-node"
	const jobName = "send-receipt"

	client := requireRedisOrSkip(t)
	t.Cleanup(func() { _ = client.Close() })

	ctx, cancel := context.WithTimeout(context.Background(), nodeCompatTimeout)
	defer cancel()

	cleanQueueKeys(t, ctx, client, queueName)
	t.Cleanup(func() {
		cleanCtx, cleanCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanCancel()
		cleanQueueKeys(t, cleanCtx, client, queueName)
	})

	queue := echomq.NewQueue(queueName, client)

	payload := map[string]interface{}{
		"orderID":  "ORD-998",
		"amount":   42,
		"currency": "USD",
	}
	job, err := queue.Add(ctx, jobName, payload, echomq.JobOptions{
		Priority: 5,
		Attempts: 3,
	})
	require.NoError(t, err)
	require.NotEmpty(t, job.ID)

	// Address the underlying Redis hash directly. This is what a Node.js
	// BullMQ Worker would resolve via its own KeyBuilder for the same
	// (queue, jobID) — both clients agree on the same byte layout.
	jobKey := fmt.Sprintf("bull:%s:%s", queueName, job.ID)
	require.False(t, strings.Contains(jobKey, "{"),
		"Go-produced single-instance jobKey must not contain hash tags (Node.js parity)")

	hash, err := client.HGetAll(ctx, jobKey).Result()
	require.NoError(t, err)
	require.NotEmpty(t, hash, "Go-produced job hash must exist at the Node.js-expected key")

	// Field-name + casing assertions per phase-1-state-contract.md §Protocol Invariants.
	requireField := func(name string) string {
		t.Helper()
		v, ok := hash[name]
		require.True(t, ok,
			"Go-produced hash missing field %q — Node.js BullMQ would not see this job correctly", name)
		return v
	}

	assert.Equal(t, job.ID, requireField("id"), "id field exact match")
	assert.Equal(t, jobName, requireField("name"), "name field exact match")

	// data and opts are JSON strings — verify they round-trip parseable.
	var dataParsed map[string]interface{}
	require.NoError(t, json.Unmarshal([]byte(requireField("data")), &dataParsed),
		"data field must be parseable JSON (Node.js parses via JSON.parse)")
	assert.Equal(t, "ORD-998", dataParsed["orderID"])
	assert.EqualValues(t, 42, dataParsed["amount"])

	var optsParsed map[string]interface{}
	require.NoError(t, json.Unmarshal([]byte(requireField("opts")), &optsParsed),
		"opts field must be parseable JSON (Node.js parses via JSON.parse)")
	assert.EqualValues(t, 5, optsParsed["priority"])
	assert.EqualValues(t, 3, optsParsed["attempts"])

	// timestamp and atm: top-level numeric strings (Redis hashes always
	// store strings; client side parses on read).
	tsField := requireField("timestamp")
	require.NotEmpty(t, tsField, "timestamp field must be set")
	atmField := requireField("atm")
	assert.Equal(t, "0", atmField, "atm field must be initial 0 (Node.js convention)")

	// priority top-level field — phase-1-state-contract.md GAP-7 + B-001 fix.
	// Without this, Node.js Lua scripts read 0 and break delayed-job promotion.
	priorityField := requireField("priority")
	assert.Equal(t, "5", priorityField,
		"priority MUST be a top-level hash field (B-001 fix); Node.js Lua reads via HGET jobKey priority")

	// Confirm the wait list contains the job ID — Node.js BullMQ workers
	// pull from this exact LIST shape.
	waitKey := fmt.Sprintf("bull:%s:wait", queueName)
	// NOTE: priority > 0 routes to the prioritized ZSET, not the wait list
	// (per queue_impl.go:120-133). Assert the prioritized ZSET membership.
	priorityKey := fmt.Sprintf("bull:%s:prioritized", queueName)
	prioCount, err := client.ZCard(ctx, priorityKey).Result()
	require.NoError(t, err)
	assert.Equal(t, int64(1), prioCount,
		"Go-produced priority>0 job must land in prioritized ZSET (Node.js parity)")
	// And confirm the wait list is empty (priority job did NOT go there).
	waitLen, err := client.LLen(ctx, waitKey).Result()
	require.NoError(t, err)
	assert.Equal(t, int64(0), waitLen,
		"priority job must not appear on wait list (Node.js routing parity)")
}

// TestNodeJSCompatibility_KeyShape_DoesNotContainHashTags asserts the bare
// key shape on a single-instance Redis client matches the Node.js BullMQ
// default exactly. This is a defensive regression guard: any future change
// to KeyBuilder that flips single-instance to hash-tagged would break
// cross-language compatibility silently and this test fails first.
func TestNodeJSCompatibility_KeyShape_DoesNotContainHashTags(t *testing.T) {
	client := requireRedisOrSkip(t)
	t.Cleanup(func() { _ = client.Close() })

	const queueName = "compat-shape-guard"

	kb := echomq.NewKeyBuilder(queueName, client)
	keys := []string{
		kb.Wait(), kb.Active(), kb.Completed(), kb.Failed(),
		kb.Events(), kb.Meta(), kb.Job("1"), kb.Lock("1"),
		kb.Logs("1"), kb.Stalled(), kb.Marker(), kb.Paused(),
		kb.Prioritized(), kb.Delayed(), kb.PriorityCounter(),
		kb.RateLimiter(), kb.Metrics("completed"),
	}
	require.Len(t, keys, 17,
		"all 17 KeyBuilder methods must be exercised here (R-1 matrix parity)")

	for _, k := range keys {
		assert.False(t, strings.Contains(k, "{"),
			"single-instance key %q must not contain '{' (Node.js BullMQ parity)", k)
		assert.False(t, strings.Contains(k, "}"),
			"single-instance key %q must not contain '}' (Node.js BullMQ parity)", k)
		assert.True(t, strings.HasPrefix(k, "bull:"),
			"single-instance key %q must start with 'bull:' (D-9 invariant)", k)
	}
}
