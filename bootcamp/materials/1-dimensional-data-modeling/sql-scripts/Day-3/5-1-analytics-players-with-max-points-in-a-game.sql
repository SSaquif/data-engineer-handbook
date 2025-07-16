-- The annoying JSON properties 
-- is they are treated as strings
-- so we have to cast them to integers or other types
-- also removing the nulls
WITH with_nulls AS (
	SELECT
		v.properties->>'player_name' AS player_name,  
		MAX(CAST(e.properties->>'pts' AS integer)) AS player_max_pts_in_game  	
	FROM vertices v
	JOIN edges e
		ON e.subject_identifier = v.identifier 
		AND e.subject_type = v.type
	GROUP BY player_name
	ORDER BY player_max_pts_in_game DESC
)
SELECT * FROM with_nulls 
WHERE player_max_pts_in_game IS NOT null