-- 1. DDL for actors table
CREATE TYPE films AS (
    film text,
    votes integer,
    rating real,
    film_id text,
    film_year integer
);

CREATE TYPE quality_class AS ENUM (
    'star',
    'good',
    'average',
    'bad'
);

CREATE TABLE actors (
    actor_id text,
    actor text,
    quality_class quality_class,
    films films[],
    is_active boolean,
    current_year integer,
    PRIMARY KEY (actor_id, current_year)
);

-- 2. cumulative table generation query
DO $$
DECLARE
    x int;
    max_year int;
BEGIN
    SELECT min(year) - 1 FROM actor_films INTO x; -- 1970 - 1 = 1969 
    SELECT max(year) FROM actor_films INTO max_year; -- 2021
    WHILE x < max_year LOOP
        -- insert
        -- Cumulative table generation query for actors table
        INSERT INTO actors
        WITH yesterday AS (
            SELECT * from actors
            WHERE current_year = x
        ),
        today AS (
            SELECT * from actor_films
            WHERE year = x + 1
        ),
        -- beacause 1 actor can make multiple films in a year
        this_years_films AS(
            SELECT
                actorid as actor_id,        
                year,
                MAX(actor) AS actor,
                ARRAY_AGG(ROW(
                    film, 
                    votes, 
                    rating, 
                    filmid, 
                    year
                )::films) AS films,
                AVG(rating) AS rating       
            FROM today
            GROUP BY actorid, year
        )
        SELECT
            -- coalesce non changing dimensions
            coalesce(y.actor_id, t.actor_id) as actor_id,
            coalesce(y.actor, t.actor) as actor,
            CASE 
                WHEN t.rating > 8 THEN 'star'
                WHEN t.rating > 7 AND t.rating <= 8 THEN 'good'
                WHEN t.rating > 6 AND t.rating <= 7 THEN 'average'
                WHEN t.rating is NULL THEN y.quality_class
                ELSE 'bad'
            END::quality_class as quality_class,
            CASE
                WHEN y.films IS NULL AND t.films IS NOT NULL THEN t.films  
                WHEN t.films IS NULL AND y.films IS NOT NULL THEN y.films            
                ELSE y.films || t.films
            END as films,
            CASE
                WHEN t.year IS NOT NULL THEN true
                ELSE false
            END as is_active,
            coalesce(t.year, y.current_year+1) as current_year  
        FROM this_years_films t FULL OUTER JOIN yesterday y
            ON t.actor_id = y.actor_id;
        x:= x + 1;
    END LOOP;
END $$;

-- 3. ddl for actors_history_scd table
CREATE TABLE actors_history_scd (
    actor_id text,
    actor text,
    quality_class quality_class,
    is_active boolean,
    start_date integer, -- start of streak
    end_date integer, -- end of streak
    current_year integer, 
    PRIMARY KEY (actor_id, start_date) 
);

-- 4. backfill query for actors_history_scd
DO $$
DECLARE    
    max_year int;
BEGIN
    SELECT max(current_year) FROM actors INTO max_year; -- 2021   

    INSERT INTO actors_history_scd
    WITH with_previous AS (
        SELECT
            actor_id,
            actor,
            quality_class,
            is_active,
            current_year,
            LAG(quality_class, 1)
                OVER (PARTITION BY actor_id ORDER BY current_year) AS previous_quality_class,
            LAG(is_active, 1)
            OVER (PARTITION BY actor_id ORDER BY current_year) AS previous_is_active
        FROM actors
        WHERE current_year <= max_year 
    ),
    with_indicators AS (
        SELECT
            *,
            -- combining them to act like and OR operator
            CASE       
                WHEN quality_class <> previous_quality_class THEN 1            
                WHEN is_active <> previous_is_active THEN 1
                ELSE 0
            END AS is_changed
        FROM with_previous 
    ),
    with_change_streak AS (
        SELECT
            *,
            SUM(is_changed) OVER (
                PARTITION BY actor_id ORDER BY current_year
            ) AS change_streak
        FROM with_indicators
    )
    SELECT
        actor_id,
        MAX(actor) as actor,
        quality_class,
        is_active,
        MIN(current_year) AS start_date,
        MAX(current_year) AS end_date,
        max_year AS current_year-- change_streak,
    FROM with_change_streak
    GROUP BY actor_id, quality_class, is_active, change_streak
    ORDER BY actor_id, change_streak;
END $$;

-- 5. Incremental query for actors_history_scd        
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
SELECT * FROM new_records;