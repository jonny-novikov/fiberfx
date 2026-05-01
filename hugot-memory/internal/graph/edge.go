package graph

type EdgeKind string

const (
	EdgeMDLink       EdgeKind = "md_link"
	EdgeMDLinkAnchor EdgeKind = "md_link_anchor"
	EdgeExternalRel  EdgeKind = "external_rel"
	EdgeCodePath     EdgeKind = "code_path"
	EdgeBareMention  EdgeKind = "bare_mention"
	EdgeAnchorOnly   EdgeKind = "anchor_only"
	EdgeCrossSubdir  EdgeKind = "cross_subdir"
)

type Edge struct {
	From          string   `json:"from"`
	To            string   `json:"to"`
	ToResolved    string   `json:"to_resolved,omitempty"`
	Kind          EdgeKind `json:"kind"`
	SourceLine    int      `json:"source_line"`
	SourceCol     int      `json:"source_col"`
	Snippet       string   `json:"snippet"`
	Resolved      bool     `json:"resolved"`
	InCodeBlock   bool     `json:"in_code_block"`
	InDeletionCtx bool     `json:"in_deletion_ctx"`
	Anchor        string   `json:"anchor,omitempty"`
}
