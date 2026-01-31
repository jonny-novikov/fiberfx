package fiberfx

import (
	"sync"
	"time"
)

// Generator creates unique snowflake-based IDs.
// Thread-safe for concurrent use.
type Generator struct {
	mu       sync.Mutex
	workerID int64
	sequence int64
	lastTime int64
}

// NewGenerator creates a generator with the given worker ID (0-1023).
func NewGenerator(workerID int64) *Generator {
	if workerID < 0 || workerID > int64(MaxWorkerID) {
		workerID = workerID % int64(MaxWorkerID+1)
	}
	return &Generator{workerID: workerID}
}

// Generate creates a new snowflake ID.
func (g *Generator) Generate() int64 {
	g.mu.Lock()
	defer g.mu.Unlock()

	now := time.Now().UnixMilli() - Epoch

	if now == g.lastTime {
		g.sequence = (g.sequence + 1) & int64(MaxSequence)
		if g.sequence == 0 {
			// Sequence exhausted, wait for next millisecond
			for now <= g.lastTime {
				now = time.Now().UnixMilli() - Epoch
			}
		}
	} else {
		g.sequence = 0
	}

	g.lastTime = now

	return (now << TimestampShift) | (g.workerID << WorkerShift) | g.sequence
}

// New creates a branded ID with the given namespace.
func (g *Generator) New(ns Namespace) ID {
	return New(ns, g.Generate())
}

// WorkerID returns the generator's worker ID.
func (g *Generator) WorkerID() int64 { return g.workerID }

// Default generator (worker ID 0)
var defaultGen = NewGenerator(0)

// Generate creates a new branded ID using the default generator.
func Generate(ns Namespace) ID {
	return defaultGen.New(ns)
}

// SetDefaultWorkerID configures the default generator's worker ID.
// Should be called at startup before generating IDs.
func SetDefaultWorkerID(workerID int64) {
	defaultGen = NewGenerator(workerID)
}
