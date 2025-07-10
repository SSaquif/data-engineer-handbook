-- Loop to insert data
DO $$
DECLARE
    x int := 1995;
BEGIN
    WHILE x < 2022 LOOP
    -- Query Begins
    insert into players
    with yesterday as (
        select * from players
        where current_season = x
    ),
    today as (
        select * from player_seasons
        where season = x + 1
    )
    select
        -- coalescing the non changing dimensions
        coalesce(t.player_name, y.player_name) as player_name,
        coalesce(t.height, y.height) as height,
        coalesce(t.college, y.college) as college,
        coalesce(t.country, y.country) as country,
        coalesce(t.draft_year, y.draft_year) as draft_year,
        coalesce(t.draft_round, y.draft_round) as draft_round,
        coalesce(t.draft_number, y.draft_number) as draft_number,
        case when y.seasons is null 
            then array[ROW(
                t.season, 
                t.gp, 
                t.pts, 
                t.reb, 
                t.ast
            )::season_stats] -- need to do type casting
            else y.seasons || array[ROW(
                t.season, 
                t.gp, 
                t.pts, 
                t.reb,
                t.ast
            )::season_stats] -- else we concat the arrays
        end as season_stats,
        -- the following are analyical fields added at the end of the video
        case 
            when t.season is not null then 
                case
                    when t.pts > 20 then 'elite'
                    when t.pts > 15 then 'good'
                    when t.pts > 10 then 'average'
                    when t.pts > 5 then 'below average'
                    else 'poor'
                end::scoring_class        
            -- else get the scoring class from there last season of play 
            else y.scoring_class
        end as scoring_class,
        case 
            when t.season is not null then 0
            else y.years_since_last_season + 1
        end as years_since_last_season,
        coalesce(t.season, y.current_season+1) as current_season,
        case 
            when t.season is not null then true
            else false
        end as is_active
    from today t full outer join yesterday y
    on t.player_name = y.player_name;
    -- Query Ends
    x:= x + 1;
    END LOOP;
END $$;