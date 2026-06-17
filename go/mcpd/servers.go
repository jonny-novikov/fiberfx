package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

// Server describes one managed MCP server: how to build it, how to launch its
// FOREGROUND `serve`, and where it listens. The whole aaw/msh asymmetry lives in
// these fields so the daemon engine (daemon.go) can treat both uniformly:
//
//   - aaw is stdlib-`flag`, NOT cobra, and flag.Parse stops at the first
//     non-flag arg — so its flags MUST precede the `serve` word, and `-addr`
//     MUST be the literal "localhost:8905" (aaw's strict wire-check compares the
//     host string against .mcp.json with no 127.0.0.1 normalization). aaw also
//     holds an instance flock for its whole life (DualLock/LockPath).
//   - msh is cobra: `mcp serve --port … --root …`, single socket, no flock.
type Server struct {
	Name      string   // short id; also bin/<Name>, bin/<Name>.pid, bin/<Name>.log
	AppDir    string   // module dir to build from (go build's cwd)
	BuildPkg  string   // package arg to `go build -o <out> <BuildPkg>`
	Port      int      // TCP port it binds on localhost
	ServeArgs []string // args to the built binary for a foreground serve
	WorkDir   string   // child process working directory
	DualStack bool     // binds both 127.0.0.1 and [::1] all-or-nothing (aaw)
	LockPath  string   // non-empty ⇒ an flock held for process-life (aaw); the
	// authoritative "previous instance fully exited" signal on restart
}

// servers is the static registry of everything mcpd manages, parameterised by
// the resolved repo root. Ground truth for both invocations is the as-built
// boot code: go/aaw/cmd/aaw/main.go (flags-before-serve, strict wire-check vs
// the repo-root .mcp.json which pins aaw→localhost:8905) and go/msh/cmd/main.go
// (msh mcp serve --port 8899; memory root from .msh-memory.json → <root>/memory).
func servers(root string) []Server {
	return []Server{
		{
			Name:      "aaw",
			AppDir:    filepath.Join(root, "go", "aaw"),
			BuildPkg:  "./cmd/aaw",
			Port:      8905,
			ServeArgs: []string{"-workspace", root, "-addr", "localhost:8905", "serve"},
			WorkDir:   root,
			DualStack: true,
			LockPath:  filepath.Join(root, ".aaw", "aaw.lock"),
		},
		{
			Name:      "msh",
			AppDir:    filepath.Join(root, "go", "msh"),
			BuildPkg:  "./cmd",
			Port:      8899,
			ServeArgs: []string{"mcp", "serve", "--port", "8899", "--root", filepath.Join(root, "memory")},
			WorkDir:   root,
		},
	}
}

// --- per-server paths under <root>/bin (all gitignored) ---------------------

func binDir(root string) string             { return filepath.Join(root, "bin") }
func (s Server) binPath(root string) string { return filepath.Join(binDir(root), s.Name) }
func (s Server) pidPath(root string) string { return filepath.Join(binDir(root), s.Name+".pid") }
func (s Server) logPath(root string) string { return filepath.Join(binDir(root), s.Name+".log") }

// tmpBuildPath is the staging path for a fresh build, in the same directory as
// the live binary so os.Rename into place is atomic (same filesystem).
func (s Server) tmpBuildPath(root string) string {
	return filepath.Join(binDir(root), "."+s.Name+".new")
}

// bindAddr is one (network, address) pair to probe for "is the port free".
type bindAddr struct{ network, addr string }

// bindAddrs mirrors exactly how the server itself binds, so a free-port probe
// is faithful. aaw binds dual-stack all-or-nothing (go/aaw/cmd/aaw/main.go
// bindLocalhost); msh binds a single localhost socket.
func (s Server) bindAddrs() []bindAddr {
	p := strconv.Itoa(s.Port)
	if s.DualStack {
		return []bindAddr{{"tcp4", "127.0.0.1:" + p}, {"tcp6", "[::1]:" + p}}
	}
	return []bindAddr{{"tcp", "localhost:" + p}}
}

// --- repo root resolution ----------------------------------------------------

// resolveRoot finds the jonnify repo root. An explicit --root wins; otherwise it
// walks up from the mcpd binary's own location (bin/mcpd ⇒ root two levels up)
// and then from the working directory, looking for the markers that uniquely
// identify this repo. It deliberately does NOT trust os.Getwd alone — a detached
// mcpd or a TUI launched from elsewhere would otherwise mis-resolve.
func resolveRoot(explicit string) (string, error) {
	if explicit != "" {
		abs, err := filepath.Abs(explicit)
		if err != nil {
			return "", err
		}
		if isRepoRoot(abs) {
			return abs, nil
		}
		return "", fmt.Errorf("--root %s is not the jonnify repo root (need .mcp.json + go/aaw + go/msh)", abs)
	}
	var starts []string
	if exe, err := os.Executable(); err == nil {
		starts = append(starts, filepath.Dir(exe))
	}
	if wd, err := os.Getwd(); err == nil {
		starts = append(starts, wd)
	}
	for _, start := range starts {
		if r := walkUpForRoot(start); r != "" {
			return r, nil
		}
	}
	return "", fmt.Errorf("could not locate the jonnify repo root (looked up from the mcpd binary and the working dir); pass --root")
}

func walkUpForRoot(dir string) string {
	for {
		if isRepoRoot(dir) {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return ""
		}
		dir = parent
	}
}

// isRepoRoot is true when dir holds the markers that identify THIS repo: the
// .mcp.json aaw's wire-check needs, plus both managed app dirs.
func isRepoRoot(dir string) bool {
	for _, marker := range []string{".mcp.json", filepath.Join("go", "aaw"), filepath.Join("go", "msh")} {
		if _, err := os.Stat(filepath.Join(dir, marker)); err != nil {
			return false
		}
	}
	return true
}
