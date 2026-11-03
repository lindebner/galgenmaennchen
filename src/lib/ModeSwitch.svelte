<script lang="ts">
  import type { GameMode } from './gameRules';

  interface Props {
    mode: GameMode;
    onchange: (mode: GameMode) => void;
  }

  let { mode, onchange }: Props = $props();

  const OPTIONS: { id: GameMode; label: string }[] = [
    { id: 'single', label: 'Einzelspieler' },
    { id: 'two', label: 'Zwei Spieler' },
    { id: 'online', label: 'Online' },
  ];
</script>

<div class="mode-switch" role="group" aria-label="Spielmodus">
  {#each OPTIONS as option (option.id)}
    <button
      class="mode-option"
      class:active={mode === option.id}
      aria-pressed={mode === option.id}
      onclick={() => onchange(option.id)}
    >
      {option.label}
    </button>
  {/each}
</div>

<style>
  .mode-switch {
    display: inline-flex;
    gap: 4px;
    padding: 4px;
    margin-top: 20px;
    border-radius: 999px;
    background: rgba(255, 255, 255, 0.7);
    border: 1px solid var(--border);
  }

  .mode-option {
    padding: 8px 18px;
    border-radius: 999px;
    border: none;
    background: transparent;
    color: var(--text-h);
    font-family: inherit;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s, color 0.2s;
  }

  .mode-option:hover:not(.active) {
    background: var(--accent-bg);
  }

  .mode-option.active {
    background: var(--pink-dark);
    color: #fff;
  }

  .mode-option:focus-visible {
    outline: 2px solid var(--pink-dark);
    outline-offset: 2px;
  }
</style>
