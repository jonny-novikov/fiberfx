// Package store is the SQLite content store for the published /elixir course:
// a filesystem-mirrored store that decomposes each published HTML page into
// normalized templates plus per-page data, so the assembler (internal/builder)
// can recompose byte-identical output. It supersedes spec 05's shared-head model
// (a single _head.html no longer reproduces the published heads — per-page accent
// and recent drift diverge them) by storing each page's own head template, and
// extends spec 90 (which scoped SQLite to a deferred progress store) to also hold
// content. See docs/specs/07-content-store.md.
//
// The store uses the pure-Go modernc.org/sqlite driver (registered as "sqlite"),
// so the module stays CGO-free.
package store

import (
	"database/sql"
	"fmt"

	_ "modernc.org/sqlite" // registers the pure-Go "sqlite" database/sql driver
)

// Page is one decomposed published page: its route, its on-disk output path, the
// unescaped title and description, the head template it shares with like pages,
// the body-fragment template with the build stamp re-placeholded, and the stamp
// values themselves. byteLen is the published file length, kept for a sanity
// check.
type Page struct {
	Route      string
	OutputPath string
	Title      string // unescaped
	Descr      string // unescaped
	HeadID     int64
	Fragment   []byte // body fragment template, stamp re-placeholded
	BuildID    string // the page's pinned stamp (may be "")
	BuildTS    string // "YYYY-MM-DD HH:MM:SS UTC" (may be "")
	ByteLen    int64
}

// Store wraps the SQLite database holding the decomposed pages.
type Store struct {
	db *sql.DB
}

const schema = `
CREATE TABLE IF NOT EXISTS head (
  id     INTEGER PRIMARY KEY,
  sha256 TEXT NOT NULL UNIQUE,
  bytes  BLOB NOT NULL
);
CREATE TABLE IF NOT EXISTS page (
  route       TEXT PRIMARY KEY,
  output_path TEXT NOT NULL,
  title       TEXT NOT NULL,
  descr       TEXT NOT NULL,
  head_id     INTEGER NOT NULL REFERENCES head(id),
  fragment    BLOB NOT NULL,
  build_id    TEXT NOT NULL,
  build_ts    TEXT NOT NULL,
  byte_len    INTEGER NOT NULL
);
`

// Open opens (or creates) the SQLite content store at path. The path may be
// ":memory:" for an ephemeral store or a filesystem path for a persistent one.
// The schema is created if absent.
func Open(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec(schema); err != nil {
		db.Close()
		return nil, fmt.Errorf("create schema: %w", err)
	}
	return &Store{db: db}, nil
}

// Close releases the underlying database handle.
func (s *Store) Close() error { return s.db.Close() }

// Get returns the decomposed page for a clean route together with the bytes of
// its head template.
func (s *Store) Get(route string) (Page, []byte, error) {
	var p Page
	row := s.db.QueryRow(
		`SELECT route, output_path, title, descr, head_id, fragment, build_id, build_ts, byte_len
		   FROM page WHERE route = ?`, route)
	if err := row.Scan(&p.Route, &p.OutputPath, &p.Title, &p.Descr, &p.HeadID,
		&p.Fragment, &p.BuildID, &p.BuildTS, &p.ByteLen); err != nil {
		if err == sql.ErrNoRows {
			return Page{}, nil, fmt.Errorf("no page for route %q", route)
		}
		return Page{}, nil, err
	}
	var head []byte
	if err := s.db.QueryRow(`SELECT bytes FROM head WHERE id = ?`, p.HeadID).Scan(&head); err != nil {
		return Page{}, nil, fmt.Errorf("head %d for route %q: %w", p.HeadID, route, err)
	}
	return p, head, nil
}

// Routes returns every stored route in ascending order.
func (s *Store) Routes() ([]string, error) {
	rows, err := s.db.Query(`SELECT route FROM page ORDER BY route`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var r string
		if err := rows.Scan(&r); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}
