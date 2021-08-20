SELECT 
	name
	FROM app_store_apps
UNION
	SELECT
	name
	FROM play_store_apps
ORDER BY name DESC;

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

SELECT*
FROM
app_store_apps
INNER JOIN play_store_apps
ON app_store_apps.name=play_store_apps.name


