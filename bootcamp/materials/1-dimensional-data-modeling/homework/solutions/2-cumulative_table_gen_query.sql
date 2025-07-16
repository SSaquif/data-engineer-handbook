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