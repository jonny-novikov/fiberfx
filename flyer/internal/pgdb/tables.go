// internal/pgdb/tables.go
// Table operations: truncate, count

package pgdb

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// MigrationTables lists tables to clear in FK-safe order (children first)
var MigrationTables = []string{
	"game_rooms",        // FK → emoji_sets, players
	"shop_packages",     // No FK
	"player_resources",  // FK → players
	"players",           // No FK
	"emoji_sets",        // No FK
}

// TableRowCount holds the row count for a table
type TableRowCount struct {
	Table string
	Count int64
}

// TruncateTables truncates all migration tables in FK-safe order
func TruncateTables(ctx context.Context, pool *pgxpool.Pool) error {
	// Use a transaction for atomicity
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	for _, table := range MigrationTables {
		query := fmt.Sprintf("TRUNCATE %s CASCADE", table)
		_, err := tx.Exec(ctx, query)
		if err != nil {
			return fmt.Errorf("truncate %s: %w", table, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit: %w", err)
	}

	return nil
}

// GetRowCounts returns the row count for each migration table
func GetRowCounts(ctx context.Context, pool *pgxpool.Pool) ([]TableRowCount, error) {
	counts := make([]TableRowCount, 0, len(MigrationTables))

	for _, table := range MigrationTables {
		var count int64
		query := fmt.Sprintf("SELECT COUNT(*) FROM %s", table)
		err := pool.QueryRow(ctx, query).Scan(&count)
		if err != nil {
			return nil, fmt.Errorf("count %s: %w", table, err)
		}
		counts = append(counts, TableRowCount{Table: table, Count: count})
	}

	return counts, nil
}
