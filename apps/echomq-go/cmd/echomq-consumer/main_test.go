package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestResolveRedisURL(t *testing.T) {
	cases := []struct {
		name        string
		env         string
		want        string
		wantSource  string
		wantErr     bool
		errContains string
	}{
		{
			name:       "empty env falls back to nano-net default (R-3 + INV-3)",
			env:        "",
			want:       DefaultRedisURL,
			wantSource: "default",
		},
		{
			name:       "valid override is honored verbatim (R-3 override path)",
			env:        "redis://:secret@powerhouse:6379/0",
			want:       "redis://:secret@powerhouse:6379/0",
			wantSource: "env",
		},
		{
			name:       "rediss scheme accepted",
			env:        "rediss://example.com:6380/2",
			want:       "rediss://example.com:6380/2",
			wantSource: "env",
		},
		{
			name:        "malformed URL surfaces parse error",
			env:         "not-a-redis-url",
			wantErr:     true,
			errContains: "invalid URL",
		},
		{
			name:        "wrong scheme rejected",
			env:         "http://example.com:6379",
			wantErr:     true,
			errContains: "scheme",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, source, err := resolveRedisURL(tc.env, DefaultRedisURL)

			if tc.wantErr {
				if err == nil {
					t.Fatalf("resolveRedisURL(%q): want error containing %q, got nil", tc.env, tc.errContains)
				}
				if tc.errContains != "" && !strings.Contains(err.Error(), tc.errContains) {
					t.Fatalf("resolveRedisURL(%q): want error containing %q, got %q", tc.env, tc.errContains, err.Error())
				}
				return
			}

			if err != nil {
				t.Fatalf("resolveRedisURL(%q): unexpected error: %v", tc.env, err)
			}
			if got != tc.want {
				t.Fatalf("resolveRedisURL(%q) URL: got %q, want %q", tc.env, got, tc.want)
			}
			if source != tc.wantSource {
				t.Fatalf("resolveRedisURL(%q) source: got %q, want %q", tc.env, source, tc.wantSource)
			}
		})
	}
}

func TestDefaultRedisURLIsNanoNetHostname(t *testing.T) {
	const want = "redis://redis:6379"
	if DefaultRedisURL != want {
		t.Fatalf("DefaultRedisURL = %q, want %q (INV-3 nano-net hostname)", DefaultRedisURL, want)
	}

	forbidden := []string{"host.docker.internal", "localhost", "127.0.0.1"}
	for _, f := range forbidden {
		if strings.Contains(DefaultRedisURL, f) {
			t.Fatalf("DefaultRedisURL %q contains forbidden host %q (INV-3 violation)", DefaultRedisURL, f)
		}
	}
}

func TestQueueNameMatchesP1Spine(t *testing.T) {
	const want = "cclin.events"
	if QueueName != want {
		t.Fatalf("QueueName = %q, want %q (cclin-server P1 spine)", QueueName, want)
	}
}

func TestRunConsumerInvalidURLReturnsError(t *testing.T) {
	var stdout, stderr bytes.Buffer
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	err := runConsumer(ctx, runOptions{
		RedisURL:  "not-a-redis-url",
		URLSource: "env",
		QueueName: QueueName,
	}, &stdout, &stderr)

	if err == nil {
		t.Fatal("runConsumer with invalid URL: want error, got nil")
	}
	if !strings.Contains(err.Error(), "parse") {
		t.Fatalf("runConsumer error: want %q context, got %q", "parse", err.Error())
	}
}

func TestRunConsumerUnreachableRedisReturnsPingError(t *testing.T) {
	var stdout, stderr bytes.Buffer
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	err := runConsumer(ctx, runOptions{
		RedisURL:  "redis://127.0.0.1:1/0",
		URLSource: "env",
		QueueName: QueueName,
	}, &stdout, &stderr)

	if err == nil {
		t.Fatal("runConsumer with unreachable redis: want error, got nil")
	}
	if !strings.Contains(err.Error(), "ping") {
		t.Fatalf("runConsumer error: want %q context, got %q", "ping", err.Error())
	}
}

func TestRunConsumerCanceledContextBeforeStartReturnsCleanly(t *testing.T) {
	var stdout, stderr bytes.Buffer
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	err := runConsumer(ctx, runOptions{
		RedisURL:  "redis://127.0.0.1:1/0",
		URLSource: "env",
		QueueName: QueueName,
	}, &stdout, &stderr)

	if err == nil {
		t.Fatal("runConsumer with pre-canceled ctx and unreachable redis: want non-nil error")
	}
	if errors.Is(err, context.Canceled) {
		return
	}
	if !strings.Contains(err.Error(), "ping") && !strings.Contains(err.Error(), "context") {
		t.Fatalf("runConsumer error: want ping or context error, got %q", err.Error())
	}
}

func TestEmitJobToStdout(t *testing.T) {
	cases := []struct {
		name string
		job  *echomq.Job
	}{
		{
			name: "job with data",
			job: &echomq.Job{
				ID:           "1",
				Name:         "cclin.event.tool_call",
				AttemptsMade: 0,
				Data:         map[string]interface{}{"trace_id": "abc123"},
			},
		},
		{
			name: "job without data",
			job: &echomq.Job{
				ID:           "2",
				Name:         "cclin.event.heartbeat",
				AttemptsMade: 1,
				Data:         nil,
			},
		},
		{
			name: "job with multi-attempt retry",
			job: &echomq.Job{
				ID:           "3",
				Name:         "cclin.event.tool_call",
				AttemptsMade: 3,
				Data:         map[string]interface{}{"k": "v"},
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var stdout, stderr bytes.Buffer
			logger := slog.New(slog.NewJSONHandler(&stderr, nil))
			processor := emitJobToStdout(&stdout, logger)

			ret, err := processor(tc.job)
			if err != nil {
				t.Fatalf("processor returned error: %v", err)
			}
			if ret != nil {
				t.Fatalf("processor return value: got %v, want nil", ret)
			}

			line := stdout.String()
			if !strings.HasSuffix(line, "\n") {
				t.Fatalf("emitted line must end in newline (NDJSON), got %q", line)
			}

			var decoded map[string]interface{}
			if err := json.Unmarshal([]byte(strings.TrimSpace(line)), &decoded); err != nil {
				t.Fatalf("emitted line not valid JSON: %v (line=%q)", err, line)
			}

			for _, key := range []string{"event", "queue", "job_id", "job_name", "attempts_made", "timestamp_ms"} {
				if _, ok := decoded[key]; !ok {
					t.Fatalf("emitted record missing required key %q: %s", key, line)
				}
			}

			if decoded["event"] != "consumed" {
				t.Fatalf("event field: got %v, want %q", decoded["event"], "consumed")
			}
			if decoded["queue"] != QueueName {
				t.Fatalf("queue field: got %v, want %q", decoded["queue"], QueueName)
			}
			if decoded["job_id"] != tc.job.ID {
				t.Fatalf("job_id field: got %v, want %q", decoded["job_id"], tc.job.ID)
			}
			if decoded["job_name"] != tc.job.Name {
				t.Fatalf("job_name field: got %v, want %q", decoded["job_name"], tc.job.Name)
			}
			if int(decoded["attempts_made"].(float64)) != tc.job.AttemptsMade {
				t.Fatalf("attempts_made field: got %v, want %d", decoded["attempts_made"], tc.job.AttemptsMade)
			}
			if ts, ok := decoded["timestamp_ms"].(float64); !ok || ts <= 0 {
				t.Fatalf("timestamp_ms field: got %v, want positive int64-as-float", decoded["timestamp_ms"])
			}
		})
	}
}
