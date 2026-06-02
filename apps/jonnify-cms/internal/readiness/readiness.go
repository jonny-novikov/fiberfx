// Package readiness reconciles the three sources of truth for every module: the
// manifest's declared status, whether the page exists on disk, and whether it
// passes the nine Apollo gates. The classification it produces is the tool's
// headline answer to "is this page ready, and does the manifest agree?".
package readiness

import (
	"os"

	"github.com/jonny-novikov/jonnify-cms/internal/apollo"
	"github.com/jonny-novikov/jonnify-cms/internal/manifest"
	"github.com/jonny-novikov/jonnify-cms/internal/site"
)

// Class is the reconciled verdict for a module.
type Class string

const (
	Ready        Class = "READY"         // declared linkable, exists, passes
	DriftPromote Class = "DRIFT-PROMOTE" // declared planned/soon, but exists and passes -> promote
	InProgress   Class = "IN-PROGRESS"   // declared planned, exists, not yet passing
	Regression   Class = "REGRESSION"    // declared linkable, exists, but a gate fails
	Broken       Class = "BROKEN"        // declared linkable, but no file resolves
	Planned      Class = "PLANNED"       // declared planned, no file (expected)
)

// Row is one module's reconciliation.
type Row struct {
	N          string   `json:"n"`
	Title      string   `json:"title"`
	Route      string   `json:"route"`
	Declared   string   `json:"declared"`
	FileExists bool     `json:"file_exists"`
	GatesPass  bool     `json:"gates_pass"`
	GateFails  []string `json:"gate_fails,omitempty"`
	Class      Class    `json:"class"`
	Note       string   `json:"note,omitempty"`
}

// Assess reconciles every spine and prologue module under root.
func Assess(root string) ([]Row, error) {
	var rows []Row
	for _, c := range manifest.Chapters {
		for _, m := range manifest.Modules[c.ID] {
			route := c.Route + "/" + m.Slug
			file, ok, note := site.Resolve(root, route)
			row := Row{N: m.N, Title: m.Title, Route: route, Declared: m.Status, FileExists: ok, Note: note}
			if ok {
				doc, err := os.ReadFile(file)
				if err != nil {
					return nil, err
				}
				res, all := apollo.Run(string(doc))
				row.GatesPass = all
				for _, r := range res {
					if !r.OK {
						row.GateFails = append(row.GateFails, r.Name)
					}
				}
			}
			row.Class = classify(m.Status, ok, row.GatesPass)
			rows = append(rows, row)
		}
	}
	return rows, nil
}

func classify(declared string, exists, pass bool) Class {
	linkable := manifest.Linkable(declared)
	switch {
	case exists && pass && linkable:
		return Ready
	case exists && pass && !linkable:
		return DriftPromote
	case exists && !pass && linkable:
		return Regression
	case exists && !pass && !linkable:
		return InProgress
	case !exists && linkable:
		return Broken
	default:
		return Planned
	}
}
