// db/db.go
// =============================================================================
// DATABASE OPERATIONS - SQLite operations for FWHD
// =============================================================================

package db

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

// DB wraps the SQLite database connection
type DB struct {
	conn *sql.DB
	path string
}

// Open opens or creates the database at the given path
func Open(path string) (*DB, error) {
	// Ensure directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("create directory: %w", err)
	}

	// Open with WAL mode for Litestream compatibility
	dsn := fmt.Sprintf("file:%s?_journal_mode=WAL&_busy_timeout=5000&_synchronous=NORMAL", path)
	conn, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}

	// Set pragmas for performance
	pragmas := []string{
		"PRAGMA foreign_keys = ON",
		"PRAGMA cache_size = -10000", // 10MB cache
	}
	for _, pragma := range pragmas {
		if _, err := conn.Exec(pragma); err != nil {
			conn.Close()
			return nil, fmt.Errorf("set pragma: %w", err)
		}
	}

	return &DB{conn: conn, path: path}, nil
}

// Close closes the database connection
func (db *DB) Close() error {
	return db.conn.Close()
}

// Init initializes the database schema
func (db *DB) Init() error {
	_, err := db.conn.Exec(Schema)
	if err != nil {
		return fmt.Errorf("init schema: %w", err)
	}
	return nil
}

// Path returns the database file path
func (db *DB) Path() string {
	return db.path
}

// Conn returns the underlying sql.DB connection
func (db *DB) Conn() *sql.DB {
	return db.conn
}

// =============================================================================
// PACKAGE OPERATIONS
// =============================================================================

// Package represents a built artifact
type Package struct {
	ID        string
	Name      string
	Version   string
	TigrisKey string
	SizeBytes int64
	Checksum  string
	Metadata  string
	CreatedAt time.Time
}

// InsertPackage creates a new package record
func (db *DB) InsertPackage(pkg *Package) error {
	_, err := db.conn.Exec(`
		INSERT INTO packages (id, name, version, tigris_key, size_bytes, checksum, metadata, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, pkg.ID, pkg.Name, pkg.Version, pkg.TigrisKey, pkg.SizeBytes, pkg.Checksum, pkg.Metadata, pkg.CreatedAt.Format(time.RFC3339))
	return err
}

// GetPackage retrieves a package by ID
func (db *DB) GetPackage(id string) (*Package, error) {
	pkg := &Package{}
	var createdAt string
	err := db.conn.QueryRow(`
		SELECT id, name, version, tigris_key, size_bytes, checksum, COALESCE(metadata, ''), created_at
		FROM packages WHERE id = ?
	`, id).Scan(&pkg.ID, &pkg.Name, &pkg.Version, &pkg.TigrisKey, &pkg.SizeBytes, &pkg.Checksum, &pkg.Metadata, &createdAt)
	if err != nil {
		return nil, err
	}
	pkg.CreatedAt, _ = time.Parse(time.RFC3339, createdAt)
	return pkg, nil
}

// ListPackages returns all packages
func (db *DB) ListPackages(limit int) ([]*Package, error) {
	if limit <= 0 {
		limit = 50
	}
	rows, err := db.conn.Query(`
		SELECT id, name, version, tigris_key, size_bytes, checksum, COALESCE(metadata, ''), created_at
		FROM packages ORDER BY created_at DESC LIMIT ?
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var packages []*Package
	for rows.Next() {
		pkg := &Package{}
		var createdAt string
		if err := rows.Scan(&pkg.ID, &pkg.Name, &pkg.Version, &pkg.TigrisKey, &pkg.SizeBytes, &pkg.Checksum, &pkg.Metadata, &createdAt); err != nil {
			return nil, err
		}
		pkg.CreatedAt, _ = time.Parse(time.RFC3339, createdAt)
		packages = append(packages, pkg)
	}
	return packages, nil
}

// =============================================================================
// RELEASE OPERATIONS
// =============================================================================

// Release represents a deployable version
type Release struct {
	ID          string
	PackageID   string
	Tag         string
	Status      string
	Notes       string
	CreatedAt   time.Time
	StagedAt    *time.Time
	ActivatedAt *time.Time
}

// InsertRelease creates a new release record
func (db *DB) InsertRelease(rel *Release) error {
	_, err := db.conn.Exec(`
		INSERT INTO releases (id, package_id, tag, status, notes, created_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, rel.ID, rel.PackageID, rel.Tag, rel.Status, rel.Notes, rel.CreatedAt.Format(time.RFC3339))
	return err
}

// GetRelease retrieves a release by ID
func (db *DB) GetRelease(id string) (*Release, error) {
	rel := &Release{}
	var createdAt, stagedAt, activatedAt sql.NullString
	err := db.conn.QueryRow(`
		SELECT id, package_id, tag, status, COALESCE(notes, ''), created_at, staged_at, activated_at
		FROM releases WHERE id = ?
	`, id).Scan(&rel.ID, &rel.PackageID, &rel.Tag, &rel.Status, &rel.Notes, &createdAt, &stagedAt, &activatedAt)
	if err != nil {
		return nil, err
	}
	rel.CreatedAt, _ = time.Parse(time.RFC3339, createdAt.String)
	if stagedAt.Valid {
		t, _ := time.Parse(time.RFC3339, stagedAt.String)
		rel.StagedAt = &t
	}
	if activatedAt.Valid {
		t, _ := time.Parse(time.RFC3339, activatedAt.String)
		rel.ActivatedAt = &t
	}
	return rel, nil
}

// GetReleaseByTag retrieves a release by tag
func (db *DB) GetReleaseByTag(tag string) (*Release, error) {
	rel := &Release{}
	var createdAt, stagedAt, activatedAt sql.NullString
	err := db.conn.QueryRow(`
		SELECT id, package_id, tag, status, COALESCE(notes, ''), created_at, staged_at, activated_at
		FROM releases WHERE tag = ?
	`, tag).Scan(&rel.ID, &rel.PackageID, &rel.Tag, &rel.Status, &rel.Notes, &createdAt, &stagedAt, &activatedAt)
	if err != nil {
		return nil, err
	}
	rel.CreatedAt, _ = time.Parse(time.RFC3339, createdAt.String)
	if stagedAt.Valid {
		t, _ := time.Parse(time.RFC3339, stagedAt.String)
		rel.StagedAt = &t
	}
	if activatedAt.Valid {
		t, _ := time.Parse(time.RFC3339, activatedAt.String)
		rel.ActivatedAt = &t
	}
	return rel, nil
}

// StageRelease marks a release as staged
func (db *DB) StageRelease(id string) error {
	_, err := db.conn.Exec(`
		UPDATE releases SET status = 'staged', staged_at = datetime('now') WHERE id = ?
	`, id)
	return err
}

// ActivateRelease marks a release as active
func (db *DB) ActivateRelease(id string) error {
	_, err := db.conn.Exec(`
		UPDATE releases SET status = 'active', activated_at = datetime('now') WHERE id = ?
	`, id)
	return err
}

// GetPendingReleases returns releases ready for deployment
func (db *DB) GetPendingReleases() ([]*Release, error) {
	rows, err := db.conn.Query(`
		SELECT id, package_id, tag, status, COALESCE(notes, ''), created_at, staged_at, activated_at
		FROM releases WHERE status = 'staged' ORDER BY staged_at DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var releases []*Release
	for rows.Next() {
		rel := &Release{}
		var createdAt, stagedAt, activatedAt sql.NullString
		if err := rows.Scan(&rel.ID, &rel.PackageID, &rel.Tag, &rel.Status, &rel.Notes, &createdAt, &stagedAt, &activatedAt); err != nil {
			return nil, err
		}
		rel.CreatedAt, _ = time.Parse(time.RFC3339, createdAt.String)
		if stagedAt.Valid {
			t, _ := time.Parse(time.RFC3339, stagedAt.String)
			rel.StagedAt = &t
		}
		releases = append(releases, rel)
	}
	return releases, nil
}

// =============================================================================
// DEPLOYMENT OPERATIONS
// =============================================================================

// Deployment represents an audit record of deployment action
type Deployment struct {
	ID         string
	ReleaseID  string
	Status     string
	MachineID  string
	Trigger    string
	StartedAt  time.Time
	EndedAt    *time.Time
	Error      string
	RollbackTo string
	Metadata   string
}

// InsertDeployment creates a new deployment record
func (db *DB) InsertDeployment(dep *Deployment) error {
	_, err := db.conn.Exec(`
		INSERT INTO deployments (id, release_id, status, machine_id, trigger, started_at, metadata)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, dep.ID, dep.ReleaseID, dep.Status, dep.MachineID, dep.Trigger, dep.StartedAt.Format(time.RFC3339), dep.Metadata)
	return err
}

// UpdateDeploymentStatus updates deployment status
func (db *DB) UpdateDeploymentStatus(id, status string, errMsg string) error {
	if status == "completed" || status == "failed" || status == "cancelled" || status == "rolled_back" {
		_, err := db.conn.Exec(`
			UPDATE deployments SET status = ?, error = ?, ended_at = datetime('now') WHERE id = ?
		`, status, errMsg, id)
		return err
	}
	_, err := db.conn.Exec(`
		UPDATE deployments SET status = ?, error = ? WHERE id = ?
	`, status, errMsg, id)
	return err
}

// GetActiveDeployment returns the currently active deployment
func (db *DB) GetActiveDeployment() (*Deployment, error) {
	dep := &Deployment{}
	var startedAt, endedAt sql.NullString
	err := db.conn.QueryRow(`
		SELECT id, release_id, status, machine_id, trigger, started_at, ended_at, COALESCE(error, ''), COALESCE(rollback_to, ''), COALESCE(metadata, '')
		FROM deployments WHERE status IN ('pending', 'downloading', 'running')
		ORDER BY started_at DESC LIMIT 1
	`).Scan(&dep.ID, &dep.ReleaseID, &dep.Status, &dep.MachineID, &dep.Trigger, &startedAt, &endedAt, &dep.Error, &dep.RollbackTo, &dep.Metadata)
	if err != nil {
		return nil, err
	}
	dep.StartedAt, _ = time.Parse(time.RFC3339, startedAt.String)
	if endedAt.Valid {
		t, _ := time.Parse(time.RFC3339, endedAt.String)
		dep.EndedAt = &t
	}
	return dep, nil
}

// =============================================================================
// ACTIVE VERSION OPERATIONS
// =============================================================================

// ActiveVersion represents current active release per component
type ActiveVersion struct {
	Component   string
	ReleaseID   string
	ActivatedAt time.Time
	ActivatedBy string
}

// SetActiveVersion updates the active version for a component
func (db *DB) SetActiveVersion(component, releaseID, activatedBy string) error {
	_, err := db.conn.Exec(`
		INSERT INTO active_versions (component, release_id, activated_at, activated_by)
		VALUES (?, ?, datetime('now'), ?)
		ON CONFLICT(component) DO UPDATE SET
			release_id = excluded.release_id,
			activated_at = excluded.activated_at,
			activated_by = excluded.activated_by
	`, component, releaseID, activatedBy)
	return err
}

// GetActiveVersion returns the current active version for a component
func (db *DB) GetActiveVersion(component string) (*ActiveVersion, error) {
	av := &ActiveVersion{}
	var activatedAt string
	err := db.conn.QueryRow(`
		SELECT component, release_id, activated_at, COALESCE(activated_by, '')
		FROM active_versions WHERE component = ?
	`, component).Scan(&av.Component, &av.ReleaseID, &activatedAt, &av.ActivatedBy)
	if err != nil {
		return nil, err
	}
	av.ActivatedAt, _ = time.Parse(time.RFC3339, activatedAt)
	return av, nil
}
