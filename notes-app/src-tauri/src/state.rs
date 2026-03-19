use notes_core::vault::Vault;
use std::sync::Mutex;

pub struct AppState {
    pub vault: Mutex<Option<Vault>>,
}

impl AppState {
    pub fn new() -> Self {
        Self {
            vault: Mutex::new(None),
        }
    }
}
