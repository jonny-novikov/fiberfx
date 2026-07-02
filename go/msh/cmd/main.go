// Command msh is the "msh" toolchain + MCP server.
//
// "memory" subcommand, and exposes the same memory operations as MCP tools over
// a streamable-HTTP server mcp__msh__memory_* :
//
//	msh memory scan|graph|stale|audit|version   # the memory CLI, verbatim
//	msh specs [AREA]   [--base docs] [--format pretty] [--severity warn]  # stale md-link check
//	msh mcp serve   [--port 8899] [--root P] [--stdio]   # foreground server
//	msh mcp start   [--port 8899] [--root P]             # detach + pidfile
//	msh mcp stop    [--port 8899]
//	msh mcp restart [--port 8899] [--root P]
//
// Register the running server in a project .mcp.json as:
//
//	"msh": { "type": "streamable-http", "url": "http://localhost:8899/" }
//
// which surfaces the tools to a client as mcp__msh__memory_audit,
// mcp__msh__specs, mcp__msh__mint, etc.
package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/spf13/cobra"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/msh/memory/command"
)

const (
	mcpName        = "msh"
	mcpVersion     = "0.1.0"
	defaultMCPPort = 8899
)

func main() {
	if err := newRootCmd().Execute(); err != nil {
		os.Exit(1)
	}
}

// newRootCmd assembles the whole msh command tree. This is the single wiring
// point: the memory toolchain and the MCP server are both mounted here.
func newRootCmd() *cobra.Command {
	root := &cobra.Command{
		Use:           "msh",
		Short:         "msh — memory toolchain + MCP server.",
		Long:          "msh mounts the msh-memory graph/stale toolchain as a subcommand and serves the same operations as MCP tools over streamable HTTP.",
		SilenceUsage:  true,
		SilenceErrors: false,
	}

	// `msh memory ...` — the full msh-memory command tree, mounted verbatim.
	root.AddCommand(command.New(
		"memory",
		"Memory graph + stale-reference toolchain.",
		os.Stdout, os.Stderr,
	))

	// `msh mcp ...` — run/manage the MCP server.
	root.AddCommand(newMCPCmd())

	// `msh mint ...` — mint branded snowflake ids (brd14).
	root.AddCommand(newMintCmd())

	// `msh specs [AREA]` — check a docs/specs tree for stale markdown links.
	root.AddCommand(newSpecsCmd())

	// `msh history QUERY...` — search Claude Code session transcripts.
	root.AddCommand(newHistoryCmd())

	return root
}

// ---- mcp command group -----------------------------------------------------

func newMCPCmd() *cobra.Command {
	var port int
	var root string

	mcpCmd := &cobra.Command{
		Use:   "mcp",
		Short: "Run/manage the msh MCP server (memory tools over streamable HTTP).",
	}
	mcpCmd.PersistentFlags().IntVar(&port, "port", defaultMCPPort, "TCP port for the streamable-HTTP MCP server")
	mcpCmd.PersistentFlags().StringVar(&root, "root", "", "Memory root (default: .msh-memory.json, else walk-up to MEMORY.md)")

	var stdio bool
	serve := &cobra.Command{
		Use:   "serve",
		Short: "Run the MCP server in the foreground (blocks until SIGINT/SIGTERM).",
		Args:  cobra.NoArgs,
		RunE: func(_ *cobra.Command, _ []string) error {
			return serveMCP(port, root, stdio)
		},
	}
	serve.Flags().BoolVar(&stdio, "stdio", false, "Use stdio transport instead of streamable HTTP")

	start := &cobra.Command{
		Use:   "start",
		Short: "Start the MCP server detached (writes a pidfile).",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return startMCP(port, root) },
	}
	stop := &cobra.Command{
		Use:   "stop",
		Short: "Stop the detached MCP server for this port.",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return stopMCP(port) },
	}
	restart := &cobra.Command{
		Use:   "restart",
		Short: "Restart the detached MCP server for this port.",
		Args:  cobra.NoArgs,
		RunE:  func(_ *cobra.Command, _ []string) error { return restartMCP(port, root) },
	}

	mcpCmd.AddCommand(serve, start, stop, restart)
	return mcpCmd
}

// ---- server + tool registrator ---------------------------------------------

// serveMCP builds the MCP server and serves it on the chosen transport,
// blocking until the process receives SIGINT/SIGTERM.
func serveMCP(port int, root string, stdio bool) error {
	resolvedRoot, err := command.ResolveRoot(root)
	if err != nil {
		return fmt.Errorf("resolve memory root: %w", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	server := buildMCPServer(resolvedRoot)

	if stdio {
		log.Printf("msh mcp: stdio transport, memory root %s", resolvedRoot)
		return server.Run(ctx, &mcp.StdioTransport{})
	}

	addr := fmt.Sprintf("localhost:%d", port)
	handler := mcp.NewStreamableHTTPHandler(func(*http.Request) *mcp.Server { return server }, nil)
	httpSrv := &http.Server{Addr: addr, Handler: handler}

	go func() {
		<-ctx.Done()
		shutCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = httpSrv.Shutdown(shutCtx)
	}()

	log.Printf("msh mcp: streamable HTTP on http://%s/  (memory root %s)", addr, resolvedRoot)
	if err := httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

// buildMCPServer constructs the MCP server and registers the memory tools.
func buildMCPServer(root string) *mcp.Server {
	server := mcp.NewServer(&mcp.Implementation{Name: mcpName, Version: mcpVersion}, nil)
	registerMemoryTools(server, root)
	registerMintTool(server)
	registerSpecsTool(server)
	registerHistoryTool(server, root)
	return server
}

// Tool argument structs. Empty fields fall back to the server's defaults; an
// explicit Root overrides the server-wide memory root per call.
type (
	auditArgs struct {
		Root   string `json:"root,omitempty" jsonschema:"override the memory root for this call"`
		Config string `json:"config,omitempty" jsonschema:"path to .msh-memory.yaml (default: <root>/.msh-memory.yaml)"`
	}
	staleArgs struct {
		Root     string `json:"root,omitempty" jsonschema:"override the memory root for this call"`
		Config   string `json:"config,omitempty" jsonschema:"path to .msh-memory.yaml"`
		Rules    string `json:"rules,omitempty" jsonschema:"comma-separated rule names, or 'all' (default)"`
		Severity string `json:"severity,omitempty" jsonschema:"minimum severity: error | warn (default) | info"`
		Format   string `json:"format,omitempty" jsonschema:"ndjson (default) | pretty"`
	}
	graphArgs struct {
		Root            string `json:"root,omitempty" jsonschema:"override the memory root for this call"`
		Format          string `json:"format,omitempty" jsonschema:"json (default) | dot"`
		IncludeExternal bool   `json:"include_external,omitempty" jsonschema:"include external_rel edges"`
	}
	scanArgs struct {
		Root   string `json:"root,omitempty" jsonschema:"override the memory root for this call"`
		Format string `json:"format,omitempty" jsonschema:"ndjson (default) | pretty"`
	}
	projectArgs struct {
		Format string `json:"format,omitempty" jsonschema:"text (default) | json"`
	}
)

// registerMemoryTools is the mcp-go tool registrator: it binds each memory
// operation to a tool. Every handler forwards to the command package so the
// MCP surface and the CLI share one implementation.
func registerMemoryTools(s *mcp.Server, root string) {
	mcp.AddTool(s, &mcp.Tool{
		Name:        "memory_audit",
		Description: "Audit the memory corpus: node count, stale-finding counts, and warn+ findings.",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in auditArgs) (*mcp.CallToolResult, any, error) {
		out, err := command.Audit(rootOr(root, in.Root), in.Config)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})

	mcp.AddTool(s, &mcp.Tool{
		Name:        "memory_stale",
		Description: "Run stale-detection rules and return findings (dead targets, broken anchors, orphans, removed tools, stale external links).",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in staleArgs) (*mcp.CallToolResult, any, error) {
		out, err := command.Stale(rootOr(root, in.Root), in.Config, in.Rules, in.Severity, in.Format)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})

	mcp.AddTool(s, &mcp.Tool{
		Name:        "memory_graph",
		Description: "Build the cross-reference graph of the memory corpus and return it as JSON or GraphViz dot.",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in graphArgs) (*mcp.CallToolResult, any, error) {
		out, err := command.Graph(rootOr(root, in.Root), in.Format, in.IncludeExternal)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})

	mcp.AddTool(s, &mcp.Tool{
		Name:        "memory_scan",
		Description: "Walk the memory corpus and return per-note metadata (frontmatter name/type/description, size, hash).",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in scanArgs) (*mcp.CallToolResult, any, error) {
		out, err := command.Scan(rootOr(root, in.Root), in.Format)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})

	mcp.AddTool(s, &mcp.Tool{
		Name:        "memory_project",
		Description: "Return the active project context from .msh-memory.json: name, code, roadmap, status, current_rung, the resolved memory root, and the optional docs_root (anchor v1.1) — orients an agent to what is being developed.",
	}, func(_ context.Context, _ *mcp.CallToolRequest, in projectArgs) (*mcp.CallToolResult, any, error) {
		out, err := command.ProjectInfo(in.Format)
		if err != nil {
			return nil, nil, err
		}
		return textResult(out), nil, nil
	})
}

func textResult(s string) *mcp.CallToolResult {
	return &mcp.CallToolResult{Content: []mcp.Content{&mcp.TextContent{Text: s}}}
}

func rootOr(serverRoot, override string) string {
	if strings.TrimSpace(override) != "" {
		return override
	}
	return serverRoot
}

// Root resolution (explicit flag > .msh-memory.json root > MEMORY.md walk-up)
// lives in the command package, so the CLI and the MCP server resolve the corpus
// identically; see command.ResolveRoot / command.LoadMemoryConfig.

// ---- detached process management (start/stop/restart) ----------------------

func pidFilePath(port int) string {
	return filepath.Join(os.TempDir(), fmt.Sprintf("msh-mcp-%d.pid", port))
}

func logFilePath(port int) string {
	return filepath.Join(os.TempDir(), fmt.Sprintf("msh-mcp-%d.log", port))
}

func startMCP(port int, root string) error {
	if pid, ok := readPid(port); ok && processAlive(pid) {
		return fmt.Errorf("msh mcp already running on port %d (pid %d)", port, pid)
	}

	self, err := os.Executable()
	if err != nil {
		return fmt.Errorf("locate self: %w", err)
	}

	args := []string{"mcp", "serve", "--port", strconv.Itoa(port)}
	if strings.TrimSpace(root) != "" {
		args = append(args, "--root", root)
	}

	logf, err := os.OpenFile(logFilePath(port), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return fmt.Errorf("open log: %w", err)
	}
	defer logf.Close()

	cmd := exec.Command(self, args...)
	cmd.Stdout = logf
	cmd.Stderr = logf
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true} // detach into its own session

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start server: %w", err)
	}
	if err := os.WriteFile(pidFilePath(port), []byte(strconv.Itoa(cmd.Process.Pid)), 0o644); err != nil {
		return fmt.Errorf("write pidfile: %w", err)
	}

	fmt.Printf("msh mcp started: http://localhost:%d/  (pid %d, log %s)\n", port, cmd.Process.Pid, logFilePath(port))
	return nil
}

func stopMCP(port int) error {
	pid, ok := readPid(port)
	if !ok {
		return fmt.Errorf("msh mcp not running on port %d (no pidfile)", port)
	}
	proc, err := os.FindProcess(pid)
	if err != nil {
		_ = os.Remove(pidFilePath(port))
		return fmt.Errorf("find pid %d: %w", pid, err)
	}
	if err := proc.Signal(syscall.SIGTERM); err != nil {
		_ = os.Remove(pidFilePath(port))
		return fmt.Errorf("signal pid %d (already gone?): %w", pid, err)
	}
	_ = os.Remove(pidFilePath(port))
	fmt.Printf("msh mcp stopped (pid %d)\n", pid)
	return nil
}

func restartMCP(port int, root string) error {
	if pid, ok := readPid(port); ok && processAlive(pid) {
		if err := stopMCP(port); err != nil {
			return err
		}
		// Give the old process a moment to release the listening socket.
		for i := 0; i < 20; i++ {
			if !processAlive(pid) {
				break
			}
			time.Sleep(50 * time.Millisecond)
		}
	}
	return startMCP(port, root)
}

func readPid(port int) (int, bool) {
	b, err := os.ReadFile(pidFilePath(port))
	if err != nil {
		return 0, false
	}
	pid, err := strconv.Atoi(strings.TrimSpace(string(b)))
	if err != nil {
		return 0, false
	}
	return pid, true
}

// processAlive reports whether pid names a live process (signal 0 probe).
func processAlive(pid int) bool {
	proc, err := os.FindProcess(pid)
	if err != nil {
		return false
	}
	return proc.Signal(syscall.Signal(0)) == nil
}
