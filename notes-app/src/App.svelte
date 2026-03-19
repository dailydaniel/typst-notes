<script lang="ts">
  import { invoke } from "@tauri-apps/api/core";

  let vaultPath = $state("");
  let notes: any[] = $state([]);
  let status = $state("No vault opened");

  async function openVault() {
    const { open } = await import("@tauri-apps/plugin-dialog");
    const selected = await open({ directory: true });
    if (selected) {
      try {
        const info: any = await invoke("open_vault", { path: selected });
        vaultPath = info.root;
        status = `Vault: ${info.root} (${info.note_count} notes)`;
        notes = await invoke("list_notes", { noteType: null });
      } catch (e) {
        status = `Error: ${e}`;
      }
    }
  }
</script>

<main>
  <div class="toolbar">
    <button onclick={openVault}>Open Vault</button>
    <span class="status">{status}</span>
  </div>

  <div class="content">
    <div class="sidebar">
      <h3>Notes</h3>
      {#each notes as note}
        <div class="note-item">{note.title} ({note.note_type})</div>
      {/each}
    </div>
    <div class="editor">
      <p>Select a note to edit</p>
    </div>
  </div>
</main>

<style>
  main {
    height: 100vh;
    display: flex;
    flex-direction: column;
    font-family: system-ui, sans-serif;
  }
  .toolbar {
    padding: 8px 16px;
    border-bottom: 1px solid #ddd;
    display: flex;
    align-items: center;
    gap: 16px;
  }
  .status {
    color: #666;
    font-size: 0.9em;
  }
  .content {
    display: flex;
    flex: 1;
    overflow: hidden;
  }
  .sidebar {
    width: 250px;
    border-right: 1px solid #ddd;
    padding: 8px;
    overflow-y: auto;
  }
  .editor {
    flex: 1;
    padding: 16px;
  }
  .note-item {
    padding: 4px 8px;
    cursor: pointer;
    border-radius: 4px;
  }
  .note-item:hover {
    background: #f0f0f0;
  }
</style>
