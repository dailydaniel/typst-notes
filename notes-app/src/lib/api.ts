import { invoke } from "@tauri-apps/api/core";
import type { VaultInfo, VaultTypeInfo, NoteMetadata } from "./types";

// --- Vault management ---

export function openVault(path: string): Promise<VaultInfo> {
  return invoke("open_vault", { path });
}

export function initVault(path: string): Promise<VaultInfo> {
  return invoke("init_vault", { path });
}

export function getVaultTypes(): Promise<VaultTypeInfo[]> {
  return invoke("get_vault_types");
}

// --- Notes CRUD ---

export function listNotes(noteType?: string): Promise<NoteMetadata[]> {
  return invoke("list_notes", { noteType: noteType ?? null });
}

export function createNote(title: string, noteType: string): Promise<NoteMetadata> {
  return invoke("create_note", { title, noteType });
}

export function deleteNote(id: string): Promise<void> {
  return invoke("delete_note", { id });
}

export function renameNote(oldId: string, newId: string): Promise<string[]> {
  return invoke("rename_note", { oldId, newId });
}

// --- File read/write ---

export function readNote(id: string): Promise<string> {
  return invoke("read_note", { id });
}

export function saveNote(id: string, content: string): Promise<void> {
  return invoke("save_note", { id, content });
}

// --- Compile ---

export function compileNote(id: string, format: string = "html"): Promise<string> {
  return invoke("compile_note", { id, format });
}

export function compileNotePdf(id: string, output: string, showMeta: boolean = true): Promise<string> {
  return invoke("compile_note_pdf", { id, output, showMeta });
}

// --- Search & navigation ---

export function searchNotes(query: string): Promise<NoteMetadata[]> {
  return invoke("search_notes", { query });
}

export function getBacklinks(id: string): Promise<NoteMetadata[]> {
  return invoke("get_backlinks", { id });
}

// --- Graph ---

export function getGraph(): Promise<unknown> {
  return invoke("get_graph");
}

// --- Index management ---

export function reindex(): Promise<number> {
  return invoke("reindex");
}

export function syncVault(): Promise<[number, number]> {
  return invoke("sync_vault");
}
