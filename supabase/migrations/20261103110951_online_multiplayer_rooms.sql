/*
# Online two-player rooms

1. New Tables
- `game_rooms`: one row per online game room. Stores the secret word and hint, the guessed letters, the number of wrong guesses, whose turn it is, the round number, both players' names and scores, and who won the last round.

2. Security
- Row level security is enabled on `game_rooms` with no policies, and all default table privileges are revoked from `anon` and `authenticated`. Nobody can read or change the table directly, so the secret word can never leak through the data interface.
- The app reaches the table only through these functions, which are the only things granted to `anon` and `authenticated`:
  - `create_room`, `join_room`, `get_room`, `guess_letter`, `new_round`.
- The helper `room_view` builds what a player is allowed to see. Unguessed letters stay hidden, and the full word is only shown once the round is over.
- Helper functions are not callable by the app.

3. Important Notes
- 1. Players are identified by a random ID stored in their browser, not by an account.
- 2. Turn rules: a correct letter keeps the turn with the same player. A wrong letter passes the turn to the other player and adds one wrong guess. Six wrong guesses lose the round with no point.
- 3. Whoever guesses the whole word wins the round and earns one point.
- 4. The starting player alternates from round to round.
*/

CREATE TABLE IF NOT EXISTS game_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  word text NOT NULL,
  hint text NOT NULL,
  guessed text[] NOT NULL DEFAULT '{}',
  wrong_count integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'playing', 'won', 'lost')),
  round integer NOT NULL DEFAULT 1,
  turn smallint NOT NULL DEFAULT 1 CHECK (turn IN (1, 2)),
  round_starter smallint NOT NULL DEFAULT 1 CHECK (round_starter IN (1, 2)),
  last_winner smallint CHECK (last_winner IN (1, 2)),
  player1_id uuid NOT NULL,
  player1_name text NOT NULL,
  player2_id uuid,
  player2_name text,
  score1 integer NOT NULL DEFAULT 0,
  score2 integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE game_rooms ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON game_rooms FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION clean_name(p_name text)
RETURNS text
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF p_name IS NULL OR char_length(btrim(p_name)) NOT BETWEEN 1 AND 20 THEN
    RAISE EXCEPTION 'invalid_name';
  END IF;
  RETURN btrim(p_name);
END;
$$;

CREATE OR REPLACE FUNCTION assert_round_input(p_word text, p_hint text)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF p_word IS NULL OR p_word !~ '^[A-ZÄÖÜß]{2,30}$' THEN
    RAISE EXCEPTION 'invalid_word';
  END IF;
  IF p_hint IS NULL OR char_length(p_hint) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'invalid_word';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION room_view(r game_rooms, p_player uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
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
      jsonb_build_object('seat', 1, 'name', r.player1_name, 'score', r.score1),
      jsonb_build_object('seat', 2, 'name', r.player2_name, 'score', r.score2)
    )
  );
END;
$$;

CREATE OR REPLACE FUNCTION create_room(p_player uuid, p_name text, p_word text, p_hint text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text;
  v_room game_rooms;
BEGIN
  PERFORM assert_round_input(p_word, p_hint);

  LOOP
    v_code := '';
    FOR i IN 1..6 LOOP
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    END LOOP;
    EXIT WHEN NOT EXISTS (SELECT 1 FROM game_rooms WHERE code = v_code);
  END LOOP;

  INSERT INTO game_rooms (code, word, hint, player1_id, player1_name)
  VALUES (v_code, p_word, p_hint, p_player, clean_name(p_name))
  RETURNING * INTO v_room;

  RETURN room_view(v_room, p_player);
END;
$$;

CREATE OR REPLACE FUNCTION join_room(p_code text, p_player uuid, p_name text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

  UPDATE game_rooms
  SET player2_id = p_player, player2_name = v_name, status = 'playing'
  WHERE id = v_room.id
  RETURNING * INTO v_room;

  RETURN room_view(v_room, p_player);
END;
$$;

CREATE OR REPLACE FUNCTION get_room(p_code text, p_player uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room game_rooms;
BEGIN
  SELECT * INTO v_room FROM game_rooms WHERE code = upper(btrim(p_code));
  IF NOT FOUND THEN
    RAISE EXCEPTION 'room_not_found';
  END IF;

  IF v_room.player1_id IS DISTINCT FROM p_player AND v_room.player2_id IS DISTINCT FROM p_player THEN
    RAISE EXCEPTION 'not_in_room';
  END IF;

  RETURN room_view(v_room, p_player);
END;
$$;

CREATE OR REPLACE FUNCTION guess_letter(p_code text, p_player uuid, p_letter text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room game_rooms;
  v_seat smallint;
  v_guessed text[];
  v_won boolean;
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
          last_winner = v_seat,
          score1 = score1 + CASE WHEN v_seat = 1 THEN 1 ELSE 0 END,
          score2 = score2 + CASE WHEN v_seat = 2 THEN 1 ELSE 0 END
      WHERE id = v_room.id
      RETURNING * INTO v_room;
    ELSE
      UPDATE game_rooms SET guessed = v_guessed WHERE id = v_room.id RETURNING * INTO v_room;
    END IF;
  ELSE
    UPDATE game_rooms
    SET guessed = v_guessed,
        wrong_count = wrong_count + 1,
        status = CASE WHEN wrong_count + 1 >= 6 THEN 'lost' ELSE status END,
        turn = CASE WHEN wrong_count + 1 >= 6 THEN turn ELSE 3 - turn END
    WHERE id = v_room.id
    RETURNING * INTO v_room;
  END IF;

  RETURN room_view(v_room, p_player);
END;
$$;

CREATE OR REPLACE FUNCTION new_round(p_code text, p_player uuid, p_word text, p_hint text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
      last_winner = NULL
  WHERE id = v_room.id
  RETURNING * INTO v_room;

  RETURN room_view(v_room, p_player);
END;
$$;

REVOKE ALL ON FUNCTION clean_name(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION assert_round_input(text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION room_view(game_rooms, uuid) FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION create_room(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION join_room(text, uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION get_room(text, uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION guess_letter(text, uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION new_round(text, uuid, text, text) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION create_room(uuid, text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION join_room(text, uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_room(text, uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION guess_letter(text, uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION new_round(text, uuid, text, text) TO anon, authenticated;
