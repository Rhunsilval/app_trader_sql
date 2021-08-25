WITH app_query AS
(SELECT
	-- Case 1 - establish which store an app can be found in
	DISTINCT p.name AS app_name,
 	a.primary_genre,
 	p.category,
 	p.genres,
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
		WHEN (a.content_rating = '12+') THEN 'Teen'
		WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
		WHEN (a.content_rating = '17+') THEN 'Mature 17+'
		WHEN p.content_rating IS NULL THEN a.content_rating
		WHEN a.content_rating IS NULL THEN p.content_rating
	END AS content_rating,
-- Case 2 - combine p and a name columns
	CASE
		WHEN p.name IS NULL THEN a.name
		WHEN a.name IS NULL THEN p.name
		ELSE p.name END AS name,
 	-- window function to get row numbers
 	ROW_NUMBER() OVER (PARTITION BY p.name ORDER BY p.name)
FROM play_store_apps AS p
-- Joins on name
INNER JOIN app_store_apps AS a
ON p.name = a.name
WHERE p.rating >= '4'
 AND a.rating >= '4'
 AND a.primary_genre NOT LIKE 'Productivity'
 AND a.primary_genre NOT LIKE 'Social Networking'
 AND a.primary_genre NOT LIKE 'Productivity'
 AND a.primary_genre NOT LIKE 'Weather'
 AND a.primary_genre NOT LIKE 'Finance'
 AND a.primary_genre NOT LIKE 'Shopping'
 AND a.primary_genre NOT LIKE 'Sports'
 AND a.primary_genre NOT LIKE 'Travel'
 AND a.primary_genre NOT LIKE 'Food & Drink'
 AND a.primary_genre NOT LIKE 'Photo & Video'
 AND a.primary_genre NOT LIKE 'Catalogs'
 AND a.primary_genre NOT LIKE 'Business'
 AND a.primary_genre NOT LIKE 'Medical'
 AND a.primary_genre NOT LIKE 'Utilities'
 AND a.primary_genre NOT LIKE 'Health & Fitness'
 AND a.primary_genre NOT LIKE 'Reference'
ORDER BY android_review_count DESC)
SELECT *
FROM app_query
WHERE row_number = 1;