// Package brandedid implements the branded snowflake contract (brd14) in pure
// Go: a 3-byte uppercase namespace + an 11-byte Base62 payload over a
// ts(41)|node(10)|seq(12) snowflake, epoch 2024-01-01T00:00:00Z — time-ordered
// and coordination-free.
//
// The codec below is vendored verbatim from the canonical reference
// (dev/echo_data/runtimes/go/brandedid), whose contract "travels as test
// vectors, not as a shared object"; brandedid_test.go re-asserts those vectors
// so this copy can never drift. The minter (snowflake.go) ports
// EchoData.Snowflake.
package brandedid

import (
	"errors"
	"time"
)

const (
	// EpochMs is the contract epoch: 2024-01-01T00:00:00Z.
	EpochMs = 1_704_067_200_000
	// Len is the fixed branded length: 3-byte namespace + 11-byte payload.
	Len = 14

	alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	// base62(2^63-1): lexicographic range guard for the payload.
	maxPayload = "AzL8n0Y58m7"
)

var ErrInvalid = errors.New("brandedid: invalid branded id")

var values [256]int8

func init() {
	for i := range values {
		values[i] = -1
	}
	for i := 0; i < 62; i++ {
		values[alphabet[i]] = int8(i)
	}
}

// Encode brands a snowflake. ns must be 3 bytes of A-Z; snow must fit int64.
func Encode(ns string, snow uint64) (string, error) {
	if len(ns) != 3 || !upper3(ns) || snow > 1<<63-1 {
		return "", ErrInvalid
	}
	var buf [Len]byte
	buf[0], buf[1], buf[2] = ns[0], ns[1], ns[2]
	for i := 13; i >= 3; i-- {
		buf[i] = alphabet[snow%62] // constant divisor: compiled to multiply, no DIV
		snow /= 62
	}
	return string(buf[:]), nil
}

func MustEncode(ns string, snow uint64) string {
	id, err := Encode(ns, snow)
	if err != nil {
		panic(err)
	}
	return id
}

// Parse splits a branded id into namespace and snowflake, gate-checked.
func Parse(id string) (ns string, snow uint64, err error) {
	if len(id) != Len || !upper3(id) || id[3:] > maxPayload {
		return "", 0, ErrInvalid
	}
	for i := 3; i < Len; i++ {
		d := values[id[i]]
		if d < 0 {
			return "", 0, ErrInvalid
		}
		snow = snow*62 + uint64(d)
	}
	return id[:3], snow, nil
}

func Decode(id string) (uint64, error) {
	_, snow, err := Parse(id)
	return snow, err
}

func Valid(id string) bool {
	_, _, err := Parse(id)
	return err == nil
}

// Hash32 is the trie-placement contract hash: the first half of
// MurmurHash3 fmix64, truncated to 32 bits. Vector: Hash32(274557032793636864) == 234878118.
func Hash32(snow uint64) uint32 {
	k := snow
	k ^= k >> 33
	k *= 0xFF51AFD7ED558CCD
	k ^= k >> 33
	return uint32(k)
}

// UnixMs extracts the mint instant.
func UnixMs(snow uint64) int64 { return int64(snow>>22) + EpochMs }

// Time extracts the mint instant as time.Time.
func Time(snow uint64) time.Time { return time.UnixMilli(UnixMs(snow)) }

// MinFor returns the smallest snowflake mintable at or after t — the
// half-open lower bound for time-range scans and synthetic cursors.
func MinFor(t time.Time) uint64 { return uint64(t.UnixMilli()-EpochMs) << 22 }

func upper3(s string) bool {
	return s[0] >= 'A' && s[0] <= 'Z' && s[1] >= 'A' && s[1] <= 'Z' && s[2] >= 'A' && s[2] <= 'Z'
}
