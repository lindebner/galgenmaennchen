<script lang="ts">
  import { getRandomWord } from '../words';
  import {
    MAX_WRONG,
    buildSlots,
    letterFromKey,
    wrongLettersOf,
    type Seat,
  } from '../gameRules';
  import { avatarEmoji } from '../avatars';
  import AvatarPicker from '../AvatarPicker.svelte';
  import GameLayout from '../GameLayout.svelte';
  import GallowsPanel from '../GallowsPanel.svelte';
  import HintBox from '../HintBox.svelte';
  import WordDisplay from '../WordDisplay.svelte';
  import Keyboard from '../Keyboard.svelte';
  import ResultBanner from '../ResultBanner.svelte';
  import Scoreboard from '../Scoreboard.svelte';

  const STORAGE_KEY = 'galgenmaennchen-zwei';
  const seats: Seat[] = [1, 2];

  type GameState = 'playing' | 'won' | 'lost';

  interface SavedState {
    word: string;
    hint: string;
    guessed: string[];
    wrongCount: number;
    gameState: GameState;
    turn: Seat;
    starter: Seat;
    scores: Record<Seat, number>;
    avatars: Record<Seat, string>;
  }

  function loadState(): SavedState | null {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as SavedState;
      if (
        typeof parsed.word !== 'string' ||
        !Array.isArray(parsed.guessed) ||
        typeof parsed.wrongCount !== 'number' ||
        !parsed.scores ||
        !parsed.avatars?.[1] ||
        !parsed.avatars?.[2]
      ) {
        return null;
      }
      return parsed;
    } catch {
      return null;
    }
  }

  function saveState() {
    const state: SavedState = {
      word,
      hint,
      guessed: [...guessed],
      wrongCount,
      gameState,
      turn,
      starter,
      scores,
      avatars: { 1: avatars[1] ?? '', 2: avatars[2] ?? '' },
    };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // ignore storage errors
    }
  }

  function other(seat: Seat): Seat {
    return seat === 1 ? 2 : 1;
  }

  let word = $state('');
  let hint = $state('');
  let guessed = $state<Set<string>>(new Set());
  let wrongCount = $state(0);
  let gameState = $state<GameState>('playing');
  let turn = $state<Seat>(1);
  let starter = $state<Seat>(2);
  let scores = $state<Record<Seat, number>>({ 1: 0, 2: 0 });
  let avatars = $state<Record<Seat, string | null>>({ 1: null, 2: null });
  let setupDone = $state(false);

  let correctLetters = $derived(new Set(word));
  let wrongLetters = $derived(wrongLettersOf(word, guessed));
  let slots = $derived(buildSlots(word, guessed, gameState === 'lost'));
  let scoreboardPlayers = $derived(
    seats.map((seat) => ({
      name: `Spieler ${seat}`,
      emoji: avatarEmoji(avatars[seat]),
      score: scores[seat],
      active: gameState === 'playing' && turn === seat,
    })),
  );

  function startNewRound() {
    const entry = getRandomWord();
    word = entry.word;
    hint = entry.hint;
    guessed = new Set();
    wrongCount = 0;
    gameState = 'playing';
    starter = other(starter);
    turn = starter;
    saveState();
  }

  function startGame() {
    setupDone = true;
    scores = { 1: 0, 2: 0 };
    starter = 2;
    startNewRound();
  }

  function guess(letter: string) {
    if (gameState !== 'playing') return;
    if (guessed.has(letter)) return;

    const next = new Set(guessed);
    next.add(letter);
    guessed = next;

    if (word.includes(letter)) {
      if (word.split('').every((l) => next.has(l))) {
        gameState = 'won';
        scores[turn] += 1;
      }
    } else {
      wrongCount += 1;
      if (wrongCount >= MAX_WRONG) {
        gameState = 'lost';
      } else {
        turn = other(turn);
      }
    }
    saveState();
  }

  function handleKeydown(event: KeyboardEvent) {
    if (!setupDone) return;
    if (event.key === 'Enter' && gameState !== 'playing') {
      startNewRound();
      return;
    }
    const letter = letterFromKey(event.key);
    if (letter) guess(letter);
  }

  const saved = loadState();
  if (saved) {
    word = saved.word;
    hint = saved.hint;
    guessed = new Set(saved.guessed);
    wrongCount = saved.wrongCount;
    gameState = saved.gameState;
    turn = saved.turn;
    starter = saved.starter;
    scores = saved.scores;
    avatars = { 1: saved.avatars[1], 2: saved.avatars[2] };
    setupDone = true;
  }
</script>

<svelte:window onkeydown={handleKeydown} />

{#if !setupDone}
  <section class="setup">
    <h2 class="setup-title">Figuren wählen</h2>
    <p class="setup-text">Jeder Spieler wählt eine eigene Figur.</p>

    <div class="setup-players">
      {#each seats as seat (seat)}
        <div class="setup-player">
          <span class="setup-label">Spieler {seat}</span>
          <AvatarPicker
            selected={avatars[seat]}
            unavailable={avatars[other(seat)]}
            onselect={(id) => (avatars[seat] = id)}
          />
        </div>
      {/each}
    </div>

    <button
      class="start-button"
      onclick={startGame}
      disabled={avatars[1] === null || avatars[2] === null}
    >
      Spiel starten
    </button>
  </section>
{:else}
  <Scoreboard players={scoreboardPlayers} />

  <GameLayout>
    {#snippet left()}
      <GallowsPanel {wrongCount} {wrongLetters} />
    {/snippet}

    <HintBox {hint} />

    <WordDisplay {slots} />

    {#if gameState === 'playing'}
      <Keyboard guessed={guessed} correct={correctLetters} onguess={guess} />
    {:else}
      <ResultBanner
        tone={gameState === 'won' ? 'win' : 'lose'}
        title={gameState === 'won' ? 'Gewonnen!' : 'Verloren'}
        nextLabel="Nächste Runde"
        onnext={startNewRound}
      >
        {#snippet detail()}
          {#if gameState === 'won'}
            Spieler {turn} hat das Wort erraten und bekommt einen Punkt.
          {:else}
            Niemand hat das Wort erraten. Das Wort war <strong>{word}</strong>
          {/if}
        {/snippet}
      </ResultBanner>
    {/if}
  </GameLayout>
{/if}

<style>
  .setup {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    padding: 32px 24px;
    border-radius: 20px;
    background: rgba(255, 255, 255, 0.7);
    border: 1px solid var(--border);
    box-shadow: var(--shadow-soft);
  }

  .setup-title {
    margin: 0;
    font-size: 24px;
    line-height: 120%;
    color: var(--text-h);
  }

  .setup-text {
    margin: 0;
    font-size: 15px;
    color: var(--text-h);
  }

  .setup-players {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 32px;
    width: 100%;
  }

  .setup-player {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
  }

  .setup-label {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-h);
  }

  .start-button {
    padding: 12px 28px;
    border-radius: 14px;
    border: none;
    background: var(--pink-dark);
    color: #fff;
    font-family: inherit;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    transition: transform 0.15s, box-shadow 0.2s, opacity 0.2s;
    box-shadow: var(--shadow-soft);
  }

  .start-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: var(--shadow);
  }

  .start-button:disabled {
    opacity: 0.5;
    cursor: default;
  }
</style>
