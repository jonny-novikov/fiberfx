// Package fiberfx provides branded identifier types for Atlas schema definitions.
//
// Branded IDs are 14-character identifiers with format: {NS}{BASE62}
//   - NS: 3-character namespace prefix (e.g., "TSK", "USR")
//   - BASE62: 11-character Base62 encoded snowflake
//
// Example: TSK0Ij1P13FRDM
package fiberfx

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"
)

// Format constants
const (
	NamespaceLen = 3  // Namespace prefix length
	EncodedLen   = 11 // Base62 encoded snowflake length
	IDLen        = 14 // Total branded ID length

	// Snowflake epoch: 2024-01-01 00:00:00 UTC
	Epoch int64 = 1704067200000

	// Snowflake bit structure
	TimestampBits  = 41
	WorkerBits     = 10
	SequenceBits   = 12
	TimestampShift = WorkerBits + SequenceBits
	WorkerShift    = SequenceBits
	MaxWorkerID    = (1 << WorkerBits) - 1
	MaxSequence    = (1 << SequenceBits) - 1
)

// Base62 alphabet for encoding
const base62Chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

// ID represents a branded identifier with namespace and snowflake components.
type ID struct {
	value     string
	snowflake int64
	namespace Namespace
}

// Validation regex: 3 uppercase letters + 11 alphanumeric
var idPattern = regexp.MustCompile(`^[A-Z]{3}[0-9A-Za-z]{11}$`)

// New creates an ID from namespace and snowflake.
func New(ns Namespace, snowflake int64) ID {
	encoded := encodeBase62(snowflake)
	return ID{
		value:     string(ns) + encoded,
		snowflake: snowflake,
		namespace: ns,
	}
}

// Parse validates and parses a branded ID string.
func Parse(s string) (ID, error) {
	if len(s) != IDLen {
		return ID{}, fmt.Errorf("invalid length: expected %d, got %d", IDLen, len(s))
	}

	// Normalize namespace to uppercase
	normalized := strings.ToUpper(s[:NamespaceLen]) + s[NamespaceLen:]

	if !idPattern.MatchString(normalized) {
		return ID{}, errors.New("invalid format: must be 3 uppercase letters + 11 alphanumeric")
	}

	ns := Namespace(normalized[:NamespaceLen])
	snowflake, err := decodeBase62(normalized[NamespaceLen:])
	if err != nil {
		return ID{}, fmt.Errorf("invalid encoding: %w", err)
	}

	return ID{
		value:     normalized,
		snowflake: snowflake,
		namespace: ns,
	}, nil
}

// MustParse parses a branded ID, panicking on error.
func MustParse(s string) ID {
	id, err := Parse(s)
	if err != nil {
		panic(err)
	}
	return id
}

// String returns the full branded ID string.
func (id ID) String() string { return id.value }

// Snowflake returns the raw snowflake value.
func (id ID) Snowflake() int64 { return id.snowflake }

// Namespace returns the 3-character namespace.
func (id ID) Namespace() Namespace { return id.namespace }

// Timestamp extracts the creation time from the snowflake.
func (id ID) Timestamp() time.Time {
	ts := (id.snowflake >> TimestampShift) + Epoch
	return time.UnixMilli(ts)
}

// WorkerID extracts the worker ID from the snowflake.
func (id ID) WorkerID() int64 {
	return (id.snowflake >> WorkerShift) & int64(MaxWorkerID)
}

// Sequence extracts the sequence number from the snowflake.
func (id ID) Sequence() int64 {
	return id.snowflake & int64(MaxSequence)
}

// IsZero returns true if the ID is uninitialized.
func (id ID) IsZero() bool { return id.value == "" }

// MarshalText implements encoding.TextMarshaler.
func (id ID) MarshalText() ([]byte, error) {
	return []byte(id.value), nil
}

// UnmarshalText implements encoding.TextUnmarshaler.
func (id *ID) UnmarshalText(data []byte) error {
	parsed, err := Parse(string(data))
	if err != nil {
		return err
	}
	*id = parsed
	return nil
}

// Valid checks if the string is a valid branded ID format.
func Valid(s string) bool {
	if len(s) != IDLen {
		return false
	}
	normalized := strings.ToUpper(s[:NamespaceLen]) + s[NamespaceLen:]
	return idPattern.MatchString(normalized)
}

// encodeBase62 converts snowflake to 11-char Base62 string.
func encodeBase62(n int64) string {
	if n < 0 {
		n = -n
	}

	var buf [EncodedLen]byte
	for i := EncodedLen - 1; i >= 0; i-- {
		buf[i] = base62Chars[n%62]
		n /= 62
	}
	return string(buf[:])
}

// decodeBase62 converts 11-char Base62 string to snowflake.
func decodeBase62(s string) (int64, error) {
	var n int64
	for _, c := range s {
		n *= 62
		idx := strings.IndexRune(base62Chars, c)
		if idx < 0 {
			return 0, fmt.Errorf("invalid character: %c", c)
		}
		n += int64(idx)
	}
	return n, nil
}
