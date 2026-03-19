<script lang="ts">
  import { appState } from "./state.svelte";

  interface Props {
    onOpenNote: (id: string) => void;
    onOpenVaultTyp: () => void;
    onShowGraph: () => void;
  }

  let { onOpenNote, onOpenVaultTyp, onShowGraph }: Props = $props();

  let allOpen = $state(true);
  let starredOpen = $state(false);

  const sortedNotes = $derived(
    [...appState.notes].sort((a, b) => a.id.localeCompare(b.id))
  );

  const sortedStarred = $derived(
    [...appState.starredNotes].sort((a, b) => a.id.localeCompare(b.id))
  );
</script>

<div class="sidebar">
  <!-- Vault section -->
  <button
    class="section-btn vault-btn"
    class:active={appState.isVaultTyp}
    onclick={onOpenVaultTyp}
  >
    <span class="section-icon">V</span>
    vault.typ
  </button>

  <!-- All Notes accordion -->
  <button class="section-btn" onclick={() => (allOpen = !allOpen)}>
    <span class="chevron" class:open={allOpen}>&#9656;</span>
    All Notes
    <span class="badge">{appState.notes.length}</span>
  </button>
  {#if allOpen}
    <div class="note-list">
      {#each sortedNotes as note (note.id)}
        <button
          class="note-item"
          class:active={note.id === appState.currentNoteId}
          onclick={() => onOpenNote(note.id)}
        >
          <span class="note-id">{note.id}</span>
          <span class="note-type">{note.type}</span>
        </button>
      {:else}
        <div class="empty">No notes</div>
      {/each}
    </div>
  {/if}

  <!-- Starred accordion -->
  <button class="section-btn" onclick={() => (starredOpen = !starredOpen)}>
    <span class="chevron" class:open={starredOpen}>&#9656;</span>
    Starred
    {#if sortedStarred.length > 0}
      <span class="badge">{sortedStarred.length}</span>
    {/if}
  </button>
  {#if starredOpen}
    <div class="note-list">
      {#each sortedStarred as note (note.id)}
        <button
          class="note-item"
          class:active={note.id === appState.currentNoteId}
          onclick={() => onOpenNote(note.id)}
        >
          <span class="note-id">{note.id}</span>
          <span class="note-type">{note.type}</span>
        </button>
      {:else}
        <div class="empty">No starred notes</div>
      {/each}
    </div>
  {/if}

  <!-- Graph button -->
  <button class="section-btn" onclick={onShowGraph}>
    <span class="section-icon">G</span>
    Graph
  </button>
</div>

<style>
  .sidebar {
    border-right: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    overflow-y: auto;
    background: var(--bg-secondary);
  }
  .section-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    width: 100%;
    padding: 8px 12px;
    border: none;
    border-bottom: 1px solid var(--border);
    border-radius: 0;
    background: none;
    text-align: left;
    cursor: pointer;
    font-size: 12px;
    font-weight: 600;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.3px;
  }
  .section-btn:hover {
    background: rgba(0,0,0,0.04);
  }
  .section-btn.active {
    background: rgba(37, 99, 235, 0.08);
    color: var(--accent);
  }
  .vault-btn {
    text-transform: none;
    font-weight: 500;
    font-family: 'SF Mono', Menlo, Monaco, monospace;
    font-size: 13px;
  }
  .section-icon {
    width: 16px;
    text-align: center;
    font-weight: 700;
    font-size: 11px;
  }
  .chevron {
    display: inline-block;
    width: 12px;
    font-size: 10px;
    transition: transform 0.15s;
  }
  .chevron.open {
    transform: rotate(90deg);
  }
  .badge {
    margin-left: auto;
    font-size: 11px;
    font-weight: 400;
    color: var(--text-secondary);
    background: rgba(0,0,0,0.06);
    padding: 0 6px;
    border-radius: 8px;
  }
  .note-list {
    padding: 2px 4px;
    border-bottom: 1px solid var(--border);
  }
  .note-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 5px 10px;
    border: none;
    border-radius: var(--radius-sm);
    background: none;
    text-align: left;
    cursor: pointer;
    font-size: 13px;
    gap: 8px;
  }
  .note-item:hover {
    background: rgba(0,0,0,0.05);
  }
  .note-item.active {
    background: var(--accent);
    color: white;
  }
  .note-item.active .note-type {
    color: rgba(255,255,255,0.7);
  }
  .note-id {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    flex: 1;
    font-family: 'SF Mono', Menlo, Monaco, monospace;
    font-size: 12px;
  }
  .note-type {
    font-size: 11px;
    color: var(--text-secondary);
    flex-shrink: 0;
  }
  .empty {
    padding: 12px;
    text-align: center;
    color: var(--text-secondary);
    font-size: 12px;
  }
</style>
