// Copyright 2026 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by the license
// that can be found in the LICENSE file.

// Package oauthex — OAuth RFC 9110 case-INsensitive invariant guard.
//
// Cross-reference HAZARD: apps/mcp-go/internal/json/json.go:22 enforces the
// opposite-polarity invariant (strict case-SENSITIVE JSON-RPC field matching
// per JSON-RPC 2.0 §5). DO NOT CONFLATE the two. JSON-RPC strict-casing rejects
// `{"Method": "initialize"}`; OAuth case-insensitivity accepts `BEARER` ==
// `bearer`. Applying the wrong rule to the wrong subsystem silently breaks
// cross-SDK compatibility (JSON-RPC) or RFC 9110 compliance (OAuth).
//
// References:
//   - D-18 (this file) in dev/mcp/features/FTR-006-mcp-server-research-preview/state.yaml
//   - backlog.md §4.2 at apps/mcp-go/docs/backlog.md
//   - RFC 9110, Section 11.6.1 (HTTP authentication challenges)
//   - Sibling invariant: internal/json/json_invariant_test.go (§4.1)

package oauthex

import "testing"

// TestAuthSchemeCaseInsensitive asserts that every case variant of the
// "Bearer" auth-scheme parses to the canonical lower-case form "bearer".
//
// Regression this guards against: accidental removal of strings.ToLower at
// resource_meta.go:229 or :303 would retain input casing in Scheme, breaking
// cross-SDK interop with RFC-9110-conforming OAuth servers.
func TestAuthSchemeCaseInsensitive(t *testing.T) {
	variants := []string{"Bearer", "bearer", "BEARER", "BeArEr", "bEaReR"}
	for _, v := range variants {
		t.Run(v, func(t *testing.T) {
			input := v + ` realm="example"`
			got, err := parseSingleChallenge(input)
			if err != nil {
				t.Fatalf("parseSingleChallenge(%q) error: %v", input, err)
			}
			if got.Scheme != "bearer" {
				t.Fatalf("case-insensitive scheme invariant broken — variant %q parsed as Scheme=%q, want %q. See D-18 in FTR-006 state.yaml + backlog.md §4.2.", v, got.Scheme, "bearer")
			}
		})
	}
}

// TestParamKeyCaseInsensitive asserts that every case variant of the param
// key "realm" normalizes to the canonical lower-case map key "realm".
//
// Regression this guards against: accidental removal of strings.ToLower at
// resource_meta.go:291 would retain input casing in Params keys, so lookups
// keyed on the RFC-documented lower-case form would miss values.
func TestParamKeyCaseInsensitive(t *testing.T) {
	variants := []string{"realm", "Realm", "REALM", "ReAlM", "rEaLm"}
	for _, v := range variants {
		t.Run(v, func(t *testing.T) {
			input := `Bearer ` + v + `="example"`
			got, err := parseSingleChallenge(input)
			if err != nil {
				t.Fatalf("parseSingleChallenge(%q) error: %v", input, err)
			}
			val, ok := got.Params["realm"]
			if !ok {
				t.Fatalf("case-insensitive param-key invariant broken — variant %q did not normalize to key %q. Got Params=%v. See D-18 + backlog.md §4.2.", v, "realm", got.Params)
			}
			if val != "example" {
				t.Fatalf("param value mismatch — got %q, want %q", val, "example")
			}
		})
	}
}

// TestCaseInsensitivityIsNotStrict is the negative-polarity companion to the
// equivalence-class tests above. It constructs an input with BOTH upper-case
// scheme and upper-case param key, then asserts that:
//  1. the canonical lower-case key is present in Params (positive), and
//  2. the pre-lowercase upper-case key is NOT present (negative), and
//  3. Scheme is normalized to lower-case.
//
// A regression that softens case-folding to a strict case-sensitive lookup
// keyed on the pre-lowercase input form would cause the second assertion to
// fail — the upper-case key would remain in Params. This fails BEFORE any
// downstream component notices the RFC 9110 violation.
func TestCaseInsensitivityIsNotStrict(t *testing.T) {
	input := `BEARER REALM="example"`
	got, err := parseSingleChallenge(input)
	if err != nil {
		t.Fatalf("parseSingleChallenge(%q) error: %v", input, err)
	}

	if _, ok := got.Params["realm"]; !ok {
		t.Fatalf("OAuth case-INsensitive invariant broken — canonical lower-case key %q missing from Params=%v (regression would lock in pre-lowercase form). See D-18 + backlog.md §4.2.", "realm", got.Params)
	}

	if _, ok := got.Params["REALM"]; ok {
		t.Fatalf("OAuth case-insensitive invariant broken — pre-lowercase key %q should have been normalized out. Params=%v. See D-18 + backlog.md §4.2.", "REALM", got.Params)
	}

	if got.Scheme != "bearer" {
		t.Fatalf("Scheme normalization broken — got %q, want %q. See D-18 + backlog.md §4.2.", got.Scheme, "bearer")
	}
}
