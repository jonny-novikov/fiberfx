//go:build compat_docker
// +build compat_docker

// Package integration — Docker-gated Node.js BullMQ compat test.
//
// File: nodejs_compat_docker_test.go
// Build tag: compat_docker (off by default).
// Run: `go test -tags compat_docker -run TestNodeJSCompatibility_Docker ./tests/integration/`
//
// This file requires:
//   - Docker available on PATH (`docker` and `docker compose` v2 syntax).
//   - Network egress to docker.io for redis:7-alpine + node:20-alpine pulls.
//   - The fixture under apps/echomq-go/tests/compatibility/nodejs/
//     (docker-compose.yml + producer.js + package.json).
//
// Why a separate build tag: Docker availability varies across CI matrices.
// The default-build nodejs_compat_test.go (same package) covers the
// wire-format invariant via Go-driven HSET/LPUSH simulation; this Docker
// variant adds the bonus end-to-end evidence with a real Node.js BullMQ
// producer/consumer in the loop.
//
// Coordination note: spec.yaml R-13 reserves apps/echomq-go/tests/compat/
// nodejs/ for the full P5 compat harness. This P2 variant uses
// tests/compatibility/nodejs/ (co-located with the existing package.json
// fixture) to avoid clashing with the R-13 path.
package integration

import (
	"context"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/echomq-go/pkg/echomq"
	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	// dockerComposeFixtureDir locates the docker-compose.yml + Node.js
	// producer fixture relative to the test binary's working directory
	// (`go test ./tests/integration/` runs in tests/integration).
	dockerComposeFixtureDir = "../compatibility/nodejs"

	// dockerComposeFile is the compose file inside dockerComposeFixtureDir.
	dockerComposeFile = "docker-compose.yml"

	// dockerNodeQueueName is hardcoded in producer.js — keep in sync.
	dockerNodeQueueName = "compat-docker-queue"

	// dockerRedisAddr is the host-mapped Redis port from the compose file.
	// Distinct from 6379 to avoid clashing with the default-build test's
	// localhost dev Redis.
	dockerRedisAddr = "localhost:6390"
)

// requireDockerOrSkip skips the test when docker or docker compose v2 is
// unavailable, or when the fixture directory is missing.
func requireDockerOrSkip(t *testing.T) {
	t.Helper()
	if _, err := exec.LookPath("docker"); err != nil {
		t.Skipf("docker not on PATH: %v — skipping Docker-gated Node.js compat test", err)
	}
	cmd := exec.Command("docker", "compose", "version")
	if err := cmd.Run(); err != nil {
		t.Skipf("docker compose v2 unavailable: %v — skipping Docker-gated Node.js compat test", err)
	}
	abs, err := filepath.Abs(dockerComposeFixtureDir)
	require.NoError(t, err)
	if _, err := exec.LookPath("test"); err == nil {
		// Lightweight existence check via stat-via-shell.
		check := exec.Command("test", "-d", abs)
		if err := check.Run(); err != nil {
			t.Skipf("fixture dir %s missing: %v — run `make test-compat-nodejs` to scaffold", abs, err)
		}
	}
}

// dockerComposeUp brings the Node.js + Redis stack up. Failure stops the
// test (fixture is required).
func dockerComposeUp(t *testing.T) {
	t.Helper()
	cmd := exec.Command("docker", "compose", "-f", dockerComposeFile, "up", "-d", "--build")
	cmd.Dir = dockerComposeFixtureDir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("docker compose up failed: %v\nOutput:\n%s", err, string(out))
	}
	t.Logf("docker compose up:\n%s", string(out))
}

// dockerComposeDown tears the stack down. Best-effort; logs on failure but
// does not fail the test (cleanup hygiene).
func dockerComposeDown(t *testing.T) {
	t.Helper()
	cmd := exec.Command("docker", "compose", "-f", dockerComposeFile, "down", "-v")
	cmd.Dir = dockerComposeFixtureDir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Logf("docker compose down warning: %v\nOutput:\n%s", err, string(out))
	}
}

// waitForRedis polls the host-mapped Redis port until PING succeeds or the
// context expires.
func waitForRedis(t *testing.T, ctx context.Context) *redis.Client {
	t.Helper()
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		client := redis.NewClient(&redis.Options{
			Addr:        dockerRedisAddr,
			DialTimeout: 1 * time.Second,
		})
		pingCtx, cancel := context.WithTimeout(ctx, 1*time.Second)
		err := client.Ping(pingCtx).Err()
		cancel()
		if err == nil {
			return client
		}
		_ = client.Close()
		time.Sleep(500 * time.Millisecond)
	}
	t.Fatalf("Redis at %s did not become ready within 30 s", dockerRedisAddr)
	return nil
}

// runNodeProducer invokes the Node.js producer in a one-shot container that
// shares the compose network. Returns stdout + stderr for log inspection.
func runNodeProducer(t *testing.T) string {
	t.Helper()
	cmd := exec.Command("docker", "compose", "-f", dockerComposeFile, "run", "--rm", "node-producer")
	cmd.Dir = dockerComposeFixtureDir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("node producer failed: %v\nOutput:\n%s", err, string(out))
	}
	return string(out)
}

// TestNodeJSCompatibility_Docker_NodeProducesGoConsumes is the full
// end-to-end variant of the R-1 integration test. It boots a real Node.js
// BullMQ producer in a Docker container, waits for it to enqueue a job, and
// asserts the Go worker (running in this test process) processes it.
func TestNodeJSCompatibility_Docker_NodeProducesGoConsumes(t *testing.T) {
	requireDockerOrSkip(t)

	dockerComposeUp(t)
	t.Cleanup(func() { dockerComposeDown(t) })

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	client := waitForRedis(t, ctx)
	t.Cleanup(func() { _ = client.Close() })

	producerLog := runNodeProducer(t)
	t.Logf("Node.js producer output:\n%s", producerLog)
	require.True(t, strings.Contains(producerLog, "PRODUCED_JOB_ID="),
		"node producer must print PRODUCED_JOB_ID=<id> on success")

	// Now run a Go worker against the same Redis instance and queue.
	worker := echomq.NewWorker(dockerNodeQueueName, client, echomq.WorkerOptions{
		Concurrency:          1,
		LockDuration:         5 * time.Second,
		HeartbeatInterval:    1 * time.Second,
		StalledCheckInterval: 30 * time.Second,
		MaxAttempts:          1,
	})

	processed := make(chan *echomq.Job, 1)
	worker.Process(func(job *echomq.Job) (interface{}, error) {
		select {
		case processed <- job:
		default:
		}
		return map[string]interface{}{"status": "ok"}, nil
	})

	workerCtx, workerCancel := context.WithCancel(ctx)
	defer workerCancel()
	go func() { _ = worker.Start(workerCtx) }()
	t.Cleanup(func() { _ = worker.Stop() })

	select {
	case job := <-processed:
		require.NotNil(t, job)
		assert.NotEmpty(t, job.ID, "Go worker received job from Node.js producer")
		assert.NotEmpty(t, job.Name)
		assert.Contains(t, producerLog, fmt.Sprintf("PRODUCED_JOB_ID=%s", job.ID),
			"Go-consumed job ID must equal what Node.js logged")
	case <-ctx.Done():
		t.Fatalf("Go worker did not consume Node.js-produced job within deadline; ctx err: %v", ctx.Err())
	}
}

// TestNodeJSCompatibility_Docker_GoProducesNodeConsumes is the inverse leg
// using the Node.js BullMQ Worker as the consumer. The Node.js consumer
// container is brought up, then Go writes a job, then the test asserts the
// Node.js consumer logged a successful processing.
//
// This variant requires a longer-running Node.js consumer container (rather
// than the one-shot producer pattern). Implementation is staged for the R-13
// full harness — for P2 R-1, the Go-produces-Node-readable wire-format
// assertion in nodejs_compat_test.go's TestNodeJSCompatibility_SingleInstance_GoProducesNodeReadable
// covers the inverse direction without needing a live Node.js consumer.
//
// Skipping under -tags compat_docker keeps the build green; an explicit
// run flag is required to opt in.
func TestNodeJSCompatibility_Docker_GoProducesNodeConsumes(t *testing.T) {
	t.Skip("Reserved for R-13 full Node.js consumer container — see nodejs_compat_test.go " +
		"GoProducesNodeReadable for the wire-format assertion that covers this direction at P2.")
}
