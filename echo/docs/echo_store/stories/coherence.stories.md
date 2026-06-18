<!-- Authored acceptance criteria for echo_store. Back each scenario with an
     `EchoStore.Story` test (tagged :valkey) to make it generated-and-proven. -->

# Coherence

> **Feature — acceptance criteria.** `EchoStore.Coherence` — cross-node cache
> coherence over EchoMQ, ordered by the snowflake body of the version.

**3 scenarios.**

## Scenario: the newer version wins by snowflake body

- **Given** two versions of the same id, A minted after B
- **When** `newer?/2` compares them
- **Then** it returns true for A over B — comparing only the 11-byte payload, skipping the namespace bytes

## Scenario: a coherence notice round-trips

- **Given** an id and a version
- **When** the notice is encoded with `payload/2` and decoded with `parse/1`
- **Then** the decoded `{id, version}` equals the original

## Scenario: an invalidation drops L1 and signals peers

- **Given** a key cached in L1 on two nodes
- **When** one node calls `invalidate/3` (or broadcasts via `broadcast/4`)
- **Then** the local L1 entry is dropped and a coherence notice is published, so peers drop or refill on next read
