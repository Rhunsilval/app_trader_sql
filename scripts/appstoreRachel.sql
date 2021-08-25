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

-- okay, let's try some things
SELECT 
	name,
	rating,
	(12+(24*rating)) AS longevity,
	price::money,
	CASE 
		WHEN price::money <= '$1.00' THEN '$10,000'
		WHEN price::money > '$1.00' THEN (price::money*10000)
		ELSE '$0' END AS initial_cost,
-- profit:  longevity * 4000 (5000 profit minus 1000 marketing)-initial cost
	(((12+(24*rating))*4000)::money -
		(CASE 
			WHEN price::money <= '$1.00' THEN '$10,000'
			WHEN price::money > '$1.00' THEN (price::money*10000)
			ELSE '$0' END)) 
		AS potential_profit,
	review_count::int,
	primary_genre
FROM app_store_apps
WHERE rating = 5.0
ORDER BY potential_profit DESC, review_count DESC;
	