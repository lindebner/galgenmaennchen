# Project memory

## Product intent & audience

- App is a German-language hangman game ("Galgenmännchen").
- Audience: general users; readability and clarity are valued over decorative effects.
- Multiplayer modes include single-player, two-player (local), and online (database-backed).

## Brand personality & voice

- Practical and user-focused; prioritizes legibility over stylistic flair.
- Communication is direct and concise.

## Visual design & UX direction

- Background uses light/pale pink tones.
- Current headline: solid deep pink that matches/coordinates with the page theme while maintaining readability.
- Preference: text contrast takes priority over decorative gradient treatments.
- Avoid low-contrast text-on-background combinations generally.
- Avatar selection UI: character picker with 17 options (animals, humans, fantasy/mythical creatures like dragon, unicorn, wizard).
- Avatars displayed as emoji on player score cards and online scoreboards.

## Decisions, constraints & rationale

- Gradient headline abandoned: washed out against pale pink background.
- Dark purple-brown headline replaced with deep pink per user request for a matching pink tone.
- Character/avatar selection added per user request; implemented as a pre-game step.
- 17 avatar options spanning animals, humans, and fantasy/mythical creatures.
- Two-player mode: setup screen where each player picks a different avatar; avatar stored in browser (local state), not in online database.
- Online mode: avatar selection required on create and join screens; avatar stored in database via migration (avatar columns added to room/player tables); appears on both players' scoreboards.
- Single-player mode: no avatar step (only one player).
- No visual browser preview available in this environment; changes validated via build success and type check only, not visual confirmation.
- Security advisor findings are intentional public-function warnings (same as before, not new issues).

## Open questions & assumptions

- Assumes the deep pink headline meets adequate contrast against the pale pink background (not visually verified).
- Avatar picker UI not visually verified; hands-on browser check still recommended.
- No explicit `.bolt/prompt` instructions exist yet; visual direction is inferred from observed codebase and user feedback.
- Assumed avatar emoji rendering is consistent across target browsers/devices.