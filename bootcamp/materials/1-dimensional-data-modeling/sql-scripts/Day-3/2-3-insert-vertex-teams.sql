-- teams
-- the teams table has duplicate team_ids
-- so we need to deduplicate them first
INSERT INTO vertices
WITH deduped_teams AS (
    SELECT DISTINCT
        *,
        -- helps with deduplication
        -- in case of multiple rows with same team_id
        -- look into this window function
        -- adds row number to each row with same team_id
        -- first entry = 1, duplicates = 2, 3, etc.
        ROW_NUMBER() OVER (PARTITION BY team_id) AS row_num
    FROM teams
)
SELECT
    team_id AS identifier,
    'team'::vertex_type AS type,
    JSON_BUILD_OBJECT(
        'abbreviation', abbreviation,
        'nickname', nickname,
        'city', city,
        'arena', arena,
        'year_founded', yearfounded
    ) AS properties
FROM deduped_teams
WHERE row_num = 1; -- only take the first row for each team_id