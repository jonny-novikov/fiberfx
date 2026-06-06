package unit

import (
	"testing"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/stretchr/testify/assert"
)

// Unit tests for job validation (without Redis)

func TestQueue_ValidateJobOptions_NegativePriority(t *testing.T) {
	opts := echomq.JobOptions{
		Priority: -1,
		Attempts: 3,
		Backoff:  echomq.BackoffConfig{Type: "exponential", Delay: 1000},
	}

	err := echomq.ValidateJobOptions(opts)
	assert.Error(t, err)

	var validationErr *echomq.ValidationError
	assert.ErrorAs(t, err, &validationErr)
	assert.Equal(t, "priority", validationErr.Field)
}

func TestQueue_ValidateJobOptions_InvalidBackoffType(t *testing.T) {
	opts := echomq.JobOptions{
		Attempts: 3,
		Backoff:  echomq.BackoffConfig{Type: "invalid", Delay: 1000},
	}

	err := echomq.ValidateJobOptions(opts)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "backoff.type")
}

func TestQueue_ValidateJobPayloadSize_WithinLimit(t *testing.T) {
	job := &echomq.Job{
		ID:   "test-123",
		Name: "send-email",
		Data: map[string]interface{}{
			"to":      "user@example.com",
			"subject": "Test",
			"body":    "Hello!",
		},
		Opts: echomq.DefaultJobOptions,
	}

	err := echomq.ValidateJobPayloadSize(job)
	assert.NoError(t, err)
}

func TestQueue_ValidateJobPayloadSize_LargeButValid(t *testing.T) {
	// 1MB payload (well within 10MB limit)
	largeData := make([]byte, 1024*1024)
	for i := range largeData {
		largeData[i] = 'x'
	}

	job := &echomq.Job{
		ID:   "large-job",
		Name: "process-data",
		Data: map[string]interface{}{
			"payload": string(largeData),
		},
		Opts: echomq.DefaultJobOptions,
	}

	err := echomq.ValidateJobPayloadSize(job)
	assert.NoError(t, err)
}

func TestJobOptions_Defaults(t *testing.T) {
	defaults := echomq.DefaultJobOptions

	assert.Equal(t, 0, defaults.Priority)
	assert.Equal(t, time.Duration(0), defaults.Delay)
	assert.Equal(t, 3, defaults.Attempts)
	assert.Equal(t, "exponential", defaults.Backoff.Type)
	assert.Equal(t, int64(1000), defaults.Backoff.Delay)
	assert.False(t, defaults.RemoveOnComplete.ShouldRemove())
	assert.False(t, defaults.RemoveOnFail.ShouldRemove())
}
