use crate::error::NotesError;
use crate::types::NoteMetadata;
use crate::vault::Vault;

impl Vault {
    /// Create a new note file and register it in CSV.
    pub fn new_note(
        &self,
        title: &str,
        note_type: &str,
        id: Option<&str>,
        parent: Option<&str>,
        tags: &[&str],
        extra_fields: &[(&str, &str)],
    ) -> Result<NoteMetadata, NotesError> {
        todo!()
    }

    /// Delete a note: remove file + CSV entry.
    pub fn delete_note(&self, id: &str) -> Result<(), NotesError> {
        todo!()
    }
}
