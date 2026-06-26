# R7.06.1 · GEOADD and GEOSEARCH

**Route:** `/redis-patterns/data-modeling/geospatial/geoadd-and-geosearch`  
**Parent module:** [R7.06 · Geospatial](/redis-patterns/data-modeling/geospatial)

`GEOADD`, `GEOSEARCH`, `GEOPOS`, `GEODIST` — the four commands that cover adding, retrieving, measuring, and
querying a geospatial index in Valkey. These are **core Valkey** commands; no module required.

## GEOADD — longitude first, then latitude

The classic gotcha: `GEOADD` takes **longitude before latitude**, following the GeoJSON convention rather than the
everyday latitude-longitude habit. Getting this wrong silently puts every point in the wrong hemisphere.

```
GEOADD locations -122.4194 37.7749 "san_francisco"   # lon, then lat
GEOADD locations  -73.9857 40.7484 "new_york"
GEOADD locations   -0.1276 51.5074 "london"
```

Multiple members in one call:

```
GEOADD locations -122.4194 37.7749 "san_francisco" -73.9857 40.7484 "new_york"
```

Returns the count of newly added members. Calling `GEOADD` on an existing member updates its position.

## GEOPOS — retrieve stored coordinates

`GEOPOS` returns the stored `[longitude, latitude]` for one or more members. Because coordinates are stored as
geohash integers, the returned values may differ from the inputs in the last few decimal places (geohash precision
is about ±0.6 m at the 52-bit level used by Valkey).

```
GEOPOS locations "san_francisco"
# → [[-122.41940081119537354, 37.77490011721691718]]
```

## GEODIST — distance between two members

`GEODIST` returns the distance between two stored members. Choose the unit that fits the use-case:

```
GEODIST locations "san_francisco" "new_york" km   # ~4129 km
GEODIST locations "san_francisco" "london"   mi   # ~5367 mi
```

Supported units: `m` (metres), `km` (kilometres), `mi` (miles), `ft` (feet).

## GEOSEARCH — radius and nearest-member queries

`GEOSEARCH` supersedes the deprecated `GEORADIUS` / `GEORADIUSBYMEMBER`. Two search origin forms:

- `FROMMEMBER name` — centre the search on a stored member
- `FROMLONLAT lon lat` — centre on arbitrary coordinates

Two shape forms:

- `BYRADIUS r unit` — circular search
- `BYBOX w h unit` — rectangular search (width × height centred on the origin)

Output options shape the result set:

```
GEOSEARCH locations FROMLONLAT -122.4 37.8 BYRADIUS 50 km WITHCOORD WITHDIST COUNT 10 ASC
```

- `WITHCOORD` — include `[lon, lat]` in each result
- `WITHDIST` — include distance from the origin
- `WITHHASH` — include the raw geohash integer
- `COUNT N` — stop after N results (combine with `ASC` to get the nearest N)
- `ASC` / `DESC` — sort by distance ascending or descending

## The lon-before-lat convention

Longitude before latitude is consistent with the GeoJSON specification (`[lon, lat]`). The confusion arises because
geographic coordinates in human contexts are written latitude-first ("37.7749°N, 122.4194°W"). Both `GEOADD` and
`FROMLONLAT` take longitude first. `GEOPOS` returns the same order.

## References

### Sources

- [Valkey — GEOADD](https://valkey.io/commands/geoadd/) — add coordinates; lon-before-lat argument order.
- [Valkey — GEOSEARCH](https://valkey.io/commands/geosearch/) — FROMMEMBER/FROMLONLAT, BYRADIUS/BYBOX, output options.
- [Valkey — GEODIST](https://valkey.io/commands/geodist/) — distance in m/km/mi/ft.
- [Valkey — GEOPOS](https://valkey.io/commands/geopos/) — retrieve stored coordinates.

### Related in this course

- [R7.06 · Geospatial — module hub](/redis-patterns/data-modeling/geospatial)
- [R7.05 · Vectors & similarity search](/redis-patterns/data-modeling/vector-sets)
- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns)
- [R4 · Time, delay & priority](/redis-patterns/time-delay-priority)
