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