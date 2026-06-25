package bitmapist

import (
	"context"
	"time"

	"github.com/gomodule/redigo/redis"
)

// RedigoStore is a BitStore backed by bitmapist-server over the Redis protocol.
// It uses redigo (a plain RESP client) on purpose: bitmapist-server implements
// a subset of Redis on a minimal RESP server and does not negotiate RESP3, so a
// client that issues exactly the commands given — rather than a mandatory
// HELLO 3 handshake — connects without surprises. Point it at the address the
// bitmapist Fly app exposes over the private network (for example
// codemojex-bitmapist.internal:6400).
type RedigoStore struct{ pool *redis.Pool }

// NewRedigoStore builds a small pooled store for addr (host:port).
func NewRedigoStore(addr string) *RedigoStore {
	return &RedigoStore{pool: &redis.Pool{
		MaxIdle:     4,
		MaxActive:   16,
		IdleTimeout: 4 * time.Minute,
		Wait:        true,
		Dial: func() (redis.Conn, error) {
			return redis.Dial("tcp", addr,
				redis.DialConnectTimeout(3*time.Second),
				redis.DialReadTimeout(3*time.Second),
				redis.DialWriteTimeout(3*time.Second),
			)
		},
	}}
}

// Close releases the pool.
func (s *RedigoStore) Close() error { return s.pool.Close() }

func (s *RedigoStore) SetBit(ctx context.Context, key string, off uint32, val int) error {
	c, err := s.pool.GetContext(ctx)
	if err != nil {
		return err
	}
	defer c.Close()
	_, err = c.Do("SETBIT", key, off, val)
	return err
}

func (s *RedigoStore) GetBit(ctx context.Context, key string, off uint32) (int, error) {
	c, err := s.pool.GetContext(ctx)
	if err != nil {
		return 0, err
	}
	defer c.Close()
	return redis.Int(c.Do("GETBIT", key, off))
}

func (s *RedigoStore) BitCount(ctx context.Context, key string) (int64, error) {
	c, err := s.pool.GetContext(ctx)
	if err != nil {
		return 0, err
	}
	defer c.Close()
	return redis.Int64(c.Do("BITCOUNT", key))
}

func (s *RedigoStore) BitOp(ctx context.Context, op, dest string, keys ...string) error {
	c, err := s.pool.GetContext(ctx)
	if err != nil {
		return err
	}
	defer c.Close()
	args := make([]interface{}, 0, len(keys)+2)
	args = append(args, op, dest)
	for _, k := range keys {
		args = append(args, k)
	}
	_, err = c.Do("BITOP", args...)
	return err
}

func (s *RedigoStore) Del(ctx context.Context, keys ...string) error {
	c, err := s.pool.GetContext(ctx)
	if err != nil {
		return err
	}
	defer c.Close()
	args := make([]interface{}, len(keys))
	for i, k := range keys {
		args[i] = k
	}
	_, err = c.Do("DEL", args...)
	return err
}

var _ BitStore = (*RedigoStore)(nil)
