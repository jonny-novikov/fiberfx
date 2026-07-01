use tauri::{WebviewUrl, WebviewWindowBuilder};

/// Injected before any page script runs — including the remote Phoenix-served
/// React app — so it can wrap `window.WebSocket` and tap every Phoenix Channel
/// frame, then render the developer panel over the page.
const DEVPANEL_SCRIPT: &str = include_str!("../../dev-panel/inject.js");

/// Receives the captured event log (JSON) from the panel and writes it to a
/// temp file, returning the path. Rust file writes are not gated by the fs
/// plugin permissions, so this needs no extra capability.
#[tauri::command]
fn export_events(events: String) -> Result<String, String> {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    let path = std::env::temp_dir().join(format!("codemoji-events-{ts}.json"));
    std::fs::write(&path, events).map_err(|e| e.to_string())?;
    Ok(path.to_string_lossy().into_owned())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        // Optional: a Rust-side WebSocket for a privileged/second connection
        // (e.g. an admin socket the page must not hold). Remove if unused.
        .plugin(tauri_plugin_websocket::init())
        .invoke_handler(tauri::generate_handler![export_events])
        .setup(|app| {
            // The Phoenix app to wrap. Override with PHX_APP_URL, e.g.
            //   PHX_APP_URL=https://portal.example.com
            let app_url = std::env::var("PHX_APP_URL")
                .unwrap_or_else(|_| "http://localhost:4000".to_string());
            let url = app_url
                .parse::<url::Url>()
                .expect("PHX_APP_URL must be a valid absolute URL");

            WebviewWindowBuilder::new(app, "main", WebviewUrl::External(url))
                .title("Codemoji — Dev Toolkit")
                .inner_size(1280.0, 840.0)
                .initialization_script(DEVPANEL_SCRIPT)
                .build()?;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
