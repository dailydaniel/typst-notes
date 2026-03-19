<script lang="ts">
  import { appState } from "./state.svelte";

  interface Props {
    onOpenVault: () => void;
    onNewNote: () => void;
    onSearch: () => void;
    onToggleActions: () => void;
  }

  let { onOpenVault, onNewNote, onSearch, onToggleActions }: Props = $props();
</script>

<div class="toolbar">
  <div class="toolbar-left">
    <button
      class="icon-btn"
      title="Toggle sidebar"
      onclick={() => (appState.sidebarOpen = !appState.sidebarOpen)}
    >≡</button>
    <button onclick={onOpenVault} title="Open Vault (⌘O)">Open</button>
    {#if appState.isVaultOpen}
      <button onclick={onNewNote} title="New Note (⌘N)">New</button>
      <button onclick={onSearch} title="Search (⌘K)">Search</button>
    {/if}
  </div>

  <div class="toolbar-center">
    {#if appState.currentNoteId}
      <span class="note-indicator">
        {appState.isVaultTyp ? "vault.typ" : appState.currentNoteId}
        {#if appState.isDirty}
          <span class="dirty-dot" title="Unsaved changes"></span>
        {/if}
      </span>
    {/if}
  </div>

  <div class="toolbar-right">
    {#if appState.currentNoteId && !appState.isVaultTyp}
      <button
        class="icon-btn"
        class:active={appState.previewOpen}
        onclick={() => (appState.previewOpen = !appState.previewOpen)}
        title={appState.previewOpen ? "Hide preview" : "Show preview"}
      >&#x25C9;</button>
    {/if}
    {#if appState.currentNoteId}
      <button class="icon-btn" onclick={onToggleActions} title="Actions">···</button>
    {/if}
  </div>
</div>

<style>
  .toolbar {
    height: var(--toolbar-h);
    padding: 0 12px;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    gap: 8px;
    flex-shrink: 0;
    user-select: none;
  }
  .toolbar-left {
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .toolbar-center {
    flex: 1;
    text-align: center;
  }
  .toolbar-right {
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .note-indicator {
    font-size: 13px;
    color: var(--text-secondary);
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .dirty-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: var(--danger);
    display: inline-block;
  }
  .icon-btn {
    font-size: 18px;
    padding: 4px 8px;
    line-height: 1;
    border: none;
    background: none;
  }
  .icon-btn:hover {
    background: var(--bg-secondary);
    border-radius: var(--radius-sm);
  }
  .icon-btn.active {
    color: var(--accent);
  }
</style>
