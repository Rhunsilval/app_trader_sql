--select primary_genre,
--COUNT(primary_genre)
--FROM app_store_apps AS a
--INNER JOIN play_store_apps AS p
--ON a.name = p.name
--GROUP BY (primary_genre)
--ORDER BY COUNT(primary_genre) DESC;

--select category,
--COUNT(category)
--FROM play_store_apps AS p
--INNER JOIN app_store_apps AS a
--ON p.name = a.name

WITH app_query AS
(SELECT
-- Case 1 - establish which store an app can be found in
	CASE
		WHEN p.name IS NULL THEN 'iPhone'
		WHEN a.name IS NULL THEN 'Android'
		ELSE '1Both' END AS store,	
 	--DISTINCT
 	-- Case 2 - combine p and a name columns
	CASE
		WHEN p.name IS NULL THEN a.name
		WHEN a.name IS NULL THEN p.name
		ELSE p.name END AS name,
	-- window function to get row numbers
 	--ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name),	
 	-- CASE 2 - combine p category and a primary_genre - cleaned data with INITCAP and REPLACE to standardize categories 		between both
	--INITCAP(
	--CASE
	--	WHEN p.category IS NULL then REPLACE(a.primary_genre, '&', 'And')
	--	WHEN a.primary_genre IS NULL then REPLACE(p.category, '_', ' ')
	--ELSE REPLACE(p.category, '_', ' ') END) AS category,
	--android
 	a.primary_genre,
	p.genres,
 	p.install_count AS android_install_count,
	p.review_count AS android_review_count,
	-- convert apple_review_count to integer to match android column when pulling it in
	a.review_count::integer AS apple_review_count,
	--ratings - how best to combine, if we should?
	p.rating AS android_rating,
	a.rating AS apple_rating,
	--Calculate longevity for apps
	ROUND(((a.rating/.5 + p.rating/.5)/2), 1) AS estimated_longevity,
	-- dollas
	p.price::money AS android_price,
	a.price::money AS apple_price,
	--CASE 3 - calculate the cost of purchasing an app
	CASE
		WHEN p.price::money = '$0.00' AND a.price::money = '$0.00' THEN '$20,000'
		WHEN p.price::money = '$0.00' AND a.price::money > '$0.00' THEN ('$10000' + (a.price::money*10000))
		WHEN p.price::money > '$0.00' AND a.price::money = '$0.00' THEN ((p.price::money*10000) + '$10000')
		WHEN p.price::money > '$0.00' AND a.price::money > '$0.00' THEN (p.price::money + a.price::money)*10000
		ELSE '$0' END AS investment_cost,
	--CASE 4 -- calculate estimated profits for each app
	--CASE 5 - combine content ratings, privilege android data by converting apple data - converting doesn't work unless put first
	CASE
		WHEN (a.content_rating = '4+') THEN 'Everyone'
		WHEN (a.content_rating = '12+') THEN 'Everyone 12+'
		WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
		WHEN (a.content_rating = '17+') THEN 'Mature 17+'
		WHEN p.content_rating IS NULL THEN a.content_rating
		WHEN a.content_rating IS NULL THEN p.content_rating
	END AS content_rating
FROM play_store_apps AS p
-- Joins on name, keeps matches and those that don't match
FULL JOIN app_store_apps AS a
ON p.name = a.name
WHERE a.primary_genre NOT LIKE 'ENTERTAINMENT'
AND p.genres NOT LIKE 'Entertainment'
ORDER BY store, category)
SELECT *
FROM app_query
--WHERE row_number = 1;
--GROUP BY (category)
--ORDER BY COUNT(category) DESC;

