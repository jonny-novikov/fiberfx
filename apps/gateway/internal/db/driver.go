package db

import "context"

// Driver defines the interface for database drivers
type Driver interface {
	// Query executes a single SQL query and returns the result
	Query(ctx context.Context, sql string) (*QueryResult, error)

	// Batch executes multiple SQL queries and returns all results
	Batch(ctx context.Context, queries []string) ([]QueryResult, error)

	// Close closes the database connection
	Close() error

	// DriverType returns the driver type identifier ("postgres" or "sqlite")
	DriverType() string
}
