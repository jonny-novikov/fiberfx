// internal/pgdb/conn.go
// PostgreSQL connection pool using pgx/v5

package pgdb

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Connect creates a new PostgreSQL connection pool
func Connect(ctx context.Context, cfg *Config) (*pgxpool.Pool, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}

	poolConfig, err := pgxpool.ParseConfig(cfg.ConnString())
	if err != nil {
		return nil, fmt.Errorf("parse config: %w", err)
	}

	// Pool settings
	poolConfig.MaxConns = 5
	poolConfig.MinConns = 1
	poolConfig.MaxConnLifetime = 30 * time.Minute
	poolConfig.MaxConnIdleTime = 5 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("connect: %w", err)
	}

	// Verify connection
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping: %w", err)
	}

	return pool, nil
}

// QuickConnect creates a connection with a short timeout for health checks
func QuickConnect(cfg *Config) (*pgxpool.Pool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return Connect(ctx, cfg)
}
