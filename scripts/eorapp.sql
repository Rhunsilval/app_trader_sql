-- Full Join with play store duplicates removed
SELECT
	CASE WHEN DISTINCT(p.name) IS NOT NULL
	a.name,
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

-- can I merge two columns with a case statement that will replace the nulls with the other information? Can CASE do this? Then conditional for apps that are in either store or both.

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
