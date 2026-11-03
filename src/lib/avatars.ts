export interface Avatar {
  id: string;
  emoji: string;
  label: string;
}

export const AVATARS: Avatar[] = [
  { id: 'fox', emoji: '🦊', label: 'Fuchs' },
  { id: 'bear', emoji: '🐻', label: 'Bär' },
  { id: 'frog', emoji: '🐸', label: 'Frosch' },
  { id: 'owl', emoji: '🦉', label: 'Eule' },
  { id: 'panda', emoji: '🐼', label: 'Panda' },
  { id: 'octopus', emoji: '🐙', label: 'Krake' },
  { id: 'lion', emoji: '🦁', label: 'Löwe' },
  { id: 'penguin', emoji: '🐧', label: 'Pinguin' },
  { id: 'astronaut', emoji: '🧑‍🚀', label: 'Astronautin' },
  { id: 'artist', emoji: '🧑‍🎨', label: 'Künstlerin' },
  { id: 'scientist', emoji: '🧑‍🔬', label: 'Forscherin' },
  { id: 'dragon', emoji: '🐉', label: 'Drache' },
  { id: 'unicorn', emoji: '🦄', label: 'Einhorn' },
  { id: 'wizard', emoji: '🧙', label: 'Magier' },
  { id: 'fairy', emoji: '🧚', label: 'Fee' },
  { id: 'mermaid', emoji: '🧜', label: 'Meerjungfrau' },
  { id: 'vampire', emoji: '🧛', label: 'Vampir' },
];

export function avatarEmoji(id: string | null): string {
  return AVATARS.find((avatar) => avatar.id === id)?.emoji ?? '';
}
