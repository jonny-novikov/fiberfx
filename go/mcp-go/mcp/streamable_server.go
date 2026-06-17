// Copyright 2025 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package mcp

/*
Streamable HTTP Server Design

This document describes the server-side implementation of the MCP streamable
HTTP transport, as defined by the MCP spec:
https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#streamable-http

# Overview

The streamable HTTP transport enables MCP communication over HTTP, with
server-sent events (SSE) for server-to-client messages. The implementation
consists of several layered components:

	┌─────────────────────────────────────────────────────────────────┐
	│                   [StreamableHTTPHandler]                       │
	│   http.Handler that manages sessions and routes HTTP requests   │
	└─────────────────────────────────────────────────────────────────┘
	                              │
	                              ▼
	┌─────────────────────────────────────────────────────────────────┐
	│                  [StreamableServerTransport]                    │
	│  transport implementation, one per session; exposes ServeHTTP   │
	└─────────────────────────────────────────────────────────────────┘
	                              │
	                              ▼
	┌─────────────────────────────────────────────────────────────────┐
	│                   [streamableServerConn]                        │
	│        Connection implementation, handles message routing       │
	└─────────────────────────────────────────────────────────────────┘
	                              │
	                              ▼
	┌─────────────────────────────────────────────────────────────────┐
	│                         [stream]                                │
	│   Logical message channel within a session, may be resumed      │
	└─────────────────────────────────────────────────────────────────┘

# Sessions

As with other transports, a session represents a logical MCP connection between
a client and server. In the streamable transport, sessions are identified by a
unique session ID (Mcp-Session-Id header) and persist across multiple HTTP
requests.

[StreamableHTTPHandler] maintains a map of active sessions ([sessionInfo]),
each containing:
  - The [ServerSession] (MCP-level session state)
  - The [StreamableServerTransport] (for message I/O)
  - Optional timeout management for idle session cleanup

Sessions are created on the first POST request (typically containing the
initialize request) and destroyed either by:
  - Client sending a DELETE request
  - Session timeout due to inactivity
  - Server explicitly closing the session

# Streams

Within a session, there can be multiple concurrent "streams" - logical channels
for message delivery. This is distinct from HTTP streams; a single [stream] may
span multiple HTTP request/response cycles (via resumption).

There are two types of streams:

1. Optional standalone SSE stream (id = ""):
   - Created when client sends a GET request to the endpoint
   - Used for server-initiated messages (requests/notifications to client)
   - Persists for the lifetime of the session
   - Only one standalone stream per session

2. Request streams (id = random string):
   - Created for each POST request containing JSON-RPC calls
   - Used to route responses back to the originating HTTP request
   - Completed when all responses have been sent
   - Can be resumed via GET with Last-Event-ID if interrupted

# Message Routing

When the server writes a message, it must be routed to the correct [stream]:

  - Responses: Routed to the stream that originated the request
  - Requests/Notifications made during request handling: Routed to the same
    stream as the triggering request (via context)
  - Requests/Notifications made outside request handling: Routed to the
    standalone SSE stream

This routing is implemented using:
  - [streamableServerConn.requestStreams] maps request IDs to stream IDs
  - [idContextKey] is used to store the originating request ID in Context
  - [streamableServerConn.streams] maps stream IDs to [stream] objects

# Stream Resumption

If an HTTP connection is interrupted (network issues, etc.), clients can
resume a stream by sending a GET request with the Last-Event-ID header.
This requires an [EventStore] to be configured on the server.

  - [EventStore.Open] is called when a new stream is created
  - [EventStore.Append] is called for each message written to the stream
  - [EventStore.After] is called to replay messages after a given index
  - [EventStore.SessionClosed] is called when the session ends

Event IDs are formatted as "<streamID>_<index>" to identify both the
stream and position within that stream (see [formatEventID] and [parseEventID]).

# Stateless Mode

For simpler deployments, the handler supports "stateless" mode
([StreamableHTTPOptions.Stateless]) where:
  - No session ID validation is performed
  - Each request creates a temporary session that's closed after the request
  - Server-to-client requests are not supported (no way to receive response)

This mode is useful for simple tool servers that don't need bidirectional
communication.

# Response Formats

The server can respond to POST requests in two formats:

1. text/event-stream (default): Messages sent as SSE events, supports
   streaming multiple messages and server-initiated communication during
   request handling.

2. application/json ([StreamableHTTPOptions.JSONResponse]): Single JSON
   response, simpler but doesn't support streaming. Server-initiated messages
   during request handling go to the standalone SSE stream instead.

# HTTP Methods

  - POST: Send JSON-RPC messages (requests, responses, notifications)
  - GET: Open standalone SSE stream or resume an interrupted stream
  - DELETE: Terminate the session

# Key Implementation Details

The [stream] struct manages delivery of messages to HTTP responses.

Fields:
  - [stream.w] is the ResponseWriter for the current HTTP response (non-nil indicates claimed)
  - [stream.done] is closed to release the hanging HTTP request
  - [stream.requests] tracks pending request IDs (stream completes when empty)

Methods:
  - [stream.deliverLocked] delivers a message to the stream
  - [stream.close] sends a close event and releases the stream
  - [stream.release] releases the stream from the HTTP request, allowing resumption

[streamableServerConn] handles the [Connection] interface:
  - [streamableServerConn.Read] receives messages from the incoming channel (fed by POST handlers)
  - [streamableServerConn.Write] routes messages to appropriate streams
  - [streamableServerConn.Close] terminates the session and notifies the [EventStore]
*/

import (
	"bytes"
	"context"
	crand "crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"maps"
	"mime"
	"net"
	"net/http"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/fiberfx/mcp-go/v2/auth"
	internaljson "github.com/fiberfx/mcp-go/v2/internal/json"
	"github.com/fiberfx/mcp-go/v2/internal/jsonrpc2"
	"github.com/fiberfx/mcp-go/v2/internal/mcpgodebug"
	"github.com/fiberfx/mcp-go/v2/internal/util"
	"github.com/fiberfx/mcp-go/v2/jsonrpc"
)

// A StreamableHTTPHandler is an http.Handler that serves streamable MCP
// sessions, as defined by the [MCP spec].
//
// [MCP spec]: https://modelcontextprotocol.io/2025/03/26/streamable-http-transport.html
type StreamableHTTPHandler struct {
	getServer func(*http.Request) *Server
	opts      StreamableHTTPOptions

	onTransportDeletion func(sessionID string) // for testing

	mu       sync.Mutex
	sessions map[string]*sessionInfo // keyed by session ID
}

type sessionInfo struct {
	session   *ServerSession
	transport *StreamableServerTransport
	// userID is the user ID from the TokenInfo when the session was created.
	// If non-empty, subsequent requests must have the same user ID to prevent
	// session hijacking.
	userID string

	// If timeout is set, automatically close the session after an idle period.
	timeout time.Duration
	timerMu sync.Mutex
	refs    int // reference count
	timer   *time.Timer
}

// startPOST signals that a POST request for this session is starting (which
// carries a client->server message), pausing the session timeout if it was
// running.
//
// settled(aaw): the timer is not paused when resuming non-standalone SSE
// streams (tricky to implement); clients should generally make keepalive
// pings if they want to keep the session live.
func (i *sessionInfo) startPOST() {
	if i.timeout <= 0 {
		return
	}

	i.timerMu.Lock()
	defer i.timerMu.Unlock()

	if i.timer == nil {
		return // timer stopped permanently
	}
	if i.refs == 0 {
		i.timer.Stop()
	}
	i.refs++
}

// endPOST signals that a request for this session is ending, starting the
// timeout if there are no other requests running.
func (i *sessionInfo) endPOST() {
	if i.timeout <= 0 {
		return
	}

	i.timerMu.Lock()
	defer i.timerMu.Unlock()

	if i.timer == nil {
		return // timer stopped permanently
	}

	i.refs--
	assert(i.refs >= 0, "negative ref count")
	if i.refs == 0 {
		i.timer.Reset(i.timeout)
	}
}

// stopTimer stops the inactivity timer permanently.
func (i *sessionInfo) stopTimer() {
	i.timerMu.Lock()
	defer i.timerMu.Unlock()
	if i.timer != nil {
		i.timer.Stop()
		i.timer = nil
	}
}

// StreamableHTTPOptions configures the StreamableHTTPHandler.
type StreamableHTTPOptions struct {
	// Stateless controls whether the session is 'stateless'.
	//
	// A stateless server does not validate the Mcp-Session-Id header, and uses a
	// temporary session with default initialization parameters. Any
	// server->client request is rejected immediately as there's no way for the
	// client to respond. Server->Client notifications may reach the client if
	// they are made in the context of an incoming request, as described in the
	// documentation for [StreamableServerTransport].
	Stateless bool

	// settled(aaw, upstream #148): session retention not pursued — this fork
	// serves a single local aaw instance.

	// JSONResponse causes streamable responses to return application/json rather
	// than text/event-stream ([§2.1.5] of the spec).
	//
	// [§2.1.5]: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#sending-messages-to-the-server
	JSONResponse bool

	// Logger specifies the logger to use.
	// If nil, do not log.
	Logger *slog.Logger

	// EventStore enables stream resumption.
	//
	// If set, EventStore will be used to persist stream events and replay them
	// upon stream resumption.
	EventStore EventStore

	// SessionTimeout configures a timeout for idle sessions.
	//
	// When sessions receive no new HTTP requests from the client for this
	// duration, they are automatically closed.
	//
	// If SessionTimeout is the zero value, idle sessions are never closed.
	SessionTimeout time.Duration

	// DisableLocalhostProtection disables automatic DNS rebinding protection.
	// By default, requests arriving via a localhost address (127.0.0.1, [::1])
	// that have a non-localhost Host header are rejected with 403 Forbidden.
	// This protects against DNS rebinding attacks regardless of whether the
	// server is listening on localhost specifically or on 0.0.0.0.
	//
	// Only disable this if you understand the security implications.
	// See: https://modelcontextprotocol.io/specification/2025-11-25/basic/security_best_practices#local-mcp-server-compromise
	DisableLocalhostProtection bool

	// CrossOriginProtection allows to customize cross-origin protection.
	// The deny handler set in the CrossOriginProtection through SetDenyHandler
	// is ignored.
	// If nil, default (zero-value) cross-origin protection will be used.
	// Use `disablecrossoriginprotection` MCPGODEBUG compatibility parameter
	// to disable the default protection until v1.7.0.
	CrossOriginProtection *http.CrossOriginProtection
}

// NewStreamableHTTPHandler returns a new [StreamableHTTPHandler].
//
// The getServer function is used to create or look up servers for new
// sessions. It is OK for getServer to return the same server multiple times.
// If getServer returns nil, a 400 Bad Request will be served.
func NewStreamableHTTPHandler(getServer func(*http.Request) *Server, opts *StreamableHTTPOptions) *StreamableHTTPHandler {
	h := &StreamableHTTPHandler{
		getServer: getServer,
		sessions:  make(map[string]*sessionInfo),
	}
	if opts != nil {
		h.opts = *opts
	}

	h.opts.Logger = ensureLogger(h.opts.Logger)

	if h.opts.CrossOriginProtection == nil {
		h.opts.CrossOriginProtection = &http.CrossOriginProtection{}
	}

	return h
}

// closeAll closes all ongoing sessions, for tests.
//
// settled(aaw, upstream rfindley): a caller-configurable session-lifecycle
// API (e.g. a pluggable session store enabling a stateless handler) is an
// upstream design question, not pursued in this fork.
func (h *StreamableHTTPHandler) closeAll() {
	// settled(aaw): closeAll stays test-only; exposing it would require
	// preventing new sessions from being added, beyond simply collecting
	// sessions while holding the lock.
	//
	// Currently, sessions remove themselves from h.sessions when closed, so we
	// can't call Close while holding the lock.
	h.mu.Lock()
	sessionInfos := slices.Collect(maps.Values(h.sessions))
	h.sessions = nil
	h.mu.Unlock()
	for _, s := range sessionInfos {
		s.session.Close(context.Background())
	}
}

// disablelocalhostprotection is a compatibility parameter that allows to disable
// DNS rebinding protection, which was added in the 1.4.0 version of the SDK.
// See the documentation for the mcpgodebug package for instructions how to enable it.
// The option will be removed in the 1.7.0 version of the SDK.
var disablelocalhostprotection = mcpgodebug.Value("disablelocalhostprotection")

// disablecrossoriginprotection is a compatibility parameter that allows to disable
// the verification of the 'Origin' and 'Content-Type' headers, which was added in
// the 1.4.1 version of the SDK. See the documentation for the mcpgodebug package
// for instructions how to enable it.
// The option will be removed in the 1.7.0 version of the SDK.
var disablecrossoriginprotection = mcpgodebug.Value("disablecrossoriginprotection")

func (h *StreamableHTTPHandler) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	// DNS rebinding protection: auto-enabled for localhost servers.
	// See: https://modelcontextprotocol.io/specification/2025-11-25/basic/security_best_practices#local-mcp-server-compromise
	if !h.opts.DisableLocalhostProtection && disablelocalhostprotection != "1" {
		if localAddr, ok := req.Context().Value(http.LocalAddrContextKey).(net.Addr); ok && localAddr != nil {
			if util.IsLoopback(localAddr.String()) && !util.IsLoopback(req.Host) {
				http.Error(w, fmt.Sprintf("Forbidden: invalid Host header %q", req.Host), http.StatusForbidden)
				return
			}
		}
	}

	if disablecrossoriginprotection != "1" {
		// Verify the 'Origin' header to protect against CSRF attacks.
		if err := h.opts.CrossOriginProtection.Check(req); err != nil {
			http.Error(w, err.Error(), http.StatusForbidden)
			return
		}
		// Validate 'Content-Type' header.
		if req.Method == http.MethodPost {
			mediaType, _, err := mime.ParseMediaType(req.Header.Get("Content-Type"))
			if err != nil || mediaType != "application/json" {
				http.Error(w, "Content-Type must be 'application/json'", http.StatusUnsupportedMediaType)
				return
			}
		}
	}

	// Allow multiple 'Accept' headers.
	// https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept#syntax
	jsonOK, streamOK := streamableAccepts(req.Header.Values("Accept"))

	if req.Method == http.MethodGet {
		if !streamOK {
			http.Error(w, "Accept must contain 'text/event-stream' for GET requests", http.StatusBadRequest)
			return
		}
	} else if (!jsonOK || !streamOK) && req.Method != http.MethodDelete { // settled(aaw): consolidation with the method handling below is refactor churn, not pursued in this fork.
		http.Error(w, "Accept must contain both 'application/json' and 'text/event-stream'", http.StatusBadRequest)
		return
	}

	sessionID := req.Header.Get(sessionIDHeader)
	var sessInfo *sessionInfo
	if sessionID != "" {
		h.mu.Lock()
		sessInfo = h.sessions[sessionID]
		h.mu.Unlock()
		if sessInfo == nil && !h.opts.Stateless {
			// Unless we're in 'stateless' mode, which doesn't perform any Session-ID
			// validation, we require that the session ID matches a known session.
			//
			// In stateless mode, a temporary transport is be created below.
			http.Error(w, "session not found", http.StatusNotFound)
			return
		}
		// Prevent session hijacking: if the session was created with a user ID,
		// verify that subsequent requests come from the same user.
		if sessInfo != nil && sessInfo.userID != "" {
			tokenInfo := auth.TokenInfoFromContext(req.Context())
			if tokenInfo == nil || tokenInfo.UserID != sessInfo.userID {
				http.Error(w, "session user mismatch", http.StatusForbidden)
				return
			}
		}
	}

	if req.Method == http.MethodDelete {
		if sessionID == "" {
			http.Error(w, "Bad Request: DELETE requires an Mcp-Session-Id header", http.StatusBadRequest)
			return
		}
		if sessInfo != nil { // sessInfo may be nil in stateless mode
			// Closing the session also removes it from h.sessions, due to the
			// onClose callback.
			sessInfo.session.Close(context.WithoutCancel(req.Context()))
		}
		w.WriteHeader(http.StatusNoContent)
		return
	}

	switch req.Method {
	case http.MethodPost, http.MethodGet:
		if req.Method == http.MethodGet && (h.opts.Stateless || sessionID == "") {
			if h.opts.Stateless {
				// Per MCP spec: server MUST return 405 if it doesn't offer SSE stream.
				// In stateless mode, GET (SSE streaming) is not supported.
				// RFC 9110 §15.5.6: 405 responses MUST include Allow header.
				w.Header().Set("Allow", "POST")
				http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			} else {
				// In stateful mode, GET is supported but requires a session ID.
				// This is a precondition error, similar to DELETE without session.
				http.Error(w, "Bad Request: GET requires an Mcp-Session-Id header", http.StatusBadRequest)
			}
			return
		}
	default:
		// RFC 9110 §15.5.6: 405 responses MUST include Allow header.
		if h.opts.Stateless {
			w.Header().Set("Allow", "POST")
		} else {
			w.Header().Set("Allow", "GET, POST, DELETE")
		}
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	// [§2.7] of the spec (2025-06-18) states:
	//
	// "If using HTTP, the client MUST include the MCP-Protocol-Version:
	// <protocol-version> HTTP header on all subsequent requests to the MCP
	// server, allowing the MCP server to respond based on the MCP protocol
	// version.
	//
	// For example: MCP-Protocol-Version: 2025-06-18
	// The protocol version sent by the client SHOULD be the one negotiated during
	// initialization.
	//
	// For backwards compatibility, if the server does not receive an
	// MCP-Protocol-Version header, and has no other way to identify the version -
	// for example, by relying on the protocol version negotiated during
	// initialization - the server SHOULD assume protocol version 2025-03-26.
	//
	// If the server receives a request with an invalid or unsupported
	// MCP-Protocol-Version, it MUST respond with 400 Bad Request."
	//
	// Since this wasn't present in the 2025-03-26 version of the spec, this
	// effectively means:
	//  1. IF the client provides a version header, it must be a supported
	//     version.
	//  2. In stateless mode, where we've lost the state of the initialize
	//     request, we assume that whatever the client tells us is the truth (or
	//     assume 2025-03-26 if the client doesn't say anything).
	//
	// This logic matches the typescript SDK.
	//
	// [§2.7]: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#protocol-version-header
	protocolVersion := req.Header.Get(protocolVersionHeader)
	if protocolVersion == "" {
		protocolVersion = protocolVersion20250326
	}
	if !slices.Contains(supportedProtocolVersions, protocolVersion) {
		http.Error(w, fmt.Sprintf("Bad Request: Unsupported protocol version (supported versions: %s)", strings.Join(supportedProtocolVersions, ",")), http.StatusBadRequest)
		return
	}

	if sessInfo == nil {
		server := h.getServer(req)
		if server == nil {
			// The getServer argument to NewStreamableHTTPHandler returned nil.
			http.Error(w, "no server available", http.StatusBadRequest)
			return
		}
		if sessionID == "" {
			// In stateless mode, sessionID may be nonempty even if there's no
			// existing transport.
			sessionID = server.opts.GetSessionID()
		}
		transport := &StreamableServerTransport{
			SessionID:    sessionID,
			Stateless:    h.opts.Stateless,
			EventStore:   h.opts.EventStore,
			jsonResponse: h.opts.JSONResponse,
			logger:       h.opts.Logger,
		}

		// Sessions without a session ID are also stateless: there's no way to
		// address them.
		stateless := h.opts.Stateless || sessionID == ""
		// To support stateless mode, we initialize the session with a default
		// state, so that it doesn't reject subsequent requests.
		var connectOpts *ServerSessionOptions
		if stateless {
			// Peek at the body to see if it is initialize or initialized.
			// We want those to be handled as usual.
			var hasInitialize, hasInitialized bool
			{
				// settled(aaw): protocol-version negotiation for stateless servers
				// is unverified upstream; behavior kept as-is.
				body, err := io.ReadAll(req.Body)
				if err != nil {
					http.Error(w, "failed to read body", http.StatusBadRequest)
					return
				}
				req.Body.Close()

				// Reset the body so that it can be read later.
				req.Body = io.NopCloser(bytes.NewBuffer(body))

				msgs, _, err := readBatch(body)
				if err == nil {
					for _, msg := range msgs {
						if req, ok := msg.(*jsonrpc.Request); ok {
							switch req.Method {
							case methodInitialize:
								hasInitialize = true
							case notificationInitialized:
								hasInitialized = true
							}
						}
					}
				}
			}

			// If we don't have InitializeParams or InitializedParams in the request,
			// set the initial state to a default value.
			state := new(ServerSessionState)
			if !hasInitialize {
				state.InitializeParams = &InitializeParams{
					ProtocolVersion: protocolVersion,
				}
			}
			if !hasInitialized {
				state.InitializedParams = new(InitializedParams)
			}
			state.LogLevel = "info"
			connectOpts = &ServerSessionOptions{
				State: state,
			}
		} else {
			// Cleanup is only required in stateful mode, as transportation is
			// not stored in the map otherwise.
			connectOpts = &ServerSessionOptions{
				onClose: func() {
					h.mu.Lock()
					defer h.mu.Unlock()
					if info, ok := h.sessions[transport.SessionID]; ok {
						info.stopTimer()
						delete(h.sessions, transport.SessionID)
						if h.onTransportDeletion != nil {
							h.onTransportDeletion(transport.SessionID)
						}
					}
				},
			}
		}

		// Pass req.Context() here, to allow middleware to add context values.
		// The context is detached in the jsonrpc2 library when handling the
		// long-running stream.
		session, err := server.Connect(req.Context(), transport, connectOpts)
		if err != nil {
			http.Error(w, "failed connection", http.StatusInternalServerError)
			return
		}
		// Capture the user ID from the token info to enable session hijacking
		// prevention on subsequent requests.
		var userID string
		if tokenInfo := auth.TokenInfoFromContext(req.Context()); tokenInfo != nil {
			userID = tokenInfo.UserID
		}
		sessInfo = &sessionInfo{
			session:   session,
			transport: transport,
			userID:    userID,
		}

		if stateless {
			// Stateless mode: close the session when the request exits.
			defer session.Close(context.WithoutCancel(req.Context())) // close the fake session after handling the request
		} else {
			// Otherwise, save the transport so that it can be reused

			// Clean up the session when it times out.
			//
			// Note that the timer here may fire multiple times, but
			// sessInfo.session.Close is idempotent.
			if h.opts.SessionTimeout > 0 {
				sessInfo.timeout = h.opts.SessionTimeout
				sessInfo.timer = time.AfterFunc(sessInfo.timeout, func() {
					sessInfo.session.Close(context.Background())
				})
			}
			h.mu.Lock()
			h.sessions[transport.SessionID] = sessInfo
			h.mu.Unlock()
			defer func() {
				// If initialization failed, clean up the session (#578).
				if session.InitializeParams() == nil {
					// Initialization failed.
					session.Close(context.WithoutCancel(req.Context()))
				}
			}()
		}
	}

	if req.Method == http.MethodPost {
		sessInfo.startPOST()
		defer sessInfo.endPOST()
	}

	sessInfo.transport.ServeHTTP(w, req)
}

func streamableAccepts(values []string) (jsonOK, streamOK bool) {
	for _, value := range values {
		for _, raw := range strings.Split(value, ",") {
			token := strings.TrimSpace(raw)
			// Ignore Accept parameters like ";charset=utf-8"; match the base media type.
			base, _, _ := strings.Cut(token, ";")
			switch strings.ToLower(strings.TrimSpace(base)) {
			case "application/json", "application/*":
				jsonOK = true
			case "text/event-stream", "text/*":
				streamOK = true
			case "*/*":
				jsonOK = true
				streamOK = true
			}
		}
	}
	return jsonOK, streamOK
}

// A StreamableServerTransport implements the server side of the MCP streamable
// transport.
//
// Each StreamableServerTransport must be connected (via [Server.Connect]) at
// most once, since [StreamableServerTransport.ServeHTTP] serves messages to
// the connected session.
//
// Reads from the streamable server connection receive messages from http POST
// requests from the client. Writes to the streamable server connection are
// sent either to the related stream, or to the standalone SSE stream,
// according to the following rules:
//   - JSON-RPC responses to incoming requests are always routed to the
//     appropriate HTTP response.
//   - Requests or notifications made with a context.Context value derived from
//     an incoming request handler, are routed to the HTTP response
//     corresponding to that request, unless it has already terminated, in
//     which case they are routed to the standalone SSE stream.
//   - Requests or notifications made with a detached context.Context value are
//     routed to the standalone SSE stream.
type StreamableServerTransport struct {
	// SessionID is the ID of this session.
	//
	// If SessionID is the empty string, this is a 'stateless' session, which has
	// limited ability to communicate with the client. Otherwise, the session ID
	// must be globally unique, that is, different from any other session ID
	// anywhere, past and future. (We recommend using a crypto random number
	// generator to produce one, as with [crypto/rand.Text].)
	SessionID string

	// Stateless controls whether the eventstore is 'Stateless'. Server sessions
	// connected to a stateless transport are disallowed from making outgoing
	// requests.
	//
	// See also [StreamableHTTPOptions.Stateless].
	Stateless bool

	// EventStore enables stream resumption.
	//
	// If set, EventStore will be used to persist stream events and replay them
	// upon stream resumption.
	EventStore EventStore

	// jsonResponse, if set, tells the server to prefer to respond to requests
	// using application/json responses rather than text/event-stream.
	//
	// Specifically, responses will be application/json whenever incoming POST
	// request contain only a single message. In this case, notifications or
	// requests made within the context of a server request will be sent to the
	// standalone SSE stream, if any.
	//
	// settled(aaw, upstream rfindley): jsonResponse stays unexported even
	// though StreamableHTTPOptions.JSONResponse is exported; an exported
	// custom-handler surface is an upstream API proposal, not pursued in this
	// fork.
	jsonResponse bool

	// optional logger provided through the [StreamableHTTPOptions.Logger].
	//
	// settled(aaw, upstream rfindley): logger stays unexported; same
	// custom-handler API proposal as jsonResponse above.
	logger *slog.Logger

	// connection is non-nil if and only if the transport has been connected.
	connection *streamableServerConn
}

// Connect implements the [Transport] interface.
func (t *StreamableServerTransport) Connect(ctx context.Context) (Connection, error) {
	if t.connection != nil {
		return nil, fmt.Errorf("transport already connected")
	}
	t.connection = &streamableServerConn{
		sessionID:      t.SessionID,
		stateless:      t.Stateless,
		eventStore:     t.EventStore,
		jsonResponse:   t.jsonResponse,
		logger:         ensureLogger(t.logger), // see #556: must be non-nil
		incoming:       make(chan jsonrpc.Message, 10),
		done:           make(chan struct{}),
		streams:        make(map[string]*stream),
		requestStreams: make(map[jsonrpc.ID]string),
	}
	// Stream 0 corresponds to the standalone SSE stream.
	//
	// It is always text/event-stream, since it must carry arbitrarily many
	// messages.
	var err error
	t.connection.streams[""], err = t.connection.newStream(ctx, nil, "")
	if err != nil {
		return nil, err
	}
	return t.connection, nil
}

type streamableServerConn struct {
	sessionID    string
	stateless    bool
	jsonResponse bool
	eventStore   EventStore

	logger *slog.Logger

	incoming chan jsonrpc.Message // messages from the client to the server

	mu sync.Mutex // guards all fields below

	// Sessions are closed exactly once.
	isDone bool
	done   chan struct{}

	// Sessions can have multiple logical connections (which we call streams),
	// corresponding to HTTP requests. Additionally, streams may be resumed by
	// subsequent HTTP requests, when the HTTP connection is terminated
	// unexpectedly.
	//
	// Therefore, we use a logical stream ID to key the stream state, and
	// perform the accounting described below when incoming HTTP requests are
	// handled.

	// streams holds the logical streams for this session, keyed by their ID.
	//
	// Lifecycle: streams persist until all of their responses are received from
	// the server.
	streams map[string]*stream

	// requestStreams maps incoming requests to their logical stream ID.
	//
	// Lifecycle: requestStreams persist until their response is received.
	requestStreams map[jsonrpc.ID]string
}

func (c *streamableServerConn) SessionID() string {
	return c.sessionID
}

// A stream is a single logical stream of SSE events within a server session.
// A stream begins with a client request, or with a client GET that has
// no Last-Event-ID header.
//
// A stream ends only when its session ends; we cannot determine its end otherwise,
// since a client may send a GET with a Last-Event-ID that references the stream
// at any time.
type stream struct {
	// id is the logical ID for the stream, unique within a session.
	//
	// The standalone SSE stream has id "".
	id string

	// logger is used for logging errors during stream operations.
	logger *slog.Logger

	// mu guards the fields below, as well as storage of new messages in the
	// connection's event store (if any).
	mu sync.Mutex

	// If pendingJSONMessages is non-nil, this is a JSON stream and messages are
	// collected here until the stream is complete, at which point they are
	// flushed as a single JSON response. Note that the non-nilness of this field
	// is significant, as it signals the expected content type.
	//
	// Note: if we remove support for batching, this could just be a bool.
	pendingJSONMessages []json.RawMessage

	// w is the HTTP response writer for this stream. A non-nil w indicates
	// that the stream is claimed by an HTTP request (the hanging POST or GET);
	// it is set to nil when the request completes.
	w http.ResponseWriter

	// done is closed to release the hanging HTTP request.
	//
	// Invariant: a non-nil done implies w is also non-nil, though the converse
	// is not necessarily true: done is set to nil when it is closed, to avoid
	// duplicate closure.
	done chan struct{}

	// lastIdx is the index of the last written SSE event, for event ID generation.
	// It starts at -1 since indices start at 0.
	lastIdx int

	// protocolVersion is the protocol version for this stream.
	protocolVersion string

	// requests is the set of unanswered incoming requests for the stream.
	//
	// Requests are removed when their response has been received.
	// In practice, there is only one request, but in the 2025-03-26 version of
	// the spec and earlier there was a concept of batching, in which POST
	// payloads could hold multiple requests or responses.
	requests map[jsonrpc.ID]struct{}
}

// close sends a 'close' event to the client (if protocolVersion >= 2025-11-25
// and reconnectAfter > 0) and closes the done channel.
//
// The done channel is set to nil after closing, so that done != nil implies
// the stream is active and done is open. This simplifies checks elsewhere.
func (s *stream) close(reconnectAfter time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.done == nil {
		return // stream not connected or already closed
	}
	if s.protocolVersion >= protocolVersion20251125 && reconnectAfter > 0 {
		reconnectStr := strconv.FormatInt(reconnectAfter.Milliseconds(), 10)
		if _, err := writeEvent(s.w, Event{
			Name:  "close",
			Retry: reconnectStr,
		}); err != nil {
			s.logger.Warn(fmt.Sprintf("Writing close event: %v", err))
		}
	}
	close(s.done)
	s.done = nil
}

// release releases the stream from its HTTP request, allowing it to be
// claimed by another request (e.g., for resumption).
func (s *stream) release() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.w = nil
	s.done = nil // may already be nil, if the stream is done or closed
}

// deliverLocked writes data to the stream (for SSE) or stores it in
// pendingJSONMessages (for JSON mode). The eventID is used for SSE event ID;
// pass "" to omit.
//
// If responseTo is valid, it is removed from the requests map. When all
// requests have been responded to, the done channel is closed and set to nil.
//
// Returns true if the stream is now done (all requests have been responded to).
// The done value is always accurate, even if an error is returned.
//
// s.mu must be held when calling this method.
func (s *stream) deliverLocked(data []byte, eventID string, responseTo jsonrpc.ID) (done bool, err error) {
	// First, record the response. We must do this *before* returning an error
	// below, as even if the stream is disconnected we want to update our
	// accounting.
	if responseTo.IsValid() {
		delete(s.requests, responseTo)
	}
	// Now, try to deliver the message to the client.
	done = len(s.requests) == 0 && s.id != ""
	if s.done == nil {
		return done, fmt.Errorf("stream not connected or already closed")
	}
	if done {
		defer func() { close(s.done); s.done = nil }()
	}
	// Try to write to the response.
	//
	// If we get here, the request is still hanging (because s.done != nil
	// implies s.w != nil), but may have been cancelled by the client/http layer:
	// there's a brief race between request cancellation and releasing the
	// stream.
	if s.pendingJSONMessages != nil {
		s.pendingJSONMessages = append(s.pendingJSONMessages, data)
		if done {
			// Flush all pending messages as JSON response.
			var toWrite []byte
			if len(s.pendingJSONMessages) == 1 {
				toWrite = s.pendingJSONMessages[0]
			} else {
				toWrite, err = json.Marshal(s.pendingJSONMessages)
				if err != nil {
					return done, err
				}
			}
			if _, err := s.w.Write(toWrite); err != nil {
				return done, err
			}
		}
	} else {
		// SSE mode: write event to response writer.
		s.lastIdx++
		if _, err := writeEvent(s.w, Event{Name: "message", Data: data, ID: eventID}); err != nil {
			return done, err
		}
	}
	return done, nil
}

// doneLocked reports whether the stream is logically complete.
//
// s.requests was populated when reading the POST body, requests are deleted as
// they are responded to. Once all requests have been responded to, the stream
// is done.
//
// s.mu must be held while calling this function.
func (s *stream) doneLocked() bool {
	return len(s.requests) == 0 && s.id != ""
}

func (c *streamableServerConn) newStream(ctx context.Context, requests map[jsonrpc.ID]struct{}, id string) (*stream, error) {
	if c.eventStore != nil {
		if err := c.eventStore.Open(ctx, c.sessionID, id); err != nil {
			return nil, err
		}
	}
	return &stream{
		id:       id,
		requests: requests,
		lastIdx:  -1, // indices start at 0, incremented before each write
		logger:   c.logger,
	}, nil
}

// We track the incoming request ID inside the handler context using
// idContextValue, so that notifications and server->client calls that occur in
// the course of handling incoming requests are correlated with the incoming
// request that caused them, and can be dispatched as server-sent events to the
// correct HTTP request.
//
// Currently, this is implemented in [ServerSession.handle]. This is not ideal,
// because it means that a user of the MCP package couldn't implement the
// streamable transport, as they'd lack this privileged access.
//
// If we ever wanted to expose this mechanism, we have a few options:
//  1. Make ServerSession an interface, and provide an implementation of
//     ServerSession to handlers that closes over the incoming request ID.
//  2. Expose a 'HandlerTransport' interface that allows transports to provide
//     a handler middleware, so that we don't hard-code this behavior in
//     ServerSession.handle.
//  3. Add a `func ForRequest(context.Context) jsonrpc.ID` accessor that lets
//     any transport access the incoming request ID.
//
// For now, by giving only the StreamableServerTransport access to the request
// ID, we avoid having to make this API decision.
type idContextKey struct{}

// ServeHTTP handles a single HTTP request for the session.
func (t *StreamableServerTransport) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	if t.connection == nil {
		http.Error(w, "transport not connected", http.StatusInternalServerError)
		return
	}
	switch req.Method {
	case http.MethodGet:
		t.connection.serveGET(w, req)
	case http.MethodPost:
		t.connection.servePOST(w, req)
	default:
		// Should not be reached, as this is checked in StreamableHTTPHandler.ServeHTTP.
		w.Header().Set("Allow", "GET, POST")
		http.Error(w, "unsupported method", http.StatusMethodNotAllowed)
		return
	}
}

// serveGET streams messages to a hanging http GET, with stream ID and last
// message parsed from the Last-Event-ID header.
//
// It returns an HTTP status code and error message.
func (c *streamableServerConn) serveGET(w http.ResponseWriter, req *http.Request) {
	// streamID "" corresponds to the default GET request.
	streamID := ""
	// By default, we haven't seen a last index. Since indices start at 0, we represent
	// that by -1. This is incremented just before each event is written.
	lastIdx := -1
	if len(req.Header.Values(lastEventIDHeader)) > 0 {
		eid := req.Header.Get(lastEventIDHeader)
		var ok bool
		streamID, lastIdx, ok = parseEventID(eid)
		if !ok {
			http.Error(w, fmt.Sprintf("malformed Last-Event-ID %q", eid), http.StatusBadRequest)
			return
		}
		if c.eventStore == nil {
			http.Error(w, "stream replay unsupported", http.StatusBadRequest)
			return
		}
	}

	ctx := req.Context()

	// Read the protocol version from the header. For GET requests, this should
	// always be present since GET only happens after initialization.
	protocolVersion := req.Header.Get(protocolVersionHeader)
	if protocolVersion == "" {
		protocolVersion = protocolVersion20250326
	}

	stream, done := c.acquireStream(ctx, w, streamID, lastIdx, protocolVersion)
	if stream == nil {
		return
	}
	defer stream.release()
	c.hangResponse(ctx, done)
}

// hangResponse blocks the HTTP response until one of three conditions is met:
//   - ctx is cancelled (the client disconnected or the request timed out)
//   - done is closed (all responses have been sent, or the stream was explicitly closed)
//   - the session is closed
//
// This keeps the HTTP connection open so that server-sent events can be
// written to the response.
func (c *streamableServerConn) hangResponse(ctx context.Context, done <-chan struct{}) {
	select {
	case <-ctx.Done():
	case <-done:
	case <-c.done:
	}
}

// acquireStream replays all events since lastIdx, and acquires the ongoing
// stream, if any. If non-nil, the resulting stream will be registered for
// receiving new messages, and the stream's done channel will be closed when
// all related messages have been delivered.
//
// If any errors occur, they will be written to w and the resulting stream will
// be nil. The resulting stream may also be nil if the stream is complete.
//
// Importantly, this function must hold the stream mutex until done replaying
// all messages, so that no delivery or storage of new messages occurs while
// the stream is still replaying.
//
// protocolVersion is the protocol version for this stream, used to determine
// feature support (e.g. prime and close events were added in 2025-11-25).
func (c *streamableServerConn) acquireStream(ctx context.Context, w http.ResponseWriter, streamID string, lastIdx int, protocolVersion string) (*stream, chan struct{}) {
	// if tempStream is set, the stream is done and we're just replaying messages.
	//
	// We record a temporary stream to claim exclusive replay rights. The spec
	// (https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#resumability-and-redelivery)
	// does not explicitly require exclusive replay, but we enforce it defensively.
	tempStream := false
	c.mu.Lock()
	s, ok := c.streams[streamID]
	if !ok {
		// The stream is logically done, but claim exclusive rights to replay it by
		// adding a temporary entry in the streams map.
		//
		// We create this entry with a non-nil w, to ensure it isn't claimed by
		// another request before we lock it below.
		tempStream = true
		s = &stream{
			id: streamID,
			w:  w,
		}
		c.streams[streamID] = s

		// Since this stream is transient, we must clean up after replaying.
		defer func() {
			c.mu.Lock()
			delete(c.streams, streamID)
			c.mu.Unlock()
		}()
	}
	c.mu.Unlock()

	s.mu.Lock()
	defer s.mu.Unlock()

	// Check that this stream wasn't claimed by another request.
	if !tempStream && s.w != nil {
		http.Error(w, "stream ID conflicts with ongoing stream", http.StatusConflict)
		return nil, nil
	}

	// Collect events to replay. Collect them all before writing, so that we
	// have an opportunity to set the HTTP status code on an error.
	//
	// As indicated above, we must do that while holding stream.mu, so that no
	// new messages are added to the eventstore until we've replayed all previous
	// messages, and registered our delivery function.
	var toReplay [][]byte
	if c.eventStore != nil {
		for data, err := range c.eventStore.After(ctx, c.SessionID(), s.id, lastIdx) {
			if err != nil {
				// We can't replay events, perhaps because the underlying event store
				// has garbage collected its storage.
				//
				// We must be careful here: any 404 will signal to the client that the
				// *session* is not found, rather than the stream.
				//
				// 400 is not really accurate, but should at least have no side effects.
				// Other SDKs (typescript) do not have a mechanism for events to be purged.
				http.Error(w, "failed to replay events", http.StatusBadRequest)
				return nil, nil
			}
			if len(data) > 0 {
				toReplay = append(toReplay, data)
			}
		}
	}

	w.Header().Set("Cache-Control", "no-cache, no-transform")
	w.Header().Set("Content-Type", "text/event-stream") // Accept checked in [StreamableHTTPHandler]
	w.Header().Set("Connection", "keep-alive")

	if s.id == "" {
		// Issue #410: the standalone SSE stream is likely not to receive messages
		// for a long time. Ensure that headers are flushed.
		w.WriteHeader(http.StatusOK)
		rc := http.NewResponseController(w)
		// Ignore returned error as flushing is best-effort.
		_ = rc.Flush()
	}

	for _, data := range toReplay {
		lastIdx++
		e := Event{Name: "message", Data: data}
		if c.eventStore != nil {
			e.ID = formatEventID(s.id, lastIdx)
		}
		if _, err := writeEvent(w, e); err != nil {
			return nil, nil
		}
	}

	if tempStream || s.doneLocked() {
		// Nothing more to do.
		return nil, nil
	}

	// The stream is not done: set up delivery state before the stream is
	// unlocked, allowing the connection to write new events.
	s.w = w
	s.done = make(chan struct{})
	s.lastIdx = lastIdx
	s.protocolVersion = protocolVersion
	return s, s.done
}

// servePOST handles an incoming message, and replies with either an outgoing
// message stream or single response object, depending on whether the
// jsonResponse option is set.
//
// It returns an HTTP status code and error message.
func (c *streamableServerConn) servePOST(w http.ResponseWriter, req *http.Request) {
	if len(req.Header.Values(lastEventIDHeader)) > 0 {
		http.Error(w, "can't send Last-Event-ID for POST request", http.StatusBadRequest)
		return
	}

	// Read incoming messages.
	body, err := io.ReadAll(req.Body)
	if err != nil {
		http.Error(w, "failed to read body", http.StatusBadRequest)
		return
	}
	if len(body) == 0 {
		http.Error(w, "POST requires a non-empty body", http.StatusBadRequest)
		return
	}
	// settled(aaw, upstream #674): batch matching stays pending an upstream
	// support-matrix decision for 2025-03-26 and earlier; dropping it would
	// change protocol behavior, not pursued in this fork.
	incoming, isBatch, err := readBatch(body)
	if err != nil {
		http.Error(w, fmt.Sprintf("malformed payload: %v", err), http.StatusBadRequest)
		return
	}

	protocolVersion := req.Header.Get(protocolVersionHeader)
	if protocolVersion == "" {
		protocolVersion = protocolVersion20250326
	}

	if isBatch && protocolVersion >= protocolVersion20250618 {
		http.Error(w, fmt.Sprintf("JSON-RPC batching is not supported in %s and later (request version: %s)", protocolVersion20250618, protocolVersion), http.StatusBadRequest)
		return
	}

	// settled(aaw, upstream rfindley): the batch-rejection guard below stays
	// disabled — older-protocol-version coverage is an upstream test gap (no
	// tests fail if batch JSON requests are rejected entirely).
	// if isBatch && c.jsonResponse {
	// 	http.Error(w, "server does not support batch requests", http.StatusBadRequest)
	// 	return
	// }

	calls := make(map[jsonrpc.ID]struct{})
	tokenInfo := auth.TokenInfoFromContext(req.Context())
	isInitialize := false
	var initializeProtocolVersion string
	for _, msg := range incoming {
		if jreq, ok := msg.(*jsonrpc.Request); ok {
			// Preemptively check that this is a valid request, so that we can fail
			// the HTTP request. If we didn't do this, a request with a bad method or
			// missing ID could be silently swallowed.
			if _, err := checkRequest(jreq, serverMethodInfos); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			if jreq.Method == methodInitialize {
				isInitialize = true
				// Extract the protocol version from InitializeParams.
				var params InitializeParams
				if err := internaljson.Unmarshal(jreq.Params, &params); err == nil {
					initializeProtocolVersion = params.ProtocolVersion
				}
			}
			// Include metadata for all requests (including notifications).
			jreq.Extra = &RequestExtra{
				TokenInfo: tokenInfo,
				Header:    req.Header,
			}
			if jreq.IsCall() {
				calls[jreq.ID] = struct{}{}
				// See the doc for CloseSSEStream: allow the request handler to
				// explicitly close the ongoing stream.
				jreq.Extra.(*RequestExtra).CloseSSEStream = func(args CloseSSEStreamArgs) {
					c.mu.Lock()
					streamID, ok := c.requestStreams[jreq.ID]
					var stream *stream
					if ok {
						stream = c.streams[streamID]
					}
					c.mu.Unlock()

					if stream != nil {
						stream.close(args.RetryAfter)
					}
				}
			}
		}
	}

	// The prime and close events were added in protocol version 2025-11-25 (SEP-1699).
	// Use the version from InitializeParams if this is an initialize request,
	// otherwise use the protocol version header.
	effectiveVersion := protocolVersion
	if isInitialize && initializeProtocolVersion != "" {
		effectiveVersion = initializeProtocolVersion
	}

	// If we don't have any calls, we can just publish the incoming messages and return.
	// No need to track a logical stream.
	//
	// See section [§2.1.4] of the spec: "If the server accepts the input, the
	// server MUST return HTTP status code 202 Accepted with no body."
	//
	// [§2.1.4]: https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#sending-messages-to-the-server
	if len(calls) == 0 {
		for _, msg := range incoming {
			select {
			case c.incoming <- msg:
			case <-c.done:
				// The session is closing. Since we haven't yet written any data to the
				// response, we can signal to the client that the session is gone.
				http.Error(w, "session is closing", http.StatusNotFound)
				return
			}
		}
		w.WriteHeader(http.StatusAccepted)
		return
	}

	// Invariant: we have at least one call.
	//
	// Create a logical stream to track its responses.
	// Important: don't publish the incoming messages until the stream is
	// registered, as the server may attempt to respond to incoming messages as
	// soon as they're published.
	stream, err := c.newStream(req.Context(), calls, crand.Text())
	if err != nil {
		http.Error(w, fmt.Sprintf("storing stream: %v", err), http.StatusInternalServerError)
		return
	}

	// Set response headers. Accept was checked in [StreamableHTTPHandler].
	w.Header().Set("Cache-Control", "no-cache, no-transform")
	if c.jsonResponse {
		w.Header().Set("Content-Type", "application/json")
	} else {
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Connection", "keep-alive")
	}
	if c.sessionID != "" && isInitialize {
		w.Header().Set(sessionIDHeader, c.sessionID)
	}

	// Set up stream delivery state.
	stream.w = w
	done := make(chan struct{})
	stream.done = done
	stream.protocolVersion = effectiveVersion
	if c.jsonResponse {
		// JSON mode: collect messages in pendingJSONMessages until done.
		// Set pendingJSONMessages to a non-nil value to signal that this is an
		// application/json stream.
		stream.pendingJSONMessages = []json.RawMessage{}
	} else {
		// SSE mode: write a priming event if supported.
		if c.eventStore != nil && effectiveVersion >= protocolVersion20251125 {
			// Write a priming event, as defined by [§2.1.6] of the spec.
			//
			// [§2.1.6]: https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#sending-messages-to-the-server
			//
			// We must also write it to the event store in order for indexes to
			// align.
			if err := c.eventStore.Append(req.Context(), c.sessionID, stream.id, nil); err != nil {
				c.logger.Warn(fmt.Sprintf("Storing priming event: %v", err))
			}
			stream.lastIdx++
			e := Event{Name: "prime", ID: formatEventID(stream.id, stream.lastIdx)}
			if _, err := writeEvent(w, e); err != nil {
				c.logger.Warn(fmt.Sprintf("Writing priming event: %v", err))
			}
		}
	}

	// settled(aaw, upstream rfindley): without an event store, remaining
	// requests are not cancelled on stream exit (the client never gets the
	// results); changing this would alter protocol behavior, not pursued in
	// this fork.
	defer stream.release()

	// The stream is now set up to deliver messages.
	//
	// Register it before publishing incoming messages.
	c.mu.Lock()
	c.streams[stream.id] = stream
	for reqID := range calls {
		c.requestStreams[reqID] = stream.id
	}
	c.mu.Unlock()

	// Publish incoming messages.
	for _, msg := range incoming {
		select {
		case c.incoming <- msg:
		// Note: don't select on req.Context().Done() here, since we've already
		// received the requests and may have already published a response message
		// or notification. The client could resume the stream.
		//
		// In fact, this send could be in a separate goroutine.
		case <-c.done:
			// Session closed: we don't know if any data has been written, so it's
			// too late to write a status code here.
			return
		}
	}

	c.hangResponse(req.Context(), done)
}

// Event IDs: encode both the logical connection ID and the index, as
// <streamID>_<idx>, to be consistent with the typescript implementation.

// formatEventID returns the event ID to use for the logical connection ID
// streamID and message index idx.
//
// See also [parseEventID].
func formatEventID(sid string, idx int) string {
	return fmt.Sprintf("%s_%d", sid, idx)
}

// parseEventID parses a Last-Event-ID value into a logical stream id and
// index.
//
// See also [formatEventID].
func parseEventID(eventID string) (streamID string, idx int, ok bool) {
	parts := strings.Split(eventID, "_")
	if len(parts) != 2 {
		return "", 0, false
	}
	streamID = parts[0]
	idx, err := strconv.Atoi(parts[1])
	if err != nil || idx < 0 {
		return "", 0, false
	}
	return streamID, idx, true
}

// Read implements the [Connection] interface.
func (c *streamableServerConn) Read(ctx context.Context) (jsonrpc.Message, error) {
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case msg, ok := <-c.incoming:
		if !ok {
			return nil, io.EOF
		}
		return msg, nil
	case <-c.done:
		return nil, io.EOF
	}
}

// Write implements the [Connection] interface.
func (c *streamableServerConn) Write(ctx context.Context, msg jsonrpc.Message) error {
	// Throughout this function, note that any error that wraps ErrRejected
	// indicates a does not cause the connection to break.
	//
	// Most errors don't break the connection: unlike a true bidirectional
	// stream, a failure to deliver to a stream is not an indication that the
	// logical session is broken.
	data, err := jsonrpc2.EncodeMessage(msg)
	if err != nil {
		return err
	}

	if req, ok := msg.(*jsonrpc.Request); ok && req.IsCall() && (c.stateless || c.sessionID == "") {
		// Requests aren't possible with stateless servers, or when there's no session ID.
		return fmt.Errorf("%w: stateless servers cannot make requests", jsonrpc2.ErrRejected)
	}

	// Find the incoming request that this write relates to, if any.
	var (
		relatedRequest jsonrpc.ID
		responseTo     jsonrpc.ID // if valid, the message is a response to this request
	)
	if resp, ok := msg.(*jsonrpc.Response); ok {
		// If the message is a response, it relates to its request (of course).
		relatedRequest = resp.ID
		responseTo = resp.ID
	} else {
		// Otherwise, we check to see if it request was made in the context of an
		// ongoing request. This may not be the case if the request was made with
		// an unrelated context.
		if v := ctx.Value(idContextKey{}); v != nil {
			relatedRequest = v.(jsonrpc.ID)
		}
	}

	// If the stream is application/json, but the message is not a response, we
	// must send it out of band to the standalone SSE stream.
	if c.jsonResponse && !responseTo.IsValid() {
		relatedRequest = jsonrpc.ID{}
	}

	// Write the message to the stream.
	var s *stream
	c.mu.Lock()
	if relatedRequest.IsValid() {
		if streamID, ok := c.requestStreams[relatedRequest]; ok {
			s = c.streams[streamID]
		}
	} else {
		s = c.streams[""] // standalone SSE stream
	}
	if responseTo.IsValid() {
		// Once we've responded to a request, disallow related messages by removing
		// the stream association. This also releases memory.
		delete(c.requestStreams, responseTo)
	}
	sessionClosed := c.isDone
	c.mu.Unlock()

	if s == nil {
		// The request was made in the context of an ongoing request, but that
		// request is complete.
		//
		// In the future, we could be less strict and allow the request to land on
		// the standalone SSE stream.
		return fmt.Errorf("%w: write to closed stream", jsonrpc2.ErrRejected)
	}
	if sessionClosed {
		return errors.New("session is closed")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	// Store in eventStore before delivering.
	// settled(aaw, upstream rfindley): events append to the store even for
	// JSON responses; pushing the decision into the delivery layer is an
	// upstream refactor, not pursued in this fork.
	delivered := false
	var errs []error
	if c.eventStore != nil {
		if err := c.eventStore.Append(ctx, c.sessionID, s.id, data); err != nil {
			errs = append(errs, err)
		} else {
			delivered = true
		}
	}

	// Compute eventID for SSE streams with event store.
	// Use s.lastIdx + 1 because deliverLocked increments before writing.
	var eventID string
	if c.eventStore != nil {
		eventID = formatEventID(s.id, s.lastIdx+1)
	}

	done, err := s.deliverLocked(data, eventID, responseTo)
	if err != nil {
		errs = append(errs, err)
	} else {
		delivered = true
	}

	if done {
		c.mu.Lock()
		delete(c.streams, s.id)
		c.mu.Unlock()
	}

	if !delivered {
		return fmt.Errorf("%w: undelivered message: %v", jsonrpc2.ErrRejected, errors.Join(errs...))
	}
	return nil
}

// Close implements the [Connection] interface.
func (c *streamableServerConn) Close(ctx context.Context) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.isDone {
		c.isDone = true
		close(c.done)
		if c.eventStore != nil {
			return c.eventStore.SessionClosed(ctx, c.sessionID)
		}
	}
	return nil
}
