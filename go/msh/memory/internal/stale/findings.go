package stale

const (
	SeverityError = "error"
	SeverityWarn  = "warn"
	SeverityInfo  = "info"
)

type Finding struct {
	Rule     string `json:"rule"`
	Severity string `json:"severity"`
	File     string `json:"file"`
	Line     int    `json:"line"`
	Snippet  string `json:"snippet"`
	Target   string `json:"target,omitempty"`
	Message  string `json:"message"`
	EdgeKind string `json:"edge_kind,omitempty"`
}

type Findings []Finding

func (f Findings) Counts() map[string]int {
	out := map[string]int{
		SeverityError: 0,
		SeverityWarn:  0,
		SeverityInfo:  0,
	}
	for _, x := range f {
		out[x.Severity]++
	}
	return out
}

func (f Findings) FilterBySeverity(min string) Findings {
	threshold := severityRank(min)
	out := make(Findings, 0, len(f))
	for _, x := range f {
		if severityRank(x.Severity) >= threshold {
			out = append(out, x)
		}
	}
	return out
}

func severityRank(s string) int {
	switch s {
	case SeverityError:
		return 3
	case SeverityWarn:
		return 2
	case SeverityInfo:
		return 1
	default:
		return 0
	}
}
