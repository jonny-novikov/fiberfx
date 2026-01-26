package db

import (
	"context"
	"database/sql"
	"time"

	_ "modernc.org/sqlite"
)

// SQLiteDriver implements Driver for SQLite using modernc.org/sqlite
type SQLiteDriver struct {
	db *sql.DB
}

// NewSQLiteDriver creates a new SQLite driver
func NewSQLiteDriver(dbPath string) (*SQLiteDriver, error) {
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, err
	}

	// Configure connection pool
	db.SetMaxOpenConns(1) // SQLite prefers single connection
	db.SetMaxIdleConns(1)

	// Test connection
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, err
	}

	return &SQLiteDriver{db: db}, nil
}

// DriverType returns "sqlite"
func (d *SQLiteDriver) DriverType() string {
	return "sqlite"
}

// Query executes a single SQL query
func (d *SQLiteDriver) Query(ctx context.Context, sqlStmt string) (*QueryResult, error) {
	start := time.Now()

	rows, err := d.db.QueryContext(ctx, sqlStmt)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Get column info
	colTypes, err := rows.ColumnTypes()
	if err != nil {
		return nil, err
	}

	headers := make([]ColumnHeader, len(colTypes))
	for i, ct := range colTypes {
		headers[i] = ColumnHeader{
			Name: ct.Name(),
			Type: ct.DatabaseTypeName(), // Return type name string for SQLite
		}
	}

	// Get column names
	cols, err := rows.Columns()
	if err != nil {
		return nil, err
	}

	// Collect rows
	items := []map[string]any{}
	for rows.Next() {
		values := make([]any, len(cols))
		valuePtrs := make([]any, len(cols))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, err
		}

		row := make(map[string]any)
		for i, col := range cols {
			row[col] = convertSQLiteValue(values[i])
		}
		items = append(items, row)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	durationMs := int(time.Since(start).Milliseconds())

	return &QueryResult{
		Items:   items,
		Headers: headers,
		Stat: QueryStat{
			RowsAffected:    0, // Not available for SELECT in database/sql
			RowsRead:        nil,
			RowsWritten:     nil,
			QueryDurationMs: &durationMs,
		},
	}, nil
}

// Batch executes multiple SQL queries
func (d *SQLiteDriver) Batch(ctx context.Context, queries []string) ([]QueryResult, error) {
	results := make([]QueryResult, len(queries))
	for i, q := range queries {
		result, err := d.Query(ctx, q)
		if err != nil {
			return nil, err
		}
		results[i] = *result
	}
	return results, nil
}

// Close closes the SQLite database
func (d *SQLiteDriver) Close() error {
	return d.db.Close()
}

// convertSQLiteValue converts SQLite values to JSON-serializable types
func convertSQLiteValue(v any) any {
	switch val := v.(type) {
	case []byte:
		// Convert byte arrays to array of ints for JSON
		result := make([]int, len(val))
		for i, b := range val {
			result[i] = int(b)
		}
		return result
	default:
		return v
	}
}
