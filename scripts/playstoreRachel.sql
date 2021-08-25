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

-- playing around with investment numbers:
WITH app_query AS(
	SELECT 
		DISTINCT p.name AS app_name,
		--a.name AS app_name,
		--trying to get a window to give row numbers
		ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),
		p.price::money AS play_price,
		a.price::money AS app_price,
		CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END AS investment_cost,
		ROUND(((p.rating + a.rating)/2),1) AS avg_rating,
	-- can i calculate profit potential?!  
	-- longevity in months (12 + 24*average star rating) 
		-- calculated based on 12-month increases every .5 ratings = 2.4 months for every .1 stars
	-- times 9000 (5000/month earnings from each store minus 1000/month marketing cost total)
	-- minus initial investment cost (CASE calculation above)
		(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*9000)::money - 
			(CASE 
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit
	-- turning play_installations into a# so it can sort properly
--		(REPLACE(TRIM('+' FROM install_count),',',''))::int AS play_installations,
--		(p.review_count + a.review_count::integer) AS total_reviews,
--		p.genres AS play_genre,
--		a.primary_genre AS app_genre,
--		p.content_rating AS play_content,
--		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY potential_profit DESC, investment_cost )
SELECT *
FROM app_query
WHERE row_number = 1
	AND avg_rating > 4.0;