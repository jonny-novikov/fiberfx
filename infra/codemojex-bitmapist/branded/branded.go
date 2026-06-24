// Package branded is a Go port of the branded Snowflake contract that the Echo
// umbrella ships as a Rust NIF (apps/echo_data/native/branded_id.rs) and a C
// ABI (branded_id.h), with the matching pure-Elixir module EchoData.BrandedId.
//
// A branded id is 14 bytes: a 3 x [A-Z] namespace followed by 11 base62 digits
// of a 63-bit snowflake (layout ts(41)<<22 | node(10)<<12 | seq(12), epoch
// 2024-01-01Z). This port carries the same algorithms and the same contract
// vectors, so a Go caller derives the same offset for a branded id as the BEAM:
//
//	branded.Encode("USR", 274557032793636864) == "USR0KHTOWnGLuC"
//	branded.Decode("USR0NgWEfAEJfs")           == ("USR", 320636799581945856)
//	branded.Hash32(274557032793636864)         == 234878118
//
// Hash32 is the offset used for bitmap analytics. It is the first half of
// MurmurHash3's fmix64 truncated to 32 bits: a hash, so it is one-way (an
// offset does not reveal its branded id) and collision-bearing in the 32-bit
// space (distinct counts undercount by the collision rate at scale).
package branded

import "errors"

const (
	Len        = 14
	NsLen      = 3
	PayloadLen = 11
	EpochMS    = uint64(1_704_067_200_000) // 2024-01-01T00:00:00Z
	MaxSnow    = uint64(1)<<63 - 1         // 2^63 - 1

	alphabet   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	p62_6      = uint64(56_800_235_584) // 62^6
	maxPayload = "AzL8n0Y58m7"          // base62(2^63 - 1), the lexicographic range guard
)

// Validation errors, in the contract's precedence order.
var (
	ErrLength    = errors.New("branded: input is not exactly 14 bytes")
	ErrNamespace = errors.New("branded: namespace is not 3 x [A-Z]")
	ErrCharset   = errors.New("branded: payload byte outside [0-9A-Za-z]")
	ErrRange     = errors.New("branded: value outside [0, 2^63)")
)

// decodeTbl maps a base62 byte to its digit, or -1 for an invalid byte.
var decodeTbl = func() [256]int8 {
	var t [256]int8
	for i := range t {
		t[i] = -1
	}
	for i := 0; i < 62; i++ {
		t[alphabet[i]] = int8(i)
	}
	return t
}()

func nsValid(ns string) bool {
	if len(ns) != NsLen {
		return false
	}
	for i := 0; i < NsLen; i++ {
		if ns[i] < 'A' || ns[i] > 'Z' {
			return false
		}
	}
	return true
}

// Encode writes a snowflake (< 2^63) under a 3 x [A-Z] namespace into 14 bytes,
// using the same split-chain pair-table layout as the reference encoder.
func Encode(ns string, snowflake uint64) (string, error) {
	if snowflake > MaxSnow {
		return "", ErrRange
	}
	if !nsValid(ns) {
		return "", ErrNamespace
	}
	out := make([]byte, Len)
	copy(out, ns)

	pair := func(at int, k uint32) {
		out[at] = alphabet[k/62]
		out[at+1] = alphabet[k%62]
	}

	hi := uint32(snowflake / p62_6) // < 62^5: payload digits 0..4
	lo := snowflake % p62_6         // < 62^6: payload digits 5..10

	pair(6, hi%3844)
	hi /= 3844
	pair(4, hi%3844)
	hi /= 3844
	out[3] = alphabet[hi] // hi < 62

	pair(12, uint32(lo%3844))
	l := uint32(lo / 3844) // < 62^4
	pair(10, l%3844)
	l /= 3844
	pair(8, l) // l < 3844

	return string(out), nil
}

// Decode parses exactly 14 bytes into (namespace, snowflake < 2^63).
// Validation order: length, namespace, charset, range.
func Decode(id string) (ns string, snowflake uint64, err error) {
	if len(id) != Len {
		return "", 0, ErrLength
	}
	if !nsValid(id[:NsLen]) {
		return "", 0, ErrNamespace
	}
	p := id[NsLen:Len]

	var bad bool
	var hi uint32  // digits 0..4
	var low uint64 // digits 5..10
	for i := 0; i < 5; i++ {
		d := decodeTbl[p[i]]
		if d < 0 {
			bad = true
		}
		hi = hi*62 + uint32(d)
	}
	for i := 5; i < PayloadLen; i++ {
		d := decodeTbl[p[i]]
		if d < 0 {
			bad = true
		}
		low = low*62 + uint64(d)
	}
	if bad {
		return "", 0, ErrCharset
	}
	// ASCII order equals base62 numeric order for this alphabet, so the range
	// guard is a fixed-width byte compare against base62(2^63 - 1).
	if p > maxPayload {
		return "", 0, ErrRange
	}
	return id[:NsLen], uint64(hi)*p62_6 + low, nil
}

// Hash32 is the trie hash: the first half of MurmurHash3's fmix64, truncated to
// the low 32 bits. Contract vector: Hash32(274557032793636864) == 234878118.
func Hash32(key uint64) uint32 {
	k := key
	k ^= k >> 33
	k *= 0xFF51AFD7ED558CCD
	k ^= k >> 33
	return uint32(k)
}

// UnixMs is the mint instant of a snowflake as Unix milliseconds.
func UnixMs(snowflake uint64) uint64 { return (snowflake >> 22) + EpochMS }

// Offset is the bitmap offset for a branded id: Decode then Hash32. This is the
// value to pass as the bit position in bitmapist marks and reads.
func Offset(id string) (uint32, error) {
	_, snow, err := Decode(id)
	if err != nil {
		return 0, err
	}
	return Hash32(snow), nil
}
