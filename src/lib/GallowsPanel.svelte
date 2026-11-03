<script lang="ts">
  import HangmanCanvas from './HangmanCanvas.svelte';
  import { MAX_WRONG } from './gameRules';

  interface Props {
    wrongCount: number;
    wrongLetters: string[];
  }

  let { wrongCount, wrongLetters }: Props = $props();
</script>

<section class="left-panel">
  <HangmanCanvas {wrongCount} />

  <div class="lives">
    <span class="lives-label">Fehler</span>
    <span class="lives-count" class:danger={wrongCount >= MAX_WRONG - 1}>
      {wrongCount} / {MAX_WRONG}
    </span>
  </div>

  {#if wrongLetters.length > 0}
    <div class="wrong-letters">
      <span class="wrong-label">Falsch:</span>
      {#each wrongLetters as letter (letter)}
        <span class="wrong-chip">{letter}</span>
      {/each}
    </div>
  {/if}
</section>

<style>
  .left-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    flex-shrink: 0;
    padding: 24px 20px;
    border-radius: 24px;
    background: rgba(255, 255, 255, 0.6);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(236, 72, 153, 0.12);
    box-shadow: var(--shadow-soft);
  }

  .lives {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
  }

  .lives-label {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: var(--text);
  }

  .lives-count {
    font-size: 22px;
    font-weight: 700;
    color: var(--lavender-dark);
    font-variant-numeric: tabular-nums;
  }

  .lives-count.danger {
    color: var(--error);
  }

  .wrong-letters {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
    justify-content: center;
    max-width: 200px;
  }

  .wrong-label {
    font-size: 13px;
    color: var(--text);
  }

  .wrong-chip {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 26px;
    height: 26px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    color: var(--error);
    background: var(--error-bg);
  }
</style>
