package main

import (
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// stopGrace bounds how long we wait for a graceful SIGTERM exit before SIGKILL.
// It must exceed msh's 5s shutdown drain (go/msh/cmd/main.go); aaw has no
// handler and dies immediately, so this only ever bites msh.
const stopGrace = 9 * time.Second

// --- building (safe hot-swap: build to temp, atomic rename on success) -------

// buildSwap compiles the server to a temp path and, only on success, atomically
// renames it over the live binary. A FAILED build leaves the running server
// completely untouched — this is the core safety property of the hot-swap: a
// broken tree never takes down a healthy server. Rename-over-a-running-binary is
// safe on Unix (the live process keeps its open inode; the new dirent is used by
// the next exec). All builds force GOWORK=off so each server compiles hermetically
// from its own go.mod — independent of go/go.work (which spans aaw/msh/mcpd/mcp-go
// for interactive dev) and reproducible regardless of workspace state.
func buildSwap(s Server, root string) error {
	tmp := s.tmpBuildPath(root)
	cmd := exec.Command("go", "build", "-o", tmp, s.BuildPkg)
	cmd.Dir = s.AppDir
	cmd.Env = append(os.Environ(), "GOWORK=off")
	if out, err := cmd.CombinedOutput(); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("build %s failed (server left untouched):\n%s", s.Name, strings.TrimSpace(string(out)))
	}
	if err := os.Rename(tmp, s.binPath(root)); err != nil {
		os.Remove(tmp)
		return fmt.Errorf("swap %s binary into place: %w", s.Name, err)
	}
	return nil
}

// ensureBuilt builds only if the binary is missing (used by `start`; `restart`
// always buildSwaps for a fresh hot-swap).
func ensureBuilt(s Server, root string) error {
	if _, err := os.Stat(s.binPath(root)); err == nil {
		return nil
	}
	return buildSwap(s, root)
}

// --- launching ---------------------------------------------------------------

// spawn starts the server's foreground `serve` as a child process and records
// its pid. detach ⇒ Setsid (its own session, outlives mcpd) with output to the
// log file only. Foreground ⇒ Setpgid (its own process group so a terminal
// Ctrl-C does not signal it directly — the supervisor forwards exactly once)
// with output tee'd to both the terminal and the log file.
func spawn(s Server, root string, detach bool) (*exec.Cmd, error) {
	logf, err := os.OpenFile(s.logPath(root), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return nil, fmt.Errorf("open %s log: %w", s.Name, err)
	}
	cmd := exec.Command(s.binPath(root), s.ServeArgs...)
	cmd.Dir = s.WorkDir
	cmd.Env = os.Environ()
	if detach {
		cmd.Stdout, cmd.Stderr = logf, logf
		cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	} else {
		w := io.MultiWriter(os.Stdout, logf)
		cmd.Stdout, cmd.Stderr = w, w
		cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	}
	if err := cmd.Start(); err != nil {
		logf.Close()
		return nil, fmt.Errorf("start %s: %w", s.Name, err)
	}
	if detach {
		logf.Close() // the child holds its own dup'd fd now
	}
	if err := writePid(s, root, cmd.Process.Pid); err != nil {
		return cmd, fmt.Errorf("write %s pidfile: %w", s.Name, err)
	}
	return cmd, nil
}

// startOne spawns the server and waits until it is actually listening (or fails
// fast if it dies during startup — e.g. a wire mismatch or a busy port).
func startOne(s Server, root string, detach bool) (*exec.Cmd, error) {
	cmd, err := spawn(s, root, detach)
	if err != nil {
		return nil, err
	}
	if err := awaitListening(s, cmd, 12*time.Second); err != nil {
		return cmd, err
	}
	return cmd, nil
}

// awaitListening polls until the server accepts a TCP connection on its port, or
// the child exits, or the timeout elapses. A TCP connect is the cheapest honest
// "it's up" probe — neither server returns 200 to a bare GET (msh answers 400),
// so an HTTP status check would be misleading here.
func awaitListening(s Server, cmd *exec.Cmd, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for {
		if portListening(s.Port, 300*time.Millisecond) {
			return nil
		}
		if cmd != nil && cmd.Process != nil && !processAlive(cmd.Process.Pid) {
			return fmt.Errorf("%s exited during startup — check bin/%s.log", s.Name, s.Name)
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("%s did not start listening on :%d within %s — check bin/%s.log", s.Name, s.Port, timeout, s.Name)
		}
		time.Sleep(150 * time.Millisecond)
	}
}

// --- stopping ----------------------------------------------------------------

// stopServer SIGTERMs the recorded pid, waits up to stopGrace, then SIGKILLs.
// Returns whether something was actually running. A stale/absent pidfile is
// cleaned up and reported as "not running".
func stopServer(s Server, root string, grace time.Duration) (bool, error) {
	pid, ok := readPid(s, root)
	if !ok || !processAlive(pid) {
		os.Remove(s.pidPath(root))
		return false, nil
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		os.Remove(s.pidPath(root))
		return false, fmt.Errorf("find %s pid %d: %w", s.Name, pid, err)
	}
	_ = proc.Signal(syscall.SIGTERM)
	deadline := time.Now().Add(grace)
	for processAlive(pid) {
		if time.Now().After(deadline) {
			_ = proc.Signal(syscall.SIGKILL)
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	for i := 0; i < 60 && processAlive(pid); i++ {
		time.Sleep(50 * time.Millisecond)
	}
	os.Remove(s.pidPath(root))
	return true, nil
}

// --- restarting (the safe hot-swap pipeline) ---------------------------------

// restartServer runs the full hot-swap for one server, strictly ordered:
//
//	build → atomic swap → stop old → wait until startable → start new
//
// "wait until startable" is what makes an aaw restart correct: the new aaw
// would die with INSTANCE_LOCKED if it booted before the old one released its
// flock, so we block until the flock is acquirable and the port is free.
func restartServer(s Server, root string, detach bool) (*exec.Cmd, error) {
	if err := buildSwap(s, root); err != nil {
		return nil, err
	}
	if _, err := stopServer(s, root, stopGrace); err != nil {
		return nil, err
	}
	if err := waitStartable(s); err != nil {
		return nil, err
	}
	return startOne(s, root, detach)
}

// waitStartable blocks (bounded) until a fresh instance can boot: the aaw
// instance flock is released AND the port is bindable. For msh (no flock) only
// the port check applies.
func waitStartable(s Server) error {
	if err := waitFlockFree(s.LockPath, 9*time.Second); err != nil {
		return err
	}
	return waitPortFree(s, 9*time.Second)
}

// waitFlockFree blocks until the instance flock is acquirable, i.e. the previous
// instance fully exited and the kernel released its LOCK_EX. aaw takes this lock
// before binding and holds it for its whole life (go/aaw/internal/store/lock.go),
// so flock-free is the authoritative, PID-reuse-immune "old instance is gone"
// signal. We acquire non-blocking and release immediately; mcpd is the only
// thing that starts aaw (serialised by the orchestrator lock), so the very next
// spawn reliably re-acquires.
func waitFlockFree(lockPath string, timeout time.Duration) error {
	if lockPath == "" {
		return nil
	}
	deadline := time.Now().Add(timeout)
	for {
		f, err := os.Open(lockPath)
		if err != nil {
			if os.IsNotExist(err) {
				return nil // no lock file ⇒ nothing holds it
			}
			return err
		}
		lockErr := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB)
		if lockErr == nil {
			_ = syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
			f.Close()
			return nil
		}
		f.Close()
		if time.Now().After(deadline) {
			return fmt.Errorf("timed out waiting for the instance lock %s to release", lockPath)
		}
		time.Sleep(50 * time.Millisecond)
	}
}

// waitPortFree blocks until every address the server binds is free (listen +
// immediate close). For aaw this checks BOTH loopback families, mirroring its
// all-or-nothing dual-stack bind.
func waitPortFree(s Server, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for {
		free := true
		for _, a := range s.bindAddrs() {
			l, err := net.Listen(a.network, a.addr)
			if err != nil {
				free = false
				break
			}
			l.Close()
		}
		if free {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("port %d still in use after stopping %s", s.Port, s.Name)
		}
		time.Sleep(50 * time.Millisecond)
	}
}

// --- probes & pidfiles -------------------------------------------------------

// portListening reports whether something accepts a TCP connection on the port.
func portListening(port int, timeout time.Duration) bool {
	c, err := net.DialTimeout("tcp", "localhost:"+strconv.Itoa(port), timeout)
	if err != nil {
		return false
	}
	c.Close()
	return true
}

// processAlive is a signal-0 liveness probe (the same check msh uses).
func processAlive(pid int) bool {
	proc, err := os.FindProcess(pid)
	if err != nil {
		return false
	}
	return proc.Signal(syscall.Signal(0)) == nil
}

// isRunning is true when the recorded pid names a live process.
func isRunning(s Server, root string) bool {
	pid, ok := readPid(s, root)
	return ok && processAlive(pid)
}

func mustPid(s Server, root string) int {
	pid, _ := readPid(s, root)
	return pid
}

func readPid(s Server, root string) (int, bool) {
	b, err := os.ReadFile(s.pidPath(root))
	if err != nil {
		return 0, false
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(b)))
	if err != nil {
		return 0, false
	}
	return pid, true
}

// writePid writes the pidfile atomically (temp + rename) — a torn read would
// just fail the strconv and be treated as "no pidfile", but atomic write keeps
// the discipline uniform with the binary swap.
func writePid(s Server, root string, pid int) error {
	tmp := s.pidPath(root) + ".tmp"
	if err := os.WriteFile(tmp, []byte(strconv.Itoa(pid)), 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, s.pidPath(root))
}
