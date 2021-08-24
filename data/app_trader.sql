SELECT *
FROM app_store_apps;

SELECT *
FROM play_store_apps;

SELECT *
FROM app_store_apps INNER JOIN  play_store_apps ON app_store_apps.name = play_store_apps.name;

SELECT
	name,
	price,
	CAST((CASE WHEN price <= 1.00 THEN 10000
	ELSE (price*10000) END) AS money) AS purchase_cost,
	review_count,
	rating,
	ROUND((rating/.5), 1) AS longevity,
	content_rating,
	primary_genre AS genres
FROM app_store_apps AS iphone

SELECT DISTINCT(p.name),
	p.category,
	p.rating,
	p.review_count AS p_reviews,
	a.review_count AS a_reviews,
	p.install_count AS play_installs,
	p.type,
	p.price AS p_price,
	a.price AS a_price,
	p.content_rating,
	p.genres
FROM play_store_apps AS p
FULL JOIN app_store_apps AS a
ON p.name = a.name




-- Full Join with play store and combining columns
SELECT
-- combine iphone and google name columns - if one is null, take value from the other
	CASE WHEN p.name IS NULL THEN a.name
	WHEN a.name IS NULL THEN p.name
	ELSE p.name || '-' || a.name END AS combname,
	INITCAP(p.category) AS category,
-- effort to combine disparate categories  (didn't work right)
	CASE WHEN a.primary_genre IS NULL THEN p.genres
	WHEN p.genres IS NULL THEN a.primary_genre
	ELSE p.genres END AS subcategory,
-- need to distill into sub genres with cleaning
--	a.primary_genre,
--	p.genres,
	p.rating AS p_rating,
	p.review_count AS p_reviews,
	p.install_count AS play_installs,
	a.rating AS a_rating,
	a.review_count AS a_reviews,
	p.price AS p_price,
	a.price AS a_price,
	p.content_rating,
	a.content_rating,
-- if no title in play store, label it iphone app, if no name in iphone store, label it android - if matched name, label it both
	CASE WHEN p.name IS NULL THEN 'iPhone'
	WHEN a.name IS NULL THEN 'Android'
	ELSE 'Both' END AS Store
FROM play_store_apps AS p
FULL JOIN app_store_apps AS a
ON p.name = a.name
ORDER BY combname;


SELECT
	name,
	rating,
	(12+(24*rating)) AS longevity,
	price::money,
	CASE
		WHEN price::money <= '$1.00' THEN '$10,000'
		WHEN price::money > '$1.00' THEN (price::money*10000)
		ELSE '$0' END AS initial_cost,
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
WITH app_query AS(
	SELECT
		DISTINCT p.name AS play_name,
		a.name AS app_name,
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