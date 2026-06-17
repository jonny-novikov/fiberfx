# bcs_rung_shadow_check.exs -- gates SH1..SH4: the pluggable shadow.
#   MIX_ENV=prod mix run bcs_rung_shadow_check.exs        (no server, no creds)
alias EchoCache.Shadow
alias EchoCache.Shadow.Copy

defmodule SH do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end
end

work = Path.join(System.tmp_dir!(), "emq_shadow_#{System.unique_integer([:positive])}")
File.rm_rf!(work)
db = Path.join(work, "live/journal.db")
rep = Path.join(work, "replica")
File.mkdir_p!(Path.dirname(db))

IO.puts(
  "header: the journal's shadow made pluggable -- one behaviour (start_link, restore, status, stop; restore-if-missing by law) over two implementations: EchoCache.Litestream (the committed Appendix D path, object storage by sidecar) and EchoCache.Shadow.Copy (pure Elixir, VACUUM INTO snapshots to a directory; zero binaries, zero credentials, a development laptop included) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)}"
)

# SH1 -- the contract, both implementations
IO.puts("derive (contract): a behaviour is only real if its implementations export it -- both modules must carry the four callbacks at the contract's arities, and the dispatcher must route a tuple choice and answer :none without a process")
confs =
  for mod <- [EchoCache.Litestream, Copy] do
    Code.ensure_loaded!(mod)
    Enum.all?([{:start_link, 1}, {:restore, 1}, {:status, 1}, {:stop, 1}], fn {f, a} ->
      function_exported?(mod, f, a)
    end)
  end

{:ok, :no_replica} = Shadow.restore(:none)
:ignore = Shadow.start_link(:none)

sh1 =
  SH.line(
    "SH1 contract",
    Enum.all?(confs),
    "EchoCache.Litestream and EchoCache.Shadow.Copy both export start_link/1, restore/1, status/1, stop/1 under @behaviour EchoCache.Shadow; the dispatcher answered :none with {:ok, :no_replica} and started nothing -- one contract, the production path and the laptop path behind it"
  )

# SH2 -- the Copy cycle, live: write, snapshot, lose the box, restore, count
IO.puts("derive (copy cycle): VACUUM INTO writes a consistent snapshot from a live database, so the cycle must hold whole -- rows written, one forced sync, the live file deleted as the box loss, restore answering :restored, and the snapshot carrying every row; expect the snapshot file to exist after sync and the row count to survive exactly")
{:ok, conn} = Exqlite.Sqlite3.open(db)
:ok = Exqlite.Sqlite3.execute(conn, "CREATE TABLE intents (id TEXT PRIMARY KEY, body TEXT)")

for i <- 1..40 do
  :ok = Exqlite.Sqlite3.execute(conn, "INSERT INTO intents VALUES ('row#{i}', 'payload#{i}')")
end

:ok = Exqlite.Sqlite3.close(conn)

{:ok, sh} = Shadow.start_link({Copy, db: db, dir: rep, every_ms: 60_000})
:ok = Copy.sync(sh)
snap_exists = File.exists?(Copy.replica_path(db, rep))
%{syncs: syncs} = Copy.status(sh)

File.rm!(db)
{:ok, verdict} = Shadow.restore({Copy, db: db, dir: rep})
{:ok, conn2} = Exqlite.Sqlite3.open(db)
{:ok, stmt} = Exqlite.Sqlite3.prepare(conn2, "SELECT COUNT(*) FROM intents")
{:row, [count]} = Exqlite.Sqlite3.step(conn2, stmt)
:ok = Exqlite.Sqlite3.release(conn2, stmt)
:ok = Exqlite.Sqlite3.close(conn2)

sh2 =
  SH.line(
    "SH2 copy cycle",
    snap_exists and syncs == 1 and verdict == :restored and count == 40,
    "40 rows written, one forced sync (status counts #{syncs}), the live file deleted, restore through the dispatcher answered :#{verdict}, and the rebuilt journal counts #{count}/40 -- the Appendix D posture on a plain directory, no sidecar, no credentials"
  )

# SH3 -- restore-if-missing is the law, both directions
IO.puts("derive (the law): an existing live file is never overwritten -- restore over a present database must answer :no_replica and leave the file byte-identical; and a missing database with an empty replica directory must answer :no_replica rather than inventing a file")
before = File.read!(db)
{:ok, v_present} = Copy.restore(db: db, dir: rep)
untouched = File.read!(db) == before

empty_rep = Path.join(work, "empty_replica")
File.mkdir_p!(empty_rep)
ghost = Path.join(work, "ghost/journal.db")
{:ok, v_missing} = Copy.restore(db: ghost, dir: empty_rep)
no_invention = not File.exists?(ghost)

sh3 =
  SH.line(
    "SH3 the law",
    v_present == :no_replica and untouched and v_missing == :no_replica and no_invention,
    "restore over a live file answered :#{v_present} and left it byte-identical; restore with nothing behind it answered :#{v_missing} and wrote nothing -- restore-if-missing both directions, the same law the Litestream path carries with -if-replica-exists"
  )

# SH4 -- the snapshot keeps following the live file
IO.puts("derive (follow): the shadow is periodic, so a second sync after more writes must carry the new rows -- snapshot count moves 40 to 55, and the facade's layer underneath stays untouched: EchoWire delegates compile against the same connector this rung never needed")
{:ok, conn3} = Exqlite.Sqlite3.open(db)

for i <- 41..55 do
  :ok = Exqlite.Sqlite3.execute(conn3, "INSERT INTO intents VALUES ('row#{i}', 'payload#{i}')")
end

:ok = Exqlite.Sqlite3.close(conn3)
:ok = Copy.sync(sh)

{:ok, conn4} = Exqlite.Sqlite3.open(Copy.replica_path(db, rep))
{:ok, stmt4} = Exqlite.Sqlite3.prepare(conn4, "SELECT COUNT(*) FROM intents")
{:row, [count2]} = Exqlite.Sqlite3.step(conn4, stmt4)
:ok = Exqlite.Sqlite3.release(conn4, stmt4)
:ok = Exqlite.Sqlite3.close(conn4)
:ok = Copy.stop(sh)

Code.ensure_loaded!(EchoWire)
facade = function_exported?(EchoWire, :command, 3) and function_exported?(EchoWire, :eval, 5)

sh4 =
  SH.line(
    "SH4 follow",
    count2 == 55 and facade,
    "after 15 more rows and a second sync the snapshot counts #{count2}/55 -- the shadow follows the live file; and the EchoWire facade exports the wire layer's verbs over the unchanged connector, the extraction's front door in place"
  )

File.rm_rf!(work)
IO.puts("cleanup: the scratch tree under tmp removed whole")

if Enum.all?([sh1, sh2, sh3, sh4]) do
  IO.puts("PASS 4/4")
else
  IO.puts("FAIL")
  System.halt(1)
end
