-- First get all the unique player teams combinatios
INSERT INTO edges
WITH player_teams AS (
	SELECT
		player_id,
		team_id, 
		MIN(player_name) AS player_name,  
		MIN(team_abbreviation) AS team_abbreviation,		
		COUNT(DISTINCT game_id) AS num_of_games_played,  
		SUM(pts) as total_pts_for_team
	FROM game_details 
	GROUP BY player_id, team_id 
)
SELECT
    player_id AS subject_identifier,
    'player'::vertex_type AS subject_type,
    team_id AS object_identifier,
    'team'::vertex_type AS object_type,
    'plays_for'::edge_type AS edge_type,
    JSON_BUILD_OBJECT(    	    
	    'player_name', player_name,
        'team_abbreviation', team_abbreviation,
        'num_of_games_played', num_of_games_played,
        'total_pts_for_team', total_pts_for_team       
    ) AS properties
FROM player_teams
WHERE team_id IS NOT NULL; -- to avoid null edges 