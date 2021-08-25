SELECT name, rating, category
FROM play_store_apps
WHERE rating IS NOT NULL
ORDER BY rating DESC;

-- The longer an app lives, the more money you can make on it
-- app lifespan is determined by star rating
-- so which apps have the highest rating
SELECT DISTINCT name,
	rating, 
	price,
	review_count,
	genres,
	category
FROM play_store_apps
--WHERE rating IS NOT NULL
--	AND price = '0'
ORDER BY price DESC, rating DESC;
--7594 results

-- let's try some things here, too:
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
	install_count,
	review_count,
	genres,
	category
FROM play_store_apps
WHERE rating > 4.5
	AND (install_count = '500,000,000+'
		OR install_count = '100,000,000+'
		OR install_count = '1,000,000,000+')
ORDER BY potential_profit DESC, install_count;

--SELECT DISTINCT install_count
--FROM play_store_apps;