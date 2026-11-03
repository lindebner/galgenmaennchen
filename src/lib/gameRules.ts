export type GameMode = 'single' | 'two' | 'online';
export type Seat = 1 | 2;

export const MAX_WRONG = 6;

export const KEY_ROWS: string[][] = [
  ['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü'],
  ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä'],
  ['Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß'],
];

export const ALL_LETTERS = KEY_ROWS.flat();

const UMLAUTS = new Set(['Ä', 'Ö', 'Ü']);

export function letterFromKey(key: string): string | null {
  if (key === 'ß') return 'ß';
  const upper = key.toUpperCase();
  if (upper.length !== 1) return null;
  if ((upper >= 'A' && upper <= 'Z') || UMLAUTS.has(upper)) return upper;
  return null;
}

export interface WordSlot {
  letter: string;
  state: 'empty' | 'filled' | 'missed';
}

export function buildSlots(word: string, guessed: Set<string>, showMissed: boolean): WordSlot[] {
  return [...word].map((char): WordSlot => {
    if (guessed.has(char)) return { letter: char, state: 'filled' };
    if (showMissed) return { letter: char, state: 'missed' };
    return { letter: '', state: 'empty' };
  });
}

export function wrongLettersOf(word: string, guessed: Set<string>): string[] {
  return ALL_LETTERS.filter((l) => guessed.has(l) && !word.includes(l));
}
