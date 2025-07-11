-- Combine the 2 indicators into 1, 
-- because more indicators = more complicated to understand 
-- what's going on
-- so we are converging the 2 indicators into 1
-- But personally I would have kept them separate
-- because retirements and scoring class 
-- don't really have much in common
WITH with_previous AS (
    SELECT 
        player_name,
        current_season,
        scoring_class,
        is_active
        -- window function
        LAG(scoring_class, 1) ,
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
	    -- combining them like this acts like an OR operation
	    CASE 
	        WHEN scoring_class <> previous_scoring_class THEN 1
	        WHEN is_active <> previous_is_active THEN 1
	        ELSE 0
	    END AS change_indicator,
	FROM with_previous
)
SELECT * FROM with_indicators;