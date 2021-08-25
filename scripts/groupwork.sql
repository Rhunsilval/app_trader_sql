-- Erin's code:
SELECT
	-- Case 1 - establish which store an app can be found in
	CASE
		WHEN p.name IS NULL THEN 'iPhone'
		WHEN a.name IS NULL THEN 'zAndroid'
		ELSE 'Both' END AS store,
	-- Case 2 - combine p and a name columns
	CASE
		WHEN p.name IS NULL THEN a.name
		WHEN a.name IS NULL THEN p.name
		ELSE p.name END AS name,
	-- CASE 3 - combine p category and a primary_genre - cleaned data with 		INITCAP and REPLACE to standardize categories between both
	INITCAP(
	CASE
		WHEN p.category IS NULL then REPLACE(a.primary_genre, '&', 				'And')
		WHEN a.primary_genre IS NULL then p.category
		ELSE p.category END) AS category,
	p.install_count AS android_install_count,
	p.review_count AS android_review_count,
	-- convert apple_review_count to integer to match android column when 		pulling it in
	a.review_count::integer AS apple_review_count,
	--ratings - how best to combine?
	p.rating,
	a.rating AS apple_rating,
	--CASE 5 - calculate longevity for apps
	CASE
		WHEN p.rating IS NULL THEN
		ROUND((a.rating/.5), 1)
		WHEN a.rating IS NULL THEN
		ROUND((p.rating/.5), 1)
		ELSE ROUND(((a.rating/.5 + p.rating/.5)/2), 1)
		END AS estimated_longevity,
	-- dollas
	p.price::money AS android_price,
	a.price::money AS apple_price,
--Rachel's redoing of the columns:
	--p.price AS android_price,
	--a.price AS apple_price,
	--CASE 6 - calculate the cost of purchasing an app
	--CASE 7 -- calculate estimated profits for each app
	--CASE 8 - combine content ratings, privilege android data by 			converting apple data - converting doesn't work unless put first
	CASE
	WHEN (a.content_rating = '4+') THEN 'Everyone'
	WHEN (a.content_rating = '12+') THEN 'Teen'
	WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
	WHEN (a.content_rating = '17+') THEN 'Mature 17+'
	WHEN p.content_rating IS NULL THEN a.content_rating
	WHEN a.content_rating IS NULL THEN p.content_rating
	END AS content_rating
FROM
	-- subquery to filter results and start cleaning - this is where the query starts, and what we'll have to start with when beginning SELECT at the top
	(SELECT
		name,
		REPLACE(category, '_',' ') AS category,
		review_count,
		install_count,
	-- if you don't name your column after the REPLACE function the column 		will be called REPLACE and the query will not recognize p.price:
		REPLACE(price,'$','') AS price,
		rating,
	 	content_rating
		FROM play_store_apps
	 -- Remove apps from play_store_apps with less than 50 reviews - also removes null ratings and review counts (I think this isn't working)
		WHERE review_count > 50
	) AS p
-- Joins on name but also keeps results that don't match, allows us to select columns from a
FULL JOIN app_store_apps AS a
ON p.name = a.name
-- Remove apps from app_store_apps with less than 50 reviews (this isn't working)
--WHERE a.review_count > '50'
-- Rachel: trying to remove nulls from longevity and ratings
--WHERE estimated_longevity IS NOT NULL
	--AND rating IS NOT NULL
	--AND apple_rating IS NOT NULL
-- order by longevity
ORDER BY estimated_longevity DESC
--can't get rid of the nulls - longevity is not a column, it's a calculation.  Can do order by, though - 10 years start at row 66
OFFSET 66 ROWS;

--ERIN'S CODE + MY CODE:
WITH app_query AS
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
WHERE row_number = 1;
--results in 175 rows


--RYAN's CODE
WITH a AS (					--apple store cte
SELECT LOWER(REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(apple.name,'–','')
		,',','')
		,' ','')
		,'.','')
		,'!','')
		,'-','')
		,':','')) AS name,
	ROW_NUMBER() OVER(PARTITION BY name) AS row_num, --create row num for filtering duplicates
	CASE WHEN price <= 1 THEN 10000
		ELSE (price * 10000) END AS purchase_price,
	size_bytes,currency,price,review_count,rating,
	CASE WHEN rating = 0.00 THEN 1
		ELSE ROUND((rating/.5)) END AS longevity,
	content_rating,primary_genre
	FROM app_store_apps AS apple
	ORDER BY price DESC),	
	p AS(					--playstore cte							
	SELECT LOWER(REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(google.name,'–','')
		,',','')
		,' ','')
		,'.','')
		,'!','')
		,'-','')
		,':','')) AS name,
	ROW_NUMBER() OVER(PARTITION BY name) AS row_num ,--create row # for filtering duplicates
	category,COALESCE(rating,0) AS rating,CAST(review_count AS bigint),
	REPLACE(TRIM('+' FROM install_count),',','') AS trimmed_install_count,
	install_count,type,
	CASE WHEN rating = 0.00 THEN 1
		ELSE ROUND((rating/.5)) END AS longevity,
	REPLACE(price,'$','') AS price,content_rating,genres
	FROM play_store_apps AS google
	ORDER BY price DESC)
SELECT
CASE WHEN p.name IS NULL THEN a.name
	WHEN a.name IS NULL THEN p.name
	ELSE a.name END AS combname,
(a.review_count::int + p.review_count::int) AS total_review_count,--generally combining apple and google columns
ROUND(((4000*(a.longevity * 12))+ (4000*(p.longevity * 12))/2),2) AS est_earnings,
ROUND((a.longevity + p.longevity)/2,2) AS avg_longevity,
ROUND((a.rating + p.rating)/2,2) AS avg_rating,
	CASE WHEN p.genres = a.primary_genre THEN p.genres
		ELSE CONCAT(p.genres,' ',a.primary_genre) END AS concat_genre,
CONCAT(p.content_rating,'-',a.content_rating) AS concat_rating,
CAST(a.purchase_price AS float) AS apple_purch_price,
CASE WHEN p.price::float <= 1 THEN 10000
		ELSE (p.price::float * 10000) END AS goog_purchase_price
FROM a
LEFT JOIN p
	ON a.name = p.name
WHERE p.row_num = 1 AND ROUND((a.longevity + p.longevity)/2,2)>= 9
ORDER BY est_earnings DESC;
--group by concat genre
