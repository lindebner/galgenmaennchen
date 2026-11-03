<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    tone: 'win' | 'lose';
    title: string;
    nextLabel: string;
    detail: Snippet;
    onnext: () => void;
  }

  let { tone, title, nextLabel, detail, onnext }: Props = $props();
</script>

<div class="result-banner" class:win={tone === 'win'} class:lose={tone === 'lose'}>
  <span class="result-title">{title}</span>
  <span class="result-detail">{@render detail()}</span>
  <button class="play-again" onclick={onnext}>{nextLabel}</button>
  <span class="kbd-hint">oder Enter drücken</span>
</div>

<style>
  .result-banner {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    padding: 24px 32px;
    border-radius: 20px;
    animation: fade-in 0.35s ease-out;
  }

  .result-banner.win {
    background: var(--success-bg);
    border: 1px solid var(--success-border);
  }

  .result-banner.lose {
    background: var(--error-bg);
    border: 1px solid var(--error-border);
  }

  .result-title {
    font-size: 26px;
    font-weight: 700;
  }

  .result-banner.win .result-title {
    color: var(--success);
  }

  .result-banner.lose .result-title {
    color: var(--error);
  }

  .result-detail {
    font-size: 14px;
    color: var(--text-h);
  }

  .result-detail :global(strong) {
    color: var(--text-h);
  }

  .play-again {
    margin-top: 10px;
    padding: 12px 32px;
    border-radius: 14px;
    border: none;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    background: var(--pink-dark);
    color: #fff;
    transition: transform 0.15s, box-shadow 0.2s;
    box-shadow: var(--shadow-soft);
  }

  .play-again:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow);
  }

  .play-again:active {
    transform: translateY(0);
  }

  .kbd-hint {
    font-size: 12px;
    color: var(--text-h);
  }

  @keyframes fade-in {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
  }
</style>
