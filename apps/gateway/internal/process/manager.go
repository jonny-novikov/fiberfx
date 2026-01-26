package process

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/fireheadz/codemoji-gateway/internal/config"
)

// splitCommand splits a command string into parts, handling quoted strings
func splitCommand(cmd string) []string {
	return strings.Fields(cmd)
}

// Manager manages child processes
type Manager struct {
	cfg     *config.Config
	cmd     *exec.Cmd
	mu      sync.Mutex
	running bool
	ready   chan struct{}
}

// NewManager creates a new process manager
func NewManager(cfg *config.Config) *Manager {
	return &Manager{
		cfg:   cfg,
		ready: make(chan struct{}),
	}
}

// Start starts the Outerbase Studio child process (Next.js standalone)
func (m *Manager) Start(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.running {
		return nil
	}

	// Parse the Studio command (e.g., "node .next/standalone/server.js")
	cmdParts := splitCommand(m.cfg.StudioCmd)
	if len(cmdParts) == 0 {
		return fmt.Errorf("STUDIO_CMD is empty")
	}

	// Command to run Studio
	m.cmd = exec.CommandContext(ctx, cmdParts[0], cmdParts[1:]...)

	// Set working directory for Next.js standalone
	m.cmd.Dir = m.cfg.StudioWorkDir

	// Inherit parent environment and set PORT for Next.js
	env := os.Environ()
	env = append(env, fmt.Sprintf("PORT=%d", m.cfg.StudioPort))
	env = append(env, "HOSTNAME=0.0.0.0") // Bind to all interfaces
	m.cmd.Env = env

	// Redirect output
	m.cmd.Stdout = os.Stdout
	m.cmd.Stderr = os.Stderr

	// Start process
	if err := m.cmd.Start(); err != nil {
		return fmt.Errorf("failed to start Studio: %w", err)
	}

	m.running = true

	slog.Info("Studio started",
		"pid", m.cmd.Process.Pid,
		"port", m.cfg.StudioPort,
		"workdir", m.cfg.StudioWorkDir,
		"cmd", strings.Join(m.cmd.Args, " "),
	)

	// Wait for process to be ready
	go m.waitForReady()

	// Monitor process
	go m.monitor()

	return nil
}

// waitForReady waits for the studio to become ready
func (m *Manager) waitForReady() {
	maxAttempts := 30
	for i := 0; i < maxAttempts; i++ {
		time.Sleep(500 * time.Millisecond)

		// Try to connect to the studio
		resp, err := healthCheck(fmt.Sprintf("http://127.0.0.1:%d", m.cfg.StudioPort))
		if err == nil && resp {
			slog.Info("Studio is ready", "port", m.cfg.StudioPort)
			close(m.ready)
			return
		}
	}

	slog.Warn("Studio did not become ready in time")
}

// healthCheck performs a simple HTTP health check
func healthCheck(url string) (bool, error) {
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()
	return resp.StatusCode < 500, nil
}

// Ready returns a channel that closes when the gateway is ready
func (m *Manager) Ready() <-chan struct{} {
	return m.ready
}

// IsReady returns true if the gateway is ready
func (m *Manager) IsReady() bool {
	select {
	case <-m.ready:
		return true
	default:
		return false
	}
}

// monitor watches the child process and restarts if needed
func (m *Manager) monitor() {
	if m.cmd == nil || m.cmd.Process == nil {
		return
	}

	state, err := m.cmd.Process.Wait()
	m.mu.Lock()
	m.running = false
	m.mu.Unlock()

	if err != nil {
		slog.Error("Studio process error", "error", err)
	} else {
		slog.Info("Studio process exited",
			"exit_code", state.ExitCode(),
			"success", state.Success(),
		)
	}
}

// Stop stops the child process gracefully
func (m *Manager) Stop() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.running || m.cmd == nil || m.cmd.Process == nil {
		return nil
	}

	slog.Info("Stopping Studio", "pid", m.cmd.Process.Pid)

	// Send SIGTERM first
	if err := m.cmd.Process.Signal(syscall.SIGTERM); err != nil {
		slog.Warn("Failed to send SIGTERM, trying SIGKILL", "error", err)
		return m.cmd.Process.Kill()
	}

	// Wait for graceful shutdown with timeout
	done := make(chan error, 1)
	go func() {
		_, err := m.cmd.Process.Wait()
		done <- err
	}()

	select {
	case <-done:
		slog.Info("Studio stopped gracefully")
	case <-time.After(10 * time.Second):
		slog.Warn("Timeout waiting for graceful shutdown, killing process")
		m.cmd.Process.Kill()
	}

	m.running = false
	return nil
}

// IsRunning returns true if the process is running
func (m *Manager) IsRunning() bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.running
}
