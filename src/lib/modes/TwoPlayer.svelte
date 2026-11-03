<script lang="ts">
  import { getRandomWord } from '../words';
  import {
    MAX_WRONG,
    buildSlots,
    letterFromKey,
    wrongLettersOf,
    type Seat,
  } from '../gameRules';
  import GameLayout from '../GameLayout.svelte';
  import GallowsPanel from '../GallowsPanel.svelte';
  import HintBox from '../HintBox.svelte';
  import WordDisplay from '../WordDisplay.svelte';
  import Keyboard from '../Keyboard.svelte';
  import ResultBanner from '../ResultBanner.svelte';
  import Scoreboard from '../Scoreboard.svelte';

  const STORAGE_KEY = 'galgenmaennchen-zwei';

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
        !parsed.scores
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

  let correctLetters = $derived(new Set(word));
  let wrongLetters = $derived(wrongLettersOf(word, guessed));
  let slots = $derived(buildSlots(word, guessed, gameState === 'lost'));
  let scoreboardPlayers = $derived(
    ([1, 2] as Seat[]).map((seat) => ({
      name: `Spieler ${seat}`,
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
  } else {
    startNewRound();
  }
</script>

<svelte:window onkeydown={handleKeydown} />

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
