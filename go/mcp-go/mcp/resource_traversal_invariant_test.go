// Copyright 2026 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// Package mcp — path-traversal containment invariant guard.
//
// Promotes the prose contract at mcp/resource.go:88 ("It must not try to
// escape its directory") from godoc-only to enforced test. The enforcement is
// filepath.Localize + filepath.Rel/IsLocal; this test asserts that the
// negative set (../, %2e%2e/, windows-style, symlink-like) is uniformly
// rejected, and that valid same-dir / subdir paths still succeed.
//
// References:
//   - D-19 (this file) in dev/mcp/features/FTR-006-mcp-server-research-preview/state.yaml
//   - backlog.md §4.3 at apps/mcp-go/docs/backlog.md
//   - Prose contract: mcp/resource.go:88
//   - Enforcement: filepath.Localize at mcp/resource.go:89, filepath.Rel/IsLocal at :104

package mcp

import (
	"path/filepath"
	"testing"
)

// TestPathTraversalRejected asserts that a canonical negative-set of
// URL path-traversal attempts is uniformly rejected by computeURIFilepath,
// while a small positive control set is accepted.
//
// Regression this guards against: removal or softening of filepath.Localize
// at resource.go:89 (e.g., substitution with filepath.Clean) would cause
// one or more "../" forms to resolve to a canonical path and cease to
// produce an error, silently re-enabling directory escape.
//
// settled(aaw, was backlog §5.7 future-wave note): symlink-escape coverage
// stays deferred — it requires filesystem state, and Windows is out of fork
// scope.
func TestPathTraversalRejected(t *testing.T) {
	root := filepath.Join(string(filepath.Separator), "tmp", "ftr006-traversal-test")

	cases := []struct {
		name    string
		rawURI  string
		wantErr bool
	}{
		{"dotdot-slash", "file:///../escape", true},
		{"double-dotdot", "file:///../../etc/passwd", true},
		{"url-encoded-dotdot", "file:///%2e%2e/escape", true},
		{"url-encoded-upper", "file:///%2E%2E%2Fescape", true},
		{"mixed-dotdot", "file:///./../escape", true},
		{"nested-dotdot", "file:///subdir/../../escape", true},

		{"same-dir-file", "file:///hello.txt", false},
		{"subdir-file", "file:///subdir/hello.txt", false},
		{"dotfile-accepted", "file:///.hidden", false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := computeURIFilepath(tc.rawURI, root, nil)
			if tc.wantErr && err == nil {
				t.Fatalf("path-traversal invariant broken — computeURIFilepath(%q) accepted a traversal attempt. See D-19 + backlog.md §4.3 + resource.go:88.", tc.rawURI)
			}
			if !tc.wantErr && err != nil {
				t.Fatalf("valid-path invariant broken — computeURIFilepath(%q) rejected %v; expected accept. See D-19 + backlog.md §4.3.", tc.rawURI, err)
			}
		})
	}
}

// TestValidPathsAccepted is the positive-set companion to TestPathTraversalRejected.
// Valid same-dir / subdir / dotfile paths resolve without error.
//
// Rationale (per spec): separating positive from negative clarifies grep
// output when a single case fails; one function, one intent.
func TestValidPathsAccepted(t *testing.T) {
	root := filepath.Join(string(filepath.Separator), "tmp", "ftr006-traversal-test")

	cases := []struct {
		name   string
		rawURI string
	}{
		{"same-dir-file", "file:///hello.txt"},
		{"subdir-file", "file:///subdir/hello.txt"},
		{"deep-subdir", "file:///a/b/c/d/hello.txt"},
		{"dotfile", "file:///.hidden"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := computeURIFilepath(tc.rawURI, root, nil)
			if err != nil {
				t.Fatalf("valid-path invariant broken — computeURIFilepath(%q) rejected %v; expected accept. See D-19 + backlog.md §4.3.", tc.rawURI, err)
			}
		})
	}
}
