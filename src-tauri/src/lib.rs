use tauri::Manager;

mod trial;

#[tauri::command]
fn check_trial() -> trial::TrialStatus {
    trial::check()
}

#[tauri::command]
fn activate_license(key: String) -> Result<String, String> {
    trial::activate(&key)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_process::init())
        .invoke_handler(tauri::generate_handler![check_trial, activate_license])
        .setup(|app| {
            // Check trial on startup
            let status = trial::check();
            if status.expired {
                // Emit event to frontend to show purchase screen
                if let Some(window) = app.get_webview_window("main") {
                    let _ = window.eval("window.__trialExpired = true;");
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running 4MA");
}
