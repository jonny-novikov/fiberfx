// Package snowflake implements the branded Snowflake build-stamp scheme used
// throughout the Elixir course: a three-character namespace prefix followed by
// an eleven-character base62 encoding of a 64-bit Snowflake id. It is a faithful
// port of the mint/decode logic in docs/elixir/kb/build_page.py and reproduces
// the on-page JavaScript decoder exactly.
package snowflake

import (
	"errors"
	"fmt"
	"time"
)

const (
	// EpochMS is the custom epoch (2024-01-01T00:00:00Z) in milliseconds.
	EpochMS = int64(1_704_067_200_000)
	// B62 is the base62 alphabet: digits, then upper case, then lower case.
	B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

	b62Width  = 11
	tsShift   = 22
	nodeShift = 12
	nodeMask  = 0x3FF // 10-bit node
	seqMask   = 0xFFF // 12-bit sequence
)

// Compose packs a relative-millisecond timestamp, a 10-bit node and a 12-bit
// sequence into a 64-bit Snowflake: (rel << 22) | (node << 12) | seq.
func Compose(tsMS int64, node, seq uint64) (uint64, error) {
	rel := tsMS - EpochMS
	if rel < 0 {
		return 0, errors.New("timestamp predates the snowflake epoch")
	}
	return (uint64(rel) << tsShift) | ((node & nodeMask) << nodeShift) | (seq & seqMask), nil
}

// B62Encode renders n in base62, left-zero-padded to at least width characters.
func B62Encode(n uint64, width int) string {
	var s string
	if n == 0 {
		s = "0"
	} else {
		buf := make([]byte, 0, 16)
		for n > 0 {
			buf = append(buf, B62[n%62])
			n /= 62
		}
		for i, j := 0, len(buf)-1; i < j; i, j = i+1, j-1 {
			buf[i], buf[j] = buf[j], buf[i]
		}
		s = string(buf)
	}
	for len(s) < width {
		s = "0" + s
	}
	return s
}

// B62Decode parses a base62 string via Horner's method.
func B62Decode(s string) (uint64, error) {
	var n uint64
	for i := 0; i < len(s); i++ {
		idx := indexB62(s[i])
		if idx < 0 {
			return 0, fmt.Errorf("invalid base62 character %q", s[i])
		}
		n = n*62 + uint64(idx)
	}
	return n, nil
}

func indexB62(c byte) int {
	switch {
	case c >= '0' && c <= '9':
		return int(c - '0')
	case c >= 'A' && c <= 'Z':
		return int(c-'A') + 10
	case c >= 'a' && c <= 'z':
		return int(c-'a') + 36
	}
	return -1
}

// Mint builds a 14-character branded id for the given namespace (exactly three
// characters), node, sequence and instant. A zero `at` uses the current time.
func Mint(ns string, node, seq uint64, at time.Time) (string, error) {
	if len([]rune(ns)) != 3 {
		return "", errors.New("namespace prefix must be exactly 3 characters")
	}
	if at.IsZero() {
		at = time.Now()
	}
	snow, err := Compose(at.UTC().UnixMilli(), node, seq)
	if err != nil {
		return "", err
	}
	return ns + B62Encode(snow, b62Width), nil
}

// Decoded is the result of unpacking a branded id.
type Decoded struct {
	Branded   string    `json:"branded"`
	Namespace string    `json:"namespace"`
	Snowflake uint64    `json:"snowflake"`
	Node      uint64    `json:"node"`
	Seq       uint64    `json:"seq"`
	Timestamp string    `json:"timestamp"`
	Time      time.Time `json:"-"`
}

// Decode unpacks a 14-character branded id back into its fields.
func Decode(branded string) (Decoded, error) {
	if len(branded) < 4 {
		return Decoded{}, errors.New("branded id too short")
	}
	snow, err := B62Decode(branded[3:])
	if err != nil {
		return Decoded{}, err
	}
	ts := snow >> tsShift
	node := (snow >> nodeShift) & nodeMask
	seq := snow & seqMask
	t := time.UnixMilli(EpochMS + int64(ts)).UTC()
	return Decoded{
		Branded:   branded,
		Namespace: branded[:3],
		Snowflake: snow,
		Node:      node,
		Seq:       seq,
		Timestamp: t.Format("2006-01-02 15:04:05") + " UTC",
		Time:      t,
	}, nil
}
