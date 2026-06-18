<!-- Authored acceptance criteria for echo_store. Back each scenario with an
     `EchoStore.Story` test (tagged :valkey) to make it generated-and-proven. -->

# Cache-aside (L1 over L2)

> **Feature — acceptance criteria.** `EchoStore.Table` — an ETS L1 over a Valkey
> L2 with single-flight fills and versioned writes.

**3 scenarios.**

## Scenario: a miss fills from L2, then a hit is served from L1

- **Given** a started table and a key present only in the Valkey L2
- **When** `fetch/3` is called twice for that key
- **Then** the first read fills L1 from L2 and the second is served from L1 (the table's stats show one fill, one L1 hit)

## Scenario: concurrent misses share a single fill

- **Given** a key not in L1
- **When** many processes call `fetch/3` for it at once
- **Then** exactly one fill is issued to L2 and every caller receives the same value — the single-flight guarantee

## Scenario: a write carries a version

- **Given** a value and a 14-byte version
- **When** it is written with `put/4`
- **Then** the L2 frame is `<<version::binary-14, value::binary>>`, so a reader can compare versions without unpacking the value
