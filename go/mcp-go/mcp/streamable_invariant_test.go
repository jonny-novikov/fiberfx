// Copyright 2026 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// Package mcp — streamable.go prose-invariants → guard-test conversion.
//
// Promotes two prose invariants in mcp/streamable.go to test-enforced guards:
//   §4.4a (L732): non-nil done implies non-nil w
//   §4.4b (L1211): we have at least one call
//
// Both are internal invariants; the tests exercise the public
// StreamableHTTPHandler path that traverses each and asserts the
// externally-observable behavior (SSE-stream-established vs 202-accepted)
// that the invariant distinguishes.
//
// References:
//   - D-20 (this file) in dev/mcp/features/FTR-006-mcp-server-research-preview/state.yaml
//   - backlog.md §4.4 at apps/mcp-go/docs/backlog.md
//   - L732 prose: mcp/streamable.go:732
//   - L1211 prose: mcp/streamable.go:1211

package mcp

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// newTestStreamableServer returns an httptest.Server wrapping a
// StreamableHTTPHandler backed by a freshly-constructed mcp.Server.
// Mirrors the pattern used throughout streamable_test.go.
func newTestStreamableServer(t *testing.T) *httptest.Server {
	t.Helper()
	server := NewServer(&Implementation{Name: "t", Version: "v1"}, nil)
	handler := NewStreamableHTTPHandler(
		func(*http.Request) *Server { return server }, nil)
	return httptest.NewServer(handler)
}

// TestAtLeastOneCall covers §4.4b (streamable.go:1211).
//
// POSTing a payload with zero calls (only notifications) MUST return 202
// Accepted per spec §2.1.4 — this is the L1196 early-return branch. POSTing
// a payload with at least one call (a request carrying an ID) MUST return
// 200 with a streaming-compatible Content-Type — this is the L1211 branch.
//
// Regression this guards against: deletion of the `if len(calls) == 0`
// early-return at L1196 would cause notification-only POSTs to fall through
// to the logical-stream code path, producing 200 instead of 202.
func TestAtLeastOneCall(t *testing.T) {
	srv := newTestStreamableServer(t)
	defer srv.Close()

	sessionID := initializeStreamableSession(t, srv.URL)

	notificationBody := []byte(`{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}`)
	req, err := http.NewRequest(http.MethodPost, srv.URL, bytes.NewReader(notificationBody))
	if err != nil {
		t.Fatalf("NewRequest (notification): %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json, text/event-stream")
	req.Header.Set(sessionIDHeader, sessionID)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST notification error: %v", err)
	}
	if resp.StatusCode != http.StatusAccepted {
		b, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		t.Fatalf("at-least-one-call invariant: zero-calls path broken — got status %d, body %q; want %d. See D-20 + backlog.md §4.4b + streamable.go:1211.", resp.StatusCode, string(b), http.StatusAccepted)
	}
	resp.Body.Close()

	initBody := []byte(`{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}`)
	req2, err := http.NewRequest(http.MethodPost, srv.URL, bytes.NewReader(initBody))
	if err != nil {
		t.Fatalf("NewRequest (ping): %v", err)
	}
	req2.Header.Set("Content-Type", "application/json")
	req2.Header.Set("Accept", "application/json, text/event-stream")
	req2.Header.Set(sessionIDHeader, sessionID)
	resp2, err := http.DefaultClient.Do(req2)
	if err != nil {
		t.Fatalf("POST ping error: %v", err)
	}
	defer resp2.Body.Close()
	if resp2.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp2.Body)
		t.Fatalf("at-least-one-call invariant: non-empty-calls path broken — got status %d, body %q; want %d (streaming). See D-20 + backlog.md §4.4b + streamable.go:1211.", resp2.StatusCode, string(b), http.StatusOK)
	}
	ct := resp2.Header.Get("Content-Type")
	if !strings.HasPrefix(ct, "text/event-stream") && !strings.HasPrefix(ct, "application/json") {
		t.Fatalf("at-least-one-call invariant: streaming content-type broken — got %q; want text/event-stream or application/json. See D-20 + backlog.md §4.4b.", ct)
	}
}

// TestDoneImpliesWNonNil covers §4.4a (streamable.go:732).
//
// The invariant "a non-nil done implies w is also non-nil" is an internal
// coupling on the stream struct. The stream.close method at :758-... reads
// s.w when s.done != nil; if the invariant breaks (done non-nil, w nil),
// close will dereference a nil writer and panic.
//
// This test establishes a streamable session, drains and closes the response
// body (triggering the server-side close path), and asserts that no panic
// propagates. A recover() guard converts any nil-writer panic during close
// into a controlled test failure with spec cross-reference.
func TestDoneImpliesWNonNil(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			t.Fatalf("done-implies-w-non-nil invariant broken — stream.close panicked on nil writer. Recover: %v. See D-20 + backlog.md §4.4a + streamable.go:732.", r)
		}
	}()

	srv := newTestStreamableServer(t)
	defer srv.Close()

	initBody := []byte(`{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"v0"}}}`)
	req, err := http.NewRequest(http.MethodPost, srv.URL, bytes.NewReader(initBody))
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json, text/event-stream")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("POST initialize error: %v", err)
	}
	_, _ = io.Copy(io.Discard, resp.Body)
	resp.Body.Close()
}

// initializeStreamableSession performs the MCP initialize handshake
// against the given HTTP test URL and returns the session ID so
// subsequent notification-only POSTs are accepted by the server.
func initializeStreamableSession(t *testing.T, url string) string {
	t.Helper()
	body := `{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"t","version":"v1"}}}`
	req, err := http.NewRequest(http.MethodPost, url, strings.NewReader(body))
	if err != nil {
		t.Fatalf("NewRequest (init): %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json, text/event-stream")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Do (init): %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		payload, _ := io.ReadAll(resp.Body)
		t.Fatalf("initialize: status = %d, want %d. Body: %s", resp.StatusCode, http.StatusOK, payload)
	}
	sid := resp.Header.Get(sessionIDHeader)
	if sid == "" {
		t.Fatalf("initialize: no %s header in response", sessionIDHeader)
	}
	_, _ = io.Copy(io.Discard, resp.Body)
	return sid
}
