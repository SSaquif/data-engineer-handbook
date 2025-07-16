-- Insert our games vertices
INSERT INTO vertices
SELECT
    game_id AS identifier,
    'game'::vertex_type AS type,
    JSON_BUILD_OBJECT(
        'pts_home', pts_home,
        'pts_away', pts_away,
        'winning_team', 
        CASE 
            WHEN home_team_wins = 1 THEN home_team_id
            ELSE visitor_team_id
        END
    ) AS properties
FROM games;