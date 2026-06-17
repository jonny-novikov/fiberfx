package store

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

// MCP1-INV2: a reader observes either the complete prior file or the complete
// new file — never a torn one — while writes race the reads.
func TestWriteFileAtomicNeverTorn(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "f.json")
	old := bytes.Repeat([]byte("A"), 4096)
	next := bytes.Repeat([]byte("B"), 8192)
	if err := writeFileAtomic(path, old, 0o644); err != nil {
		t.Fatal(err)
	}

	stop := make(chan struct{})
	var wg sync.WaitGroup
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case <-stop:
					return
				default:
				}
				b, err := os.ReadFile(path)
				if err != nil {
					t.Errorf("read: %v", err)
					return
				}
				switch {
				case len(b) == len(old) && bytes.Count(b, []byte("A")) == len(old):
				case len(b) == len(next) && bytes.Count(b, []byte("B")) == len(next):
				default:
					t.Errorf("torn read: len=%d head=%q", len(b), b[:min(8, len(b))])
					return
				}
			}
		}()
	}
	for i := 0; i < 200; i++ {
		data := old
		if i%2 == 0 {
			data = next
		}
		if err := writeFileAtomic(path, data, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	close(stop)
	wg.Wait()

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		if strings.Contains(e.Name(), ".tmp.") {
			t.Errorf("temp residue after successful writes: %s", e.Name())
		}
	}
}

// MCP1-INV2: a crash before the rename (a stray partial temp file) leaves the
// prior file whole, and a later atomic write still lands.
func TestWriteFileAtomicCrashLeavesPriorWhole(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "f.json")
	if err := writeFileAtomic(path, []byte("prior"), 0o644); err != nil {
		t.Fatal(err)
	}
	// The crash shape: the temp written but never renamed.
	if err := os.WriteFile(path+".tmp.crashed", []byte("par"), 0o600); err != nil {
		t.Fatal(err)
	}
	b, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != "prior" {
		t.Fatalf("prior file not whole after simulated crash: %q", b)
	}
	if err := writeFileAtomic(path, []byte("next"), 0o644); err != nil {
		t.Fatal(err)
	}
	b, err = os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(b) != "next" {
		t.Fatalf("subsequent atomic write lost: %q", b)
	}
	// The stale temp is inert: never read, never renamed over, untouched by
	// later writes. It accumulates until swept — out of this rung's scope.
	if b, err := os.ReadFile(path + ".tmp.crashed"); err != nil || string(b) != "par" {
		t.Fatalf("stale tmp not inert after a subsequent write: %q %v", b, err)
	}
}
