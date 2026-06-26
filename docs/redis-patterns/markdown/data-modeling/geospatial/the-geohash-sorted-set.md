# R7.06.3 · The Geohash Sorted Set

> Dive 3 of the Geospatial module — `/redis-patterns/data-modeling/geospatial/the-geohash-sorted-set`

## Summary

A GEO set is a Sorted Set. The source states it three times: "Coordinates are stored as geohashes in a Sorted Set"
(line 5), "The results are stored as a Sorted Set with geohash scores" (line 71), "Since GEO data is stored in a
Sorted Set, use `ZREM`" (line 125). `GEOADD` encodes (longitude, latitude) into a 52-bit interleaved geohash
integer stored as the ZSET score. `GEOSEARCH` is a bounded range-scan over that score space. This is the pattern's
payoff: one sorted scalar lets a standard ordered structure answer a two-dimensional spatial query.

## The Geohash Integer — a 52-bit Z-order Score

Longitude and latitude are each divided into binary intervals; the result bits are **interleaved** (lon bit, lat
bit, lon bit, lat bit…) into a single 52-bit integer — a Z-order curve, also called a Morton curve. The
interleaving has a critical spatial property: **points that are close in 2-D space tend to have numerically close
geohash integers**. This is not exact — the curve folds back on itself at region boundaries — but it is good enough
for bounded range queries over a Sorted Set.

`GEOADD` computes this integer and stores it as the member's ZSET score. `GEOSEARCH` translates the shape (radius
or box) into a range on that score axis and does a bounded scan. The GEO commands are sugar over that arithmetic.

## Exposed as ZSET Commands

Because a GEO set is a Sorted Set, the ZSET commands work on it directly:

```
GEOADD locations -122.4194 37.7749 "san_francisco"   # → ZADD with a geohash score
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km  # → bounded ZRANGEBYSCORE
GEOHASH locations "san_francisco"                    # the base32-encoded geohash string
ZREM locations "san_francisco"                       # remove a member — no GEOREM exists
```

`ZREM` is the deletion command; there is no `GEOREM`. `GEOHASH` exposes the base32-encoded string (the familiar
`9q8yy4s` form) — distinct from the raw integer score stored internally, but derived from the same bits. `WITHHASH`
in a `GEOSEARCH` returns the raw integer score.

## Precision vs Proximity

The geohash partitions the world into a grid of cells. The more bits used, the finer the cell. At 52 bits, the
precision is about 0.6 metres. But the interleaving means that two nearby points may span a cell boundary and land
in **numerically distant** geohash bins — a bounded scan must check a small set of neighbouring cells, which is
what `GEOSEARCH` handles automatically.

## The R4 Parallel — Packing a Structured Value into a Sortable Scalar

The geohash encodes **place** into a sortable integer so a Sorted Set answers a 2-D spatial query. The R4
time-delay-priority module encodes **time** into a ZSET score so `ZRANGEBYSCORE` sweeps due jobs. A branded
snowflake encodes **creation order** into a sortable id so a set of ids sorts by creation time. The idea is one:
pack a structured value into a scalar, then use an ordered structure to answer a structured query.

## References

### Sources

- [Valkey — GEOHASH](https://valkey.io/commands/geohash/) — the base32-encoded geohash string for a stored member.
- [Valkey — GEOSEARCH](https://valkey.io/commands/geosearch/) — bounded range-scan over the geohash score space.
- [Valkey — GEOADD](https://valkey.io/commands/geoadd/) — encodes (lon, lat) into a geohash score and stores it as a ZSET member.
- [Valkey — GEODIST](https://valkey.io/commands/geodist/) — distance between two members.

### Related in this course

- `/redis-patterns/data-modeling/geospatial` — the Geospatial hub
- `/redis-patterns/data-modeling/geospatial/radius-and-box-queries` — `BYRADIUS` vs `BYBOX`, `GEOSEARCHSTORE`, the metadata pattern
- `/redis-patterns/data-modeling/vector-sets` — R7.05: similarity over a vector neighbourhood vs proximity over a geohash score
- `/redis-patterns/time-delay-priority` — R4: time packed into a ZSET score — the same sortable-scalar family
