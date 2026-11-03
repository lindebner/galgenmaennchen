/*
# Add 5-second turn timer to online rooms

Plain-English summary: in online games each guess must come within 5 seconds. If the time runs out, the turn passes to the other player and it counts as a wrong letter. A correct letter keeps the turn and restarts the 5 seconds. The server enforces this, so it cannot be bypassed from the browser.

1. Modified Tables
- `game_rooms`
  - `turn_ends_at` (timestamptz, nullable): moment the current turn expires. Null when the room is not in an active round.

2. Data Update
- Rooms that are already playing get a fresh 5-second window so they are not stuck.

3. Modified Functions
- `room_view` returns `turnEndsAtMs` and `serverTimeMs` (milliseconds since epoch) so the browser can show a countdown without trusting its own clock.
- `get_room` applies an expired turn before returning the room.
- `guess_letter` applies an expired turn first; a late guess is rejected by returning the updated room.
- `join_room`, `new_round` and `guess_letter` set the 5-second window when a turn starts or continues.

4. New Helper
- `expire_turn(game_rooms)` counts a missed turn as a wrong guess, passes the turn, or ends the round as lost after six wrong guesses. Not callable by public, anon or authenticated roles.

5. Security
- No table grants or policies change. Existing function grants are preserved by CREATE OR REPLACE.

6. Notes
- Safe to re-run: columns use IF NOT EXISTS, functions use CREATE OR REPLACE.
*/

ALTER TABLE game_rooms ADD COLUMN IF NOT EXISTS turn_ends_at timestamptz;

UPDATE game_rooms
SET turn_ends_at = now() + interval '5 seconds'
WHERE status = 'playing' AND turn_ends_at IS NULL;

CREATE OR REPLACE FUNCTION expire_turn(r game_rooms)
RETURNS game_rooms
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
IF r.status <> 'playing' OR r.turn_ends_at IS NULL OR now() < r.turn_ends_at THEN
RETURN r;
END IF;

IF r.wrong_count + 1 >= 6 THEN
UPDATE game_rooms
SET wrong_count = wrong_count + 1, status = 'lost', turn_ends_at = NULL
WHERE id = r.id
RETURNING * INTO r;
ELSE
UPDATE game_rooms
SET wrong_count = wrong_count + 1, turn = 3 - turn, turn_ends_at = now() + interval '5 seconds'
WHERE id = r.id
RETURNING * INTO r;
END IF;

RETURN r;
END;
$function$;

REVOKE ALL ON FUNCTION expire_turn(game_rooms) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION room_view(r game_rooms, p_player uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'public'
AS $function$
DECLARE
v_seat smallint;
v_finished boolean := r.status IN ('won', 'lost');
BEGIN
v_seat := CASE
WHEN r.player1_id = p_player THEN 1
WHEN r.player2_id = p_player THEN 2
END;

RETURN jsonb_build_object(
'code', r.code,
'status', r.status,
'round', r.round,
'hint', r.hint,
'seat', v_seat,
'turn', r.turn,
'wrongCount', r.wrong_count,
'guessed', to_jsonb(r.guessed),
'wrongLetters', (
SELECT coalesce(jsonb_agg(g ORDER BY g), '[]'::jsonb)
FROM unnest(r.guessed) AS g
WHERE position(g IN r.word) = 0
),
'slots', (
SELECT coalesce(
jsonb_agg(CASE WHEN v_finished OR c = ANY(r.guessed) THEN c END ORDER BY ord),
'[]'::jsonb
)
FROM regexp_split_to_table(r.word, '') WITH ORDINALITY AS t(c, ord)
),
'lastWinner', r.last_winner,
'turnEndsAtMs', CASE WHEN r.turn_ends_at IS NULL THEN NULL ELSE (extract(epoch from r.turn_ends_at) * 1000)::bigint END,
'serverTimeMs', (extract(epoch from now()) * 1000)::bigint,
'players', jsonb_build_array(
jsonb_build_object('seat', 1, 'name', r.player1_name, 'score', r.score1, 'avatar', r.avatar1),
jsonb_build_object('seat', 2, 'name', r.player2_name, 'score', r.score2, 'avatar', r.avatar2)
)
);
END;
$function$;

CREATE OR REPLACE FUNCTION get_room(p_code text, p_player uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
v_room game_rooms;
BEGIN
SELECT * INTO v_room FROM game_rooms WHERE code = upper(btrim(p_code)) FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'room_not_found';
END IF;

IF v_room.player1_id IS DISTINCT FROM p_player AND v_room.player2_id IS DISTINCT FROM p_player THEN
RAISE EXCEPTION 'not_in_room';
END IF;

v_room := expire_turn(v_room);
RETURN room_view(v_room, p_player);
END;
$function$;

CREATE OR REPLACE FUNCTION guess_letter(p_code text, p_player uuid, p_letter text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
v_room game_rooms;
v_seat smallint;
v_guessed text[];
v_won boolean;
v_wrong_before integer;
BEGIN
SELECT * INTO v_room FROM game_rooms WHERE code = upper(btrim(p_code)) FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'room_not_found';
END IF;

v_seat := CASE
WHEN v_room.player1_id = p_player THEN 1
WHEN v_room.player2_id = p_player THEN 2
END;
IF v_seat IS NULL THEN
RAISE EXCEPTION 'not_in_room';
END IF;

v_wrong_before := v_room.wrong_count;
v_room := expire_turn(v_room);
IF v_room.wrong_count <> v_wrong_before THEN
RETURN room_view(v_room, p_player);
END IF;

IF v_room.status <> 'playing' THEN
RAISE EXCEPTION 'round_not_active';
END IF;
IF v_room.turn <> v_seat THEN
RAISE EXCEPTION 'not_your_turn';
END IF;
IF p_letter IS NULL OR p_letter !~ '^[A-ZÄÖÜß]$' THEN
RAISE EXCEPTION 'invalid_letter';
END IF;
IF p_letter = ANY(v_room.guessed) THEN
RAISE EXCEPTION 'already_guessed';
END IF;

v_guessed := array_append(v_room.guessed, p_letter);

IF position(p_letter IN v_room.word) > 0 THEN
v_won := NOT EXISTS (
SELECT 1 FROM regexp_split_to_table(v_room.word, '') AS c
WHERE NOT (c = ANY(v_guessed))
);

IF v_won THEN
UPDATE game_rooms
SET guessed = v_guessed,
status = 'won',
turn_ends_at = NULL,
last_winner = v_seat,
score1 = score1 + CASE WHEN v_seat = 1 THEN 1 ELSE 0 END,
score2 = score2 + CASE WHEN v_seat = 2 THEN 1 ELSE 0 END
WHERE id = v_room.id
RETURNING * INTO v_room;
ELSE
UPDATE game_rooms
SET guessed = v_guessed, turn_ends_at = now() + interval '5 seconds'
WHERE id = v_room.id
RETURNING * INTO v_room;
END IF;
ELSE
UPDATE game_rooms
SET guessed = v_guessed,
wrong_count = wrong_count + 1,
status = CASE WHEN wrong_count + 1 >= 6 THEN 'lost' ELSE status END,
turn = CASE WHEN wrong_count + 1 >= 6 THEN turn ELSE 3 - turn END,
turn_ends_at = CASE WHEN wrong_count + 1 >= 6 THEN NULL ELSE now() + interval '5 seconds' END
WHERE id = v_room.id
RETURNING * INTO v_room;
END IF;

RETURN room_view(v_room, p_player);
END;
$function$;

CREATE OR REPLACE FUNCTION join_room(p_code text, p_player uuid, p_name text, p_avatar text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
v_name text := clean_name(p_name);
v_room game_rooms;
BEGIN
SELECT * INTO v_room FROM game_rooms WHERE code = upper(btrim(p_code)) FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'room_not_found';
END IF;

IF v_room.player1_id = p_player OR v_room.player2_id = p_player THEN
RETURN room_view(v_room, p_player);
END IF;

IF v_room.player2_id IS NOT NULL THEN
RAISE EXCEPTION 'room_full';
END IF;

PERFORM assert_avatar(p_avatar);
IF p_avatar = v_room.avatar1 THEN
RAISE EXCEPTION 'avatar_taken';
END IF;

UPDATE game_rooms
SET player2_id = p_player, player2_name = v_name, avatar2 = p_avatar,
status = 'playing', turn_ends_at = now() + interval '5 seconds'
WHERE id = v_room.id
RETURNING * INTO v_room;

RETURN room_view(v_room, p_player);
END;
$function$;

CREATE OR REPLACE FUNCTION new_round(p_code text, p_player uuid, p_word text, p_hint text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
v_room game_rooms;
BEGIN
SELECT * INTO v_room FROM game_rooms WHERE code = upper(btrim(p_code)) FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'room_not_found';
END IF;
IF v_room.player1_id IS DISTINCT FROM p_player AND v_room.player2_id IS DISTINCT FROM p_player THEN
RAISE EXCEPTION 'not_in_room';
END IF;
IF v_room.status NOT IN ('won', 'lost') THEN
RAISE EXCEPTION 'round_not_finished';
END IF;

PERFORM assert_round_input(p_word, p_hint);

UPDATE game_rooms
SET word = p_word,
hint = p_hint,
guessed = '{}',
wrong_count = 0,
status = 'playing',
round = round + 1,
round_starter = 3 - round_starter,
turn = 3 - round_starter,
turn_ends_at = now() + interval '5 seconds',
last_winner = NULL
WHERE id = v_room.id
RETURNING * INTO v_room;

RETURN room_view(v_room, p_player);
END;
$function$;
