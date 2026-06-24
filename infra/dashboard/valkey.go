// Native Valkey monitor: reads INFO, DBSIZE, CONFIG, CLIENT LIST, and SLOWLOG
// from echo-valkey over the 6PN and shapes them into JSON for the Svelte UI.
// Uses valkeycompat (a go-redis-compatible adapter over valkey-go), so the
// command method names mirror go-redis.
package main

import (
	"bufio"
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/valkey-io/valkey-go"
	"github.com/valkey-io/valkey-go/valkeycompat"
)

type valkeyMonitor struct {
	raw valkey.Client
	rdb valkeycompat.Cmdable
}

func newValkeyMonitor(addr string) (*valkeyMonitor, error) {
	c, err := valkey.NewClient(valkey.ClientOption{
		InitAddress:       []string{addr},
		ForceSingleClient: true, // a single Valkey node, not a cluster
		DisableCache:      true, // a monitor does not need client-side caching
	})
	if err != nil {
		return nil, err
	}
	return &valkeyMonitor{raw: c, rdb: valkeycompat.NewAdapter(c)}, nil
}

func (m *valkeyMonitor) Close() {
	if m.raw != nil {
		m.raw.Close()
	}
}

func (m *valkeyMonitor) Overview(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
	defer cancel()

	text, err := m.rdb.Info(ctx).Result()
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": err.Error()})
		return
	}
	in := parseInfo(text)
	dbsize, _ := m.rdb.DBSize(ctx).Result()
	mm, _ := m.rdb.ConfigGet(ctx, "maxmemory").Result()

	c.JSON(http.StatusOK, gin.H{
		"server":  pick(in["server"], "valkey_version", "redis_version", "redis_mode", "uptime_in_seconds"),
		"clients": pick(in["clients"], "connected_clients", "blocked_clients", "maxclients"),
		"memory": merge(
			pick(in["memory"], "used_memory", "used_memory_human", "used_memory_rss", "mem_fragmentation_ratio"),
			gin.H{"maxmemory": mm["maxmemory"]},
		),
		"stats": pick(in["stats"],
			"instantaneous_ops_per_sec", "total_commands_processed",
			"keyspace_hits", "keyspace_misses", "total_connections_received"),
		"persistence": pick(in["persistence"],
			"aof_enabled", "rdb_changes_since_last_save", "rdb_last_save_time", "rdb_last_bgsave_status"),
		"keyspace": in["keyspace"],
		"dbsize":   dbsize,
	})
}

func (m *valkeyMonitor) Clients(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
	defer cancel()
	out, err := m.rdb.Do(ctx, "CLIENT", "LIST").Text()
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": err.Error()})
		return
	}
	clients := []map[string]string{}
	for _, line := range strings.Split(strings.TrimSpace(out), "\n") {
		if line = strings.TrimSpace(line); line == "" {
			continue
		}
		f := map[string]string{}
		for _, kv := range strings.Fields(line) {
			if i := strings.IndexByte(kv, '='); i >= 0 {
				f[kv[:i]] = kv[i+1:]
			}
		}
		clients = append(clients, f)
	}
	c.JSON(http.StatusOK, gin.H{"count": len(clients), "clients": clients})
}

func (m *valkeyMonitor) Slowlog(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
	defer cancel()
	rows, err := m.rdb.Do(ctx, "SLOWLOG", "GET", "25").Slice()
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": err.Error()})
		return
	}
	type entry struct {
		ID      int64    `json:"id"`
		At      int64    `json:"at"`
		Micros  int64    `json:"micros"`
		Command []string `json:"command"`
		Client  string   `json:"client"`
	}
	out := []entry{}
	for _, r := range rows {
		row, ok := r.([]interface{})
		if !ok || len(row) < 4 {
			continue
		}
		e := entry{ID: toInt(row[0]), At: toInt(row[1]), Micros: toInt(row[2])}
		if cmd, ok := row[3].([]interface{}); ok {
			for _, a := range cmd {
				e.Command = append(e.Command, toStr(a))
			}
		}
		if len(row) > 4 {
			e.Client = toStr(row[4])
		}
		out = append(out, e)
	}
	c.JSON(http.StatusOK, gin.H{"count": len(out), "entries": out})
}

// --- helpers ---------------------------------------------------------------

func parseInfo(s string) map[string]map[string]string {
	out := map[string]map[string]string{"default": {}}
	cur := "default"
	sc := bufio.NewScanner(strings.NewReader(s))
	sc.Buffer(make([]byte, 1024*64), 1024*256)
	for sc.Scan() {
		line := strings.TrimRight(sc.Text(), "\r")
		if line == "" {
			continue
		}
		if strings.HasPrefix(line, "#") {
			cur = strings.ToLower(strings.TrimSpace(line[1:]))
			out[cur] = map[string]string{}
			continue
		}
		if i := strings.IndexByte(line, ':'); i > 0 {
			out[cur][line[:i]] = line[i+1:]
		}
	}
	return out
}

func pick(m map[string]string, keys ...string) gin.H {
	h := gin.H{}
	for _, k := range keys {
		if v, ok := m[k]; ok {
			h[k] = v
		}
	}
	return h
}

func merge(h, extra gin.H) gin.H {
	for k, v := range extra {
		h[k] = v
	}
	return h
}

func toInt(v interface{}) int64 {
	switch t := v.(type) {
	case int64:
		return t
	case int:
		return int64(t)
	case string:
		n, _ := strconv.ParseInt(t, 10, 64)
		return n
	}
	return 0
}

func toStr(v interface{}) string {
	switch t := v.(type) {
	case string:
		return t
	case []byte:
		return string(t)
	}
	return fmt.Sprintf("%v", v)
}
