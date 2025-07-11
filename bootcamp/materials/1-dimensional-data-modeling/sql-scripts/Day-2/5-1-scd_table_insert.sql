-- This query is broken down into parts for clarity.
-- The main goal is to insert data
-- and have columns that track changes in the dimension
-- like how long were they elite or how long were they active

-- part 1, window functions
-- The lag(col,count) window function 
-- helps track the previous value of the scd columns 
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