

/*WITH app_query AS(
	SELECT
		DISTINCT p.name AS play_name,
		a.name AS app_name,
		--trying to get a window to give row numbers
		ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),
		p.price::money AS play_price,
		a.price::money AS app_price,
		CASE
			WHEN p.price::money = '$0.00' AND a.price::money = '$0.00' THEN '$20,000'
			WHEN p.price::money = '$0.00' AND a.price::money > '$0.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$0.00' AND a.price::money = '$0.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$0.00' AND a.price::money > '$0.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END AS investment_cost,
		ROUND(((p.rating + a.rating)/2),2) AS avg_rating,
		p.install_count AS play_installations,
		(p.review_count + a.review_count::integer) AS total_reviews,
		p.genres AS play_genre,
		a.primary_genre AS app_genre,
		p.content_rating AS play_content,
		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY avg_rating DESC, investment_cost, play_installations)
SELECT *
FROM app_query
WHERE row_number = 1 AND avg_rating > ;*/

/*WITH app_query AS
(SELECT
	DISTINCT p.name AS app_name,
	-- window function to get row numbers
 	ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),	
 	-- CASE 2 - combine p category and a primary_genre - cleaned data with INITCAP and REPLACE to standardize categories 		between both
	INITCAP(
	CASE
		WHEN p.category IS NULL then REPLACE(a.primary_genre, '&', 'And')
		WHEN a.primary_genre IS NULL then REPLACE(p.category, '_', ' ')
	ELSE REPLACE(p.category, '_', ' ') END) AS category,
	--android
	p.install_count AS android_install_count,
	p.review_count AS android_review_count,
	-- convert apple_review_count to integer to match android column when pulling it in
	a.review_count::integer AS apple_review_count,
	--ratings - how best to combine, if we should?
	p.rating AS android_rating,
	a.rating AS apple_rating,
	--Calculate longevity for apps
	ROUND(((a.rating/.5 + p.rating/.5)/2), 1) AS estimated_longevity,
	--SUM((p.rating + a.rating)/2) AS star_rating,
 -- dollas
	p.price::money AS android_price,
	a.price::money AS apple_price,
	--CASE 3 - calculate the cost of purchasing an app
	(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*4000)::money -
			(CASE
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit,
 
 	CASE
		WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
		WHEN p.price::money <= '$0.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
		WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
		WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
		ELSE '$0' END AS investment_cost,
	--CASE 4 -- calculate estimated profits for each app
	--CASE 5 - combine content ratings, privilege android data by converting apple data - converting doesn't work unless put first
	CASE
		WHEN (a.content_rating = '4+') THEN 'Everyone'
		WHEN (a.content_rating = '12+') THEN 'Teen'
		WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
		WHEN (a.content_rating = '17+') THEN 'Mature 17+'
		WHEN p.content_rating IS NULL THEN a.content_rating
		WHEN a.content_rating IS NULL THEN p.content_rating
	END AS content_rating
FROM play_store_apps AS p
-- Joins on name, only keeps matches
INNER JOIN app_store_apps AS a
ON p.name = a.name
WHERE p.rating > '4'
AND a.rating > '4'
ORDER BY apple_review_count)
SELECT *
FROM app_query
WHERE row_number = 1;*/

/*WITH app_query AS(
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
		(((12+(24*(ROUND(((p.rating + a.rating)/2),1))))*4000)::money -
			(CASE
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END))
			AS potential_profit,
		p.install_count AS play_installations,
		(p.review_count + a.review_count::integer) AS total_reviews,
		p.genres AS play_genre,
		a.primary_genre AS app_genre,
		p.content_rating AS play_content,
		a.content_rating AS app_content
	FROM play_store_apps AS p
	INNER JOIN app_store_apps AS a
		ON p.name = a.name
	ORDER BY avg_rating DESC, investment_cost, play_installations)
SELECT *
FROM app_query
WHERE row_number = 1
	AND avg_rating > 4.0;/
	
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
		p.install_count AS play_installations,
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
		p.install_count AS play_installations,
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
		p.install_count AS play_installations,
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
	AND avg_rating > 4.0;*/

/*WITH app_query AS(
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
		p.install_count AS play_installations,
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
	AND avg_rating > 4.0;*/
	
	
	
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
WHERE row_number = 1
ORDER BY investment_cost DESC;
	
	
	
	
	