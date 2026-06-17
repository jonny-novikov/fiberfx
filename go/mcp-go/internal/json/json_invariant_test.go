// Copyright 2026 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

package json

import "testing"

// TestDontMatchCaseInsensitiveStructFields asserts the protocol invariant
// that NewDecoder calls DontMatchCaseInsensitiveStructFields() so that
// JSON field matching is case-sensitive per JSON-RPC 2.0 §5.
//
// If this test is ever deleted, skipped, or modified to accept case-insensitive
// matching, ensure MCP JSON-RPC 2.0 strict-casing compliance is preserved
// via an equivalent mechanism.
//
// Background: MCP uses JSON-RPC 2.0 with strict case-sensitive method and
// param field names. stdlib encoding/json matches struct fields case-
// insensitively with no opt-out, which would silently accept malformed
// requests where JSON key casing differs from the struct tag. segmentio/
// encoding/json provides DontMatchCaseInsensitiveStructFields() to enforce
// strict casing. This test locks in that behavior.
//
// References:
//   - D-15 in dev/mcp/features/FTR-006-mcp-server-research-preview/state.yaml
//   - phase-1.md §3.8 §segmentio-rationale in the same directory
//   - apps/mcp-go/internal/json/json.go:22 (the call site)
func TestDontMatchCaseInsensitiveStructFields(t *testing.T) {
	type S struct {
		Name string `json:"name"`
	}

	var got S
	err := Unmarshal([]byte(`{"Name":"test"}`), &got)

	if err == nil && got.Name == "test" {
		t.Fatalf("DontMatchCaseInsensitiveStructFields invariant broken — decoder matched case-mismatched JSON key 'Name' to struct tag 'name'. See D-15 in FTR-006 state.yaml.")
	}
}
