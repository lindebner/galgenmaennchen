<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    left: Snippet;
    children: Snippet;
  }

  let { left, children }: Props = $props();
</script>

<div class="game-body">
  {@render left()}
  <section class="right-panel">
    {@render children()}
  </section>
</div>

<style>
  .game-body {
    display: flex;
    gap: 40px;
    align-items: flex-start;
    justify-content: center;
    flex-wrap: wrap;
  }

  .right-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
    flex: 1;
    min-width: 280px;
  }

  @media (max-width: 768px) {
    .game-body {
      flex-direction: column;
      align-items: center;
      gap: 20px;
    }
  }
</style>
