<script lang="ts">
  import { getRandomWord } from './lib/words';
  import HangmanCanvas from './lib/HangmanCanvas.svelte';

  const MAX_WRONG = 6;

  const KEY_ROWS: string[][] = [
    ['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä'],
    ['Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß'],
  ];

  const ALL_LETTERS = KEY_ROWS.flat();

  // Map physical keyboard keys to the game's letter representation.
  // German umlauts can be typed with an international keyboard, or as ae/oe/ue/ss.
  const KEY_MAP: Record<string, string> = {
    'Ä': 'Ä', 'Ö': 'Ö', 'Ü': 'Ü', 'ß': 'ß',
    'AE': 'Ä', 'OE': 'Ö', 'UE': 'Ü', 'SS': 'ß',
  };

  type GameState = 'playing' | 'won' | 'lost';

  interface SavedState {
    word: string;
    hint: string;
    guessed: string[];
    wrongCount: number;
    gameState: GameState;
  }

  const STORAGE_KEY = 'galgenmaennchen';

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

  let revealed = $derived(word.split('').map((l) => (guessed.has(l) ? l : null)));
  let wrongLetters = $derived(
    ALL_LETTERS.filter((l) => guessed.has(l) && !word.includes(l)),
  ) as string[];

  function startNewGame() {
    const entry = getRandomWord();
    word = entry.word;
    hint = entry.hint;
    guessed = new Set();
    wrongCount = 0;
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

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Enter' && gameState !== 'playing') {
      startNewGame();
      return;
    }
    const key = event.key.toUpperCase();
    if (key.length !== 1) return;
    // Umlauts and ß via direct key or two-letter alternatives (ae/oe/ue/ss)
    if (KEY_MAP[key]) {
      guess(KEY_MAP[key]);
      return;
    }
    // Regular A–Z letters
    if (key >= 'A' && key <= 'Z') {
      guess(key);
    }
  }

  // Restore from local storage, or start fresh
  const saved = loadState();
  if (saved) {
    word = saved.word;
    hint = saved.hint;
    guessed = new Set(saved.guessed);
    wrongCount = saved.wrongCount;
    gameState = saved.gameState;
  } else {
    startNewGame();
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<main id="game">
  <header class="game-header">
    <h1>Galgenmännchen</h1>
    <p class="subtitle">Errate das Wort, bevor die Figur fertig ist</p>
  </header>

  <div class="game-body">
    <!-- Left: gallows + status -->
    <section class="left-panel">
      <HangmanCanvas {wrongCount} />

      <div class="lives">
        <span class="lives-label">Fehler</span>
        <span class="lives-count" class:danger={wrongCount >= MAX_WRONG - 1}>
          {wrongCount} / {MAX_WRONG}
        </span>
      </div>

      {#if wrongLetters.length > 0}
        <div class="wrong-letters">
          <span class="wrong-label">Falsch:</span>
          {#each wrongLetters as letter (letter)}
            <span class="wrong-chip">{letter}</span>
          {/each}
        </div>
      {/if}
    </section>

    <!-- Right: word + keyboard -->
    <section class="right-panel">
      <div class="hint-box">
        <span class="hint-icon">Tipp</span>
        <span class="hint-text">{hint}</span>
      </div>

      <!-- Word display -->
      <div class="word-display" class:revealed-all={gameState !== 'playing'}>
        {#each revealed as letter, i (i)}
          <span class="letter-slot" class:filled={letter !== null} class:missed={gameState === 'lost' && letter === null}>
            {letter ?? (gameState === 'lost' ? word[i] : '')}
          </span>
        {/each}
      </div>

      <!-- Game result banner -->
      {#if gameState !== 'playing'}
        <div class="result-banner" class:win={gameState === 'won'} class:lose={gameState === 'lost'}>
          {#if gameState === 'won'}
            <span class="result-title">Gewonnen!</span>
            <span class="result-detail">Du hast das Wort mit {MAX_WRONG - wrongCount} {MAX_WRONG - wrongCount === 1 ? 'Versuch' : 'Versuchen'} übrig erraten.</span>
          {:else}
            <span class="result-title">Verloren</span>
            <span class="result-detail">Das Wort war <strong>{word}</strong></span>
          {/if}
          <button class="play-again" onclick={startNewGame}>Nochmal spielen</button>
          <span class="kbd-hint">oder Enter drücken</span>
        </div>
      {/if}

      <!-- Keyboard -->
      {#if gameState === 'playing'}
        <div class="keyboard">
          {#each KEY_ROWS as row (row.join(''))}
            <div class="key-row">
              {#each row as letter (letter)}
                {@const isGuessed = guessed.has(letter)}
                {@const isCorrect = isGuessed && word.includes(letter)}
                {@const isWrong = isGuessed && !word.includes(letter)}
                <button
                  class="key"
                  class:correct={isCorrect}
                  class:wrong={isWrong}
                  disabled={isGuessed}
                  onclick={() => guess(letter)}
                  aria-label={`Buchstabe ${letter} raten`}
                >
                  {letter}
                </button>
              {/each}
            </div>
          {/each}
        </div>
        <p class="type-hint">Du kannst auch direkt auf der Tastatur tippen</p>
      {/if}
    </section>
  </div>
</main>

<style>
  #game {
    max-width: 960px;
    margin: 0 auto;
    padding: 24px 20px 48px;
    text-align: center;
  }

  .game-header {
    margin-bottom: 32px;
  }

  .game-header h1 {
    font-size: 48px;
    font-weight: 700;
    letter-spacing: -1px;
    margin: 0 0 6px;
    background: var(--gradient-mixed);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .subtitle {
    color: var(--text);
    font-size: 15px;
  }

  .game-body {
    display: flex;
    gap: 40px;
    align-items: flex-start;
    justify-content: center;
    flex-wrap: wrap;
  }

  .left-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    flex-shrink: 0;
    padding: 24px 20px;
    border-radius: 24px;
    background: rgba(255, 255, 255, 0.6);
    backdrop-filter: blur(12px);
    border: 1px solid rgba(236, 72, 153, 0.12);
    box-shadow: var(--shadow-soft);
  }

  .lives {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
  }

  .lives-label {
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: var(--text);
  }

  .lives-count {
    font-size: 22px;
    font-weight: 700;
    color: var(--lavender-dark);
    font-variant-numeric: tabular-nums;
  }

  .lives-count.danger {
    color: var(--error);
  }

  .wrong-letters {
    display: flex;
    align-items: center;
    gap: 6px;
    flex-wrap: wrap;
    justify-content: center;
    max-width: 200px;
  }

  .wrong-label {
    font-size: 13px;
    color: var(--text);
  }

  .wrong-chip {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 26px;
    height: 26px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 600;
    color: var(--error);
    background: var(--error-bg);
  }

  .right-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
    flex: 1;
    min-width: 280px;
  }

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

  .result-banner {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    padding: 24px 32px;
    border-radius: 20px;
    animation: fade-in 0.35s ease-out;
  }

  .result-banner.win {
    background: var(--success-bg);
    border: 1px solid var(--success-border);
  }

  .result-banner.lose {
    background: var(--error-bg);
    border: 1px solid var(--error-border);
  }

  .result-title {
    font-size: 26px;
    font-weight: 700;
  }

  .result-banner.win .result-title {
    color: var(--success);
  }

  .result-banner.lose .result-title {
    color: var(--error);
  }

  .result-detail {
    font-size: 14px;
    color: var(--text);
  }

  .result-detail strong {
    color: var(--text-h);
  }

  .play-again {
    margin-top: 10px;
    padding: 12px 32px;
    border-radius: 14px;
    border: none;
    font-size: 15px;
    font-weight: 600;
    cursor: pointer;
    background: var(--gradient-pink);
    color: #fff;
    transition: transform 0.15s, box-shadow 0.2s;
    box-shadow: var(--shadow-soft);
  }

  .play-again:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow);
  }

  .play-again:active {
    transform: translateY(0);
  }

  .kbd-hint {
    font-size: 12px;
    color: var(--text);
  }

  .type-hint {
    font-size: 13px;
    color: var(--text);
    margin-top: 4px;
  }

  .keyboard {
    display: flex;
    flex-direction: column;
    gap: 7px;
    max-width: 560px;
    width: 100%;
  }

  .key-row {
    display: flex;
    justify-content: center;
    gap: 7px;
  }

  .key {
    width: 42px;
    height: 46px;
    border-radius: 14px;
    border: 1px solid var(--border);
    background: rgba(255, 255, 255, 0.7);
    color: var(--text-h);
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.15s, transform 0.1s, border-color 0.15s, box-shadow 0.15s;
  }

  .key:hover:not(:disabled) {
    border-color: var(--accent-border);
    background: var(--accent-bg);
    box-shadow: var(--shadow-soft);
  }

  .key:active:not(:disabled) {
    transform: scale(0.92);
  }

  .key:disabled {
    cursor: default;
  }

  .key.correct {
    background: var(--success-bg);
    border-color: var(--success-border);
    color: var(--success);
  }

  .key.wrong {
    background: var(--error-bg);
    border-color: var(--error-border);
    color: var(--error);
    opacity: 0.55;
  }

  @keyframes fade-in {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
  }

  @media (max-width: 768px) {
    .game-body {
      flex-direction: column;
      align-items: center;
      gap: 20px;
    }

    .game-header h1 {
      font-size: 36px;
    }

    .key {
      width: 34px;
      height: 38px;
      font-size: 14px;
      border-radius: 10px;
    }

    .letter-slot {
      width: 28px;
      height: 40px;
      font-size: 22px;
    }
  }

  @media (max-width: 420px) {
    .key {
      width: 28px;
      height: 32px;
      font-size: 12px;
    }

    .key-row {
      gap: 4px;
    }
  }
</style>
