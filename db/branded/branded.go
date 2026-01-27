// Package branded provides a branded ID system for image files.
// Uses Snowflake IDs encoded in Base62 for compact, sortable identifiers.
package branded

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"
)

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

const (
	// Epoch is the custom epoch (2024-01-01 00:00:00 UTC) for snowflake IDs
	Epoch int64 = 1704067200000

	// Base62Alphabet for encoding
	Base62Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

	// Bit allocation for snowflake ID
	TimestampBits = 41
	WorkerBits    = 10
	SequenceBits  = 12

	// Bit shifts
	TimestampShift = WorkerBits + SequenceBits
	WorkerShift    = SequenceBits

	// Maximum values
	MaxWorkerID  = (1 << WorkerBits) - 1
	MaxSequence  = (1 << SequenceBits) - 1
	EncodedLen   = 11
)

// ═══════════════════════════════════════════════════════════════════════════════
// GENERATOR
// ═══════════════════════════════════════════════════════════════════════════════

// Generator generates snowflake IDs
type Generator struct {
	mu        sync.Mutex
	workerID  int64
	sequence  int64
	lastTime  int64
}

// NewGenerator creates a new snowflake generator with the given worker ID
func NewGenerator(workerID int64) (*Generator, error) {
	if workerID < 0 || workerID > MaxWorkerID {
		return nil, fmt.Errorf("worker ID must be between 0 and %d", MaxWorkerID)
	}
	return &Generator{workerID: workerID}, nil
}

// Generate produces a new snowflake ID
func (g *Generator) Generate() int64 {
	g.mu.Lock()
	defer g.mu.Unlock()

	now := time.Now().UnixMilli() - Epoch

	if now == g.lastTime {
		g.sequence = (g.sequence + 1) & MaxSequence
		if g.sequence == 0 {
			for now <= g.lastTime {
				now = time.Now().UnixMilli() - Epoch
			}
		}
	} else {
		g.sequence = 0
	}

	g.lastTime = now

	return (now << TimestampShift) | (g.workerID << WorkerShift) | g.sequence
}

// ═══════════════════════════════════════════════════════════════════════════════
// BASE62 ENCODING
// ═══════════════════════════════════════════════════════════════════════════════

// EncodeBase62 encodes an int64 to a Base62 string with fixed length
func EncodeBase62(n int64) string {
	if n == 0 {
		return strings.Repeat("0", EncodedLen)
	}

	var result strings.Builder
	for n > 0 {
		result.WriteByte(Base62Alphabet[n%62])
		n /= 62
	}

	// Pad to fixed length
	str := result.String()
	if len(str) < EncodedLen {
		str = str + strings.Repeat("0", EncodedLen-len(str))
	}

	// Reverse
	runes := []rune(str)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}

	return string(runes)
}

// DecodeBase62 decodes a Base62 string to int64
func DecodeBase62(s string) (int64, error) {
	var result int64
	for _, c := range s {
		result *= 62
		idx := strings.IndexRune(Base62Alphabet, c)
		if idx < 0 {
			return 0, fmt.Errorf("invalid Base62 character: %c", c)
		}
		result += int64(idx)
	}
	return result, nil
}

// ═══════════════════════════════════════════════════════════════════════════════
// IMAGE BRANDED ID
// ═══════════════════════════════════════════════════════════════════════════════

// ImageBrandedID represents a branded image identifier
type ImageBrandedID struct {
	ID        int64
	Encoded   string
	Version   int
	Extension string
}

// ImageIDFactory creates image branded IDs
type ImageIDFactory struct {
	gen *Generator
}

// NewImageIDFactory creates a factory for generating image IDs
func NewImageIDFactory(workerID int64) (*ImageIDFactory, error) {
	gen, err := NewGenerator(workerID)
	if err != nil {
		return nil, err
	}
	return &ImageIDFactory{gen: gen}, nil
}

// Generate creates a new ImageBrandedID
func (f *ImageIDFactory) Generate(ext string) ImageBrandedID {
	id := f.gen.Generate()
	return ImageBrandedID{
		ID:        id,
		Encoded:   EncodeBase62(id),
		Version:   1,
		Extension: ext,
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// FILENAME UTILITIES
// ═══════════════════════════════════════════════════════════════════════════════

// ImageFilename generates a filename from an encoded ID and extension
func ImageFilename(encoded, ext string) string {
	return fmt.Sprintf("%s.%s", encoded, ext)
}

// ImageFilenameWithVersion generates a versioned filename
func ImageFilenameWithVersion(encoded, ext string, version int) string {
	if version <= 1 {
		return ImageFilename(encoded, ext)
	}
	return fmt.Sprintf("%s_v%d.%s", encoded, version, ext)
}

// OrderPrefix returns the order prefix from an encoded ID (first 4 chars)
func OrderPrefix(encoded string) string {
	if len(encoded) < 4 {
		return encoded
	}
	return encoded[:4]
}

// OrderPrefixWithVersion returns order prefix with version
func OrderPrefixWithVersion(encoded string, version int) string {
	prefix := OrderPrefix(encoded)
	if version <= 1 {
		return prefix
	}
	return fmt.Sprintf("%s_v%d", prefix, version)
}

// ParseOrderVersion extracts version from a string like "prefix_v2"
func ParseOrderVersion(s string) (prefix string, version int, err error) {
	if idx := strings.LastIndex(s, "_v"); idx > 0 {
		prefix = s[:idx]
		verStr := s[idx+2:]
		version, err = strconv.Atoi(verStr)
		if err != nil {
			return s, 1, nil
		}
		return prefix, version, nil
	}
	return s, 1, nil
}

// ParseImageFilename parses a branded image filename
func ParseImageFilename(filename string) (encoded string, ext string, version int, err error) {
	// Remove extension
	lastDot := strings.LastIndex(filename, ".")
	if lastDot < 0 {
		return "", "", 0, errors.New("no extension found")
	}
	ext = filename[lastDot+1:]
	base := filename[:lastDot]

	// Check for version
	if idx := strings.LastIndex(base, "_v"); idx > 0 {
		encoded = base[:idx]
		verStr := base[idx+2:]
		version, err = strconv.Atoi(verStr)
		if err != nil {
			return base, ext, 1, nil
		}
		return encoded, ext, version, nil
	}

	return base, ext, 1, nil
}

// IsValidImageFilename checks if a filename matches the branded ID pattern
func IsValidImageFilename(filename string) bool {
	encoded, _, _, err := ParseImageFilename(filename)
	if err != nil {
		return false
	}
	return len(encoded) == EncodedLen
}
