SELECT DISTINCT name
FROM app_store_apps ;

-- The longer an app lives, the more money you can make on it
-- app lifespan is determined by star rating
-- so which apps have the highest rating
SELECT DISTINCT name, 
	rating, 
	price,
	primary_genre
FROM app_store_apps
--WHERE rating = 5
	--AND price = '0.00'
ORDER BY rating DESC, price; 
--255 results