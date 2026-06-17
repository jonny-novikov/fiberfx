// Copyright 2026 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// Package mcp — must-not-contracts invariant guard (nil-check + non-mutation).
//
// Promotes godoc-only contracts to enforced tests per backlog §4.6:
//   §4.6a NewClient(nil, ...) panics      (mcp/client.go:41 godoc → :45 runtime)
//   §4.6b NewServer(nil, ...) panics      (mcp/server.go:154 godoc → :158 runtime)
//   §4.6c Server.AddTool does not mutate the caller's Tool during registration
//         (mcp/server.go:217 godoc — symmetric server-side invariant)
//
// References:
//   - D-21 (this file) in dev/mcp/features/FTR-006-mcp-server-research-preview/state.yaml
//   - backlog.md §4.6 at apps/mcp-go/docs/backlog.md
//   - client.go:41, :45-47
//   - server.go:154, :158-160, :217, :277

package mcp

import (
	"context"
	"encoding/json"
	"reflect"
	"testing"
)

// TestNewClientNilImplementationPanics asserts the client.go:41 contract
// that NewClient panics when its first argument is nil, with message
// "nil Implementation". Locks in current runtime-enforced behavior.
//
// Regression this guards against: substitution of the panic with a silent
// return or an error-returning signature would cause the recover() guard
// to observe no panic and fail the test.
func TestNewClientNilImplementationPanics(t *testing.T) {
	defer func() {
		r := recover()
		if r == nil {
			t.Fatalf("NewClient(nil) nil-check invariant broken — call did not panic. See D-21 + backlog.md §4.6a + client.go:41.")
		}
		msg, ok := r.(string)
		if !ok {
			t.Fatalf("NewClient(nil) panicked with non-string value %v (type %T); expected string %q. See D-21 + backlog.md §4.6a.", r, r, "nil Implementation")
		}
		if msg != "nil Implementation" {
			t.Fatalf("NewClient(nil) panic message regression — got %q, want %q. See D-21 + backlog.md §4.6a.", msg, "nil Implementation")
		}
	}()
	_ = NewClient(nil, nil)
	t.Fatalf("NewClient(nil) returned without panic — invariant broken. See D-21 + backlog.md §4.6a + client.go:41.")
}

// TestNewServerNilImplementationPanics asserts the server.go:154 contract
// that NewServer panics when its first argument is nil, with message
// "nil Implementation". Parallel in shape to TestNewClientNilImplementationPanics.
func TestNewServerNilImplementationPanics(t *testing.T) {
	defer func() {
		r := recover()
		if r == nil {
			t.Fatalf("NewServer(nil) nil-check invariant broken — call did not panic. See D-21 + backlog.md §4.6b + server.go:154.")
		}
		msg, ok := r.(string)
		if !ok {
			t.Fatalf("NewServer(nil) panicked with non-string value %v (type %T); expected string %q. See D-21 + backlog.md §4.6b.", r, r, "nil Implementation")
		}
		if msg != "nil Implementation" {
			t.Fatalf("NewServer(nil) panic message regression — got %q, want %q. See D-21 + backlog.md §4.6b.", msg, "nil Implementation")
		}
	}()
	_ = NewServer(nil, nil)
	t.Fatalf("NewServer(nil) returned without panic — invariant broken. See D-21 + backlog.md §4.6b + server.go:154.")
}

// TestToolArgumentNotMutatedPostRegister asserts the server-side symmetric
// invariant to the godoc contract at server.go:217: the server itself does
// NOT mutate the caller's Tool during registration.
//
// The godoc states the *caller's* obligation ("must not be modified after
// this call"). This test locks in the corresponding *server-side* guarantee:
// fields on the caller's *Tool struct are byte-for-byte identical before and
// after AddTool, as observed through JSON marshaling.
//
// Regression this guards against: a refactor that caches a resolved schema
// back onto t.InputSchema, or populates t.Annotations from defaults, would
// change the marshaled form and fail reflect.DeepEqual.
func TestToolArgumentNotMutatedPostRegister(t *testing.T) {
	tool := &Tool{
		Name:        "invariant-test-tool",
		Description: "captured for non-mutation test",
		InputSchema: json.RawMessage(`{"type":"object","properties":{"x":{"type":"string"}}}`),
	}
	before, err := json.Marshal(tool)
	if err != nil {
		t.Fatalf("pre-register marshal error: %v", err)
	}

	srv := NewServer(&Implementation{Name: "test", Version: "v0"}, nil)
	srv.AddTool(tool, func(context.Context, *CallToolRequest) (*CallToolResult, error) {
		return &CallToolResult{}, nil
	})

	after, err := json.Marshal(tool)
	if err != nil {
		t.Fatalf("post-register marshal error: %v", err)
	}

	if !reflect.DeepEqual(before, after) {
		t.Fatalf("non-mutation invariant broken — AddTool mutated the caller's Tool. Before=%s After=%s. See D-21 + backlog.md §4.6c + server.go:217.", string(before), string(after))
	}
}
