# R7.06.2 · Radius and Box Queries

> Dive 2 of the Geospatial module — `/redis-patterns/data-modeling/geospatial/radius-and-box-queries`

## Summary

`GEOSEARCH` answers "what is near here?" in two shapes: a **circle** (`BYRADIUS`) or a **rectangle** (`BYBOX`). The
circle covers an area within a given radius; the box covers a width × height rectangle centred on the reference
point — useful for bounding-box delivery zones, map tiles, or rectangular regions. `GEOSEARCHSTORE` persists the
result as a Sorted Set for downstream processing. Because GEO members carry only a name, co-locate all metadata in
a separate Hash: search returns ids, then `HGETALL` fetches the row.

## BYRADIUS vs BYBOX

`GEOSEARCH` takes a **shape** argument: `BYRADIUS r unit` or `BYBOX w h unit`.

```
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km COUNT 10 ASC
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYBOX 100 80 km COUNT 10 ASC
```

`BYRADIUS` produces a circle of radius `r`; `BYBOX` produces a rectangle `w` units wide and `h` units tall, both
centred on the reference point. The same reference point with a radius of 50 km and a box of 100 km × 100 km will
return overlapping but **different** member sets — the circle clips the corners, the box extends into them.

Both accept `FROMMEMBER name` (use a stored member as the origin) or `FROMLONLAT lon lat` (explicit coordinates).

## GEOSEARCHSTORE — Persisting Results

`GEOSEARCHSTORE` runs the same spatial search and writes the result set to a **new Sorted Set key**, retaining
the geohash scores. This is useful for caching a "nearby restaurants" result for repeated reads, or for feeding
a second step in a pipeline.

```
GEOSEARCHSTORE nearby_cache locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km
```

The result at `nearby_cache` is a plain Sorted Set with geohash scores — because a GEO set IS a Sorted Set, the
output of `GEOSEARCHSTORE` can be consumed with `ZRANGE`/`ZCARD`/`ZREM` like any other Sorted Set.

## Location with Metadata — the Separate-Hash Pattern

GEO members carry only a name; there is no room in a Sorted Set score for additional fields. The pattern:

1. **Add a named id as the member:** `GEOADD restaurants -122.4194 37.7749 "restaurant:123"`
2. **Store all metadata in a Hash under that id:** `HSET restaurant:123 name "Joe's Diner" cuisine "American" rating "4.5"`
3. **Search returns ids; then fetch each:** `HGETALL restaurant:123`

The GEO set is the spatial index. The Hash is the record. They are joined by the member name.

## Real-Time Location Tracking

For tracking moving entities (drivers, delivery couriers), each GPS ping is a `GEOADD`:

```
GEOADD drivers -122.4 37.8 "driver:456"
HSET driver:456:status last_update 1706648400 available 1
GEOSEARCH drivers FROMLONLAT -122.4 37.8 BYRADIUS 5 km COUNT 20
```

`GEOADD` is idempotent on the member name — calling it again moves the driver's position. The timestamp and
availability live in a companion Hash; the application filters on those after fetching the nearby ids.

## Geofencing

Valkey has no built-in geofence events. Geofencing is implemented at the application layer:

1. Store the geofence definition (centre coordinates + radius, or a bounding box).
2. On each location update, check whether the entity is inside or outside each relevant fence using `GEOSEARCH`.
3. Compare the current membership state to the previous state.
4. On a state change (enter or exit), publish the event via Pub/Sub.

This is a poll-then-compare loop, not a reactive trigger — the application carries the state machine.

## References

### Sources

- [Valkey — GEOSEARCH](https://valkey.io/commands/geosearch/) — `BYRADIUS`, `BYBOX`, `FROMMEMBER`, `FROMLONLAT`, and output options.
- [Valkey — GEOSEARCHSTORE](https://valkey.io/commands/geosearchstore/) — persisting results as a Sorted Set.
- [Valkey — GEODIST](https://valkey.io/commands/geodist/) — distance between two members in m/km/mi/ft.
- [Valkey — GEOADD](https://valkey.io/commands/geoadd/) — adding or moving members by coordinate.

### Related in this course

- `/redis-patterns/data-modeling/geospatial` — the Geospatial hub
- `/redis-patterns/data-modeling/geospatial/the-geohash-sorted-set` — the structure reveal: why a GEO set IS a Sorted Set
- `/redis-patterns/data-modeling/vector-sets` — R7.05: another distance-based structure
- `/redis-patterns/data-modeling/bitmap-patterns` — R7.04: the modeling family
