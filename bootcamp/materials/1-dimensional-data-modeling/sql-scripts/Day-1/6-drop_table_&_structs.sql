-- Drop the table first since it depends on the types
DROP TABLE IF EXISTS players;

-- Drop the enum type
DROP TYPE IF EXISTS scoring_class;

-- Drop the composite type
DROP TYPE IF EXISTS season_stats;
