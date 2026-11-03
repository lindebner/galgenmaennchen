<script lang="ts">
  interface Props {
    hint: string;
  }

  let { hint }: Props = $props();
</script>

<div class="hint-box">
  <span class="hint-icon">Tipp</span>
  <span class="hint-text">{hint}</span>
</div>

<style>
  .hint-box {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 20px;
    border-radius: 16px;
    background: var(--secondary-bg);
    border: 1px solid var(--secondary-border);
    max-width: 100%;
  }

  .hint-icon {
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--lavender-dark);
    flex-shrink: 0;
  }

  .hint-text {
    font-size: 14px;
    color: var(--text-h);
  }
</style>
