INSERT INTO players_scd
WITH with_previous AS (
    SELECT 
        player_name,
        current_season,
        scoring_class,
        is_active,        
        LAG(scoring_class, 1) 
        OVER (
            PARTITION BY player_name 
            ORDER BY current_season
        ) AS previous_scoring_class,
        LAG(is_active, 1) 
        OVER (
            PARTITION BY player_name 
            ORDER BY current_season
        ) AS previous_is_active
    FROM players
    -- hardcoded to match the final table's current_season
    -- imagine this is our end date in a real world scenario
    WHERE current_season <= 2021 
), with_indicators AS (
	SELECT *,	    
	    CASE 
	        WHEN scoring_class <> previous_scoring_class THEN 1
	        WHEN is_active <> previous_is_active THEN 1
	        ELSE 0
	    END AS change_indicator
	FROM with_previous
), with_streaks AS ( 
	SELECT 
		* , 
		SUM(change_indicator) 
	    OVER (
	        PARTITION BY player_name 
	        ORDER BY current_season
	    ) AS streak_identifier
	FROM with_indicators 
)
-- note that the streak_identifier column was removed
-- from the select statement below
-- since it is not in players_scd table
SELECT 
    player_name,
    scoring_class,
    is_active,    
    MIN(current_season) AS start_season,
    MAX(current_season) AS end_season,
    2021 AS current_season -- hardcoded to match the where clause up top    
FROM with_streaks
GROUP BY player_name, streak_identifier, scoring_class, is_active
ORDER BY player_name, streak_identifier;