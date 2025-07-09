-- This solves the run length encoding problem
-- In the sense that origanally all the players are not in order in the player_seasons table
-- we would have to run a SORT each time, which is expensive
-- BUT with our cunulative table design
-- we have essentialy used run length encoding
-- and now we have to a way to unnest the array
-- without having to sort the data
-- We keep the temporal data together
-- in this case the season_stats array
-- this can be very powerful

-- We can unnest the array like this
-- with a CTE = Common Table Expression
-- AND it will ALWAYS be SORTED
with unnested as (
    select 
        player_name,
        unnest(season_stats)::season_stats as season_stats
    from players
    where current_season = 2001 
)
select
    player_name,
    (season_stats::season_stats).*
from unnested;

-- If users now need to do a join with the players table
-- they can do it in the select inside the CTE
-- so you do the join and unnest it, but everything is still sorted
