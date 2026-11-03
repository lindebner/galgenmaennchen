import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { WordEntry } from '../words';
import type { Seat } from '../gameRules';

export interface RoomPlayer {
  seat: Seat;
  name: string | null;
  score: number;
  avatar: string | null;
}

export interface RoomView {
  code: string;
  status: 'waiting' | 'playing' | 'won' | 'lost';
  round: number;
  hint: string;
  seat: Seat | null;
  turn: Seat;
  wrongCount: number;
  guessed: string[];
  wrongLetters: string[];
  slots: (string | null)[];
  lastWinner: Seat | null;
  players: RoomPlayer[];
}

const GENERIC_ERROR = 'Etwas ist schiefgelaufen. Bitte versuche es noch einmal.';

const ERROR_MESSAGES: Record<string, string> = {
  room_not_found: 'Diesen Raumcode gibt es nicht.',
  room_full: 'In diesem Raum sind schon zwei Spieler.',
  not_in_room: 'Du bist nicht Teil dieses Raums.',
  not_your_turn: 'Du bist gerade nicht am Zug.',
  already_guessed: 'Dieser Buchstabe wurde schon geraten.',
  round_not_active: 'Diese Runde ist schon vorbei.',
  round_not_finished: 'Die aktuelle Runde läuft noch.',
  invalid_name: 'Bitte gib einen Namen mit 1 bis 20 Zeichen ein.',
  invalid_word: 'Das Wort konnte nicht gespeichert werden.',
  invalid_letter: 'Dieser Buchstabe ist ungültig.',
  invalid_avatar: 'Bitte wähle eine Figur aus.',
  avatar_taken: 'Diese Figur ist schon vergeben. Wähle eine andere.',
};

let client: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (!client) {
    const url = import.meta.env.VITE_SUPABASE_URL;
    const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
    if (!url || !anonKey) {
      throw new Error('Der Online-Modus ist noch nicht eingerichtet.');
    }
    client = createClient(url, anonKey);
  }
  return client;
}

function isRoomView(value: unknown): value is RoomView {
  if (typeof value !== 'object' || value === null) return false;
  const view = value as Partial<RoomView>;
  return (
    typeof view.code === 'string' &&
    typeof view.status === 'string' &&
    Array.isArray(view.guessed) &&
    Array.isArray(view.wrongLetters) &&
    Array.isArray(view.slots) &&
    Array.isArray(view.players)
  );
}

async function callRoom(fn: string, args: Record<string, string>): Promise<RoomView> {
  const { data, error } = await getClient().rpc(fn, args);
  if (error) throw new Error(ERROR_MESSAGES[error.message] ?? GENERIC_ERROR);
  if (!isRoomView(data)) throw new Error(GENERIC_ERROR);
  return data;
}

export function messageFromError(error: unknown): string {
  return error instanceof Error ? error.message : GENERIC_ERROR;
}

export function createRoom(
  playerId: string,
  name: string,
  avatar: string,
  entry: WordEntry,
): Promise<RoomView> {
  return callRoom('create_room', {
    p_player: playerId,
    p_name: name,
    p_avatar: avatar,
    p_word: entry.word,
    p_hint: entry.hint,
  });
}

export function joinRoom(
  code: string,
  playerId: string,
  name: string,
  avatar: string,
): Promise<RoomView> {
  return callRoom('join_room', {
    p_code: code,
    p_player: playerId,
    p_name: name,
    p_avatar: avatar,
  });
}

export function getRoom(code: string, playerId: string): Promise<RoomView> {
  return callRoom('get_room', { p_code: code, p_player: playerId });
}

export function guessLetter(code: string, playerId: string, letter: string): Promise<RoomView> {
  return callRoom('guess_letter', { p_code: code, p_player: playerId, p_letter: letter });
}

export function startOnlineRound(code: string, playerId: string, entry: WordEntry): Promise<RoomView> {
  return callRoom('new_round', {
    p_code: code,
    p_player: playerId,
    p_word: entry.word,
    p_hint: entry.hint,
  });
}
