// Package handler holds the echo-courses HTTP handlers. ec.1 ships the health
// probe; ec.4 adds the courses index and the course-detail handlers.
package handler

import (
	"net/http"

	"github.com/labstack/echo/v5"
)

// Health is the liveness/readiness probe. ec.6's fly.toml health check and the
// container HEALTHCHECK both hit GET /healthz.
func Health(c *echo.Context) error {
	return c.String(http.StatusOK, "ok")
}
