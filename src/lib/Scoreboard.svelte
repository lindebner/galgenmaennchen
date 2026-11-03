<script lang="ts">
  interface Props {
    players: { name: string; score: number; active: boolean }[];
  }

  let { players }: Props = $props();
</script>

<div class="scoreboard">
  {#each players as player, i (i)}
    <div class="score-card" class:active={player.active}>
      {#if player.active}
        <span class="turn-badge">Am Zug</span>
      {/if}
      <span class="score-name">{player.name}</span>
      <span class="score-value">{player.score}</span>
      <span class="score-label">Punkte</span>
    </div>
  {/each}
</div>

<style>
  .scoreboard {
    display: flex;
    gap: 16px;
    justify-content: center;
    flex-wrap: wrap;
    width: 100%;
    max-width: 420px;
  }

  .score-card {
    flex: 1;
    min-width: 140px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    padding: 12px 16px;
    border-radius: 16px;
    background: rgba(255, 255, 255, 0.7);
    border: 1px solid var(--border);
    transition: border-color 0.2s, background 0.2s, box-shadow 0.2s;
  }

  .score-card.active {
    border-color: var(--pink-dark);
    background: var(--accent-bg);
    box-shadow: var(--shadow-soft);
  }

  .turn-badge {
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: #fff;
    background: var(--pink-dark);
    padding: 2px 10px;
    border-radius: 999px;
    margin-bottom: 4px;
  }

  .score-name {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-h);
  }

  .score-value {
    font-size: 28px;
    font-weight: 700;
    line-height: 120%;
    color: var(--pink-dark);
    font-variant-numeric: tabular-nums;
  }

  .score-label {
    font-size: 12px;
    color: var(--text-h);
  }
</style>
