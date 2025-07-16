CREATE TYPE vertex_type AS ENUM(
    'player',
    'team',
    'game'
);

CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type,
    properties JSON, -- this is the map equivalent in pgSQL
    PRIMARY KEY (identifier, type)
);

CREATE TYPE edge_type AS ENUM(
    'plays_for', -- player to team edge, when they played for a team
    'plays_in', -- player to game edge, when they played in a game
    'plays_against', -- player to player edge, when they played against each other
    'shares_team' -- player to player edge, when they played together
);

CREATE TABLE edges (
    subject_identifier TEXT,
    subject_type vertex_type,
    object_identifier TEXT,
    object_type vertex_type,
    edge_type edge_type,
    properties JSON,
    -- apparently, there is debate about what
    -- the primary key should be here
    -- but it's essentially all the identifiers
    -- but optionally you could have an edge_id col and use that
    PRIMARY KEY (subject_identifier, subject_type, object_identifier, object_type, edge_type) 
);



