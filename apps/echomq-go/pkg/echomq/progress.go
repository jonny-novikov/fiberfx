package echomq

import (
	"context"
	"fmt"

	"github.com/fiberfx/echomq-go/pkg/echomq/scripts"
	"github.com/redis/go-redis/v9"
)

// ProgressUpdater handles atomic progress updates using Lua scripts
type ProgressUpdater struct {
	queueName    string
	redisClient  redis.Cmdable
	keyBuilder   *KeyBuilder
	scriptLoader *scripts.ScriptLoader
}

// NewProgressUpdater creates a new progress updater with auto-detected key formatting.
// For explicit ForceHashTags propagation, use NewProgressUpdaterWithKeyBuilder.
func NewProgressUpdater(queueName string, redisClient redis.Cmdable) *ProgressUpdater {
	return NewProgressUpdaterWithKeyBuilder(queueName, redisClient, NewKeyBuilder(queueName, redisClient))
}

// NewProgressUpdaterWithKeyBuilder creates a progress updater that reuses a pre-built KeyBuilder.
func NewProgressUpdaterWithKeyBuilder(queueName string, redisClient redis.Cmdable, kb *KeyBuilder) *ProgressUpdater {
	scriptLoader := scripts.NewScriptLoader(redisClient)
	scriptLoader.LoadAll()

	return &ProgressUpdater{
		queueName:    queueName,
		redisClient:  redisClient,
		keyBuilder:   kb,
		scriptLoader: scriptLoader,
	}
}

// UpdateProgress atomically updates job progress and emits progress event
// Uses updateProgress Lua script for atomicity
//
// Returns:
//   - 0: Success
//   - -1: Job not found
func (p *ProgressUpdater) UpdateProgress(ctx context.Context, jobID string, progress int) (int64, error) {
	if progress < 0 || progress > 100 {
		return 0, &ValidationError{
			Field:   "progress",
			Message: fmt.Sprintf("must be between 0 and 100, got %d", progress),
		}
	}

	kb := p.keyBuilder

	// KEYS
	keys := []string{
		kb.Job(jobID),    // KEYS[1]: Job hash key
		kb.Events(),      // KEYS[2]: Event stream key
		kb.Meta(),        // KEYS[3]: Meta key (for maxEvents)
	}

	// ARGV
	args := []interface{}{
		jobID,    // ARGV[1]: Job ID
		progress, // ARGV[2]: Progress value (0-100)
	}

	// Execute Lua script
	result, err := p.scriptLoader.Run(ctx, scripts.ScriptUpdateProgress, keys, args...).Result()
	if err != nil {
		return 0, fmt.Errorf("updateProgress script failed: %w", err)
	}

	// Parse result
	resultCode, ok := result.(int64)
	if !ok {
		return 0, fmt.Errorf("unexpected result type from updateProgress: %T", result)
	}

	if resultCode == -1 {
		return -1, fmt.Errorf("job not found: %s", jobID)
	}

	return resultCode, nil
}
