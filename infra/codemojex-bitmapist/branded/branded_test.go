package branded

import "testing"

// contractVectors mirrors the Rust reference tests in branded_id.rs so the Go
// port is proven byte-for-byte against the same vectors the BEAM and C pass.
func TestContractVectors(t *testing.T) {
	if got, _ := Encode("USR", 274557032793636864); got != "USR0KHTOWnGLuC" {
		t.Fatalf("encode: got %q", got)
	}
	ns, v, err := Decode("USR0NgWEfAEJfs")
	if err != nil || ns != "USR" || v != 320636799581945856 {
		t.Fatalf("decode: %q %d %v", ns, v, err)
	}
	if got := UnixMs(v); got != 1780512970164 {
		t.Fatalf("unix_ms: got %d", got)
	}
	if got := Hash32(274557032793636864); got != 234878118 {
		t.Fatalf("hash32: got %d", got)
	}
	if off, err := Offset("USR0KHTOWnGLuC"); err != nil || off != 234878118 {
		t.Fatalf("offset: %d %v", off, err)
	}
}

func TestBoundaries(t *testing.T) {
	if _, max, err := Decode("USRAzL8n0Y58m7"); err != nil || max != MaxSnow {
		t.Fatalf("max payload: %d %v", max, err)
	}
	cases := []struct {
		id   string
		want error
	}{
		{"USRzzzzzzzzzzz", ErrRange},
		{"usr0KHTOWnGLuC", ErrNamespace},
		{"USR0KHTOWnGLu*", ErrCharset},
		{"USR0KHTOWnGLu", ErrLength},
		{"USR0KHTOWnGLuCx", ErrLength},
	}
	for _, c := range cases {
		if _, _, err := Decode(c.id); err != c.want {
			t.Errorf("decode(%q): got %v want %v", c.id, err, c.want)
		}
	}
	if _, err := Encode("USR", 1<<63); err != ErrRange {
		t.Errorf("encode overflow: got %v", err)
	}
	if got, _ := Encode("USR", 0); got != "USR00000000000" {
		t.Errorf("encode zero: got %q", got)
	}
}

// TestRoundtripMillion replays the reference's xorshift property test.
func TestRoundtripMillion(t *testing.T) {
	s := uint64(0x6A09E667F3BCC909)
	for i := 0; i < 1_000_000; i++ {
		s ^= s << 13
		s ^= s >> 7
		s ^= s << 17
		x := s & 0x7FFFFFFFFFFFFFFF
		id, err := Encode("CRS", x)
		if err != nil {
			t.Fatalf("encode %d: %v", x, err)
		}
		ns, back, err := Decode(id)
		if err != nil || ns != "CRS" || back != x {
			t.Fatalf("roundtrip %d -> %q -> %q %d %v", x, id, ns, back, err)
		}
	}
}
