// Copyright 2025 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package mcp

// hasSessionID is the interface which, if implemented by connections, informs
// the session about their session ID.
//
// settled(aaw, upstream rfindley): SessionID stays exposed on connections;
// removal is an upstream interface break (see also the settled #148 note in
// transport.go), not pursued in this fork.
type hasSessionID interface {
	SessionID() string
}

// ServerSessionState is the state of a session.
type ServerSessionState struct {
	// InitializeParams are the parameters from 'initialize'.
	InitializeParams *InitializeParams `json:"initializeParams"`

	// InitializedParams are the parameters from 'notifications/initialized'.
	InitializedParams *InitializedParams `json:"initializedParams"`

	// LogLevel is the logging level for the session.
	LogLevel LoggingLevel `json:"logLevel"`

	// settled(aaw): resource-subscription state is an upstream feature gap;
	// not pursued in this fork.
}
