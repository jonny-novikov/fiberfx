# Claude Agent — echo_graft Kickoff Prompt

> Paste this as the agent brief (e.g. into `CLAUDE.md` or the Claude Code session opener) for the repo that will hold `echo_graft`. It assumes `graft.roadmap.md` and `graft.1.md`…`graft.6.md` are present in the repo.

---

You are an autonomous engineering agent building **echo_graft** — a hard fork of the Graft storage engine (`orbitinghail/graft`, dual MIT/Apache-2.0) re-seamed for the EchoMQ platform. You work **rung by rung** against the specs already in this repo. You do not improvise architecture; the specs are the contract.

## Read first (authoritative)

- `graft.roadmap.md` — rung map (`eg.1`–`eg.6`), architecture, the seven cross-cutting gates, glossary.
- `graft.1.md` … `graft.6.md` — per-rung specs. Each carries rationale, 5W+H, scope (in/out), specification, and **Given/When/Then acceptance criteria**.
- `graft.integration-surface.md` — the exact upstream API surface to wrap (relevant from `eg.4`; informs what `eg.1` must preserve).

Treat each rung's Given/When/Then list as its definition of done. Do not exceed a rung's declared scope.

## Mission (one paragraph)

Fork Graft's core, remove the SQLite extension, and rewrite three seams for this platform: a Tigris remote backend (via `object_store`), branded-Snowflake identity at the edge, and an EchoMQ change-feed driven off the commit LSN. The engine runs as a supervised Rust sidecar the BEAM drives over EchoMQ (RESP3); a versioned protocol crate keeps both sides in lockstep. Outcome: a durability tier that is transactional **and** replicated, benchmarked beside Champ and Oban.

## Ground truth about upstream Graft (verified — do not re-derive)

- Crate `graft` `0.2.1`, dual MIT/Apache-2.0. Public modules: `rt::runtime` (the Runtime entry point), `volume`, `volume_reader`, `volume_writer`, `snapshot`, `setup` (storage wiring), `local` (Fjall), `remote` (object_store), `oracle`, `core`, `err` (`GraftErr`/`LogicalErr`). Macros `lsn!`, `pageidx!`.
- Remote storage rides Apache **`object_store` 0.12** → Tigris is an `object_store` S3 configuration; the **conditional-write commit (the fence) is object_store's create-if-not-exists**, not hand-rolled SigV4.
- Local store is **Fjall** (LSM, `fjall`/`lsm-tree`). Async runtime is **Tokio**. Segment frames are **Zstd**. Page sets use **`splinter-rs`**. Wire/commit encoding is **`bilrost`**. Identifiers (GIDs) are **base58 (`bs58`)**.
- Recent upstream refactor: `graft-core` merged into `graft-kernel`, and clients connect directly to object storage (no middle-man services). Pin a specific upstream commit and record it in `README.md` (the former `FORK.md`); confirm the exact module path against the pinned source.

## Hard constraints (do not violate)

1. Integration is a **supervised Rust sidecar over EchoMQ (RESP3)** — **not** an in-VM NIF. (Alpha engine + Tokio blocking I/O.) An async-NIF hot-read path is out of scope until after `eg.6`.
2. Keep **Fjall** as the local store. Do not swap it.
3. Remote backend is **`object_store`** pointed at Tigris. Do not hand-roll SigV4.
4. Retain upstream **MIT/Apache-2.0 license headers** on every carried file.
5. **Declared keys** — enumerate every remote object key and every EchoMQ field a rung adds, in that rung's PR description.
6. **Byte-frozen wire** — once `echo_graft_proto` defines a message, its encoding is frozen; changes go through a protocol-version bump, never a silent edit.
7. Any in-VM path runs on a **dirty scheduler** or returns via message-back; it never parks a normal scheduler.
8. **Do not invent API signatures.** Confirm every upstream type and function against the pinned source or docs.rs before calling it. If a signature is unclear, read the source; do not guess.

## First task — `eg.1` (carve the fork)

Execute `graft.1.md` and nothing beyond it:

1. Vendor the `graft` runtime into `crates/echo_graft`; pin the upstream commit; create `README.md` (the former `FORK.md`) recording the commit hash, deleted files, and any build patch.
2. Remove the SQLite extension (the VFS + pragma crate) and every SQLite dependency it pulls.
3. Retain `local` (Fjall) and `remote` (object_store) with the Memory/FS backends for tests; do not add Tigris yet (`eg.2`).
4. Get `cargo build --workspace` and `cargo test --workspace` green; upstream's Volume/transaction tests must pass **unchanged**.
5. Satisfy every Given/When/Then in `graft.1.md`, including: disjoint-page concurrent commits both succeed; same-page concurrent commits → exactly one aborts with a conflict; carried files retain their license header.

Stop at the `eg.1` acceptance boundary and report before touching `eg.2`.

## Working loop (every rung)

1. Read the rung spec; restate its scope (in/out) and acceptance list back to yourself.
2. Implement the smallest change that satisfies the acceptance criteria — no more.
3. Add the declared keys and byte-frozen fixtures the spec requires.
4. Run the rung's tests **plus** the cross-cutting gates: upstream parity (never regress the `eg.1` baseline) and, for any new commit/mint/lease surface, a ≥100-iteration interleaving determinism loop.
5. Report (see below). Do not start the next rung until the current one's acceptance is fully green.

## Verification

- `cargo build --workspace` / `cargo test --workspace`.
- Upstream Volume suite green (the `eg.1` baseline; never regress it).
- Every Given/When/Then for the rung is green before advancing.
- **Network:** if `cargo` cannot reach crates.io through the egress proxy, run `cargo vendor`, commit the vendored crates, and build offline. Do **not** stub or mock the engine to get a green build.

## Report format (end of each rung)

- **Shipped:** what now exists, by crate/module.
- **Acceptance:** each Given/When/Then for the rung, marked pass/fail with the test that proves it.
- **Gates:** upstream parity, declared keys, byte-frozen wire, determinism loop — pass/fail.
- **Deviations:** anything you changed from the spec and why (one line each).
- **Next:** the entry conditions for the next rung and any decision you need from the maintainer.

## Do not

- Exceed a rung's scope, add the NIF path, swap Fjall, hand-roll SigV4, or alter the engine's transaction logic during `eg.1`.
- Reproduce large verbatim upstream prose in commit messages or docs — paraphrase.
- Mark a rung done with any acceptance criterion red.
