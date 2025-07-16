-- The game_details table has duplicates
-- so had to remove them first with the CTE 
-- and the where at the end
INSERT INTO edges
WITH deduped_game_details AS ( 
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY player_id, game_id) AS row_num 
	FROM game_details
)
-- the actual rows for the edge
SELECT 
	player_id AS subject_identifier,
	'player'::vertex_type AS subject_type, 
	game_id AS object_identifier, 
	'game'::vertex_type AS object_type, 
	'plays_in'::edge_type AS edge_type, 
	JSON_BUILD_OBJECT( 
		'start_position', start_position, 
	    'pts', PTS, 
	    'team_id', team_id,
	    'team_abbreviation', team_abbreviation
	) AS properties  
FROM deduped_game_details
WHERE row_num = 1; -- only take the first row for each player_id and game_id