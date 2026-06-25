# codemojex-bitmapist

A Go port of Doist's bitmapist cohort model (`github.com/Doist/bitmapist4`),
rewritten from Python so the Codemojex Go stack — the dashboard and any marker —
speaks it directly, and made **branded-id-native**: every call takes a 14-char
branded id and resolves its bit offset through the in-repo branded codec.

## Packages

- `branded/` — a Go port of the branded Snowflake contract that the Echo
  umbrella ships as a Rust NIF (`apps/echo_data/native/branded_id.rs`) and a C
  ABI (`branded_id.h`). It carries the same algorithms and the same contract
  vectors, verified by `branded/branded_test.go`:
  - `Encode("USR", 274557032793636864) == "USR0KHTOWnGLuC"`
  - `Decode("USR0NgWEfAEJfs") == ("USR", 320636799581945856)`
  - `Hash32(274557032793636864) == 234878118`
  - `Offset("USR0KHTOWnGLuC") == 234878118`
  `Offset` is the bitmap offset: `Hash32(Decode(id))`.

- `bitmapist/` — the cohort client. Keeps bitmapist4 key conventions (the
  `bitmapist_` prefix and dated sibling keys) and exposes `Mark`, `MarkUnique`,
  `In`, `Count`, `AndCount`/`OrCount`/`XorCount`, and `RetentionRow`, all over a
  `BitStore` interface and all keyed by branded id. `RedigoStore` is the
  transport to bitmapist-server; `MemStore` backs the tests.

## Two properties of the offset to design around

`Hash32` is MurmurHash3's fmix64 first half truncated to 32 bits — a hash, so:

1. **One-way.** An offset does not reveal its branded id. Marking and membership
   work by branded id; listing a cohort's members as branded ids needs a
   separate offset-to-id index.
2. **Collision-bearing** in the 32-bit space. Distinct counts undercount by the
   collision rate, which is on the order of `N^2 / 2^33` colliding pairs at `N`
   users — negligible into the millions, but a property to state, not assume.

## Transport

bitmapist-server implements a subset of the Redis protocol on a minimal RESP
server and does not negotiate RESP3. `RedigoStore` uses redigo, a plain RESP
client that issues exactly the commands given, rather than a client that
mandates a `HELLO 3` handshake. Point it at `codemojex-bitmapist.internal:6400`.

## Example

```go
store := bitmapist.NewRedigoStore("codemojex-bitmapist.internal:6400")
defer store.Close()
bm := bitmapist.New(store)

// mark, by branded id, on a game event
_ = bm.Mark(ctx, "active", "USR0KHTOWnGLuC", time.Now())
_ = bm.Mark(ctx, "paid", "USR0KHTOWnGLuC", time.Now())

// monthly actives, and a registered -> played -> paid funnel
mau, _ := bm.Count(ctx, "active", time.Now(), bitmapist.Month)
reg := bm.Key("registered", t, bitmapist.Month)
played := bm.Key("played", t, bitmapist.Month)
paid := bm.Key("paid", t, bitmapist.Month)
converters, _ := bm.AndCount(ctx, reg, played, paid)
```

## Deploy

`deploy/` runs bitmapist-server as a separate minimal Fly app
(`Dockerfile` builds it from source; `fly.toml` is private 6PN, a volume for the
memory-mapped db, always-on). Build and deploy require Docker and network.

## Tests

```
go test ./...
```
