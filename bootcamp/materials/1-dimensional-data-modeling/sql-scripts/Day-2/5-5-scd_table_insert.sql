-- Finally we do a group by
-- 	- to set the correct start and end range
-- 	- for each of our unique streaks for each player
-- 	- this collapses the redundant data into 1 row

-- get the correct start and end seasons for each unique combination of these streaks
-- the unique combination of streaks is defined by the player_name, scoring_class, and is_active status
-- ex: Michael Jordan has a streak of 1 for scoring_class = 'A' and is_active = true
-- then say nothing changes for 3 seasons, so those 3 seasons will be collapsed into one row
-- then say he changes to scoring_class = 'B', then that will be a new streak
-- so we will have two rows for Michael Jordan, one for scoring_class = 'A' 

-- How do we determine the columns for the Group By clause?
-- But basically it's the following
-- name or type or identifier of the table in this case the players_name
-- then the scd columns that we want to track, here scoring_class and is_active
-- then the cumulative tracker that tracks how long the dimension has been in a particular state
-- in this case streak_identifier

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
SELECT 
    player_name,
    scoring_class,
    is_active,
    streak_identifier, -- this is just for viewing purposes (not in the final table)
    MIN(current_season) AS start_season,
    MAX(current_season) AS end_season,
    2021 AS current_season -- hardcoded to match the where clause up top    
FROM with_streaks
GROUP BY player_name, streak_identifier, scoring_class, is_active
ORDER BY player_name, streak_identifier;

-- Why the GROUP BY?
-- We are grouping by player_name, streaks, scoring_class, and is_active
-- to ensure that we get the correct start and end seasons for each unique combination of these attributes
-- We are collapsing the data to get the start and end seasons for each streak