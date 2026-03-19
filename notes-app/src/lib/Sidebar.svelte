<script lang="ts">
  import { appState } from "./state.svelte";

  interface Props {
    onOpenNote: (id: string) => void;
    onOpenVaultTyp: () => void;
    onShowGraph: () => void;
    onTodayJournal: () => void;
  }

  let { onOpenNote, onOpenVaultTyp, onShowGraph, onTodayJournal }: Props = $props();

  let allOpen = $state(true);
  let starredOpen = $state(false);
  let journalOpen = $state(false);

  const sortedNotes = $derived(
    [...appState.notes].sort((a, b) => a.id.localeCompare(b.id))
  );

  const sortedStarred = $derived(
    [...appState.starredNotes].sort((a, b) => a.id.localeCompare(b.id))
  );

  const hasJournal = $derived(
    appState.vaultTypes.some((t) => t.name === "journal")
  );

  const journalNotes = $derived(
    [...appState.notes]
      .filter((n) => n.type === "journal")
      .sort((a, b) => ((b as any).date ?? "").localeCompare((a as any).date ?? ""))
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

  <!-- Journal section (only if vault has journal type) -->
  {#if hasJournal}
    <div class="section-row">
      <button class="section-btn journal-btn" onclick={() => (journalOpen = !journalOpen)}>
        <span class="chevron" class:open={journalOpen}>&#9656;</span>
        Journal
        {#if journalNotes.length > 0}
          <span class="badge">{journalNotes.length}</span>
        {/if}
      </button>
      <button
        class="today-btn"
        onclick={onTodayJournal}
        title="Open today's journal"
      >Today</button>
    </div>
    {#if journalOpen}
      <div class="note-list">
        {#each journalNotes as note (note.id)}
          <button
            class="note-item"
            class:active={note.id === appState.currentNoteId}
            onclick={() => onOpenNote(note.id)}
          >
            <span class="note-id">{note.title}</span>
            <span class="note-type">{(note as any).date ?? ""}</span>
          </button>
        {:else}
          <div class="empty">No journal entries</div>
        {/each}
      </div>
    {/if}
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
  .section-row {
    display: flex;
    align-items: center;
    border-bottom: 1px solid var(--border);
  }
  .section-row .section-btn {
    border-bottom: none;
  }
  .journal-btn {
    flex: 1;
  }
  .today-btn {
    flex-shrink: 0;
    margin-right: 8px;
    font-size: 10px;
    font-weight: 600;
    padding: 2px 8px;
    border: 1px solid var(--border);
    border-radius: var(--radius-sm);
    background: var(--bg);
    color: var(--accent);
    cursor: pointer;
    text-transform: none;
    letter-spacing: 0;
  }
  .today-btn:hover {
    background: var(--accent);
    color: white;
    border-color: var(--accent);
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
