WITH last_season_scd AS (
    SELECT * FROM players_scd
    WHERE current_season = 2021
    AND end_season = 2021
), historical_scd AS (
    SELECT 
        player_name,
        scoring_class,
        is_active,
        start_season,
        end_season
    FROM players_scd
    WHERE current_season = 2021
    AND end_season < 2021
), this_season_data AS (
    SELECT * FROM players
    WHERE current_season = 2022
), unchanged_records AS (
    SELECT
        ts.player_name,
        ts.scoring_class, 
        ts.is_active,
        ls.start_season,
        ts.current_season as end_season
    FROM this_season_data ts
        JOIN last_season_scd ls 
        ON ts.player_name = ls.player_name
    -- where the scds have not changed
    WHERE ts.scoring_class = ls.scoring_class
    AND ts.is_active = ls.is_active       
), 
-- this is one of the complex part
changed_records AS (
    SELECT
        ts.player_name,
        -- run with and without unnest
        -- figure out the difference        
        UNNEST(ARRAY [
            ROW (
                ls.scoring_class,
                ls.is_active,
                ls.start_season,
                ls.end_season
            )::scd_type,
            ROW (
                ts.scoring_class,
                ts.is_active,
                ts.current_season,
                ts.current_season
            )::scd_type
        ]) as records
    FROM this_season_data ts
        LEFT JOIN last_season_scd ls 
        ON ts.player_name = ls.player_name
    WHERE (
        ts.scoring_class <> ls.scoring_class 
        OR ts.is_active <> ls.is_active
        ) OR ls.player_name IS NULL
), unnested_changed_records AS (
    SELECT 
        player_name,
        -- flatten the records  
        (records::scd_type).scoring_class as scoring_class,
        (records::scd_type).is_active as is_active,
        (records::scd_type).start_season as start_season,
        (records::scd_type).end_season as end_season
    FROM changed_records
), new_records AS (
    SELECT         
        ts.player_name,
        ts.scoring_class,
        ts.is_active,
        ts.current_season as start_season,
        ts.current_season as end_season
    FROM this_season_data ts
    LEFT JOIN last_season_scd ls
        ON ts.player_name = ls.player_name
    WHERE ls.player_name IS NULL    
)
-- select * FROM last_season_scd
-- select * FROM historical_scd
-- select * FROM this_season_data
-- select * FROM changed_records
-- SELECT * FROM unchanged_records
-- SELECT * FROM unnested_changed_records
-- SELECT * FROM new_records
SELECT * FROM historical_scd
UNION ALL
SELECT * FROM unchanged_records
UNION ALL
SELECT * FROM unnested_changed_records
UNION ALL
SELECT * FROM new_records
-- ORDER BY player_name, start_season;
-- Note: (AI) The final query combines all the records from the historical, unchanged, changed, and new records
-- this how add incremental data to the scd table
-- you are incrementally adding data to the scd table

-- assumtion: is_active and scoring_class are never NULL
-- because if they are NULL then the logic will not work

-- because in sql NULL <> NULL is false
-- NULL = NULL is false

-- But the query also has a sequential problem 
-- we are depending on yesterday's data to insert today's data
-- harder to backfill
