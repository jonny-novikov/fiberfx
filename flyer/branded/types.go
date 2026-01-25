// branded/types.go
// =============================================================================
// BRANDED ID TYPES - Core Type Definitions for FWHD
// =============================================================================
//
// Contains the BrandedID type and typed aliases for FWHD domain entities.
// Format: '{NS}{BASE62}' (3-char namespace + 11-char Base62 = 14 chars)
//
// =============================================================================

package branded

import (
	"time"
)

// =============================================================================
// CONSTANTS
// =============================================================================

const (
	// Epoch: 2024-01-01 00:00:00 UTC in milliseconds
	Epoch int64 = 1704067200000

	// Base62 alphabet (digits + uppercase + lowercase)
	Base62Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

	// Snowflake bit structure (64-bit layout)
	TimestampBits  = 41
	WorkerBits     = 10
	SequenceBits   = 12
	TimestampShift = SequenceBits + WorkerBits // 22
	WorkerShift    = SequenceBits              // 12

	// Derived values
	MaxWorkerID  = (1 << WorkerBits) - 1  // 1023
	MaxSequence  = (1 << SequenceBits) - 1 // 4095

	// Branded ID format
	NamespaceLen = 3
	EncodedLen   = 11
	BrandedLen   = NamespaceLen + EncodedLen // 14
)

// =============================================================================
// BRANDED ID TYPE
// =============================================================================

// BrandedID carries namespace, snowflake, and formatted value together.
type BrandedID struct {
	Value     string    // Full branded string: "PKG0KCdYDJzkEy"
	Snowflake int64     // Raw snowflake for database
	Namespace Namespace // "PKG"
	Timestamp time.Time // Extracted from snowflake
}

// String returns the branded ID string.
func (b BrandedID) String() string {
	return b.Value
}

// MarshalJSON for JSON serialization.
func (b BrandedID) MarshalJSON() ([]byte, error) {
	return []byte(`"` + b.Value + `"`), nil
}

// =============================================================================
// TYPED ID ALIASES - FWHD Domain
// =============================================================================

type (
	PackageID    = BrandedID // PKG - Package artifact
	ReleaseID    = BrandedID // RLS - Release version
	DeploymentID = BrandedID // DPL - Deployment record
	CommandID    = BrandedID // CMD - Deploy command
)
