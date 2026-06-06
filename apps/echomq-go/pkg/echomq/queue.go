package echomq

import (
	"github.com/fiberfx/echomq-go/pkg/echomq/scripts"
	"github.com/redis/go-redis/v9"
)

// Queue manages job submission and queue operations
type Queue struct {
	name         string
	redisClient  redis.Cmdable
	keyBuilder   *KeyBuilder
	scripts      *scripts.ScriptLoader
	eventEmitter *EventEmitter
}

// QueueOptions configures queue construction.
//
// All fields are optional; zero values preserve the pre-R-4 default behavior.
type QueueOptions struct {
	// ForceHashTags overrides Redis-Cluster auto-detection for key formatting.
	//
	//   nil    -> auto-detect (redis.ClusterClient -> on; redis.Client -> off) [DEFAULT]
	//   &true  -> always emit bull:{queue}:... keys (hash-tagged)
	//   &false -> always emit bull:queue:... keys (flat)
	//
	// Use &true for cross-cluster parity testing on single-instance Redis, or &false when
	// connecting a cluster client to an environment that expects flat keys (rare).
	ForceHashTags *bool
}

// JobCounts represents queue statistics
type JobCounts struct {
	Waiting     int64
	Active      int64
	Completed   int64
	Failed      int64
	Delayed     int64
	Prioritized int64
}

// NewQueue creates a new queue instance with default options.
// Accepts both *redis.Client and *redis.ClusterClient via redis.Cmdable interface.
// Key format is auto-detected from the client type.
func NewQueue(name string, redisClient redis.Cmdable) *Queue {
	return NewQueueWithOptions(name, redisClient, QueueOptions{})
}

// NewQueueWithOptions creates a new queue instance with explicit options.
// See QueueOptions for field semantics.
func NewQueueWithOptions(name string, redisClient redis.Cmdable, opts QueueOptions) *Queue {
	scriptLoader := scripts.NewScriptLoader(redisClient)
	scriptLoader.LoadAll()

	var kb *KeyBuilder
	if opts.ForceHashTags != nil {
		kb = NewKeyBuilderWithHashTags(name, *opts.ForceHashTags)
	} else {
		kb = NewKeyBuilder(name, redisClient)
	}

	return &Queue{
		name:         name,
		redisClient:  redisClient,
		keyBuilder:   kb,
		scripts:      scriptLoader,
		eventEmitter: NewEventEmitterWithKeyBuilder(name, redisClient, 10000, kb),
	}
}

// KeyBuilder returns the Queue's KeyBuilder. Exposed for subsystems that need to share the
// Queue's hash-tag policy without re-deriving it.
func (q *Queue) KeyBuilder() *KeyBuilder {
	return q.keyBuilder
}
