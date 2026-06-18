<!-- Authored acceptance criteria for echo_data. Back each scenario with an
     `EchoData.Story` test to make it generated-and-proven. -->

# Property store

> **Feature — acceptance criteria.** `EchoData.Bcs.PropertyStore` — an ETS
> `:ordered_set` component column keyed by the branded id, so a key range is a
> chronological window with no secondary index.

**3 scenarios.**

## Scenario: a component reads back by id

- **Given** a started property store and an entity id
- **When** a value is written with `put/3`
- **Then** `get/2` returns that value

## Scenario: a key range is a chronological window

- **Given** several components written over time, each under a snowflake-ordered id
- **When** `window/3` is asked for the ids between a low and a high bound
- **Then** it returns exactly the components minted in that time span, in order — because the `:ordered_set` is keyed by the time-ordered snowflake

## Scenario: the newest entities come back first

- **Given** a column with many recorded entities (`record_entity/2`)
- **When** `page_desc/2` is asked for the newest `n`
- **Then** it returns the most recent `n` ids, descending — a recency page with no extra index
