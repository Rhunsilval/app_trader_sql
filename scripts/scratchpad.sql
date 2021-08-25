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
	-- CASE 3 - combine p category and a primary_genre - cleaned data with 		INITCAP and REPLACE to standardize categories between both
	INITCAP(CASE
			WHEN p.category IS NULL then REPLACE(a.primary_genre, '&', 				'And')
			WHEN a.primary_genre IS NULL then p.category
			ELSE p.category END) AS category,
	p.install_count AS android_install_count,
	p.review_count AS android_review_count,
	-- convert apple_review_count to integer to match android column when 		pulling it in
	a.review_count::integer AS apple_review_count, 
	-- dollas
	p.price::money AS android_price,
	a.price::money AS apple_price,
	-- CASE 4 - combine content ratings, privilege android data by 			converting apple data
	CASE
	WHEN p.content_rating IS NULL THEN a.content_rating
	WHEN a.content_rating IS NULL THEN p.content_rating
	--ELSE p.content_rating END AS content_rating,
	WHEN (a.content_rating = '4+') THEN 'Everyone'
	WHEN (a.content_rating = '12+') THEN 'Teen'
	WHEN (a.content_rating = '9+') THEN 'Everyone 10+'
	WHEN (a.content_rating = '17+') THEN 'Mature 17+'
	--ELSE p.content_rating
	END AS content_rating
FROM
	-- subquery to filter results and start cleaning - this is where the query starts, and what we'll have to work with when beginning SELECT at the top
	(SELECT
	name,
	REPLACE(category, '_',' ') AS category,
	review_count,
	install_count,
	-- if you don't name your column after the REPLACE function the column will be called REPLACE and the query will not recognize p.price:
	REPLACE(price,'$','') AS price,
	content_rating
		FROM play_store_apps
	 -- Remove apps from play_store_apps with less that 500 reviews and null for reviews and ratings
		WHERE review_count IS NOT NULL
		AND content_rating IS NOT NULL
		AND review_count > 500
	) AS p
-- Joins on name but keeps results that don't match, allows us to select columns from a
FULL JOIN app_store_apps AS a
ON p.name = a.name
-- Remove apps from app_store_apps with less than 500 reviews and null for review count
WHERE a.review_count IS NOT NULL
AND a.review_count > '500';

-- query for subquery
SELECT
	name,
	REPLACE(category, '_',' ') as category,
	review_count,
	install_count,
	price,
	content_rating
FROM play_store_apps
WHERE review_count IS NOT NULL
AND content_rating IS NOT NULL
AND review_count > 500;



--genre/cat queries
SELECT DISTINCT primary_genre
FROM app_store_apps

SELECT DISTINCT category
FROM play_store_apps

-- YA NO
-- Full Join with play store and combining columns
SELECT
	-- if no title in play store, label it iphone app, if no name in iphone store, 	   label it android - if matched name, label it both
	CASE WHEN p.name IS NULL THEN 'iPhone'
	WHEN a.name IS NULL THEN 'Android'
	ELSE 'Both' END AS store,
	-- combine iphone and google app name columns - if one is null, take value from 	the	other
	CASE WHEN p.name IS NULL THEN a.name
	WHEN a.name IS NULL THEN p.name
	ELSE p.name END AS combname,
	-- one combined category column - could still use cleaning
	CASE WHEN a.primary_genre IS NULL THEN p.genres
	WHEN p.genres IS NULL THEN a.primary_genre
	ELSE p.genres END AS category,
	-- calculate longevity of each app - ratings are different in each store, which is why they're separate
	p.rating AS android_rating,
	ROUND((p.rating/.5), 1) AS app_longevity_android,
	a.rating AS iphone_rating,
	ROUND((a.rating/.5), 1) AS app_longevity_iphone,
	p.review_count AS android_review_count,
	p.install_count AS play_installs,
	a.review_count AS iphone_review_count,
	p.price AS p_price,
	a.price AS a_price,
	p.content_rating,
	a.content_rating
-- TO GET DISTINCT name - instead of below subquery, group by name and take one value for each name or a criteria for which one to keep like highest rating w/ window function
FROM
	(SELECT DISTINCT (name),
	category,
	genres,
	rating,
	review_count,
	install_count,
	price,
	content_rating
	FROM play_store_apps) AS p
FULL JOIN app_store_apps AS a
ON p.name = a.name
-- ???? Remove apps with no rating info in either store - other things to cut down results to be more manageable
WHERE p.review_count > '200'
OR a.review_count > '200'
ORDER BY play_installs;

-- can I merge two columns with a case statement that will replace the nulls with the other information? Can CASE do this? Then conditional for apps that are in either store or both.

CAST((CASE WHEN price <= 1.00 THEN 10000
	ELSE (price*10000) END) AS money) AS purchase_cost

CASE WHEN a.primary_genre IS NULL THEN p.genres
	WHEN p.genres IS NULL THEN a.primary_genres
	ELSE p.genres END AS subcategory,

-- merged like an inner join
SELECT COUNT(*)
FROM play_store_apps AS p -- Select all customers with at least one rating
WHERE EXISTS
	(SELECT *
	FROM app_store_apps AS a
	WHERE name IS NOT NULL 
	AND p.name = a.name);

-- Removing duplicates from play_store_apps
SELECT DISTINCT(name),
	category,
	rating,
	review_count,
	install_count,
	type,
	price,
	content_rating,
	genres
FROM play_store_apps
--9659 apps

SELECT COUNT(*)
FROM play_store_apps
--10840 apps

-- Inner join of both tables
SELECT*
FROM
app_store_apps
INNER JOIN play_store_apps
ON app_store_apps.name=play_store_apps.name

-- SELECT statements to pull up both tables
SELECT *
FROM app_store_apps
ORDER BY name;

SELECT *
FROM play_store_apps
ORDER BY name;

-- SELECT statement with addition of calculated rows
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

-- Experiment w/ UNION
-- SELECT 
-- 	name
-- 	FROM app_store_apps
-- UNION
-- 	SELECT
-- 	name
-- 	FROM play_store_apps
-- ORDER BY name DESC;
