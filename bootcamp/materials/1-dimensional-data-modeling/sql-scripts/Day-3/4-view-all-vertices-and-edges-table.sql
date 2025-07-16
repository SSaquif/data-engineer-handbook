-- Basically our graph model  
SELECT 
	* 
FROM vertices v
JOIN edges e
	ON  v.identifier = e.subject_identifier 
	AND v.type = e.subject_type