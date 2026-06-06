package echomq

import "fmt"

// KeyBuilder generates Redis keys with conditional hash tags for cluster compatibility.
//
// Hash tags {queue-name} are used ONLY in Redis Cluster mode to ensure all keys for a queue
// hash to the same slot (required for multi-key Lua scripts). In single-instance Redis mode,
// hash tags are omitted to match Node.js EchoMQ default behavior for cross-language compatibility.
type KeyBuilder struct {
	queueName   string
	useHashTags bool // Auto-detected from Redis client type, or explicitly set
}

// NewKeyBuilder creates a new key builder for a queue with auto-detected Redis mode.
//
// The key format is automatically determined based on the Redis client type:
//   - redis.ClusterClient → uses hash tags: bull:{queue-name}:wait
//   - redis.Client → no hash tags: bull:queue-name:wait
//
// This ensures cross-language compatibility with Node.js EchoMQ while maintaining
// Redis Cluster support.
func NewKeyBuilder(queueName string, client interface{}) *KeyBuilder {
	return &KeyBuilder{
		queueName:   queueName,
		useHashTags: IsRedisCluster(client),
	}
}

// NewKeyBuilderWithHashTags creates a key builder with explicit hash tag control.
//
// Use this when you need to force hash tags on single-instance Redis (e.g., testing
// cluster behavior) or override auto-detection for special cases.
func NewKeyBuilderWithHashTags(queueName string, useHashTags bool) *KeyBuilder {
	return &KeyBuilder{
		queueName:   queueName,
		useHashTags: useHashTags,
	}
}

// Wait returns the key for the wait queue (FIFO, priority=0)
func (kb *KeyBuilder) Wait() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:wait", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:wait", kb.queueName)
}

// Prioritized returns the key for the prioritized queue (ZSET, priority>0)
func (kb *KeyBuilder) Prioritized() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:prioritized", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:prioritized", kb.queueName)
}

// Delayed returns the key for the delayed queue (ZSET, scheduled jobs)
func (kb *KeyBuilder) Delayed() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:delayed", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:delayed", kb.queueName)
}

// Active returns the key for the active jobs list
func (kb *KeyBuilder) Active() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:active", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:active", kb.queueName)
}

// Completed returns the key for the completed jobs sorted set
func (kb *KeyBuilder) Completed() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:completed", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:completed", kb.queueName)
}

// Failed returns the key for the failed jobs sorted set
func (kb *KeyBuilder) Failed() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:failed", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:failed", kb.queueName)
}

// Events returns the key for the events stream
func (kb *KeyBuilder) Events() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:events", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:events", kb.queueName)
}

// StreamFor returns the key for a pub/sub topic stream keyed off the supplied
// topic name (distinct from the BullMQ-reserved :events suffix used by Events).
// Hash-tag detection carried by the receiver is reused so cluster deployments
// inherit the {topic} slot-stability guarantee without extra plumbing.
//
// Cross-ref: FTR-008 architecture/topic-registry.md D-TR-2.
func (kb *KeyBuilder) StreamFor(topic string) string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:stream", topic)
	}
	return fmt.Sprintf("bull:%s:stream", topic)
}

// Meta returns the key for queue metadata (paused, rate limits)
func (kb *KeyBuilder) Meta() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:meta", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:meta", kb.queueName)
}

// Job returns the key for a specific job hash
func (kb *KeyBuilder) Job(jobID string) string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:%s", kb.queueName, jobID)
	}
	return fmt.Sprintf("bull:%s:%s", kb.queueName, jobID)
}

// Lock returns the key for a job's lock
func (kb *KeyBuilder) Lock(jobID string) string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:%s:lock", kb.queueName, jobID)
	}
	return fmt.Sprintf("bull:%s:%s:lock", kb.queueName, jobID)
}

// Logs returns the key for a job's logs list
func (kb *KeyBuilder) Logs(jobID string) string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:%s:logs", kb.queueName, jobID)
	}
	return fmt.Sprintf("bull:%s:%s:logs", kb.queueName, jobID)
}

// Stalled returns the key for the stalled jobs set (used by two-phase stalled detection)
func (kb *KeyBuilder) Stalled() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:stalled", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:stalled", kb.queueName)
}

// PriorityCounter returns the key for the per-queue priority counter
// Used to compute composite ZADD scores: priority * 0x100000000 + counter % 0x100000000
func (kb *KeyBuilder) PriorityCounter() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:pc", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:pc", kb.queueName)
}

// RateLimiter returns the key for the rate limiter counter
func (kb *KeyBuilder) RateLimiter() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:limiter", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:limiter", kb.queueName)
}

// Paused returns the key for the paused queue list
func (kb *KeyBuilder) Paused() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:paused", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:paused", kb.queueName)
}

// Marker returns the key for the queue marker (ZSET used for delayed/waiting signals)
func (kb *KeyBuilder) Marker() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:marker", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:marker", kb.queueName)
}

// Metrics returns the key for queue metrics (target is "completed" or "failed")
func (kb *KeyBuilder) Metrics(target string) string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:metrics:%s", kb.queueName, target)
	}
	return fmt.Sprintf("bull:%s:metrics:%s", kb.queueName, target)
}

// Prefix returns the key prefix for all keys in this queue
func (kb *KeyBuilder) Prefix() string {
	if kb.useHashTags {
		return fmt.Sprintf("bull:{%s}:", kb.queueName)
	}
	return fmt.Sprintf("bull:%s:", kb.queueName)
}
