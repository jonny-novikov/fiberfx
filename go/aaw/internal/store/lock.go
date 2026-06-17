package store

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/jonny-novikov/aaw/internal/gates"
)

// InstanceLock is the held single-instance guard: an advisory flock on
// <workspace>/.aaw/aaw.lock held for the process lifetime (MCP1-D5 / ADR-2).
// One instance per workspace makes the in-process per-scope lock sufficient
// for all file mutations; the flock releases with the fd on any exit.
type InstanceLock struct {
	ID   string
	PID  int
	Path string
	f    *os.File
}

// AcquireInstanceLock takes the workspace flock, writing the holder's
// instance id + pid into the lock file, or refuses with INSTANCE_LOCKED
// naming the current holder.
func AcquireInstanceLock(workspace string) (*InstanceLock, error) {
	path := filepath.Join(workspace, ".aaw", "aaw.lock")
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, err
	}
	f, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE, 0o644)
	if err != nil {
		return nil, err
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		holder, _ := os.ReadFile(path)
		f.Close()
		// The boot-time, non-tool-result member of the closed set (MCP3-D4):
		// the literal folds into the gates constant, the rendering stays —
		// main.go's "aaw: %v" boot prefix already prints the contract form
		// "aaw: INSTANCE_LOCKED: <detail>". Behavior unchanged.
		return nil, fmt.Errorf("%s: workspace %s is already served by another aaw instance (%s)", gates.INSTANCE_LOCKED, workspace, strings.TrimSpace(string(holder)))
	}
	lk := &InstanceLock{
		ID:   fmt.Sprintf("aaw-%d-%d", os.Getpid(), time.Now().Unix()),
		PID:  os.Getpid(),
		Path: path,
		f:    f,
	}
	if err := f.Truncate(0); err != nil {
		f.Close()
		return nil, err
	}
	if _, err := fmt.Fprintf(f, "%s pid=%d\n", lk.ID, lk.PID); err != nil {
		f.Close()
		return nil, err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		return nil, err
	}
	return lk, nil
}

// Release drops the flock by closing the fd. Tests use it; the server holds
// the lock for its lifetime and never calls it.
func (l *InstanceLock) Release() error { return l.f.Close() }
