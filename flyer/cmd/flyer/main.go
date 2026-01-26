// cmd/flyer/main.go
// =============================================================================
// FLYER CLI - FWHD Deployment Management Tool
// =============================================================================
//
// Pure Go CLI for managing FWHD (Fastify Worker Hot Deployment) operations.
// Uses SQLite + Litestream for deployment orchestration.
//
// Usage:
//   flyer id new PKG          # Generate new package ID
//   flyer db init             # Initialize database
//   flyer pkg create          # Register new package
//   flyer release create      # Create release from package
//   flyer deploy start        # Start deployment
//
// =============================================================================

package main

import (
	"archive/tar"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/spf13/cobra"

	"github.com/fiberfx/flyer/branded"
	"github.com/fiberfx/flyer/config"
	"github.com/fiberfx/flyer/db"
	"github.com/fiberfx/flyer/s3"
)

var (
	cfg       *config.Config
	configDir string
	dbPath    string
	version   = "dev"
	commit    = "unknown"
	buildDate = "unknown"
)

func main() {
	rootCmd := &cobra.Command{
		Use:     "flyer",
		Short:   "FWHD Deployment Management Tool",
		Long:    "Pure Go CLI for managing Fastify Worker Hot Deployment operations.",
		Version: fmt.Sprintf("%s (commit=%s built=%s)", version, commit, buildDate),
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			// Load configuration
			var err error
			if configDir != "" {
				cfg, err = config.LoadFromDir(configDir)
			} else {
				// Try common locations
				for _, dir := range []string{"/app", "/etc/flyer", "."} {
					cfg, err = config.LoadFromDir(dir)
					if err == nil {
						break
					}
				}
				// Fall back to defaults if no config found
				if cfg == nil {
					cfg = config.Default()
				}
			}

			// Apply config to dbPath if not overridden by flag
			if dbPath == "" || dbPath == "/app/data/packages.db" {
				dbPath = cfg.Database.Path
			}

			return nil
		},
	}

	// Global flags
	rootCmd.PersistentFlags().StringVar(&configDir, "config", "", "Config directory (contains flyer.conf)")
	rootCmd.PersistentFlags().StringVar(&dbPath, "db", "/app/data/packages.db", "Path to SQLite database")

	// Add subcommands
	rootCmd.AddCommand(idCmd())
	rootCmd.AddCommand(dbCmd())
	rootCmd.AddCommand(pkgCmd())
	rootCmd.AddCommand(releaseCmd())
	rootCmd.AddCommand(deployCmd())
	rootCmd.AddCommand(streamCmd())
	rootCmd.AddCommand(syncCmd())
	rootCmd.AddCommand(configCmd())

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

// =============================================================================
// CONFIG COMMANDS
// =============================================================================

func configCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Configuration operations",
	}

	// config show
	showCmd := &cobra.Command{
		Use:   "show",
		Short: "Show current configuration",
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("# Current flyer configuration")
			fmt.Println()
			fmt.Println("database {")
			fmt.Printf("    path %s;\n", cfg.Database.Path)
			fmt.Println("}")
			fmt.Println()
			fmt.Println("s3 {")
			fmt.Printf("    endpoint %s;\n", cfg.S3.Endpoint)
			fmt.Printf("    bucket   %s;\n", cfg.S3.Bucket)
			fmt.Printf("    region   %s;\n", cfg.S3.Region)
			fmt.Println("}")
			fmt.Println()
			fmt.Println("litestream {")
			fmt.Printf("    config_path    %s;\n", cfg.Litestream.ConfigPath)
			fmt.Printf("    retention_days %d;\n", cfg.Litestream.RetentionDays)
			fmt.Println("}")
			fmt.Println()
			fmt.Println("packages {")
			fmt.Printf("    dir         %s;\n", cfg.Packages.Dir)
			fmt.Printf("    entry_point %s;\n", cfg.Packages.EntryPoint)
			fmt.Println("}")
			fmt.Println()
			fmt.Println("sync {")
			fmt.Printf("    component %s;\n", cfg.Sync.Component)
			fmt.Printf("    timeout   %d;\n", cfg.Sync.Timeout)
			fmt.Println("}")
			return nil
		},
	}

	// config init
	var outputDir string
	initCmd := &cobra.Command{
		Use:   "init",
		Short: "Generate default configuration files",
		RunE: func(cmd *cobra.Command, args []string) error {
			if outputDir == "" {
				outputDir = "."
			}

			// Write flyer.default.conf
			defaultPath := filepath.Join(outputDir, "flyer.default.conf")
			defaultContent := `# flyer.default.conf - Default configuration for flyer CLI

database {
    path /app/data/packages.db;
}

s3 {
    endpoint https://fly.storage.tigris.dev;
    bucket   fwhd-packages;
    region   auto;
    access_key env:AWS_ACCESS_KEY_ID;
    secret_key env:AWS_SECRET_ACCESS_KEY;
}

litestream {
    config_path    /app/litestream.yml;
    retention_days 7;
}

packages {
    dir         /app/packages;
    entry_point dist/index.js;
}

sync {
    component backend;
    timeout   60;
}
`
			if err := os.WriteFile(defaultPath, []byte(defaultContent), 0644); err != nil {
				return fmt.Errorf("write default config: %w", err)
			}
			fmt.Printf("Created: %s\n", defaultPath)

			// Write flyer.conf
			confPath := filepath.Join(outputDir, "flyer.conf")
			confContent := `# flyer.conf - Local configuration overrides
# Uncomment and modify values as needed

# database {
#     path /data/packages.db;
# }

# s3 {
#     bucket my-bucket;
# }
`
			if err := os.WriteFile(confPath, []byte(confContent), 0644); err != nil {
				return fmt.Errorf("write config: %w", err)
			}
			fmt.Printf("Created: %s\n", confPath)

			return nil
		},
	}
	initCmd.Flags().StringVarP(&outputDir, "output", "o", ".", "Output directory")

	cmd.AddCommand(showCmd, initCmd)
	return cmd
}

// =============================================================================
// ID COMMANDS
// =============================================================================

func idCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "id",
		Short: "Branded ID operations",
	}

	// id new <namespace>
	newCmd := &cobra.Command{
		Use:   "new <namespace>",
		Short: "Generate a new branded ID",
		Long:  "Generate a new branded ID. Valid namespaces: PKG, RLS, DPL, CMD",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			ns := branded.Namespace(args[0])
			if !branded.IsValidNamespace(ns) {
				return fmt.Errorf("invalid namespace: %s. Valid: PKG, RLS, DPL, CMD", args[0])
			}

			id := branded.NewID(ns)
			fmt.Println(id.Value)
			return nil
		},
	}

	// id parse <id>
	parseCmd := &cobra.Command{
		Use:   "parse <id>",
		Short: "Parse a branded ID",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			id, err := branded.Parse(args[0])
			if err != nil {
				return err
			}

			fmt.Printf("Value:     %s\n", id.Value)
			fmt.Printf("Namespace: %s\n", id.Namespace)
			fmt.Printf("Snowflake: %d\n", id.Snowflake)
			fmt.Printf("Timestamp: %s\n", id.Timestamp.Format("2006-01-02 15:04:05.000"))
			fmt.Printf("Worker:    %d\n", branded.ExtractWorkerID(id.Snowflake))
			fmt.Printf("Sequence:  %d\n", branded.ExtractSequence(id.Snowflake))
			return nil
		},
	}

	// id list
	listCmd := &cobra.Command{
		Use:   "list",
		Short: "List valid namespaces",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Valid namespaces:")
			for ns, desc := range branded.NamespaceDescriptions {
				fmt.Printf("  %s - %s\n", ns, desc)
			}
		},
	}

	cmd.AddCommand(newCmd, parseCmd, listCmd)
	return cmd
}

// =============================================================================
// DATABASE COMMANDS
// =============================================================================

func dbCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "db",
		Short: "Database operations",
	}

	// db init
	initCmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize database schema",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			if err := database.Init(); err != nil {
				return fmt.Errorf("init schema: %w", err)
			}

			fmt.Printf("Database initialized: %s\n", dbPath)
			return nil
		},
	}

	// db path
	pathCmd := &cobra.Command{
		Use:   "path",
		Short: "Show database path",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println(dbPath)
		},
	}

	cmd.AddCommand(initCmd, pathCmd)
	return cmd
}

// =============================================================================
// PACKAGE COMMANDS
// =============================================================================

func pkgCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "pkg",
		Aliases: []string{"package"},
		Short:   "Package operations",
	}

	// pkg create
	var name, ver, key, checksum string
	var size int64
	createCmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new package record",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			id := branded.NewID(branded.NS_PACKAGE)
			pkg := &db.Package{
				ID:        id.Value,
				Name:      name,
				Version:   ver,
				TigrisKey: key,
				SizeBytes: size,
				Checksum:  checksum,
				CreatedAt: id.Timestamp,
			}

			if err := database.InsertPackage(pkg); err != nil {
				return fmt.Errorf("create package: %w", err)
			}

			fmt.Printf("Created package: %s\n", id.Value)
			return nil
		},
	}
	createCmd.Flags().StringVar(&name, "name", "@fireheadz/codemoji-backend", "Package name")
	createCmd.Flags().StringVar(&ver, "version", "", "Package version (required)")
	createCmd.Flags().StringVar(&key, "key", "", "Tigris S3 key (required)")
	createCmd.Flags().StringVar(&checksum, "checksum", "", "SHA256 checksum (required)")
	createCmd.Flags().Int64Var(&size, "size", 0, "File size in bytes (required)")
	createCmd.MarkFlagRequired("version")
	createCmd.MarkFlagRequired("key")
	createCmd.MarkFlagRequired("checksum")
	createCmd.MarkFlagRequired("size")

	// pkg list
	var limit int
	listCmd := &cobra.Command{
		Use:   "list",
		Short: "List packages",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			packages, err := database.ListPackages(limit)
			if err != nil {
				return fmt.Errorf("list packages: %w", err)
			}

			if len(packages) == 0 {
				fmt.Println("No packages found")
				return nil
			}

			fmt.Printf("%-14s  %-30s  %-10s  %s\n", "ID", "NAME", "VERSION", "CREATED")
			for _, pkg := range packages {
				fmt.Printf("%-14s  %-30s  %-10s  %s\n",
					pkg.ID, pkg.Name, pkg.Version, pkg.CreatedAt.Format("2006-01-02 15:04"))
			}
			return nil
		},
	}
	listCmd.Flags().IntVar(&limit, "limit", 20, "Maximum number of packages to show")

	// pkg get
	getCmd := &cobra.Command{
		Use:   "get <id>",
		Short: "Get package details",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			pkg, err := database.GetPackage(args[0])
			if err != nil {
				return fmt.Errorf("get package: %w", err)
			}

			fmt.Printf("ID:        %s\n", pkg.ID)
			fmt.Printf("Name:      %s\n", pkg.Name)
			fmt.Printf("Version:   %s\n", pkg.Version)
			fmt.Printf("Key:       %s\n", pkg.TigrisKey)
			fmt.Printf("Size:      %d bytes\n", pkg.SizeBytes)
			fmt.Printf("Checksum:  %s\n", pkg.Checksum)
			fmt.Printf("Created:   %s\n", pkg.CreatedAt.Format("2006-01-02 15:04:05"))
			return nil
		},
	}

	cmd.AddCommand(createCmd, listCmd, getCmd)
	return cmd
}

// =============================================================================
// RELEASE COMMANDS
// =============================================================================

func releaseCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "release",
		Short: "Release operations",
	}

	// release create
	var packageID, tag, notes string
	createCmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new release",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			// Verify package exists
			if _, err := database.GetPackage(packageID); err != nil {
				return fmt.Errorf("package not found: %s", packageID)
			}

			id := branded.NewID(branded.NS_RELEASE)
			rel := &db.Release{
				ID:        id.Value,
				PackageID: packageID,
				Tag:       tag,
				Status:    "draft",
				Notes:     notes,
				CreatedAt: id.Timestamp,
			}

			if err := database.InsertRelease(rel); err != nil {
				return fmt.Errorf("create release: %w", err)
			}

			fmt.Printf("Created release: %s (tag: %s)\n", id.Value, tag)
			return nil
		},
	}
	createCmd.Flags().StringVar(&packageID, "package", "", "Package ID (required)")
	createCmd.Flags().StringVar(&tag, "tag", "", "Release tag e.g. v8.0.0 (required)")
	createCmd.Flags().StringVar(&notes, "notes", "", "Release notes (optional)")
	createCmd.MarkFlagRequired("package")
	createCmd.MarkFlagRequired("tag")

	// release stage
	stageCmd := &cobra.Command{
		Use:   "stage <id>",
		Short: "Stage a release for deployment",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			if err := database.StageRelease(args[0]); err != nil {
				return fmt.Errorf("stage release: %w", err)
			}

			fmt.Printf("Staged release: %s\n", args[0])
			return nil
		},
	}

	// release activate
	activateCmd := &cobra.Command{
		Use:   "activate <id>",
		Short: "Activate a release",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			if err := database.ActivateRelease(args[0]); err != nil {
				return fmt.Errorf("activate release: %w", err)
			}

			fmt.Printf("Activated release: %s\n", args[0])
			return nil
		},
	}

	// release pending
	pendingCmd := &cobra.Command{
		Use:   "pending",
		Short: "List staged releases pending deployment",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			releases, err := database.GetPendingReleases()
			if err != nil {
				return fmt.Errorf("get pending: %w", err)
			}

			if len(releases) == 0 {
				fmt.Println("No pending releases")
				return nil
			}

			fmt.Printf("%-14s  %-12s  %-14s  %s\n", "ID", "TAG", "PACKAGE", "STAGED")
			for _, rel := range releases {
				staged := ""
				if rel.StagedAt != nil {
					staged = rel.StagedAt.Format("2006-01-02 15:04")
				}
				fmt.Printf("%-14s  %-12s  %-14s  %s\n", rel.ID, rel.Tag, rel.PackageID, staged)
			}
			return nil
		},
	}

	cmd.AddCommand(createCmd, stageCmd, activateCmd, pendingCmd)
	return cmd
}

// =============================================================================
// DEPLOY COMMANDS
// =============================================================================

// =============================================================================
// LITESTREAM COMMANDS (SQLitestream integration)
// =============================================================================

func streamCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "stream",
		Short: "Litestream replication operations",
		Long:  "Commands for managing Litestream SQLite replication to Tigris S3.",
	}

	// stream restore - Restore SQLite from Tigris replica
	var configPath string
	var ifNotExists bool
	restoreCmd := &cobra.Command{
		Use:   "restore",
		Short: "Restore SQLite database from Tigris S3 replica",
		Long: `Restore the packages.db database from Litestream replica on Tigris S3.

This command should be run at startup before any other flyer operations.
If the database already exists and --if-not-exists is set, this is a no-op.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			// Apply config default
			if configPath == "" {
				configPath = cfg.Litestream.ConfigPath
			}
			// Check if database already exists
			if ifNotExists {
				if _, err := os.Stat(dbPath); err == nil {
					fmt.Printf("Database already exists: %s (skipping restore)\n", dbPath)
					return nil
				}
			}

			// Build litestream restore command
			litestreamArgs := []string{"restore"}
			if configPath != "" {
				litestreamArgs = append(litestreamArgs, "-config", configPath)
			}
			litestreamArgs = append(litestreamArgs, "-if-replica-exists", dbPath)

			fmt.Printf("Restoring database from Tigris replica...\n")
			fmt.Printf("  Database: %s\n", dbPath)
			fmt.Printf("  Config: %s\n", configPath)

			// Execute litestream restore
			execCmd := exec.Command("litestream", litestreamArgs...)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr

			if err := execCmd.Run(); err != nil {
				// Check if it's "no replica exists" error (not a failure)
				if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 1 {
					fmt.Println("No replica exists yet (fresh deployment)")
					return nil
				}
				return fmt.Errorf("litestream restore failed: %w", err)
			}

			fmt.Println("Database restored successfully")
			return nil
		},
	}
	restoreCmd.Flags().StringVar(&configPath, "config", "", "Path to litestream.yml config (default from flyer.conf)")
	restoreCmd.Flags().BoolVar(&ifNotExists, "if-not-exists", true, "Skip restore if database already exists")

	// stream status - Check Litestream replication status
	statusCmd := &cobra.Command{
		Use:   "status",
		Short: "Check Litestream replication status",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Apply config default
			if configPath == "" {
				configPath = cfg.Litestream.ConfigPath
			}

			// Check if database exists
			dbInfo, err := os.Stat(dbPath)
			if err != nil {
				fmt.Printf("Database: %s (NOT FOUND)\n", dbPath)
				return nil
			}

			fmt.Printf("Database: %s\n", dbPath)
			fmt.Printf("  Size: %d bytes\n", dbInfo.Size())
			fmt.Printf("  Modified: %s\n", dbInfo.ModTime().Format("2006-01-02 15:04:05"))

			// Check for WAL file (indicates active writes)
			walPath := dbPath + "-wal"
			if walInfo, err := os.Stat(walPath); err == nil {
				fmt.Printf("  WAL: %d bytes (active)\n", walInfo.Size())
			} else {
				fmt.Println("  WAL: none")
			}

			// Check for SHM file
			shmPath := dbPath + "-shm"
			if _, err := os.Stat(shmPath); err == nil {
				fmt.Println("  SHM: present")
			}

			// Run litestream generations to show replica info
			if configPath != "" {
				fmt.Println("\nLitestream Generations:")
				execCmd := exec.Command("litestream", "generations", "-config", configPath, dbPath)
				execCmd.Stdout = os.Stdout
				execCmd.Stderr = os.Stderr
				execCmd.Run() // Ignore errors, just informational
			}

			return nil
		},
	}
	statusCmd.Flags().StringVar(&configPath, "config", "", "Path to litestream.yml config (default from flyer.conf)")

	// stream replicate - Start Litestream replication (background)
	replicateCmd := &cobra.Command{
		Use:   "replicate",
		Short: "Start Litestream replication daemon",
		Long:  "Start Litestream in replication mode. This runs as a background daemon.",
		RunE: func(cmd *cobra.Command, args []string) error {
			// Apply config default
			if configPath == "" {
				configPath = cfg.Litestream.ConfigPath
			}

			litestreamArgs := []string{"replicate"}
			if configPath != "" {
				litestreamArgs = append(litestreamArgs, "-config", configPath)
			}

			fmt.Printf("Starting Litestream replication...\n")
			fmt.Printf("  Config: %s\n", configPath)
			fmt.Printf("  Database: %s\n", dbPath)

			execCmd := exec.Command("litestream", litestreamArgs...)
			execCmd.Stdout = os.Stdout
			execCmd.Stderr = os.Stderr

			// This blocks until litestream exits
			return execCmd.Run()
		},
	}
	replicateCmd.Flags().StringVar(&configPath, "config", "", "Path to litestream.yml config (default from flyer.conf)")

	cmd.AddCommand(restoreCmd, statusCmd, replicateCmd)
	return cmd
}

func deployCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "deploy",
		Short: "Deployment operations",
	}

	// deploy start
	var releaseID, machineID, trigger string
	startCmd := &cobra.Command{
		Use:   "start",
		Short: "Start a deployment",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			// Verify release exists
			if _, err := database.GetRelease(releaseID); err != nil {
				return fmt.Errorf("release not found: %s", releaseID)
			}

			id := branded.NewID(branded.NS_DEPLOYMENT)
			dep := &db.Deployment{
				ID:        id.Value,
				ReleaseID: releaseID,
				Status:    "pending",
				MachineID: machineID,
				Trigger:   trigger,
				StartedAt: id.Timestamp,
			}

			if err := database.InsertDeployment(dep); err != nil {
				return fmt.Errorf("start deployment: %w", err)
			}

			fmt.Printf("Started deployment: %s\n", id.Value)
			return nil
		},
	}
	startCmd.Flags().StringVar(&releaseID, "release", "", "Release ID (required)")
	startCmd.Flags().StringVar(&machineID, "machine", "", "Fly machine ID")
	startCmd.Flags().StringVar(&trigger, "trigger", "manual", "Trigger: manual|ci|watcher")
	startCmd.MarkFlagRequired("release")

	// deploy complete
	completeCmd := &cobra.Command{
		Use:   "complete <id>",
		Short: "Mark deployment as completed",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			if err := database.UpdateDeploymentStatus(args[0], "completed", ""); err != nil {
				return fmt.Errorf("complete deployment: %w", err)
			}

			fmt.Printf("Completed deployment: %s\n", args[0])
			return nil
		},
	}

	// deploy fail
	var errMsg string
	failCmd := &cobra.Command{
		Use:   "fail <id>",
		Short: "Mark deployment as failed",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			if err := database.UpdateDeploymentStatus(args[0], "failed", errMsg); err != nil {
				return fmt.Errorf("fail deployment: %w", err)
			}

			fmt.Printf("Failed deployment: %s\n", args[0])
			return nil
		},
	}
	failCmd.Flags().StringVar(&errMsg, "error", "", "Error message")

	// deploy active
	activeCmd := &cobra.Command{
		Use:   "active",
		Short: "Show active deployment",
		RunE: func(cmd *cobra.Command, args []string) error {
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			dep, err := database.GetActiveDeployment()
			if err != nil {
				fmt.Println("No active deployment")
				return nil
			}

			fmt.Printf("ID:        %s\n", dep.ID)
			fmt.Printf("Release:   %s\n", dep.ReleaseID)
			fmt.Printf("Status:    %s\n", dep.Status)
			fmt.Printf("Machine:   %s\n", dep.MachineID)
			fmt.Printf("Trigger:   %s\n", dep.Trigger)
			fmt.Printf("Started:   %s\n", dep.StartedAt.Format("2006-01-02 15:04:05"))
			return nil
		},
	}

	cmd.AddCommand(startCmd, completeCmd, failCmd, activeCmd)
	return cmd
}

// =============================================================================
// SYNC COMMANDS - Pre-download packages before Echo starts
// =============================================================================

func syncCmd() *cobra.Command {
	var packagesDir string
	var component string
	var timeout int

	cmd := &cobra.Command{
		Use:   "sync",
		Short: "Sync packages from Tigris S3 before Echo starts",
		PreRunE: func(cmd *cobra.Command, args []string) error {
			// NOTE: Use PreRunE (not PersistentPreRunE) to avoid overriding root
			// command's PersistentPreRunE which initializes cfg.
			// Apply config defaults if flags not set
			if packagesDir == "" {
				packagesDir = cfg.Packages.Dir
			}
			if component == "" {
				component = cfg.Sync.Component
			}
			if timeout == 0 {
				timeout = cfg.Sync.Timeout
			}
			return nil
		},
		Long: `Download and extract packages based on active_versions in packages.db.

This command should be run in start.sh BEFORE Echo starts:
  1. Reads packages.db to find active_version for component
  2. Downloads tarball from Tigris S3
  3. Extracts to packages/{tag}/
  4. Creates symlink: current → {tag}

This eliminates the need for DistrWatcher to download during runtime,
making health checks pass faster and enabling true blue-green deploys.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			startTime := time.Now()
			fmt.Println("==================================================")
			fmt.Println("FWHD v3: Sync Packages from Tigris")
			fmt.Println("==================================================")

			// Open database
			database, err := db.Open(dbPath)
			if err != nil {
				return fmt.Errorf("open database: %w", err)
			}
			defer database.Close()

			// Get active version for component
			fmt.Printf("Looking up active version for: %s\n", component)
			activeVer, err := database.GetActiveVersion(component)
			if err != nil {
				return fmt.Errorf("get active version: %w", err)
			}
			fmt.Printf("  Active release: %s\n", activeVer.ReleaseID)

			// Get release details
			release, err := database.GetRelease(activeVer.ReleaseID)
			if err != nil {
				return fmt.Errorf("get release: %w", err)
			}
			fmt.Printf("  Tag: %s\n", release.Tag)
			fmt.Printf("  Status: %s\n", release.Status)

			// Get package details
			pkg, err := database.GetPackage(release.PackageID)
			if err != nil {
				return fmt.Errorf("get package: %w", err)
			}
			fmt.Printf("  Package: %s@%s\n", pkg.Name, pkg.Version)
			fmt.Printf("  Tigris key: %s\n", pkg.TigrisKey)
			fmt.Printf("  Size: %d bytes\n", pkg.SizeBytes)

			// Create packages directory
			if err := os.MkdirAll(packagesDir, 0755); err != nil {
				return fmt.Errorf("create packages dir: %w", err)
			}

			// Check if already synced (version directory exists with valid content)
			versionDir := filepath.Join(packagesDir, release.Tag)
			entryPoint := filepath.Join(versionDir, "dist", "index.js")
			if _, err := os.Stat(entryPoint); err == nil {
				fmt.Printf("✓ Already synced: %s\n", versionDir)
				// Just ensure symlink is correct
				if err := updateSymlink(packagesDir, release.Tag); err != nil {
					return fmt.Errorf("update symlink: %w", err)
				}
				fmt.Printf("✓ Symlink updated: current → %s\n", release.Tag)
				fmt.Printf("Sync completed in %v\n", time.Since(startTime))
				return nil
			}

			// Create S3 client
			s3Client, err := s3.NewClient()
			if err != nil {
				return fmt.Errorf("create S3 client: %w", err)
			}
			fmt.Printf("  S3 bucket: %s\n", s3Client.Bucket())

			// Download tarball to temp file
			ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeout)*time.Second)
			defer cancel()

			tmpFile := filepath.Join(os.TempDir(), fmt.Sprintf("flyer-sync-%s.tar.gz", release.Tag))
			fmt.Printf("Downloading to: %s\n", tmpFile)

			downloaded, err := s3Client.Download(ctx, pkg.TigrisKey, tmpFile)
			if err != nil {
				return fmt.Errorf("download from S3: %w", err)
			}
			fmt.Printf("✓ Downloaded: %d bytes\n", downloaded)
			defer os.Remove(tmpFile) // Clean up temp file

			// Extract tarball
			fmt.Printf("Extracting to: %s\n", versionDir)
			if err := extractTarGz(tmpFile, versionDir); err != nil {
				return fmt.Errorf("extract tarball: %w", err)
			}
			fmt.Println("✓ Extracted successfully")

			// Create/update symlink
			if err := updateSymlink(packagesDir, release.Tag); err != nil {
				return fmt.Errorf("update symlink: %w", err)
			}
			fmt.Printf("✓ Symlink: current → %s\n", release.Tag)

			// Verify entry point exists
			if _, err := os.Stat(entryPoint); err != nil {
				return fmt.Errorf("entry point not found: %s", entryPoint)
			}
			fmt.Printf("✓ Entry point verified: %s\n", entryPoint)

			fmt.Println("==================================================")
			fmt.Printf("Sync completed in %v\n", time.Since(startTime))
			fmt.Println("==================================================")

			return nil
		},
	}

	cmd.Flags().StringVar(&packagesDir, "packages", "", "Directory to sync packages to (default from config)")
	cmd.Flags().StringVar(&component, "component", "", "Component to sync (default from config)")
	cmd.Flags().IntVar(&timeout, "timeout", 0, "Download timeout in seconds (default from config)")

	return cmd
}

// extractTarGz extracts a .tar.gz file to the destination directory
func extractTarGz(src, dest string) error {
	// Open the tarball
	file, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("open tarball: %w", err)
	}
	defer file.Close()

	// Create gzip reader
	gzReader, err := gzip.NewReader(file)
	if err != nil {
		return fmt.Errorf("create gzip reader: %w", err)
	}
	defer gzReader.Close()

	// Create tar reader
	tarReader := tar.NewReader(gzReader)

	// Create destination directory
	if err := os.MkdirAll(dest, 0755); err != nil {
		return fmt.Errorf("create dest dir: %w", err)
	}

	// Extract files
	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("read tar header: %w", err)
		}

		// Calculate target path
		target := filepath.Join(dest, header.Name)

		// Ensure target is within dest (security check)
		if !filepath.HasPrefix(target, filepath.Clean(dest)+string(os.PathSeparator)) {
			return fmt.Errorf("invalid path in tarball: %s", header.Name)
		}

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, os.FileMode(header.Mode)); err != nil {
				return fmt.Errorf("create directory: %w", err)
			}
		case tar.TypeReg:
			// Create parent directory
			if err := os.MkdirAll(filepath.Dir(target), 0755); err != nil {
				return fmt.Errorf("create parent dir: %w", err)
			}

			// Create file
			outFile, err := os.OpenFile(target, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.FileMode(header.Mode))
			if err != nil {
				return fmt.Errorf("create file: %w", err)
			}

			// Copy content
			if _, err := io.Copy(outFile, tarReader); err != nil {
				outFile.Close()
				return fmt.Errorf("copy content: %w", err)
			}
			outFile.Close()
		case tar.TypeSymlink:
			// Create symlink
			if err := os.Symlink(header.Linkname, target); err != nil {
				return fmt.Errorf("create symlink: %w", err)
			}
		}
	}

	return nil
}

// updateSymlink creates or updates the "current" symlink
func updateSymlink(packagesDir, tag string) error {
	linkPath := filepath.Join(packagesDir, "current")
	targetPath := tag // Relative path

	// Remove existing symlink if present
	if _, err := os.Lstat(linkPath); err == nil {
		if err := os.Remove(linkPath); err != nil {
			return fmt.Errorf("remove old symlink: %w", err)
		}
	}

	// Create new symlink
	if err := os.Symlink(targetPath, linkPath); err != nil {
		return fmt.Errorf("create symlink: %w", err)
	}

	return nil
}
