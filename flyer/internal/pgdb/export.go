// internal/pgdb/export.go
// CSV export using pgx COPY TO protocol

package pgdb

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ExportTable represents a table with its columns for CSV export
type ExportTable struct {
	Name    string
	Columns string // Comma-separated column names (excludes GENERATED columns)
}

// ExportTables defines the tables and columns for CSV export
// Excludes GENERATED ALWAYS columns: branded_id, namespace, snowflake_ts
var ExportTables = []ExportTable{
	{
		Name:    "players",
		Columns: "id, telegram_id, telegram_username, display_name, first_name, last_name, language_code, photo_url, is_premium, is_bot, auth_provider, auth_provider_id, level, xp, total_xp, title, status, role, last_seen_at, games_played, games_won, total_score, best_score, win_rate, avg_score, current_streak, best_streak, preferred_emoji_set, settings, achievements, stats, inventory, profile_metadata, feature_flags, created_at, updated_at, deleted_at, created_by, updated_by",
	},
	{
		Name:    "player_resources",
		Columns: "id, player_id, keys, bonus_keys, locked_keys, diamonds, bonus_diamonds, locked_diamonds, total_keys_earned, total_keys_spent, total_keys_purchased, total_diamonds_earned, total_diamonds_spent, total_stars_purchased, last_daily_claim_at, daily_claim_streak, created_at, updated_at, deleted_at, created_by, updated_by, version, metadata",
	},
	{
		Name:    "emoji_sets",
		Columns: "id, name, slug, description, category, emoji_count, emojis, difficulty_ratings, preview_url, is_default, is_premium, price_keys, price_diamonds, sort_order, status, created_at, updated_at, deleted_at, created_by, updated_by",
	},
	{
		Name:    "shop_packages",
		Columns: "id, name, slug, description, type, keys_amount, diamonds_amount, price_stars, bonus_percentage, is_featured, max_purchases, sort_order, status, created_at, updated_at, metadata",
	},
	{
		Name:    "game_rooms",
		Columns: "id, host_id, name, slug, code, emoji_set_id, package_id, mode, status, visibility, max_players, current_players, round_count, current_round, time_limit_seconds, settings, started_at, finished_at, scheduled_for, invite_link, created_at, updated_at, deleted_at, created_by, updated_by, version, metadata, room_config, game_state",
	},
}

// ExportResult holds the result of exporting a table
type ExportResult struct {
	Table    string
	FilePath string
	Rows     int64
	Size     int64
	Error    error
}

// ExportToCSV exports a single table to a CSV file using pgx COPY TO
func ExportToCSV(ctx context.Context, pool *pgxpool.Pool, table ExportTable, outputDir string) (*ExportResult, error) {
	result := &ExportResult{
		Table: table.Name,
	}

	// Create output directory
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		result.Error = fmt.Errorf("create output dir: %w", err)
		return result, result.Error
	}

	// Create output file
	filePath := filepath.Join(outputDir, table.Name+".csv")
	result.FilePath = filePath

	file, err := os.Create(filePath)
	if err != nil {
		result.Error = fmt.Errorf("create file: %w", err)
		return result, result.Error
	}
	defer file.Close()

	// Build COPY query
	query := fmt.Sprintf(
		"COPY (SELECT %s FROM %s ORDER BY id) TO STDOUT WITH (FORMAT csv, HEADER true, NULL '')",
		table.Columns, table.Name,
	)

	// Get a connection from the pool
	conn, err := pool.Acquire(ctx)
	if err != nil {
		result.Error = fmt.Errorf("acquire connection: %w", err)
		return result, result.Error
	}
	defer conn.Release()

	// Execute COPY TO
	tag, err := conn.Conn().PgConn().CopyTo(ctx, file, query)
	if err != nil {
		result.Error = fmt.Errorf("copy to: %w", err)
		return result, result.Error
	}

	result.Rows = tag.RowsAffected()

	// Get file size
	info, err := file.Stat()
	if err == nil {
		result.Size = info.Size()
	}

	return result, nil
}

// ExportAllTables exports all migration tables to CSV files
func ExportAllTables(ctx context.Context, pool *pgxpool.Pool, outputDir string, tables []string) ([]ExportResult, error) {
	// If no specific tables provided, use all
	tablesToExport := ExportTables
	if len(tables) > 0 {
		tablesToExport = make([]ExportTable, 0)
		for _, name := range tables {
			for _, t := range ExportTables {
				if t.Name == name {
					tablesToExport = append(tablesToExport, t)
					break
				}
			}
		}
	}

	results := make([]ExportResult, 0, len(tablesToExport))

	for _, table := range tablesToExport {
		result, _ := ExportToCSV(ctx, pool, table, outputDir)
		results = append(results, *result)
	}

	return results, nil
}

// CountExportedBytes is a writer that counts bytes written
type CountExportedBytes struct {
	Writer io.Writer
	Count  int64
}

func (c *CountExportedBytes) Write(p []byte) (int, error) {
	n, err := c.Writer.Write(p)
	c.Count += int64(n)
	return n, err
}
