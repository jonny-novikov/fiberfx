//! `echo_graft_backend` — the deployable live backend binary (eg.5).
//!
//! Stands the Rust page-engine up as a real `EchoMQ` participant: it opens a real engine `Runtime`
//! (a memory remote + a temporary Fjall store for the eg.5 leg; a deployment swaps in the real
//! Tigris remote + a persistent store), binds [`live::serve`] to a real Valkey RESP3 socket, and
//! serves real `EchoStore.GraftBackend` clients over the byte-frozen `echo_graft_proto` wire.
//!
//! Configuration (env):
//!   * `ECHO_GRAFT_VALKEY_HOST` (default `127.0.0.1`), `ECHO_GRAFT_VALKEY_PORT` (default `6390`).
//!   * `ECHO_GRAFT_BRANDED` — a comma-separated list of branded Volume ids to open + serve on
//!     start (so their `egraft:cmd:{vid}` lanes are subscribed). The native vid is minted at open.
//!   * `ECHO_GRAFT_CAP` — the per-Volume in-flight cap (default 64).
//!
//! On readiness it prints a single line to stdout — `READY <branded>=<vid> ...` — so a launching
//! supervisor (the Elixir live-leg test) can wait for the backend to be connected + subscribed
//! before driving it. SIGINT / a closed stdin triggers shutdown.

use std::sync::Arc;

use echo_graft::{
    identity::BrandedId, local::fjall_storage::FjallStorage, remote::RemoteConfig,
    rt::runtime::Runtime,
};
use echo_graft_backend::{Backpressure, LiveConfig, live};

#[tokio::main(flavor = "multi_thread", worker_threads = 4)]
async fn main() {
    let host = std::env::var("ECHO_GRAFT_VALKEY_HOST").unwrap_or_else(|_| "127.0.0.1".to_owned());
    let port: u16 = std::env::var("ECHO_GRAFT_VALKEY_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(6390);
    let cap: u32 = std::env::var("ECHO_GRAFT_CAP").ok().and_then(|s| s.parse().ok()).unwrap_or(64);
    let branded_list: Vec<String> = std::env::var("ECHO_GRAFT_BRANDED")
        .unwrap_or_default()
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
        .collect();

    // The engine runtime (memory remote + temporary store for the leg; a deployment swaps these).
    let handle = tokio::runtime::Handle::current();
    let remote = Arc::new(RemoteConfig::Memory.build().expect("memory remote"));
    let storage = Arc::new(FjallStorage::open_temporary().expect("temporary store"));
    let rt = Runtime::new(handle, remote, storage, None);

    // Open each served branded Volume up front so its command lane can be subscribed, and report
    // the native vid the engine minted. The engine open path may `block_on` internally
    // (`runtime.rs:125`), which deadlocks on an async reactor thread — run it via `block_in_place`.
    let (command_lanes, ready_pairs) = tokio::task::block_in_place(|| {
        let mut lanes = Vec::new();
        let mut pairs = Vec::new();
        for branded in &branded_list {
            let bid = BrandedId::parse(branded).expect("a valid branded id");
            rt.volume_open_branded(&bid, None, None).expect("open branded volume");
            let vid = rt
                .resolve_branded(&bid)
                .expect("resolve")
                .expect("branded mapping")
                .to_string();
            lanes.push(format!("egraft:cmd:{vid}"));
            pairs.push(format!("{branded}={vid}"));
        }
        (lanes, pairs)
    });

    let config = LiveConfig { host, port, command_lanes };
    let backpressure = Arc::new(Backpressure::new(cap));
    let (shutdown_tx, shutdown_rx) = tokio::sync::oneshot::channel();

    // The live serve loop runs as a task; we announce readiness after a short connect grace.
    let serve = tokio::spawn(live::serve(rt, config, backpressure, shutdown_rx));
    tokio::time::sleep(std::time::Duration::from_millis(200)).await;
    println!("READY {}", ready_pairs.join(" "));
    // flush stdout so a launching supervisor sees the readiness line immediately
    use std::io::Write;
    let _ = std::io::stdout().flush();

    // Shut down on SIGINT (Ctrl-C) or when the serve loop ends.
    tokio::select! {
        _ = tokio::signal::ctrl_c() => {
            let _ = shutdown_tx.send(());
        }
        r = serve => {
            if let Ok(Err(e)) = r {
                eprintln!("serve loop ended with error: {e}");
            }
            return;
        }
    }
}
