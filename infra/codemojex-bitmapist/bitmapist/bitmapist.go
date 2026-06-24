// Package bitmapist is a Go port of the bitmapist4 cohort model
// (github.com/Doist/bitmapist4), rewritten from Python so the Go stack — the
// codemojex-dashboard and any marker — speaks it directly, and made
// branded-id-native: every public call takes a 14-char branded id and resolves
// its bit offset through the in-repo branded codec (branded.Offset), so the
// dashboard talks in USR…/RMM… ids rather than raw integers.
//
// It keeps bitmapist4's key conventions (the "bitmapist_" prefix and the dated
// sibling keys), so the data is wire-compatible with bitmapist-server's tooling
// and with a Python bitmapist reader, should one ever run beside it.
package bitmapist

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/jonnify/codemojex-bitmapist/branded"
)

// Period selects which binned bitmap a call addresses.
type Period int

const (
	Day Period = iota
	Week
	Month
	Year
	Unique // a single date-independent key (bitmapist's UniqueEvents)
)

var (
	// ErrUnsupportedOp is returned by MemStore for bitwise ops it does not model.
	ErrUnsupportedOp = errors.New("bitmapist: unsupported bitop")
	// ErrBadID surfaces an invalid branded id from the codec.
	ErrBadID = errors.New("bitmapist: invalid branded id")
)

// Client marks and queries cohort bitmaps against a BitStore.
type Client struct {
	store       BitStore
	prefix      string
	trackHourly bool
}

// Option configures a Client.
type Option func(*Client)

// WithPrefix overrides the key prefix (default "bitmapist_").
func WithPrefix(p string) Option { return func(c *Client) { c.prefix = p } }

// New builds a Client over the given store.
func New(store BitStore, opts ...Option) *Client {
	c := &Client{store: store, prefix: "bitmapist_"}
	for _, o := range opts {
		o(c)
	}
	return c
}

// ---- key conventions (bitmapist4) ------------------------------------------

func (c *Client) bare(event string) string { return c.prefix + "_" + event }

// Key returns the bitmapist4 key for an event in a period at time t (UTC).
func (c *Client) Key(event string, t time.Time, p Period) string {
	t = t.UTC()
	y, mo, d := t.Date()
	switch p {
	case Day:
		return fmt.Sprintf("%s_%d-%d-%d", c.bare(event), y, int(mo), d)
	case Week:
		iy, iw := t.ISOWeek()
		return fmt.Sprintf("%s_W%d-%d", c.bare(event), iy, iw)
	case Month:
		return fmt.Sprintf("%s_%d-%d", c.bare(event), y, int(mo))
	case Year:
		return fmt.Sprintf("%s_Y%d", c.bare(event), y)
	default: // Unique
		return c.bare(event)
	}
}

// ---- marking (branded-native) ----------------------------------------------

// Mark records that the user (by branded id) performed event at time t, setting
// the bit in the day, week, month, and year bitmaps and the bare event key.
func (c *Client) Mark(ctx context.Context, event, brandedID string, t time.Time) error {
	off, err := branded.Offset(brandedID)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrBadID, err)
	}
	periods := []Period{Day, Week, Month, Year, Unique}
	for _, p := range periods {
		if err := c.store.SetBit(ctx, c.Key(event, t, p), off, 1); err != nil {
			return err
		}
	}
	return nil
}

// MarkUnique records a date-independent flag (a standing state) for the user.
func (c *Client) MarkUnique(ctx context.Context, event, brandedID string) error {
	off, err := branded.Offset(brandedID)
	if err != nil {
		return fmt.Errorf("%w: %v", ErrBadID, err)
	}
	return c.store.SetBit(ctx, c.bare(event), off, 1)
}

// ---- reads (branded-native) ------------------------------------------------

// In reports whether the user is in the event's bitmap for the period at t.
func (c *Client) In(ctx context.Context, event, brandedID string, t time.Time, p Period) (bool, error) {
	off, err := branded.Offset(brandedID)
	if err != nil {
		return false, fmt.Errorf("%w: %v", ErrBadID, err)
	}
	v, err := c.store.GetBit(ctx, c.Key(event, t, p), off)
	return v == 1, err
}

// Count returns how many distinct users are in the event's bitmap for the
// period at t. The 32-bit hash undercounts by its collision rate at scale.
func (c *Client) Count(ctx context.Context, event string, t time.Time, p Period) (int64, error) {
	return c.store.BitCount(ctx, c.Key(event, t, p))
}

// ---- cohort operations -----------------------------------------------------

func (c *Client) tempKey() string {
	var b [8]byte
	_, _ = rand.Read(b[:])
	return c.prefix + "_BITOP_" + hex.EncodeToString(b[:])
}

// opCount applies a bitwise op across keys into a temporary key, counts it, and
// deletes the temporary — no cohort scratch lingers.
func (c *Client) opCount(ctx context.Context, op string, keys ...string) (int64, error) {
	dest := c.tempKey()
	if err := c.store.BitOp(ctx, op, dest, keys...); err != nil {
		return 0, err
	}
	n, err := c.store.BitCount(ctx, dest)
	_ = c.store.Del(ctx, dest)
	return n, err
}

// AndCount is the size of the intersection of the keys — retention and funnels.
func (c *Client) AndCount(ctx context.Context, keys ...string) (int64, error) {
	return c.opCount(ctx, "AND", keys...)
}

// OrCount is the size of the union of the keys.
func (c *Client) OrCount(ctx context.Context, keys ...string) (int64, error) {
	return c.opCount(ctx, "OR", keys...)
}

// XorCount is the size of the symmetric difference of the keys.
func (c *Client) XorCount(ctx context.Context, keys ...string) (int64, error) {
	return c.opCount(ctx, "XOR", keys...)
}

// RetentionRow is the classic bitmapist retention curve: the cohort size,
// followed by the count still present in each follow-up period bitmap.
func (c *Client) RetentionRow(ctx context.Context, cohortKey string, followKeys []string) ([]int64, error) {
	base, err := c.store.BitCount(ctx, cohortKey)
	if err != nil {
		return nil, err
	}
	row := make([]int64, 0, len(followKeys)+1)
	row = append(row, base)
	for _, fk := range followKeys {
		n, err := c.AndCount(ctx, cohortKey, fk)
		if err != nil {
			return nil, err
		}
		row = append(row, n)
	}
	return row, nil
}
