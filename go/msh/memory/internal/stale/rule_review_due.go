package stale

import (
	"fmt"
	"strings"
	"time"

	"github.com/jonny-novikov/msh/memory/internal/config"
	"github.com/jonny-novikov/msh/memory/internal/graph"
)

// reviewDateLayout is the review_after contract format (msh2.2 §3.5).
const reviewDateLayout = "2006-01-02"

// ruleReviewDue flags notes whose review_after date has arrived. Due fires ON
// the named day (!ref.Before(date)) as one warn finding per note; an
// unparseable date is one error finding, so the audit gate catches a bad date;
// superseded notes are skipped (a dead note carries no review obligation);
// keyless notes yield nothing. ref is the injected reference date — this rule
// NEVER reads the wall clock (design §4.3): same corpus + same ref means
// byte-identical findings.
func ruleReviewDue(g *graph.Graph, cfg *config.Config, src Source, ref time.Time) Findings {
	_ = cfg
	_ = src
	var out Findings
	for _, n := range g.Nodes() {
		if n.Status == graph.StatusSuperseded {
			continue
		}
		raw := strings.TrimSpace(n.ReviewAfter)
		if raw == "" {
			continue
		}
		date, err := time.Parse(reviewDateLayout, raw)
		if err != nil {
			out = append(out, Finding{
				Rule:     RuleReviewDue,
				Severity: SeverityError,
				File:     n.Path,
				Line:     1,
				Target:   raw,
				Message:  fmt.Sprintf("invalid review_after %q: want YYYY-MM-DD", raw),
			})
			continue
		}
		if !ref.Before(date) {
			out = append(out, Finding{
				Rule:     RuleReviewDue,
				Severity: SeverityWarn,
				File:     n.Path,
				Line:     1,
				Target:   raw,
				Message:  fmt.Sprintf("review_after %s is due (reference date %s)", raw, ref.Format(reviewDateLayout)),
			})
		}
	}
	return out
}
