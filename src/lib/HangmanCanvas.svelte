<script lang="ts">
  interface Props {
    wrongCount: number;
  }

  let { wrongCount }: Props = $props();
</script>

<svg
  viewBox="0 0 280 340"
  class="hangman-svg"
  aria-label={`Galgenmännchen: ${wrongCount} von 6 falschen Versuchen`}
>
  <!-- Gallows (always visible) -->
  <line x1="20" y1="320" x2="180" y2="320" class="gallows" />
  <line x1="60" y1="320" x2="60" y2="20" class="gallows" />
  <line x1="60" y1="20" x2="200" y2="20" class="gallows" />
  <line x1="200" y1="20" x2="200" y2="50" class="gallows" />
  <!-- Support brace -->
  <line x1="60" y1="40" x2="100" y2="20" class="gallows" />

  <!-- Head -->
  {#if wrongCount >= 1}
    <circle cx="200" cy="75" r="25" class="figure figure-head" />
  {/if}

  <!-- Body -->
  {#if wrongCount >= 2}
    <line x1="200" y1="100" x2="200" y2="200" class="figure" />
  {/if}

  <!-- Left arm -->
  {#if wrongCount >= 3}
    <line x1="200" y1="130" x2="160" y2="170" class="figure" />
  {/if}

  <!-- Right arm -->
  {#if wrongCount >= 4}
    <line x1="200" y1="130" x2="240" y2="170" class="figure" />
  {/if}

  <!-- Left leg -->
  {#if wrongCount >= 5}
    <line x1="200" y1="200" x2="165" y2="250" class="figure" />
  {/if}

  <!-- Right leg -->
  {#if wrongCount >= 6}
    <line x1="200" y1="200" x2="235" y2="250" class="figure" />
  {/if}
</svg>

<style>
  .hangman-svg {
    width: 100%;
    max-width: 320px;
    height: auto;
  }

  .gallows {
    stroke: var(--lavender);
    stroke-width: 5;
    stroke-linecap: round;
    fill: none;
  }

  .figure {
    stroke: var(--pink);
    stroke-width: 5;
    stroke-linecap: round;
    fill: none;
    stroke-dasharray: 200;
    stroke-dashoffset: 200;
    animation: draw 0.4s ease-out forwards;
  }

  .figure-head {
    stroke-dasharray: 160;
    stroke-dashoffset: 160;
    animation: draw-head 0.4s ease-out forwards;
  }

  @keyframes draw {
    to {
      stroke-dashoffset: 0;
    }
  }

  @keyframes draw-head {
    to {
      stroke-dashoffset: 0;
    }
  }
</style>
