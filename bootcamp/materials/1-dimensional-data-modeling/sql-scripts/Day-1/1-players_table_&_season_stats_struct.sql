-- struct
create type season_stats as (
    season integer,
    gp integer,
    pts real,
    reb real,
    ast real
);

-- needed later for the scoring class
create type scoring_class AS ENUM (
    'elite',
    'good',
    'average',
    'below average',
    'poor'
);
-- skipping age for now
-- except season_stats and current_season
-- the ohter dimensions are non changing
-- current season will be calculated cumulatively from the season_stats array
create table players (
    player_name text,
    height text,
    college text,
    country text,
    draft_year text,
    draft_round text,
    draft_number text,
    season_stats season_stats[],
    scoring_class scoring_class,
    years_since_last_season integer,
    current_season integer,
    primary key (player_name, current_season)
)
