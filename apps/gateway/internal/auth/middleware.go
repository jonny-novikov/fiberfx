package auth

import (
	"context"
	"net/http"
	"strings"
)

// contextKey is a custom type for context keys
type contextKey string

const (
	// ClaimsContextKey is the key for storing claims in context
	ClaimsContextKey contextKey = "claims"
)

// Middleware creates an authentication middleware
func (h *Handler) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var tokenString string

		// Try cookie first
		if cookie, err := r.Cookie(h.cfg.CookieName); err == nil && cookie.Value != "" {
			tokenString = cookie.Value
		}

		// Fallback to Authorization header
		if tokenString == "" {
			authHeader := r.Header.Get("Authorization")
			if authHeader != "" {
				parts := strings.SplitN(authHeader, " ", 2)
				if len(parts) == 2 && strings.EqualFold(parts[0], "bearer") {
					tokenString = parts[1]
				}
			}
		}

		// No token found
		if tokenString == "" {
			jsonError(w, http.StatusUnauthorized, "NO_TOKEN", "Authentication required")
			return
		}

		// Validate token
		claims, err := h.ValidateToken(tokenString)
		if err != nil {
			// Clear invalid cookie
			http.SetCookie(w, &http.Cookie{
				Name:     h.cfg.CookieName,
				Value:    "",
				Path:     "/",
				MaxAge:   -1,
				HttpOnly: true,
			})
			jsonError(w, http.StatusUnauthorized, "INVALID_TOKEN", "Token is invalid or expired")
			return
		}

		// Add claims to context
		ctx := context.WithValue(r.Context(), ClaimsContextKey, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// MiddlewareWithRedirect creates auth middleware that redirects to login page on failure
func (h *Handler) MiddlewareWithRedirect(loginPath string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			var tokenString string

			// Try cookie first
			if cookie, err := r.Cookie(h.cfg.CookieName); err == nil && cookie.Value != "" {
				tokenString = cookie.Value
			}

			// Fallback to Authorization header
			if tokenString == "" {
				authHeader := r.Header.Get("Authorization")
				if authHeader != "" {
					parts := strings.SplitN(authHeader, " ", 2)
					if len(parts) == 2 && strings.EqualFold(parts[0], "bearer") {
						tokenString = parts[1]
					}
				}
			}

			// No token found - redirect to login
			if tokenString == "" {
				http.Redirect(w, r, loginPath, http.StatusFound)
				return
			}

			// Validate token
			claims, err := h.ValidateToken(tokenString)
			if err != nil {
				// Clear invalid cookie
				http.SetCookie(w, &http.Cookie{
					Name:     h.cfg.CookieName,
					Value:    "",
					Path:     "/",
					MaxAge:   -1,
					HttpOnly: true,
				})
				// Redirect to login
				http.Redirect(w, r, loginPath, http.StatusFound)
				return
			}

			// Add claims to context
			ctx := context.WithValue(r.Context(), ClaimsContextKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// OptionalMiddleware validates token if present but doesn't require it
func (h *Handler) OptionalMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var tokenString string

		// Try cookie first
		if cookie, err := r.Cookie(h.cfg.CookieName); err == nil && cookie.Value != "" {
			tokenString = cookie.Value
		}

		// Fallback to Authorization header
		if tokenString == "" {
			authHeader := r.Header.Get("Authorization")
			if authHeader != "" {
				parts := strings.SplitN(authHeader, " ", 2)
				if len(parts) == 2 && strings.EqualFold(parts[0], "bearer") {
					tokenString = parts[1]
				}
			}
		}

		// If token present, validate it
		if tokenString != "" {
			if claims, err := h.ValidateToken(tokenString); err == nil {
				ctx := context.WithValue(r.Context(), ClaimsContextKey, claims)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}
		}

		// Continue without auth
		next.ServeHTTP(w, r)
	})
}

// GetClaimsFromContext retrieves claims from context
func GetClaimsFromContext(ctx context.Context) *Claims {
	if claims, ok := ctx.Value(ClaimsContextKey).(*Claims); ok {
		return claims
	}
	return nil
}

// IsAuthenticated checks if request has valid authentication
func IsAuthenticated(ctx context.Context) bool {
	return GetClaimsFromContext(ctx) != nil
}
