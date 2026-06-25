package bitmapist

import "context"

// BitStore is the subset of bitmap operations the bitmapist model needs, as
// served by bitmapist-server over the Redis protocol (or by Valkey/Redis).
// Offsets are uint32 — the branded-id hash sits inside 32 bits, which is also
// roaring's native width, so bitmapist-server stores the sparse offsets cheaply.
type BitStore interface {
	SetBit(ctx context.Context, key string, offset uint32, val int) error
	GetBit(ctx context.Context, key string, offset uint32) (int, error)
	BitCount(ctx context.Context, key string) (int64, error)
	// BitOp applies op (AND, OR, XOR) over the source keys into dest.
	BitOp(ctx context.Context, op, dest string, keys ...string) error
	Del(ctx context.Context, keys ...string) error
}

// MemStore is an in-memory BitStore for tests and local development. It models
// each bitmap as a set of set offsets, which is semantically faithful to the
// server (it is not memory-optimized; bitmapist-server's roaring store is).
type MemStore struct{ m map[string]map[uint32]struct{} }

func NewMemStore() *MemStore { return &MemStore{m: map[string]map[uint32]struct{}{}} }

func (s *MemStore) SetBit(_ context.Context, key string, off uint32, val int) error {
	if val == 0 {
		if b, ok := s.m[key]; ok {
			delete(b, off)
		}
		return nil
	}
	b := s.m[key]
	if b == nil {
		b = map[uint32]struct{}{}
		s.m[key] = b
	}
	b[off] = struct{}{}
	return nil
}

func (s *MemStore) GetBit(_ context.Context, key string, off uint32) (int, error) {
	if b, ok := s.m[key]; ok {
		if _, set := b[off]; set {
			return 1, nil
		}
	}
	return 0, nil
}

func (s *MemStore) BitCount(_ context.Context, key string) (int64, error) {
	return int64(len(s.m[key])), nil
}

func (s *MemStore) BitOp(_ context.Context, op, dest string, keys ...string) error {
	res := map[uint32]struct{}{}
	switch op {
	case "AND":
		if len(keys) > 0 {
			for off := range s.m[keys[0]] {
				in := true
				for _, k := range keys[1:] {
					if _, ok := s.m[k][off]; !ok {
						in = false
						break
					}
				}
				if in {
					res[off] = struct{}{}
				}
			}
		}
	case "OR":
		for _, k := range keys {
			for off := range s.m[k] {
				res[off] = struct{}{}
			}
		}
	case "XOR":
		counts := map[uint32]int{}
		for _, k := range keys {
			for off := range s.m[k] {
				counts[off]++
			}
		}
		for off, c := range counts {
			if c%2 == 1 {
				res[off] = struct{}{}
			}
		}
	default:
		return ErrUnsupportedOp
	}
	s.m[dest] = res
	return nil
}

func (s *MemStore) Del(_ context.Context, keys ...string) error {
	for _, k := range keys {
		delete(s.m, k)
	}
	return nil
}
