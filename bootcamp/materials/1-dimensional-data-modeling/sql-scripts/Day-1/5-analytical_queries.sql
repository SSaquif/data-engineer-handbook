-- Find the first and last season for each player up until 2022.
-- Select
--     player_name,
--     (season_stats[1]::season_stats).pts AS first_season,
--     (season_stats[CARDINALITY(season_stats)]::season_stats).pts AS lastest_season
-- FROM players
-- WHERE current_season = 2022;


-- Which player has the most improvement when comparing first and last season?
-- usually this query would have to written with a group by
-- but since we have the season_stats array
-- we can do it without a group by
-- this improves performance greatly
Select
    player_name,
    case 
        when (season_stats[1]::season_stats).pts = 0 then 1
        when (season_stats[1]::season_stats).pts != 0
            then (season_stats[CARDINALITY(season_stats)]::season_stats).pts/(season_stats[1]::season_stats).pts
        else null
    end AS improvement_ratio    
FROM players
WHERE current_season = 2022
Order By improvement_ratio desc;


-- Here is an alternative way to write the query with group by
-- which is not as performant
-- WITH player_season_bounds AS (
--     SELECT
--         player_name,
--         MIN(season) AS first_season,
--         MAX(season) AS last_season
--     FROM player_seasons
--     GROUP BY player_name
-- ),
-- first_and_last_pts AS (
--     SELECT
--         ps.player_name,
--         MIN(CASE WHEN ps.season = psb.first_season THEN ps.pts END) AS first_pts,
--         MIN(CASE WHEN ps.season = psb.last_season THEN ps.pts END) AS last_pts
--     FROM player_seasons ps
--     JOIN player_season_bounds psb ON ps.player_name = psb.player_name
--     GROUP BY ps.player_name
-- )
-- SELECT
--     player_name,
--     CASE
--         WHEN first_pts = 0 THEN 1
--         WHEN first_pts IS NOT NULL THEN last_pts / first_pts
--         ELSE NULL
--     END AS improvement_ratio
-- FROM first_and_last_pts
-- ORDER BY improvement_ratio DESC;

-- player_season_bounds: Gets the MIN(season) and MAX(season) for each player.
-- first_and_last_pts: Uses conditional aggregation (with CASE) to extract pts
-- from both the first and last season in a single pass over player_seasons.
-- Final SELECT: Calculates the improvement_ratio with a safe CASE to avoid division by zero.