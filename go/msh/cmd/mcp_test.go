package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/fiberfx/mcp-go/v2/mcp"
	"github.com/jonny-novikov/msh/brandedid"
)

// testCorpusRoot points at the msh-memory module's synthetic testdata corpus so
// the MCP tools run against a known, hermetic fixture.
func testCorpusRoot(t *testing.T) string {
	t.Helper()
	abs, err := filepath.Abs(filepath.Join("..", "memory", "testdata", "memory"))
	if err != nil {
		t.Fatal(err)
	}
	return abs
}

func textOf(res *mcp.CallToolResult) string {
	var b strings.Builder
	for _, c := range res.Content {
		if tc, ok := c.(*mcp.TextContent); ok {
			b.WriteString(tc.Text)
		}
	}
	return b.String()
}

// TestMemoryToolsOverStreamableHTTP drives the registered memory tools through
// the real streamable-HTTP transport (handler <-> client), exercising the same
// path a remote MCP client uses.
func TestMemoryToolsOverStreamableHTTP(t *testing.T) {
	root := testCorpusRoot(t)
	srv := buildMCPServer(root)

	ts := httptest.NewServer(mcp.NewStreamableHTTPHandler(
		func(*http.Request) *mcp.Server { return srv }, nil))
	defer ts.Close()

	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "msh-test", Version: "test"}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: ts.URL}, nil)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer session.Close(ctx)

	// All four memory tools must be advertised.
	lt, err := session.ListTools(ctx, nil)
	if err != nil {
		t.Fatalf("list tools: %v", err)
	}
	got := map[string]bool{}
	for _, tl := range lt.Tools {
		got[tl.Name] = true
	}
	for _, want := range []string{"memory_audit", "memory_stale", "memory_graph", "memory_scan"} {
		if !got[want] {
			t.Errorf("missing tool %q (advertised: %v)", want, got)
		}
	}

	// memory_scan should enumerate the corpus, including its MEMORY.md index.
	scan, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "memory_scan",
		Arguments: map[string]any{"format": "ndjson"},
	})
	if err != nil {
		t.Fatalf("call memory_scan: %v", err)
	}
	if scan.IsError {
		t.Fatalf("memory_scan reported tool error: %s", textOf(scan))
	}
	if out := textOf(scan); !strings.Contains(out, "MEMORY.md") {
		t.Errorf("memory_scan output missing MEMORY.md:\n%s", out)
	}

	// memory_audit should produce the summary line.
	audit, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "memory_audit",
		Arguments: map[string]any{},
	})
	if err != nil {
		t.Fatalf("call memory_audit: %v", err)
	}
	if audit.IsError {
		t.Fatalf("memory_audit reported tool error: %s", textOf(audit))
	}
	if out := textOf(audit); !strings.Contains(out, "audit summary") {
		t.Errorf("memory_audit output missing summary:\n%s", out)
	}

	// A per-call root override should also work (point at the same fixture).
	graph, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "memory_graph",
		Arguments: map[string]any{"root": root, "format": "json"},
	})
	if err != nil {
		t.Fatalf("call memory_graph: %v", err)
	}
	if graph.IsError {
		t.Fatalf("memory_graph reported tool error: %s", textOf(graph))
	}
	if out := textOf(graph); !strings.Contains(out, "\"nodes\"") {
		t.Errorf("memory_graph json missing nodes:\n%s", out)
	}
}

// TestMintToolOverStreamableHTTP exercises mcp__msh__mint end-to-end: minting a
// SES-branded id over the real transport.
func TestMintToolOverStreamableHTTP(t *testing.T) {
	srv := buildMCPServer(testCorpusRoot(t))
	ts := httptest.NewServer(mcp.NewStreamableHTTPHandler(
		func(*http.Request) *mcp.Server { return srv }, nil))
	defer ts.Close()

	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "msh-test", Version: "test"}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: ts.URL}, nil)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer session.Close(ctx)

	// Single SES id (text format).
	res, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "mint",
		Arguments: map[string]any{"ns": "SES"},
	})
	if err != nil {
		t.Fatalf("call mint: %v", err)
	}
	if res.IsError {
		t.Fatalf("mint reported tool error: %s", textOf(res))
	}
	id := strings.TrimSpace(textOf(res))
	if !brandedid.Valid(id) {
		t.Fatalf("mint returned invalid brd14 id %q", id)
	}
	if ns, _, _ := brandedid.Parse(id); ns != "SES" {
		t.Fatalf("expected SES namespace, got %q (id %q)", ns, id)
	}

	// A batch with decoded fields (ndjson).
	batch, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "mint",
		Arguments: map[string]any{"ns": "USR", "count": 3, "format": "ndjson"},
	})
	if err != nil {
		t.Fatalf("call mint batch: %v", err)
	}
	if batch.IsError {
		t.Fatalf("mint batch tool error: %s", textOf(batch))
	}
	lines := strings.Split(strings.TrimSpace(textOf(batch)), "\n")
	if len(lines) != 3 {
		t.Fatalf("expected 3 ndjson lines, got %d:\n%s", len(lines), textOf(batch))
	}
}

// TestSpecsToolOverStreamableHTTP exercises mcp__msh__specs end-to-end: the tool
// is advertised, and a docs tree with a known dead link yields a DEAD-TARGET
// finding over the real transport.
func TestSpecsToolOverStreamableHTTP(t *testing.T) {
	// A throwaway docs tree with one dead relative link.
	area := t.TempDir()
	if err := os.WriteFile(filepath.Join(area, "a.md"),
		[]byte("# A\n\n[dead](missing.md)\n[ok external](https://example.com)\n"), 0o644); err != nil {
		t.Fatalf("write fixture: %v", err)
	}

	srv := buildMCPServer(testCorpusRoot(t))
	ts := httptest.NewServer(mcp.NewStreamableHTTPHandler(
		func(*http.Request) *mcp.Server { return srv }, nil))
	defer ts.Close()

	ctx := context.Background()
	client := mcp.NewClient(&mcp.Implementation{Name: "msh-test", Version: "test"}, nil)
	session, err := client.Connect(ctx, &mcp.StreamableClientTransport{Endpoint: ts.URL}, nil)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer session.Close(ctx)

	// The specs tool must be advertised.
	lt, err := session.ListTools(ctx, nil)
	if err != nil {
		t.Fatalf("list tools: %v", err)
	}
	advertised := false
	for _, tl := range lt.Tools {
		if tl.Name == "specs" {
			advertised = true
		}
	}
	if !advertised {
		t.Fatalf("specs tool not advertised")
	}

	// Calling it against the fixture surfaces the dead link (and skips the URL).
	res, err := session.CallTool(ctx, &mcp.CallToolParams{
		Name:      "specs",
		Arguments: map[string]any{"area": area, "format": "ndjson", "severity": "info"},
	})
	if err != nil {
		t.Fatalf("call specs: %v", err)
	}
	if res.IsError {
		t.Fatalf("specs reported tool error: %s", textOf(res))
	}
	out := textOf(res)
	if !strings.Contains(out, "DEAD-TARGET") || !strings.Contains(out, "missing.md") {
		t.Errorf("specs output missing the dead-link finding:\n%s", out)
	}
	// Exactly one finding: the external URL is skipped (it appears only in the
	// dead link's context snippet, never as a flagged target).
	if n := strings.Count(strings.TrimSpace(out), "\n") + 1; n != 1 {
		t.Errorf("expected exactly 1 finding (external URL skipped), got %d:\n%s", n, out)
	}
	if strings.Contains(out, `"target":"https://example.com"`) {
		t.Errorf("specs should skip external URLs, but flagged one as a target:\n%s", out)
	}
}
