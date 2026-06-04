ExUnit.start()

# F6.3 — DB-touching tests run in the Ecto sandbox (Portal.DataCase). Manual mode:
# each test checks out its own owner; the in-memory engine suite never touches the
# Repo, so it is unaffected.
Ecto.Adapters.SQL.Sandbox.mode(Portal.Repo, :manual)

# F6.4 — the umbrella runs every app's ExUnit suite in ONE shared BEAM node, and
# `Portal.Repo` is the same supervised process across all of them. The `:portal_web`
# ConnTests are Repo-free by invariant (F6.4-INV2: the web names only `Portal`, never
# `Ecto`/`Repo`), so they never check out a sandbox owner — yet F6.4 routes the
# Repo-backed `Catalog.fetch_course/1` enroll gate through the out-of-band
# `Portal.Engine` process, which therefore also holds no owner. Under the `:manual`
# mode this suite sets, that read raises `DBConnection.OwnershipError` and crashes the
# `:portal` app during the `:portal_web` phase. Switch the shared Repo to `:auto` once
# THIS suite finishes (the per-suite teardown hook), so any subsequent suite in the
# node — `:portal_web` — runs with a Repo unowned processes may use directly. The
# `:portal` suite itself keeps `:manual` for its own per-test rollback isolation; the
# flip lands only after its last test (`Portal.DataCase` owners are already torn down).
ExUnit.after_suite(fn _result ->
  Ecto.Adapters.SQL.Sandbox.mode(Portal.Repo, :auto)
end)
