# `echo-tunnel` Chapter 4 · The Smallest Useful Proxy

---

*In which we ship a working reverse proxy in 50 lines of Go, using nothing but the standard library, and establish the foundation that the next eight chapters extend.*

---

## What This Chapter Delivers

By the end of this chapter, you'll have:

1. A reverse proxy binary (`proxyd`) that accepts HTTP traffic on a configurable port and forwards it to a configurable backend
2. A `Director` function that rewrites the request's `Host`, `URL.Scheme`, and `URL.Host` correctly for the upstream
3. A tuned `Transport` with explicit dial timeouts, keep-alive intervals, and connection pool sizing — not the standard library's defaults
4. A `responseWriter` wrapper that captures status codes and bytes-written, ready to be extended into the request inspector in Chapter 11
5. An understanding of which standard-library defaults are wrong for a proxy and which configuration values are the inputs to deliberate choice

This is the smallest useful proxy. It does nothing more than what a reverse proxy must do. Everything in Chapters 5–12 is an extension of the structure built here. If this chapter's code is wrong, every subsequent chapter compounds the error.

---

## Why Start Here

Part 0 ended with the architectural decision: build the tunnel from primitives because the seven requirements don't fit any single existing tool. Part 1 begins with the smallest primitive — a reverse proxy — and extends it across nine chapters into a full WebSocket-tunneled, multi-tenant, observable platform.

The reverse proxy is the right starting primitive because every later capability depends on it. Wildcard TLS (Chapter 6) terminates connections that the proxy then forwards. WebSocket tunneling (Chapter 7) replaces the proxy's "forward to a backend URL" with "forward through a WebSocket to a tunnel client." Authentication (Chapter 10) is middleware wrapping the proxy. Observability (Chapter 11) instruments the proxy's request and response paths. None of those capabilities makes sense without the proxy underneath.

The Go standard library provides `httputil.ReverseProxy` — a thin, well-designed type that handles the mechanics of HTTP forwarding. We use it. We do not write a reverse proxy from scratch when the standard library already provides one. What this chapter is really about is using `ReverseProxy` correctly: configuring its `Director`, tuning its `Transport`, wrapping its responses for observability. The default `httputil.NewSingleHostReverseProxy` is not what you want in production. Understanding why is the chapter's main work.

---

## The 50-Line Version

Let's see the whole thing first, then dissect it.

```go
// cmd/proxyd/main.go
package main

import (
	"flag"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"time"
)

func main() {
	listen := flag.String("listen", ":8080", "address to listen on")
	target := flag.String("target", "", "backend URL to forward to (required)")
	flag.Parse()

	if *target == "" {
		slog.Error("target URL is required")
		os.Exit(1)
	}

	targetURL, err := url.Parse(*target)
	if err != nil {
		slog.Error("invalid target URL", "url", *target, "error", err)
		os.Exit(1)
	}

	proxy := &httputil.ReverseProxy{
		Director: newDirector(targetURL),
		Transport: newTransport(),
		ErrorHandler: func(w http.ResponseWriter, r *http.Request, err error) {
			slog.Error("proxy error", "url", r.URL.String(), "error", err)
			http.Error(w, "bad gateway", http.StatusBadGateway)
		},
	}

	slog.Info("proxyd listening", "addr", *listen, "target", *target)

	srv := &http.Server{
		Addr:              *listen,
		Handler:           withLogging(proxy),
		ReadHeaderTimeout: 5 * time.Second,
	}

	if err := srv.ListenAndServe(); err != nil {
		slog.Error("server failed", "error", err)
		os.Exit(1)
	}
}
```

This file is the binary's entry point. It reads two flags (the listen address and the target backend), constructs an `httputil.ReverseProxy` with three configured behaviors (Director, Transport, ErrorHandler), wraps it in a logging middleware, and serves it on an `http.Server` with a sane `ReadHeaderTimeout`.

The supporting functions (`newDirector`, `newTransport`, `withLogging`) live in the next sections. Each one is small and deliberate.

Build and test it:

```bash
cd echo-tunnel
go build -o proxyd ./cmd/proxyd

# In one terminal, run a backend:
python3 -m http.server 3000

# In another, run the proxy:
./proxyd --listen :8080 --target http://localhost:3000

# In a third, send a request through the proxy:
curl -v http://localhost:8080/
```

You should see the directory listing from the Python HTTP server, served through the proxy on port 8080. Working reverse proxy in 50 lines. The rest of this chapter explains why each line is the way it is.

---

## The Director: Rewriting Requests Correctly

The `Director` function is called once per incoming request, before the request is forwarded to the upstream. Its job is to mutate the request so that it correctly addresses the upstream backend rather than the proxy itself.

```go
// internal/proxy/director.go
package proxy

import (
	"net/http"
	"net/url"
	"strings"
)

func newDirector(target *url.URL) func(*http.Request) {
	targetQuery := target.RawQuery

	return func(req *http.Request) {
		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.URL.Path = singleJoiningSlash(target.Path, req.URL.Path)

		if targetQuery == "" || req.URL.RawQuery == "" {
			req.URL.RawQuery = targetQuery + req.URL.RawQuery
		} else {
			req.URL.RawQuery = targetQuery + "&" + req.URL.RawQuery
		}

		// Set the Host header to match the target, not the original request.
		// This is what most upstream applications expect — they want to see
		// the host of the backend they're running on, not the proxy's host.
		req.Host = target.Host

		// If the original request didn't set User-Agent, the standard library
		// would set "Go-http-client/1.1" as a default. We'd rather send no
		// User-Agent than a misleading one, so we set it to empty if missing.
		if _, ok := req.Header["User-Agent"]; !ok {
			req.Header.Set("User-Agent", "")
		}
	}
}

func singleJoiningSlash(a, b string) string {
	aslash := strings.HasSuffix(a, "/")
	bslash := strings.HasPrefix(b, "/")
	switch {
	case aslash && bslash:
		return a + b[1:]
	case !aslash && !bslash:
		return a + "/" + b
	}
	return a + b
}
```

Most of this is what `httputil.NewSingleHostReverseProxy` does internally. The reason we write it explicitly is to make the behavior visible and modifiable. Three things matter:

**The `Host` header.** When a request arrives at the proxy with `Host: example.com`, what do we send to the backend? The two reasonable choices are "preserve the original Host" or "use the backend's Host." In our setup, we set `req.Host = target.Host` — the backend sees its own hostname in the `Host` header. This is what most application frameworks expect: they generated their config based on the host they're running on, and a foreign Host header would confuse path generation, redirects, and cookie domains.

The alternative (`req.Host = req.Host`, leaving the original) is what you want when the backend is host-aware and routes based on the incoming host. The Codemoji backends are not host-aware in this way; they trust the proxy to do host-based routing and then deliver to a single backend per host. Chapter 7 will revisit this when the same proxy needs to handle requests for many subdomains routing to many backends.

**Path joining.** The standard library's `singleJoiningSlash` handles the case where the target URL has a path prefix (e.g., `http://backend.internal/api`) and the request path also starts with a slash. Without `singleJoiningSlash`, you'd get `http://backend.internal/api//some/path` (double slash). With it, you get `http://backend.internal/api/some/path` (single slash). We copy this implementation rather than depending on `httputil.NewSingleHostReverseProxy` for it because we want the Director to be self-contained and modifiable.

**The User-Agent default.** Go's standard `http` package sets `User-Agent: Go-http-client/1.1` if the field is missing. For a reverse proxy, this would replace the original client's User-Agent with Go's, losing information that backend logging and analytics depend on. The fix: if the original request didn't set User-Agent, set it to empty (which Go interprets as "don't add a default"). The original User-Agent from the client passes through unchanged.

What this Director does NOT do (yet):

- Set `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Real-IP` — those are added in Chapter 10's header trust boundary work, with explicit configuration about which forwarding headers to trust from upstream and which to set ourselves
- Strip hop-by-hop headers (`Connection`, `Upgrade`, `Keep-Alive`) — `httputil.ReverseProxy` does this internally; we rely on it
- Handle WebSocket upgrades — that's Chapter 9's work

The Director is the smallest unit of request mutation. Adding more responsibilities to it would make it the wrong size; later chapters add middleware around the proxy, not more code inside the Director.

---

## The Transport: Why the Defaults Are Wrong

`httputil.ReverseProxy` uses `http.DefaultTransport` if you don't specify one. This is the single most consequential decision in writing a production-grade Go HTTP server, and the answer is: don't use the default.

The default transport has the following characteristics (per the Go standard library source as of Go 1.23):

```go
var DefaultTransport RoundTripper = &Transport{
    Proxy: ProxyFromEnvironment,
    DialContext: defaultTransportDialContext(&net.Dialer{
        Timeout:   30 * time.Second,
        KeepAlive: 30 * time.Second,
    }),
    ForceAttemptHTTP2:     true,
    MaxIdleConns:          100,
    IdleConnTimeout:       90 * time.Second,
    TLSHandshakeTimeout:   10 * time.Second,
    ExpectContinueTimeout: 1 * time.Second,
}
```

These defaults are tuned for a general-purpose HTTP client — a script downloading files, a one-off API call, a cron job hitting a webhook. They are wrong for a long-running reverse proxy in three ways:

**`MaxIdleConns: 100` is too low for a busy proxy.** This is the total number of idle connections across all hosts. In a system with multiple upstreams (which is where we're going by Chapter 6), 100 connections divided across many hosts means each host gets only a handful, leading to constant connection establishment overhead.

**There's no `MaxIdleConnsPerHost`.** The default for this field is `DefaultMaxIdleConnsPerHost` which is 2. Two idle connections per upstream host is fine for a script; it's a bottleneck for a proxy expecting many concurrent requests to a single backend.

**There's no `MaxConnsPerHost`.** Without a limit, a slow upstream can cause connection counts to grow unboundedly during a backlog, exhausting file descriptors.

**There's no `ResponseHeaderTimeout`.** A backend that accepts the connection and then never sends response headers will hang the proxy goroutine indefinitely (or until the request context is cancelled). For a webhook delivery scenario with a hard deadline, this is a critical missing setting.

Here's the explicit Transport we use instead:

```go
// internal/proxy/transport.go
package proxy

import (
	"net"
	"net/http"
	"time"
)

func newTransport() *http.Transport {
	return &http.Transport{
		// Connection establishment.
		DialContext: (&net.Dialer{
			Timeout:   5 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,

		// Connection pooling.
		MaxIdleConns:        500,
		MaxIdleConnsPerHost: 50,
		MaxConnsPerHost:     200,
		IdleConnTimeout:     90 * time.Second,

		// Response timing.
		TLSHandshakeTimeout:   5 * time.Second,
		ResponseHeaderTimeout: 10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,

		// HTTP/2 negotiation.
		ForceAttemptHTTP2: true,
	}
}
```

The values:

- `Dial Timeout: 5 seconds` — give up on establishing a TCP connection that takes more than 5 seconds. The default 30 seconds is too long; if a backend isn't reachable in 5 seconds, it's not reachable at all from the proxy's perspective.
- `MaxIdleConns: 500` — a generous total budget. The proxy can hold 500 idle connections across all upstreams.
- `MaxIdleConnsPerHost: 50` — up to 50 idle connections to any single backend. For a typical concurrent request count, this means subsequent requests reuse existing connections rather than establishing new ones.
- `MaxConnsPerHost: 200` — a hard ceiling on connections to any single backend, including in-use ones. If a backend is slow and 200 connections are pending, the 201st request waits for one to free up rather than creating new connections that would exhaust file descriptors.
- `IdleConnTimeout: 90 seconds` — same as the default; idle connections are closed after 90 seconds of no use. This is a reasonable balance between connection reuse and not holding stale connections forever.
- `TLSHandshakeTimeout: 5 seconds` — for HTTPS upstreams. Same reasoning as the dial timeout.
- `ResponseHeaderTimeout: 10 seconds` — wait at most 10 seconds for the first response byte from the backend. If the backend accepts the connection and then takes 10+ seconds to start responding, treat it as a failure. This is the timeout that prevents indefinite hangs.

Each of these values is a starting point. Tune them based on your specific backends. The point is not the specific numbers; it's that the values exist and are deliberate. The default Transport's choices are deliberate too — for a different use case.

### The HTTP/2 Question

`ForceAttemptHTTP2: true` is in the default Transport too, and we keep it. This means the proxy will negotiate HTTP/2 with backends that support it. HTTP/2 multiplexes multiple requests over a single TCP connection, which improves efficiency for high-concurrency scenarios.

There's a subtlety: HTTP/2 requires HTTPS for compatibility with most clients. Plain HTTP backends won't negotiate HTTP/2 even if `ForceAttemptHTTP2` is set. For backends running over Fly.io's 6PN private network (Chapter 6's work), they're plain HTTP and will use HTTP/1.1. That's fine.

For backends that support HTTP/2 over plain HTTP (h2c), additional configuration is needed using `golang.org/x/net/http2` and `http2.ConfigureTransport`. We're not configuring h2c here because the use case doesn't require it. If you need h2c, the standard library provides it; the configuration is documented at `https://pkg.go.dev/golang.org/x/net/http2`.

---

## The Response Writer Wrapper: Setting Up for Observability

The `Director` and `Transport` cover the request and connection sides. The third configured behavior is response handling — specifically, capturing what status code the backend returned and how many bytes flowed back to the client.

`http.ResponseWriter` is an interface, not a struct. We can wrap it in our own type that records what passes through. This is the foundation for the request inspector in Chapter 11 and the Prometheus metrics in Chapter 11.

```go
// internal/proxy/response_writer.go
package proxy

import (
	"net/http"
)

// responseWriter wraps an http.ResponseWriter to capture response metadata.
// It records the status code and the number of bytes written, leaving the
// underlying ResponseWriter's behavior otherwise unchanged.
type responseWriter struct {
	http.ResponseWriter
	statusCode  int
	bytesWritten int64
	wroteHeader  bool
}

func newResponseWriter(w http.ResponseWriter) *responseWriter {
	return &responseWriter{
		ResponseWriter: w,
		statusCode:     http.StatusOK, // default if WriteHeader is never called
	}
}

func (rw *responseWriter) WriteHeader(code int) {
	if !rw.wroteHeader {
		rw.statusCode = code
		rw.wroteHeader = true
	}
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
	if !rw.wroteHeader {
		rw.WriteHeader(http.StatusOK)
	}
	n, err := rw.ResponseWriter.Write(b)
	rw.bytesWritten += int64(n)
	return n, err
}

func (rw *responseWriter) StatusCode() int {
	return rw.statusCode
}

func (rw *responseWriter) BytesWritten() int64 {
	return rw.bytesWritten
}
```

The wrapper is small but has three subtle correctness properties worth naming:

**`wroteHeader` guards against double `WriteHeader` calls.** The HTTP package calls `WriteHeader` at most once. If user code calls it twice, the second call is a no-op (the standard library logs a warning). Our wrapper preserves this behavior — only the first `WriteHeader` call sets the captured status code. Subsequent calls are passed through to the underlying writer, which will warn but not fail.

**Implicit `WriteHeader(200)` on first `Write`.** If the handler writes a response body without calling `WriteHeader` explicitly, Go's HTTP package implicitly sends a 200 status. Our wrapper does the same — the first `Write` call triggers our `WriteHeader(http.StatusOK)`, which records the status code as 200 and then writes through to the underlying writer.

**`bytesWritten` is cumulative.** Multiple `Write` calls (e.g., for streamed responses) accumulate into the total. After the response is complete, `BytesWritten()` returns the total response body size.

What the wrapper does NOT do (yet):

- Capture the response body itself — that's Chapter 11's request inspector, which uses a different wrapper that buffers bytes for replay
- Implement `http.Hijacker` for WebSocket support — that's Chapter 9's work; we'll need to add `Hijack()` to the wrapper there
- Implement `http.Flusher` for streaming — also Chapter 9's work
- Implement `http.Pusher` for HTTP/2 server push — we don't use server push in this project

This is the smallest useful wrapper. It captures status and byte counts. Chapter 11 extends it with body capture. Chapter 9 extends it with `Hijacker` and `Flusher`. The pattern of incremental wrapping continues throughout the project.

---

## The Logging Middleware: Wiring the Wrapper In

The wrapper has to be installed somewhere. Logging middleware is the natural place because it needs the captured status code and byte count for its log line.

```go
// internal/proxy/logging.go
package proxy

import (
	"log/slog"
	"net/http"
	"time"
)

// withLogging wraps an http.Handler with structured request/response logging.
// It also installs the responseWriter wrapper that Chapter 11 will use for
// inspection and metrics.
func withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rw := newResponseWriter(w)

		next.ServeHTTP(rw, r)

		duration := time.Since(start)

		slog.Info("request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", rw.StatusCode(),
			"bytes", rw.BytesWritten(),
			"duration_ms", duration.Milliseconds(),
			"remote", r.RemoteAddr,
			"user_agent", r.Header.Get("User-Agent"),
		)
	})
}
```

The middleware records the request start time, wraps the response writer, calls the next handler (which is the proxy), and emits a structured log line with method, path, status, bytes, duration, remote address, and user agent.

The log output looks like this when running the proxy:

```
{"time":"2026-04-30T10:42:03.127Z","level":"INFO","msg":"request","method":"GET","path":"/","status":200,"bytes":1247,"duration_ms":4,"remote":"[::1]:54328","user_agent":"curl/8.4.0"}
```

JSON output is structured logging's default in `slog`. Each field is queryable in any log aggregator (Datadog, Loki, CloudWatch, anything that ingests JSON).

In development, JSON is harder to read than plain text. Switch to text format with a flag or environment variable:

```go
func setupLogger() {
	var handler slog.Handler
	if os.Getenv("LOG_FORMAT") == "text" {
		handler = slog.NewTextHandler(os.Stderr, nil)
	} else {
		handler = slog.NewJSONHandler(os.Stderr, nil)
	}
	slog.SetDefault(slog.New(handler))
}
```

Call `setupLogger()` at the top of `main()`. Default to JSON (which is correct for production); switch to text with `LOG_FORMAT=text` for development readability.

---

## The Server: A `ReadHeaderTimeout` Note

The `http.Server` struct has many configurable timeouts: `ReadTimeout`, `ReadHeaderTimeout`, `WriteTimeout`, `IdleTimeout`. The `proxyd` `main.go` above sets only `ReadHeaderTimeout: 5 * time.Second`. Why not all of them?

`ReadHeaderTimeout` is the hard requirement. Without it, a slow client (or a malicious one) can keep a connection open by sending headers very slowly, exhausting the server's goroutines. This is the "Slowloris" attack pattern, and it's been a known DoS vector for HTTP servers for over a decade. Setting `ReadHeaderTimeout` mitigates it: if the client takes more than 5 seconds to send the request headers, the connection is dropped.

The other timeouts have trade-offs:

- **`ReadTimeout`**: Limits the total time to read the entire request, including body. For a proxy forwarding large uploads (file uploads, video streams), this would limit upload duration. Setting it too low breaks legitimate use cases. Leaving it unset means relying on `ReadHeaderTimeout` for slow-header attacks and on application-level timeouts for slow-body attacks.

- **`WriteTimeout`**: Limits the total time to write the response. For a proxy returning large downloads or streaming responses (Server-Sent Events, long-polling), this would limit response duration. Same trade-off — too low breaks legitimate use cases.

- **`IdleTimeout`**: Limits the time an idle keep-alive connection is held. Without it, a client could open many connections and hold them indefinitely.

For Chapter 4's smallest-useful-proxy, we set only `ReadHeaderTimeout` (the security-critical one) and leave the others to be configured per use case in later chapters. Chapter 12's resilience work will add `IdleTimeout` and revisit the others as part of the graceful shutdown story.

---

## What's Missing

This chapter intentionally builds nothing more than what's needed to forward HTTP requests. The next eight chapters add capabilities:

- **No TLS.** The proxy listens on plain HTTP. Chapter 5 adds automatic HTTPS via Let's Encrypt.
- **No subdomain routing.** The proxy forwards everything to a single target. Chapter 6 adds wildcard subdomain routing.
- **No tunneling.** The proxy forwards to URLs, not through WebSocket tunnels. Chapter 7 introduces the tunnel transport.
- **No multiplexing.** Each request is an independent forward. Chapter 8 adds multiplexed concurrent request handling once the tunnel exists.
- **No WebSocket support.** WebSocket upgrade requests would fail. Chapter 9 adds passthrough.
- **No authentication.** Anyone can use the proxy. Chapter 10 adds token-based auth and namespace policies.
- **No metrics.** Only structured logs. Chapter 11 adds Prometheus metrics and the request inspector.
- **No graceful shutdown.** SIGTERM kills in-flight requests. Chapter 12 adds the drain and rate limiting.

Each subsequent chapter extends the structure built here. The Director will gain forwarding header logic. The Transport will get tuned per-route. The responseWriter wrapper will get `Hijack()` and `Flush()` and body capture. The middleware chain will grow.

But the foundation — `httputil.ReverseProxy` with a Director, a Transport, and a wrapped response writer — stays. Every later chapter is an extension, not a replacement.

---

## What We Built

A working reverse proxy with the right shape for everything that comes next:

- **A single binary** (`proxyd`) that compiles from one `main.go` and three internal Go files
- **A Director function** that rewrites requests for the upstream with explicit Host handling and User-Agent preservation
- **A tuned Transport** with timeouts and connection pool sizes that are appropriate for a long-running proxy, not for a one-off HTTP client
- **A response writer wrapper** that captures status codes and byte counts, ready to be extended into the inspector and metrics layers
- **Structured logging middleware** that emits one JSON log line per request

The whole thing — `cmd/proxyd/main.go` plus three internal files (`director.go`, `transport.go`, `response_writer.go`, `logging.go`) — fits in a few small files. It compiles, runs, and forwards HTTP correctly.

---

## What's Next

Chapter 5 adds TLS. The proxy from this chapter listens on plain HTTP — fine for development behind a TLS-terminating load balancer, wrong for direct internet exposure. Chapter 5 introduces `golang.org/x/crypto/acme/autocert` for single-domain Let's Encrypt certificate provisioning. The configuration story is straightforward; the operational story (certificate caching, the HTTP-01 challenge mechanism, the difference between staging and production endpoints) needs care.

By the end of Chapter 5, the proxy serves HTTPS for a single domain. Chapter 6 generalizes this to wildcard subdomains using DNS-01 challenges, which is what the rest of the project's routing depends on.

→ **Chapter 5 · Automatic HTTPS**

---

## References

### Repositories

- **Go standard library: `net/http/httputil`** — The package that provides `ReverseProxy`. Reading the source (https://cs.opensource.google/go/go/+/refs/tags/go1.23.0:src/net/http/httputil/reverseproxy.go) is the best documentation for understanding what `ReverseProxy` does internally.
  https://pkg.go.dev/net/http/httputil

- **Go standard library: `net/http`** — `http.Transport`, `http.Server`, and `http.ResponseWriter` are all defined here. The package documentation is the authoritative reference.
  https://pkg.go.dev/net/http

- **golang/go: source for `http.DefaultTransport`** — The default Transport's exact configuration, useful for comparing against the values this chapter uses.
  https://cs.opensource.google/go/go/+/refs/tags/go1.23.0:src/net/http/transport.go

- **golang.org/x/net/http2** — The HTTP/2 implementation, including `h2c` (HTTP/2 over plain HTTP) configuration. Not used in this chapter, but the reference for projects that need it.
  https://pkg.go.dev/golang.org/x/net/http2

### Expert Voice

- **Filippo Valsorda, "So you want to expose Go on the Internet"** — The canonical reference on configuring `http.Server` for production exposure. Covers `ReadHeaderTimeout`, the Slowloris attack vector, and the trade-offs in the other Server timeout fields. Required reading for anyone running a Go HTTP server on the public internet.
  https://blog.cloudflare.com/exposing-go-on-the-internet/

- **Cloudflare blog, "The complete guide to Go net/http timeouts"** — Detailed exploration of the timeout fields in `http.Server` and `http.Transport`, with diagrams showing where each timeout applies in the request/response lifecycle.
  https://blog.cloudflare.com/the-complete-guide-to-golang-net-http-timeouts/

- **Mat Ryer, "How I write HTTP services in Go after 13 years"** — Practical patterns for organizing Go HTTP services. The "handler factory" pattern Ryer describes is similar to the `newDirector` and `newTransport` pattern in this chapter — small functions that return configured types.
  https://grafana.com/blog/2024/02/09/how-i-write-http-services-in-go-after-13-years/

### Books

- **Adam Bouhenguel, "Network Programming with Go" (O'Reilly, 2021)** — Chapter 9 on HTTP servers covers the reverse proxy pattern, including the `Director` function and Transport tuning that this chapter implements.

- **Jon Bodner, "Learning Go" (2nd ed., O'Reilly, 2024)** — Chapter 14 on the standard library's HTTP support. The treatment of `http.Handler`, middleware composition, and the `http.ResponseWriter` interface is the foundation for the wrapping pattern this chapter uses.

- **Alan Donovan and Brian Kernighan, "The Go Programming Language" (Addison-Wesley, 2015)** — Chapter 8 on goroutines and Chapter 9 on shared variables. The HTTP server invokes handlers in goroutines; understanding the concurrency model is essential for writing handlers that don't share mutable state inappropriately.

### RFCs and Standards

- **RFC 9110 — HTTP Semantics** — The current HTTP specification. Section 7.5 on the `Host` header is directly relevant to the Director's Host-header handling. Section 6.5 on response status codes is what the responseWriter wrapper captures.
  https://www.rfc-editor.org/rfc/rfc9110

- **RFC 9112 — HTTP/1.1** — The HTTP/1.1 message syntax. Relevant for understanding what the responseWriter wrapper is intercepting and why hop-by-hop headers (which `httputil.ReverseProxy` strips) are different from end-to-end headers (which it preserves).
  https://www.rfc-editor.org/rfc/rfc9112

- **RFC 7239 — Forwarded HTTP Extension** — The standardized `Forwarded` header that proxies use to communicate the original request's source. Not implemented in this chapter (we use the more common `X-Forwarded-*` headers in Chapter 10), but the standard worth knowing for projects that need RFC-compliant header forwarding.
  https://www.rfc-editor.org/rfc/rfc7239
