<script lang="ts">
  import { drawWord } from '../words';
  import {
    ALL_LETTERS,
    MAX_WRONG,
    buildSlots,
    letterFromKey,
    wrongLettersOf,
  } from '../gameRules';
  import GameLayout from '../GameLayout.svelte';
  import GallowsPanel from '../GallowsPanel.svelte';
  import HintBox from '../HintBox.svelte';
  import WordDisplay from '../WordDisplay.svelte';
  import Keyboard from '../Keyboard.svelte';
  import ResultBanner from '../ResultBanner.svelte';

  const MAX_HINTS = 3;
  const STORAGE_KEY = 'galgenmaennchen';

  type GameState = 'playing' | 'won' | 'lost';

  interface SavedState {
    word: string;
    hint: string;
    guessed: string[];
    wrongCount: number;
    gameState: GameState;
    hintsUsed?: number;
    usedWords?: string[];
  }

  function loadState(): SavedState | null {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw) as SavedState;
      if (
        typeof parsed.word !== 'string' ||
        typeof parsed.hint !== 'string' ||
        !Array.isArray(parsed.guessed) ||
        typeof parsed.wrongCount !== 'number' ||
        typeof parsed.gameState !== 'string'
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
      hintsUsed,
      usedWords,
    };
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch {
      // ignore storage errors
    }
  }

  let word = $state('');
  let hint = $state('');
  let guessed = $state<Set<string>>(new Set());
  let wrongCount = $state(0);
  let gameState = $state<GameState>('playing');
  let hintsUsed = $state(0);
  let usedWords = $state<string[]>([]);

  let correctLetters = $derived(new Set(word));
  let wrongLetters = $derived(wrongLettersOf(word, guessed));
  let slots = $derived(buildSlots(word, guessed, gameState === 'lost'));
  let hintLetters = $derived(ALL_LETTERS.filter((l) => word.includes(l) && !guessed.has(l)));

  function startNewGame() {
    const drawn = drawWord(usedWords);
    usedWords = drawn.used;
    word = drawn.entry.word;
    hint = drawn.entry.hint;
    guessed = new Set();
    wrongCount = 0;
    hintsUsed = 0;
    gameState = 'playing';
    saveState();
  }

  function guess(letter: string) {
    if (gameState !== 'playing') return;
    if (guessed.has(letter)) return;

    const next = new Set(guessed);
    next.add(letter);
    guessed = next;

    if (!word.includes(letter)) {
      wrongCount += 1;
    }

    if (wrongCount >= MAX_WRONG) {
      gameState = 'lost';
    } else if (word.split('').every((l) => next.has(l))) {
      gameState = 'won';
    }
    saveState();
  }

  function revealHint() {
    if (gameState !== 'playing' || hintsUsed >= MAX_HINTS || hintLetters.length === 0) return;
    const letter = hintLetters[Math.floor(Math.random() * hintLetters.length)];
    hintsUsed += 1;
    guess(letter);
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Enter' && gameState !== 'playing') {
      startNewGame();
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
    hintsUsed = saved.hintsUsed ?? 0;
    usedWords = saved.usedWords ?? [];
  } else {
    startNewGame();
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<GameLayout>
  {#snippet left()}
    <GallowsPanel {wrongCount} {wrongLetters} />
  {/snippet}

  <HintBox {hint} />

  <WordDisplay {slots} />

  {#if gameState === 'playing'}
    <button
      class="help-button"
      onclick={revealHint}
      disabled={hintsUsed >= MAX_HINTS || hintLetters.length === 0}
    >
      Hilfe: Buchstabe aufdecken ({MAX_HINTS - hintsUsed} übrig)
    </button>
    <Keyboard guessed={guessed} correct={correctLetters} onguess={guess} />
  {:else}
    <ResultBanner
      tone={gameState === 'won' ? 'win' : 'lose'}
      title={gameState === 'won' ? 'Gewonnen!' : 'Verloren'}
      nextLabel="Nochmal spielen"
      onnext={startNewGame}
    >
      {#snippet detail()}
        {#if gameState === 'won'}
          Du hast das Wort mit {MAX_WRONG - wrongCount} {MAX_WRONG - wrongCount === 1 ? 'Versuch' : 'Versuchen'} übrig erraten.
        {:else}
          Das Wort war <strong>{word}</strong>
        {/if}
      {/snippet}
    </ResultBanner>
  {/if}
</GameLayout>

<style>
  .help-button {
    padding: 10px 24px;
    border-radius: 14px;
    border: 1px solid var(--secondary-border);
    background: var(--secondary-bg);
    color: var(--text-h);
    font-family: inherit;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.15s, transform 0.1s, box-shadow 0.2s;
  }

  .help-button:hover:not(:disabled) {
    background: var(--accent-bg);
    box-shadow: var(--shadow-soft);
  }

  .help-button:active:not(:disabled) {
    transform: scale(0.97);
  }

  .help-button:disabled {
    opacity: 0.5;
    cursor: default;
  }
</style>
