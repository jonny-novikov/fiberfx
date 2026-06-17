// Copyright 2025 The Go MCP SDK Authors. All rights reserved.
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

package mcp

/*
Streamable HTTP Client Design

This document describes the client-side implementation of the MCP streamable
HTTP transport, as defined by the MCP spec:
https://modelcontextprotocol.io/specification/2025-11-25/basic/transports#streamable-http

# Overview

The client-side streamable transport allows an MCP client to communicate with a
server over HTTP, sending messages via POST and receiving responses via either
JSON or server-sent events (SSE). The implementation consists of two main
components:

	┌─────────────────────────────────────────────────────────────────┐
	│                 [StreamableClientTransport]                     │
	│   Transport configuration; creates connections via Connect()    │
	└─────────────────────────────────────────────────────────────────┘
	                              │
	                              ▼
	┌─────────────────────────────────────────────────────────────────┐
	│                   [streamableClientConn]                        │
	│   Connection implementation; handles HTTP request/response      │
	└─────────────────────────────────────────────────────────────────┘
	                              │
	                              ├──────────────────────────────────────┐
	                              ▼                                      ▼
	┌─────────────────────────────────────────┐  ┌────────────────────────────────────┐
	│        POST request handlers            │  │      Standalone SSE stream         │
	│   (one per outgoing message/call)       │  │   (server-initiated messages)      │
	└─────────────────────────────────────────┘  └────────────────────────────────────┘

# Sessions

The client maintains a session with the server, identified by a session ID
(Mcp-Session-Id header):

  - Session ID is received from the server after initialization
  - Client includes the session ID in all subsequent requests
  - Session ends when the client calls Close() (sends DELETE) or server returns 404

[streamableClientConn] stores the session state:
  - [streamableClientConn.sessionID]: Server-assigned session identifier
  - [streamableClientConn.initializedResult]: Protocol version and server capabilities

# Connection Lifecycle

1. Connect: [StreamableClientTransport.Connect] creates a [streamableClientConn]
   with a detached context for the connection's lifetime. The context is detached
   to prevent the standalone SSE stream from being cancelled when the original
   Connect context times out.

2. Initialize: The MCP client sends initialize/initialized messages. Upon
   receiving [InitializeResult], the connection:
   - Stores the negotiated protocol version for the Mcp-Protocol-Version header
   - Captures the session ID from the Mcp-Session-Id response header
   - Starts the standalone SSE stream via [streamableClientConn.connectStandaloneSSE]

3. Operation: Messages are sent via POST, responses received via JSON or SSE.

4. Close: [streamableClientConn.Close] sends a DELETE request to terminate
   the session (unless the session is already gone), then cancels the connection
   context to clean up the standalone SSE stream.

# Sending Messages (Write)

[streamableClientConn.Write] sends all outgoing messages via HTTP POST:

	POST /endpoint
	Content-Type: application/json
	Accept: application/json, text/event-stream
	Mcp-Protocol-Version: <negotiated version>
	Mcp-Session-Id: <session ID, if established>

	<JSON-RPC message>

The server may respond with:
  - 202 Accepted: Message received, no response body (notifications/responses)
  - 200 OK with application/json: Single JSON-RPC response
  - 200 OK with text/event-stream: SSE stream of responses

# Receiving Messages (Read)

[streamableClientConn.Read] returns messages from the [streamableClientConn.incoming]
channel, which is populated by multiple concurrent goroutines:

1. POST response handlers ([streamableClientConn.handleJSON] and
   [streamableClientConn.handleSSE]): Process responses from POST requests

2. Standalone SSE stream: Receives server-initiated requests and notifications

The client handles both response formats:
  - JSON: [streamableClientConn.handleJSON] reads body, decodes message
  - SSE: [streamableClientConn.handleSSE] scans events, decodes each message

# Standalone SSE Stream

After initialization, [streamableClientConn.sessionUpdated] triggers
[streamableClientConn.connectStandaloneSSE] to open a GET request for
server-initiated messages:

	GET /endpoint
	Accept: text/event-stream
	Mcp-Session-Id: <session ID>

Stream behavior:
  - Optional: Server may return 405 Method Not Allowed (spec-compliant) or
    other 4xx errors (tolerated in non-strict mode for compatibility)
  - Persistent: Runs for the connection lifetime in a background goroutine
  - Resumable: Uses Last-Event-ID header on reconnection if server provides event IDs
  - Reconnects: Automatic reconnection with exponential backoff on interruption

# Stream Resumption

When an SSE stream (standalone or POST response) is interrupted, the client
attempts to reconnect using [streamableClientConn.connectSSE]:

Event ID tracking:
  - [streamableClientConn.processStream] tracks the last received event ID
  - On reconnection, the Last-Event-ID header is set to resume from that point
  - Server replays missed events if it has an [EventStore] configured

See [calculateReconnectDelay] for the reconnect delay details.

Server-initiated reconnection (SEP-1699)
  - SSE retry field: Sets the delay for the next reconnect attempt
  - If server doesn't provide event IDs, non-standalone streams don't reconnect

# Response Formats

The client must handle two response formats from POST requests:

1. application/json: Single JSON-RPC response
   - Body contains one JSON-RPC message
   - Handled by [streamableClientConn.handleJSON]
   - Simpler but doesn't support streaming or server-initiated messages

2. text/event-stream: SSE stream of messages
   - Body contains SSE events with JSON-RPC messages
   - Handled by [streamableClientConn.handleSSE]
   - Supports multiple messages and server-initiated communication
   - Stream completes when the response to the originating call is received

# HTTP Methods

  - POST: Send JSON-RPC messages (requests, responses, notifications)
    - Used by [streamableClientConn.Write]
    - Response may be JSON or SSE

  - GET: Open or resume SSE stream for server-initiated messages
    - Used by [streamableClientConn.connectSSE]
    - Always expects text/event-stream response (or 405)

  - DELETE: Terminate the session
    - Used by [streamableClientConn.Close]
    - Skipped if session is already known to be gone ([ErrSessionMissing])

# Error Handling

Errors are categorized and handled differently:

1. Transient (recoverable via reconnection):
   - Network interruption during SSE streaming
   - Connection reset or timeout
   - Triggers reconnection in [streamableClientConn.handleSSE]

2. Terminal (breaks the connection):
   - 404 Not Found: Session terminated by server ([ErrSessionMissing])
   - Message decode errors: Protocol violation
   - Context cancellation: Client closed connection
   - Mismatched session IDs: Protocol error
	 - See issue #683: our terminal errors are too strict.

Terminal errors are stored via [streamableClientConn.fail] and returned by
subsequent [streamableClientConn.Read] calls. The [streamableClientConn.failed]
channel signals that the connection is broken.

Special case: [ErrSessionMissing] indicates the server has terminated the session,
so [streamableClientConn.Close] skips the DELETE request.

# Protocol Version Header

After initialization, all requests include:

	Mcp-Protocol-Version: <negotiated version>

This header (set by [streamableClientConn.setMCPHeaders]):
  - Allows the server to handle requests per the negotiated protocol
  - Is omitted before initialization completes
  - Uses the version from [streamableClientConn.initializedResult]

# Key Implementation Details

[StreamableClientTransport] configuration:
  - [StreamableClientTransport.Endpoint]: URL of the MCP server
  - [StreamableClientTransport.HTTPClient]: Custom HTTP client (optional)
  - [StreamableClientTransport.MaxRetries]: Reconnection attempts (default 5)

[streamableClientConn] handles the [Connection] interface:
  - [streamableClientConn.Read]: Returns messages from incoming channel
  - [streamableClientConn.Write]: Sends messages via POST, starts response handlers
  - [streamableClientConn.Close]: Sends DELETE, cancels context, closes done channel

State management:
  - [streamableClientConn.incoming]: Buffered channel for received messages
  - [streamableClientConn.sessionID]: Server-assigned session identifier
  - [streamableClientConn.initializedResult]: Cached for protocol version header
  - [streamableClientConn.failed]: Channel closed on terminal error
  - [streamableClientConn.done]: Channel closed on graceful shutdown
  - [streamableClientConn.ctx]: Detached context for connection lifetime
  - [streamableClientConn.cancel]: Cancels ctx to terminate SSE streams

Context handling:
  - Connection context is detached from [StreamableClientTransport.Connect] context
    using [xcontext.Detach] to preserve context values (for auth middleware) while
    preventing premature cancellation of the standalone SSE stream
  - Individual POST requests use caller-provided contexts for cancellation
*/

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"math"
	"math/rand/v2"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/fiberfx/mcp-go/v2/auth"
	"github.com/fiberfx/mcp-go/v2/internal/jsonrpc2"
	"github.com/fiberfx/mcp-go/v2/internal/xcontext"
	"github.com/fiberfx/mcp-go/v2/jsonrpc"
)

// A StreamableClientTransport is a [Transport] that can communicate with an MCP
// endpoint serving the streamable HTTP transport defined by the 2025-03-26
// version of the spec.
type StreamableClientTransport struct {
	Endpoint   string
	HTTPClient *http.Client
	// MaxRetries is the maximum number of times to attempt a reconnect before giving up.
	// It defaults to 5. To disable retries, use a negative number.
	MaxRetries int

	// DisableStandaloneSSE controls whether the client establishes a standalone SSE stream
	// for receiving server-initiated messages.
	//
	// When false (the default), after initialization the client sends an HTTP GET request
	// to establish a persistent server-sent events (SSE) connection. This allows the server
	// to send messages to the client at any time, such as ToolListChangedNotification or
	// other server-initiated requests and notifications. The connection persists for the
	// lifetime of the session and automatically reconnects if interrupted.
	//
	// When true, the client does not establish the standalone SSE stream. The client will
	// only receive responses to its own POST requests. Server-initiated messages will not
	// be received.
	//
	// According to the MCP specification, the standalone SSE stream is optional.
	// Setting DisableStandaloneSSE to true is useful when:
	//   - You only need request-response communication and don't need server-initiated notifications
	//   - The server doesn't properly handle GET requests for SSE streams
	//   - You want to avoid maintaining a persistent connection
	DisableStandaloneSSE bool

	// OAuthHandler is an optional field that, if provided, will be used to authorize the requests.
	OAuthHandler auth.OAuthHandler

	// settled(aaw, upstream rfindley): strict and logger stay unexported; an
	// export proposal is upstream work, not pursued in this fork.
	// If strict is set, the transport is in 'strict mode', where any violation
	// of the MCP spec causes a failure.
	strict bool
	// If logger is set, it is used to log aspects of the transport, such as spec
	// violations that were ignored.
	logger *slog.Logger
}

// These settings are not (yet) exposed to the user in
// StreamableClientTransport.
const (
	// reconnectGrowFactor is the multiplicative factor by which the delay increases after each attempt.
	// A value of 1.0 results in a constant delay, while a value of 2.0 would double it each time.
	// It must be 1.0 or greater if MaxRetries is greater than 0.
	reconnectGrowFactor = 1.5
	// reconnectMaxDelay caps the backoff delay, preventing it from growing indefinitely.
	reconnectMaxDelay = 30 * time.Second
)

var (
	// reconnectInitialDelay is the base delay for the first reconnect attempt.
	//
	// Mutable for testing.
	reconnectInitialDelay atomic.Int64
)

func init() {
	reconnectInitialDelay.Store(int64(1 * time.Second))
}

// Connect implements the [Transport] interface.
//
// The resulting [Connection] writes messages via POST requests to the
// transport URL with the Mcp-Session-Id header set, and reads messages from
// hanging requests.
//
// When closed, the connection issues a DELETE request to terminate the logical
// session.
func (t *StreamableClientTransport) Connect(ctx context.Context) (Connection, error) {
	client := t.HTTPClient
	if client == nil {
		client = http.DefaultClient
	}
	maxRetries := t.MaxRetries
	if maxRetries == 0 {
		maxRetries = 5
	} else if maxRetries < 0 {
		maxRetries = 0
	}
	// Create a new cancellable context that will manage the connection's lifecycle.
	// This is crucial for cleanly shutting down the background SSE listener by
	// cancelling its blocking network operations, which prevents hangs on exit.
	//
	// This context should be detached from the incoming context: the standalone
	// SSE request should not break when the connection context is done.
	//
	// For example, consider that the user may want to wait at most 5s to connect
	// to the server, and therefore uses a context with a 5s timeout when calling
	// client.Connect. Let's suppose that Connect returns after 1s, and the user
	// starts using the resulting session. If we didn't detach here, the session
	// would break after 4s, when the background SSE stream is terminated.
	//
	// Instead, creating a cancellable context detached from the incoming context
	// allows us to preserve context values (which may be necessary for auth
	// middleware), yet only cancel the standalone stream when the connection is closed.
	connCtx, cancel := context.WithCancel(xcontext.Detach(ctx))
	conn := &streamableClientConn{
		url:                  t.Endpoint,
		client:               client,
		incoming:             make(chan jsonrpc.Message, 10),
		done:                 make(chan struct{}),
		maxRetries:           maxRetries,
		strict:               t.strict,
		logger:               ensureLogger(t.logger), // must be non-nil for safe logging
		ctx:                  connCtx,
		cancel:               cancel,
		failed:               make(chan struct{}),
		disableStandaloneSSE: t.DisableStandaloneSSE,
		oauthHandler:         t.OAuthHandler,
	}
	return conn, nil
}

type streamableClientConn struct {
	url        string
	client     *http.Client
	ctx        context.Context    // connection context, detached from Connect
	cancel     context.CancelFunc // cancels ctx
	incoming   chan jsonrpc.Message
	maxRetries int
	strict     bool         // from [StreamableClientTransport.strict]
	logger     *slog.Logger // from [StreamableClientTransport.logger]

	// disableStandaloneSSE controls whether to disable the standalone SSE stream
	// for receiving server-to-client notifications when no request is in flight.
	disableStandaloneSSE bool // from [StreamableClientTransport.DisableStandaloneSSE]

	// oauthHandler is the OAuth handler for the connection.
	oauthHandler auth.OAuthHandler // from [StreamableClientTransport.OAuthHandler]

	// Guard calls to Close, as it may be called multiple times.
	closeOnce sync.Once
	closeErr  error
	done      chan struct{} // signal graceful termination

	// Logical reads are distributed across multiple http requests. Whenever any
	// of them fails to process their response, we must break the connection, by
	// failing the pending Read.
	//
	// Achieve this by storing the failure message, and signalling when reads are
	// broken. See also [streamableClientConn.fail] and
	// [streamableClientConn.failure].
	failOnce sync.Once
	_failure error
	failed   chan struct{} // signal failure

	// Guard the initialization state.
	mu                sync.Mutex
	initializedResult *InitializeResult
	sessionID         string
}

var _ clientConnection = (*streamableClientConn)(nil)

func (c *streamableClientConn) sessionUpdated(state clientSessionState) {
	c.mu.Lock()
	c.initializedResult = state.InitializeResult
	c.mu.Unlock()

	// Start the standalone SSE stream as soon as we have the initialized
	// result, if continuous listening is enabled.
	//
	// § 2.2: The client MAY issue an HTTP GET to the MCP endpoint. This can be
	// used to open an SSE stream, allowing the server to communicate to the
	// client, without the client first sending data via HTTP POST.
	//
	// We have to wait for initialized, because until we've received
	// initialized, we don't know whether the server requires a sessionID.
	//
	// § 2.5: A server using the Streamable HTTP transport MAY assign a session
	// ID at initialization time, by including it in a Mcp-Session-Id header
	// on the HTTP response containing the InitializeResult.
	if !c.disableStandaloneSSE {
		c.connectStandaloneSSE()
	}
}

func (c *streamableClientConn) connectStandaloneSSE() {
	resp, err := c.connectSSE(c.ctx, "", 0, true)
	if err != nil {
		// If the client didn't cancel the request, and failure breaks the logical
		// session.
		if c.ctx.Err() == nil {
			c.fail(fmt.Errorf("standalone SSE request failed (session ID: %v): %v", c.sessionID, err))
		}
		return
	}

	// [§2.2.3]: "The server MUST either return Content-Type:
	// text/event-stream in response to this HTTP GET, or else return HTTP
	// 405 Method Not Allowed, indicating that the server does not offer an
	// SSE stream at this endpoint."
	//
	// [§2.2.3]: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
	if resp.StatusCode == http.StatusMethodNotAllowed {
		// The server doesn't support the standalone SSE stream.
		resp.Body.Close()
		return
	}
	if resp.Header.Get("Content-Type") != "text/event-stream" {
		// modelcontextprotocol/go-sdk#736: some servers return 200 OK or redirect with
		// non-SSE content type instead of text/event-stream for the standalone
		// SSE stream.
		c.logger.Warn(fmt.Sprintf("got Content-Type %s instead of text/event-stream for standalone SSE stream", resp.Header.Get("Content-Type")))
		resp.Body.Close()
		return
	}
	if resp.StatusCode >= 400 && resp.StatusCode < 500 && !c.strict {
		// modelcontextprotocol/go-sdk#393,#610: some servers return NotFound or
		// other status codes instead of MethodNotAllowed for the standalone SSE
		// stream.
		//
		// Treat this like MethodNotAllowed in non-strict mode.
		c.logger.Warn(fmt.Sprintf("got %d instead of 405 for standalone SSE stream", resp.StatusCode))
		resp.Body.Close()
		return
	}
	summary := "standalone SSE stream"
	if err := c.checkResponse(summary, resp); err != nil {
		c.fail(err)
		return
	}
	go c.handleSSE(c.ctx, summary, resp, nil)
}

// fail handles an asynchronous error while reading.
//
// If err is non-nil, it is terminal, and subsequent (or pending) Reads will
// fail.
//
// If err wraps ErrSessionMissing, the failure indicates that the session is no
// longer present on the server, and no final DELETE will be performed when
// closing the connection.
func (c *streamableClientConn) fail(err error) {
	if err != nil {
		c.failOnce.Do(func() {
			c._failure = err
			close(c.failed)
		})
	}
}

func (c *streamableClientConn) failure() error {
	select {
	case <-c.failed:
		return c._failure
	default:
		return nil
	}
}

func (c *streamableClientConn) SessionID() string {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.sessionID
}

// Read implements the [Connection] interface.
func (c *streamableClientConn) Read(ctx context.Context) (jsonrpc.Message, error) {
	if err := c.failure(); err != nil {
		return nil, err
	}
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case <-c.failed:
		return nil, c.failure()
	case <-c.done:
		return nil, io.EOF
	case msg := <-c.incoming:
		return msg, nil
	}
}

// Write implements the [Connection] interface.
func (c *streamableClientConn) Write(ctx context.Context, msg jsonrpc.Message) error {
	if err := c.failure(); err != nil {
		return err
	}

	var requestSummary string
	var forCall *jsonrpc.Request
	switch msg := msg.(type) {
	case *jsonrpc.Request:
		requestSummary = fmt.Sprintf("sending %q", msg.Method)
		if msg.IsCall() {
			forCall = msg
		}
	case *jsonrpc.Response:
		requestSummary = fmt.Sprintf("sending jsonrpc response #%d", msg.ID)
	default:
		panic("unreachable")
	}

	data, err := jsonrpc.EncodeMessage(msg)
	if err != nil {
		return fmt.Errorf("%s: %v", requestSummary, err)
	}

	doRequest := func() (*http.Request, *http.Response, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.url, bytes.NewReader(data))
		if err != nil {
			return nil, nil, err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Accept", "application/json, text/event-stream")
		if err := c.setMCPHeaders(req); err != nil {
			// Failure to set headers means that the request was not sent.
			// Wrap with ErrRejected so the jsonrpc2 connection doesn't set writeErr
			// and permanently break the connection.
			return nil, nil, fmt.Errorf("%s: %w: %v", requestSummary, jsonrpc2.ErrRejected, err)
		}
		resp, err := c.client.Do(req)
		if err != nil {
			// Any error from client.Do means the request didn't reach the server.
			// Wrap with ErrRejected so the jsonrpc2 connection doesn't set writeErr
			// and permanently break the connection.
			err = fmt.Errorf("%s: %w: %v", requestSummary, jsonrpc2.ErrRejected, err)
		}
		return req, resp, err
	}

	req, resp, err := doRequest()
	if err != nil {
		return err
	}

	if (resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden) && c.oauthHandler != nil {
		if err := c.oauthHandler.Authorize(ctx, req, resp); err != nil {
			// Wrap with ErrRejected so the jsonrpc2 connection doesn't set writeErr
			// and permanently break the connection.
			// Wrap the authorization error as well for client inspection.
			return fmt.Errorf("%s: %w: %w", requestSummary, jsonrpc2.ErrRejected, err)
		}
		// Retry the request after successful authorization.
		_, resp, err = doRequest()
		if err != nil {
			return err
		}
	}

	if err := c.checkResponse(requestSummary, resp); err != nil {
		// Only fail the connection for non-transient errors.
		// Transient errors (wrapped with ErrRejected) should not break the connection.
		if !errors.Is(err, jsonrpc2.ErrRejected) {
			c.fail(err)
		}
		return err
	}

	if sessionID := resp.Header.Get(sessionIDHeader); sessionID != "" {
		c.mu.Lock()
		hadSessionID := c.sessionID
		if hadSessionID == "" {
			c.sessionID = sessionID
		}
		c.mu.Unlock()
		if hadSessionID != "" && hadSessionID != sessionID {
			resp.Body.Close()
			return fmt.Errorf("mismatching session IDs %q and %q", hadSessionID, sessionID)
		}
	}

	if forCall == nil {
		resp.Body.Close()

		// [§2.1.4]: "If the input is a JSON-RPC response or notification:
		// If the server accepts the input, the server MUST return HTTP status code 202 Accepted with no body."
		//
		// [§2.1.4]: https://modelcontextprotocol.io/specification/2025-06-18/basic/transports#listening-for-messages-from-the-server
		if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusAccepted {
			errMsg := fmt.Sprintf("unexpected status code %d from non-call", resp.StatusCode)
			// Some servers return 200, even with an empty json body.
			//
			// In strict mode, return an error to the caller.
			c.logger.Warn(errMsg)
			if c.strict {
				return errors.New(errMsg)
			}
		}
		return nil
	}

	contentType := strings.TrimSpace(strings.SplitN(resp.Header.Get("Content-Type"), ";", 2)[0])
	switch contentType {
	case "application/json":
		go c.handleJSON(requestSummary, resp)

	case "text/event-stream":
		var forCall *jsonrpc.Request
		if jsonReq, ok := msg.(*jsonrpc.Request); ok && jsonReq.IsCall() {
			forCall = jsonReq
		}
		// Handle the resulting stream. Note that ctx comes from the call, and
		// therefore is already cancelled when the JSON-RPC request is cancelled
		// (or rather, context cancellation is what *triggers* JSON-RPC
		// cancellation)
		go c.handleSSE(ctx, requestSummary, resp, forCall)

	default:
		resp.Body.Close()
		return fmt.Errorf("%s: unsupported content type %q", requestSummary, contentType)
	}
	return nil
}

func (c *streamableClientConn) setMCPHeaders(req *http.Request) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.oauthHandler != nil {
		ts, err := c.oauthHandler.TokenSource(c.ctx)
		if err != nil {
			return err
		}
		if ts != nil {
			token, err := ts.Token()
			if err != nil {
				return err
			}
			if token != nil {
				req.Header.Set("Authorization", "Bearer "+token.AccessToken)
			}
		}
	}
	if c.initializedResult != nil {
		req.Header.Set(protocolVersionHeader, c.initializedResult.ProtocolVersion)
	}
	if c.sessionID != "" {
		req.Header.Set(sessionIDHeader, c.sessionID)
	}
	return nil
}

func (c *streamableClientConn) handleJSON(requestSummary string, resp *http.Response) {
	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		c.fail(fmt.Errorf("%s: failed to read body: %v", requestSummary, err))
		return
	}
	msg, err := jsonrpc.DecodeMessage(body)
	if err != nil {
		c.fail(fmt.Errorf("%s: failed to decode response: %v", requestSummary, err))
		return
	}
	select {
	case c.incoming <- msg:
	case <-c.done:
		// The connection was closed by the client; exit gracefully.
	}
}

// handleSSE manages the lifecycle of an SSE connection. It can be either
// persistent (for the main GET listener) or temporary (for a POST response).
//
// If forCall is set, it is the call that initiated the stream, and the
// stream is complete when we receive its response. Otherwise, this is the
// standalone stream.
func (c *streamableClientConn) handleSSE(ctx context.Context, requestSummary string, resp *http.Response, forCall *jsonrpc2.Request) {
	// Track the last event ID to detect progress.
	// The retry counter is only reset when progress is made (lastEventID advances).
	// This prevents infinite retry loops when a server repeatedly terminates
	// connections without making progress (#679).
	var prevLastEventID string
	retriesWithoutProgress := 0

	for {
		lastEventID, reconnectDelay, clientClosed := c.processStream(ctx, requestSummary, resp, forCall)

		// If the connection was closed by the client, we're done.
		if clientClosed {
			return
		}
		// If we don't have a last event ID, we can never get the call response, so
		// there's nothing to resume. For the standalone stream, we can reconnect,
		// but we may just miss messages.
		if lastEventID == "" && forCall != nil {
			return
		}

		// Check if we made progress (lastEventID advanced).
		// Only reset the retry counter when actual progress is made.
		if lastEventID != "" && lastEventID != prevLastEventID {
			// Progress was made: reset the retry counter.
			retriesWithoutProgress = 0
			prevLastEventID = lastEventID
		} else {
			// No progress: increment the retry counter.
			retriesWithoutProgress++
			if retriesWithoutProgress > c.maxRetries {
				if ctx.Err() == nil {
					c.fail(fmt.Errorf("%s: exceeded %d retries without progress (session ID: %v)", requestSummary, c.maxRetries, c.sessionID))
				}
				return
			}
		}

		// The stream was interrupted or ended by the server. Attempt to reconnect.
		newResp, err := c.connectSSE(ctx, lastEventID, reconnectDelay, false)
		if err != nil {
			// If the client didn't cancel this request, any failure to execute it
			// breaks the logical MCP session.
			if ctx.Err() == nil {
				// All reconnection attempts failed: fail the connection.
				c.fail(fmt.Errorf("%s: failed to reconnect (session ID: %v): %v", requestSummary, c.sessionID, err))
			}
			return
		}

		resp = newResp
		if err := c.checkResponse(requestSummary, resp); err != nil {
			c.fail(err)
			return
		}
	}
}

// checkResponse checks the status code of the provided response, and
// translates it into an error if the request was unsuccessful.
//
// The response body is close if a non-nil error is returned.
func (c *streamableClientConn) checkResponse(requestSummary string, resp *http.Response) (err error) {
	defer func() {
		if err != nil {
			resp.Body.Close()
		}
	}()
	// §2.5.3: "The server MAY terminate the session at any time, after
	// which it MUST respond to requests containing that session ID with HTTP
	// 404 Not Found."
	if resp.StatusCode == http.StatusNotFound {
		// Return an ErrSessionMissing to avoid sending a redundant DELETE when the
		// session is already gone.
		return fmt.Errorf("%s: failed to connect (session ID: %v): %w", requestSummary, c.sessionID, ErrSessionMissing)
	}
	// Transient server errors (502, 503, 504, 429) should not break the connection.
	// Wrap them with ErrRejected so the jsonrpc2 layer doesn't set writeErr.
	if isTransientHTTPStatus(resp.StatusCode) {
		return fmt.Errorf("%w: %s: %v", jsonrpc2.ErrRejected, requestSummary, http.StatusText(resp.StatusCode))
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("%s: %v", requestSummary, http.StatusText(resp.StatusCode))
	}
	return nil
}

// processStream reads from a single response body, sending events to the
// incoming channel. It returns the ID of the last processed event and a flag
// indicating if the connection was closed by the client. If resp is nil, it
// returns "", false.
func (c *streamableClientConn) processStream(ctx context.Context, requestSummary string, resp *http.Response, forCall *jsonrpc.Request) (lastEventID string, reconnectDelay time.Duration, clientClosed bool) {
	defer func() {
		// Drain any remaining unprocessed body. This allows the connection to be re-used after closing.
		io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
	}()
	for evt, err := range scanEvents(resp.Body) {
		if err != nil {
			if ctx.Err() != nil {
				return "", 0, true // don't reconnect: client cancelled
			}

			// Malformed events are hard errors that indicate corrupted data or protocol
			// violations. These should fail the connection permanently.
			if errors.Is(err, errMalformedEvent) {
				c.fail(fmt.Errorf("%s: %v", requestSummary, err))
				return "", 0, true
			}

			break
		}

		if evt.ID != "" {
			lastEventID = evt.ID
		}

		if evt.Retry != "" {
			if n, err := strconv.ParseInt(evt.Retry, 10, 64); err == nil {
				reconnectDelay = time.Duration(n) * time.Millisecond
			}
		}

		// According to SSE specification
		// (https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation)
		// events with an empty data buffer are allowed.
		// In MCP these can be priming events (SEP-1699) that carry only a Last-Event-ID for stream resumption.
		if len(evt.Data) == 0 {
			continue
		}

		// According to SSE spec, events with no name default to "message"
		if evt.Name != "" && evt.Name != "message" {
			continue
		}

		msg, err := jsonrpc.DecodeMessage(evt.Data)
		if err != nil {
			c.fail(fmt.Errorf("%s: failed to decode event: %v", requestSummary, err))
			return "", 0, true
		}

		select {
		case c.incoming <- msg:
			// Check if this is the response to our call, which terminates the request.
			// (it could also be a server->client request or notification).
			if jsonResp, ok := msg.(*jsonrpc.Response); ok && forCall != nil {
				// settled(aaw): a response on the standalone SSE stream (forCall
				// nil) is never expected but goes undetected; adding the assertion
				// is upstream hardening, not pursued in this fork.
				if jsonResp.ID == forCall.ID {
					return "", 0, true
				}
			}

		case <-c.done:
			// The connection was closed by the client; exit gracefully.
			return "", 0, true
		}
	}
	// The loop finished without an error, indicating the server closed the stream.
	//
	// If the lastEventID is "", the stream is not retryable and we should
	// report a synthetic error for the call.
	//
	// Note that this is different from the cancellation case above, since the
	// caller is still waiting for a response that will never come.
	if lastEventID == "" && forCall != nil {
		errmsg := &jsonrpc2.Response{
			ID:    forCall.ID,
			Error: fmt.Errorf("request terminated without response"),
		}
		select {
		case c.incoming <- errmsg:
		case <-c.done:
		}
	}
	return lastEventID, reconnectDelay, false
}

// connectSSE handles the logic of connecting a text/event-stream connection.
//
// If lastEventID is set, it is the last-event ID of a stream being resumed.
//
// If connection fails, connectSSE retries with an exponential backoff
// strategy. It returns a new, valid HTTP response if successful, or an error
// if all retries are exhausted.
//
// reconnectDelay is the delay set by the server using the SSE retry field, or
// 0.
//
// If initial is set, this is the initial attempt.
//
// If connectSSE exits due to context cancellation, the result is (nil, ctx.Err()).
func (c *streamableClientConn) connectSSE(ctx context.Context, lastEventID string, reconnectDelay time.Duration, initial bool) (*http.Response, error) {
	var finalErr error
	attempt := 0
	if !initial {
		// We've already connected successfully once, so delay subsequent
		// reconnections. Otherwise, if the server returns 200 but terminates the
		// connection, we'll reconnect as fast as we can, ad infinitum.
		//
		// settled(aaw): no total-attempts cap per logical request; reconnects
		// are already delay-bounded, and a cap is an upstream design question.
		attempt = 1
	}
	delay := calculateReconnectDelay(attempt)
	if reconnectDelay > 0 {
		delay = reconnectDelay // honor the server's requested initial delay
	}
	for ; attempt <= c.maxRetries; attempt++ {
		select {
		case <-c.done:
			return nil, fmt.Errorf("connection closed by client during reconnect")

		case <-ctx.Done():
			// If the connection context is canceled, the request below will not
			// succeed anyway.
			return nil, ctx.Err()

		case <-time.After(delay):
			req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.url, nil)
			if err != nil {
				return nil, err
			}
			if err := c.setMCPHeaders(req); err != nil {
				return nil, err
			}
			if lastEventID != "" {
				req.Header.Set(lastEventIDHeader, lastEventID)
			}
			req.Header.Set("Accept", "text/event-stream")
			resp, err := c.client.Do(req)
			if err != nil {
				finalErr = err // Store the error and try again.
				delay = calculateReconnectDelay(attempt + 1)
				continue
			}
			return resp, nil
		}
	}
	// If the loop completes, all retries have failed, or the client is closing.
	if finalErr != nil {
		return nil, fmt.Errorf("connection failed after %d attempts: %w", c.maxRetries, finalErr)
	}
	return nil, fmt.Errorf("connection aborted after %d attempts", c.maxRetries)
}

// Close implements the [Connection] interface.
func (c *streamableClientConn) Close(ctx context.Context) error {
	c.closeOnce.Do(func() {
		if errors.Is(c.failure(), ErrSessionMissing) {
			// If the session is missing, no need to delete it.
		} else {
			req, err := http.NewRequestWithContext(ctx, http.MethodDelete, c.url, nil)
			if err != nil {
				c.closeErr = err
			} else {
				if err := c.setMCPHeaders(req); err != nil {
					c.closeErr = err
				} else if _, err := c.client.Do(req); err != nil {
					c.closeErr = err
				}
			}
		}

		// Cancel any hanging network requests after cleanup.
		c.cancel()
		close(c.done)
	})
	return c.closeErr
}

// calculateReconnectDelay calculates a delay using exponential backoff with full jitter.
func calculateReconnectDelay(attempt int) time.Duration {
	if attempt == 0 {
		return 0
	}
	// Calculate the exponential backoff using the grow factor.
	backoffDuration := time.Duration(float64(reconnectInitialDelay.Load()) * math.Pow(reconnectGrowFactor, float64(attempt-1)))
	// Cap the backoffDuration at maxDelay.
	backoffDuration = min(backoffDuration, reconnectMaxDelay)

	// Use a full jitter using backoffDuration
	jitter := rand.N(backoffDuration)

	return backoffDuration + jitter
}

// isTransientHTTPStatus reports whether the HTTP status code indicates a
// transient server error that should not permanently break the connection.
func isTransientHTTPStatus(statusCode int) bool {
	switch statusCode {
	case http.StatusInternalServerError, // 500
		http.StatusBadGateway,         // 502
		http.StatusServiceUnavailable, // 503
		http.StatusGatewayTimeout,     // 504
		http.StatusTooManyRequests:    // 429
		return true
	}
	return false
}
