<script lang="ts">
  import type { WordSlot } from './gameRules';

  interface Props {
    slots: WordSlot[];
  }

  let { slots }: Props = $props();
</script>

<div class="word-display">
  {#each slots as slot, i (i)}
    <span
      class="letter-slot"
      class:filled={slot.state === 'filled'}
      class:missed={slot.state === 'missed'}
    >
      {slot.letter}
    </span>
  {/each}
</div>

<style>
  .word-display {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: center;
    padding: 12px 0;
    margin: 4px 0;
  }

  .letter-slot {
    display: inline-flex;
    align-items: flex-end;
    justify-content: center;
    width: 36px;
    height: 48px;
    border-bottom: 3px solid var(--lavender);
    font-size: 26px;
    font-weight: 700;
    color: var(--text-h);
    font-family: var(--mono);
    transition: border-color 0.2s;
  }

  .letter-slot.filled {
    animation: pop 0.25s ease-out;
  }

  .letter-slot.missed {
    color: var(--error);
    border-bottom-color: var(--error);
  }

  @keyframes pop {
    0% { transform: scale(0.5); opacity: 0; }
    60% { transform: scale(1.15); }
    100% { transform: scale(1); opacity: 1; }
  }

  @media (max-width: 768px) {
    .letter-slot {
      width: 28px;
      height: 40px;
      font-size: 22px;
    }
  }
</style>
