WITH app_query AS(
	SELECT
		-- Case 1 - establish which store an app can be found in
		CASE
			WHEN p.name IS NULL THEN 'iPhone'
			WHEN a.name IS NULL THEN 'Android'
			ELSE 'Both' END AS store,
		-- Case 2 - combine p and a name columns
		CASE
			WHEN p.name IS NULL THEN a.name
			WHEN a.name IS NULL THEN p.name
			ELSE p.name END AS name,
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
		(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*4000)::money -
			(CASE
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit,
		p.install_count AS play_installations,
		p.review_count::integer AS android_review_count,
		a.review_count::integer AS apple_review_count,
	-- CASE 3 - combine p category and a primary_genre - cleaned data with INITCAP and REPLACE to standardize 					categories between both
	INITCAP(
	CASE
		WHEN p.category IS NULL then REPLACE(a.primary_genre, '&', 'And')
		WHEN a.primary_genre IS NULL then p.category
		ELSE p.category END) AS category,
		-- CASE 4 - combine content ratings, privilege android data by converting apple data - converting doesn't work unless 		put first
	CASE
		WHEN (a.content_rating = '4+') THEN 'Everyone'
		WHEN (a.content_rating = '12+') THEN 'Everyone 10+'
		WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
		WHEN (a.content_rating = '17+') THEN 'Mature 17+'
		WHEN (p.content_rating = 'Teen') THEN 'Everyone 10+'
		WHEN p.content_rating IS NULL THEN a.content_rating
		WHEN a.content_rating IS NULL THEN p.content_rating
	END AS content_rating,
		--trying to get a window to give row numbers
		ROW_NUMBER() OVER (PARTITION BY p.name)
	FROM play_store_apps AS p
	FULL JOIN app_store_apps AS a
		ON p.name = a.name
		--WHERE p.rating > '4'
		--AND a.rating > '4'
	ORDER BY avg_rating DESC, investment_cost, play_installations)
SELECT *
FROM app_query
WHERE row_number = 1;