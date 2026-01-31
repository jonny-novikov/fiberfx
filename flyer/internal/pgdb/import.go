// internal/pgdb/import.go
// SQL script execution via psql subprocess

package pgdb

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
)

// ImportScripts defines the SQL scripts to execute in order
var ImportScripts = []string{
	"00-preflight.sql",
	"01-clean.sql",
	"02-import-emoji-sets.sql",
	"03-import-players.sql",
	"04-transform-player-resources.sql",
	"05-import-shop-packages.sql",
	"06-import-game-rooms.sql",
	"07-verify.sql",
}

// ImportOptions controls import behavior
type ImportOptions struct {
	SkipClean bool   // Skip 01-clean.sql
	DryRun    bool   // Wrap in BEGIN/ROLLBACK
	SQLDir    string // Directory containing initial_data scripts
}

// ScriptResult holds the result of executing a script
type ScriptResult struct {
	Script  string
	Success bool
	Output  string
	Error   error
}

// ExecuteScript runs a single SQL script via psql
func ExecuteScript(cfg *Config, scriptPath string) (*ScriptResult, error) {
	result := &ScriptResult{
		Script: filepath.Base(scriptPath),
	}

	// Build psql command
	cmd := exec.Command("psql",
		"-h", cfg.Host,
		"-p", strconv.Itoa(cfg.Port),
		"-U", cfg.User,
		"-d", cfg.Database,
		"-v", "ON_ERROR_STOP=1",
		"-f", scriptPath,
	)

	// Set PGPASSWORD environment variable
	cmd.Env = append(os.Environ(), "PGPASSWORD="+cfg.Password)

	// Capture output
	output, err := cmd.CombinedOutput()
	result.Output = string(output)

	if err != nil {
		result.Error = fmt.Errorf("psql error: %w", err)
		return result, result.Error
	}

	result.Success = true
	return result, nil
}

// ExecuteAllScripts runs all import scripts in order
func ExecuteAllScripts(cfg *Config, opts ImportOptions) ([]ScriptResult, error) {
	// Find SQL directory containing initial_data scripts
	sqlDir := opts.SQLDir
	if sqlDir != "" {
		// If sqlDir is provided, check if it contains initial_data or is initial_data itself
		initialDataPath := filepath.Join(sqlDir, "initial_data")
		if _, err := os.Stat(initialDataPath); err == nil {
			sqlDir = initialDataPath
		}
		// Otherwise assume sqlDir is the initial_data directory itself
	} else {
		// Auto-detect initial_data directory
		candidates := []string{
			"phoenix/sql/initial_data",
			"../phoenix/sql/initial_data",
			"../../phoenix/sql/initial_data",
		}
		for _, candidate := range candidates {
			if _, err := os.Stat(candidate); err == nil {
				sqlDir = candidate
				break
			}
		}
	}

	if sqlDir == "" {
		return nil, fmt.Errorf("cannot find initial_data directory (tried phoenix/sql/initial_data)")
	}

	results := make([]ScriptResult, 0)

	if opts.DryRun {
		// Create wrapper script for dry-run
		wrapperPath, err := createDryRunWrapper(sqlDir, opts.SkipClean)
		if err != nil {
			return nil, fmt.Errorf("create dry-run wrapper: %w", err)
		}
		defer os.Remove(wrapperPath)

		result, err := ExecuteScript(cfg, wrapperPath)
		results = append(results, *result)
		if err != nil {
			return results, err
		}
	} else {
		// Execute scripts individually
		for _, script := range ImportScripts {
			// Skip clean if requested
			if opts.SkipClean && script == "01-clean.sql" {
				results = append(results, ScriptResult{Script: script, Success: true, Output: "SKIPPED"})
				continue
			}

			scriptPath := filepath.Join(sqlDir, script)
			result, err := ExecuteScript(cfg, scriptPath)
			results = append(results, *result)

			if err != nil {
				return results, err // Stop on first error (ON_ERROR_STOP)
			}
		}
	}

	return results, nil
}

// createDryRunWrapper creates a temporary SQL file that wraps all scripts in a transaction
func createDryRunWrapper(sqlDir string, skipClean bool) (string, error) {
	// Create temp file
	tmpFile, err := os.CreateTemp("", "flyer-dryrun-*.sql")
	if err != nil {
		return "", err
	}
	defer tmpFile.Close()

	// Write wrapper content
	fmt.Fprintln(tmpFile, "-- Dry-run wrapper: all changes will be rolled back")
	fmt.Fprintln(tmpFile, "BEGIN;")
	fmt.Fprintln(tmpFile)

	for _, script := range ImportScripts {
		if skipClean && script == "01-clean.sql" {
			fmt.Fprintf(tmpFile, "-- SKIPPED: %s\n", script)
			continue
		}
		scriptPath := filepath.Join(sqlDir, script)
		fmt.Fprintf(tmpFile, "\\echo Running: %s\n", script)
		fmt.Fprintf(tmpFile, "\\i %s\n", scriptPath)
		fmt.Fprintln(tmpFile)
	}

	fmt.Fprintln(tmpFile, "-- Dry-run: rolling back all changes")
	fmt.Fprintln(tmpFile, "ROLLBACK;")

	return tmpFile.Name(), nil
}

// FindSQLDir attempts to locate the phoenix/sql directory
func FindSQLDir() string {
	candidates := []string{
		"phoenix/sql",
		"../phoenix/sql",
		"../../phoenix/sql",
		"../../../phoenix/sql",
	}
	for _, candidate := range candidates {
		if info, err := os.Stat(candidate); err == nil && info.IsDir() {
			return candidate
		}
	}
	return ""
}
