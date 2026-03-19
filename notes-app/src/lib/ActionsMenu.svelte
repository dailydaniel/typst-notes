<script lang="ts">
  import { onMount } from "svelte";
  import { appState } from "./state.svelte";

  interface Props {
    onClose: () => void;
    onSave: () => void;
    onDelete: () => void;
    onRename: () => void;
    onExportPdf: () => void;
    onTogglePreview: () => void;
  }

  let { onClose, onSave, onDelete, onRename, onExportPdf, onTogglePreview }: Props = $props();

  function action(fn: () => void) {
    return () => {
      fn();
      onClose();
    };
  }

  function onBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) onClose();
  }

  function onKeydown(e: KeyboardEvent) {
    if (e.key === "Escape") onClose();
  }

  onMount(() => {
    document.addEventListener("keydown", onKeydown);
    return () => document.removeEventListener("keydown", onKeydown);
  });
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="menu-backdrop" onclick={onBackdropClick}>
  <div class="menu">
    <button class="menu-item" onclick={action(onSave)}>
      Save <kbd>⌘S</kbd>
    </button>

    {#if appState.currentNoteId && !appState.isVaultTyp}
      <button class="menu-item" onclick={action(() => appState.toggleStar(appState.currentNoteId!))}>
        {appState.isStarred(appState.currentNoteId) ? "Unstar" : "Star"}
      </button>

      <button class="menu-item" onclick={action(onTogglePreview)}>
        {appState.previewOpen ? "Hide Preview" : "Show Preview"}
      </button>

      <hr />

      <button class="menu-item" onclick={action(onRename)}>
        Rename…
      </button>

      <button class="menu-item" onclick={action(onExportPdf)}>
        Export PDF
      </button>

      <hr />

      <button class="menu-item danger" onclick={action(onDelete)}>
        Delete
      </button>
    {/if}
  </div>
</div>

<style>
  .menu-backdrop {
    position: fixed;
    inset: 0;
    z-index: 50;
  }
  .menu {
    position: absolute;
    top: var(--toolbar-h);
    right: 12px;
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
    min-width: 180px;
    padding: 4px;
    z-index: 51;
  }
  .menu-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 6px 12px;
    border: none;
    border-radius: var(--radius-sm);
    background: none;
    text-align: left;
    cursor: pointer;
    font-size: 13px;
  }
  .menu-item:hover {
    background: var(--bg-secondary);
  }
  .menu-item.danger {
    color: var(--danger);
  }
  .menu-item.danger:hover {
    background: #fef2f2;
  }
  hr {
    border: none;
    border-top: 1px solid var(--border);
    margin: 4px 0;
  }
</style>
