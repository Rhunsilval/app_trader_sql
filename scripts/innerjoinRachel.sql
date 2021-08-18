SELECT a.name AS app_store_name,
	a.rating AS app_store_rating,
	p.rating AS play_store_rating,
	a.price AS app_store_price,
	p.price AS play_store_price,
	primary_genre AS app_store_genre, 
	category AS play_store_category
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
	ON a.name = p.name
ORDER BY app_store_rating DESC, play_store_rating DESC;