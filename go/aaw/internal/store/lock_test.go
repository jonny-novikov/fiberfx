package store

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/fiberfx/mcp-go/v2/mcp"
)

// MCP1-INV4 (the lock mechanism): a held workspace flock refuses a second
// acquire with INSTANCE_LOCKED naming the holder; release frees it.
func TestInstanceLockExcludesSecondAcquire(t *testing.T) {
	ws := t.TempDir()
	lk, err := AcquireInstanceLock(ws)
	if err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile(lk.Path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(b), lk.ID) || !strings.Contains(string(b), fmt.Sprintf("pid=%d", lk.PID)) {
		t.Fatalf("lock file does not name the holder: %q", b)
	}
	if _, err := AcquireInstanceLock(ws); err == nil || !strings.Contains(err.Error(), "INSTANCE_LOCKED") {
		t.Fatalf("second acquire not refused with INSTANCE_LOCKED: %v", err)
	} else if !strings.Contains(err.Error(), lk.ID) {
		t.Fatalf("refusal does not name the holder: %v", err)
	}
	if err := lk.Release(); err != nil {
		t.Fatal(err)
	}
	lk2, err := AcquireInstanceLock(ws)
	if err != nil {
		t.Fatalf("acquire after release: %v", err)
	}
	lk2.Release()
}

func freePort(t *testing.T) string {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	_, port, err := net.SplitHostPort(l.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	return port
}

func waitTCP(t *testing.T, addr string) {
	t.Helper()
	for i := 0; i < 50; i++ {
		c, err := net.DialTimeout("tcp", addr, 200*time.Millisecond)
		if err == nil {
			c.Close()
			return
		}
		time.Sleep(100 * time.Millisecond)
	}
	t.Fatalf("server at %s never came up", addr)
}

// MCP1-INV4 (two processes, hermetic): the second server process on the same
// temp workspace exits non-zero with INSTANCE_LOCKED; the first keeps serving.
func TestSecondServerProcessRefused(t *testing.T) {
	bin := filepath.Join(t.TempDir(), "aaw-under-test")
	moduleRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatal(err)
	}
	build := exec.Command("go", "build", "-o", bin, "./cmd/aaw")
	build.Dir = moduleRoot
	build.Env = append(os.Environ(), "GOWORK=off")
	if out, err := build.CombinedOutput(); err != nil {
		t.Fatalf("building the server under test: %v\n%s", err, out)
	}

	ws := t.TempDir()
	portA, portB := freePort(t), freePort(t)

	// Flags precede the mode: flag.Parse stops at the first non-flag arg, so
	// flags after "serve" would silently fall back to the defaults.
	first := exec.Command(bin, "-addr", "127.0.0.1:"+portA, "-workspace", ws, "serve")
	var firstLog bytes.Buffer
	first.Stdout, first.Stderr = &firstLog, &firstLog
	if err := first.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		first.Process.Kill()
		first.Wait()
	})
	waitTCP(t, "127.0.0.1:"+portA)

	second := exec.Command(bin, "-addr", "127.0.0.1:"+portB, "-workspace", ws, "serve")
	out, err := second.CombinedOutput()
	if err == nil {
		t.Fatalf("second instance booted; output:\n%s", out)
	}
	if !strings.Contains(string(out), "INSTANCE_LOCKED") {
		t.Fatalf("second instance refused without INSTANCE_LOCKED:\n%s", out)
	}

	// The first instance keeps serving: its endpoint still answers HTTP.
	resp, err := http.Get("http://127.0.0.1:" + portA + "/")
	if err != nil {
		t.Fatalf("first instance stopped serving after the refusal: %v\nlog:\n%s", err, firstLog.String())
	}
	resp.Body.Close()

	// The lock file names the live holder.
	b, err := os.ReadFile(filepath.Join(ws, ".aaw", "aaw.lock"))
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(b), fmt.Sprintf("pid=%d", first.Process.Pid)) {
		t.Fatalf("lock file does not name the first instance: %q", b)
	}

	// MCP1-US4 AC2: probe reports the holder instance id and pid — asserted
	// over the real wire against the running holder.
	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "store-harden-test", Version: "test"}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: "http://127.0.0.1:" + portA + "/"}, nil)
	if err != nil {
		t.Fatalf("mcp connect to the holder: %v", err)
	}
	res, err := session.CallTool(ctx, &mcp.CallToolParams{Name: "probe", Arguments: map[string]any{}})
	if err != nil {
		t.Fatalf("probe transport error: %v", err)
	}
	if res.IsError {
		t.Fatalf("probe IsError: %v", res.Content)
	}
	sc, err := json.Marshal(res.StructuredContent)
	if err != nil {
		t.Fatal(err)
	}
	var probe struct {
		InstanceID string `json:"instance_id"`
		PID        int    `json:"pid"`
	}
	if err := json.Unmarshal(sc, &probe); err != nil {
		t.Fatalf("probe structured content: %v (%s)", err, sc)
	}
	if probe.InstanceID == "" {
		t.Fatalf("probe reports no instance_id: %s", sc)
	}
	if probe.PID != first.Process.Pid {
		t.Fatalf("probe pid = %d, want the holder %d", probe.PID, first.Process.Pid)
	}
	session.Close(ctx)

	// The flock releases with the process: kill the holder, then a fresh
	// acquire succeeds (ADR-2's crashed-holder consequence).
	first.Process.Kill()
	first.Wait()
	lk, err := AcquireInstanceLock(ws)
	if err != nil {
		t.Fatalf("flock not released on process death: %v", err)
	}
	lk.Release()
}
