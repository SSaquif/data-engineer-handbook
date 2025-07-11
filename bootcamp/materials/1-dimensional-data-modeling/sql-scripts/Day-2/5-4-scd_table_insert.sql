-- Add a select to calculate the change streak
-- This is what we are looking for 
-- when building this `SCD` tables, 
-- we want to know how long a they stay a particular value.

-- What is streak identifier?
-- It basically tracks how many times 
-- a player has changed their scoring class 
-- or how many times they have changed their is_active status.
-- i.e. how many times the slow moving dimension has changed
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
), with_indicators AS (
	SELECT *,	    
	    CASE 
	        WHEN scoring_class <> previous_scoring_class THEN 1
	        WHEN is_active <> previous_is_active THEN 1
	        ELSE 0
	    END AS change_indicator
	FROM with_previous
)
SELECT 
	* , 
	SUM(change_indicator) 
    OVER (
        PARTITION BY player_name 
        ORDER BY current_season
    ) AS streak_identifier
FROM with_indicators;

-- Then we do the same thing we did in part 2
-- we put the select in a CTE
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
SELECT * FROM with_streaks;