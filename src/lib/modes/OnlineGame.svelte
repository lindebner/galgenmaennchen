<script lang="ts">
  import { getRandomWord } from '../words';
  import { letterFromKey, type WordSlot } from '../gameRules';
  import { avatarEmoji } from '../avatars';
  import {
    getRoom,
    guessLetter,
    messageFromError,
    startOnlineRound,
    type RoomView,
  } from '../online/roomApi';
  import GameLayout from '../GameLayout.svelte';
  import GallowsPanel from '../GallowsPanel.svelte';
  import HintBox from '../HintBox.svelte';
  import WordDisplay from '../WordDisplay.svelte';
  import Keyboard from '../Keyboard.svelte';
  import ResultBanner from '../ResultBanner.svelte';
  import Scoreboard from '../Scoreboard.svelte';
  import OnlineLobby from './OnlineLobby.svelte';

  const PLAYER_KEY = 'galgenmaennchen-player-id';
  const ROOM_KEY = 'galgenmaennchen-room';
  const POLL_INTERVAL_MS = 2000;

  function loadPlayerId(): string {
    const stored = localStorage.getItem(PLAYER_KEY);
    if (stored) return stored;
    const created = crypto.randomUUID();
    localStorage.setItem(PLAYER_KEY, created);
    return created;
  }

  function onlineSlots(view: RoomView): WordSlot[] {
    return view.slots.map((letter): WordSlot => {
      if (letter === null) return { letter: '', state: 'empty' };
      if (view.guessed.includes(letter)) return { letter, state: 'filled' };
      return { letter, state: 'missed' };
    });
  }

  function scoreboardOf(view: RoomView) {
    return view.players.map((player) => ({
      name: `${player.name ?? 'Warte auf Mitspieler'}${player.seat === view.seat ? ' (du)' : ''}`,
      emoji: avatarEmoji(player.avatar),
      score: player.score,
      active: view.status === 'playing' && view.turn === player.seat,
    }));
  }

  const playerId = loadPlayerId();

  let roomCode = $state<string | null>(localStorage.getItem(ROOM_KEY));
  let room = $state<RoomView | null>(null);
  let busy = $state(false);
  let errorMessage = $state('');

  let finished = $derived(room !== null && (room.status === 'won' || room.status === 'lost'));
  let myTurn = $derived(
    room !== null && room.status === 'playing' && room.seat !== null && room.turn === room.seat,
  );
  let canGuess = $derived(myTurn && !busy);
  let wrongCount = $derived(room?.wrongCount ?? 0);
  let wrongLetters = $derived(room?.wrongLetters ?? []);
  let guessedLetters = $derived(new Set(room?.guessed ?? []));
  let correctLetters = $derived(
    new Set((room?.slots ?? []).filter((letter): letter is string => letter !== null)),
  );
  let slots = $derived(room ? onlineSlots(room) : []);
  let players = $derived(room ? scoreboardOf(room) : []);
  let turnName = $derived(room?.players.find((p) => p.seat === room?.turn)?.name ?? 'Dein Mitspieler');
  let winnerName = $derived(room?.players.find((p) => p.seat === room?.lastWinner)?.name ?? '');
  let revealedWord = $derived((room?.slots ?? []).join(''));

  $effect(() => {
    const code = roomCode;
    if (!code) return;
    let active = true;

    const refresh = async () => {
      try {
        const view = await getRoom(code, playerId);
        if (active) {
          room = view;
          errorMessage = '';
        }
      } catch (error) {
        if (active) errorMessage = messageFromError(error);
      }
    };

    refresh();
    const timer = setInterval(refresh, POLL_INTERVAL_MS);
    return () => {
      active = false;
      clearInterval(timer);
    };
  });

  function enterRoom(view: RoomView) {
    localStorage.setItem(ROOM_KEY, view.code);
    room = view;
    roomCode = view.code;
    errorMessage = '';
  }

  function leaveRoom() {
    localStorage.removeItem(ROOM_KEY);
    roomCode = null;
    room = null;
    errorMessage = '';
  }

  async function perform(action: () => Promise<RoomView>) {
    if (busy) return;
    busy = true;
    try {
      room = await action();
      errorMessage = '';
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      busy = false;
    }
  }

  function guess(letter: string) {
    if (!room || !canGuess) return;
    const code = room.code;
    perform(() => guessLetter(code, playerId, letter));
  }

  function nextRound() {
    if (!room || !finished) return;
    const code = room.code;
    perform(() => startOnlineRound(code, playerId, getRandomWord()));
  }

  function handleKeydown(event: KeyboardEvent) {
    if (!room) return;
    if (event.key === 'Enter' && finished) {
      nextRound();
      return;
    }
    const letter = letterFromKey(event.key);
    if (letter) guess(letter);
  }
</script>

<svelte:window onkeydown={handleKeydown} />

{#if !roomCode}
  <OnlineLobby {playerId} onenter={enterRoom} />
{:else}
  <div class="room-bar">
    <span class="room-label">Raumcode</span>
    <span class="room-code">{roomCode}</span>
    <button class="leave-button" onclick={leaveRoom}>Raum verlassen</button>
  </div>

  {#if room}
    <Scoreboard {players} />

    <GameLayout>
      {#snippet left()}
        <GallowsPanel {wrongCount} {wrongLetters} />
      {/snippet}

      <HintBox hint={room.hint} />

      <WordDisplay {slots} />

      {#if room.status === 'waiting'}
        <p class="info">
          Warte auf deinen Mitspieler. Schick ihm den Code <strong>{room.code}</strong>.
        </p>
      {:else if room.status === 'playing'}
        <p class="info">
          {myTurn ? 'Du bist am Zug.' : `${turnName} ist am Zug.`}
        </p>
        <Keyboard guessed={guessedLetters} correct={correctLetters} disabled={!canGuess} onguess={guess} />
      {:else}
        <ResultBanner
          tone={room.status === 'won' ? 'win' : 'lose'}
          title={room.status === 'won' ? 'Gewonnen!' : 'Verloren'}
          nextLabel="Nächste Runde"
          onnext={nextRound}
        >
          {#snippet detail()}
            {#if winnerName}
              {winnerName} hat das Wort erraten und bekommt einen Punkt.
            {:else}
              Niemand hat das Wort erraten. Das Wort war <strong>{revealedWord}</strong>
            {/if}
          {/snippet}
        </ResultBanner>
      {/if}
    </GameLayout>
  {:else}
    <p class="info">Raum wird geladen ...</p>
  {/if}

  {#if errorMessage}
    <p class="error" role="alert">{errorMessage}</p>
  {/if}
{/if}

<style>
  .room-bar {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 20px;
  }

  .room-label {
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 1.5px;
    color: var(--text-h);
  }

  .room-code {
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 4px;
    color: var(--pink-dark);
    font-family: var(--mono);
  }

  .leave-button {
    padding: 8px 16px;
    border-radius: 12px;
    border: 1px solid var(--border);
    background: rgba(255, 255, 255, 0.8);
    color: var(--text-h);
    font-family: inherit;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
  }

  .leave-button:hover {
    border-color: var(--accent-border);
  }

  .info {
    margin: 0;
    font-size: 15px;
    color: var(--text-h);
    text-align: center;
  }

  .error {
    margin: 16px 0 0;
    font-size: 14px;
    color: #b91c1c;
    text-align: center;
  }
</style>
