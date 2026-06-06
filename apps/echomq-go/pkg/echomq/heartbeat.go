package echomq

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq/scripts"
	"github.com/redis/go-redis/v9"
)

// HeartbeatManager manages lock extensions for active jobs
type HeartbeatManager struct {
	worker       *Worker
	activeLocks  map[string]context.CancelFunc
	mu           sync.RWMutex
	stopChan     chan struct{}
	failureCount uint64
}

// NewHeartbeatManager creates a new heartbeat manager
func NewHeartbeatManager(worker *Worker) *HeartbeatManager {
	return &HeartbeatManager{
		worker:      worker,
		activeLocks: make(map[string]context.CancelFunc),
		stopChan:    make(chan struct{}),
	}
}

// StartHeartbeat starts heartbeat for a specific job
func (hm *HeartbeatManager) StartHeartbeat(ctx context.Context, jobID string, lockToken LockToken) {
	hm.mu.Lock()
	defer hm.mu.Unlock()

	// Cancel existing heartbeat if any
	if cancel, exists := hm.activeLocks[jobID]; exists {
		cancel()
	}

	// Create cancellable context for this job's heartbeat
	heartbeatCtx, cancel := context.WithCancel(ctx)
	hm.activeLocks[jobID] = cancel

	// Start heartbeat loop
	go hm.heartbeatLoop(heartbeatCtx, jobID, lockToken)
}

// StopHeartbeat stops heartbeat for a specific job
func (hm *HeartbeatManager) StopHeartbeat(jobID string) {
	hm.mu.Lock()
	defer hm.mu.Unlock()

	if cancel, exists := hm.activeLocks[jobID]; exists {
		cancel()
		delete(hm.activeLocks, jobID)
	}
}

// heartbeatLoop extends lock periodically using the official ExtendLock Lua script
func (hm *HeartbeatManager) heartbeatLoop(ctx context.Context, jobID string, lockToken LockToken) {
	ticker := time.NewTicker(hm.worker.opts.HeartbeatInterval)
	defer ticker.Stop()
	defer hm.StopHeartbeat(jobID)

	kb := hm.worker.keyBuilder
	lockKey := kb.Lock(jobID)
	stalledKey := kb.Stalled()
	lockDurationMs := hm.worker.opts.LockDuration.Milliseconds()

	// Load the official ExtendLock script (EVALSHA with fallback to EVAL)
	extendLockScript := redis.NewScript(scripts.ExtendLock)

	for {
		select {
		case <-ctx.Done():
			return
		case <-hm.stopChan:
			return
		case <-ticker.C:
			// Official ExtendLock script:
			//   KEYS[1] = lock key, KEYS[2] = stalled set
			//   ARGV[1] = token, ARGV[2] = lock duration (ms), ARGV[3] = jobId
			//   Returns 1 = success, 0 = lock was stolen
			result, err := extendLockScript.Run(ctx, hm.worker.redisClient,
				[]string{lockKey, stalledKey},
				lockToken.String(),
				lockDurationMs,
				jobID,
			).Int64()

			if err != nil {
				hm.failureCount++
				fmt.Printf("[echomq-go] WARN: heartbeat extend failed for job %s: %v\n", jobID, err)
				continue
			}
			if result == 0 {
				// Lock was stolen by another worker — stop heartbeat
				hm.failureCount++
				fmt.Printf("[echomq-go] WARN: lock stolen for job %s, stopping heartbeat\n", jobID)
				return
			}
		}
	}
}

// Stop stops all heartbeats
func (hm *HeartbeatManager) Stop() {
	close(hm.stopChan)

	hm.mu.Lock()
	defer hm.mu.Unlock()

	// Cancel all active heartbeats
	for _, cancel := range hm.activeLocks {
		cancel()
	}
	hm.activeLocks = make(map[string]context.CancelFunc)
}

// GetFailureCount returns total heartbeat failures
func (hm *HeartbeatManager) GetFailureCount() uint64 {
	return hm.failureCount
}
