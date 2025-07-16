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

        
