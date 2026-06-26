# R7.06 · Geospatial

**Route:** `/redis-patterns/data-modeling/geospatial`  
**Pattern slug:** `geospatial`  
**Author source:** `docs/redis-patterns/content/community/geospatial.md.txt`

Store locations and query by radius, distance, or bounding box using GEOADD, GEOSEARCH, and GEODIST commands built on geohash-encoded Sorted Sets.

Redis natively supports geospatial indexes using the GEO* command family. Coordinates are stored as geohashes in a Sorted Set, enabling efficient spatial queries for "find nearby" features.

## Adding Locations

Store locations with their coordinates — longitude first, then latitude. The longitude-before-latitude order is the classic GEO gotcha; it follows the GeoJSON convention, not the everyday latitude-first habit.

```
GEOADD locations -122.4194 37.7749 "san_francisco"
GEOADD locations -73.9857 40.7484 "new_york"
GEOADD locations -0.1276 51.5074 "london"
```

Multiple locations can be added in a single command. `GEOADD` returns the number of new members added.

## Retrieving Coordinates

Get the stored coordinates of a member with `GEOPOS`. Returns a nested array of `[longitude, latitude]`.

```
GEOPOS locations "san_francisco"
```

Get the geohash string representation with `GEOHASH`. Useful for debugging, visualization, and interoperability with other geospatial systems.

```
GEOHASH locations "san_francisco"
```

## Calculating Distance

Measure the distance between two members with `GEODIST`. Supported units: `m` (metres), `km` (kilometres), `mi` (miles), `ft` (feet).

```
GEODIST locations "san_francisco" "new_york" km
```

## Searching by Radius

Find all locations within a specified radius using `GEOSEARCH`. Search from a member or from explicit coordinates:

```
GEOSEARCH locations FROMMEMBER "san_francisco" BYRADIUS 500 km
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km
```

## Search Options

`GEOSEARCH` accepts output-shaping options:

```
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km WITHCOORD WITHDIST COUNT 10 ASC
```

- `WITHCOORD` — include coordinates in results
- `WITHDIST` — include distance from the search point
- `WITHHASH` — include the geohash integer
- `COUNT N` — limit results to N items
- `ASC` / `DESC` — sort by distance

## Searching by Bounding Box

Search within a rectangular area centred on a point:

```
GEOSEARCH locations FROMMEMBER "san_francisco" BYBOX 1000 1000 km
```

The box is specified as width × height.

## Storing Search Results

Save search results to a new key for further processing:

```
GEOSEARCHSTORE nearby_cache locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km
```

The results are stored as a Sorted Set with geohash scores.

## Location with Metadata

Since GEO commands use Sorted Sets, a member carries only a name. Store additional metadata in a separate Hash; search returns ids, then fetch the row:

```
GEOADD restaurants -122.4194 37.7749 "restaurant:123"
HSET restaurant:123 name "Joe's Diner" cuisine "American" rating "4.5"

GEOSEARCH restaurants FROMLONLAT -122.4 37.8 BYRADIUS 5 km
HGETALL restaurant:123
```

## Real-Time Location Tracking

Update a driver's position on each GPS ping, store a status Hash, then query nearby:

```
GEOADD drivers -122.4 37.8 "driver:456"
HSET driver:456:status last_update 1706648400 available 1
GEOSEARCH drivers FROMLONLAT -122.4 37.8 BYRADIUS 5 km COUNT 20
```

## Geofencing

Geofencing detects when entities enter or leave defined areas. Store fence definitions, check on each position update, compare current state to previous state, broadcast via Pub/Sub.

## Geohash

The geohash string encodes coordinates at a given precision. Longer strings = finer precision; the geohash is what is stored as the ZSET score (as a 52-bit integer).

## Removing Locations

Since GEO data is stored in a Sorted Set, remove a member with `ZREM`:

```
ZREM locations "san_francisco"
```

## The pattern applied — the ZSET-as-sortable-scalar family

`GEOADD` encodes `(longitude, latitude)` into a 52-bit interleaved geohash integer stored as the **ZSET score**. `GEOSEARCH` is a bounded range-scan over that score space. This is the same move the BCS branded id makes (pack creation time into a sortable 11-char Base62 integer so a ZSET sorts by birth) and the same move R4 makes (pack a job's fire-time into a ZSET score so `ZRANGEBYSCORE` sweeps due jobs). A geohash, a branded snowflake, and a delayed-job score are one idea: a structured value flattened to a sortable scalar so an ordered structure answers a structured query.

codemojex has no geospatial surface — it is a location-agnostic Telegram emoji-guessing game. Players guess emoji; nothing is placed in space. The GEO commands' natural home is a standalone store-locator or ride-share driver index, which is what the examples above show.

## References

### Sources

- [Valkey — GEOADD](https://valkey.io/commands/geoadd/) — add members with lon/lat coordinates.
- [Valkey — GEOSEARCH](https://valkey.io/commands/geosearch/) — radius and box queries; supersedes GEORADIUS.
- [Valkey — GEODIST](https://valkey.io/commands/geodist/) — distance between two members in m/km/mi/ft.
- [Valkey — GEOHASH](https://valkey.io/commands/geohash/) — the geohash string representation.

### Related in this course

- [R7.06.1 · GEOADD and GEOSEARCH](/redis-patterns/data-modeling/geospatial/geoadd-and-geosearch)
- [R7.05 · Vectors & similarity search](/redis-patterns/data-modeling/vector-sets)
- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns)
- [R7.01 · Redis as a primary database](/redis-patterns/data-modeling/primary-database)
- [R4 · Time, delay & priority](/redis-patterns/time-delay-priority)
