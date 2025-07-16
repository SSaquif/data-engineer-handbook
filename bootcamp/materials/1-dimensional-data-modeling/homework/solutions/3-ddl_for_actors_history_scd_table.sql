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