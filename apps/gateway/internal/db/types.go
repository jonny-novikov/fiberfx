package db

// QueryRequest matches the client's request shape from LocalPostgresQueryable
type QueryRequest struct {
	Query   string   `json:"query,omitempty"`
	Queries []string `json:"queries,omitempty"`
}

// QueryResult matches Outerbase's response shape
type QueryResult struct {
	Items   []map[string]any `json:"items"`
	Headers []ColumnHeader   `json:"headers"`
	Stat    QueryStat        `json:"stat"`
}

// ColumnHeader contains column metadata
// For PostgreSQL: Type is the OID (int)
// For SQLite: Type would be the type name (string)
type ColumnHeader struct {
	Name string `json:"name"`
	Type any    `json:"type"`
}

// QueryStat contains query execution statistics
type QueryStat struct {
	RowsAffected    int  `json:"rowsAffected"`
	RowsRead        *int `json:"rowsRead"`
	RowsWritten     *int `json:"rowsWritten"`
	QueryDurationMs *int `json:"queryDurationMs"`
}

// SingleQueryResponse wraps a single query result
type SingleQueryResponse struct {
	Response QueryResult `json:"response"`
}

// BatchQueryResponse wraps multiple query results
type BatchQueryResponse struct {
	Response []QueryResult `json:"response"`
}

// ErrorResponse for errors
type ErrorResponse struct {
	Error string `json:"error"`
}
