/*
# Add player avatars to online rooms

Plain-English summary: each online player now picks a character (animal, human, or fantasy creature) when they create or join a room. The room stores both choices and shows them on the scoreboard.

1. Modified Tables
- `game_rooms`
  - `avatar1` (text, nullable): avatar chosen by player 1. Null for rooms created before this change.
  - `avatar2` (text, nullable): avatar chosen by player 2.

2. Modified Functions
- `create_room` now takes `p_avatar` and validates it. The old four-argument version is removed.
- `join_room` now takes `p_avatar`, validates it, and rejects an avatar already used by player 1 (`avatar_taken`). The old three-argument version is removed.
- `room_view` includes each player's avatar in the `players` list.

3. New Helper
- `assert_avatar(p_avatar)` raises `invalid_avatar` unless the value is one of the allowed avatar ids.

4. Security
- The helper is not callable by public, anon, or authenticated roles.
- The two public functions keep EXECUTE only for `anon` and `authenticated`.
- No table grants or policies change; `game_rooms` stays fully locked and is reached only through functions.

5. Notes
- No data is removed or changed. Existing rooms keep their rows with null avatars.
- Re-running this migration is safe: columns use IF NOT EXISTS, functions use CREATE OR REPLACE, and old overloads use DROP IF EXISTS.
*/

ALTER TABLE game_rooms ADD COLUMN IF NOT EXISTS avatar1 text;
ALTER TABLE game_rooms ADD COLUMN IF NOT EXISTS avatar2 text;

CREATE OR REPLACE FUNCTION assert_avatar(p_avatar text)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $function$
BEGIN
IF p_avatar IS NULL OR p_avatar NOT IN (
'fox', 'bear', 'frog', 'owl', 'panda', 'octopus', 'lion', 'penguin',
'astronaut', 'artist', 'scientist',
'dragon', 'unicorn', 'wizard', 'fairy', 'mermaid', 'vampire'
) THEN
RAISE EXCEPTION 'invalid_avatar';
END IF;
END;
$function$;

REVOKE ALL ON FUNCTION assert_avatar(text) FROM PUBLIC, anon, authenticated;

DROP FUNCTION IF EXISTS create_room(uuid, text, text, text);
DROP FUNCTION IF EXISTS join_room(text, uuid, text);

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
'players', jsonb_build_array(
jsonb_build_object('seat', 1, 'name', r.player1_name, 'score', r.score1, 'avatar', r.avatar1),
jsonb_build_object('seat', 2, 'name', r.player2_name, 'score', r.score2, 'avatar', r.avatar2)
)
);
END;
$function$;

CREATE OR REPLACE FUNCTION create_room(p_player uuid, p_name text, p_avatar text, p_word text, p_hint text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
v_code text;
v_room game_rooms;
BEGIN
PERFORM assert_round_input(p_word, p_hint);
PERFORM assert_avatar(p_avatar);

LOOP
v_code := '';
FOR i IN 1..6 LOOP
v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
END LOOP;
EXIT WHEN NOT EXISTS (SELECT 1 FROM game_rooms WHERE code = v_code);
END LOOP;

INSERT INTO game_rooms (code, word, hint, player1_id, player1_name, avatar1)
VALUES (v_code, p_word, p_hint, p_player, clean_name(p_name), p_avatar)
RETURNING * INTO v_room;

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
SET player2_id = p_player, player2_name = v_name, avatar2 = p_avatar, status = 'playing'
WHERE id = v_room.id
RETURNING * INTO v_room;

RETURN room_view(v_room, p_player);
END;
$function$;

REVOKE ALL ON FUNCTION create_room(uuid, text, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION create_room(uuid, text, text, text, text) TO anon, authenticated;

REVOKE ALL ON FUNCTION join_room(text, uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION join_room(text, uuid, text, text) TO anon, authenticated;
