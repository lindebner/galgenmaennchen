<script lang="ts">
  import ModeSwitch from './lib/ModeSwitch.svelte';
  import SinglePlayer from './lib/modes/SinglePlayer.svelte';
  import TwoPlayer from './lib/modes/TwoPlayer.svelte';
  import OnlineGame from './lib/modes/OnlineGame.svelte';
  import type { GameMode } from './lib/gameRules';

  let mode = $state<GameMode>('single');
</script>

<main id="game">
  <header class="game-header">
    <h1>Galgenmännchen</h1>
    <p class="subtitle">Errate das Wort, bevor die Figur fertig ist</p>
    <ModeSwitch {mode} onchange={(next) => (mode = next)} />
  </header>

  {#if mode === 'single'}
    <SinglePlayer />
  {:else if mode === 'two'}
    <TwoPlayer />
  {:else}
    <OnlineGame />
  {/if}
</main>

<style>
  #game {
    max-width: 960px;
    margin: 0 auto;
    padding: 24px 20px 48px;
    text-align: center;
  }

  .game-header {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-bottom: 32px;
  }

  .game-header h1 {
    font-size: 48px;
    font-weight: 700;
    letter-spacing: -1px;
    margin: 0 0 6px;
    color: var(--pink-dark);
  }

  .subtitle {
    color: var(--text);
    font-size: 15px;
    margin: 0;
  }

  @media (max-width: 768px) {
    .game-header h1 {
      font-size: 36px;
    }
  }
</style>
