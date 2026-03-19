#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod state;

use state::AppState;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .manage(AppState::new())
        .invoke_handler(tauri::generate_handler![
            commands::open_vault,
            commands::init_vault,
            commands::get_vault_types,
            commands::list_notes,
            commands::create_note,
            commands::delete_note,
            commands::rename_note,
            commands::read_note,
            commands::save_note,
            commands::compile_note,
            commands::compile_note_pdf,
            commands::search_notes,
            commands::get_backlinks,
            commands::get_graph,
            commands::reindex,
            commands::sync_vault,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
