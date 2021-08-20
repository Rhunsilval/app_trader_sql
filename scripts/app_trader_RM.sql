--reference 
SELECT *
FROM play_store_apps
LIMIT 10;

SELECT DISTINCT name,category,review_count,rating
FROM play_store_apps
WHERE type = 'Free'
	AND review_count <1000000
ORDER BY rating ;

SELECT
	name,
	price,
	CAST((CASE WHEN price <= 1.00 THEN 10000
	ELSE (price*10000) END) AS money) AS purchase_cost,
	review_count,
	rating,
	ROUND((rating/.5), 1) AS longevity,
	content_rating,
	primary_genre AS genres
FROM app_store_apps AS iphone



