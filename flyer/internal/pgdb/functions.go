// internal/pgdb/functions.go
// Branded ID function verification and creation

package pgdb

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	"github.com/jackc/pgx/v5/pgxpool"
)

// RequiredFunctions lists the branded ID functions that must exist
var RequiredFunctions = []string{
	"encode_base62",
	"decode_base62",
	"extract_snowflake_ts",
	"format_branded_id",
}

// FunctionTestQueries maps function names to test queries
var FunctionTestQueries = map[string]string{
	"encode_base62":        "SELECT encode_base62(1)",
	"decode_base62":        "SELECT decode_base62('00000000001')",
	"extract_snowflake_ts": "SELECT extract_snowflake_ts(253497805168701440)",
	"format_branded_id":    "SELECT format_branded_id('TST', 253497805168701440)",
}

// FunctionCheckResult represents the result of checking a function
type FunctionCheckResult struct {
	Name    string
	Exists  bool
	Error   error
}

// CheckFunctions verifies that all required branded ID functions exist and work
func CheckFunctions(ctx context.Context, pool *pgxpool.Pool) ([]FunctionCheckResult, error) {
	results := make([]FunctionCheckResult, 0, len(RequiredFunctions))

	for _, fn := range RequiredFunctions {
		result := FunctionCheckResult{Name: fn}

		query := FunctionTestQueries[fn]
		if query == "" {
			result.Error = fmt.Errorf("no test query defined")
			results = append(results, result)
			continue
		}

		var dummy interface{}
		err := pool.QueryRow(ctx, query).Scan(&dummy)
		if err != nil {
			result.Error = err
		} else {
			result.Exists = true
		}

		results = append(results, result)
	}

	return results, nil
}

// CreateFunctions executes the functions.sql script to install branded ID functions
func CreateFunctions(ctx context.Context, pool *pgxpool.Pool, sqlDir string) error {
	// Find functions.sql
	functionsPath := filepath.Join(sqlDir, "functions.sql")
	if sqlDir == "" {
		// Try to auto-detect
		candidates := []string{
			"phoenix/sql/functions.sql",
			"../phoenix/sql/functions.sql",
			"../../phoenix/sql/functions.sql",
		}
		for _, candidate := range candidates {
			if _, err := os.Stat(candidate); err == nil {
				functionsPath = candidate
				break
			}
		}
	}

	// Read SQL file
	content, err := os.ReadFile(functionsPath)
	if err != nil {
		return fmt.Errorf("read functions.sql: %w (path: %s)", err, functionsPath)
	}

	// Execute SQL
	_, err = pool.Exec(ctx, string(content))
	if err != nil {
		return fmt.Errorf("execute functions.sql: %w", err)
	}

	return nil
}
