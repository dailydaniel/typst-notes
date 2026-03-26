<script lang="ts">
  let {
    onOpenVault,
    onCreateVault,
    recentVaults,
    onOpenRecent,
  }: {
    onOpenVault: () => void;
    onCreateVault: () => void;
    recentVaults: string[];
    onOpenRecent: (path: string) => void;
  } = $props();
</script>

<div class="welcome">
  <div class="welcome-inner">
    <img src="/typos-mark.svg" alt="typos" class="logo" />
    <h1>typos</h1>
    <p class="tagline">A note-taking system built on Typst</p>

    <div class="actions">
      <button class="welcome-btn" onclick={onOpenVault}>
        <span class="icon">&#9776;</span>
        Open existing vault
      </button>
      <button class="welcome-btn" onclick={onCreateVault}>
        <span class="icon">+</span>
        Create new vault
      </button>
    </div>

    {#if recentVaults.length > 0}
      <div class="recent">
        <h3>Recent</h3>
        {#each recentVaults as path}
          <button class="recent-item" onclick={() => onOpenRecent(path)}>
            {path.replace(/^\/Users\/[^/]+/, "~")}
          </button>
        {/each}
      </div>
    {/if}

    <span class="version">v0.2.3</span>
  </div>
</div>

<style>
  .welcome {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    grid-column: 1 / -1;
  }

  .welcome-inner {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    max-width: 340px;
    width: 100%;
  }

  .logo {
    width: 80px;
    height: 80px;
    margin-bottom: 4px;
    opacity: 0.85;
  }

  h1 {
    font-size: 28px;
    font-weight: 600;
    color: var(--text);
    letter-spacing: -0.5px;
  }

  .tagline {
    color: var(--text-secondary);
    font-size: 14px;
    margin-bottom: 20px;
  }

  .actions {
    display: flex;
    flex-direction: column;
    gap: 8px;
    width: 100%;
  }

  .welcome-btn {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
    padding: 12px 16px;
    font-size: 14px;
    text-align: left;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    color: var(--text);
    cursor: pointer;
    transition: background 0.15s, border-color 0.15s;
  }

  .welcome-btn:hover {
    background: var(--bg-secondary);
    border-color: var(--accent);
  }

  .welcome-btn .icon {
    font-size: 18px;
    width: 24px;
    text-align: center;
    color: var(--accent);
  }

  .recent {
    width: 100%;
    margin-top: 20px;
  }

  .recent h3 {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: var(--text-muted);
    margin-bottom: 6px;
  }

  .recent-item {
    display: block;
    width: 100%;
    padding: 8px 12px;
    font-size: 13px;
    font-family: var(--font-mono);
    text-align: left;
    color: var(--text-secondary);
    background: none;
    border: none;
    border-radius: var(--radius-sm);
    cursor: pointer;
    transition: background 0.15s, color 0.15s;
  }

  .recent-item:hover {
    background: var(--bg-secondary);
    color: var(--text);
  }

  .version {
    margin-top: 24px;
    font-size: 12px;
    color: var(--text-muted);
  }
</style>
