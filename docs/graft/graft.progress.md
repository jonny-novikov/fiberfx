[1;36m╔══════════════════════════════════════════════════════════════════════╗
║  echo_graft  ·  durability tier  ·  real-time epic tracker            ║
║  [0m[2mfrom-scratch Rust engine seeded from Graft · NO upstream compatibility[0m[1;36m  ║
╚══════════════════════════════════════════════════════════════════════╝[0m
[2m  rendered for the terminal — `cat docs/graft/graft.progress.md` · updated 2026-06-21[0m

[1;35m▌ ARCHITECTURE[0m  (Operator-ruled 2026-06-21 · D-1=A COEXIST · D-2 name=echo_graft_backend)
    [32m●[0m native-BEAM [1mEchoStore.Graft.*[0m   canonical default · pure Elixir · UNTOUCHED
    [32m●[0m Rust [1mecho_graft_backend[0m        raw-page / replica-recovery workloads (backend)
    [2mtwo functional-twin engines · one role, two bets · eg.6 shootout decides per-workload[0m

[1;35m▌ RUNGS[0m
  [32m✓ eg.1[0m  carve + workspace           [90mNORMAL [0m  [32m75 tests[0m · det 100/100     [32mSHIPPED[0m
  [32m✓ eg.2[0m  Tigris remote + fence       [90mNORMAL [0m  [32m87 tests[0m · live-Tigris ✓    [32mSHIPPED[0m
  [32m✓ eg.3[0m  branded-id + change-feed    [90mNORMAL+[0m  [32m98 tests[0m · det 100/100     [32mSHIPPED[0m
  [32m✓ eg.4[0m  echo_graft_backend + proto  [90mHIGH   [0m  [32m120 tests · BEAM 69/0 ✓[0m    [32mSHIPPED[0m
  [97m○ eg.5[0m  low-latency write tier      [90mNORMAL+[0m  [2mcarries UF-1 (wire cap) · UF-2 (not_found)[0m  [33mNEXT[0m
  [90m○ eg.6  ship + durability shootout  NORMAL   —                     PENDING[0m

[1;35m▌ eg.4 BUILD ORDER[0m  [2m(foundation first; reassess before the live-bus surface)[0m
  [32m✓ 1[0m echo_graft_proto + fixtures   [32m16 msgs · Rust 6 tests green · clippy clean[0m
  [32m✓ 2[0m dual-side conformance         [32mElixir EchoMQ.RESP ≡ Rust bytes · 2 tests green[0m
  [32m✓ 3[0m echo_graft_backend dispatch   [32m1:1 onto the real Runtime · observe→republish feed[0m
  [32m✓ 4[0m version handshake             [32mHello/Welcome/Incompatible · refuse = no Volume op (S-2)[0m
  [32m✓ 5[0m EchoStore.GraftBackend client [32mconnect/commit/read/sync + feed subscribe · live Valkey 6390[0m
  [32m✓ 6[0m reconnect + backpressure      [32mresubscribe-from-LSN · per-Volume isolation (cap→eg.5 UF-1)[0m
  [32m✓ 7[0m live-bus leg + determinism    [32mdual-side conformance · det 100/100 · live leg env-gated[0m

[1;35m▌ CROSS-CUTTING GATES[0m
  [32m✓[0m upstream parity     [32m✓[0m declared keys      [32m✓[0m byte-frozen wire [2m(proto proven 5+6)[0m
  [32m✓[0m determinism: pure   [32m✓[0m license retained   [90m○ shootout battery [2m(eg.6)[0m

[2mlegend:  [32m✓[2m shipped/done   [33m⚙[2m building   ○ pending          spec: docs/graft/specs/graft.4.md[0m
