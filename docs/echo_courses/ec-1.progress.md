# ec-1 — ship ledger { #ec-1 }

Rung **ec.1 — Echo v5 server scaffold** · program echo-courses (`go/echo-courses`) ·
vehicle `/echo-courses-ship ec.1` (x-mode, right-sized) · shipped 2026-06-21.

## {ec-1-ship}

**T-1 — UNDERSTAND.** ec.1 stands up the Echo v5 scaffold (boot · `GET /healthz` · static serving · graceful
shutdown · the `cmd`/`internal`/`web`/`content` layout) for `go/echo-courses`, consuming the vendored Echo
v5.2.0 at `go/echo` via `replace => ../echo`. It was built directly this session (a right-sized bootstrap) and
is green on the go/ gate + a running-binary smoke. The ship is therefore **Director-solo**: the build exists and
is verified, so no Venus/Mars fan-out — re-building green code would be FAKE-N. The live work is the independent
verify + the scoped commit.

**D-1 — vendored framework.** Echo v5 has no published release → vendor `go/echo` (the v5.2.0 snapshot) and
consume via `replace github.com/labstack/echo/v5 => ../echo`; build `GOWORK=off`, not a `go.work` member. The
repo must carry `go/echo` for echo-courses to build (Operator ruled: commit the snapshot).

**D-2 — module org.** `github.com/fiberfx/echo-courses` (matches `mcp-go` / `echomq-go`).

**D-3 — v5 API (confirmed vs the vendored source; the v4→v5 drift).** No `e.Shutdown` →
`echo.StartConfig{Address, GracefulTimeout}.Start(ctx, e)` driven by `signal.NotifyContext`; `Context` is a
struct (`*echo.Context`); `Renderer.Render(c *echo.Context, w io.Writer, name string, data any) error`;
`middleware.RequestLogger()`.

**V — verify (independent, on the as-committed tree).** `make gate` = OK (`GOWORK=off` `go build`/`vet`/`test` +
`gofmt -l .` empty); running-binary smoke `/healthz`=200, `/static/version.txt`=200, `SIGTERM`→exit 0
(graceful, not 143). Boundary clean: only `go/echo`, `go/echo-courses`, `docs/echo_courses` in scope; no
Elixir-umbrella / other-module bleed.

**S — surface.** The vendored framework (`go/echo`, 130 files) + the scaffold (`go/echo-courses`, 12 files)
were committed out-of-band by the Operator in `a701bffc [echo-courses] bootstrap project` — tracked, clean, and
byte-equal to the verified-green working tree. The remaining ship concern was the docs reconcile.

**Y — report.** ec.1 ships green. Acceptance 5/5: compiles · `/healthz` 200 · static served · `SIGTERM` drain
(exit 0) · layout present. Vendor + scaffold already committed (`a701bffc`); this run committed the docs concern
(`echo-courses.{1,2,6,roadmap}.md` reconciled to as-built + `echo-courses.1.prompt.md` + this ledger).

**Z — complete.** ec.1 shipped 2026-06-21. Next rung: **ec.2** — templating engine + base layout (the
`echo.Renderer` over `html/template` + the header/footer/card/filter partials).
