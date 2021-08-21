-- Full Join with play store and combining columns
SELECT
	-- combine iphone and google name columns - if one is null, take value from the 	other
	CASE WHEN p.name IS NULL THEN a.name
	WHEN a.name IS NULL THEN p.name
	ELSE p.name || '-' || a.name END AS combname,
	INITCAP(REPLACE(p.category, '_', ' ')) AS category,
	-- effort to combine disparate categories  (didn't work right)
	CASE WHEN a.primary_genre IS NULL THEN p.genres
	WHEN p.genres IS NULL THEN a.primary_genre
	ELSE p.genres END AS subcategory,
	-- need to distill into sub genres with cleaning
	--	a.primary_genre,
	--	p.genres,
	-- calculate longevity of app
	CASE WHEN p.rating IS NULL THEN ROUND((a.rating/.5), 1)
	WHEN a.rating IS NULL THEN ROUND((p.rating/.5), 1)
	ELSE ROUND(((p.rating+a.rating)/.5)/2, 1) END AS longevity,
	p.rating AS p_rating,
	p.review_count AS p_reviews,
	p.install_count AS play_installs,
	a.rating AS a_rating,
	a.review_count AS a_reviews,
	p.price AS p_price,
	a.price AS a_price,
	p.content_rating,
	a.content_rating,
	-- if no title in play store, label it iphone app, if no name in iphone store, 	   label it android - if matched name, label it both
	CASE WHEN p.name IS NULL THEN 'iPhone'
	WHEN a.name IS NULL THEN 'Android'
	ELSE 'Both' END AS Store
-- try one of these instead: window function ranking according to review count within name/group by name and take one value for each name or a criteria for which one to keep like highest rating w/ window function
FROM
	(SELECT name,
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
ORDER BY store;

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
