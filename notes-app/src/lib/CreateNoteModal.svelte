<script lang="ts">
  import { onMount } from "svelte";
  import { appState } from "./state.svelte";

  interface Props {
    onClose: () => void;
    onCreate: (title: string, noteType: string) => void;
  }

  let { onClose, onCreate }: Props = $props();

  let title = $state("");
  let noteType = $state(appState.vaultTypes[0]?.name ?? "note");

  onMount(() => {
    if (appState.prefillTitle) {
      title = appState.prefillTitle;
      appState.prefillTitle = "";
    }
  });

  function onSubmit(e: Event) {
    e.preventDefault();
    if (!title.trim()) return;
    onCreate(title.trim(), noteType);
  }

  function onKeydown(e: KeyboardEvent) {
    if (e.key === "Escape") onClose();
  }

  function onBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) onClose();
  }
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="modal-backdrop" onclick={onBackdropClick} onkeydown={onKeydown}>
  <div class="modal">
    <h3>New Note</h3>
    <form onsubmit={onSubmit}>
      <div class="field">
        <label for="note-title">Title</label>
        <!-- svelte-ignore a11y_autofocus -->
        <input id="note-title" bind:value={title} placeholder="Note title" autofocus />
      </div>
      <div class="field">
        <label for="note-type">Type</label>
        <select id="note-type" bind:value={noteType}>
          {#each appState.vaultTypes as vt}
            <option value={vt.name}>{vt.name}</option>
          {/each}
        </select>
      </div>
      <div class="actions">
        <button type="button" onclick={onClose}>Cancel</button>
        <button type="submit" class="btn-primary" disabled={!title.trim()}>Create</button>
      </div>
    </form>
  </div>
</div>
