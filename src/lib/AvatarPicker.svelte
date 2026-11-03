<script lang="ts">
  import { AVATARS } from './avatars';

  interface Props {
    selected: string | null;
    unavailable?: string | null;
    onselect: (id: string) => void;
  }

  let { selected, unavailable = null, onselect }: Props = $props();
</script>

<div class="avatar-grid" role="radiogroup" aria-label="Figur wählen">
  {#each AVATARS as avatar (avatar.id)}
    {@const isDisabled = avatar.id === unavailable}
    <button
      type="button"
      class="avatar-option"
      class:selected={avatar.id === selected}
      role="radio"
      aria-checked={avatar.id === selected}
      aria-label={avatar.label}
      title={avatar.label}
      disabled={isDisabled}
      onclick={() => onselect(avatar.id)}
    >
      <span class="avatar-emoji">{avatar.emoji}</span>
    </button>
  {/each}
</div>

<style>
  .avatar-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(56px, 1fr));
    gap: 8px;
    width: 100%;
    max-width: 360px;
  }

  .avatar-option {
    aspect-ratio: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 16px;
    border: 2px solid var(--border);
    background: rgba(255, 255, 255, 0.85);
    cursor: pointer;
    transition: transform 0.15s, border-color 0.2s, box-shadow 0.2s, opacity 0.2s;
  }

  .avatar-option:hover:not(:disabled) {
    transform: translateY(-2px);
    border-color: var(--accent-border);
  }

  .avatar-option.selected {
    border-color: var(--pink-dark);
    background: var(--accent-bg);
    box-shadow: var(--shadow-soft);
  }

  .avatar-option:disabled {
    opacity: 0.35;
    cursor: not-allowed;
  }

  .avatar-option:focus-visible {
    outline: 3px solid var(--pink-dark);
    outline-offset: 2px;
  }

  .avatar-emoji {
    font-size: 28px;
    line-height: 1;
  }
</style>
