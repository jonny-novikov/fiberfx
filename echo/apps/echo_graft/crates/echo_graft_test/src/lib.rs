use std::{
    ops::{Deref, DerefMut},
    sync::{Arc, Once},
    thread::JoinHandle,
};

use echo_graft::{
    local::fjall_storage::FjallStorage,
    remote::{Remote, RemoteConfig},
    rt::runtime::Runtime,
};
use echo_graft_tracing::{SubscriberInitExt, TracingConsumer, setup_tracing_with_writer};
use precept::dispatch::test::TestDispatch;
use tokio::sync::Notify;
use tracing_subscriber::fmt::TestWriter;

/// This function should be run at the start of all integration tests in ./tests/*.
/// Faults may be re-enabled via precept APIs if needed.
pub fn ensure_test_env() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        setup_tracing_with_writer(TracingConsumer::Test, TestWriter::default(), None).init();
        precept::init(&TestDispatch).expect("failed to setup precept");
        precept::fault::disable_all();
        echo_graft::fault::set_crash_mode(true);
    });
}

pub struct GraftTestRuntime {
    thread: JoinHandle<()>,
    runtime: Runtime,
    remote: Arc<Remote>,
    handle: tokio::runtime::Handle,
    live: bool,
    shutdown_tx: Arc<tokio::sync::Notify>,
}

impl Deref for GraftTestRuntime {
    type Target = Runtime;

    fn deref(&self) -> &Self::Target {
        &self.runtime
    }
}

impl DerefMut for GraftTestRuntime {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.runtime
    }
}

impl GraftTestRuntime {
    pub fn with_memory_remote() -> GraftTestRuntime {
        let remote = Arc::new(RemoteConfig::Memory.build().unwrap());
        Self::with_remote(remote)
    }

    /// The deterministic in-process harness: a current-thread tokio runtime with
    /// a **paused** clock, for the Memory/Fs backends.
    pub fn with_remote(remote: Arc<Remote>) -> GraftTestRuntime {
        Self::build(remote, true)
    }

    /// A harness for a **live network backend** (e.g. Tigris over S3). Uses a
    /// real (unpaused) clock — under `start_paused` tokio auto-advances time
    /// when the runtime goes idle awaiting the network, which fires reqwest's
    /// connect/retry timeouts instantly and makes every call appear to time out.
    pub fn with_live_remote(remote: Arc<Remote>) -> GraftTestRuntime {
        Self::build(remote, false)
    }

    /// Build a harness backed by a live S3-compatible remote (Tigris/MinIO),
    /// reading `ECHO_GRAFT_TEST_S3_BUCKET` (+ the standard `AWS_ENDPOINT_URL` /
    /// `AWS_*` env). Returns `None` when unconfigured so a test can skip cleanly.
    /// `tag` namespaces the object prefix (`echo-graft-eg2-sync/{pid}/{tag}`) so
    /// concurrent tests and re-runs are isolated and easy to clean up.
    pub fn live_s3(tag: &str) -> Option<GraftTestRuntime> {
        let bucket = std::env::var("ECHO_GRAFT_TEST_S3_BUCKET").ok()?;
        let prefix = format!("echo-graft-eg2-sync/{}/{}", std::process::id(), tag);
        let remote = RemoteConfig::S3Compatible { bucket, prefix: Some(prefix) }
            .build()
            .expect("build s3 remote");
        Some(Self::with_live_remote(Arc::new(remote)))
    }

    fn build(remote: Arc<Remote>, paused: bool) -> GraftTestRuntime {
        let thread_builder = std::thread::Builder::new().name("graft-runtime".to_string());

        let mut rt_builder = tokio::runtime::Builder::new_current_thread();
        rt_builder.enable_all();
        if paused {
            rt_builder.start_paused(true);
        }
        let tokio_rt = rt_builder.build().unwrap();
        let handle = tokio_rt.handle().clone();

        let storage = Arc::new(FjallStorage::open_temporary().unwrap());
        let runtime = Runtime::new(handle.clone(), remote.clone(), storage, None);

        let shutdown_tx = Arc::new(Notify::const_new());
        let shutdown_rx = shutdown_tx.clone();

        let thread = thread_builder
            .spawn(move || tokio_rt.block_on(async { shutdown_rx.notified().await }))
            .expect("failed to spawn backend thread");

        GraftTestRuntime {
            thread,
            runtime,
            remote,
            handle,
            live: !paused,
            shutdown_tx,
        }
    }

    /// Spawn a new runtime connected to the same remote as this runtime. The peer
    /// matches this harness's liveness (a live harness spawns a live peer).
    pub fn spawn_peer(&self) -> GraftTestRuntime {
        Self::build(self.remote.clone(), !self.live)
    }

    /// The remote object store backing this runtime (shared with any peers
    /// spawned via [`Self::spawn_peer`]). Lets a test inspect what actually
    /// landed in object storage after a push.
    pub fn remote(&self) -> Arc<Remote> {
        self.remote.clone()
    }

    /// Drive a remote async op to completion on **this harness's** tokio runtime,
    /// so a live backend's connection pool / DNS resolver — initialized on this
    /// runtime during a push — are reused for the inspection. Used by tests to
    /// assert what landed in object storage.
    pub fn on_remote<F: Future>(&self, fut: F) -> F::Output {
        self.handle.block_on(fut)
    }

    pub fn shutdown(self) -> std::thread::Result<()> {
        self.shutdown_tx.notify_one();
        self.thread.join()
    }
}
