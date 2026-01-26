package db

import (
	"context"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PostgresDriver implements Driver for PostgreSQL using pgx
type PostgresDriver struct {
	pool *pgxpool.Pool
}

// NewPostgresDriver creates a new PostgreSQL driver
func NewPostgresDriver(pool *pgxpool.Pool) *PostgresDriver {
	return &PostgresDriver{pool: pool}
}

// DriverType returns "postgres"
func (d *PostgresDriver) DriverType() string {
	return "postgres"
}

// Query executes a single SQL query
func (d *PostgresDriver) Query(ctx context.Context, sql string) (*QueryResult, error) {
	start := time.Now()

	rows, err := d.pool.Query(ctx, sql)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Get field descriptions for column metadata (OIDs)
	fieldDescs := rows.FieldDescriptions()
	headers := make([]ColumnHeader, len(fieldDescs))
	for i, fd := range fieldDescs {
		headers[i] = ColumnHeader{
			Name: fd.Name,
			Type: int(fd.DataTypeOID), // Return raw PostgreSQL OID
		}
	}

	// Collect rows
	items := []map[string]any{}
	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			return nil, err
		}
		row := make(map[string]any)
		for i, fd := range fieldDescs {
			row[fd.Name] = convertPostgresValue(values[i])
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
			RowsAffected:    int(rows.CommandTag().RowsAffected()),
			RowsRead:        nil,
			RowsWritten:     nil,
			QueryDurationMs: &durationMs,
		},
	}, nil
}

// Batch executes multiple SQL queries
func (d *PostgresDriver) Batch(ctx context.Context, queries []string) ([]QueryResult, error) {
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

// Close closes the PostgreSQL connection pool
func (d *PostgresDriver) Close() error {
	d.pool.Close()
	return nil
}

// convertPostgresValue converts PostgreSQL values to JSON-serializable types
func convertPostgresValue(v any) any {
	switch val := v.(type) {
	case []byte:
		// BYTEA: PostgreSQL hex format \x48656c6c6f
		return `\x` + hex.EncodeToString(val)
	case [16]byte:
		// UUID: RFC 4122 format 550e8400-e29b-41d4-a716-446655440000
		return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
			val[0:4], val[4:6], val[6:8], val[8:10], val[10:16])
	default:
		return v
	}
}
