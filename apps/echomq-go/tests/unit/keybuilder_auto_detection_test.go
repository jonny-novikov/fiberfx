// Package unit contains unit tests for the echomq-go library.
//
// File: keybuilder_auto_detection_test.go
// Scope: R-1 acceptance — exhaustive coverage of all 17 KeyBuilder methods
// across three modes (single-instance auto-detect, cluster auto-detect,
// ForceHashTags override) per dev/mcp/features/FTR-009-echomq-go-parity/
// spec.yaml R-1 + phases/phase-1-state-contract.md §Redis Key Inventory.
//
// Matrix: 17 methods × 3 modes = 51 rows.
// Edge cases: empty queue name, multi-colon job IDs, multi-target metrics.
//
// Invariants asserted (Phase 1 §Locked Invariants):
//   - D-9: every key starts with literal `bull:` (cross-language wire compat).
//   - Single-instance: NO hash tags (matches Node.js BullMQ default).
//   - Cluster: hash tags `{<queue>}` enclose queue name (CROSSSLOT prevention).
//   - ForceHashTags(true) on single-instance: matches cluster shape.
//   - ForceHashTags(false) on cluster client: matches single-instance shape.
package unit

import (
	"strings"
	"testing"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// keyBuilderMethod names every method on KeyBuilder that participates in the
// 17-method matrix. The list is the authoritative ordering from
// pkg/echomq/keys.go:42-184. Adding a new method on KeyBuilder REQUIRES
// adding a row here so the matrix expands automatically.
//
// Methods 9-11 (Job, Lock, Logs) take a jobID argument; method 17 (Metrics)
// takes a target. The keyFunc closure abstracts argument shape.
type keyBuilderRow struct {
	method      string // human-readable method name (matches keys.go)
	jobID       string // non-empty for Job/Lock/Logs; "" otherwise
	target      string // non-empty for Metrics; "" otherwise
	expectNoTag string // expected key shape under single-instance mode
	expectTag   string // expected key shape under cluster mode
	keyFunc     func(*echomq.KeyBuilder) string
}

// queueName for the canonical 17-method matrix (51 rows).
const matrixQueueName = "video-generation"

// matrixRows returns the 17 method × queue-name combinations that drive every
// matrix variant. Suffix patterns mirror the table at
// dev/mcp/features/FTR-009-echomq-go-parity/phases/phase-1-state-contract.md
// §Redis Key Inventory.
//
// Note: Prefix() is the 18th helper called out in §Redis Key Inventory but
// not counted in this 17-method matrix (per R-1 task spec). Prefix() is
// asserted independently in TestKeyBuilder_Prefix_AutoDetection.
func matrixRows(queueName string) []keyBuilderRow {
	const (
		jobID  = "job-42"
		target = "completed"
	)
	noTag := func(suffix string) string { return "bull:" + queueName + ":" + suffix }
	withTag := func(suffix string) string { return "bull:{" + queueName + "}:" + suffix }

	return []keyBuilderRow{
		{method: "Wait", expectNoTag: noTag("wait"), expectTag: withTag("wait"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Wait() }},
		{method: "Prioritized", expectNoTag: noTag("prioritized"), expectTag: withTag("prioritized"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Prioritized() }},
		{method: "Delayed", expectNoTag: noTag("delayed"), expectTag: withTag("delayed"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Delayed() }},
		{method: "Active", expectNoTag: noTag("active"), expectTag: withTag("active"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Active() }},
		{method: "Completed", expectNoTag: noTag("completed"), expectTag: withTag("completed"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Completed() }},
		{method: "Failed", expectNoTag: noTag("failed"), expectTag: withTag("failed"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Failed() }},
		{method: "Events", expectNoTag: noTag("events"), expectTag: withTag("events"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Events() }},
		{method: "Meta", expectNoTag: noTag("meta"), expectTag: withTag("meta"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Meta() }},
		{method: "Job", jobID: jobID, expectNoTag: noTag(jobID), expectTag: withTag(jobID),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Job(jobID) }},
		{method: "Lock", jobID: jobID, expectNoTag: noTag(jobID + ":lock"), expectTag: withTag(jobID + ":lock"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Lock(jobID) }},
		{method: "Logs", jobID: jobID, expectNoTag: noTag(jobID + ":logs"), expectTag: withTag(jobID + ":logs"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Logs(jobID) }},
		{method: "Stalled", expectNoTag: noTag("stalled"), expectTag: withTag("stalled"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Stalled() }},
		{method: "PriorityCounter", expectNoTag: noTag("pc"), expectTag: withTag("pc"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.PriorityCounter() }},
		{method: "RateLimiter", expectNoTag: noTag("limiter"), expectTag: withTag("limiter"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.RateLimiter() }},
		{method: "Paused", expectNoTag: noTag("paused"), expectTag: withTag("paused"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Paused() }},
		{method: "Marker", expectNoTag: noTag("marker"), expectTag: withTag("marker"),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Marker() }},
		{method: "Metrics", target: target, expectNoTag: noTag("metrics:" + target), expectTag: withTag("metrics:" + target),
			keyFunc: func(kb *echomq.KeyBuilder) string { return kb.Metrics(target) }},
	}
}

// TestKeyBuilder_Matrix_SingleInstance asserts all 17 KeyBuilder methods
// produce single-instance key shape (no hash tags) when constructed with a
// *redis.Client. Row count: 17.
//
// This test is the single-instance leg of the 51-row R-1 matrix.
func TestKeyBuilder_Matrix_SingleInstance(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	t.Cleanup(func() { _ = client.Close() })

	require.False(t, echomq.IsRedisCluster(client),
		"precondition: *redis.Client must not be detected as cluster")

	kb := echomq.NewKeyBuilder(matrixQueueName, client)
	require.NotNil(t, kb)

	rows := matrixRows(matrixQueueName)
	require.Len(t, rows, 17,
		"matrix invariant: exactly 17 KeyBuilder methods (per §Redis Key Inventory)")

	for _, row := range rows {
		t.Run(row.method, func(t *testing.T) {
			got := row.keyFunc(kb)
			assert.Equal(t, row.expectNoTag, got,
				"single-instance key for %s must NOT contain hash tags", row.method)

			// D-9 prefix invariant.
			assert.True(t, strings.HasPrefix(got, "bull:"),
				"D-9 invariant: every key must start with 'bull:' — got %q", got)
			// Single-instance invariant.
			assert.NotContains(t, got, "{",
				"single-instance key must not contain '{' — got %q", got)
			assert.NotContains(t, got, "}",
				"single-instance key must not contain '}' — got %q", got)
		})
	}
}

// TestKeyBuilder_Matrix_Cluster asserts all 17 KeyBuilder methods produce
// cluster key shape (hash tags around queue name) when constructed with a
// *redis.ClusterClient. Row count: 17.
//
// This test is the cluster leg of the 51-row R-1 matrix.
//
// Note: NewClusterClient does not require an active cluster connection for
// type-detection-only tests — KeyBuilder reads only the Go type at construct.
func TestKeyBuilder_Matrix_Cluster(t *testing.T) {
	client := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{"localhost:7001"},
	})
	t.Cleanup(func() { _ = client.Close() })

	require.True(t, echomq.IsRedisCluster(client),
		"precondition: *redis.ClusterClient must be detected as cluster")

	kb := echomq.NewKeyBuilder(matrixQueueName, client)
	require.NotNil(t, kb)

	rows := matrixRows(matrixQueueName)
	require.Len(t, rows, 17,
		"matrix invariant: exactly 17 KeyBuilder methods (per §Redis Key Inventory)")

	expectedTag := "{" + matrixQueueName + "}"
	for _, row := range rows {
		t.Run(row.method, func(t *testing.T) {
			got := row.keyFunc(kb)
			assert.Equal(t, row.expectTag, got,
				"cluster key for %s must contain hash tags around queue name", row.method)

			// D-9 prefix invariant.
			assert.True(t, strings.HasPrefix(got, "bull:"),
				"D-9 invariant: every key must start with 'bull:' — got %q", got)
			// Cluster invariant.
			assert.Contains(t, got, expectedTag,
				"cluster key must contain hash tag %q — got %q", expectedTag, got)
		})
	}
}

// TestKeyBuilder_Matrix_ForceHashTags asserts NewKeyBuilderWithHashTags(true)
// on a *redis.Client (single-instance) produces cluster-shape keys for all
// 17 methods. Row count: 17.
//
// This test is the override leg of the 51-row R-1 matrix.
func TestKeyBuilder_Matrix_ForceHashTags(t *testing.T) {
	kb := echomq.NewKeyBuilderWithHashTags(matrixQueueName, true)
	require.NotNil(t, kb)

	rows := matrixRows(matrixQueueName)
	require.Len(t, rows, 17,
		"matrix invariant: exactly 17 KeyBuilder methods (per §Redis Key Inventory)")

	expectedTag := "{" + matrixQueueName + "}"
	for _, row := range rows {
		t.Run(row.method, func(t *testing.T) {
			got := row.keyFunc(kb)
			assert.Equal(t, row.expectTag, got,
				"ForceHashTags(true) for %s must produce cluster-shape key", row.method)

			assert.True(t, strings.HasPrefix(got, "bull:"),
				"D-9 invariant: every key must start with 'bull:' — got %q", got)
			assert.Contains(t, got, expectedTag,
				"override key must contain hash tag %q — got %q", expectedTag, got)
		})
	}
}

// TestKeyBuilder_Matrix_ForceNoHashTags asserts NewKeyBuilderWithHashTags(false)
// produces single-instance-shape keys regardless of subsequent client type.
//
// Why this matters: an operator migrating from v0.1.0 (always-hash-tags) to
// v0.1.1 (auto-detect) on a cluster client may need the no-tag form to read
// legacy data; the explicit `false` override supports that fallback.
func TestKeyBuilder_Matrix_ForceNoHashTags(t *testing.T) {
	kb := echomq.NewKeyBuilderWithHashTags(matrixQueueName, false)
	require.NotNil(t, kb)

	rows := matrixRows(matrixQueueName)
	require.Len(t, rows, 17,
		"matrix invariant: exactly 17 KeyBuilder methods (per §Redis Key Inventory)")

	for _, row := range rows {
		t.Run(row.method, func(t *testing.T) {
			got := row.keyFunc(kb)
			assert.Equal(t, row.expectNoTag, got,
				"ForceHashTags(false) for %s must produce single-instance shape", row.method)
			assert.NotContains(t, got, "{",
				"override key must not contain '{' — got %q", got)
			assert.NotContains(t, got, "}",
				"override key must not contain '}' — got %q", got)
		})
	}
}

// TestKeyBuilder_Prefix_AutoDetection asserts the Prefix() helper (called out
// at phase-1-state-contract.md §Redis Key Inventory as the 18th method but
// not counted in the 17-row matrix) honors auto-detection. Used by Lua
// scripts that receive the prefix via ARGV and reconstruct subsequent keys.
func TestKeyBuilder_Prefix_AutoDetection(t *testing.T) {
	t.Run("SingleInstance", func(t *testing.T) {
		client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder(matrixQueueName, client)
		assert.Equal(t, "bull:"+matrixQueueName+":", kb.Prefix())
	})

	t.Run("Cluster", func(t *testing.T) {
		client := redis.NewClusterClient(&redis.ClusterOptions{
			Addrs: []string{"localhost:7001"},
		})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder(matrixQueueName, client)
		assert.Equal(t, "bull:{"+matrixQueueName+"}:", kb.Prefix())
	})

	t.Run("ForceHashTagsTrue", func(t *testing.T) {
		kb := echomq.NewKeyBuilderWithHashTags(matrixQueueName, true)
		assert.Equal(t, "bull:{"+matrixQueueName+"}:", kb.Prefix())
	})

	t.Run("ForceHashTagsFalse", func(t *testing.T) {
		kb := echomq.NewKeyBuilderWithHashTags(matrixQueueName, false)
		assert.Equal(t, "bull:"+matrixQueueName+":", kb.Prefix())
	})
}

// TestKeyBuilder_EdgeCase_EmptyQueueName asserts that an empty queue name
// produces structurally well-formed keys. The library does not currently
// validate queue names; this test pins the resulting wire format so a future
// validation change does not silently break callers.
//
// Edge-case rationale: Node.js BullMQ accepts any string for queue name
// including empty (which produces `bull::wait`). Verifying Go matches that
// shape is necessary for cross-language wire compatibility.
func TestKeyBuilder_EdgeCase_EmptyQueueName(t *testing.T) {
	t.Run("SingleInstance_Empty", func(t *testing.T) {
		client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder("", client)

		assert.Equal(t, "bull::wait", kb.Wait())
		assert.Equal(t, "bull:::lock", kb.Lock(""))
		assert.Equal(t, "bull::", kb.Prefix())
		// D-9 still holds.
		assert.True(t, strings.HasPrefix(kb.Wait(), "bull:"))
	})

	t.Run("Cluster_Empty", func(t *testing.T) {
		client := redis.NewClusterClient(&redis.ClusterOptions{
			Addrs: []string{"localhost:7001"},
		})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder("", client)

		// Empty hash tag {} is a degenerate case: Redis treats {} as no hash
		// tag (per CLUSTER spec — empty content between braces is ignored).
		// We assert the shape preserves the braces literally — operator
		// debugging requires the wire format to match the constructor input.
		assert.Equal(t, "bull:{}:wait", kb.Wait())
		assert.Equal(t, "bull:{}::lock", kb.Lock(""))
	})
}

// TestKeyBuilder_EdgeCase_MultiColonJobID asserts the Job/Lock/Logs methods
// preserve colons inside jobID. Caller-provided IDs may contain colons (e.g.,
// UUID:retry-count or namespace:hash); the library MUST NOT escape them or
// the wire contract breaks.
func TestKeyBuilder_EdgeCase_MultiColonJobID(t *testing.T) {
	const colonJobID = "ns:account-42:retry:7"

	t.Run("SingleInstance", func(t *testing.T) {
		client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder(matrixQueueName, client)

		assert.Equal(t,
			"bull:"+matrixQueueName+":"+colonJobID,
			kb.Job(colonJobID))
		assert.Equal(t,
			"bull:"+matrixQueueName+":"+colonJobID+":lock",
			kb.Lock(colonJobID))
		assert.Equal(t,
			"bull:"+matrixQueueName+":"+colonJobID+":logs",
			kb.Logs(colonJobID))
	})

	t.Run("Cluster", func(t *testing.T) {
		client := redis.NewClusterClient(&redis.ClusterOptions{
			Addrs: []string{"localhost:7001"},
		})
		t.Cleanup(func() { _ = client.Close() })
		kb := echomq.NewKeyBuilder(matrixQueueName, client)

		assert.Equal(t,
			"bull:{"+matrixQueueName+"}:"+colonJobID,
			kb.Job(colonJobID))
		assert.Equal(t,
			"bull:{"+matrixQueueName+"}:"+colonJobID+":lock",
			kb.Lock(colonJobID))
		assert.Equal(t,
			"bull:{"+matrixQueueName+"}:"+colonJobID+":logs",
			kb.Logs(colonJobID))
	})
}

// TestKeyBuilder_EdgeCase_MultiTargetMetrics asserts Metrics() handles the
// two canonical targets (`completed`, `failed`) and a custom target without
// shape drift. Phase 1 §Redis Key Inventory pins `metrics:<target>` as the
// suffix shape.
func TestKeyBuilder_EdgeCase_MultiTargetMetrics(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	t.Cleanup(func() { _ = client.Close() })
	kb := echomq.NewKeyBuilder(matrixQueueName, client)

	for _, target := range []string{"completed", "failed", "custom-metric"} {
		t.Run(target, func(t *testing.T) {
			assert.Equal(t,
				"bull:"+matrixQueueName+":metrics:"+target,
				kb.Metrics(target))
		})
	}

	// Cluster shape parity for the same targets.
	clusterClient := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{"localhost:7001"},
	})
	t.Cleanup(func() { _ = clusterClient.Close() })
	clusterKB := echomq.NewKeyBuilder(matrixQueueName, clusterClient)

	for _, target := range []string{"completed", "failed", "custom-metric"} {
		t.Run("cluster_"+target, func(t *testing.T) {
			assert.Equal(t,
				"bull:{"+matrixQueueName+"}:metrics:"+target,
				clusterKB.Metrics(target))
		})
	}
}

// TestKeyBuilder_NilClient_DefaultsToSingleInstance asserts that
// NewKeyBuilder with a nil client falls through IsRedisCluster's nil-safe
// path (cluster.go:171-175 returns false for nil) and produces
// single-instance-shape keys. This pins behavior so a future change to the
// nil-handling path does not silently flip cluster mode on.
func TestKeyBuilder_NilClient_DefaultsToSingleInstance(t *testing.T) {
	kb := echomq.NewKeyBuilder(matrixQueueName, nil)
	require.NotNil(t, kb)

	assert.Equal(t, "bull:"+matrixQueueName+":wait", kb.Wait())
	assert.NotContains(t, kb.Wait(), "{",
		"nil client should default to single-instance shape, not cluster")
}

// TestKeyBuilder_Idempotency asserts that successive calls to the same
// KeyBuilder method return byte-identical results. KeyBuilder is documented
// as stateless after construction (keys.go:10-13); this test pins that
// invariant against future internal-state introduction.
func TestKeyBuilder_Idempotency(t *testing.T) {
	kb := echomq.NewKeyBuilderWithHashTags(matrixQueueName, false)

	rows := matrixRows(matrixQueueName)
	for _, row := range rows {
		t.Run(row.method, func(t *testing.T) {
			first := row.keyFunc(kb)
			for i := 0; i < 5; i++ {
				assert.Equal(t, first, row.keyFunc(kb),
					"call %d of %s must equal first call (KeyBuilder is stateless)", i+2, row.method)
			}
		})
	}
}

// TestKeyBuilder_CrossLanguageWireFormat_NodeDefault is a documentation-shape
// test: it pins the exact byte sequence that Node.js BullMQ v5.62.0 produces
// on single-instance Redis for a representative queue. If Node.js BullMQ
// upstream ever changes its default key shape (extremely unlikely), this
// test fails as the canary.
//
// Reference: BullMQ v5.62.0 src/utils.ts and src/classes/queue.ts at pinned
// commit 6a31e0aeab1311d7d089811ede7e11a98b6dd408 (per state.yaml D-5).
func TestKeyBuilder_CrossLanguageWireFormat_NodeDefault(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	t.Cleanup(func() { _ = client.Close() })

	const nodeStyleQueue = "email-notifications"
	kb := echomq.NewKeyBuilder(nodeStyleQueue, client)

	// These exact strings are what `redis-cli KEYS bull:email-notifications:*`
	// returns after a Node.js BullMQ producer adds a single job named
	// "send-welcome-email" with jobID="1".
	expected := map[string]string{
		"wait":       "bull:email-notifications:wait",
		"active":     "bull:email-notifications:active",
		"completed":  "bull:email-notifications:completed",
		"failed":     "bull:email-notifications:failed",
		"events":     "bull:email-notifications:events",
		"meta":       "bull:email-notifications:meta",
		"job_1":      "bull:email-notifications:1",
		"lock_1":     "bull:email-notifications:1:lock",
		"prefix":     "bull:email-notifications:",
		"prioritized": "bull:email-notifications:prioritized",
		"delayed":    "bull:email-notifications:delayed",
		"marker":     "bull:email-notifications:marker",
	}

	got := map[string]string{
		"wait":        kb.Wait(),
		"active":      kb.Active(),
		"completed":   kb.Completed(),
		"failed":      kb.Failed(),
		"events":      kb.Events(),
		"meta":        kb.Meta(),
		"job_1":       kb.Job("1"),
		"lock_1":      kb.Lock("1"),
		"prefix":      kb.Prefix(),
		"prioritized": kb.Prioritized(),
		"delayed":     kb.Delayed(),
		"marker":      kb.Marker(),
	}

	assert.Equal(t, expected, got,
		"Go KeyBuilder MUST produce byte-identical keys to Node.js BullMQ v5.62.0 default")
}

// TestKeyBuilder_CrossLanguageWireFormat_ClusterParity pins the cluster-mode
// wire format against Node.js BullMQ's `prefix: '{queue}'` cluster
// configuration (per HOTFIX_ANALYSIS.md §The Incompatibility Matrix line 31).
func TestKeyBuilder_CrossLanguageWireFormat_ClusterParity(t *testing.T) {
	client := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{"localhost:7001"},
	})
	t.Cleanup(func() { _ = client.Close() })

	const queue = "video-pipeline"
	kb := echomq.NewKeyBuilder(queue, client)

	// All cluster keys MUST hash to the same slot because the hash tag is
	// constant — this is what enables multi-key Lua scripts to work without
	// CROSSSLOT errors. The slot itself is deterministic but its specific
	// numeric value is not asserted here (covered by cluster.go tests).
	keys := []string{
		kb.Wait(), kb.Active(), kb.Completed(), kb.Failed(),
		kb.Events(), kb.Meta(), kb.Job("42"), kb.Lock("42"),
		kb.Prioritized(), kb.Delayed(), kb.Marker(),
	}

	for _, k := range keys {
		assert.True(t, strings.HasPrefix(k, "bull:{"+queue+"}:"),
			"cluster key must start with hash-tag prefix bull:{%s}: — got %q", queue, k)
	}

	// Use the library's own slot-validation to confirm all keys are in the
	// same slot. This is the runtime-correctness guard that protects
	// multi-key Lua scripts from CROSSSLOT failures.
	allSameSlot, slot, slotsByKey := echomq.ValidateHashTags(keys)
	assert.True(t, allSameSlot,
		"all cluster keys for queue %q must hash to the same slot; got per-key slots %v", queue, slotsByKey)
	assert.GreaterOrEqual(t, slot, 0)
	assert.Less(t, slot, echomq.RedisClusterSlots)
}
