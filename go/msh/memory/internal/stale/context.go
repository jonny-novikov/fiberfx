package stale

import (
	"strings"
)

type DeletionContext struct {
	body     []byte
	keywords []string
}

func NewDeletionContext(body []byte, keywords []string) *DeletionContext {
	low := make([]string, len(keywords))
	for i, k := range keywords {
		low[i] = strings.ToLower(k)
	}
	return &DeletionContext{body: body, keywords: low}
}

func (d *DeletionContext) MatchesAt(offset int) bool {
	if d == nil {
		return false
	}
	if len(d.keywords) == 0 {
		return false
	}
	paraStart, paraEnd := paragraphBounds(d.body, offset)
	paragraph := strings.ToLower(string(d.body[paraStart:paraEnd]))
	for _, kw := range d.keywords {
		if strings.Contains(paragraph, kw) {
			return true
		}
	}
	return false
}

func paragraphBounds(body []byte, offset int) (int, int) {
	if offset < 0 {
		offset = 0
	}
	if offset > len(body) {
		offset = len(body)
	}
	start := offset
	for start > 0 {
		if start+1 < len(body) && body[start] == '\n' && body[start-1] == '\n' {
			start++
			break
		}
		if start == 1 && body[0] == '\n' {
			break
		}
		start--
	}
	if start < 0 {
		start = 0
	}
	end := offset
	for end < len(body) {
		if end+1 < len(body) && body[end] == '\n' && body[end+1] == '\n' {
			break
		}
		end++
	}
	return start, end
}


