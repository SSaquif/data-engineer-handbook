-- We will build the query by making use of CTEs
-- So Take the first select put it in a CTE
-- Write the 2nd Select
-- Then put that in a CTE, and so on 

-- Putting the first select in a CTE
-- and then writing the 2nd select
-- which adds the change tracking columns
WITH with_previous AS (
    SELECT 
        player_name,
        current_season,
        scoring_class,
        is_active,
        -- window function
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
)
SELECT *,
    -- this indicators tracks the change in value
    CASE 
        WHEN scoring_class <> previous_scoring_class THEN 1
        ELSE 0
    END AS scoring_class_change_indicator,
    CASE 
        WHEN is_active <> previous_is_active THEN 1
        ELSE 0
    END AS is_active_change_indicator
FROM with_previous;

-- This is the same query as above
-- but the second select is put in a CTE
WITH with_previous AS (
    SELECT 
        player_name,
        current_season,
        scoring_class,
        is_active,
        -- window function
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
	        ELSE 0
	    END AS scoring_class_change_indicator,
	    CASE 
	        WHEN is_active <> previous_is_active THEN 1
	        ELSE 0
	    END AS is_active_change_indicator
	FROM with_previous
)
SELECT * FROM with_indicators;