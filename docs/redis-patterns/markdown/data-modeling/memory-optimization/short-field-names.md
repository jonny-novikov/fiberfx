# R7.02.2 · short field names

> Route: `/redis-patterns/data-modeling/memory-optimization/short-field-names` · dive 2.

Names are stored too. A key's name is held on every key; a Hash field's name is held on every entry; and at a million rows, the names can outweigh the values. The technique is to keep names few and short — short enough to stay under `hash-max-listpack-value`, so the row stays in the compact listpack encoding. EchoMQ's `state`/`attempts`/`payload` is the applied example: three fields, short whole words, **not** abbreviated to noise.

## §1 · Every name is paid per row

A value of `25` is two bytes. The key `user:profile:12345:display_name` is 31 bytes — fifteen times the value, stored once per key. For a million such keys, the names dominate. Two moves cut it:

- **Shorten the name.** `user:profile:12345:display_name` → `u:12345:dn`. The same identity, a quarter of the bytes — paid a million times.
- **Move the repeated prefix into a Hash.** `HSET u:12345 dn "Alice" karma 42` stores `u:12345` **once** and the field names `dn`, `karma` once per row, instead of repeating the full `user:profile:12345:` prefix on every String key.

The second move is usually the larger win, because it both removes the repeated prefix and lands the fields in a single compact Hash.

## §2 · Short, but not cryptic — the trade

Names pull in two directions. Byte-tightness wants `dn`; readability wants `display_name`. The honest middle is the rule EchoMQ follows: pick names that are **short and whole** — small enough to keep the value under `hash-max-listpack-value 64`, but still a word a reader recognizes. A field name is not where the memory battle is won or lost; the encoding is. Abbreviating `state` to `st` saves three bytes per row and costs every future reader a lookup — a poor trade when three short words already keep the row a listpack.

## §3 · EchoMQ's deliberate three

The job HASH is named for reading, not for the byte counter:

```elixir
# EchoMQ.Jobs — the row, verbatim from the @enqueue script
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
```

`state`, `attempts`, `payload` — three fields, each a recognizable word, each short. There is **no** abbreviated schema behind them; the row is exactly these three. The brevity that matters is the **count** (three, far under 512) and the **value size** (each under 64 bytes), and those two facts are what keep Valkey storing the row as a listpack. The moduledoc puts the design plainly: *"Jobs are entities. A job's identity is a branded id under the `JOB` namespace; its row is a hash at the job key."* A small, well-named row is the memory win and the readable record at once.

The key name itself is built by `EchoMQ.Keyspace` — `emq:{q}:job:<JOB-branded-id>` — where the brace is the cluster hash tag, not padding; every byte of the name earns its place.

## The bridge — pattern → application

**Pattern.** Few, short field names keep a row's values under `hash-max-listpack-value` and the row in the compact encoding; the prefix lives once in the key, not once per field.

**EchoMQ application.** The job HASH is `state`/`attempts`/`payload` — short whole words, not abbreviations — so the values stay under 64 bytes and the row stays a listpack, while remaining a record a person can read.

**Take.** Short field names are a real memory technique, but the point is the encoding, not the abbreviation. EchoMQ keeps three short, readable fields and gets the compact listpack for free — readable record, small footprint, no cryptic schema.

## References

### Sources

- [Valkey — Memory optimization](https://valkey.io/topics/memory-optimization/) — key and field name overhead, and the listpack value-size threshold.
- [Valkey — HSET](https://valkey.io/commands/hset/) — fields on a Hash; the prefix is stored once in the key, the field names once per row.
- [Valkey — HGET](https://valkey.io/commands/hget/) — read one field; the Hash approach stores the key prefix once rather than per field.
- [DoorDash Engineering](https://careersatdoordash.com/blog/) — collapsing flat `feature:id:attr` String pairs into one Hash cut feature-store memory measurably.

### Related in this course

- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the module hub.
- [R7.02.1 · listpack-and-intset](/redis-patterns/data-modeling/memory-optimization/listpack-and-intset) — the encoding the threshold keeps.
- [R7.02.3 · capped-structures](/redis-patterns/data-modeling/memory-optimization/capped-structures) — bounding the structures that grow.
- [R7.01.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the same three-field job HASH as the record of truth.
