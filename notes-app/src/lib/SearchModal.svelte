<script lang="ts">
  import { onMount } from "svelte";
  import { appState } from "./state.svelte";
  import * as api from "./api";
  import type { NoteMetadata } from "./types";

  interface Props {
    onClose: () => void;
    onOpenNote: (id: string) => void;
    onCreateNote: (title: string) => void;
  }

  let { onClose, onOpenNote, onCreateNote }: Props = $props();

  let query = $state("");
  let contentResults = $state<NoteMetadata[]>([]);
  let selectedIndex = $state(0);
  let debounceTimer: ReturnType<typeof setTimeout>;
  let inputEl: HTMLInputElement;

  const titleResults = $derived(
    query.trim()
      ? appState.notes.filter((n) =>
          n.id.toLowerCase().includes(query.toLowerCase()) ||
          n.title.toLowerCase().includes(query.toLowerCase())
        )
      : []
  );

  const allResults = $derived(() => {
    const titleIds = new Set(titleResults.map((n) => n.id));
    const filtered = contentResults.filter((n) => !titleIds.has(n.id));
    return [...titleResults, ...filtered];
  });

  const results = $derived(allResults());

  function onInput() {
    selectedIndex = 0;
    clearTimeout(debounceTimer);
    if (query.trim().length >= 2) {
      debounceTimer = setTimeout(async () => {
        try {
          contentResults = await api.searchNotes(query.trim());
        } catch {
          contentResults = [];
        }
      }, 200);
    } else {
      contentResults = [];
    }
  }

  function onKeydown(e: KeyboardEvent) {
    if (e.key === "Escape") {
      onClose();
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      selectedIndex = Math.min(selectedIndex + 1, results.length);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      selectedIndex = Math.max(selectedIndex - 1, 0);
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (selectedIndex < results.length) {
        onOpenNote(results[selectedIndex].id);
      } else if (query.trim()) {
        onCreateNote(query.trim());
      }
    }
  }

  function onBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) onClose();
  }

  onMount(() => {
    inputEl?.focus();
    return () => clearTimeout(debounceTimer);
  });
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="modal-backdrop" onclick={onBackdropClick}>
  <div class="search-modal">
    <input
      bind:this={inputEl}
      bind:value={query}
      oninput={onInput}
      onkeydown={onKeydown}
      placeholder="Search notes…"
      type="text"
    />

    <div class="results">
      {#each results as note, i (note.id)}
        <button
          class="result-item"
          class:selected={i === selectedIndex}
          onclick={() => onOpenNote(note.id)}
          onmouseenter={() => (selectedIndex = i)}
        >
          <span class="result-title">{note.title}</span>
          <span class="result-id">{note.id}</span>
        </button>
      {/each}

      {#if query.trim() && results.length === 0}
        <button
          class="result-item create"
          class:selected={selectedIndex === results.length}
          onclick={() => onCreateNote(query.trim())}
        >
          Create "{query.trim()}"
        </button>
      {:else if query.trim()}
        <button
          class="result-item create"
          class:selected={selectedIndex === results.length}
          onclick={() => onCreateNote(query.trim())}
        >
          Create "{query.trim()}"
        </button>
      {/if}
    </div>
  </div>
</div>

<style>
  .search-modal {
    background: var(--bg);
    border-radius: var(--radius);
    width: 500px;
    max-height: 400px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  .search-modal input {
    border: none;
    border-bottom: 1px solid var(--border);
    border-radius: 0;
    padding: 12px 16px;
    font-size: 15px;
    outline: none;
  }
  .search-modal input:focus {
    box-shadow: none;
  }
  .results {
    overflow-y: auto;
    max-height: 340px;
  }
  .result-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 8px 16px;
    border: none;
    border-radius: 0;
    background: none;
    text-align: left;
    cursor: pointer;
    font-size: 13px;
    gap: 12px;
  }
  .result-item:hover,
  .result-item.selected {
    background: var(--bg-secondary);
  }
  .result-title {
    flex: 1;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .result-id {
    color: var(--text-secondary);
    font-size: 12px;
    flex-shrink: 0;
  }
  .result-item.create {
    color: var(--accent);
    font-style: italic;
  }
</style>
