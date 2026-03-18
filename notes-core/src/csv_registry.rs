use crate::error::NotesError;
use std::path::Path;

/// Read all note paths from CSV (single column, no header).
pub fn read_note_paths(csv_path: &Path) -> Result<Vec<String>, NotesError> {
    todo!()
}

/// Append a path to CSV.
pub fn add_note_path(csv_path: &Path, note_path: &str) -> Result<(), NotesError> {
    todo!()
}

/// Remove a path from CSV.
pub fn remove_note_path(csv_path: &Path, note_path: &str) -> Result<(), NotesError> {
    todo!()
}
