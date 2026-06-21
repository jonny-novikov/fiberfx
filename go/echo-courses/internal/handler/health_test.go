package handler_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/fiberfx/echo-courses/internal/handler"
	"github.com/labstack/echo/v5"
)

// AC2: GET /healthz returns 200.
func TestHealth(t *testing.T) {
	e := echo.New()
	e.GET("/healthz", handler.Health)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
	}
	if got := rec.Body.String(); got != "ok" {
		t.Fatalf("body = %q, want %q", got, "ok")
	}
}
