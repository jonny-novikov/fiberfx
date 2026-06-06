package echomq

import (
	"testing"
	"time"

	"github.com/vmihailenco/msgpack/v5"
)

func TestParseFlatHGetAll(t *testing.T) {
	tests := []struct {
		name     string
		input    []interface{}
		expected map[string]string
	}{
		{
			name:     "empty input",
			input:    []interface{}{},
			expected: map[string]string{},
		},
		{
			name:  "single pair",
			input: []interface{}{"name", "test-job"},
			expected: map[string]string{
				"name": "test-job",
			},
		},
		{
			name:  "multiple pairs",
			input: []interface{}{"id", "job-1", "name", "test-job", "data", `{"foo":"bar"}`, "atm", "3"},
			expected: map[string]string{
				"id":   "job-1",
				"name": "test-job",
				"data": `{"foo":"bar"}`,
				"atm":  "3",
			},
		},
		{
			name:  "odd number of elements (last dropped)",
			input: []interface{}{"id", "job-1", "orphan"},
			expected: map[string]string{
				"id": "job-1",
			},
		},
		{
			name:  "numeric values converted to string",
			input: []interface{}{"atm", int64(5), "processedOn", int64(1700000000000)},
			expected: map[string]string{
				"atm":         "5",
				"processedOn": "1700000000000",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parseFlatHGetAll(tt.input)
			if len(result) != len(tt.expected) {
				t.Fatalf("expected %d entries, got %d", len(tt.expected), len(result))
			}
			for k, v := range tt.expected {
				if result[k] != v {
					t.Errorf("key %q: expected %q, got %q", k, v, result[k])
				}
			}
		})
	}
}

func TestJobFromHGetAllMap(t *testing.T) {
	data := map[string]string{
		"name":        "test-job",
		"data":        `{"action":"combat","target":"NPC_001"}`,
		"opts":        `{"priority":5,"attempts":3}`,
		"progress":    "50",
		"timestamp":   "1700000000000",
		"atm":         "2",
		"delay":       "1000",
		"processedOn": "1700000001000",
		"finishedOn":  "1700000002000",
		"failedReason": "network timeout",
	}

	job, err := jobFromHGetAllMap(data, "job-42", "combat-queue", nil, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if job.ID != "job-42" {
		t.Errorf("expected ID 'job-42', got %q", job.ID)
	}
	if job.Name != "test-job" {
		t.Errorf("expected Name 'test-job', got %q", job.Name)
	}
	if job.Data["action"] != "combat" {
		t.Errorf("expected Data['action'] = 'combat', got %v", job.Data["action"])
	}
	if job.Opts.Priority != 5 {
		t.Errorf("expected Opts.Priority = 5, got %d", job.Opts.Priority)
	}
	if job.Opts.Attempts != 3 {
		t.Errorf("expected Opts.Attempts = 3, got %d", job.Opts.Attempts)
	}
	if job.Progress != 50 {
		t.Errorf("expected Progress = 50, got %d", job.Progress)
	}
	if job.Timestamp != 1700000000000 {
		t.Errorf("expected Timestamp = 1700000000000, got %d", job.Timestamp)
	}
	if job.AttemptsMade != 2 {
		t.Errorf("expected AttemptsMade = 2, got %d", job.AttemptsMade)
	}
	if job.Delay != 1000 {
		t.Errorf("expected Delay = 1000, got %d", job.Delay)
	}
	if job.ProcessedOn != 1700000001000 {
		t.Errorf("expected ProcessedOn = 1700000001000, got %d", job.ProcessedOn)
	}
	if job.FinishedOn != 1700000002000 {
		t.Errorf("expected FinishedOn = 1700000002000, got %d", job.FinishedOn)
	}
	if job.FailedReason != "network timeout" {
		t.Errorf("expected FailedReason = 'network timeout', got %q", job.FailedReason)
	}
	if job.queueName != "combat-queue" {
		t.Errorf("expected queueName = 'combat-queue', got %q", job.queueName)
	}
}

func TestJobFromHGetAllMap_InvalidJSON(t *testing.T) {
	data := map[string]string{
		"data": "not-valid-json{{{",
	}
	_, err := jobFromHGetAllMap(data, "job-1", "q", nil, nil)
	if err == nil {
		t.Fatal("expected error for invalid JSON data")
	}
}

func TestPackMoveToActiveOpts(t *testing.T) {
	packed, err := packMoveToActiveOpts("token-123", 30000, "worker-1", nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Unpack and verify
	var result map[string]interface{}
	if err := msgpack.Unmarshal(packed, &result); err != nil {
		t.Fatalf("failed to unpack: %v", err)
	}

	if result["token"] != "token-123" {
		t.Errorf("expected token 'token-123', got %v", result["token"])
	}
	if toInt64(result["lockDuration"]) != 30000 {
		t.Errorf("expected lockDuration 30000, got %v", result["lockDuration"])
	}
	if result["name"] != "worker-1" {
		t.Errorf("expected name 'worker-1', got %v", result["name"])
	}
}

func TestPackMoveToActiveOpts_WithLimiter(t *testing.T) {
	limiter := &LimiterConfig{Max: 10, Duration: 5 * time.Second}
	packed, err := packMoveToActiveOpts("tok", 30000, "w", limiter)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var result map[string]interface{}
	if err := msgpack.Unmarshal(packed, &result); err != nil {
		t.Fatalf("failed to unpack: %v", err)
	}

	limiterMap, ok := result["limiter"].(map[string]interface{})
	if !ok {
		t.Fatal("expected limiter to be a map")
	}
	if toInt64(limiterMap["max"]) != 10 {
		t.Errorf("expected limiter.max = 10, got %v", limiterMap["max"])
	}
	if toInt64(limiterMap["duration"]) != 5000 {
		t.Errorf("expected limiter.duration = 5000, got %v", limiterMap["duration"])
	}
}

func TestPackMoveToFinishedOpts(t *testing.T) {
	keepJobs := map[string]interface{}{"count": 100, "age": nil}
	packed, err := packMoveToFinishedOpts("token-456", keepJobs, 30000, 3, "", "worker-1", nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	var result map[string]interface{}
	if err := msgpack.Unmarshal(packed, &result); err != nil {
		t.Fatalf("failed to unpack: %v", err)
	}

	if result["token"] != "token-456" {
		t.Errorf("expected token 'token-456', got %v", result["token"])
	}
	kj, ok := result["keepJobs"].(map[string]interface{})
	if !ok {
		t.Fatal("expected keepJobs to be a map")
	}
	if toInt64(kj["count"]) != 100 {
		t.Errorf("expected keepJobs.count = 100, got %v", kj["count"])
	}
	if toInt64(result["attempts"]) != 3 {
		t.Errorf("expected attempts = 3, got %v", result["attempts"])
	}
}

func TestKeepJobsFromRemoveOnSetting(t *testing.T) {
	tests := []struct {
		name        string
		setting     RemoveOnSetting
		expectCount interface{}
		expectAge   interface{}
	}{
		{
			name:        "remove immediately",
			setting:     RemoveOnSetting{Remove: true},
			expectCount: 0,
			expectAge:   nil,
		},
		{
			name:        "keep all",
			setting:     RemoveOnSetting{Remove: false},
			expectCount: nil,
			expectAge:   nil,
		},
		{
			name:        "keep last 50",
			setting:     RemoveOnSetting{Remove: true, Count: 50},
			expectCount: 50,
			expectAge:   nil,
		},
		{
			name:        "keep by age",
			setting:     RemoveOnSetting{Remove: true, Age: 3600},
			expectCount: nil,
			expectAge:   3600,
		},
		{
			name:        "keep by age and count",
			setting:     RemoveOnSetting{Remove: true, Age: 7200, Count: 100},
			expectCount: 100,
			expectAge:   7200,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := keepJobsFromRemoveOnSetting(tt.setting)

			if tt.expectCount == nil {
				if result["count"] != nil {
					t.Errorf("expected count=nil, got %v", result["count"])
				}
			} else {
				if result["count"] != tt.expectCount {
					t.Errorf("expected count=%v, got %v", tt.expectCount, result["count"])
				}
			}

			if tt.expectAge == nil {
				if result["age"] != nil {
					t.Errorf("expected age=nil, got %v", result["age"])
				}
			} else {
				if result["age"] != tt.expectAge {
					t.Errorf("expected age=%v, got %v", tt.expectAge, result["age"])
				}
			}
		})
	}
}

func TestBuildMoveToActiveKeys(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("test-queue", false)
	keys := buildMoveToActiveKeys(kb)

	if len(keys) != 11 {
		t.Fatalf("expected 11 keys, got %d", len(keys))
	}

	expected := []string{
		"bull:test-queue:wait",
		"bull:test-queue:active",
		"bull:test-queue:prioritized",
		"bull:test-queue:events",
		"bull:test-queue:stalled",
		"bull:test-queue:limiter",
		"bull:test-queue:delayed",
		"bull:test-queue:paused",
		"bull:test-queue:meta",
		"bull:test-queue:pc",
		"bull:test-queue:marker",
	}
	for i, key := range keys {
		if key != expected[i] {
			t.Errorf("KEYS[%d]: expected %q, got %q", i+1, expected[i], key)
		}
	}
}

func TestBuildMoveToFinishedKeys(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("test-queue", false)

	// Test completed target
	keys := buildMoveToFinishedKeys(kb, "job-1", "completed")
	if len(keys) != 14 {
		t.Fatalf("expected 14 keys, got %d", len(keys))
	}
	if keys[10] != "bull:test-queue:completed" {
		t.Errorf("KEYS[11] expected completed key, got %q", keys[10])
	}
	if keys[11] != "bull:test-queue:job-1" {
		t.Errorf("KEYS[12] expected job key, got %q", keys[11])
	}
	if keys[12] != "bull:test-queue:metrics:completed" {
		t.Errorf("KEYS[13] expected metrics key, got %q", keys[12])
	}
	if keys[13] != "bull:test-queue:marker" {
		t.Errorf("KEYS[14] expected marker key, got %q", keys[13])
	}

	// Test failed target
	keys = buildMoveToFinishedKeys(kb, "job-2", "failed")
	if keys[10] != "bull:test-queue:failed" {
		t.Errorf("KEYS[11] expected failed key, got %q", keys[10])
	}
	if keys[12] != "bull:test-queue:metrics:failed" {
		t.Errorf("KEYS[13] expected metrics:failed key, got %q", keys[12])
	}
}

func TestToInt64(t *testing.T) {
	tests := []struct {
		input    interface{}
		expected int64
	}{
		{int64(42), 42},
		{int(7), 7},
		{float64(3.14), 3},
		{"100", 100},
		{nil, 0},
		{true, 0},
	}

	for _, tt := range tests {
		result := toInt64(tt.input)
		if result != tt.expected {
			t.Errorf("toInt64(%v) = %d, want %d", tt.input, result, tt.expected)
		}
	}
}

func TestScriptErrorMessage(t *testing.T) {
	if msg := scriptErrorMessage(-1); msg != "job key does not exist" {
		t.Errorf("unexpected message for -1: %q", msg)
	}
	if msg := scriptErrorMessage(-2); msg != "lock is missing" {
		t.Errorf("unexpected message for -2: %q", msg)
	}
	if msg := scriptErrorMessage(-6); msg != "lock is not owned by this client" {
		t.Errorf("unexpected message for -6: %q", msg)
	}
	if msg := scriptErrorMessage(99); msg != "unknown error" {
		t.Errorf("unexpected message for 99: %q", msg)
	}
}

func TestKeyBuilder_NewMethods(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("myqueue", false)
	if kb.RateLimiter() != "bull:myqueue:limiter" {
		t.Errorf("RateLimiter: got %q", kb.RateLimiter())
	}
	if kb.Paused() != "bull:myqueue:paused" {
		t.Errorf("Paused: got %q", kb.Paused())
	}
	if kb.Marker() != "bull:myqueue:marker" {
		t.Errorf("Marker: got %q", kb.Marker())
	}
	if kb.Metrics("completed") != "bull:myqueue:metrics:completed" {
		t.Errorf("Metrics(completed): got %q", kb.Metrics("completed"))
	}
	if kb.Metrics("failed") != "bull:myqueue:metrics:failed" {
		t.Errorf("Metrics(failed): got %q", kb.Metrics("failed"))
	}
	if kb.Prefix() != "bull:myqueue:" {
		t.Errorf("Prefix: got %q", kb.Prefix())
	}

	// Test with hash tags
	kbCluster := NewKeyBuilderWithHashTags("myqueue", true)
	if kbCluster.RateLimiter() != "bull:{myqueue}:limiter" {
		t.Errorf("Cluster RateLimiter: got %q", kbCluster.RateLimiter())
	}
	if kbCluster.Prefix() != "bull:{myqueue}:" {
		t.Errorf("Cluster Prefix: got %q", kbCluster.Prefix())
	}
}

func TestBuildRetryJobKeys(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("retry-queue", false)
	keys := buildRetryJobKeys(kb, "job-99")

	if len(keys) != 11 {
		t.Fatalf("expected 11 keys, got %d", len(keys))
	}

	expected := []string{
		"bull:retry-queue:active",      // KEYS[1]
		"bull:retry-queue:wait",        // KEYS[2]
		"bull:retry-queue:paused",      // KEYS[3]
		"bull:retry-queue:job-99",      // KEYS[4] - job key
		"bull:retry-queue:meta",        // KEYS[5]
		"bull:retry-queue:events",      // KEYS[6]
		"bull:retry-queue:delayed",     // KEYS[7]
		"bull:retry-queue:prioritized", // KEYS[8]
		"bull:retry-queue:pc",          // KEYS[9]
		"bull:retry-queue:marker",      // KEYS[10]
		"bull:retry-queue:stalled",     // KEYS[11]
	}
	for i, key := range keys {
		if key != expected[i] {
			t.Errorf("KEYS[%d]: expected %q, got %q", i+1, expected[i], key)
		}
	}
}

func TestBuildRetryJobKeys_ClusterMode(t *testing.T) {
	kb := NewKeyBuilderWithHashTags("retry-queue", true)
	keys := buildRetryJobKeys(kb, "job-1")

	if len(keys) != 11 {
		t.Fatalf("expected 11 keys, got %d", len(keys))
	}

	// Verify hash tags are present in cluster mode
	expectedPrefixes := []string{
		"bull:{retry-queue}:active",
		"bull:{retry-queue}:wait",
		"bull:{retry-queue}:paused",
		"bull:{retry-queue}:job-1",
		"bull:{retry-queue}:meta",
		"bull:{retry-queue}:events",
		"bull:{retry-queue}:delayed",
		"bull:{retry-queue}:prioritized",
		"bull:{retry-queue}:pc",
		"bull:{retry-queue}:marker",
		"bull:{retry-queue}:stalled",
	}
	for i, key := range keys {
		if key != expectedPrefixes[i] {
			t.Errorf("KEYS[%d]: expected %q, got %q", i+1, expectedPrefixes[i], key)
		}
	}
}
