WITH app_query AS(
	SELECT
		DISTINCT p.name AS play_name,
		a.name AS app_name,
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
	-- fixed the money since less than $1 = 10k, not just $0
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
			AS potential_profit,
		LEFT(p.install_count, -1) AS play_installations,
		(p.review_count + a.review_count::integer) AS total_reviews,
		p.genres AS play_genre,
		a.primary_genre AS app_genre,
		p.content_rating AS play_content,
		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY potential_profit DESC, play_installations)
SELECT *
FROM app_query
WHERE row_number = 1
	AND avg_rating > 4.0;













