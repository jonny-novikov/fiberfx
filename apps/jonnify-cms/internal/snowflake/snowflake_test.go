package snowflake

import (
	"testing"
	"time"
)

// The canonical example from the course brief and build_page.py.
func TestDecodeKnownExample(t *testing.T) {
	d, err := Decode("TSK0KHTOWnGLuC")
	if err != nil {
		t.Fatal(err)
	}
	if d.Namespace != "TSK" {
		t.Errorf("namespace = %q, want TSK", d.Namespace)
	}
	if d.Snowflake != 274557032793636864 {
		t.Errorf("snowflake = %d, want 274557032793636864", d.Snowflake)
	}
	if d.Node != 0 || d.Seq != 0 {
		t.Errorf("node/seq = %d/%d, want 0/0", d.Node, d.Seq)
	}
	if d.Timestamp != "2026-01-27 15:11:37 UTC" {
		t.Errorf("timestamp = %q, want 2026-01-27 15:11:37 UTC", d.Timestamp)
	}
}

// Mint from the decoded exact instant reproduces the id (avoids the sub-second
// floor that the display timestamp would otherwise introduce).
func TestMintRoundTrip(t *testing.T) {
	d, err := Decode("TSK0KHTOWnGLuC")
	if err != nil {
		t.Fatal(err)
	}
	id, err := Mint("TSK", d.Node, d.Seq, d.Time)
	if err != nil {
		t.Fatal(err)
	}
	if id != "TSK0KHTOWnGLuC" {
		t.Errorf("mint = %q, want TSK0KHTOWnGLuC", id)
	}
}

func TestB62ZeroPadded(t *testing.T) {
	if got := B62Encode(0, 11); got != "00000000000" {
		t.Errorf("B62Encode(0,11) = %q, want 11 zeros", got)
	}
	n, err := B62Decode("00000000000")
	if err != nil || n != 0 {
		t.Errorf("B62Decode(zeros) = %d, %v, want 0", n, err)
	}
}

func TestMintBadNamespace(t *testing.T) {
	if _, err := Mint("TS", 0, 0, time.Time{}); err == nil {
		t.Error("expected error for a 2-character namespace")
	}
}
