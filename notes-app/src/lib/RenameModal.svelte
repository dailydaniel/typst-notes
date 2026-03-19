<script lang="ts">
  import { onMount } from "svelte";

  interface Props {
    currentId: string;
    onClose: () => void;
    onRename: (newId: string) => void;
  }

  let { currentId, onClose, onRename }: Props = $props();

  let newId = $state("");

  onMount(() => {
    newId = currentId;
  });

  function onSubmit(e: Event) {
    e.preventDefault();
    const trimmed = newId.trim();
    if (!trimmed || trimmed === currentId) return;
    onRename(trimmed);
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
    <h3>Rename Note</h3>
    <form onsubmit={onSubmit}>
      <div class="field">
        <label for="new-id">New ID</label>
        <!-- svelte-ignore a11y_autofocus -->
        <input id="new-id" bind:value={newId} placeholder="new-note-id" autofocus />
      </div>
      <div class="actions">
        <button type="button" onclick={onClose}>Cancel</button>
        <button
          type="submit"
          class="btn-primary"
          disabled={!newId.trim() || newId.trim() === currentId}
        >Rename</button>
      </div>
    </form>
  </div>
</div>
