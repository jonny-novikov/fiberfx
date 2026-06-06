// Package unit contains unit tests for the echomq-go library.
//
// File: force_hash_tags_test.go
// Scope: R-4 acceptance — QueueOptions.ForceHashTags + WorkerOptions.ForceHashTags
// tri-state override for Redis-Cluster key-format auto-detection.
//
// Matrix (per client type × per option state × Queue & Worker code paths):
//
//	CLIENT                  | nil (auto)        | &true (force on)  | &false (force off)
//	redis.Client            | flat              | hash-tagged       | flat
//	redis.ClusterClient     | hash-tagged       | hash-tagged       | flat
//
// Invariants asserted:
//   - D-9: every emitted key starts with literal `bull:` (cross-language wire compat).
//   - Tri-state pointer semantics: nil = auto-detect, &true/&false = override.
//   - QueueOptions.ForceHashTags and WorkerOptions.ForceHashTags MUST produce identical
//     key shapes when both set to the same non-nil value on the same queue name.
//
// Reference: spec.yaml R-4 acceptance lines 71-84; D-11 (tri-state option pattern).
package unit

import (
	"strings"
	"testing"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const forceHashTagsQueueName = "force-hash-tags-queue"

// ptrBool is a test helper that returns a *bool pointing to v. Avoids the
// "cannot take address of untyped constant" trap when writing table rows.
func ptrBool(v bool) *bool { return &v }

// forceHashTagsCase encodes one row of the R-4 matrix. Each row asserts both
// Queue and Worker code paths produce the same key shape for a given
// (client type × ForceHashTags state) combination.
type forceHashTagsCase struct {
	name           string
	useCluster     bool  // true = redis.NewClusterClient; false = redis.NewClient
	forceHashTags  *bool // nil / &true / &false
	expectHashTags bool  // ground-truth expected key shape for this (client, option) pair
}

// forceHashTagsCases is the 6-row matrix (2 client types × 3 tri-states).
// Derived from the table in the file header comment.
var forceHashTagsCases = []forceHashTagsCase{
	{"single-instance + nil (auto) -> flat", false, nil, false},
	{"single-instance + &true -> hash-tagged (override on)", false, ptrBool(true), true},
	{"single-instance + &false -> flat (explicit no-op)", false, ptrBool(false), false},
	{"cluster + nil (auto) -> hash-tagged", true, nil, true},
	{"cluster + &true -> hash-tagged (explicit no-op)", true, ptrBool(true), true},
	{"cluster + &false -> flat (override off)", true, ptrBool(false), false},
}

// newClient returns a redis.Cmdable of the requested type. The client is NEVER used
// to issue actual Redis commands in this test suite — only its *type* feeds
// echomq.IsRedisCluster() for auto-detection. Offline-safe.
func newClient(t *testing.T, cluster bool) redis.Cmdable {
	t.Helper()
	if cluster {
		return redis.NewClusterClient(&redis.ClusterOptions{
			Addrs: []string{"localhost:6379"},
		})
	}
	return redis.NewClient(&redis.Options{Addr: "localhost:6379"})
}

// hasHashTag returns true if the key uses `{queueName}` hash-tag syntax.
// This is the canonical signal for cluster-safe key format.
func hasHashTag(key, queueName string) bool {
	return strings.Contains(key, "{"+queueName+"}")
}

// TestQueueOptions_ForceHashTags asserts the Queue code path honors all 3 tri-state
// values across both client types, producing the 6 expected shapes from the matrix.
func TestQueueOptions_ForceHashTags(t *testing.T) {
	for _, tc := range forceHashTagsCases {
		t.Run("Queue/"+tc.name, func(t *testing.T) {
			client := newClient(t, tc.useCluster)
			q := echomq.NewQueueWithOptions(forceHashTagsQueueName, client, echomq.QueueOptions{
				ForceHashTags: tc.forceHashTags,
			})
			require.NotNil(t, q, "NewQueueWithOptions must not return nil")
			require.NotNil(t, q.KeyBuilder(), "Queue must expose a non-nil KeyBuilder")

			waitKey := q.KeyBuilder().Wait()
			assert.True(t, strings.HasPrefix(waitKey, "bull:"),
				"D-9: every key must start with `bull:` (got %q)", waitKey)

			if tc.expectHashTags {
				assert.True(t, hasHashTag(waitKey, forceHashTagsQueueName),
					"case %s: expected hash-tagged key shape, got %q", tc.name, waitKey)
			} else {
				assert.False(t, hasHashTag(waitKey, forceHashTagsQueueName),
					"case %s: expected flat key shape, got %q", tc.name, waitKey)
			}
		})
	}
}

// TestWorkerOptions_ForceHashTags asserts the Worker code path honors all 3 tri-state
// values across both client types. Exercises Worker.KeyBuilder() accessor which
// subsystems (heartbeat, stalled, completer, logs, progress, events) consume.
func TestWorkerOptions_ForceHashTags(t *testing.T) {
	for _, tc := range forceHashTagsCases {
		t.Run("Worker/"+tc.name, func(t *testing.T) {
			client := newClient(t, tc.useCluster)
			w := echomq.NewWorker(forceHashTagsQueueName, client, echomq.WorkerOptions{
				Concurrency:   1,
				ForceHashTags: tc.forceHashTags,
			})
			require.NotNil(t, w, "NewWorker must not return nil")
			require.NotNil(t, w.KeyBuilder(), "Worker must expose a non-nil KeyBuilder")

			// Probe across multiple key shapes to confirm the single-source-of-truth
			// invariant: every subsystem-facing key method must produce the same
			// format as Wait() (hash-tagged or flat, not a mix).
			keys := map[string]string{
				"Wait":         w.KeyBuilder().Wait(),
				"Active":       w.KeyBuilder().Active(),
				"Prioritized":  w.KeyBuilder().Prioritized(),
				"Events":       w.KeyBuilder().Events(),
				"Job":          w.KeyBuilder().Job("jobid-sample"),
				"Lock":         w.KeyBuilder().Lock("jobid-sample"),
				"Stalled":      w.KeyBuilder().Stalled(),
				"Prefix":       w.KeyBuilder().Prefix(),
			}

			for keyName, key := range keys {
				assert.True(t, strings.HasPrefix(key, "bull:"),
					"D-9: %s key must start with `bull:` (got %q)", keyName, key)
				if tc.expectHashTags {
					assert.True(t, hasHashTag(key, forceHashTagsQueueName),
						"case %s: %s expected hash-tagged, got %q", tc.name, keyName, key)
				} else {
					assert.False(t, hasHashTag(key, forceHashTagsQueueName),
						"case %s: %s expected flat, got %q", tc.name, keyName, key)
				}
			}
		})
	}
}

// TestQueueWorkerForceHashTagsParity asserts that when QueueOptions and WorkerOptions
// use the same non-nil ForceHashTags value on the same queue name, both produce
// byte-identical keys. This is the operational invariant that prevents producer/
// consumer key-shape divergence (see WorkerOptions.ForceHashTags godoc).
func TestQueueWorkerForceHashTagsParity(t *testing.T) {
	parityCases := []struct {
		name          string
		useCluster    bool
		forceHashTags *bool
	}{
		{"single-instance + force on", false, ptrBool(true)},
		{"single-instance + force off", false, ptrBool(false)},
		{"cluster + force on", true, ptrBool(true)},
		{"cluster + force off", true, ptrBool(false)},
		{"single-instance + auto-detect", false, nil},
		{"cluster + auto-detect", true, nil},
	}
	for _, tc := range parityCases {
		t.Run(tc.name, func(t *testing.T) {
			client := newClient(t, tc.useCluster)
			q := echomq.NewQueueWithOptions(forceHashTagsQueueName, client, echomq.QueueOptions{
				ForceHashTags: tc.forceHashTags,
			})
			w := echomq.NewWorker(forceHashTagsQueueName, client, echomq.WorkerOptions{
				Concurrency:   1,
				ForceHashTags: tc.forceHashTags,
			})
			assert.Equal(t, q.KeyBuilder().Wait(), w.KeyBuilder().Wait(),
				"Wait key must match between Queue and Worker with matching ForceHashTags")
			assert.Equal(t, q.KeyBuilder().Active(), w.KeyBuilder().Active(),
				"Active key must match")
			assert.Equal(t, q.KeyBuilder().Prioritized(), w.KeyBuilder().Prioritized(),
				"Prioritized key must match")
			assert.Equal(t, q.KeyBuilder().Events(), w.KeyBuilder().Events(),
				"Events key must match — critical: EventEmitter in Queue and Worker must share key shape")
			assert.Equal(t, q.KeyBuilder().Prefix(), w.KeyBuilder().Prefix(),
				"Prefix must match — used by moveToFinished / retryJob Lua scripts")
		})
	}
}

// TestNewQueue_BackwardCompatibility asserts that the pre-R-4 NewQueue(name, client)
// signature still works and delegates to auto-detect behavior.
func TestNewQueue_BackwardCompatibility(t *testing.T) {
	client := newClient(t, false)
	q := echomq.NewQueue(forceHashTagsQueueName, client)
	require.NotNil(t, q)
	require.NotNil(t, q.KeyBuilder())
	waitKey := q.KeyBuilder().Wait()
	assert.True(t, strings.HasPrefix(waitKey, "bull:"))
	assert.False(t, hasHashTag(waitKey, forceHashTagsQueueName),
		"NewQueue with single-instance client must auto-detect to flat keys")
}
