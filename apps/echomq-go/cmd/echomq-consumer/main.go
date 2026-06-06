// Command echomq-consumer is the Powerhouse-side standalone wire-only consumer
// for the FS-1 Phase 1 EchoMQ pipeline (FTR0N1TUwoc4DQ).
//
// It subscribes to the BullMQ-format queue named "cclin.events" on the internal
// Redis at redis://redis:6379 (Docker DNS / nano-net hostname; INV-3) and emits
// each consumed job as a single-line JSON record on stdout. Diagnostics route
// to stderr via log/slog so the event stream stays pipeline-clean.
//
// REDIS_URL environment variable overrides the default endpoint.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
)

// DefaultRedisURL is the nano-net internal Docker-DNS hostname endpoint.
// Per INV-3 the consumer connects via the internal bridge — NOT host.docker.internal,
// NOT localhost, NOT 127.0.0.1. LAN-direct is reserved for the cross-host Mac->Powerhouse
// producer hop (INV-4) and is not used here.
const DefaultRedisURL = "redis://redis:6379"

// QueueName is the cclin-server P1 spine — TraceIDMiddleware + echomq producer
// publish to this topic. The consumer subscribes here for wire validation.
const QueueName = "cclin.events"

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	rawURL := os.Getenv("REDIS_URL")
	resolvedURL, source, err := resolveRedisURL(rawURL, DefaultRedisURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "echomq-consumer: invalid REDIS_URL: %v\n", err)
		os.Exit(2)
	}

	if err := runConsumer(ctx, runOptions{
		RedisURL:  resolvedURL,
		URLSource: source,
		QueueName: QueueName,
	}, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "echomq-consumer: %v\n", err)
		os.Exit(1)
	}
}

type runOptions struct {
	RedisURL  string
	URLSource string
	QueueName string
}

func runConsumer(ctx context.Context, opts runOptions, stdout, stderr io.Writer) error {
	logger := slog.New(slog.NewJSONHandler(stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))

	redisOpts, err := redis.ParseURL(opts.RedisURL)
	if err != nil {
		return fmt.Errorf("parse %q: %w", opts.RedisURL, err)
	}

	logger.Info("consumer startup",
		"queue", opts.QueueName,
		"redis_addr", redisOpts.Addr,
		"redis_url_source", opts.URLSource,
	)

	client := redis.NewClient(redisOpts)
	defer func() {
		if cerr := client.Close(); cerr != nil {
			logger.Error("redis close failed", "err", cerr.Error())
		}
	}()

	pingCtx, pingCancel := context.WithTimeout(ctx, 5*time.Second)
	defer pingCancel()
	if perr := client.Ping(pingCtx).Err(); perr != nil {
		return fmt.Errorf("ping %s: %w", redisOpts.Addr, perr)
	}
	logger.Info("redis ping ok", "addr", redisOpts.Addr)

	worker := echomq.NewWorker(opts.QueueName, client, echomq.DefaultWorkerOptions)
	worker.Process(emitJobToStdout(stdout, logger))

	errCh := make(chan error, 1)
	go func() {
		errCh <- worker.Start(ctx)
	}()

	select {
	case <-ctx.Done():
		logger.Info("shutdown signal received; stopping worker")
		if serr := worker.Stop(); serr != nil {
			logger.Error("worker stop failed", "err", serr.Error())
		}
		<-errCh
		return nil
	case werr := <-errCh:
		if werr != nil {
			return fmt.Errorf("worker exited: %w", werr)
		}
		return nil
	}
}

func emitJobToStdout(stdout io.Writer, logger *slog.Logger) echomq.JobProcessor {
	enc := json.NewEncoder(stdout)
	return func(job *echomq.Job) (interface{}, error) {
		record := struct {
			Event        string                 `json:"event"`
			QueueName    string                 `json:"queue"`
			JobID        string                 `json:"job_id"`
			JobName      string                 `json:"job_name"`
			AttemptsMade int                    `json:"attempts_made"`
			Timestamp    int64                  `json:"timestamp_ms"`
			Data         map[string]interface{} `json:"data,omitempty"`
		}{
			Event:        "consumed",
			QueueName:    QueueName,
			JobID:        job.ID,
			JobName:      job.Name,
			AttemptsMade: job.AttemptsMade,
			Timestamp:    time.Now().UnixMilli(),
			Data:         job.Data,
		}

		if err := enc.Encode(&record); err != nil {
			logger.Error("emit job to stdout failed", "job_id", job.ID, "err", err.Error())
			return nil, fmt.Errorf("encode job %s: %w", job.ID, err)
		}
		return nil, nil
	}
}

// resolveRedisURL returns the URL the consumer will dial, the source label
// used for diagnostics ("env" or "default"), and a parse error if the env
// override is malformed. An empty env value falls back to the default.
func resolveRedisURL(envValue, defaultURL string) (string, string, error) {
	if envValue == "" {
		return defaultURL, "default", nil
	}
	if _, err := redis.ParseURL(envValue); err != nil {
		return "", "", err
	}
	return envValue, "env", nil
}
