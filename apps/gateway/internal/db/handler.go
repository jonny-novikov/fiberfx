package db

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

// Handler handles database query requests
type Handler struct {
	driver Driver
}

// NewHandler creates a new query handler with the given driver
func NewHandler(driver Driver) *Handler {
	return &Handler{driver: driver}
}

// HandleQuery handles POST /api/db/query
func (h *Handler) HandleQuery(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodOptions {
		// CORS preflight
		h.setCORSHeaders(w)
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		h.writeError(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	h.setCORSHeaders(w)

	var req QueryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	ctx := r.Context()

	// Handle batch queries
	if len(req.Queries) > 0 {
		results, err := h.driver.Batch(ctx, req.Queries)
		if err != nil {
			slog.Error("Batch query failed", "error", err, "driver", h.driver.DriverType())
			h.writeError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		h.writeJSON(w, BatchQueryResponse{Response: results})
		return
	}

	// Handle single query
	if req.Query != "" {
		result, err := h.driver.Query(ctx, req.Query)
		if err != nil {
			slog.Error("Query failed", "error", err, "query", truncateQuery(req.Query), "driver", h.driver.DriverType())
			h.writeError(w, err.Error(), http.StatusInternalServerError)
			return
		}
		h.writeJSON(w, SingleQueryResponse{Response: *result})
		return
	}

	h.writeError(w, "Missing query or queries parameter", http.StatusBadRequest)
}

// writeJSON writes a JSON response
func (h *Handler) writeJSON(w http.ResponseWriter, data any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// writeError writes an error response
func (h *Handler) writeError(w http.ResponseWriter, message string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(ErrorResponse{Error: message})
}

// setCORSHeaders sets CORS headers for the response
func (h *Handler) setCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
}

// truncateQuery truncates query for logging
func truncateQuery(q string) string {
	if len(q) > 100 {
		return q[:100] + "..."
	}
	return q
}
