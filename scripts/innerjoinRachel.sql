-- apps in both stores with 5-star ratings (longevity) and $0 initial cost (maximum investment)
WITH app AS (
	SELECT name AS app_name,
		rating AS app_rating,
		price AS app_price
	FROM app_store_apps
	WHERE rating = 5
		AND price = '0.00'),
play AS (
	SELECT name AS play_name,
		rating AS play_rating,
		price AS play_price
	FROM play_store_apps
	WHERE rating = 5.0
		AND price = '0')
SELECT app_name,
	app_rating,
	app_price,
	play_name,
	play_rating,
	play_price
FROM app
LEFT JOIN play
	ON app.app_name = play.play_name;
-- is not working?  on either left or inner join

--try again, simpler this time
SELECT a.name AS app_store_name,
	a.rating AS app_store_rating,
	p.rating AS play_store_rating,
	a.price AS app_store_price,
	p.price AS play_store_price,
	primary_genre AS app_store_genre, 
	category AS play_store_category
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
	ON a.name = p.name
ORDER BY app_store_rating DESC, play_store_rating DESC;
--553 results.  

-- what if it's just apps with 5 stars?
SELECT a.name AS app_store_name,
	a.rating AS app_store_rating,
	p.rating AS play_store_rating,
	a.price AS app_store_price,
	p.price AS play_store_price,
	primary_genre AS app_store_genre, 
	category AS play_store_category
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p
	ON a.name = p.name
WHERE a.rating = '5.0'
ORDER BY play_store_rating DESC;
-- gives me 10 results ... this can't be right
-- one of them is in there twice, another is $6.99 in both stores ... not a good option.

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

-- okay, trying it my way again.
SELECT 
	p.name AS play_name,
	a.name AS app_name,
	p.install_count,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name;
-- i get 553 results.  apps in both stores with same name

-- let's narrow it down.  i want top rated apps.
SELECT 
	p.name AS play_name,
	a.name AS app_name,
	p.install_count,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, install_count DESC;
--yes!  can i narrow it down more.  i don't have install counts, but i have review counts for both

SELECT 
	DISTINCT p.name AS play_name,
	a.name AS app_name,
	p.price AS play_price,
	a.price AS app_price,
	p.rating AS play_rating,
	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating,
	p.install_count AS play_installations,
--	p.review_count AS play_reviews,
--	a.review_count::integer AS app_reviews,
-- why are my app reviews text? fixed!
	(p.review_count + a.review_count::integer) AS total_reviews
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, play_installations DESC, total_reviews DESC;

-- can i do something with the price?  calculate initial investment price?
SELECT 
	DISTINCT p.name AS play_name,
	a.name AS app_name,
	p.price::money AS play_price,
	a.price::money AS app_price,
	CASE 
		WHEN p.price::money = '$0.00' AND a.price::money = '$0.00' THEN '$20,000'
		WHEN p.price::money = '$0.00' AND a.price::money > '$0.00' THEN ('$10000' + (a.price::money*10000))
		WHEN p.price::money > '$0.00' AND a.price::money = '$0.00' THEN ((p.price::money*10000) + '$10000')
		WHEN p.price::money > '$0.00' AND a.price::money > '$0.00' THEN (p.price::money + a.price::money)*10000
		ELSE '$0' END AS investment_cost,
--	p.rating AS play_rating,
--	a.rating AS app_rating,
	ROUND(((p.rating + a.rating)/2),2) AS avg_rating,
	p.install_count AS play_installations,
--	p.review_count AS play_reviews,
--	a.review_count::integer AS app_reviews,
-- why are my app reviews text? fixed!
	(p.review_count + a.review_count::integer) AS total_reviews,
	p.genres AS play_genre,
	a.primary_genre AS app_genre,
	p.content_rating AS play_content,
	a.content_rating AS app_content
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
	ON p.name = a.name
ORDER BY avg_rating DESC, investment_cost, play_installations;

-- can i get rid of duplicates?  the play store is the guilty party ... 
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
	-- times 4000 (5000/month earnings minus 1000/month marketing cost)
	-- minus initial investment cost (CASE calculation above)
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
	AND avg_rating > 4.0;
--246 results
