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