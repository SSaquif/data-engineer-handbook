CREATE TABLE players_scd (
	player_name TEXT,
    scoring_class scoring_class,
    is_active BOOLEAN,
    start_season INTEGER, -- start of the streak
    end_season INTEGER, -- end of the streak
    current_season INTEGER,
    PRIMARY KEY (player_name, start_season)
)

-- Question?
-- How did we decide the primary key?
-- Answer:
-- The primary key is the player_name and start_season.
-- This is because we want to track the changes 
-- in the player's scoring class and is_active status
-- over time, and the start_season indicates 
-- when the player started being in that state.
-- In certain cases we might also want to include end_season
-- (my Guess) if you are tracking scds separately i guess for example