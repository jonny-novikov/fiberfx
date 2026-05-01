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

type Result struct {
	Has        bool
	Frontmatter Frontmatter
	BodyOffset int
	ParseError string
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

	var fm Frontmatter
	if err := yaml.Unmarshal(yamlBody, &fm); err != nil {
		return Result{
			Has:        true,
			BodyOffset: bodyStart,
			ParseError: fmt.Sprintf("yaml unmarshal: %v", err),
		}
	}
	return Result{
		Has:         true,
		Frontmatter: fm,
		BodyOffset:  bodyStart,
	}
}
