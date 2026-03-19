export interface VaultInfo {
  root: string;
  note_count: number;
  types: VaultTypeInfo[];
}

export interface VaultTypeInfo {
  name: string;
  fields: [string, string][];
}

export interface NoteMetadata {
  id: string;
  title: string;
  type: string; // serde(rename = "type") from Rust
  parent: string | null;
  created: string | null;
  path: string;
  [extra: string]: unknown;
}
