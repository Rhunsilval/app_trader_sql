--reference 
SELECT name,review_count
FROM play_store_apps
ORDER BY review_count DESC;

SELECT name,review_count
FROM app_store_apps
WHERE review_count::int <= 200000
ORDER BY review_count::int DESC;

--Assumptions
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
FROM app_store_apps AS iphone;

SELECT
	name,
	review_count,
	rating,
	ROUND((rating/.5), 1) AS longevity,
	content_rating,
	genres
FROM play_store_apps AS Android;
--INNER JOIN
SELECT iphone.name AS name, Android.name AS name, 
iphone.price::money AS iphone_price, Android.price::money AS Android_price,
CASE WHEN iphone.price <=1.00 THEN 10000.00
ELSE (iphone.price * 10000.000)END AS iphone_purchase_price,
SUM(iphone.review_count::int + Android.review_count) AS review_count,
iphone.rating AS iphone_rating,Android.rating AS Android_rating,
ROUND((iphone.rating/.5), 1) AS iphone_longevity,ROUND((Android.rating/.5), 1) AS Android_longevity,
genres,
primary_genre AS genres
FROM app_store_apps AS iphone
INNER JOIN play_store_apps AS Android
ON iphone.name = Android.name
GROUP BY iphone.name,Android.name,iphone.price,Android.price,iphone.rating,Android.rating,
Android.genres,iphone.primary_genre
ORDER BY review_count DESC;
--NAME cleanup
WITH Android AS(
SELECT
	LOWER(REPLACE(--removing characters to 
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(Android.name,'–','')
		,',','')
		,' ','')
		,'.','')
		,'!','')
		,'-','')
		,':','')) AS name,
		Android.rating
	FROM play_store_apps AS Android)
SELECT
	LOWER(REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(
		REPLACE(iphone.name,'–','')
		,',','')
		,' ','')
	,'.','')
	,'!','')
	,'-','')
	,':','')) AS name,
	Android.rating 
FROM app_store_apps AS iphone
LEFT JOIN Android
ON iphone.name = Android.name
ORDER BY rating;

SELECT *
FROM app_store_apps AS iphone
LEFT JOIN play_store_apps AS android
ON iphone.name = android.name;

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
	CASE WHEN p.rating IS NULL THEN a.rating
	WHEN a.rating IS NULL THEN p.rating
	ELSE p.rating END AS comb_rating,
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
ORDER BY a_reviews DESC;

--top communication apps by review count (play store) *note chose because communication is most reviewed play store app
WITH row_num AS (
	SELECT ROW_NUMBER() OVER(PARTITION BY genres ORDER BY review_count)AS review_count_num,
		ROW_NUMBER() OVER(PARTITION BY name) AS dupl_elim,
		name,genres,review_count
		FROM play_store_apps)
SELECT name,genres,review_count_num,review_count
FROM row_num
WHERE genres = 'Communication' AND dupl_elim = 1
ORDER BY review_count_num DESC;
--top games by review count * selected because games is most commonly reviewed appstore app
WITH a AS (
	SELECT name,primary_genre,CAST(review_count AS int) AS review_count
	FROM app_store_apps)
SELECT name,review_count
FROM a
WHERE primary_genre = 'Games'
ORDER BY review_count DESC;
--removing apple duplicates/clean/assumptions
WITH a AS (
SELECT name,ROW_NUMBER() OVER(PARTITION BY name) AS row_num,
	CASE WHEN price <= 1 THEN 10000
		ELSE (price * 10000) END AS purchase_price,
	size_bytes,currency,price,review_count,rating,
	CASE WHEN rating = 0.00 THEN 1
		ELSE ROUND((rating/.5)) END AS longevity,
	content_rating,primary_genre
	FROM app_store_apps)
SELECT name,CAST(review_count AS bigint),
4000*(longevity * 12) AS est_earnings,
longevity,rating,content_rating,primary_genre,CAST(purchase_price AS float)
FROM a
WHERE row_num = 1
ORDER BY est_earnings DESC ;
--removing playstore duplicates /clean/assumptions
WITH p AS(
	SELECT name, ROW_NUMBER() OVER(PARTITION BY name) AS row_num ,--create row # for filtering
	category,COALESCE(rating,0) AS rating,CAST(review_count AS bigint),
	REPLACE(TRIM('+' FROM install_count),',','') AS trimmed_install_count,
	install_count,type,		
	REPLACE(price,'$','') AS price,content_rating,genres
	FROM play_store_apps)
SELECT name,
CASE WHEN CAST(price AS float) <= 1.00 THEN 10000.00
ELSE (CAST(price AS float) * 10000.00 ) END AS purchase_price,
rating,
CASE WHEN rating = 0.00 THEN 1
	ELSE ROUND((rating/.5)) END AS longevity,
CASE WHEN rating = 0.00 THEN 48000
	ELSE ROUND((rating/.5),2)*48000 END AS est_earnings,
review_count,
content_rating,genres
FROM p
WHERE row_num = 1
ORDER BY est_earnings DESC;
--compare row counts (apple has 2 duplicated rows)
WITH row_number AS(
	SELECT name,CAST(review_count AS bigint),ROW_NUMBER() OVER(PARTITION BY name) AS row_num
	FROM app_store_apps)
SELECT name,review_count,row_num
FROM row_number
WHERE row_num = 1
ORDER BY review_count DESC;

SELECT COUNT(name)--7197
FROM app_store_apps;
--compare row counts (playstore has 1181 duplicated rows)
WITH row_number AS(
	SELECT name,CAST(review_count AS bigint),ROW_NUMBER() OVER(PARTITION BY name) AS row_num
	FROM play_store_apps)
SELECT name,review_count,row_num
FROM row_number
WHERE row_num = 1
ORDER BY review_count DESC;

SELECT COUNT(name) --10840 
FROM play_store_apps;
--group by concat genre
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
--joining apple store and playstore tables/top 10 apps
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
WHERE p.row_num = 1 
ORDER BY est_earnings DESC;
--group by genre
WITH cte AS(
SELECT CASE WHEN genres = primary_genre THEN genres
			ELSE CONCAT(genres,' ',primary_genre) END AS concat_genre,
CASE
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END
			AS potential_profit,
p.name AS google_name,a.name AS apple_name,
(p.review_count + a.review_count::int) AS total_review_count,
ROW_NUMBER() OVER(PARTITION BY p.name) AS row_num
		FROM play_store_apps AS p
		INNER JOIN app_store_apps AS a
		ON p.name = a.name)
SELECT concat_genre,SUM(total_review_count) AS total_genre_reviews,ROUND(AVG(potential_profit::numeric),2) AS avg_potential_profit
FROM cte
WHERE concat_genre LIKE '%Games%' AND row_num = 1
GROUP BY concat_genre
ORDER BY total_genre_reviews DESC
;
--test specific genre
WITH cte AS(
SELECT CASE WHEN genres = primary_genre THEN genres
			ELSE CONCAT(genres,' ',primary_genre) END AS concat_genre,
CASE
			WHEN p.price::money <= '$1.00' AND a.price::money <= '$1.00' THEN '$20,000'
			WHEN p.price::money <= '$1.00' AND a.price::money > '$1.00' THEN ('$10000' + (a.price::money*10000))
			WHEN p.price::money > '$1.00' AND a.price::money <= '$1.00' THEN ((p.price::money*10000) + '$10000')
			WHEN p.price::money > '$1.00' AND a.price::money > '$1.00' THEN (p.price::money + a.price::money)*10000
			ELSE '$0' END
			AS potential_profit,
p.name AS google_name,a.name AS apple_name,
(p.review_count + a.review_count::int) AS total_review_count,
ROW_NUMBER() OVER(PARTITION BY p.name) AS row_num
		FROM play_store_apps AS p
		INNER JOIN app_store_apps AS a
		ON p.name = a.name)
SELECT google_name,concat_genre,total_review_count,potential_profit
FROM cte
WHERE concat_genre = 'Casual Games' AND row_num = 1
ORDER BY total_review_count DESC
;
