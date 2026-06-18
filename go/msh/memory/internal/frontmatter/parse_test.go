package frontmatter

import "testing"

func TestParseFourField(t *testing.T) {
	body := []byte(`---
name: Sample
description: A sample
type: feedback
originSessionId: 11111111-2222-3333-4444-555555555555
---
body line one
body line two
`)
	r := Parse(body)
	if !r.Has {
		t.Fatal("expected Has=true")
	}
	if r.ParseError != "" {
		t.Fatalf("unexpected parse error: %s", r.ParseError)
	}
	if r.Frontmatter.Name != "Sample" {
		t.Errorf("Name=%q", r.Frontmatter.Name)
	}
	if r.Frontmatter.Type != "feedback" {
		t.Errorf("Type=%q", r.Frontmatter.Type)
	}
	if r.Frontmatter.OriginSessionID != "11111111-2222-3333-4444-555555555555" {
		t.Errorf("OriginSessionID=%q", r.Frontmatter.OriginSessionID)
	}
	if string(body[r.BodyOffset:r.BodyOffset+9]) != "body line" {
		t.Errorf("BodyOffset=%d wrong; got %q", r.BodyOffset, string(body[r.BodyOffset:r.BodyOffset+9]))
	}
}

func TestParseThreeField(t *testing.T) {
	body := []byte(`---
name: Sample
description: A sample
type: project
---
body
`)
	r := Parse(body)
	if !r.Has {
		t.Fatal("expected Has=true")
	}
	if r.Frontmatter.OriginSessionID != "" {
		t.Errorf("expected empty origin, got %q", r.Frontmatter.OriginSessionID)
	}
}

func TestParseMissing(t *testing.T) {
	body := []byte(`# heading

body
`)
	r := Parse(body)
	if r.Has {
		t.Fatal("expected Has=false")
	}
}

func TestParseMalformed(t *testing.T) {
	body := []byte(`---
name: [unterminated
---
body
`)
	r := Parse(body)
	if !r.Has {
		t.Fatal("expected Has=true (delimiters present)")
	}
	if r.ParseError == "" {
		t.Fatal("expected parse error")
	}
}

func TestParseNoClosingDelim(t *testing.T) {
	body := []byte(`---
name: Sample

no closing delim`)
	r := Parse(body)
	if r.Has {
		t.Fatal("expected Has=false (no closing delim)")
	}
}

func TestParseNestedMetadata(t *testing.T) {
	body := []byte(`---
name: nested-sample
description: nested
metadata:
  node_type: memory
  type: project
  originSessionId: 99999999-8888-7777-6666-555555555555
---
body
`)
	r := Parse(body)
	if !r.Has {
		t.Fatal("expected Has=true")
	}
	if r.ParseError != "" {
		t.Fatalf("unexpected parse error: %s", r.ParseError)
	}
	if r.Frontmatter.Type != "project" {
		t.Errorf("nested metadata.type not read: Type=%q", r.Frontmatter.Type)
	}
	if r.Frontmatter.OriginSessionID != "99999999-8888-7777-6666-555555555555" {
		t.Errorf("nested metadata.originSessionId not read: %q", r.Frontmatter.OriginSessionID)
	}
}

func TestParseTopLevelTypeWinsOverMetadata(t *testing.T) {
	body := []byte(`---
name: both
type: feedback
metadata:
  type: project
---
body
`)
	r := Parse(body)
	if r.Frontmatter.Type != "feedback" {
		t.Errorf("top-level type should win over metadata.type: got %q", r.Frontmatter.Type)
	}
}
