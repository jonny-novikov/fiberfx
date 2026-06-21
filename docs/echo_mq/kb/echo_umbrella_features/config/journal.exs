import Config

# EchoMQ pluggable durability — choose the journal adapter per environment.
#
# Local development & tests: zero-infra SQLite (the shipped exqlite journal).
config :echo_mq, EchoMQ.Journal, adapter: EchoMQ.Journal.SQLite

# Bring-your-own-Postgres (the balanced split): the outbox intent rides the host's own
# Repo.transaction/1, atomic with the business row — but the bus, dequeue, retries, and
# history all stay on Valkey, so Postgres stays low-rate and mostly idle.
#
#     config :echo_mq, EchoMQ.Journal,
#       adapter: EchoMQ.Journal.Postgres,
#       repo: MyApp.Repo
#
# EchoMQ 4+ (no SQL): the commit-log-as-outbox on CubDB-backed Graft, replicated to
# object storage. A config change, not a rewrite, thanks to the shared adapter contract.
#
#     config :echo_mq, EchoMQ.Journal, adapter: EchoMQ.Journal.Graft
#
# Tests: in-memory.
#
#     config :echo_mq, EchoMQ.Journal, adapter: EchoMQ.Journal.Memory
