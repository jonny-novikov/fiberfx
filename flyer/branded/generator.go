// branded/generator.go
// =============================================================================
// BRANDED ID GENERATION - Snowflake Generator and IDFactory
// =============================================================================
//
// Contains:
//   - Base62 encoding/decoding
//   - Snowflake extraction utilities
//   - Snowflake Generator (thread-safe)
//   - IDFactory for typed ID generation
//   - Parsing functions
//   - Global singleton
//
// =============================================================================

package branded

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
	"sync"
	"time"
)

// =============================================================================
// BASE62 ENCODING/DECODING
// =============================================================================

// EncodeBase62 converts a snowflake to 11-character Base62 string.
func EncodeBase62(num int64) string {
	if num == 0 {
		return "00000000000"
	}
	if num < 0 {
		num = -num
	}

	result := make([]byte, 0, EncodedLen)
	n := num

	for n > 0 {
		remainder := n % 62
		result = append(result, Base62Alphabet[remainder])
		n = n / 62
	}

	// Reverse
	for i, j := 0, len(result)-1; i < j; i, j = i+1, j-1 {
		result[i], result[j] = result[j], result[i]
	}

	// Pad to 11 characters with leading zeros
	for len(result) < EncodedLen {
		result = append([]byte{'0'}, result...)
	}

	return string(result)
}

// DecodeBase62 converts an 11-character Base62 string to snowflake.
func DecodeBase62(encoded string) (int64, error) {
	if len(encoded) == 0 {
		return 0, errors.New("encoded string cannot be empty")
	}

	var result int64
	for _, c := range encoded {
		result *= 62
		idx := strings.IndexRune(Base62Alphabet, c)
		if idx < 0 {
			return 0, fmt.Errorf("invalid Base62 character: %c", c)
		}
		result += int64(idx)
	}

	return result, nil
}

// IsValidBase62 checks if a string contains only valid Base62 characters.
func IsValidBase62(encoded string) bool {
	if len(encoded) == 0 {
		return false
	}
	for _, c := range encoded {
		if strings.IndexRune(Base62Alphabet, c) < 0 {
			return false
		}
	}
	return true
}

// =============================================================================
// SNOWFLAKE EXTRACTION
// =============================================================================

// ExtractTimestamp extracts the timestamp from a snowflake.
func ExtractTimestamp(snowflake int64) time.Time {
	timestampMs := (snowflake >> TimestampShift) + Epoch
	return time.UnixMilli(timestampMs)
}

// ExtractWorkerID extracts the worker ID from a snowflake.
func ExtractWorkerID(snowflake int64) int64 {
	return (snowflake >> WorkerShift) & int64(MaxWorkerID)
}

// ExtractSequence extracts the sequence number from a snowflake.
func ExtractSequence(snowflake int64) int64 {
	return snowflake & int64(MaxSequence)
}

// =============================================================================
// BRANDED ID PARSING
// =============================================================================

// Regex for branded ID validation
var brandedIDRegex = regexp.MustCompile(`^[A-Z]{3}[0-9A-Za-z]{11}$`)

// Parse validates and parses a branded ID string.
func Parse(value string) (*BrandedID, error) {
	if len(value) != BrandedLen {
		return nil, fmt.Errorf("branded ID must be %d characters", BrandedLen)
	}

	// Normalize namespace to uppercase
	normalized := strings.ToUpper(value[:3]) + value[3:]

	if !brandedIDRegex.MatchString(normalized) {
		return nil, errors.New("invalid branded ID format")
	}

	ns := Namespace(normalized[:3])
	encoded := normalized[3:]

	snowflake, err := DecodeBase62(encoded)
	if err != nil {
		return nil, fmt.Errorf("invalid Base62: %w", err)
	}

	return &BrandedID{
		Value:     normalized,
		Snowflake: snowflake,
		Namespace: ns,
		Timestamp: ExtractTimestamp(snowflake),
	}, nil
}

// ParseWithNamespace validates a branded ID against expected namespace.
func ParseWithNamespace(value string, expected Namespace) (*BrandedID, error) {
	id, err := Parse(value)
	if err != nil {
		return nil, err
	}

	if id.Namespace != expected {
		return nil, fmt.Errorf("expected namespace %s, got %s", expected, id.Namespace)
	}

	return id, nil
}

// FromSnowflake creates a BrandedID from a raw snowflake.
func FromSnowflake(snowflake int64, ns Namespace) *BrandedID {
	encoded := EncodeBase62(snowflake)
	return &BrandedID{
		Value:     string(ns) + encoded,
		Snowflake: snowflake,
		Namespace: ns,
		Timestamp: ExtractTimestamp(snowflake),
	}
}

// IsValidBrandedID checks if a string is a valid branded ID format.
func IsValidBrandedID(value string) bool {
	if len(value) != BrandedLen {
		return false
	}
	normalized := strings.ToUpper(value[:3]) + value[3:]
	return brandedIDRegex.MatchString(normalized)
}

// =============================================================================
// SNOWFLAKE GENERATOR
// =============================================================================

// Generator creates unique snowflake IDs.
// Thread-safe via mutex.
type Generator struct {
	mu       sync.Mutex
	workerID int64
	sequence int64
	lastTime int64
}

// NewGenerator creates a new snowflake generator.
// Worker ID should be unique per process/node (0-1023).
func NewGenerator(workerID int64) *Generator {
	if workerID < 0 || workerID > int64(MaxWorkerID) {
		workerID = workerID % int64(MaxWorkerID+1)
	}
	return &Generator{
		workerID: workerID,
	}
}

// Generate creates a new snowflake.
func (g *Generator) Generate() int64 {
	g.mu.Lock()
	defer g.mu.Unlock()

	timestamp := time.Now().UnixMilli() - Epoch

	if timestamp == g.lastTime {
		g.sequence = (g.sequence + 1) & int64(MaxSequence)
		if g.sequence == 0 {
			// Wait for next millisecond
			for timestamp <= g.lastTime {
				timestamp = time.Now().UnixMilli() - Epoch
			}
		}
	} else {
		g.sequence = 0
	}

	g.lastTime = timestamp

	return (timestamp << TimestampShift) |
		(g.workerID << WorkerShift) |
		g.sequence
}

// GenerateBranded creates a new branded ID with the given namespace.
func (g *Generator) GenerateBranded(ns Namespace) *BrandedID {
	snowflake := g.Generate()
	return FromSnowflake(snowflake, ns)
}

// WorkerID returns the generator's worker ID.
func (g *Generator) WorkerID() int64 {
	return g.workerID
}

// =============================================================================
// ID FACTORY - Typed ID Generation for FWHD
// =============================================================================

// IDFactory provides typed ID generation and parsing.
type IDFactory struct {
	gen *Generator
}

// NewIDFactory creates a factory with the given worker ID.
func NewIDFactory(workerID int64) *IDFactory {
	return &IDFactory{
		gen: NewGenerator(workerID),
	}
}

// Generator returns the underlying generator for custom use.
func (f *IDFactory) Generator() *Generator {
	return f.gen
}

// Package creates a new PackageID
func (f *IDFactory) Package() *PackageID {
	return f.gen.GenerateBranded(NS_PACKAGE)
}

func (f *IDFactory) ParsePackage(value string) (*PackageID, error) {
	return ParseWithNamespace(value, NS_PACKAGE)
}

// Release creates a new ReleaseID
func (f *IDFactory) Release() *ReleaseID {
	return f.gen.GenerateBranded(NS_RELEASE)
}

func (f *IDFactory) ParseRelease(value string) (*ReleaseID, error) {
	return ParseWithNamespace(value, NS_RELEASE)
}

// Deployment creates a new DeploymentID
func (f *IDFactory) Deployment() *DeploymentID {
	return f.gen.GenerateBranded(NS_DEPLOYMENT)
}

func (f *IDFactory) ParseDeployment(value string) (*DeploymentID, error) {
	return ParseWithNamespace(value, NS_DEPLOYMENT)
}

// Command creates a new CommandID
func (f *IDFactory) Command() *CommandID {
	return f.gen.GenerateBranded(NS_COMMAND)
}

func (f *IDFactory) ParseCommand(value string) (*CommandID, error) {
	return ParseWithNamespace(value, NS_COMMAND)
}

// =============================================================================
// GLOBAL SINGLETON
// =============================================================================

var (
	defaultFactory     *IDFactory
	defaultFactoryOnce sync.Once
)

// DefaultFactory returns the global IDFactory singleton.
// Uses worker ID 0 by default.
func DefaultFactory() *IDFactory {
	defaultFactoryOnce.Do(func() {
		defaultFactory = NewIDFactory(0)
	})
	return defaultFactory
}

// NewID generates a branded ID with the given namespace using the default factory.
func NewID(ns Namespace) *BrandedID {
	return DefaultFactory().gen.GenerateBranded(ns)
}
