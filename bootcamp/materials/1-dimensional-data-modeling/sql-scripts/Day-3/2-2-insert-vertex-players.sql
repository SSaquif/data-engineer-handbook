-- we are getting the players from game_details table,
-- cause it has more data than 
-- the players or players_and_seasons tables used earlier

-- players
INSERT INTO vertices
WITH player_agg AS (
    SELECT
        player_id AS identifier,
        MAX(player_name) AS player_name, -- OR MIN, need agg func due to GROUP BY
        COUNT(1) AS num_of_games, -- same as COUNT(*) but excludes NULLs
        SUM(PTS) AS total_pts,
        ARRAY_AGG(DISTINCT team_id) AS teams_played_for
    FROM game_details
    GROUP BY player_id
)
SELECT
    identifier,
    'player'::vertex_type,
    JSON_BUILD_OBJECT(
        'player_name', player_name,
        'num_of_games', num_of_games,
        'total_pts', total_pts,
        'teams_played_for', teams_played_for
    ) AS properties
FROM player_agg;    