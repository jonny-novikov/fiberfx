// Copyright 2025 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// The streamable HTTP transport is split across three files:
//   - streamable.go (this file): shared header-name constants used by both
//     sides.
//   - streamable_server.go: server-side handler, transport, connection, and
//     stream types.
//   - streamable_client.go: client-side transport and connection types.

package mcp

const (
	protocolVersionHeader = "Mcp-Protocol-Version"
	sessionIDHeader       = "Mcp-Session-Id"
	lastEventIDHeader     = "Last-Event-ID"
)
