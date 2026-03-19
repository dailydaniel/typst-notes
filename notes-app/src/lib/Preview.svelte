<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import { appState } from "./state.svelte";

  interface Props {
    onNavigate: (id: string) => void;
  }

  let { onNavigate }: Props = $props();

  // Inject a script into srcdoc that posts messages for link clicks
  const previewHtml = $derived(() => {
    if (!appState.previewHtml) return "";
    const script = `<script>
      document.addEventListener('click', function(e) {
        var a = e.target.closest('a');
        if (!a) return;
        e.preventDefault();
        var href = a.getAttribute('href') || '';
        window.parent.postMessage({ type: 'note-link', href: href }, '*');
      });
    <\/script>`;
    return appState.previewHtml + script;
  });

  function onMessage(e: MessageEvent) {
    if (e.data?.type !== "note-link") return;
    const href: string = e.data.href;
    let id = href
      .replace(/^\.\//, "")
      .replace(/^\//, "")
      .replace(/\.typ$/, "")
      .replace(/^notes\//, "")
      .replace(/--/g, "/");
    if (id) {
      onNavigate(id);
    }
  }

  onMount(() => {
    window.addEventListener("message", onMessage);
  });

  onDestroy(() => {
    window.removeEventListener("message", onMessage);
  });
</script>

<div class="preview">
  <div class="preview-header">
    <span class="preview-label">Preview</span>
    <button
      class="icon-btn"
      onclick={() => (appState.previewOpen = false)}
      title="Hide preview"
    >×</button>
  </div>
  <div class="preview-body">
    {#if appState.previewLoading}
      <div class="loading">Compiling…</div>
    {:else if appState.previewHtml}
      <iframe
        srcdoc={previewHtml()}
        title="Note preview"
        sandbox="allow-same-origin allow-scripts"
      ></iframe>
    {:else}
      <div class="empty">No preview available</div>
    {/if}
  </div>
</div>

<style>
  .preview {
    border-left: 1px solid var(--border);
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  .preview-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 4px 8px;
    border-bottom: 1px solid var(--border);
    flex-shrink: 0;
  }
  .preview-label {
    font-size: 12px;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .preview-body {
    flex: 1;
    overflow: hidden;
  }
  iframe {
    width: 100%;
    height: 100%;
    border: none;
  }
  .loading, .empty {
    padding: 24px;
    text-align: center;
    color: var(--text-secondary);
    font-size: 13px;
  }
  .icon-btn {
    font-size: 16px;
    padding: 2px 6px;
    border: none;
    background: none;
    color: var(--text-secondary);
    cursor: pointer;
    line-height: 1;
  }
  .icon-btn:hover {
    color: var(--text);
  }
</style>
