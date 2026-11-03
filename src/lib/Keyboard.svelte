<script lang="ts">
  import { KEY_ROWS } from './gameRules';

  interface Props {
    guessed: Set<string>;
    correct: Set<string>;
    disabled?: boolean;
    onguess: (letter: string) => void;
  }

  let { guessed, correct, disabled = false, onguess }: Props = $props();
</script>

<div class="keyboard">
  {#each KEY_ROWS as row (row.join(''))}
    <div class="key-row">
      {#each row as letter (letter)}
        {@const isGuessed = guessed.has(letter)}
        <button
          class="key"
          class:correct={isGuessed && correct.has(letter)}
          class:wrong={isGuessed && !correct.has(letter)}
          disabled={disabled || isGuessed}
          onclick={() => onguess(letter)}
          aria-label={`Buchstabe ${letter} raten`}
        >
          {letter}
        </button>
      {/each}
    </div>
  {/each}
</div>
{#if !disabled}
  <p class="type-hint">Du kannst auch direkt auf der Tastatur tippen</p>
{/if}

<style>
  .type-hint {
    font-size: 13px;
    color: var(--text);
    margin-top: 4px;
  }

  .keyboard {
    display: flex;
    flex-direction: column;
    gap: 7px;
    max-width: 560px;
    width: 100%;
  }

  .key-row {
    display: flex;
    justify-content: center;
    gap: 7px;
  }

  .key {
    width: 42px;
    height: 46px;
    border-radius: 14px;
    border: 1px solid var(--border);
    background: rgba(255, 255, 255, 0.7);
    color: var(--text-h);
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.15s, transform 0.1s, border-color 0.15s, box-shadow 0.15s;
  }

  .key:hover:not(:disabled) {
    border-color: var(--accent-border);
    background: var(--accent-bg);
    box-shadow: var(--shadow-soft);
  }

  .key:active:not(:disabled) {
    transform: scale(0.92);
  }

  .key:disabled {
    cursor: default;
  }

  .key.correct {
    background: var(--success-bg);
    border-color: var(--success-border);
    color: var(--success);
  }

  .key.wrong {
    background: var(--error-bg);
    border-color: var(--error-border);
    color: var(--error);
    opacity: 0.55;
  }

  @media (max-width: 768px) {
    .key {
      width: 34px;
      height: 38px;
      font-size: 14px;
      border-radius: 10px;
    }
  }

  @media (max-width: 420px) {
    .key {
      width: 28px;
      height: 32px;
      font-size: 12px;
    }

    .key-row {
      gap: 4px;
    }
  }
</style>
