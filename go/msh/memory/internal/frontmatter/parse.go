package frontmatter

import (
	"bytes"
	"fmt"

	"gopkg.in/yaml.v3"
)

type Frontmatter struct {
	Name            string `yaml:"name"`
	Description     string `yaml:"description"`
	Type            string `yaml:"type"`
	OriginSessionID string `yaml:"originSessionId"`
}

// metaBlock is the nested `metadata:` block the memory corpus uses. The corpus
// convention nests type/node_type/originSessionId under `metadata:`, while the
// older form (and the test fixtures) carry them at the top level. Parse reads
// both; the top-level value wins when present, otherwise the nested one is used.
type metaBlock struct {
	NodeType        string `yaml:"node_type"`
	Type            string `yaml:"type"`
	OriginSessionID string `yaml:"originSessionId"`
}

// rawFrontmatter captures the top-level fields and the nested metadata block in a
// single unmarshal, so a note that nests `metadata.type` is classified rather than
// dropped to `unknown` (its type was invisible while Parse read only top-level).
type rawFrontmatter struct {
	Name            string    `yaml:"name"`
	Description     string    `yaml:"description"`
	Type            string    `yaml:"type"`
	OriginSessionID string    `yaml:"originSessionId"`
	Metadata        metaBlock `yaml:"metadata"`
}

type Result struct {
	Has         bool
	Frontmatter Frontmatter
	BodyOffset  int
	ParseError  string
}

var delim = []byte("---\n")

func Parse(content []byte) Result {
	if !bytes.HasPrefix(content, delim) {
		return Result{Has: false, BodyOffset: 0}
	}
	rest := content[len(delim):]
	end := bytes.Index(rest, []byte("\n---\n"))
	if end < 0 {
		altEnd := bytes.Index(rest, []byte("\n---"))
		if altEnd < 0 {
			return Result{Has: false, BodyOffset: 0}
		}
		end = altEnd
	}
	yamlBody := rest[:end]
	bodyStart := len(delim) + end + len("\n---\n")
	if bodyStart > len(content) {
		bodyStart = len(content)
	}

	var raw rawFrontmatter
	if err := yaml.Unmarshal(yamlBody, &raw); err != nil {
		return Result{
			Has:        true,
			BodyOffset: bodyStart,
			ParseError: fmt.Sprintf("yaml unmarshal: %v", err),
		}
	}
	fm := Frontmatter{
		Name:            raw.Name,
		Description:     raw.Description,
		Type:            coalesce(raw.Type, raw.Metadata.Type),
		OriginSessionID: coalesce(raw.OriginSessionID, raw.Metadata.OriginSessionID),
	}
	return Result{
		Has:         true,
		Frontmatter: fm,
		BodyOffset:  bodyStart,
	}
}

// coalesce returns top if non-empty, else fallback. A top-level field therefore
// wins over the nested metadata block when both are present, and the nested value
// is used otherwise (the corpus convention).
func coalesce(top, fallback string) string {
	if top != "" {
		return top
	}
	return fallback
}
