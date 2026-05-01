package render

import (
	"fmt"
	"io"
	"strings"
	"text/tabwriter"

	"github.com/fiberfx/hugot-memory/internal/graph"
	"github.com/fiberfx/hugot-memory/internal/stale"
)

func PrettyScan(w io.Writer, nodes []*graph.Node) error {
	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	if _, err := fmt.Fprintln(tw, "PATH\tTYPE\tSTATUS\tSIZE\tNAME"); err != nil {
		return err
	}
	for _, n := range nodes {
		name := n.Name
		if len(name) > 60 {
			name = name[:57] + "..."
		}
		if _, err := fmt.Fprintf(tw, "%s\t%s\t%s\t%d\t%s\n", n.Path, n.Type, n.Status, n.SizeBytes, name); err != nil {
			return err
		}
	}
	return tw.Flush()
}

func PrettyFindings(w io.Writer, findings stale.Findings) error {
	if len(findings) == 0 {
		_, err := fmt.Fprintln(w, "no findings")
		return err
	}
	tw := tabwriter.NewWriter(w, 0, 0, 2, ' ', 0)
	if _, err := fmt.Fprintln(tw, "SEVERITY\tRULE\tFILE\tLINE\tTARGET\tMESSAGE"); err != nil {
		return err
	}
	for _, f := range findings {
		message := f.Message
		if len(message) > 80 {
			message = message[:77] + "..."
		}
		message = strings.ReplaceAll(message, "\n", " ")
		if _, err := fmt.Fprintf(tw, "%s\t%s\t%s\t%d\t%s\t%s\n", f.Severity, f.Rule, f.File, f.Line, f.Target, message); err != nil {
			return err
		}
	}
	return tw.Flush()
}

func PrettyAuditSummary(w io.Writer, counts map[string]int, fileCount int) error {
	_, err := fmt.Fprintf(w,
		"audit summary: %d files | error=%d warn=%d info=%d\n",
		fileCount,
		counts[stale.SeverityError],
		counts[stale.SeverityWarn],
		counts[stale.SeverityInfo],
	)
	return err
}
