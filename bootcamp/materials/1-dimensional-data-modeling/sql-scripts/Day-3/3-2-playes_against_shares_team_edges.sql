-- Note
-- playes_with would be a better name then shares_team

-- Got to remove the duplicates again
-- we also put the previous WHERE row_num = 1 in a CTE
INSERT INTO edges 
WITH deduped_game_details AS ( 
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY player_id, game_id) AS row_num 
	FROM game_details
), filtered AS (
	SELECT * FROM deduped_game_details
	WHERE row_num = 1 -- only take the first row for each player_id and game_id
), aggregrated AS (
	SELECT
		f1.player_id AS subject_player_id,			
		f2.player_id AS object_player_id,		
		CASE 
			WHEN f1.team_id = f2.team_id THEN 'shares_team'::edge_type 
			ELSE 'plays_against'::edge_type 
		END AS edge_type,
		-- no of games played together or against each other
		COUNT(1) AS num_of_games, 
		-- total points scored when 
		-- both played together or against each other
		SUM(f1.PTS) AS player_1_pts, 
		SUM(f2.PTS) AS player_2_pts,
	    -- we can use MAX or MIN here, since we are grouping by player_id
	    -- non grouped columns need to be aggregated
		MAX(f1.player_name) AS subject_player_name,
		MAX(f2.player_name) AS object_player_name
	FROM filtered f1 JOIN filtered f2
		ON f1.game_id = f2.game_id 
		AND f1.player_id <> f2.player_id 
	-- this WHERE will prevent having both sets of edges like
	-- Michael Jordan - Scottie Pippen & Scottie Pippen - Michael Jordan 
	WHERE f1.player_id > f2.player_id 
	GROUP BY
		-- i think we can use aliases here
		f1.player_id,
		f2.player_id,
		edge_type
)
SELECT
	subject_player_id AS subject_identifier,
	'player'::vertex_type AS subject_type,
	object_player_id AS object_identifier,
	'player'::vertex_type AS object_type,
	edge_type,
	JSON_BUILD_OBJECT(
    'subject_player_name', subject_player_name,
    'object_player_name', object_player_name,
    'num_of_games', num_of_games,
    'subject_player_pts', player_1_pts,
    'object_player_pts', player_2_pts
  ) AS properties
FROM aggregrated;