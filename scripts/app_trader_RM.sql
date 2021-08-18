--reference 
SELECT DISTINCT name,category,review_count,rating
FROM play_store_apps
WHERE type = 'Free'
	AND review_count <1000000
ORDER BY rating ;

SELECT name,
	CASE WHEN rating BETWEEN 0 AND 
