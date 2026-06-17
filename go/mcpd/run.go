package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
)

// runningProc pairs a started server with its child handle, for supervision.
type runningProc struct {
	srv Server
	cmd *exec.Cmd
}

// --- top-level command runners (wired in main.go) ---------------------------

func runStart(detach bool) error {
	root, err := prepare()
	if err != nil {
		return err
	}
	unlock, err := acquireOrchestratorLock(root)
	if err != nil {
		return err
	}
	procs, startErr := doStart(root, detach)
	unlock()
	if startErr != nil {
		return startErr
	}
	return finish(procs, root, detach, "started")
}

func runRestart(detach bool) error {
	root, err := prepare()
	if err != nil {
		return err
	}
	unlock, err := acquireOrchestratorLock(root)
	if err != nil {
		return err
	}
	procs, rErr := doRestart(root, detach)
	unlock()
	if rErr != nil {
		return rErr
	}
	return finish(procs, root, detach, "rebuilt + restarted")
}

func runStop() error {
	root, err := prepare()
	if err != nil {
		return err
	}
	unlock, err := acquireOrchestratorLock(root)
	if err != nil {
		return err
	}
	defer unlock()
	any := false
	for _, s := range servers(root) {
		stopped, err := stopServer(s, root, stopGrace)
		switch {
		case err != nil:
			fmt.Printf("✗ %s: %v\n", s.Name, err)
		case stopped:
			fmt.Printf("✓ %s stopped\n", s.Name)
			any = true
		default:
			fmt.Printf("• %s was not running\n", s.Name)
		}
	}
	if !any {
		fmt.Println("(nothing was running)")
	}
	return nil
}

func runStatus() error {
	root, err := resolveRoot(rootFlagRepo)
	if err != nil {
		return err
	}
	fmt.Printf("%-6s %-6s %-8s %-10s %s\n", "SERVER", "PORT", "PID", "STATE", "URL")
	for _, s := range servers(root) {
		pid, ok := readPid(s, root)
		live := ok && processAlive(pid)
		listening := portListening(s.Port, 300*time.Millisecond)
		pidStr := "-"
		if live {
			pidStr = fmt.Sprint(pid)
		}
		fmt.Printf("%-6s %-6d %-8s %-10s http://localhost:%d/\n",
			s.Name, s.Port, pidStr, stateWord(live, listening), s.Port)
	}
	return nil
}

// stateWord renders the four observable states from (pid-alive, port-listening).
func stateWord(live, listening bool) string {
	switch {
	case live && listening:
		return "running"
	case live && !listening:
		return "starting"
	case !live && listening:
		return "foreign"
	default:
		return "stopped"
	}
}

// --- the locked mutating sections -------------------------------------------

func doStart(root string, detach bool) ([]runningProc, error) {
	var procs []runningProc
	for _, s := range servers(root) {
		if isRunning(s, root) {
			if !detach {
				return procs, fmt.Errorf("%s already running on :%d — `mcpd restart` or `mcpd stop` first", s.Name, s.Port)
			}
			fmt.Printf("• %s already running (pid %d)\n", s.Name, mustPid(s, root))
			continue
		}
		fmt.Printf("→ %s: build if needed…\n", s.Name)
		if err := ensureBuilt(s, root); err != nil {
			return procs, err
		}
		if err := waitStartable(s); err != nil {
			return procs, err
		}
		fmt.Printf("→ %s: starting on :%d…\n", s.Name, s.Port)
		cmd, err := startOne(s, root, detach)
		if err != nil {
			return procs, err
		}
		procs = append(procs, runningProc{srv: s, cmd: cmd})
		fmt.Printf("✓ %s up — http://localhost:%d/ (pid %d, log bin/%s.log)\n", s.Name, s.Port, cmd.Process.Pid, s.Name)
	}
	return procs, nil
}

func doRestart(root string, detach bool) ([]runningProc, error) {
	var procs []runningProc
	for _, s := range servers(root) {
		fmt.Printf("→ %s: build → swap → restart…\n", s.Name)
		cmd, err := restartServer(s, root, detach)
		if err != nil {
			return procs, err
		}
		procs = append(procs, runningProc{srv: s, cmd: cmd})
		fmt.Printf("✓ %s up — http://localhost:%d/ (pid %d, log bin/%s.log)\n", s.Name, s.Port, cmd.Process.Pid, s.Name)
	}
	return procs, nil
}

// finish either reports the detached servers and returns, or — in foreground
// mode — blocks supervising the children until Ctrl-C or a child dies.
func finish(procs []runningProc, root string, detach bool, what string) error {
	if detach {
		fmt.Printf("✓ servers %s (detached). `mcpd status` to check · `mcpd stop` to stop.\n", what)
		return nil
	}
	if len(procs) == 0 {
		return nil
	}
	fmt.Println("▶ supervising in the foreground — Ctrl-C stops both.")
	supervise(procs, root)
	return nil
}

// --- foreground supervisor ---------------------------------------------------

// supervise blocks until the user interrupts (SIGINT/SIGTERM) or any child dies,
// then tears everything down: forward SIGTERM to all, wait stopGrace, SIGKILL
// stragglers, remove pidfiles. Children are in their own process groups, so the
// tty's Ctrl-C does NOT reach them — we deliver the stop signal exactly once
// here, with no double-signalling.
func supervise(procs []runningProc, root string) {
	sigc := make(chan os.Signal, 1)
	signal.Notify(sigc, syscall.SIGINT, syscall.SIGTERM)
	defer signal.Stop(sigc)

	exited := make(chan Server, len(procs))
	for _, p := range procs {
		go func(p runningProc) {
			_ = p.cmd.Wait()
			exited <- p.srv
		}(p)
	}

	select {
	case sig := <-sigc:
		fmt.Printf("\n→ %v received — stopping both servers…\n", sig)
	case srv := <-exited:
		fmt.Printf("\n✗ %s exited on its own — tearing down the other…\n", srv.Name)
	}

	deadline := time.Now().Add(stopGrace)
	for _, p := range procs {
		_ = p.cmd.Process.Signal(syscall.SIGTERM)
	}
	for _, p := range procs {
		pid := p.cmd.Process.Pid
		for processAlive(pid) && time.Now().Before(deadline) {
			time.Sleep(100 * time.Millisecond)
		}
		if processAlive(pid) {
			_ = p.cmd.Process.Signal(syscall.SIGKILL)
		}
		os.Remove(p.srv.pidPath(root))
	}
	fmt.Println("✓ stopped.")
}

// --- shared prep: root resolution, .mcp.json check, bin/ dir, orchestrator lock

// prepare resolves the repo root and guarantees the preconditions every mutating
// command needs: a .mcp.json (aaw's strict wire-check reads it) and a bin/ dir.
func prepare() (string, error) {
	root, err := resolveRoot(rootFlagRepo)
	if err != nil {
		return "", err
	}
	if _, err := os.Stat(filepath.Join(root, ".mcp.json")); err != nil {
		return "", fmt.Errorf("no .mcp.json at repo root %s — aaw's strict wire-check requires it", root)
	}
	if err := os.MkdirAll(binDir(root), 0o755); err != nil {
		return "", err
	}
	return root, nil
}

// acquireOrchestratorLock serialises mutating operations so two mcpd invocations
// (e.g. `make mcp` while the TUI is open) can't race on the same build/swap. It
// is held only for the mutating section, never during foreground supervision —
// so `mcpd stop` from another terminal still works while a supervisor runs.
func acquireOrchestratorLock(root string) (func(), error) {
	path := filepath.Join(binDir(root), ".mcpd.lock")
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		f.Close()
		return nil, fmt.Errorf("another mcpd operation is in progress (%s held)", path)
	}
	return func() {
		_ = syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
		f.Close()
	}, nil
}
