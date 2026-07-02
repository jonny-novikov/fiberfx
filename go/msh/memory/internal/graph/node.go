package graph

type NodeType string

const (
	NodeFeedback  NodeType = "feedback"
	NodeProject   NodeType = "project"
	NodeReference NodeType = "reference"
	NodeLaw       NodeType = "law"
	NodeSession   NodeType = "session_pause"
	NodeIndex     NodeType = "index"
	NodeUnknown   NodeType = "unknown"
)

type Status string

const (
	StatusActive     Status = "active"
	StatusSuperseded Status = "superseded"
)

type Node struct {
	Path             string   `json:"path"`
	AbsPath          string   `json:"-"`
	Type             NodeType `json:"type"`
	Name             string   `json:"name,omitempty"`
	Description      string   `json:"description,omitempty"`
	OriginSessionID  string   `json:"originSessionId,omitempty"`
	Status           Status   `json:"status"`
	Project          string   `json:"project,omitempty"`
	ReviewAfter      string   `json:"review_after,omitempty"`
	SizeBytes        int64    `json:"size_bytes"`
	HasFrontmatter   bool     `json:"has_frontmatter"`
	FrontmatterError string   `json:"frontmatter_error,omitempty"`
	SHA256           string   `json:"sha256,omitempty"`
}
