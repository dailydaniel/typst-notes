use crate::error::NotesError;
use crate::types::NoteMetadata;
use crate::vault::Vault;

impl Vault {
    /// Full-text search across note titles and content.
    pub fn search(&self, query: &str) -> Result<Vec<NoteMetadata>, NotesError> {
        todo!()
    }

    /// List notes, optionally filtered by type.
    pub fn list_notes(&self, note_type: Option<&str>) -> Result<Vec<NoteMetadata>, NotesError> {
        todo!()
    }

    /// Get notes that link TO the given note id.
    pub fn backlinks(&self, id: &str) -> Result<Vec<NoteMetadata>, NotesError> {
        todo!()
    }
}
