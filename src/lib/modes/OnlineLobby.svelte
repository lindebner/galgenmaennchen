<script lang="ts">
  import { getRandomWord } from '../words';
  import { createRoom, joinRoom, messageFromError, type RoomView } from '../online/roomApi';

  interface Props {
    playerId: string;
    onenter: (view: RoomView) => void;
  }

  let { playerId, onenter }: Props = $props();

  let name = $state('');
  let code = $state('');
  let busy = $state(false);
  let errorMessage = $state('');

  let trimmedName = $derived(name.trim());
  let canJoin = $derived(trimmedName.length > 0 && code.trim().length === 6 && !busy);
  let canCreate = $derived(trimmedName.length > 0 && !busy);

  async function run(action: () => Promise<RoomView>) {
    busy = true;
    errorMessage = '';
    try {
      onenter(await action());
    } catch (error) {
      errorMessage = messageFromError(error);
    } finally {
      busy = false;
    }
  }

  function createGame() {
    run(() => createRoom(playerId, trimmedName, getRandomWord()));
  }

  function joinGame() {
    run(() => joinRoom(code.trim().toUpperCase(), playerId, trimmedName));
  }
</script>

<div class="lobby">
  <label class="field">
    <span>Dein Name</span>
    <input bind:value={name} maxlength="20" placeholder="z. B. Anna" autocomplete="off" />
  </label>

  <div class="lobby-cards">
    <section class="lobby-card">
      <h2>Neues Spiel</h2>
      <p>Erstelle einen Raum und schick den Code an deinen Mitspieler.</p>
      <button class="primary-button" onclick={createGame} disabled={!canCreate}>
        Raum erstellen
      </button>
    </section>

    <section class="lobby-card">
      <h2>Raum beitreten</h2>
      <p>Gib den Code ein, den dir dein Mitspieler geschickt hat.</p>
      <input
        bind:value={code}
        maxlength="6"
        placeholder="Raumcode"
        autocomplete="off"
        autocapitalize="characters"
        spellcheck="false"
        class="code-input"
      />
      <button class="primary-button" onclick={joinGame} disabled={!canJoin}>
        Beitreten
      </button>
    </section>
  </div>

  {#if errorMessage}
    <p class="error" role="alert">{errorMessage}</p>
  {/if}
</div>

<style>
  .lobby {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 24px;
    width: 100%;
    max-width: 640px;
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: 6px;
    width: 100%;
    max-width: 320px;
    font-size: 14px;
    font-weight: 600;
    color: var(--text-h);
  }

  .field input,
  .code-input {
    padding: 12px 16px;
    border-radius: 12px;
    border: 1px solid var(--border);
    background: #fff;
    color: var(--text-h);
    font-family: inherit;
    font-size: 16px;
    text-align: center;
  }

  .code-input {
    text-transform: uppercase;
    letter-spacing: 4px;
    font-family: var(--mono);
    font-weight: 700;
  }

  .lobby-cards {
    display: flex;
    gap: 20px;
    flex-wrap: wrap;
    justify-content: center;
    width: 100%;
  }

  .lobby-card {
    flex: 1;
    min-width: 240px;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 24px;
    border-radius: 20px;
    background: rgba(255, 255, 255, 0.7);
    border: 1px solid var(--border);
    box-shadow: var(--shadow-soft);
  }

  .lobby-card h2 {
    margin: 0;
    font-size: 20px;
    line-height: 120%;
    color: var(--text-h);
  }

  .lobby-card p {
    margin: 0;
    font-size: 14px;
    color: var(--text-h);
  }

  .primary-button {
    margin-top: 4px;
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

  .primary-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: var(--shadow);
  }

  .primary-button:disabled {
    opacity: 0.5;
    cursor: default;
  }

  .error {
    margin: 0;
    font-size: 14px;
    color: #b91c1c;
  }
</style>
