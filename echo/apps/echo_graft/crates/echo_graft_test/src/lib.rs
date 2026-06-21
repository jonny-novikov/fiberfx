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

    pub fn with_remote(remote: Arc<Remote>) -> GraftTestRuntime {
        let thread_builder = std::thread::Builder::new().name("graft-runtime".to_string());

        let tokio_rt = tokio::runtime::Builder::new_current_thread()
            .start_paused(true)
            .enable_all()
            .build()
            .unwrap();

        let storage = Arc::new(FjallStorage::open_temporary().unwrap());
        let runtime = Runtime::new(tokio_rt.handle().clone(), remote.clone(), storage, None);

        let shutdown_tx = Arc::new(Notify::const_new());
        let shutdown_rx = shutdown_tx.clone();

        let thread = thread_builder
            .spawn(move || tokio_rt.block_on(async { shutdown_rx.notified().await }))
            .expect("failed to spawn backend thread");

        GraftTestRuntime {
            thread,
            runtime,
            remote,
            shutdown_tx,
        }
    }

    /// Spawn a new runtime connected to the same remote as this runtime
    pub fn spawn_peer(&self) -> GraftTestRuntime {
        Self::with_remote(self.remote.clone())
    }

    /// The remote object store backing this runtime (shared with any peers
    /// spawned via [`Self::spawn_peer`]). Lets a test inspect what actually
    /// landed in object storage after a push.
    pub fn remote(&self) -> Arc<Remote> {
        self.remote.clone()
    }

    pub fn shutdown(self) -> std::thread::Result<()> {
        self.shutdown_tx.notify_one();
        self.thread.join()
    }
}
