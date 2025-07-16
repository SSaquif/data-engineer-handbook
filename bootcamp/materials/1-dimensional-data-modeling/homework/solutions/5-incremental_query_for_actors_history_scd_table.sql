CREATE TYPE actor_scd_type AS (
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
);

WITH last_season_scd AS (
    SELECT * FROM actors_history_scd
    WHERE current_year = 2020
    AND end_date = 2020
)
, historical_scd AS (
    SELECT 
        actor_id,
        actor,
        quality_class,
        is_active,
        start_date,
        end_date        
    FROM actors_history_scd
    WHERE current_year = 2020
    AND end_date < 2020
), this_year_data AS (
    SELECT * FROM actors
    WHERE current_year = 2021
), unchanged_records AS (
    SELECT 
        tyd.actor_id,
        tyd.actor,
        tyd.quality_class, 
        tyd.is_active,
        lss.start_date,
        tyd.current_year as end_date
    FROM this_year_data tyd
    JOIN last_season_scd lss 
        ON tyd.actor_id = lss.actor_id
    -- where the scds have not changed
    WHERE tyd.quality_class = lss.quality_class
    AND tyd.is_active = lss.is_active
),
changed_records AS (
    SELECT 
        tyd.actor_id,
        tyd.actor,        
        UNNEST(ARRAY [
            ROW (
                lss.quality_class,
                lss.is_active,
                lss.start_date,
                lss.end_date
            )::actor_scd_type,
            ROW (
                tyd.quality_class,
                tyd.is_active,
                tyd.current_year,
                tyd.current_year
            )::actor_scd_type
        ]) as records
    FROM this_year_data tyd
    LEFT JOIN last_season_scd lss
        ON tyd.actor_id = lss.actor_id
    WHERE (
        tyd.quality_class <> lss.quality_class 
        OR tyd.is_active <> lss.is_active
        ) OR lss.actor_id IS NULL
), unnested_changed_records AS (
    SELECT 
        actor_id,
        actor,
        (records::actor_scd_type).quality_class AS quality_class,
        (records::actor_scd_type).is_active AS is_active,
        (records::actor_scd_type).start_date AS start_date,
        (records::actor_scd_type).end_date AS end_date
    FROM changed_records    
), new_records AS (
    SELECT         
        tyd.actor_id,
        tyd.actor,
        tyd.quality_class,
        tyd.is_active,
        tyd.current_year AS start_date,
        tyd.current_year AS end_date
    FROM this_year_data tyd
    LEFT JOIN last_season_scd lss
        ON tyd.actor_id = lss.actor_id
    WHERE lss.actor_id IS NULL
)
SELECT * FROM historical_scd
UNION ALL
SELECT * FROM unchanged_records
UNION ALL
SELECT * FROM unnested_changed_records
UNION ALL
SELECT * FROM new_records
        

    



        
    

    