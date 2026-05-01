package linkx

import (
	"strings"

	"github.com/fiberfx/hugot-memory/internal/graph"
)

func ClassifyMDLink(target string) graph.EdgeKind {
	if target == "" {
		return graph.EdgeAnchorOnly
	}
	if strings.HasPrefix(target, "#") {
		return graph.EdgeAnchorOnly
	}
	if strings.HasPrefix(target, "../") || strings.HasPrefix(target, "./") {
		return graph.EdgeExternalRel
	}
	if strings.HasPrefix(target, "http://") || strings.HasPrefix(target, "https://") {
		return graph.EdgeExternalRel
	}
	if strings.Contains(target, "/") {
		if strings.HasPrefix(target, "topics/") {
			if strings.Contains(target, "#") {
				return graph.EdgeMDLinkAnchor
			}
			return graph.EdgeCrossSubdir
		}
		return graph.EdgeExternalRel
	}
	if strings.Contains(target, "#") {
		return graph.EdgeMDLinkAnchor
	}
	return graph.EdgeMDLink
}

func SplitAnchor(target string) (path, anchor string) {
	if i := strings.Index(target, "#"); i >= 0 {
		return target[:i], target[i+1:]
	}
	return target, ""
}
