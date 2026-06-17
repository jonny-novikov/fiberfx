package stale

import "testing"

func TestDeletionContextNilSafe(t *testing.T) {
	var d *DeletionContext
	if d.MatchesAt(0) {
		t.Error("nil context should never match")
	}
}

func TestDeletionContextEmptyKeywords(t *testing.T) {
	d := NewDeletionContext([]byte("body text"), nil)
	if d.MatchesAt(0) {
		t.Error("empty keywords should never match")
	}
}

func TestDeletionContextMatchesParagraph(t *testing.T) {
	body := []byte(`first paragraph text. removed in 2026 refactor. tool_x is gone.

unrelated paragraph mentioning tool_x_compress here.
`)
	d := NewDeletionContext(body, []string{"removed", "deleted"})
	offsetIn := 38
	if !d.MatchesAt(offsetIn) {
		t.Errorf("expected match at offset %d (within removed-context paragraph)", offsetIn)
	}
	offsetOther := 100
	if d.MatchesAt(offsetOther) {
		t.Errorf("did not expect match at offset %d (different paragraph)", offsetOther)
	}
}

func TestDeletionContextSingleParagraph(t *testing.T) {
	body := []byte("First sentence. Second mentions removed things. Third has tool_x. Fourth is unrelated.")
	d := NewDeletionContext(body, []string{"removed"})
	idx := indexInBytes(body, "tool_x")
	if !d.MatchesAt(idx) {
		t.Errorf("expected paragraph-scope window to catch removed-keyword match")
	}
}

func TestParagraphBoundsEdgeCases(t *testing.T) {
	body := []byte("only paragraph")
	start, end := paragraphBounds(body, 5)
	if start != 0 || end != len(body) {
		t.Errorf("single paragraph bounds: start=%d end=%d", start, end)
	}
	start, end = paragraphBounds(body, -1)
	if start != 0 {
		t.Errorf("negative offset start=%d", start)
	}
	start, end = paragraphBounds(body, 100)
	_ = start
	if end != len(body) {
		t.Errorf("oversized offset end=%d want %d", end, len(body))
	}
}

func indexInBytes(body []byte, needle string) int {
	s := string(body)
	for i := 0; i+len(needle) <= len(s); i++ {
		if s[i:i+len(needle)] == needle {
			return i
		}
	}
	return -1
}
