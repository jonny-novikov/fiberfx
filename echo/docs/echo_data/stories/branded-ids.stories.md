<!-- Authored acceptance criteria for echo_data. Back each scenario with an
     `EchoData.Story` test (same pattern as `Codemojex.Story`) to make it
     generated-and-proven, via `mix echo_data.stories`. -->

# Branded ids

> **Feature — acceptance criteria.** The identity layer: branded snowflake ids,
> `{ns}{base62}`, minted by `EchoData.BrandedId` over `EchoData.Snowflake`.

**5 scenarios.**

## Scenario: a minted id is a 3-letter namespace and an 11-character payload

- **Given** a namespace `"USR"`
- **When** `BrandedId.generate!("USR")` mints an id
- **Then** the id is 14 bytes, `namespace/1` returns `"USR"`, and `valid?/1` is true

## Scenario: an id carries its own mint time

- **Given** a freshly minted id
- **When** `BrandedId.unix_ms/1` reads it
- **Then** the timestamp is within a second of now — no lookup, the time is in the id

## Scenario: ids mint in strictly increasing order

- **Given** the running snowflake generator
- **When** two ids are minted back to back
- **Then** the second decodes to a larger snowflake than the first (`decode/1`), so ids sort by time

## Scenario: an id round-trips through decode and encode

- **Given** an id `id` and its parts `{ns, snow} = BrandedId.parse(id)`
- **When** it is rebuilt with `BrandedId.encode!(ns, snow)`
- **Then** the rebuilt id equals the original

## Scenario: the namespace gates a system

- **Given** a `USR` id and a code path that expects a `RND`
- **When** `Bcs.gate(usr_id, "RND")` is called
- **Then** it returns `:error` (and `gate!/2` raises), so a wrong-namespace id never enters the path
