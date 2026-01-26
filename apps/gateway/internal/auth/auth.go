package auth

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/fireheadz/codemoji-gateway/internal/config"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Claims represents JWT claims
type Claims struct {
	jwt.RegisteredClaims
	Username   string `json:"username"`
	TelegramID int64  `json:"telegram_id"`
	Role       string `json:"role"`
}

// AdminUser represents a row from admin_users table
type AdminUser struct {
	ID               int64
	TelegramID       int64
	TelegramUsername string
	Login            string
	Password         string
	Role             string
	IsActive         bool
}

// Handler handles authentication
type Handler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

// NewHandler creates a new auth handler
func NewHandler(cfg *config.Config, pool *pgxpool.Pool) *Handler {
	return &Handler{cfg: cfg, pool: pool}
}

// LoginRequest is the login request payload
type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// LoginResponse is the login response payload
type LoginResponse struct {
	Token     string `json:"token"`
	Username  string `json:"username"`
	ExpiresAt int64  `json:"expiresAt"`
}

// HandleLogin processes login requests
func (h *Handler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	// Handle CORS preflight
	if r.Method == http.MethodOptions {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		jsonError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "POST required")
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid JSON body")
		return
	}

	// Query admin_users by telegram_username
	admin, err := h.findAdminByUsername(r.Context(), req.Username)
	if err != nil {
		jsonError(w, http.StatusUnauthorized, "INVALID_CREDENTIALS", "Invalid username or password")
		return
	}

	if !admin.IsActive {
		jsonError(w, http.StatusUnauthorized, "ACCOUNT_DISABLED", "Account is disabled")
		return
	}

	// Check per-user password first, fallback to shared MASTER_PASSWORD
	validPassword := false
	if admin.Password != "" && req.Password == admin.Password {
		validPassword = true
	} else if h.cfg.MasterPass != "" && req.Password == h.cfg.MasterPass {
		validPassword = true
	}
	if !validPassword {
		jsonError(w, http.StatusUnauthorized, "INVALID_CREDENTIALS", "Invalid username or password")
		return
	}

	// Generate JWT
	token, expiresAt, err := h.generateToken(admin)
	if err != nil {
		jsonError(w, http.StatusInternalServerError, "TOKEN_ERROR", "Failed to generate token")
		return
	}

	// Set HTTP-only cookie for the gateway
	http.SetCookie(w, &http.Cookie{
		Name:     h.cfg.CookieName,
		Value:    token,
		Path:     "/",
		Domain:   h.cfg.CookieDomain,
		Expires:  expiresAt,
		HttpOnly: true,
		Secure:   h.cfg.CookieSecure,
		SameSite: http.SameSiteLaxMode,
	})

	// Also return token in response for API clients
	jsonResponse(w, http.StatusOK, LoginResponse{
		Token:     token,
		Username:  admin.TelegramUsername,
		ExpiresAt: expiresAt.Unix(),
	})
}

// HandleLogout clears the auth cookie
func (h *Handler) HandleLogout(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     h.cfg.CookieName,
		Value:    "",
		Path:     "/",
		Domain:   h.cfg.CookieDomain,
		MaxAge:   -1,
		HttpOnly: true,
		Secure:   h.cfg.CookieSecure,
		SameSite: http.SameSiteLaxMode,
	})

	jsonResponse(w, http.StatusOK, map[string]string{"status": "logged_out"})
}

// HandleMe returns current user info
func (h *Handler) HandleMe(w http.ResponseWriter, r *http.Request) {
	claims := GetClaimsFromContext(r.Context())
	if claims == nil {
		jsonError(w, http.StatusUnauthorized, "NOT_AUTHENTICATED", "Not authenticated")
		return
	}

	jsonResponse(w, http.StatusOK, map[string]interface{}{
		"username":    claims.Username,
		"telegram_id": claims.TelegramID,
		"role":        claims.Role,
		"issued_at":   claims.IssuedAt.Unix(),
		"expires_at":  claims.ExpiresAt.Unix(),
	})
}

// findAdminByUsername queries admin_users table by login or telegram_username
func (h *Handler) findAdminByUsername(ctx context.Context, username string) (*AdminUser, error) {
	query := `
		SELECT id, telegram_id, telegram_username, COALESCE(login, telegram_username), COALESCE(password, ''), role, is_active
		FROM admin_users
		WHERE (login = $1 OR telegram_username = $1) AND deleted_at IS NULL
	`

	var admin AdminUser
	err := h.pool.QueryRow(ctx, query, username).Scan(
		&admin.ID,
		&admin.TelegramID,
		&admin.TelegramUsername,
		&admin.Login,
		&admin.Password,
		&admin.Role,
		&admin.IsActive,
	)
	if err != nil {
		return nil, err
	}

	return &admin, nil
}

// generateToken creates a JWT for the admin user
func (h *Handler) generateToken(admin *AdminUser) (string, time.Time, error) {
	expiresAt := time.Now().Add(h.cfg.JWTExpiry)

	claims := &Claims{
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   admin.TelegramUsername,
			Issuer:    h.cfg.JWTIssuer,
			Audience:  jwt.ClaimStrings{h.cfg.JWTAudience},
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
		Username:   admin.TelegramUsername,
		TelegramID: admin.TelegramID,
		Role:       admin.Role,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(h.cfg.JWTSecret)
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}

// ValidateToken validates a JWT and returns claims
func (h *Handler) ValidateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return h.cfg.JWTSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, jwt.ErrTokenInvalidClaims
}

// Helper functions

func jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func jsonError(w http.ResponseWriter, status int, code, message string) {
	jsonResponse(w, status, map[string]string{
		"error":   code,
		"message": message,
	})
}
